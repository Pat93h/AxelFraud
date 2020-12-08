include(joinpath("src", "module.jl"))

config_list = [
    Dict(
        0 => [(1, 1), (1, 2)],
        1 => [(10, 10), (10, 9)]
    ),
    Dict(
        0 => [(5, 5), (5, 6)],
        1 => [(6, 5), (6, 6)]
    )
]

AxelFraud.run_batch(
    config_list=config_list,
    batch_name="competitive",
    grid_dims=(10, 10),
    levels=2,
    steps=3000,
    replicates=300,
    when=10,
    write=true    
)



AxelFraud.run_random(
    batch_name="test",
    grid_dims=(10, 10),
    stubborn_count=10,
    steps=100, 
    replicates=2, 
    when=10, 
    rnd_seed=0, 
    write=true
)









