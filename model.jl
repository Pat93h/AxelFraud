using Agents
using StatsBase
using DataFrames
using Feather
using Query
using Pipe

mutable struct AxelrodAgent <: AbstractAgent
    id::Int
    pos::NTuple{2, Int}
    stubborn::Bool
    culture::AbstractArray
end

function initialize_model(dims::NTuple{2, Int}, stubborn_positions::AbstractArray)
    space = GridSpace(dims, periodic=false, moore=false)
    model = AgentBasedModel(AxelrodAgent, space, scheduler=random_activation)
    populate!(model, dims)
    to_stubborn!(stubborn_positions, model)
    return model
end

function populate!(model::AgentBasedModel, dims::NTuple{2, Int})
    positions = [(i, j) for i in 1:dims[1] for j in 1:dims[2]]
    for (id, pos) in enumerate(positions)
        add_agent_pos!(AxelrodAgent(id, pos, false, rand(0:9, 5)), model)
    end
    return model
end

function to_stubborn!(positions::Array{NTuple{2, Int}}, model)
    for pos in positions
        stubborn_agent = get_node_agents(coord2vertex(pos, model), model)[1]
        stubborn_agent.stubborn = true
        stubborn_agent.culture = zeros(Int64, 5)
    end
    return model
end

function agent_step!(agent::AbstractAgent, model::AgentBasedModel)
    neighbors = node_neighbors(agent, model)
    interaction_partner_pos = sample(neighbors)
    interaction_partner = get_node_agents(coord2vertex(interaction_partner_pos, model), model)[1]
    similarity = StatsBase.mean(agent.culture .== interaction_partner.culture)
    if !(similarity == 1.0) & !agent.stubborn & (rand() <= similarity)
        assimilate!(agent, interaction_partner)
    end
    return agent
end

function assimilate!(agent::AbstractAgent, interaction_partner::AbstractAgent)
	random_attr = rand(1:length(agent.culture))
	if !(agent.culture[random_attr] == interaction_partner.culture[random_attr])
		agent.culture[random_attr] = interaction_partner.culture[random_attr]
	else
		assimilate!(agent, interaction_partner)
	end
	return agent
end

function prepare_data!(dataframe::DataFrame)
    dataframe[!, "culture"] = [join(c) for c in dataframe[!, "culture"]]
    agent_df[!, :x] = [i[1] for i in agent_df[!, :pos]]
    agent_df[!, :y] = [i[2] for i in agent_df[!, :pos]]
    select!(agent_df, DataFrames.Not(:pos))
    return dataframe
end

# baseline
stubborn_positions = NTuple{2, Int}[]
# line/edge
stubborn_positions = [(1, 1), (1, 2), (1, 3), (1, 4)]
# line/center
stubborn_positions = [(5, 3), (5, 4), (5, 5), (5, 6)]
# square/corner
stubborn_positions = [(1, 1), (1, 2), (2, 1), (2, 2)]
# square/center
stubborn_positions = [(5, 5), (5, 6), (6, 5), (6, 6)]
# random 
stubborn_positions = [(rand(1:10), rand(1:10)) for i in 1:4]
# corners
stubborn_positions = [(1, 1), (1, 10), (10, 1), (10, 10)]
# diagonal
stubborn_positions = [(1, 1), (4, 4), (7, 7), (10, 10)]
# distance center
stubborn_positions = [(3, 3), (3, 7), (7, 3), (7, 7)]

model = initialize_model((10, 10), stubborn_positions)
agent_df, _ = run!(model, agent_step!, 1000, adata=[:pos, :culture], replicates=10, parallel=true)
prepare_data!(agent_df)
@pipe agent_df |> last(_, 100) |> print
Feather.write("test.feather", agent_df)
