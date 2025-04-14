function left_of(location_arg::Corner, color_arg::COLOR)::Bool
    at(location_arg.wall2, color_arg)
end
function left_of(location_arg::Corner, color_arg::COLOR)::Bool
    at(location_arg.wall2, color_arg)
end
function left_of(location_arg::Corner, color_arg::COLOR)::Bool
    at(location_arg.wall2, color_arg)
end
function right_of(location_arg::Corner, color_arg::COLOR)::Bool
    at(location_arg.wall1, color_arg)
end
function right_of(location_arg::Corner, color_arg::COLOR)::Bool
    at(location_arg.wall1, color_arg)
end
function right_of(location_arg::Corner, color_arg::COLOR)::Bool
    at(location_arg.wall1, color_arg)
end
function left_of(location_arg::Wall, color_arg::COLOR)::Bool
    at(next(location_arg, locations).wall2, color_arg)
end
function left_of(location_arg::Wall, color_arg::COLOR)::Bool
    at(next(location_arg, locations).wall2, color_arg)
end
function left_of(location_arg::Wall, color_arg::COLOR)::Bool
    at(next(location_arg, locations).wall2, color_arg)
end
function right_of(location_arg::Wall, color_arg::COLOR)::Bool
    at(prev(location_arg, locations).wall1, color_arg)
end
function right_of(location_arg::Wall, color_arg::COLOR)::Bool
    at(prev(location_arg, locations).wall1, color_arg)
end
function right_of(location_arg::Wall, color_arg::COLOR)::Bool
    at(prev(location_arg, locations).wall1, color_arg)
end
