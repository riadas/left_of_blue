function left_of(location_arg::Wall, color_arg::COLOR)::Bool
    left_of(prev(location_arg, locations), color_arg)
end
function left_of(location_arg::Wall, color_arg::COLOR)::Bool
    left_of(prev(location_arg, locations), color_arg)
end
function left_of(location_arg::Wall, color_arg::COLOR)::Bool
    left_of(prev(location_arg, locations), color_arg)
end
function right_of(location_arg::Wall, color_arg::COLOR)::Bool
    right_of(next(location_arg, locations), color_arg)
end
function right_of(location_arg::Wall, color_arg::COLOR)::Bool
    right_of(next(location_arg, locations), color_arg)
end
function right_of(location_arg::Wall, color_arg::COLOR)::Bool
    right_of(next(location_arg, locations), color_arg)
end
