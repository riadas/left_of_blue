# no new permanent functions -- language augmentation test (max AST size = 10)/n# temporary functions: 0
# no new permanent functions -- language augmentation test (max AST size = 10)/n# temporary functions: 2
function right_of(location1_arg::Spot, location2_arg::Spot)::Bool
    location1_arg.position.x > location2_arg.position.x
end

function left_of(location1_arg::Spot, location2_arg::Spot)::Bool
    location1_arg.position.x < location2_arg.position.x
end
# no new permanent functions -- language augmentation test (max AST size = 10)/n# temporary functions: 4
function right_of(location1_arg::Half, location2_arg::Half)::Bool
    location1_arg.x > location2_arg.x
end

function prettier_than(location1_arg::Half, location2_arg::Half)::Bool
    location1_arg.x > location2_arg.x
end

function left_of(half1_arg::Half, half2_arg::Half)::Bool
    half1_arg.x < half2_arg.x
end

function prettier_than(half1_arg::Half, half2_arg::Half)::Bool
    half1_arg.x < half2_arg.x
end
