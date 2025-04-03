include("demo_typed.jl")
using StatsBase 

recurse_param = 0.2

function gen_pred(prize::Union{Wall, Corner})
    sample([
        gen_geo_pred(prize),
        gen_nongeo_pred(prize),
        gen_hybrid_pred(prize),
    ])
end

function gen_pred(prize::Spot)
    gen_geo_pred(prize)
end

# predicate is about a Wall or Corner
function gen_geo_pred(prize::Wall)
    pred = "$(gen_geo_field(prize)) $(gen_geo_comparison()) $(gen_geo_value())"
    if rand() < recurse_param 
        "$(pred) & $(gen_geo_pred(prize))"
    else
        pred
    end
end

function gen_geo_pred(prize::Corner)
    pred = sample([
        "$(gen_geo_field(prize)) $(gen_geo_comparison()) $(gen_geo_value())",
        "$(gen_geo_function_call(prize))"
    ])
    if rand() < recurse_param 
        "$(pred) & $(gen_geo_pred(prize))"
    else
        pred
    end
end

function gen_nongeo_pred(prize::Union{Wall, Corner})
    pred = "$(gen_nongeo_field(prize)) $(gen_nongeo_comparison()) $(gen_nongeo_value())" 
    if rand() < recurse_param
        "$(pred) & $(gen_nongeo_pred(prize))"     
    else
        pred
    end
end 

function gen_hybrid_pred(prize::Union{Wall, Corner})
    pred = sample([
        "$(gen_geo_pred(prize)) & $(gen_nongeo_pred(prize))",
        "$(gen_hybrid_function_call(prize))"
    ])
    if rand() < recurse_param
        sample([
            "$(pred) & $(gen_hybrid_pred(prize))",
            "$(pred) & $(gen_geo_pred(prize))",
            "$(pred) & $(gen_nongeo_pred(prize))",
        ])
    else
        pred
    end
end

# helpers 

function gen_geo_field(prize::Wall)
    "location.depth"
end

function gen_geo_field(prize::Corner)
    sample([
        "location.wall1.depth",
        "location.wall2.depth"
    ])
end

function gen_geo_comparison()
    sample([
        "==",
        "!=",
        ">",
        "<"
    ])
end

function gen_geo_value()
    sample([
        "close",
        "mid",
        "far"
    ])
end

function gen_geo_function_call(prize::Corner)
    sample([
        "left(location, $(gen_geo_value()))",
        "right(location, $(gen_geo_value()))",
    ])
end

function gen_nongeo_value()
    sample([
        "blue",
        "white"
    ])
end

function gen_nongeo_field(prize::Wall)
    "location.color"
end

function gen_nongeo_field(prize::Corner)
    sample([
        "location.wall1.color",
        "location.wall2.color"
    ])
end

function gen_nongeo_comparison()
    sample([
        "==",
        "!="
    ])
end

function gen_hybrid_function_call(prize::Wall)
    sample([
        "at(location, $(gen_nongeo_value()))",
        "left(location, $(gen_nongeo_value()), locations)",
        "right(location, $(gen_nongeo_value()), locations)",
        "between(location, $(gen_nongeo_value()), $(gen_nongeo_value()), locations)"
    ])
end

function gen_hybrid_function_call(prize::Corner)
    sample([
        "left(location, $(gen_nongeo_value()))",
        "right(location, $(gen_nongeo_value()))",
        "between(location, $(gen_nongeo_value()), $(gen_nongeo_value()))"
    ])
end

# predicate is about a Spot

function gen_geo_pred(prize::Spot)
    pred = "$(gen_geo_function_call(prize))"
    if rand() < recurse_param
        "$(pred) & $(gen_geo_pred(prize))"
    else
        pred
    end
end

function gen_geo_function_call(prize::Spot)
    sample([
        "left(location)",
        "right(location)",
        "left(location, Spot(Position(0, 0, 0)))",
        "right(location, Spot(Position(0, 0, 0)))"
    ])
end