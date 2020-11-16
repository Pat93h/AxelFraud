using ProgressMeter
using Feather
include(joinpath("src", "module.jl"))

begin
    BATCH_NAME = "original"
    GRID_DIMS = (10, 10)
    STUBBORN_COUNT = 4
    STEPS = 100
    REPLICATES = 2
    WHEN = 10
    WRITE = true
end

begin
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
    AxelFraud.create_config_table(
        config_list=config_list, 
        grid_dims=GRID_DIMS, 
        batch_name=BATCH_NAME,
        write=WRITE
    )
end

begin
    p = ProgressMeter.Progress(length(config_list), "Running Simulations ...")
    for (config, filename) in zip(config_list, filename_list)
        agent_df = AxelFraud.run_config(
            config_name=filename, 
            batch_name=BATCH_NAME, 
            grid_dims=GRID_DIMS, 
            stubborn_positions=config,
            steps=STEPS, 
            replicates=REPLICATES, 
            when=WHEN, 
            write=WRITE
        )    
        ProgressMeter.next!(p)
    end
end

random_agent_df, random_configs = AxelFraud.run_random(
    config_name="random",
    batch_name=BATCH_NAME,
    grid_dims=GRID_DIMS,
    stubborn_count=STUBBORN_COUNT,
    steps=STEPS, 
    replicates=REPLICATES, 
    when=WHEN, 
    rnd_seed=0, 
    write=false
)
Feather.write(joinpath("data", BATCH_NAME, "random_configs.feather"), random_configs)