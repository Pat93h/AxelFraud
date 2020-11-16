include(joinpath("src", "module.jl"))

config_list = [
    [(5, 5), (5, 6), (6, 5), (6, 6)],
    [(4, 4), (4, 7), (7, 4), (7, 7)],
    [(3, 3), (3, 8), (8, 3), (8, 8)],
    [(2, 2), (2, 9), (9, 2), (9, 9)],
    [(1, 1), (1, 10), (10, 1), (10, 10)]
]

AxelFraud.run_batch(
    config_list=config_list,
    batch_name="expanding_square",
    grid_dims=(10, 10),
    steps=100,
    replicates=2,
    when=10,
    write=true    
)

AxelFraud.run_random(
    batch_name="random",
    grid_dims=(10, 10),
    steps=100, 
    replicates=2, 
    when=10, 
    rnd_seed=0, 
    write=true
)









