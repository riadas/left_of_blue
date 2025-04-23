include("base_semantics.jl")

mutable struct Function 
    name::String
    arg_names::Vector{String}
    arg_types::Vector{DataType}
    definition::String
end

global base_syntax = Dict(
    Wall =>   "location.depth == genDEPTH", # | lib_at Wall COLOR
    Corner => "location.wall1.depth genComparison location.wall2.depth",
    SpecialCorner => "location.wall1.depth genComparison location.wall2.depth",
    Spot =>   "true",
    Whole =>  "location.coral.x != 0", # geometry match
)

global base_semantics = Dict(
    Wall =>   "gen{arg2} genComparison arg2", # | lib_at Wall COLOR
    Corner => "gen{arg2} genComparison arg2", # | lib_at Wall COLOR
    SpecialCorner => "gen{arg2} genComparison arg2", # | lib_at Wall COLOR
    Spot =>   "genInt genComparison genInt",
    Half =>  "genInt genComparison genInt"
)

function update_semantics_cfg(current_semantics_cfg, function_signature::Function)
    first_arg_type = function_signature.arg_types[1]
    cfg = current_semantics_cfg[first_arg_type]
    
    name = function_signature.name 
    arg_types = function_signature.arg_types 
    new_option = """lib_$(name) $(join(arg_types, " "))"""
    new_cfg = "$(cfg) | $(new_option)"
    current_semantics_cfg[first_arg_type] = new_cfg

    if first_arg_type == Wall 
        current_semantics_cfg[Corner] = new_cfg
    elseif first_arg_type == Corner 
        current_semantics_cfg[Wall] = new_cfg
    elseif first_arg_type == SpecialCorner 
        current_semantics_cfg[SpecialCorner] = new_cfg
    end

    return current_semantics_cfg
end

function generate_semantics(function_signature::Function, current_semantics_cfg::Dict)
    first_arg_type = function_signature.arg_types[1]
    cfg = current_semantics_cfg[first_arg_type]

    if length(function_signature.arg_types) == 3 
        index_pairs = [[1, 2], [1, 3]]
        partial_semantics = []
        for index_pair in index_pairs 
            partial_arg_names = map(i -> function_signature.arg_names[i], index_pair)
            partial_arg_types = map(i -> function_signature.arg_types[i], index_pair)
            partial_function_signature = Function(function_signature.name, partial_arg_names, partial_arg_types, "")
            s = generate_semantics(partial_function_signature, current_semantics_cfg)
            push!(partial_semantics, s)
        end

        return "$(partial_semantics[1]) && $(partial_semantics[2])"
    end

    option_strings = split(cfg, " | ")
    options = []
    for option_str in option_strings
        
        if occursin("lib_", option_str) 
            components = split(replace(option_str, "lib_" => ""), " ")
            function_name = components[1]
            lib_function_arg_types = components[2:end]
            argument_expressions = []
            
            if first_arg_type in [Wall, Corner, SpecialCorner]
                if function_signature.arg_types[end] != eval(Meta.parse(lib_function_arg_types[end]))
                    continue
                end
            end

            arg_expressions = []
            for i in 1:length(lib_function_arg_types)
                if first_arg_type in [Wall, Corner, SpecialCorner] && (i == length(lib_function_arg_types))
                    push!(arg_expressions, function_signature.arg_names[end])
                else
                    arg_type = lib_function_arg_types[i]
                    arg_expression = eval(Meta.parse("gen$(arg_type)_semantics"))(function_signature.arg_names, function_signature.arg_types)     
                    push!(arg_expressions, arg_expression)
                end
            end
            expression = """$(function_name)($(join(arg_expressions, ", ")))"""
            push!(options, expression)
        else
            components = split(option_str, " ")
            formatted_components = []
            for component in components 
                formatted_component = component
                
                if occursin("{arg", component)
                    arg_idx = parse(Int, split(component, "{arg")[end][1])
                    arg_type = function_signature.arg_types[arg_idx]
                    formatted_component = replace(formatted_component, "{arg$(arg_idx)}" => string(arg_type))
                elseif occursin("arg", component)
                    arg_idx = parse(Int, split(component, "arg")[end][1])
                    arg_name = function_signature.arg_names[arg_idx]
                    formatted_component = replace(formatted_component, "arg$(arg_idx)" => arg_name)
                end

                if occursin(".", formatted_component)
                    part1, part2 = split(formatted_component, ".")
                    part1 = "$(part1)_semantics"
                    formatted_component = "$(eval(Meta.parse(part1))(function_signature.arg_names, function_signature.arg_types)).$(part2)"
                end

                if occursin("gen", formatted_component)
                    formatted_component = eval(Meta.parse("$(formatted_component)_semantics"))(function_signature.arg_names, function_signature.arg_types)
                end

                push!(formatted_components, formatted_component)
            end 
            expression = join(formatted_components, " ")
            push!(options, expression)
        end
    end
    rand(options)
