using JSON 

# generate different left of blue configurations
dimension_ratios = [(2,3), (1,1)]
accent_walls = [true, false]
corner_prizes = [true, false]

for ratio in dimension_ratios
    for accent_wall in accent_walls
        for corner_prize in corner_prizes
            config = Dict()
            config["type"] = "left_of_blue"
            config["length"] = ratio[1]
            config["width"] = ratio[2]
            config["accent_wall"] = accent_wall
            config["corner_prize"] = corner_prize

            open("""spatial_config/configs/$(ratio[1] == ratio[2] ? "square" : "rect")_room_$(accent_wall ? "" : "no_")blue_wall_$(corner_prize ? "corner" : "center")_prize.json""", "w") do f
                JSON.print(f, config)
            end

        end
    end
end

# generate the spatial language test configuration
config = Dict()
config["type"] = "spatial_lang_test"

open("""spatial_config/configs/spatial_lang_test.json""", "w") do f
    JSON.print(f, config)
end