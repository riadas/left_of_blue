function at(location_arg::Wall, color_arg::COLOR)::Bool
    location_arg.color == color_arg
end
function at(location_special_arg::SpecialCorner, color_arg::COLOR)::Bool
    location_special_arg.color == color_arg
end
