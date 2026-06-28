# src/build_network.jl
using Dates, Random

function data_gen(num_flights::Int, num_airports::Int)
    DAY_START     = DateTime(2025, 5, 1, 6)
    DAY_END       = DAY_START + Day(7)       # one week horizon
    deadhead_cost = 100.0
    layover_cost  = 50.0
    rng = MersenneTwister(1234)

    # hubs and spokes
    airport_list = [string(Char('A' + i - 1)) for i in 1:num_airports]
    hub          = airport_list[1]
    spokes       = airport_list[2:end]

    # flight IDs
    flight_ids = ["F$(i)" for i in 1:num_flights]

    # origin/destination: only hub→spoke or spoke→hub
    dep_airpt = Dict{String,String}()
    arr_airpt = Dict{String,String}()
    for f in flight_ids
        if rand(rng) < 0.5
            dep_airpt[f] = hub
            arr_airpt[f] = rand(rng, spokes)
        else
            dep_airpt[f] = rand(rng, spokes)
            arr_airpt[f] = hub
        end
    end

    # fixed flight durations per airport-pair (in seconds, 1–5 hours)
    flight_dur = Dict{Tuple{String,String},Int}()
    for i in airport_list, j in airport_list
        flight_dur[(i,j)] = i == j ? 0 : rand(rng, 3600:5*3600)
    end

    # departure/arrival times
    dep_time = Dict{String,DateTime}()
    arr_time = Dict{String,DateTime}()
    total_sec   = Int(div(Dates.value(DAY_END - DAY_START), 1000))
    max_dur_sec = maximum(values(flight_dur))
    max_offs    = total_sec - max_dur_sec     # ensure arrival ≤ DAY_END
    
    for f in flight_ids
        offs = rand(rng, 0:max_offs)
        dur  = flight_dur[(dep_airpt[f], arr_airpt[f])]
        dt   = DAY_START + Second(offs)
        dep_time[f] = dt
        arr_time[f] = dt + Second(dur)
    end

    # deadhead times between every airport-pair: flight_hours + 1 hour
    deadhead_time = Dict{Tuple{String,String},Float64}()
    for ((i,j), secs) in flight_dur
        deadhead_time[(i,j)] = secs / 3600.0 + 1.0
    end

    return Dict(
        :airports      => airport_list,
        :hub           => hub,
        :flights       => flight_ids,
        :dep_airpt     => dep_airpt,
        :arr_airpt     => arr_airpt,
        :flight_dur    => flight_dur,
        :dep_time      => dep_time,
        :arr_time      => arr_time,
        :deadhead_time => deadhead_time,
        :layover_cost  => layover_cost,
        :deadhead_cost => deadhead_cost
    )
end