# src/master_problem.jl
using JuMP, Gurobi

function build_rmp(optimizer, flights, initial_pairings, pairing_costs; integrality=false)
    model = Model(optimizer)
    set_optimizer_attribute(model, "OutputFlag", 0)

    J = length(initial_pairings)
    
    if integrality
        @variable(model, y[1:J], Bin)
    else
        @variable(model, y[1:J] >= 0)
    end

    # Cover each flight exactly once
    flight_constrs = Dict{String,ConstraintRef}()
    for f in flights
        flight_constrs[f] = @constraint(model,
            sum(y[j] for j in 1:J if f in initial_pairings[j]) == 1
        )
    end

    @objective(model, Min, sum(pairing_costs[j]*y[j] for j in 1:J))
    optimize!(model)
    
    return model, y, flight_constrs
end