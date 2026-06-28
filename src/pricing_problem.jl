# src/pricing_problem.jl
using JuMP, Gurobi, Dates

function solve_shortest_path(
    optimizer_factory, flights, dep_airpt, arr_airpt,
    dep_time, arr_time, deadhead_time,
    layover_cost, deadhead_cost, duals, hub;
    pool_solutions=20
)
    model = Model(optimizer_factory)
    set_optimizer_attribute(model, "OutputFlag", 0)
    set_optimizer_attribute(model, "PoolSearchMode", 2)
    set_optimizer_attribute(model, "PoolSolutions", pool_solutions)

    s, t = hub, hub
    A_lay = [(f,g) for f in flights, g in flights
             if arr_airpt[f]==dep_airpt[g] && arr_time[f]+Hour(1)<=dep_time[g]]
    A_dh  = [(f,g) for f in flights, g in flights
             if arr_airpt[f]!=dep_airpt[g] &&
                arr_time[f]+Hour(1)+Second(round(Int,deadhead_time[(arr_airpt[f],dep_airpt[g])]*3600))
                <= dep_time[g]]
    A_sf = [(s,f) for f in flights]
    A_ft = [(f,t) for f in flights]
    arcs = union(A_lay, A_dh, A_sf, A_ft)

    arc_cost = Dict{Tuple{String,String},Float64}()
    for (i,j) in arcs
        if (i,j) in A_lay
            hrs = Dates.value(dep_time[j] - arr_time[i]) / 3_600_000
            arc_cost[(i,j)] = hrs * layover_cost
        elseif (i,j) in A_dh
            total = Dates.value(dep_time[j] - arr_time[i]) / 3_600_000
            travel = deadhead_time[(arr_airpt[i],dep_airpt[j])]
            lay    = max(total - travel,0)
            arc_cost[(i,j)] = travel*deadhead_cost + lay*layover_cost
        elseif i==s
            arc_cost[(i,j)] = deadhead_time[(s,dep_airpt[j])] * deadhead_cost
        else
            arc_cost[(i,j)] = deadhead_time[(arr_airpt[i],t)] * deadhead_cost
        end
    end

    @variable(model, x[a in arcs], Bin)

    flight_dur = Dict{String,Float64}()
    for f in flights
        flight_dur[f] = Dates.value(arr_time[f]-dep_time[f]) / 3_600_000
    end
    
    deadhead_dur = Dict{Tuple{String,String},Float64}()
    for a in arcs
        if a in A_lay
            deadhead_dur[a] = 0.0
        elseif a in A_dh
            deadhead_dur[a] = deadhead_time[(arr_airpt[a[1]],dep_airpt[a[2]])]
        elseif a[1]==s
            deadhead_dur[a] = deadhead_time[(s,dep_airpt[a[2]])]
        else
            deadhead_dur[a] = deadhead_time[(arr_airpt[a[1]],t)]
        end
    end

    @constraint(model,
        sum(flight_dur[j]*x[(i,j)] for (i,j) in arcs if j!=t) +
        sum(deadhead_dur[a]*x[a] for a in arcs) <= 16
    )
    
    @constraint(model, sum(x[(s,f)] for f in flights)==1)
    @constraint(model, sum(x[(f,t)] for f in flights)==1)
    
    for n in flights
        @constraint(model,
            sum(x[(i,n)] for (i,n2) in arcs if n2==n) ==
            sum(x[(n2,j)] for (n2,j) in arcs if n2==n)
        )
    end
    
    inc = [(f,g) for f in flights, g in flights
           if deadhead_time[(s,dep_airpt[f])] +
              deadhead_time[(arr_airpt[g],t)] > 16]
              
    @constraint(model, [p in inc],
        x[(s,p[1])] + x[(p[2],t)] <= 1
    )
    
    @objective(model, Min,
        sum((arc_cost[a] - get(duals,a[2],0.0))*x[a] for a in arcs)
    )
    optimize!(model)

    # Extract multiple solutions from pool
    grb_model = backend(model).optimizer.model
    env       = GRBgetenv(grb_model)
    solcount_ref = Ref{Cint}()
    GRBgetintattr(grb_model, "SolCount", solcount_ref)
    solcount = solcount_ref[]

    all_pairings = []
    for solnum in 0:solcount-1
        GRBsetintparam(env, "SolutionNumber", solnum)
        xvals = Vector{Cdouble}(undef,length(arcs))
        GRBgetdblattrarray(grb_model, "Xn", 0, length(arcs), xvals)
        
        obj_ref = Ref{Cdouble}()
        GRBgetdblattr(grb_model, "PoolObjVal", obj_ref)
        rc = obj_ref[]
        
        if rc < -1e-3
            sel = [a for (i,a) in enumerate(arcs) if xvals[i]>0.5]
            push!(all_pairings,(sel,rc))
        end
    end
    
    return all_pairings, arc_cost
end