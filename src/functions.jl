mutable struct AxelrodAgent <: Agents.AbstractAgent
    id::Int
    pos::NTuple{2, Int}
    stubborn::Bool
    culture::AbstractArray
end

function initialize_model(dims::NTuple{2, Int}, stubborn_positions::AbstractArray)
    space = Agents.GridSpace(dims, periodic=false, moore=false)
    model = Agents.AgentBasedModel(AxelrodAgent, space, scheduler=random_activation)
    populate!(model, dims)
    to_stubborn!(stubborn_positions, model)
    return model
end

function populate!(model::Agents.AgentBasedModel, dims::NTuple{2, Int})
    positions = [(i, j) for i in 1:dims[1] for j in 1:dims[2]]
    for (id, pos) in enumerate(positions)
        Agents.add_agent_pos!(AxelrodAgent(id, pos, false, rand(0:9, 5)), model)
    end
    return model
end

function to_stubborn!(positions::Array{NTuple{2, Int}}, model::Agents.AgentBasedModel)
    for pos in positions
        stubborn_agent = Agents.get_node_agents(Agents.coord2vertex(pos, model), model)[1]
        stubborn_agent.stubborn = true
        stubborn_agent.culture = zeros(Int64, 5)
    end
    return model
end

function agent_step!(agent::Agents.AbstractAgent, model::Agents.AgentBasedModel)
    neighbors = Agents.node_neighbors(agent, model)
    interaction_partner_pos = StatsBase.sample(neighbors)
    interaction_partner = Agents.get_node_agents(
        Agents.coord2vertex(interaction_partner_pos, model), model
    )[1]
    similarity = StatsBase.mean(agent.culture .== interaction_partner.culture)
    if !(similarity == 1.0) & !agent.stubborn & (rand() <= similarity)
        assimilate!(agent, interaction_partner)
    end
    return agent
end

function assimilate!(agent::Agents.AbstractAgent, interaction_partner::Agents.AbstractAgent)
    random_attr = rand(1:length(agent.culture))
    if !(agent.culture[random_attr] == interaction_partner.culture[random_attr])
        agent.culture[random_attr] = interaction_partner.culture[random_attr]
    else
        assimilate!(agent, interaction_partner)
    end
    return agent
end

function prepare_data!(dataframe::DataFrames.DataFrame, config_name::String)
    dataframe[!, "culture"] = [join(c) for c in dataframe[!, "culture"]]
    dataframe[!, :x] = [i[1] for i in dataframe[!, :pos]]
    dataframe[!, :y] = [i[2] for i in dataframe[!, :pos]]
    DataFrames.select!(dataframe, DataFrames.Not(:pos))
    dataframe[!, :config] .= config_name
    return dataframe
end

function run_random(; 
    config_name::Union{String, Nothing}=nothing,
    batch_name::String,
    grid_dims::Tuple,
    steps::Int, 
    replicates::Int, 
    when::Int=10, 
    rnd_seed::Int=0, 
    write::Bool=false
)
    if !("data" in readdir())
        mkdir("data")
    end
    if !(batch_name in readdir("data"))
        mkdir(joinpath("data", batch_name))
    end
    Random.seed!(rnd_seed)
    agent_df_list = DataFrames.DataFrame[]
    config_list = Any[]
    p = ProgressMeter.Progress(replicates, "Running Simulations ...")
    for i in 1:replicates
        config = [(rand(1:grid_dims[1]), rand(1:grid_dims[2])) for j in 1:4]
        push!(config_list, deepcopy(config))
        model = initialize_model(grid_dims, config)
        rep_df, _ = Agents.run!(
            model, agent_step!, steps, adata=[:pos, :culture],
            replicates=1, when=0:when:steps, parallel=true, obtainer=deepcopy
        )
        rep_df[!, :replicate] .= i
        push!(agent_df_list, deepcopy(rep_df))
        ProgressMeter.next!(p)
    end
    agent_df = reduce(vcat, agent_df_list)
    prepare_data!(agent_df, batch_name)
    if write
        if config_name === nothing
            Feather.write(joinpath("data", batch_name, batch_name * ".feather"), agent_df)
        else
            Feather.write(joinpath("data", batch_name, config_name * ".feather"), agent_df)
        end

    end
    config_table = create_config_table(
        config_list=config_list,
        grid_dims=grid_dims,
        batch_name=batch_name,
        write=write
    )
    return agent_df, config_table
end

function run_batch(;
    config_list::AbstractArray,
    batch_name::String,
    grid_dims::Tuple,
    steps::Int,
    replicates::Int,
    when::Int,
    write::Bool
)
    if !("data" in readdir())
        mkdir("data")
    end
    if !(batch_name in readdir("data"))
        mkdir(joinpath("data", batch_name))
    end
    results = DataFrames.DataFrame[]
    p = ProgressMeter.Progress(length(config_list), "Running Simulations ...")
    for (i, config) in enumerate(config_list)
        tmp = run_config(
            config_name=batch_name * "_" * string(i),
            batch_name=batch_name,
            grid_dims=grid_dims,
            stubborn_positions=config,
            steps=steps,
            replicates=replicates,
            when=when,
            write=false
        )
        if write
            Feather.write(
                joinpath("data", batch_name, batch_name * "_" * string(i) * ".feather"), 
                tmp
            )
        end
        push!(results, deepcopy(tmp))
        ProgressMeter.next!(p)
    end
    config_table = create_config_table(
        config_list=config_list,
        grid_dims=grid_dims,
        batch_name=batch_name,
        write=write
    )
    return results, config_table
end

function run_config(;
    config_name::String,
    batch_name::String,
    grid_dims::Tuple, 
    stubborn_positions::AbstractArray,
    steps::Int, 
    replicates::Int, 
    when::Int, 
    write::Bool
)
    if !("data" in readdir())
        mkdir("data")
    end
    if !(batch_name in readdir("data"))
        mkdir(joinpath("data", batch_name))
    end
    model = initialize_model(grid_dims, stubborn_positions)
    agent_df, _ = Agents.run!(
        model, agent_step!, steps, adata=[:pos, :culture],
        replicates=replicates, when=0:when:steps, parallel=true, obtainer=deepcopy
    )
    prepare_data!(agent_df, config_name)
    if write
        Feather.write(joinpath("data", batch_name, config_name * ".feather"), agent_df)
    end
    return agent_df
end

function create_config_table(;
    config_list::AbstractArray, 
    grid_dims::Tuple=(10, 10), 
    batch_name::String="default",
    write::Bool=false
)
    if !("data" in readdir())
        mkdir("data")
    end
    if !(batch_name in readdir("data"))
        mkdir(joinpath("data", batch_name))
    end
    configs = DataFrames.DataFrame([
        (i, j)
        for i in 1:grid_dims[1] 
        for j in 1:grid_dims[2]
    ]) 
    DataFrames.names!(configs, [:x, :y])
    for (i, config) in enumerate(config_list)
        col_name = Symbol(batch_name * "_" * string(i))
        configs[!, col_name] .= 0
        for conf in config
            for row in eachrow(configs)
                if row[:x] == conf[1] && row[:y] == conf[2]
                    row[col_name] = 1
                end
            end        
        end
    end
    if write
        Feather.write(joinpath("data", batch_name, "configs.feather"), configs)
    end
    return configs
end

