## 
using Agents
using StatsBase
using DataFrames
using Feather
using Query
using Pipe

##
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

function prepare_data!(dataframe::DataFrames.DataFrame)
    dataframe[!, "culture"] = [join(c) for c in dataframe[!, "culture"]]
    agent_df[!, :x] = [i[1] for i in agent_df[!, :pos]]
    agent_df[!, :y] = [i[2] for i in agent_df[!, :pos]]
    DataFrames.select!(agent_df, DataFrames.Not(:pos))
    return dataframe
end

## 
baseline = NTuple{2, Int}[]
line_edge = [(1, 1), (1, 2), (1, 3), (1, 4)]
line_center = [(5, 3), (5, 4), (5, 5), (5, 6)]
square_corner = [(1, 1), (1, 2), (2, 1), (2, 2)]
square_center = [(5, 5), (5, 6), (6, 5), (6, 6)]
random = [(rand(1:10), rand(1:10)) for i in 1:4]
corners = [(1, 1), (1, 10), (10, 1), (10, 10)]
diagonal = [(1, 1), (4, 4), (7, 7), (10, 10)]
distance_center = [(3, 3), (3, 7), (7, 3), (7, 7)]

##
stubborn_positions = random
model = initialize_model((10, 10), stubborn_positions)
agent_df, _ = Agents.run!(
    model, agent_step!, 1000, adata=[:pos, :culture], 
    replicates=100, parallel=true, obtainer=deepcopy
)
prepare_data!(agent_df)
Feather.write("random.feather", agent_df)

##