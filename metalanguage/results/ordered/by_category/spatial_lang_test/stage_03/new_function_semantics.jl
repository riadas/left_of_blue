function left_of(location1_arg::Spot, location2_arg::Spot)::Bool
    location2_arg.position.x > location1_arg.position.x
end
