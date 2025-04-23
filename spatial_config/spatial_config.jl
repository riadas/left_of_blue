using JSON 
# include("../scratch/demo.jl")

function define_spatial_reasoning_problem(filepath::String)
    config = JSON.parsefile(filepath)
    return define_spatial_reasoning_problem(config)
end

function define_spatial_reasoning_problem(config)
    if config["type"] == "left_of_blue"
        return define_left_of_blue_problem(config)
    elseif config["type"] == "spatial_lang_test"
        return define_spatial_lang_problem(config)
    elseif config["type"] == "red_green_test"
        return define_red_green_problem(config)
    elseif config["type"] == "triangle"
        return define_triangle_problem(config)
    elseif config["type"] == "special_corner"
        return define_special_corner_problem(config)
    end
end

function define_left_of_blue_problem(config)
    l = config["length"]
    w = config["width"]
    accent_wall = config["accent_wall"]
    prize_spec = config["prize"]

    if l == w 
        close_distance = mid 
        far_distance = mid
    else
        close_distance = close 
        far_distance = far
    end

    accent_color = accent_wall ? blue : white

    wall1 = Wall(close_distance, white)
    wall2 = Wall(far_distance, accent_color)
    wall3 = Wall(close_distance, white)
    wall4 = Wall(far_distance, white)

    corner1 = Corner(wall1, wall2)
    corner2 = Corner(wall2, wall3)
    corner3 = Corner(wall3, wall4)
    corner4 = Corner(wall4, wall1)

    locations = [wall1, corner1, wall2, corner2, wall3, corner3, wall4, corner4] 
    if prize_spec == "left"
        prize_location = corner1
    elseif prize_spec == "right"
        prize_location = corner2
    elseif prize_spec == "center"
        prize_location = wall2
    elseif prize_spec == "far-right"
        prize_location = wall3
    elseif prize_spec == "far-left"
        prize_location = wall1
    elseif prize_spec == "far-left-corner"
        prize_location = corner3
    elseif prize_spec == "far-right-corner"
        prize_location = corner4
    end

    scene = Scene(locations, prize_location)

    return scene
end

function define_spatial_lang_problem(config)
    utterance = config["utterance"]
    shift = config["shift"]
    left = config["left"]
    center = Spot(Position(shift, 0, 0))

    spots = [Spot(Position(shift - 1, 0, 0)), 
             Spot(Position(shift + 1, 0, 0)), 
             Spot(Position(shift, 0, -1)), 
             Spot(Position(shift, 0, 1)), 
             Spot(Position(shift, -1, 0)), 
             Spot(Position(shift, 1, 0))]
    if left 
        Scene(spots, spots[1], utterance)
    else # right
        Scene(spots, spots[2], utterance)
    end 
end

function define_red_green_problem(config)
    utterance = config["utterance"]
    diagonal = config["diagonal"]
    prize_left_color = config["prize_left_color"]
    order = config["order"]

    match_shift = 2 * (findall(x -> x == "M", order)[1] - 2)
    reflection_shift = 2 * (findall(x -> x == "R", order)[1] - 2)

    match = Whole(
        Half((prize_left_color == "green" ? -1 : 1) + match_shift), 
        Half((prize_left_color == "green" ? 1 : -1) + match_shift),
        diagonal 
    )

    reflection = Whole(
        Half((prize_left_color == "green" ? 1 : -1) + reflection_shift), 
        Half((prize_left_color == "green" ? -1 : 1) + reflection_shift),
        diagonal 
    )

    different = Whole(
        Half(0), 
        Half(0),
        !diagonal
    )

    associations = Dict(
        "M" => match,
        "R" => reflection,
        "D" => different,
    )

    locations = map(x -> associations[x], order)
    scene = Scene(locations, match, utterance)
    return scene
end

function define_triangle_problem(config)
    wall1 = Wall(far, white)
    wall2 = Wall(close, white)
    wall3 = Wall(close, white)

    corner1 = Corner(wall1, wall2)
    corner2 = Corner(wall2, wall3)
    corner3 = Corner(wall3, wall1)

    prize_left_depth = config["prize_left_side"] == "close" ? close : far
    prize_right_depth = config["prize_right_side"] == "close" ? close : far

    prize = filter(x -> x.wall1.depth == prize_left_depth && x.wall2.depth == prize_right_depth, [corner1, corner2, corner3])[1]

    locations = [wall1, corner1, wall2, corner2, wall3, corner3]
    scene = Scene(locations, prize)
end

function define_special_corner_problem(config)
    wall1 = Wall(close, white)
    wall2 = Wall(far, white)
    wall3 = Wall(close, white)
    wall4 = Wall(far, white)

    corner1 = SpecialCorner(wall1, wall2, blue)
    corner2 = Corner(wall2, wall3)
    corner3 = SpecialCorner(wall3, wall4, white)
    corner4 = Corner(wall4, wall1)

    locations = [wall1, corner1, wall2, corner2, wall3, corner3, wall4, corner4] 
    prize = corner1

    scene = Scene(locations, prize)
    return scene
end

# scene = define_spatial_reasoning_problem("spatial_config/configs/rect_room_blue_wall_left_prize.json")