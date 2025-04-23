function at(location_arg::Wall, color_arg::COLOR)::Bool
    location_arg.color == color_arg
end
function at(location_special_arg::SpecialCorner, color_arg::COLOR)::Bool
    location_special_arg.color == color_arg
end
function my_left(half_arg::Half)::Bool
    half_arg.x < 0
end
function my_left(location_arg::Spot)::Bool
    location_arg.position.x < 0
end
function my_right(location_arg::Spot)::Bool
    location_arg.position.x > 0
end
