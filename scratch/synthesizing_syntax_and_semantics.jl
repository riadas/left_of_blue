include("demo.jl")

struct Whole <: Location
    green::Half
    red::Half
    diagonal::Bool
end

struct Half
    x::Int
end

mutable struct Function 
    name::String
    arg_names::Vector{String}
    arg_types::Vector{DataType}
    definition::String
end

base_syntax = Dict(
    Wall:   "location.depth == genDEPTH | lib_at Wall COLOR",
    Corner:  "location.wall1.depth genComparison location.wall2.depth",
    Spot:    "true",
    Whole:   "true", 
)

base_semantics = Dict(
    Wall:   "genWall.arg2 genComparison arg2 | lib_at Wall COLOR",
    Corner: "genWall.arg2 genComparison arg2 | lib_at Wall COLOR",
    Spot:   "genInt genComparison genInt",
    Whole:  "genInt genComparison genInt"
)

function update_semantics_cfg(current_semantics_cfg, function_signature::Function)
    first_arg_type = function_signature.arg_types[1]
    cfg = current_semantics_cfg[first_arg_type]
    
    name = function_signature.name 
    arg_types = function_signature.arg_types 
    new_option = """lib_$(name) $(join(arg_types, " "))"""
    new_cfg = "$(cfg) | $(new_option)"
    current_semantics_cfg[first_arg_type] = new_cfg
    return current_semantics_cfg
end

function generate_semantics(function_signature::Function, current_semantics_cfg::Dict)
    first_arg_type = function_signature.arg_types[1]
    cfg = current_semantics_cfg[first_arg_type]

    option_strings = split(cfg, " | ")
    options = []
    for option_str in option_strings
        
        if occursin("lib_", option_str) 
            components = split(replace(option_str, "lib_" => ""), " ")
            function_name = components[1]
            lib_function_arg_types = components[2:end]
            argument_expressions = []
            
            if first_arg_type in [Wall, Corner]
                if function_signature.arg_types[end] != eval(lib_function_arg_types[end])
                    continue
                end
            end

            arg_expressions = []
            for i in 1:length(lib_function_arg_types)
                if first_arg_type in [Wall, Corner] && (i == length(lib_function_arg_types))
                    push!(arg_expressions, function_signature.arg_names[end])
                else
                    arg_type = lib_function_arg_types[i]
                    arg_expression = eval("gen$(arg_type)_semantics")(function_signature.arg_names, function_signature.arg_types)     
                    push!(arg_expressions, arg_expression)
                end
            end
            expression = """$(function_name)($(join(arg_expressions, ", ")))"""
            push!(options, expression)
        else
            components = split(option_str, " ")
            formatted_components = []
            for component of components 
                formatted_component = component
                if occursin("arg", component)
                    arg_idx = parse(Int, split(component, "arg")[end][1])
                    arg_name = function_signature.arg_names[arg_idx]
                    formatted_component = replace(formatted_component, "arg$(arg_idx)" => arg_name)                
                end

                if occursin(".", formatted_component)
                    part1, part2 = split(formatted_component, ".")
                    part1 = "$(part1)_semantics"
                    formatted_component = "$(eval(Meta.parse(part1))(function_signature.arg_names, function_signature.arg_types)).$(part2)"
                end

                if "gen" in formatted_component
                    formatted_component = eval(formatted_component)(function_signature.arg_names, function_signature.arg_types)
                end

                push!(formatted_components, formatted_component)
            end 
            expression = join(formatted_components, " ")
            push!(options, expression)
        end
    end
    rand(options)
end

function generate_syntax(prize_type::DataType, current_syntax_cfg)
    cfg = current_syntax_cfg[prize_type]
    arg_names = ["location"]
    arg_types = [prize_type]
    
    option_strings = split(cfg, " | ")
    options = []
    for option_str in option_strings
        if occursin("lib_", option_str)
            components = split(replace(option_str, "lib_" => ""), " ")
            function_name = components[1]
            lib_function_arg_types = components[2:end]
            argument_expressions = []

            arg_expressions = []
            for i in 1:length(lib_function_arg_types)
                arg_type = lib_function_arg_types[i]
                arg_expression = eval("gen$(arg_type)_syntax")(function_signature.arg_names, function_signature.arg_types)     
                push!(arg_expressions, arg_expression)
            
            end
            expression = """$(function_name)($(join(arg_expressions, ", ")))"""
            push!(options, expression)
        else
            components = split(option_str, " ")
            formatted_components = []
            for component in components 
                if occursin("gen", component)
                    formatted_component = eval("$(component)_syntax")(arg_names, arg_types)
                    push!(formatted_components, formatted_component)
                else
                    push!(formatted_components, component)
                end
            end
            expression = join(formatted_components, " ")
            push!(options, expression)
        end
    end
    rand(options)
end

