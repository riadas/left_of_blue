using JSON 
using Combinatorics

# generate different left of blue configurations
dimension_ratios = [(2,3), (1,1)]
accent_walls = [true, false]
prize_specs = ["left", "right", "center", "far-left", "far-right", "far-left-corner", "far-right-corner"]

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
        config["utterance"] = ""

        open("""spatial_config/configs/spatial_lang_test_left_$(left)_shift_$(shift).json""", "w") do f
            JSON.print(f, config)
        end

        # add natural language instructions
        left_instruction = "Put the blue object left of the red object"
        right_instruction = "Put the blue object right of the red object"
        instructions = Dict(["left" => left_instruction, "right" => right_instruction])
        if left 
            config["utterance"] = instructions["left"]
        else
            config["utterance"] = instructions["right"]
        end

        open("""spatial_config/configs/spatial_lang_test_left_$(left)_shift_$(shift)_utterance_true.json""", "w") do f
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
                config["utterance"] = ""

                open("""spatial_config/configs/green_red_test_left_color_$(prize_left_color)_diagonal_$(diagonal)_order_$(join(order, "_")).json""", "w") do f
                    JSON.print(f, config)
                end

                # add natural language labels 
                labels = Dict([
                    "directional" => """The red is $(prize_left_color == "green" ? "right" : "left") of the green""",
                    "neutral" => "The red is next to the green",
                    "prettier" => "The red is prettier than the green"
                ])
                for k in keys(labels)
                    config["utterance"] = labels[k]
                    open("""spatial_config/configs/green_red_test_left_color_$(prize_left_color)_diagonal_$(diagonal)_order_$(join(order, "_"))_utterance_$(k).json""", "w") do f
                        JSON.print(f, config)
                    end
                end
            end
        end
    end
end

# generate triangle configs
triangle_prize_locations = [("close", "close"), ("close", "far"), ("far", "close")]
for tup in triangle_prize_locations 
    config = Dict()
    config["type"] = "triangle"
    config["prize_left_side"] = tup[1]
    config["prize_right_side"] = tup[2]

    open("""spatial_config/configs/triangle_room_$(tup[1])_$(tup[2]).json""", "w") do f
        JSON.print(f, config)
    end
end

# generate rectangular rooms with colored corners ("SpecialCorner") configs
config = Dict()
config["type"] = "special_corner"
open("""spatial_config/configs/rect_room_special_corner.json""", "w") do f
    JSON.print(f, config)
end