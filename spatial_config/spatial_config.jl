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
        return define_spatial_lang_problem()
    elseif config["type"] == "red_green_test"
        return define_red_green_problem(config)
    end
end

function define_left_of_blue_problem(config)
    l = config["length"]
    w = config["width"]
    accent_wall = config["accent_wall"]
    corner_prize = config["corner_prize"]

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
    prize_location = corner_prize ? corner1 : wall2
    scene = Scene(locations, prize_location)

    return scene
end

function define_spatial_lang_problem()
    center = Spot(Position(0, 0, 0))
    spots = [Spot(Position(-1, 0, 0)), 
             Spot(Position(1, 0, 0)), 
             Spot(Position(0, 0, -1)), 
             Spot(Position(0, 0, 1)), 
             Spot(Position(0, -1, 0)), 
             Spot(Position(0, 1, 0))]
    
    scene = Scene(spots, spots[1])
    return scene    
end

function define_red_green_problem(config)
    diagonal = config["diagonal"]
    prize_left_color = config["prize_left_color"]
    order = config["order"]

    match = Whole(
        Half(prize_left_color == "green" ? -1 : 1), 
        Half(prize_left_color == "green" ? 1 : -1),
        diagonal 
    )

    reflection = Whole(
        Half(prize_left_color == "green" ? 1 : -1), 
        Half(prize_left_color == "green" ? -1 : 1),
        diagonal 
    )

    different = Whole(
        Half(prize_left_color == "green" ? -1 : 1), 
        Half(prize_left_color == "green" ? 1 : -1),
        !diagonal
    )

    associations = Dict(
        "M" => match,
        "R" => reflection,
        "D" => different,
    )

    locations = map(x -> associations[x], order)
    scene = Scene(locations, match)
    return scene
end

scene = define_spatial_reasoning_problem("spatial_config/configs/rect_room_blue_wall_center_prize.json")