end

function generate_syntax(prize_type::DataType, current_syntax_cfg; rect=true, shift=0)
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
                arg_expression = eval(Meta.parse("gen$(arg_type)_syntax"))(arg_names, arg_types, rect=rect, shift=shift)     
                push!(arg_expressions, arg_expression)
            
            end
            expression = """$(function_name)($(join(arg_expressions, ", ")))"""
            push!(options, expression)
        else
            components = split(option_str, " ")
            formatted_components = []
            for component in components 
                if occursin("gen", component)
                    formatted_component = eval(Meta.parse("$(component)_syntax"))(arg_names, arg_types, rect=rect, shift=shift)
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

function update_syntax_cfg(current_syntax_cfg, function_signature::Function; remove=false)
    first_arg_type = function_signature.arg_types[1]
    if first_arg_type != Half
        cfg = current_syntax_cfg[first_arg_type] 
    else
        first_arg_type = Whole
        cfg = current_syntax_cfg[Whole]
    end
    
    name = function_signature.name 
    arg_types = function_signature.arg_types 
    new_option = """lib_$(name) $(join(arg_types, " "))"""
    if !remove 
        new_cfg = "$(cfg) | $(new_option)"
        current_syntax_cfg[first_arg_type] = new_cfg
    else
        current_syntax_cfg[first_arg_type] = replace(cfg, " | $(new_option)" => "")
    end
    return current_syntax_cfg
end

# ----- syntax generator functions ----- 

function genWall_syntax(arg_names::Vector{String}, arg_types::Vector{DataType}; rect=true, shift=0)
    "location"
end

function genCorner_syntax(arg_names::Vector{String}, arg_types::Vector{DataType}; rect=true, shift=0)
    "location"
end

function genSpecialCorner_syntax(arg_names::Vector{String}, arg_types::Vector{DataType}; rect=true, shift=0)
    "location"
end

function genDEPTH_syntax(arg_names::Vector{String}, arg_types::Vector{DataType}; rect=true, shift=0)
    if rect 
        rand(["close", "far"])
    else
        rand(["mid"])
    end
end

function genCOLOR_syntax(arg_names::Vector{String}, arg_types::Vector{DataType}; rect=true, shift=0)
    rand(["blue", "white"]) # , "red"
end

function genSpot_syntax(arg_names::Vector{String}, arg_types::Vector{DataType}; rect=true, shift=0)
    idxs = findall(x -> x == Spot, arg_types)
    names = map(i -> arg_names[i], idxs)
    rand([names..., "Spot(Position($(shift), 0, 0))"])
end

function genHalf_syntax(arg_names::Vector{String}, arg_types::Vector{DataType}; rect=true, shift=0)
    idxs = findall(x -> x == Whole, arg_types)
    names = map(i -> arg_names[i], idxs)
    options = []
    for name in names 
        push!(options, "$(name).coral")
        push!(options, "$(name).green")
    end
    rand(options)
end

function genComparison_syntax(arg_names::Vector{String}, arg_types::Vector{DataType}; rect=true, shift=0)
    rand(["<", ">", "=="])
end

# ----- semantics generator functions -----

