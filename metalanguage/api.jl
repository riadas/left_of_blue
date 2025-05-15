function translate_from_NL_and_image(scene, functions, max_language_augmented_AST_size)
    println(functions)
    utterance = scene.utterance 
    types = map(x -> typeof(x), scene.locations)
    if Whole in types # red-green test
        parts = split(lowercase(utterance), " ")
        red_index = findall(x -> x == "red", parts)
        green_index = findall(x -> x == "green", parts)
        if red_index < green_index 
            first_program_arg = "location.coral"
            second_program_arg = "location.green"
        else
            first_program_arg = "location.green"
            second_program_arg = "location.coral"
        end
        new_function_name_parts = reverse(sort(filter(x -> !(x in ["the", "is", "to", "object", "green", "red"]), parts), by=length))
        new_function_name = join(new_function_name_parts, "_")
        new_program = "$(new_function_name)($(first_program_arg), $(second_program_arg))"

        name_core = filter(x -> length(x) > 2, new_function_name_parts)[1]

        synthesized_functions = filter(x -> x.definition != "" && !occursin("_of", x.name), functions)
        funcs_with_similar_name = filter(x -> occursin(name_core, x.name), synthesized_functions)

        new_function = nothing
        new_definition = ""

        if funcs_with_similar_name != [] # directional label
            same_type_funcs = filter(x -> Half in x.arg_types, funcs_with_similar_name)
            if same_type_funcs != []
                similar_func = same_type_funcs[1]
                old_definition = similar_func.definition
            else
                similar_func = funcs_with_similar_name[1] # has Spot input types, instead of half 
                old_definition = replace(similar_func.definition, ".position.x" => ".x")
            end
            # generate new temporary semantics 
            parts = split(old_definition, " ")
            old_first_arg_expr = parts[1]
            old_second_arg_expr = parts[end]

            arg_name = similar_func.arg_names[1]
            new_arg1_name = replace(arg_name, "_" => "1_")
            new_arg2_name = replace(arg_name, "_" => "2_")
            new_first_arg_expr = replace(old_first_arg_expr, arg_name => new_arg1_name)
            new_second_arg_expr = replace(old_first_arg_expr, arg_name => new_arg2_name)
            new_parts = [new_first_arg_expr, parts[2:end-1]..., new_second_arg_expr]
            new_definition = join(new_parts, " ")
            new_function = Function(new_function_name, [new_arg1_name, new_arg2_name], [Half, Half], new_definition)

            println("results!")
            println(new_function)
            println(new_definition)
            if size(Meta.parse(new_definition)) <= max_language_augmented_AST_size
                (new_function, new_program)
            else
                (nothing, "")
            end
        else # asymmetric, non-spatial label (e.g. "prettier than")
            # evaluate both my_left and my_right on the first_arg 
            left_func = "location -> my_left($(first_program_arg))"
            right_func = "location -> my_right($(first_program_arg))"

            global locations = scene.locations
            correct_func = nothing
            
            correct_func = left_func
            global x = eval(Meta.parse(correct_func))

            shift = (scene.prize.coral.x + scene.prize.green.x)/2
            shifted_prize = Whole(Half(scene.prize.green.x - shift), Half(scene.prize.coral.x - shift), scene.prize.diagonal)
            global new_locations = [shifted_prize]
            res = @eval filter($x, $new_locations)

            if res == []
                correct_func = right_func
            end

            old_func_name = split(split(correct_func, "(")[1], " ")[end]
            old_function = filter(x -> x.name == old_func_name, synthesized_functions)
            if length(old_function) == 0
                return (nothing, "")
            else
                same_type_funcs = filter(x -> Half in x.arg_types, old_function)
                if same_type_funcs != []
                    old_function = same_type_funcs[1]
                    old_definition = old_function.definition
                else
                    old_function = old_function[1] # has Spot input types, instead of half 
                    old_definition = replace(old_function.definition, ".position.x" => ".x")
                end

                # old_function = old_function[1]
            end

            # old_definition = old_function.definition
            arg_name = old_function.arg_names[1]

            parts = split(old_definition, " ")
            old_first_arg_expr = parts[1]
            old_second_arg_expr = parts[end]

            arg_name = old_function.arg_names[1]
            new_arg1_name = replace(arg_name, "_" => "1_")
            new_arg2_name = replace(arg_name, "_" => "2_")
            new_first_arg_expr = replace(old_first_arg_expr, arg_name => new_arg1_name)
            new_second_arg_expr = replace(old_first_arg_expr, arg_name => new_arg2_name)
            new_parts = [new_first_arg_expr, parts[2:end-1]..., new_second_arg_expr]
            new_definition = join(new_parts, " ")
            new_function = Function(new_function_name, [new_arg1_name, new_arg2_name], [Half, Half], new_definition)


            println("results!")
            println(new_function)
            println(new_definition)
            if size(Meta.parse(new_definition)) <= max_language_augmented_AST_size
                (new_function, new_program)
            else
                (nothing, "")
            end

        end

    else
        return (nothing, "")
    end

