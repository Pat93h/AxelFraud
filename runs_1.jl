include("model.jl")
if !("data" in readdir())
    mkdir("data")
end

baseline = NTuple{2, Int}[]
line_edge = [(1, 1), (1, 2), (1, 3), (1, 4)]
line_center = [(5, 3), (5, 4), (5, 5), (5, 6)]
square_corner = [(1, 1), (1, 2), (2, 1), (2, 2)]
square_center = [(5, 5), (5, 6), (6, 5), (6, 6)]
corners = [(1, 1), (1, 10), (10, 1), (10, 10)]
diagonal = [(1, 1), (4, 4), (7, 7), (10, 10)]
distance_center = [(4, 4), (4, 7), (7, 4), (7, 7)]
config_list = [
    baseline, line_edge, line_center, square_corner, 
    square_center, corners, diagonal, distance_center
]
filename_list = [
    "baseline", "line_edge", "line_center", "square_corner", 
    "square_center", "corners", "diagonal", "distance_center"
]

begin
    p = ProgressMeter.Progress(length(config_list), "Running Simulations ...")
    for (config, filename) in zip(config_list, filename_list)
        agent_df = AxelFraud.run_config(
            config_name=filename, grid_dims=(10, 10), stubborn_positions=config,
            steps=3000, replicates=300, when=10, write=true
        )    
        ProgressMeter.next!(p)
    end
end

run_random(steps=3000, replicates=300, by=10, rnd_seed=0, write=true)