function update_syntax_cfg(current_syntax_cfg, function_signature::Function)
    first_arg_type = function_signature.arg_types[1]
    cfg = current_syntax_cfg[first_arg_type]
    
    name = function_signature.name 
    arg_types = function_signature.arg_types 
    new_option = """lib_$(name) $(join(arg_types, " "))"""
    new_cfg = "$(cfg) | $(new_option)"
    current_syntax_cfg[first_arg_type] = new_cfg
    return current_syntax_cfg
end

# ----- syntax generator functions ----- 

function genWall_syntax(arg_names::Vector{String}, arg_types::Vector{DataType})
    "location"
end

function genCorner_syntax(arg_names::Vector{String}, arg_types::Vector{DataType})
    "location"
end

function genDEPTH_syntax(arg_names::Vector{String}, arg_types::Vector{DataType})
    rand(["close", "mid", "far"])
end

function genCOLOR_syntax(arg_names::Vector{String}, arg_types::Vector{DataType})
    rand(["blue", "white"])
end

function genSpot_syntax(arg_names::Vector{String}, arg_types::Vector{DataType})
    idxs = findall(x -> x == Spot, arg_types)
    names = map(i -> arg_names[i], idxs)
    rand([names..., "Spot(Position(0, 0, 0))"])
end

function genWhole_syntax(arg_names::Vector{String}, arg_types::Vector{DataType})
    idxs = findall(x -> x == Whole, arg_types)
    names = map(i -> arg_names[i], idxs)
    rand(names)
end

function genComparison_syntax(arg_names::Vector{String}, arg_types::Vector{DataType})
    rand(["<", ">", "=="])
end

# ----- semantics generator functions -----

function genWall_semantics(arg_names::Vector{String}, arg_types::Vector{DataType})
    arg_name = arg_names[1]
    type = arg_types[1]

    if type == Wall 
        choice = rand(["$(arg_name)", 
                        "prev($(arg_name)).wall1", 
                        "prev($(arg_name)).wall2", 
                        "next($(arg_name)).wall1",
                        "next($(arg_name)).wall2"])
    elseif type == Corner
        choice = rand(["$(arg_name).wall1",
                        "$(arg_name).wall2"])
    end
    choice
end

function genCorner_semantics(arg_names::Vector{String}, arg_types::Vector{DataType})
    arg_name = arg_names[1]
    type = arg_types[1]

    if type == Wall 
        choice = rand(["prev($(arg_name))",
                       "next($(arg_name))"])
    elseif type == Corner
        choice = rand(["$(arg_name)"])
    end
    choice
end

function genDEPTH_semantics(arg_names::Vector{String}, arg_types::Vector{DataType})
    wall = genWall(arg_names, arg_types)
    "$(wall).depth"
end

function genCOLOR_semantics(arg_names::Vector{String}, arg_types::Vector{DataType})
    wall = genWall(arg_names, arg_types)
    "$(wall).color"
end

function genInt_semantics(arg_names::Vector{String}, arg_types::Vector{DataType})
    type = arg_types[1]
    if type in [Spot, Whole]
        genInt(rand(arg_names), type)
    end
end

function genInt_semantics(arg_name::String, arg_type::DataType)
    choices = ["0", "-1", "1"]
    if arg_type isa Spot
        for coord in ["x", "y", "z"]
            push!(choices, "$(arg_name).position.$(coord)")
        end
    elseif arg_type isa Whole
        push!(choices, ["$(arg_name).green.x", "$(arg_name).red.x"]...)
    end
    rand(choices)
end

function genComparison_semantics(arg_names::Vector{String}, arg_types::Vector{DataType})
    if arg_types[1] in [Spot, Whole]
        rand(["<", ">"])
    else
        "=="
    end
end

function format_new_function_string(function_sig)
    typed_args = []
    for i in 1:length(function_sig.arg_names)
        arg_name = function_sig.arg_names[i]
        arg_type = function_sig.arg_types[i]
        typed_arg = "$(arg_name)::$(arg_type)"
        push!(typed_args, typed_arg)
    end
    """ 
    function $(function_sig.name)($(join(typed_args, ", ")))::Bool
        $(function_sig.definition)
    end
    """
end

function_sig = Function("at", ["location", "color"], [Wall, COLOR], "")

possible_semantics = []
for i in 1:1000
    semantics = generate_semantics(function_sig, base_semantics_cfg)
end
possible_semantics = unique(possible_semantics)

# update syntax cfg to include function
updated_syntax = update_syntax_cfg(base_syntax, function_sig)

for definition in possible_semantics 
    function_sig.definition = definition
    new_function_definition_str = format_new_function_string(function_sig)

    # update semantics.jl file with new function and import file

    # generate lots of programs in the new language, and measure performance across suite of spatial configurations
    # if performance is higher than base language, save that program and its score

end

# TODO: define measure for computing performance over suite of spatial configurations
# TODO: define ordered list of functions to add 
