function left_of(location_arg::Corner, color_arg::COLOR)::Bool
    at(location_arg.wall2, color_arg)
end
function right_of(location_arg::Corner, color_arg::COLOR)::Bool
    at(location_arg.wall1, color_arg)
end
function left_of(half1_arg::Half, half2_arg::Half)::Bool
    half1_arg.x < half2_arg.x
end
function left_of(location_arg::Wall, color_arg::COLOR)::Bool
    at(next(location_arg, locations).wall2, color_arg)
end
function left_of(location1_arg::Spot, location2_arg::Spot)::Bool
    location1_arg.position.x < location2_arg.position.x
end
function right_of(location_arg::Wall, color_arg::COLOR)::Bool
    at(prev(location_arg, locations).wall1, color_arg)
end
