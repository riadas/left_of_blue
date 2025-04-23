function my_left(location_arg::Spot)::Bool
    location_arg.position.x < 0
end
function my_right(location_arg::Spot)::Bool
    location_arg.position.x > 0
end
