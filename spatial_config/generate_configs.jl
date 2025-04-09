using JSON 
using Combinatorics

# generate different left of blue configurations
dimension_ratios = [(2,3), (1,1)]
accent_walls = [true, false]
prize_specs = ["left", "right", "center", "far-left", "far-right"]

for ratio in dimension_ratios
    for accent_wall in accent_walls
        for prize_spec in prize_specs
            config = Dict()
            config["type"] = "left_of_blue"
            config["length"] = ratio[1]
            config["width"] = ratio[2]
            config["accent_wall"] = accent_wall
            config["prize"] = prize_spec

            open("""spatial_config/configs/$(ratio[1] == ratio[2] ? "square" : "rect")_room_$(accent_wall ? "" : "no_")blue_wall_$(prize_spec)_prize.json""", "w") do f
                JSON.print(f, config)
            end

        end
    end
end

# generate the spatial language test configuration
for shift in [-2, 0, 2]
    for left in [true, false]
        config = Dict()
        config["type"] = "spatial_lang_test"
        config["shift"] = shift
        config["left"] = left

        open("""spatial_config/configs/spatial_lang_test_left_$(left)_shift_$(shift).json""", "w") do f
            JSON.print(f, config)
        end
    end

end

# generate the red-green test configurations
prize_left_colors = ["green", "red"]
diagonals = [false, true]
orders = [permutations(["M", "R", "D"])...]
diagonal_types = ["tl"] # ["tl", "tr"]

for prize_left_color in prize_left_colors 
    for diagonal in diagonals 
        for order in orders
            for diagonal_type in diagonal_types 
                config = Dict()
                config["type"] = "red_green_test"
                config["prize_left_color"] = prize_left_color
                config["diagonal"] = diagonal 
                config["order"] = order
                config["diagonal_type"] = diagonal_type
    
                open("""spatial_config/configs/green_red_test_left_color_$(prize_left_color)_diagonal_$(diagonal)_order_$(join(order, "_")).json""", "w") do f
                    JSON.print(f, config)
                end
            end
        end
    end
end