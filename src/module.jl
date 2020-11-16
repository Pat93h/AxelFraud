module AxelFraud

    using Agents
    using StatsBase
    using DataFrames
    using Feather
    using Query
    using Pipe
    using Random
    using ProgressMeter

    include("functions.jl")

    export initialize_model
    export run_config
    export run_random
    export run_batch
    export create_config_table

end
