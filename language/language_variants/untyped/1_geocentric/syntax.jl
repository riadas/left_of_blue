# import semantics
include("semantics.jl")
using StatsBase 

function generate_program(beacon)
    gen_pred(beacon)
end

recurse_param = 0.2

function gen_pred(prize::Wall)
    sample([
        gen_geo_pred(prize),
        gen_nongeo_pred(prize),
        gen_hybrid_pred(prize),
    ])
end

function gen_pred(prize::Corner)
    sample([
        gen_geo_pred(prize),
    ])
end

function gen_pred(prize::Spot)
    gen_geo_pred(prize)
end

# predicate is about a Wall or Corner
function gen_geo_pred(prize::Wall)
    pred = "$(gen_geo_field(prize)) $(gen_geo_comparison()) $(gen_geo_value())"
    if rand() < recurse_param 
        "($(pred)) & ($(gen_geo_pred(prize)))"
    else
        pred
    end
end

function gen_geo_pred(prize::Corner)
    pred = sample([
        "$(gen_geo_field(prize)) $(gen_geo_comparison()) $(gen_geo_field(prize))",
    ])
    if rand() < recurse_param 
        "($(pred)) & ($(gen_geo_pred(prize)))"
    else
        pred
    end
end

function gen_nongeo_pred(prize::Wall)
    pred = "$(gen_nongeo_field(prize)) $(gen_nongeo_comparison()) $(gen_nongeo_value())" 
    if rand() < recurse_param
        "($(pred)) & ($(gen_nongeo_pred(prize)))"     
    else
        pred
    end
end 

function gen_hybrid_pred(prize::Wall)
    pred = sample([
        "($(gen_geo_pred(prize))) & ($(gen_nongeo_pred(prize)))",
    ])
    if rand() < recurse_param
        sample([
            "($(pred)) & ($(gen_hybrid_pred(prize)))",
            "($(pred)) & ($(gen_geo_pred(prize)))",
            "($(pred)) & ($(gen_nongeo_pred(prize)))",
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

function gen_nongeo_value()
    sample([
        "blue",
        "white"
    ])
end

function gen_nongeo_field(prize::Wall)
    "location.color"
end

# function gen_hybrid_field(prize::Corner)
#     sample([
#         "location.wall1.color",
#         "location.wall2.color"
#     ])
# end

function gen_nongeo_comparison()
    sample([
        "==",
        "!="
    ])
end

# predicate is about a Spot

function gen_geo_pred(prize::Spot)
    "true"
end