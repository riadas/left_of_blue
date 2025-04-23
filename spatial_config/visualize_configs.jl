include("viz.jl")
config_path = "spatial_config/configs"

for filename in readdir(config_path)
    println(filename)
    config = JSON.parsefile("$(config_path)/$(filename)")
    if config["type"] == "left_of_blue"
        save_path = "spatial_config/images/left_of_blue/$(replace(filename, ".json" => ".png"))"
        p = visualize_left_of_blue_problem(config, save_path)
    elseif config["type"] == "red_green_test"
        save_path = "spatial_config/images/red_green_test/$(replace(filename, ".json" => ".png"))"
        p = visualize_red_green_problem(config, save_path)
    elseif config["type"] == "spatial_lang_test"
        p = visualize_spatial_lang_problem(config, "spatial_config/images/spatial_lang_test/$(replace(filename, ".json" => ".png"))")
    elseif config["type"] == "triangle"
        save_path = "spatial_config/images/triangle_rooms/$(replace(filename, ".json" => ".png"))"
        p = visualize_triangle_problem(config, save_path)
    elseif config["type"] == "special_corner"
        save_path = "spatial_config/images/special_corner_rooms/$(replace(filename, ".json" => ".png"))"
        p = visualize_special_corner_problem(config, save_path)
    end
end