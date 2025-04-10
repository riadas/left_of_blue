function right_of(location_arg::Wall, color_arg::COLOR)::Bool
    right_of(next(location_arg, locations), color_arg)
end