end

function translate_from_NL(scene, functions, max_language_augmented_AST_size)
    utterance = scene.utterance 
    types = map(x -> typeof(x), scene.locations)

    if Corner in types 
        program_segment = "&& (location.wall2.color == blue || location.wall1.color == blue)"
        if 12 <= max_language_augmented_AST_size 
            return (nothing, program_segment)
        else
            return (nothing, "")
        end
    end

    if Spot in types # spatial lang understanding test
        center_x = Int(sum(map(x -> x.position.x, scene.locations))/length(scene.locations))
        parts = split(lowercase(utterance), " ")
        first_program_arg = "location"
        second_program_arg = "Spot(Position($(center_x), 0, 0))"
        new_function_name_parts = reverse(sort(filter(x -> !(x in ["put", "the", "is", "to", "object", "blue", "red", "green"]), parts), by=length))
        new_function_name = join(new_function_name_parts, "_")
        new_program = "$(new_function_name)($(first_program_arg), $(second_program_arg))"

        name_core = filter(x -> length(x) > 2, new_function_name_parts)[1]

        synthesized_functions = filter(x -> x.definition != "" && !occursin("_of", x.name), functions)
        funcs_with_similar_name = filter(x -> occursin(name_core, x.name), synthesized_functions)
        if funcs_with_similar_name != [] # directional label
            same_type_funcs = filter(x -> Spot in x.arg_types, funcs_with_similar_name)
            if same_type_funcs != []
                similar_func = same_type_funcs[1]
                old_definition = similar_func.definition
            else
                similar_func = funcs_with_similar_name[1] # has Half input types, instead of Spot 
                old_definition = replace(similar_func.definition, ".x" => ".position.x")
            end
            # generate new temporary semantics 
            parts = split(old_definition, " ")
            old_first_arg_expr = parts[1]
            old_second_arg_expr = parts[end]

            arg_name = similar_func.arg_names[1]
            new_arg1_name = replace(arg_name, "_" => "1_")
            new_arg2_name = replace(arg_name, "_" => "2_")
            new_first_arg_expr = replace(old_first_arg_expr, arg_name => new_arg1_name)
            new_second_arg_expr = replace(old_first_arg_expr, arg_name => new_arg2_name)
            new_parts = [new_first_arg_expr, parts[2:end-1]..., new_second_arg_expr]
            new_definition = join(new_parts, " ")
            new_function = Function(new_function_name, [new_arg1_name, new_arg2_name], [Spot, Spot], new_definition)
        
            println("results!")
            println(new_function)
            println(new_definition)
            if size(Meta.parse(new_definition)) <= max_language_augmented_AST_size
                (new_function, new_program)
            else
                (nothing, "")
            end
        
        else
            # give up
            return (nothing, "")
        end
    else
        return (nothing, "")
    end
end