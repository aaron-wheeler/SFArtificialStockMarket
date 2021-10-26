# Install and precompile packages
using Pkg
Pkg.activate(".")
Pkg.instantiate()

# # Start workers (Parallel Computing)
# using Distributed
# addprocs(4)

# # Set up package environment on workers (Parallel Computing)
# @everywhere begin
#     using Pkg
#     Pkg.activate(".")
# end

# Load packages on master process
using DataFrames
using CSV
using Pipe

# # Load packages on workers 
# (Parallel Computing)
# @everywhere begin
#     using Agents
#     using Statistics: mean
#     using Random
# end

# (Sequencial Computing)
using Agents
using Statistics: mean
using Random

# # Load model libraries on workers
# (Parallel Computing)
# @everywhere cd("src/ABM")
# @everywhere include("model.jl")

# (Sequencial Computing)
include("model.jl")

## Define scenarios and run model
"""
Create model, let it run, wrangle data, dance a tarantella.
"""
function let_it_run()

    # # adata = [:status, :ϕ, :γ, :ρ,
    # #     :deviation_norm_shirk, :deviation_norm_coop,
    # #     :time_cooperation, :time_individual, :time_shirking,
    # #     :reward, :output, :realised_output, :realised_output_max]

    adata = [:relative_cash, :relative_holdings]

    # # mdata = [:gini_index]

    mdata = [:t, :price, :dividend, :trading_volume, :volatility, :technical_activity]

    # seeds = rand(UInt32, 50) # vector of random seeds
    seeds = rand(UInt32, 1) # vector of random seeds

    # Setup parameters (for complex or rational)
    # complex
    properties = (
        k = 250,
        JX = 0.1,
        τ = 75
    )
    
    models = [init_model(; seed, properties...) for seed in seeds] # 50 random seed trial runs?
    
    # # Collect data (ensemble simulation for multiple random seeded models)
    model_runs = 1 # numder of model iterations
    adf, mdf = ensemblerun!(models, dummystep, model_step!, model_runs;
        adata = adata, mdata = mdata, parallel = false)

    # Collect data (for single model case)
    # adf, mdf = run!(models, dummystep, model_step!, 500;
    #     adata = adata, mdata = mdata)

    # Create save path
    # savepath = mkpath("../../data/ABM/env=$(properties.env)")
    savepath = mkpath("../../data/ABM/test")

    # # Aggregate agent data over replicates
    # adf = @pipe adf |>
    #     groupby(_, [:step, :id]) |>
    #     combine(_,
    #         adata[1] .=> unique .=> adata[1],
    #         adata[3:end] .=> mean .=> adata[3:end]
    #     )
    # adf[!, :env] = fill(properties.env, nrow(adf))
    # adf[!, :scenario] = fill(properties.scenario, nrow(adf))
    # CSV.write("$(savepath)/data_$(properties.scenario).csv", adf)
    CSV.write("$(savepath)/adf_test.csv", adf)

    # # Collect aggregated data over steps
    # aggregate_data = @pipe adf |> 
    #     groupby(_, [:step, :env, :scenario]) |>
    #     combine(_, 
    #         [:time_individual, :time_shirking, :time_cooperation] .=> mean,
    #         [:output, :reward] .=> sum
    #     )
    # CSV.write("$(savepath)/aggregate_$(properties.scenario).csv", aggregate_data)

    # # Aggregate model data over replicates
    # mdf = @pipe mdf |>
    #     groupby(_, [:step]) |>
    #     combine(_, mdata[1] .=> mean .=> mdata[1])
    # mdf[!, :scenario] = fill(properties.scenario, nrow(mdf))
    # CSV.write("$(savepath)/mdf_$(properties.scenario).csv", mdf)
    CSV.write("$(savepath)/mdf_test.csv", mdf)
end

Random.seed!(44801)
let_it_run()
println("Simulation Complete")
