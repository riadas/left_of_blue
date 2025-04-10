function left_of(location_arg::Wall, color_arg::COLOR)::Bool
    left_of(prev(location_arg, locations), color_arg)
end
