function left_of(location_arg::Corner, color_arg::COLOR, depth_arg::DEPTH)::Bool
    left_of(location_arg, color_arg) && location_arg.wall2.depth == depth_arg
end
function right_of(location_arg::Corner, color_arg::COLOR, depth_arg::DEPTH)::Bool
    right_of(location_arg, color_arg) && location_arg.wall1.depth == depth_arg
end