function genWall_semantics(arg_names::Vector{String}, arg_types::Vector{DataType})
    arg_name = arg_names[1]
    type = arg_types[1]

    if type == Wall 
        choice = rand(["$(arg_name)", 
                        "prev($(arg_name), locations).wall1", 
                        "prev($(arg_name), locations).wall2", 
                        "next($(arg_name), locations).wall1",
                        "next($(arg_name), locations).wall2"])
    elseif type == Corner || type == SpecialCorner
        choice = rand(["$(arg_name).wall1",
                        "$(arg_name).wall2"])
    end
    choice
end

function genCorner_semantics(arg_names::Vector{String}, arg_types::Vector{DataType})
    arg_name = arg_names[1]
    type = arg_types[1]

    if type == Wall 
        choice = rand(["prev($(arg_name), locations)",
                       "next($(arg_name), locations)"])
    elseif type == Corner
        choice = rand(["$(arg_name)"])
    end
    choice
end

function genSpecialCorner_semantics(arg_names::Vector{String}, arg_types::Vector{DataType})
    arg_name = arg_names[1]
    type = arg_types[1]
    choice = rand(["$(arg_name)"])
    choice
end

function genDEPTH_semantics(arg_names::Vector{String}, arg_types::Vector{DataType})
    wall = genWall_semantics(arg_names, arg_types)
    "$(wall).depth"
end

function genCOLOR_semantics(arg_names::Vector{String}, arg_types::Vector{DataType})
    if arg_types[1] == Wall 
        wall = genWall_semantics(arg_names, arg_types)
        "$(wall).color"
    elseif arg_types[1] == SpecialCorner
        "$(arg_names[1]).color"
    end

end

function genSpot_semantics(arg_names::Vector{String}, arg_types::Vector{DataType})
    idxs = findall(x -> x == Spot, arg_types)
    rand(map(i -> arg_names[i], idxs))
end

function genHalf_semantics(arg_names::Vector{String}, arg_types::Vector{DataType})
    idxs = findall(x -> x == Half, arg_types)
    rand(map(i -> arg_names[i], idxs))
end

function genInt_semantics(arg_names::Vector{String}, arg_types::Vector{DataType})
    type = arg_types[1]
    if type in [Spot, Half]
        genInt_semantics(rand(arg_names), type)
    end
end

function genInt_semantics(arg_name::String, arg_type::DataType)
    choices = ["0", "-1", "1"]
    if arg_type == Spot
        for coord in ["x", "y", "z"] # "y", "z"
            push!(choices, "$(arg_name).position.$(coord)")
        end
    elseif arg_type == Half
        push!(choices, "$(arg_name).x")
    end
    rand(choices)
end

function genComparison_semantics(arg_names::Vector{String}, arg_types::Vector{DataType})
    if arg_types[1] in [Spot, Half]
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
    """function $(function_sig.name)($(join(typed_args, ", ")))::Bool
        $(function_sig.definition)
    end
    """
end

function Base.size(x::Expr)
    l = 0 
    for arg in x.args 
        if arg isa Expr 
            l += size(arg)
        else
            l += 1
        end
    end
    l
end

function Base.size(x::Union{Symbol, Int, Bool})
    1
end

function edit_distance(x1::Expr, x2::Expr)
    same_structure = equivalent_tree_structure(x1, x2)
    if !same_structure 
        -1
    end

    function edit_dist(x1::Expr, x2::Expr)
        dist = 0 
        if x1.head != x2.head 
            dist += 1
        end

        for i in 1:length(x1.args)
            arg1 = x1.args[i]
            arg2 = x2.args[i]

            if arg1 isa Expr && arg2 isa Expr 
                dist += edit_dist(arg1, arg2)
            elseif arg1 != arg2
                dist += 1
            end

        end 

        dist
    end

    edit_dist(x1, x2)
end

function equivalent_tree_structure(x1::Expr, x2::Expr)
    if length(x1.args) != length(x2.args)
        false
    else
        for i in 1:length(x1.args)
            arg1 = x1.args[i]
            arg2 = x2.args[i]

            if arg1 isa Expr && arg2 isa Expr 
                if !equivalent_tree_structure(arg1, arg2)
                    false
                end
            elseif arg1 isa Expr && !(arg2 isa Expr) || !(arg1 isa Expr) && arg2 isa Expr    
                false
            end

        end
    end
    true
end