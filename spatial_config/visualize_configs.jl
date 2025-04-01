
include("viz.jl")
config_path = "spatial_config/configs"

for filename in readdir(config_path)
    config = JSON.parsefile("$(config_path)/$(filename)")
    if config["type"] == "left_of_blue"
        save_path = "spatial_config/images/2D/$(replace(filename, ".json" => ".png"))"
        p = visualize_left_of_blue_problem(config, save_path)
    end
end

visualize_spatial_lang_problem("spatial_config/images/3D/spatial_lang_test.png")