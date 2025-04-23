function my_left(location_arg::Spot)::Bool
    location_arg.position.x < 0
end
function my_right(location_arg::Spot)::Bool
    location_arg.position.x > 0
end
function left_of(half1_arg::Half, half2_arg::Half)::Bool
    half2_arg.x > half1_arg.x
end
function left_of(location_arg::Wall, color_arg::COLOR)::Bool
    left_of(prev(location_arg, locations), color_arg)
end
function right_of(location_arg::Wall, color_arg::COLOR)::Bool
    right_of(next(location_arg, locations), color_arg)
end
