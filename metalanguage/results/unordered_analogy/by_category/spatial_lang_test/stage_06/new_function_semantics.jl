# no new permanent functions -- language augmentation test (max AST size = 9)/n# temporary functions: 2
function right_of(location1_arg::Spot, location2_arg::Spot)::Bool
    location1_arg.position.x > location2_arg.position.x
end

function left_of(location1_arg::Spot, location2_arg::Spot)::Bool
    location1_arg.position.x < location2_arg.position.x
end
