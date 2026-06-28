# src/column_generation.jl
include("build_network.jl")
include("master_problem.jl")
include("pricing_problem.jl")

using JuMP, Gurobi

function run_crew_pairing(data, pool_size=20)
    # Unpack data
    airports      = data[:airports]
    hub           = data[:hub]
    flights       = data[:flights]
    dep_airpt     = data[:dep_airpt]
    arr_airpt     = data[:arr_airpt]
    dep_time      = data[:dep_time]
    arr_time      = data[:arr_time]
    deadhead_time = data[:deadhead_time]
    layover_cost  = data[:layover_cost]
    deadhead_cost = data[:deadhead_cost]

    gurobi_env = Gurobi.Env()
    optimizer  = () -> Gurobi.Optimizer(gurobi_env)

    start_time = time()

    # Column‑generation initialization
    t0 = [[f] for f in flights]
    c0 = [deadhead_time[(hub,dep_airpt[f])]*deadhead_cost +
          deadhead_time[(arr_airpt[f],hub)]*deadhead_cost
          for f in flights]
          
    initial_pairings = copy(t0)
    pairing_costs    = copy(c0)

    iter = 1
    while true
        rmp, y, fcon = build_rmp(optimizer, flights, initial_pairings, pairing_costs)
        duals        = Dict(f => dual(fcon[f]) for f in flights)
        
        sols, arc_cost = solve_shortest_path(
            optimizer, flights, dep_airpt, arr_airpt,
            dep_time, arr_time, deadhead_time,
            layover_cost, deadhead_cost, duals, hub;
            pool_solutions=pool_size
        )
        
        if isempty(sols)
            println("No negative reduced-cost columns. Terminating.")
            break
        end
        
        for (sel_arcs, rc) in sols
            pairing, curr = String[], hub
            while true
                idx = findfirst(a->a[1]==curr, sel_arcs)
                if idx === nothing || sel_arcs[idx][2] == hub 
                    break 
                end
                curr = sel_arcs[idx][2]
                push!(pairing, curr)
            end
            push!(initial_pairings, pairing)
            push!(pairing_costs, sum(arc_cost[a] for a in sel_arcs))
        end
        iter += 1
    end

    # Final Integer RMP
    rmp_int, y_int, _ = build_rmp(
        optimizer, flights, initial_pairings, pairing_costs;
        integrality=true
    )
    
    println("Iterations = ", iter)
    println("Time Taken = ", time() - start_time)
    println("Final integer RMP cost = ", objective_value(rmp_int))
    println("Selected pairings:")
    for (i, val) in enumerate(value.(y_int))
        if val > 0.5 
            println("  ", initial_pairings[i]) 
        end
    end
end

# Main Execution Block
function main()
    println("Generating Data...")
    # Generate instances: small, medium, large
    data_instances = Dict(
        "small"  => data_gen(50, 6),
        "medium" => data_gen(100, 8),
        "large"  => data_gen(150, 12),
    )

    for name in ["small", "medium", "large"]
        println("\n============================")
        println("Running instance: $name")
        println("============================")
        run_crew_pairing(data_instances[name], 100) # Passes 100 pool solutions for Option 2
    end
end

# Run the program
main()