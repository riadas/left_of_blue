include("run_mcmc_bootstrap_static.jl")

test_config_names = [
    "square_room_blue_wall_center_prize.json",
    "square_room_blue_wall_center_prize_copy1.json",
    "square_room_blue_wall_center_prize_copy2.json",  
    "square_room_blue_wall_center_prize_copy3.json", 
    "square_room_blue_wall_center_prize_copy4.json",   
    "spatial_lang_test_left_true_shift_0.json", 
    "spatial_lang_test_copy_left_true_shift_0.json", 
    "spatial_lang_test_copy2_left_true_shift_0.json",
    "spatial_lang_test_copy3_left_true_shift_0.json", 
    "square_room_blue_wall_left_prize.json",
    # "square_room_blue_wall_far-left-corner_prize.json"
]

global repeats = parse(Int, ARGS[1])
intermediate_save_name = ARGS[3]
global test_name = replace("test_bootstrap_$(intermediate_save_name)_$(repeats)", ".txt" => "")
iters = parse(Int, ARGS[2])
init = parse(Bool, ARGS[4])

chain = run_mcmc(all_function_sigs, test_config_names, iters, repeats, intermediate_save_name, test_name, init)

if init 
    open("metalanguage/intermediate_outputs/intermediate_chains/$(intermediate_save_name)", "w+") do f
        write(f, "")
    end
end

open("metalanguage/intermediate_outputs/intermediate_chains/$(intermediate_save_name)", "w+") do f
    println(length(chain))
    write(f, repr(chain))
end
