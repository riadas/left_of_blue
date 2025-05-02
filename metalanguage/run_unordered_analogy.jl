include("metalanguage.jl")
include("../spatial_config/viz.jl")
include("api.jl")

global alpha = 1.0 # 0.5
global base_semantics_str = ""
open("metalanguage/base_semantics.jl", "r") do f 
    global base_semantics_str = read(f, String)
end

# reset results folders
category_names = ["left_of_blue", "spatial_lang_test", "red_green_test"]
combined_results_dir = "metalanguage/results/unordered_analogy/combined"
# if isdir(combined_results_dir)
#     rm(combined_results_dir, recursive=true)
# end
# mkdir(combined_results_dir)

# split_results_dir = "metalanguage/results/unordered_analogy/by_category"
# if isdir(split_results_dir)
#     rm(split_results_dir, recursive=true)
# end
# mkdir(split_results_dir)
# for category_name in category_names 
#     mkdir("$(split_results_dir)/$(category_name)")
# end
combined_to_split_mapping = []
categories = [[Wall, Corner, SpecialCorner, DEPTH, COLOR], [Spot], [Half, Whole]]

function test()
    at_function = Function("at", ["location_arg", "color_arg"], [Wall, COLOR], "")
    at_function_special_corner = Function("at", ["location_special_arg", "color_arg"], [SpecialCorner, COLOR], "")

    my_left_function = Function("my_left", ["location_arg", "depth_arg"], [Corner, DEPTH], "")
    left_of_function = Function("left_of", ["location_arg", "color_arg"], [Corner, COLOR], "")

    my_left_function_spot = Function("my_left", ["location_arg"], [Spot], "")
    left_of_function_spot = Function("left_of", ["location1_arg", "location2_arg"], [Spot, Spot], "")

    my_left_function_whole = Function("my_left", ["half_arg"], [Half], "")
    left_of_function_whole = Function("left_of", ["half1_arg", "half2_arg"], [Half, Half], "")

    my_right_function = Function("my_right", ["location_arg", "depth_arg"], [Corner, DEPTH], "")
    right_of_function = Function("right_of", ["location_arg", "color_arg"], [Corner, COLOR], "")

    my_right_function_spot = Function("my_right", ["location_arg"], [Spot], "")
    right_of_function_spot = Function("right_of", ["location1_arg", "location2_arg"], [Spot, Spot], "")

    my_right_function_whole = Function("my_right", ["half_arg"], [Half], "")
    right_of_function_whole = Function("right_of", ["half1_arg", "half2_arg"], [Half, Half], "")

    left_of_function_wall = Function("left_of", ["location_arg", "color_arg"], [Wall, COLOR], "")
    right_of_function_wall = Function("right_of", ["location_arg", "color_arg"], [Wall, COLOR], "")

    left_of_function_with_depth = Function("left_of", ["location_arg", "color_arg", "depth_arg"], [Corner, COLOR, DEPTH], "")
    right_of_function_with_depth = Function("right_of", ["location_arg", "color_arg", "depth_arg"], [Corner, COLOR, DEPTH], "")

    all_function_sigs = [
                        at_function, 
                        at_function_special_corner,
                        my_left_function,
                        my_right_function,
                        my_left_function_spot,
                        my_right_function_spot, 
                        my_left_function_whole,
                        my_right_function_whole,
                        left_of_function, 
                        right_of_function,
                        left_of_function_spot,
                        right_of_function_spot,
                        left_of_function_whole,
                        right_of_function_whole,
                        left_of_function_wall,
                        right_of_function_wall,
                        left_of_function_with_depth,
                        right_of_function_with_depth
                    ] 

    sig_keys = map(sig -> split(format_new_function_string(sig), "\n")[1], all_function_sigs)
    sig_dict = Dict(zip(sig_keys, all_function_sigs))
    failed_AST_sizes = Dict(map(k -> k => [], sig_keys))

    categories = [[Wall, Corner, DEPTH, COLOR], [Spot], [Half, Whole]]
    synthesized_semantics = Dict(map(x -> x => [], 1:length(categories)))
    prev_best_scores = Dict(map(x -> x => -1.0, 1:length(categories)))
    name_biases = Dict()
    max_language_augmented_AST_size = 0

    # compute initial results, before any function learning
    compute_initial_results(category_names, all_function_sigs, prev_best_scores, base_semantics_str, base_syntax)

    while length(sig_dict) != 0
        println("START OF LOOP")
        println(length(sig_dict))

        sig_semantics = Dict()
        sig_AST_sizes = Dict()
        sig_keys = [keys(sig_dict)...]
        function_sigs = [values(sig_dict)...]

        for i in 1:length(function_sigs)
            function_sig = function_sigs[i]
            category_assignment = findall(c -> intersect(function_sig.arg_types, c) != [], categories)[1]
            sig_key = sig_keys[i]

            possible_semantics = []
            for i in 1:1000
                semantics = generate_semantics(function_sig, base_semantics)
                push!(possible_semantics, semantics)
            end
            possible_semantics = unique(possible_semantics)
            println(possible_semantics)

            # exclude function definitions that have been used before
            possible_semantics = filter(x -> !(x in synthesized_semantics[category_assignment]), possible_semantics)

            # exclude function definitions that don't use all of the input arguments
            possible_semantics = filter(x -> foldl(&, map(a -> occursin(a, x), function_sig.arg_names), init=true), possible_semantics)

            possible_semantics = filter(x -> !occursin("0 <", x) && !occursin("1 <", x) && !occursin("1 >", x) && !occursin("0 >", x), possible_semantics)

            possible_semantics = sort(possible_semantics)

            sig_semantics[sig_key] = possible_semantics
            sig_AST_sizes[sig_key] = filter(x -> !(x in failed_AST_sizes[sig_key]), unique(map(s -> size(Meta.parse(s)), possible_semantics)))
        end

        for sig_key in keys(sig_AST_sizes)
            if sig_AST_sizes[sig_key] == []
                delete!(sig_dict, sig_key)
                delete!(sig_AST_sizes, sig_key)
            end
        end

        all_AST_sizes = unique(vcat([values(sig_AST_sizes)...]...))
        println("all_AST_sizes")
        println(all_AST_sizes)

        min_AST_size = minimum(all_AST_sizes)

        sig_keys_with_min = sort(filter(k -> min_AST_size in sig_AST_sizes[k], sig_keys))
        println("sig_keys_with_min")
        for k in sig_keys_with_min 
            println(k)
        end

        level_best_info = Dict()
        old_base_syntax = deepcopy(base_syntax)
        level_base_semantics_str = base_semantics_str
        for sig_key in sig_keys_with_min 
            println("current function sig")
            println(sig_key)
            function_sig = sig_dict[sig_key]
            category_assignment = findall(c -> intersect(function_sig.arg_types, c) != [], categories)[1]
            println(filter(d -> (size(Meta.parse(d)) == min_AST_size), sig_semantics[sig_key]))
            level_definitions = filter(d -> (size(Meta.parse(d)) == min_AST_size) && !(d in synthesized_semantics[category_assignment]), sig_semantics[sig_key])
            println(level_definitions)

            updated_syntax = update_syntax_cfg(base_syntax, function_sig)

            # track best semantics
            best_definition = ""
            best_total_score = -1
            best_full_results = nothing
            best_locations_to_search = Dict()

            for definition in level_definitions
                possible_sigs = filter(x -> x != function_sig, all_function_sigs)
                total_score, scores, search_locations, _ = evaluate_semantics(function_sig, definition, category_assignment, level_base_semantics_str, updated_syntax, 0, possible_sigs)

                update_best = false
                println("values(level_best_info)")
                println(map(x -> x[1], [values(level_best_info)...]))
                println("total_score")
                println(total_score)
                
                if !(definition in map(x -> x[1], [values(level_best_info)...]))
                    # println("here 0")
                    if total_score > best_total_score
                        # println("here 1")
                        update_best = true
                    elseif total_score == best_total_score 
                        # println("here 2")
                        if size(Meta.parse(best_definition)) > size(Meta.parse(definition)) # take smaller definition in terms of AST size
                            # println("here 3")
                            update_best = true
                        elseif size(Meta.parse(best_definition)) == size(Meta.parse(definition)) && length(best_definition) > length(definition) # take smaller definition in terms of character length
                            # println("here 4")
                            update_best = true 
                        elseif length(best_definition) == length(definition)
                            if best_definition > definition
                                update_best = true
                            else
                                # println("WOWOW")
                                # println(best_definition)
                                # println(definition)
                                # println(name_biases)
                                name_parts = filter(x -> length(x) > 2, split(function_sig.name, "_"))
                                name_core = name_parts[1]
                                if name_core in keys(name_biases)
                                    elts = name_biases[name_core]
                                    old_def_includes_elts = foldl(|, map(x -> occursin(x, best_definition), elts), init=false)
                                    new_def_includes_elts = foldl(|, map(x -> occursin(x, definition), elts), init=false)
                                    if old_def_includes_elts && !new_def_includes_elts 
                                        update_best = false
                                    else
                                        update_best = true
                                    end
                                else
                                    update_best = false
                                end
                            end
                        end
                    end
        
                    if update_best 
                        println("new_best!")
                        println(definition)
                        best_definition = definition
                        best_total_score = total_score
                        best_full_results = scores
                        best_locations_to_search = search_locations
                    end
                end 

            end
            println("best_definition")
            println(best_definition)
            println("best_total_score")
            println(best_total_score)
            println("prev_best_scores[category_assignment]")
            println(prev_best_scores[category_assignment])
            if !isnothing(best_full_results)
                for k in keys(best_full_results)
                    println(string((k, best_full_results[k])))
                end
            end

            if best_total_score > prev_best_scores[category_assignment]
                prev_best_scores[category_assignment] = best_total_score
                level_best_info[sig_key] = (best_definition, best_total_score, best_full_results, best_locations_to_search)
                push!(synthesized_semantics[category_assignment], best_definition)

                function_sig.definition = best_definition
                level_base_semantics_str = join([level_base_semantics_str, format_new_function_string(function_sig)], "\n")
            else
                # TODO: figure out how to properly handle prev_best_scores in the unordered case
                other_AST_sizes = filter(x -> x != min_AST_size, sig_AST_sizes[sig_key])
                if other_AST_sizes == []
                    delete!(sig_dict, sig_key)
                else
                    push!(failed_AST_sizes[sig_key], min_AST_size)
                end
                sig_keys_with_min = filter(x -> x != sig_key, sig_keys_with_min)

                # reset to prev syntax only if we don't accept this function 
                global base_syntax = update_syntax_cfg(base_syntax, function_sig, remove=true)  
            end
        end

        category_assignments = Dict(map(k -> k => findall(c -> intersect(sig_dict[k].arg_types, c) != [], categories)[1], sig_keys_with_min))

        conflicts = []
        for i in 1:length(categories)
            x = filter(k -> category_assignments[k] == i, sig_keys_with_min)
            if length(x) > 1 
                push!(conflicts, x)
            end
        end

        non_conflicting = sort(filter(k -> !(k in vcat(conflicts...)), sig_keys_with_min))

        global base_syntax = deepcopy(old_base_syntax)
        all = sort([non_conflicting..., vcat(conflicts...)...], by=x -> findall(y -> occursin(y, x), ["at(", "my_left(", "my_right(", "left_of(", "right_of("])[1])
        completed_sigs = map(k -> sig_dict[k], all)

        save_folder_name = ""
        save_dir_path_combined = ""
        if all != []
            global base_semantics_str = join([base_semantics_str, "# --- new stage begins ---"], "\n")

            open("metalanguage/final_semantics_unordered_analogy.jl", "w+") do f 
                write(f, base_semantics_str)
            end
            # save results
            ## create new combined stage folder
            combined_stage_count = length(filter(x -> !occursin("language_augmented", x), readdir("$(combined_results_dir)")))
            save_folder_name = "stage_$(lpad(string(combined_stage_count), 2, '0'))" 
            save_dir_path_combined = "$(combined_results_dir)/$(save_folder_name)"
            if !isdir(save_dir_path_combined)
                mkdir(save_dir_path_combined)
            end
        end
        new_split_folder_created = Dict(map(n -> n => false, category_names))
        
        for k in unique(all) # non_conflicting 
            update_final_syntax_and_semantics(k, sig_dict, level_best_info, base_semantics_str, base_semantics, base_syntax, save_folder_name, save_dir_path_combined, new_split_folder_created)
        end

        # handle conflicts 
        winners = []
        for arr in conflicts 
            # TODO
            println("oops")
            println(conflicts)
            # break
        end

        # for winner in winners 
        #     delete!(sig_dict, winner)
        # end 

        # abstraction/analogy loop -- same_name_different_args and different_name_same_args
        num_completed_sigs = length(completed_sigs)
        println("completed_sigs")
        println(completed_sigs)
        completed_sigs = filter(x -> !(SpecialCorner in x.arg_types) && length(x.arg_types) < 3, completed_sigs)
        while completed_sigs != []
            println("ANALOGY LOOP")
            println(length(completed_sigs))
            println(completed_sigs)
            analogous_functions = []
            level_base_semantics_str = base_semantics_str
            
            completed_sig = completed_sigs[1]
            completed_sigs = completed_sigs[2:end] # remove the current completed sig
            sig_keys = [keys(sig_dict)...]
            completed_name = completed_sig.name
            completed_name_parts = filter(x -> length(x) > 2, split(completed_name, "_"))
            if completed_name_parts != []
                completed_name_core = completed_name_parts[1]
                if !(completed_name_core in keys(name_biases))
                    if occursin("<", completed_sig.definition) || occursin(".wall1", completed_sig.definition)
                        name_biases[completed_name_core] = ["<", ".wall2", "next"]
                    elseif occursin(">", completed_sig.definition) || occursin(".wall2", completed_sig.definition)
                        name_biases[completed_name_core] = [">", ".wall1", "prev"]
                    end
                end
            else
                completed_name_core = ""
            end

            # abstraction signals
            signal_names = [
                "same_name_different_args",
                "different_name_same_args",
                "different_name_different_args"]

            abstraction_signals = Dict(map(name -> name => [], signal_names))
            for sig_key in sig_keys 
                sig = sig_dict[sig_key]
                if length(sig.arg_types) < 3
                    if sig.name == completed_name 
                        push!(abstraction_signals["same_name_different_args"], sig_key)
                    else
                        if sig.arg_types == completed_sig.arg_types 
                            push!(abstraction_signals["different_name_same_args"], sig_key)
                        end

                        # different but similar name
                        name_parts = filter(x -> length(x) > 2, split(completed_name, "_"))
                        if name_parts != []
                            name_core = name_parts[1]
                            if name_core == completed_name_core 
                                push!(abstraction_signals["different_name_different_args"], sig_key)
                            end
                        end

                    end
                end
            end

            for signal in keys(abstraction_signals) 
                abstraction_signals[signal] = sort(abstraction_signals[signal], by=length)
            end

            coord_exprs = coordExpressions(completed_sig)
            if intersect(completed_sig.arg_types, [Wall, Corner]) == []
                def_includes_coord_exprs = foldl(&, map(x -> occursin(x, completed_sig.definition), coord_exprs),init=true)
            else
                def_includes_coord_exprs = foldl(|, map(x -> occursin(x, completed_sig.definition), coord_exprs),init=false)
            end

            if def_includes_coord_exprs
                completed_definition = completed_sig.definition 

                println(completed_sig)
                println("same_name_different_args")
                println(abstraction_signals["same_name_different_args"])

                println("different_name_same_args")
                println(abstraction_signals["different_name_same_args"])

                # start with same name, different args 
                for sig_key in abstraction_signals["same_name_different_args"]
                    println("current sig_key, same_name_different_args")
                    println(sig_key)
                    sig = sig_dict[sig_key]
                    category_assignment = findall(c -> intersect(sig.arg_types, c) != [], categories)[1]

                    # evaluate new definition and see if it improves score
                    analogous_definition = generate_analogous_semantics(completed_sig, sig, true)
                    println("analogous definition")
                    println(analogous_definition)
                    sig.definition = analogous_definition
                    updated_syntax = update_syntax_cfg(base_syntax, sig)
                    possible_sigs = filter(x -> x != sig, all_function_sigs)

                    total_score, scores, search_locations, _ = evaluate_semantics(sig, analogous_definition, category_assignment, level_base_semantics_str, updated_syntax, 0, possible_sigs)
                    println("total_score")
                    println(total_score)
                    println("prev_best_scores[category_assignment]")
                    println(prev_best_scores[category_assignment])
                    if total_score > prev_best_scores[category_assignment]
                        prev_best_scores[category_assignment] = total_score
                        level_best_info[sig_key] = (analogous_definition, total_score, scores, search_locations)
                        push!(synthesized_semantics[category_assignment], analogous_definition)
        
                        sig.definition = analogous_definition
                        level_base_semantics_str = join([level_base_semantics_str, format_new_function_string(sig)], "\n")
                        push!(analogous_functions, sig_key)
                    else
                        updated_syntax = update_syntax_cfg(base_syntax, sig, remove=true)
                        sig.definition = ""
                    end
                end

                # then try different name, same args 
                for sig_key in abstraction_signals["different_name_same_args"]
                    println("current sig_key, different_name_same_args")
                    println(sig_key)

                    sig = sig_dict[sig_key]
                    category_assignment = findall(c -> intersect(sig.arg_types, c) != [], categories)[1]

                    # evaluate new definition and see if it improves score
                    analogous_definition = generate_analogous_semantics(completed_sig, sig, false)
                    println("analogous definition")
                    println(analogous_definition)
                    sig.definition = analogous_definition
                    updated_syntax = update_syntax_cfg(base_syntax, sig)

                    possible_sigs = filter(x -> x != sig, all_function_sigs)
                    total_score, scores, search_locations, _ = evaluate_semantics(sig, analogous_definition, category_assignment, level_base_semantics_str, updated_syntax, 0, possible_sigs)
                    if total_score > prev_best_scores[category_assignment]
                        prev_best_scores[category_assignment] = total_score
                        level_best_info[sig_key] = (analogous_definition, total_score, scores, search_locations)
                        push!(synthesized_semantics[category_assignment], analogous_definition)
        
                        sig.definition = analogous_definition
                        level_base_semantics_str = join([level_base_semantics_str, format_new_function_string(sig)], "\n")
                        push!(analogous_functions, sig_key)
                    else
                        updated_syntax = update_syntax_cfg(base_syntax, sig, remove=true)
                        sig.definition = ""
                    end
                end

                # finally, try different (but similar) name, different args -- skipping for now

                # after all of this, brute force anything that remains, e.g. go back to start of the loop
            end

            for k in sort(analogous_functions, by=x -> findall(y -> occursin(y, x), ["at(", "my_left(", "my_right(", "left_of(", "right_of("])[1])
                sig = sig_dict[k]
                update_final_syntax_and_semantics(k, sig_dict, level_best_info, base_semantics_str, base_semantics, base_syntax, save_folder_name, save_dir_path_combined, new_split_folder_created)
                push!(completed_sigs, sig)
            end
        end

        println(completed_sigs)
        if num_completed_sigs > 0
            println("beginning language augmented loop")
            # language-augmented abstraction loop
            println("bounds")
            @show min_AST_size + 1
            @show max_language_augmented_AST_size + 1
            @show maximum([min_AST_size + 1, max_language_augmented_AST_size + 1])
            @show maximum(all_AST_sizes)
            
            for m in maximum([min_AST_size + 1, max_language_augmented_AST_size + 1]):maximum(all_AST_sizes)
                max_language_augmented_AST_size = m
                println("LANGUAGE AUGMENTED LOOP, m=$(m)")
    
                # evaluate current semantics with new language-abstraction potential, and save results as new stage
                total_score, scores, search_locations, temp_semantics = evaluate_semantics(nothing, "", 0, base_semantics_str, base_syntax, max_language_augmented_AST_size, all_function_sigs)
                println("temp_semantics")
                println(temp_semantics)
                # save results
                ## create new combined stage folder
                combined_stage_count = length(filter(x -> !occursin("language_augmented", x), readdir("$(combined_results_dir)")))
                save_folder_name = "stage_$(lpad(string(combined_stage_count), 2, '0'))_language_augmented_$(m)" 
                save_dir_path_combined = "$(combined_results_dir)/$(save_folder_name)"
                if !isdir(save_dir_path_combined)
                    mkdir(save_dir_path_combined)
                end
    
                new_split_folder_created = Dict(map(n -> n => false, category_names))
                for c in 1:3
                    # category_names = ["left_of_blue", "spatial_lang_test", "red_green_test"]
                    category_scores = Dict()
                    category_search_locations = Dict()
                    for k in keys(scores)
                        if c == 1
                            if occursin("room", k)
                                category_scores[k] = scores[k]
                                category_search_locations[k] = search_locations[k]
                            end
                        elseif c == 2 
                            if occursin("spatial", k)
                                category_scores[k] = scores[k]
                                category_search_locations[k] = search_locations[k]
                            end
                        elseif c == 3 
                            if occursin("green", k)
                                category_scores[k] = scores[k]
                                category_search_locations[k] = search_locations[k]
                            end
                        end
                    end
                    info = Dict()
                    info["$(c)"] = ("", sum([values(category_scores)...]), category_scores, category_search_locations)
                    
                    temp_semantics_strings = unique(map(x -> format_new_function_string(x), temp_semantics))

                    category_type_annotations = map(x -> "::$(repr(x))", categories[c])
                    temp_semantics_strings = filter(x -> foldl(|, map(y -> occursin(y, x), category_type_annotations), init=false), temp_semantics_strings)

                    new_func_str = "# no new permanent functions -- language augmentation test (max AST size = $(m))/n# temporary functions: $(length(temp_semantics_strings))"
                    new_func_str = """$(new_func_str)\n$(join(temp_semantics_strings, "\n"))"""
                    save_results("$(c)", info, c, save_folder_name, save_dir_path_combined, new_split_folder_created, new_func_str)
                end
            end
            println("ending language augmented loop")
            # max_language_augmented_AST_size = 0
    
            # reset base semantics file after language augmented loop
            open("metalanguage/final_semantics_unordered_analogy.jl", "w+") do f 
                write(f, base_semantics_str)
            end
        end

    end

    open("metalanguage/results/ordered/combined_to_by_category_mapping.txt", "w") do f 
        write(f, join(map(tup -> string(tup), combined_to_split_mapping), "\n"))
    end
end

function update_final_syntax_and_semantics(k, sig_dict, level_best_info, base_semantics_str, base_semantics, base_syntax, save_folder_name, save_dir_path_combined, new_split_folder_created)
    function_sig = sig_dict[k]
    category_assignment = findall(c -> intersect(function_sig.arg_types, c) != [], categories)[1]
    best_definition = level_best_info[k][1]
    # update final semantics and syntax with new function definition
    function_sig.definition = best_definition
    new_function_definition_str = format_new_function_string(function_sig)
    println("new function definition")
    println(new_function_definition_str)
    
    # push!(synthesized_semantics[category_assignment], best_definition)

    global base_semantics_str = join([base_semantics_str, new_function_definition_str], "\n")

    open("metalanguage/final_semantics_unordered_analogy.jl", "w+") do f 
        write(f, base_semantics_str)
    end

    # update semantics cfg 
    global base_semantics = update_semantics_cfg(base_semantics, function_sig)

    # update syntax cfg 
    global base_syntax = update_syntax_cfg(base_syntax, function_sig)

    delete!(sig_dict, k)

    # save_results
    save_results(k, level_best_info, category_assignment, save_folder_name, save_dir_path_combined, new_split_folder_created, new_function_definition_str)
end

comparison_opposites = Dict(["<" => ">", ">" => "<"])

function generate_analogous_semantics(completed_sig, sig, similar_name=true)
    if length(sig.arg_types) == 3 
        old_definition = completed_sig.definition 
        old_arg_name = completed_sig.arg_names[end]
        new_arg_name = sig.arg_names[end]
        new_component = replace(old_definition, old_arg_name => new_arg_name)
        new_definition = "$(old_definition) && $(new_component)"
        return new_definition
    end

    if intersect(completed_sig.arg_types, [Wall, Corner]) == []
        parts = split(completed_sig.definition, " ")
        old_comparison_str = parts[end - 1]
    
        if !similar_name 
            new_comparison_str = comparison_opposites[old_comparison_str]
        else 
            new_comparison_str = old_comparison_str
        end
    
        if intersect(sig.arg_types, [Wall, Corner]) == []
            coord_exprs = coordExpressions(completed_sig)
            analogous_coord_exprs = coordExpressions(sig)
            replacement_pairs = map(i -> coord_exprs[i] => analogous_coord_exprs[i], 1:length(coord_exprs))
    
            new_definition = completed_sig.definition
            for i in 1:length(coord_exprs)
                new_definition = replace(new_definition, coord_exprs[i] => analogous_coord_exprs[i])
            end
            new_definition = replace(new_definition, old_comparison_str => new_comparison_str)
        else
            analogous_location = ""
            arg_name = sig.arg_names[1]
            if new_comparison_str == "<"
                if sig.arg_types[1] == Corner 
                    analogous_location = "$(arg_name).wall2"
                else # Wall 
                    analogous_location = "next($(arg_name), locations).wall2"
                end
            elseif new_comparison_str == ">"
                if sig.arg_types[1] == Corner 
                    analogous_location = "$(arg_name).wall1"
                else # Wall 
                    analogous_location = "prev($(arg_name), locations).wall1"
                end
            end
            property_name = split(sig.arg_names[end], "_")[1]
            new_definition = "$(analogous_location).$(property_name) == $(sig.arg_names[end])"
        end
    else
        if occursin(".wall1", completed_sig.definition) 
            old_comparison_str = ">"
        else
            old_comparison_str = "<"
        end

        if !similar_name 
            new_comparison_str = comparison_opposites[comparison_str]
        else 
            new_comparison_str = old_comparison_str
        end
    
        if intersect(sig.arg_types, [Wall, Corner]) == []
            analogous_coord_exprs = coordExpressions(sig)
    
            if length(analogous_coord_exprs) == 2 
                new_definition = "$(analogous_coord_exprs[1]) $(new_comparison_str) $(analogous_coord_exprs[2])"
            else
                new_definition = "$(analogous_coord_exprs[1]) $(new_comparison_str) 0"
            end

        else
            analogous_location = ""
            arg_name = completed_sig.arg_names[1]
            if occursin("$(arg_name).wall1", completed_sig.definition)
                old_location = "$(arg_name).wall1"
            elseif occursin("prev($(arg_name), locations).wall1", completed_sig.definition)
                old_location = "prev($(arg_name), locations).wall1"
            elseif occursin("$(arg_name).wall2", completed_sig.definition)
                old_location = "$(arg_name).wall2"
            elseif occursin("next($(arg_name), locations).wall2", completed_sig_definition)
                old_location = "next($(arg_name), locations).wall2"
            end

            arg_name = sig.arg_names[1]
            if new_comparison_str == "<"
                if sig.arg_types[1] == Corner 
                    analogous_location = "$(arg_name).wall2"
                else # Wall 
                    analogous_location = "next($(arg_name), locations).wall2"
                end
            elseif new_comparison_str == ">"
                if sig.arg_types[1] == Corner 
                    analogous_location = "$(arg_name).wall1"
                else # Wall 
                    analogous_location = "prev($(arg_name), locations).wall1"
                end
            end
            
            new_definition = replace(completed_sig.definition, old_location => analogous_location)

            old_property_name = split(sig.arg_names[end], "_")[1]
            property_name = split(sig.arg_names[end], "_")[1]
            new_definition = replace(new_definition, old_property_name => property_name)
        end
    end

    new_definition
end

function coordExpressions(function_sig)
    arg_names = function_sig.arg_names
    arg_types = function_sig.arg_types
    if length(function_sig.arg_types) <= 2
        arg_type = arg_types[1]
        if arg_type == Half 
            map(name -> "$(name).x", arg_names)
        elseif arg_type == Spot 
            map(name -> "$(name).position.x", arg_names)
        elseif arg_type == Corner
            idxs = findall(t -> t == Corner, arg_types)
            names = map(i -> arg_names[i], idxs)

            vcat(map(name -> "$(name).wall1", names), map(name -> "$(name).wall2", names))
        elseif arg_type == Wall 
            idxs = findall(t -> t == Wall, arg_types)
            names = map(i -> arg_names[i], idxs)

            vcat(map(name -> "prev($(name), locations).wall1", names), map(name -> "next($(name), locations).wall2", names))
        else
            []
        end
    else
        []
    end
end

function evaluate_semantics(function_sig, definition, category_assignment, level_base_semantics_str, updated_syntax, max_language_augmented_AST_size, all_functions, test_configs=[], suffix="unordered_analogy")
    # println("-- trying definition")
    # println(definition)
    if !isnothing(function_sig)
        function_sig.definition = definition
        new_function_definition_str = format_new_function_string(function_sig)
    
        # update semantics.jl file with new function and import file
        new_semantics_str = join([level_base_semantics_str, new_function_definition_str], "\n")
    else
        new_semantics_str = level_base_semantics_str
    end

    open("metalanguage/intermediate_outputs/intermediate_semantics_$(suffix).jl", "w+") do f 
        write(f, new_semantics_str)
    end
    include("intermediate_outputs/intermediate_semantics_$(suffix).jl")

    # generate lots of programs in the new language, and measure performance across suite of spatial configurations
    # if performance is higher than base language, save that program and its score

    if test_configs != []
        config_names = test_configs
    else
        config_names = readdir("spatial_config/configs")
    end
    if category_assignment == 1 # LoB experiments
        config_names = filter(x -> occursin("room", x), config_names)
    elseif category_assignment == 2 # spatial lang. experiments
        config_names = filter(x -> occursin("spatial", x), config_names)
    elseif category_assignment == 3 # red-green experiments
        config_names = filter(x -> occursin("green", x), config_names)
    end

    # DEBUGGING: DELETE LATER
    seen_utterance = Dict([
        "true" => false,
        "directional" => false, 
        "prettier" => false, 
        "neutral" => false
    ])

    scores = Dict()
    search_locations = Dict()
    temp_semantics = []
    using_temp_semantics = false
    for config_name in config_names
        # all non-control input spatial problems
        if !occursin("no_blue", config_name) && !occursin(".DS_Store", config_name) # && !occursin("utterance", config_name)
            # # println("--- CONFIG NAME")
            # # println(config_name)            
            # if occursin("utterance", config_name)
            #     t = replace(split(config_name, "utterance_")[end], ".json" => "")
            #     if !seen_utterance[t]
            #         seen_utterance[t] = true
            #     else
            #         continue
            #     end
            # end
            # println(config_name)
            config_filepath = "spatial_config/configs/$(config_name)"
            config = JSON.parsefile(config_filepath)

            scene = define_spatial_reasoning_problem(config_filepath)
            global locations = scene.locations

            # generate a lot of possible spatial memory expressions
            rect = filter(l -> l isa Wall && l.depth == mid, scene.locations) == []
            if occursin("utterance", config_name)

                shift = occursin("shift", config_name) ? parse(Int, filter(x -> x != "", split(split(config_name, "utterance_")[1], "_"))[end]) : 0
            else
                shift = occursin("shift", config_name) ? parse(Int, replace(split(config_name, "shift_")[end], ".json" => "")) : 0
            end

            # b = filter(l -> l isa Wall && l.color == blue, scene.locations) != []
            programs = []
            num_programs = 1000
            for _ in 1:num_programs
                program = generate_syntax(typeof(scene.prize), updated_syntax, rect=rect, shift=shift) # rect=rect, blue=b
                push!(programs, program)
            end
            programs = unique(programs)
            programs = filter(x -> !(occursin("white", x) && occursin("blue)", x)), programs) # PATCH
            
            using_temp_semantics = false
            temp_program = ""
            temp_func = nothing
            if occursin("utterance", config_name) && (occursin("green", config_name) && !occursin("next", scene.utterance) || occursin("spatial", config_name)) && max_language_augmented_AST_size != 0
                new_func = nothing
                if occursin("green", config_name) # red-green test
                    new_func, new_program = translate_from_NL_and_image(scene, all_functions, max_language_augmented_AST_size)
                elseif occursin("room", config_name)
                    _, new_program = translate_from_NL(scene, all_functions, max_language_augmented_AST_size)
                    if new_program != ""
                        programs = map(x -> "$(x) $(new_program)", programs)
                    end
                else # spatial lang. test
                    new_func, new_program = translate_from_NL(scene, all_functions, max_language_augmented_AST_size)
                end

                if !isnothing(new_func)
                    # update semantics 
                    new_func_str = format_new_function_string(new_func)
                    new_func_str_first_line = split(new_func_str, "\n")[1]

                    if occursin(new_func_str_first_line, new_semantics_str)
                        prefix = split(new_semantics_str, new_func_str_first_line)[1]
                        suffix_unedited = split(new_semantics_str, new_func_str_first_line)[end]
                        suffix = split(suffix_unedited,"\nend")[end]
                        new_semantics_str = join([prefix, new_func_str, suffix], "\n")
                    else
                        new_semantics_str = join([new_semantics_str, new_func_str], "\n")
                        open("metalanguage/intermediate_outputs/intermediate_semantics_$(suffix).jl", "w+") do f 
                            write(f, new_semantics_str)
                        end    
                    end
                    # println(new_semantics_str)
                    include("intermediate_outputs/intermediate_semantics_$(suffix).jl")
                
                    push!(programs, new_program)
                    programs = unique(programs)
                    temp_program = new_program 
                    temp_func = new_func
                    # println("TEMP PROGRAM")
                    # println(temp_program)
                    # println("TEMP FUNC")
                    # println(temp_func)
                    using_temp_semantics = true
                end
            end

            # exclude programs that don't include the input argument
            # # println(programs)
            programs = filter(x -> x == "true" || occursin("location", x), programs)
            # println("programs")
            # println(programs)

            # evaluate all the possible spatial memory representations and select the best one
            formatted_programs = []
            for program in programs
                if scene.prize isa Wall 
                    program = "location isa Wall && $(program)"
                elseif scene.prize isa Corner
                    program = "location isa Corner && $(program)"
                elseif scene.prize isa SpecialCorner 
                    program = "location isa SpecialCorner && $(program)"
                end
                push!(formatted_programs, program)
            end
            evaluated_lambdas = map(p -> eval(Meta.parse("location -> $(p)")), formatted_programs)
            # results = map(x -> filter(x, scene.locations), evaluated_lambdas)

            results = []
            for i in 1:length(evaluated_lambdas)
                # # println("let's try! 1")
                global x = evaluated_lambdas[i]
                # # println(formatted_programs[i])

                if !(scene.prize isa Whole)
                    # # println("let's try! 2")
                    r = @eval filter($x, $locations) 
                    # # println(r)
                    push!(results, r)
                else
                    shift = (scene.prize.coral.x + scene.prize.green.x)/2
                    shifted_prize = Whole(Half(scene.prize.green.x - shift), Half(scene.prize.coral.x - shift), scene.prize.diagonal)
                    global new_locations = [shifted_prize]
                    res = @eval filter($x, $new_locations)

                    final_res = nothing
                    if res == [] 
                        final_res = nothing
                    else
                        final_res = @eval filter($x, $locations)
                    end

                    push!(results, final_res)
                end

            end

            if scene.prize isa Whole 
                idxs = findall(x -> !isnothing(x), results)
                programs = map(i -> programs[i], idxs)
                results = map(i -> results[i], idxs)

                # # println("programs")
                # # println(programs)
                # # println("results")
                # # println(results)

                if results == []
                    scores[config_name] = 1/3
                    search_locations[config_name] = scene.locations
                else
                    programs_and_results = sort([zip(programs, results)...], by=tup -> length(tup[1]))
                    program, res = programs_and_results[end]

                    if program == temp_program
                        push!(temp_semantics, temp_func)
                    end

                    if scene.prize in res 
                        scores[config_name] = 1/length(res)
                        search_locations[config_name] = res
                    elseif length(res) == 0
                        scores[config_name] = 1/3
                        search_locations[config_name] = scene.locations
                    else
                        scores[config_name] = 0
                        search_locations[config_name] = res
                    end 
                end
            else
                programs_and_results = [zip(programs, results)...]
                programs_and_results = filter(tup -> scene.prize in tup[2], programs_and_results)

                best_indices = findall(t -> length(t[2]) == minimum(map(tup -> length(tup[2]), programs_and_results)), programs_and_results)
                best_programs = map(i -> programs_and_results[i], best_indices)
                # println(best_programs)
                sort!(best_programs, by=tup -> size(Meta.parse(tup[1])))
                best_program, locations_to_search = best_programs[1]

                
                if best_program == temp_program
                    push!(temp_semantics, temp_func)
                end
                println("best_program")
                println(best_program)
                # println("temp_program")
                # println(temp_program)
                # # println(locations_to_search)
                if occursin("modified", config_name)
                    old_locations = scene.locations
                    special_corner1, special_corner2 = filter(x -> x isa SpecialCorner, old_locations)
                    corner1, corner2 = filter(x -> x isa Corner, old_locations)

                    wall1, wall2, wall3, wall4 = filter(x -> x isa Wall, old_locations)

                    special_corner1.wall1 = wall4 
                    special_corner1.wall2 = wall1 

                    special_corner2.wall1 = wall3 
                    special_corner2.wall2 = wall4

                    corner1.wall1 = wall1 
                    corner2.wall2 = wall2 

                    corner2.wall1 = wall2 
                    corner2.wall2 = wall3

                    global locations = [wall1, corner1, wall2, corner2, wall3, special_corner2, wall4, special_corner1]
                    new_prize = special_corner1
                    global x = eval(Meta.parse("location -> location isa SpecialCorner && $(best_program)"))
                    r = @eval filter($x, $locations) 

                    if new_prize in r 
                        scores[config_name] = 1.0
                    else
                        scores[config_name] = 0.0
                    end
                    search_locations[config_name] = r
                else
                    if occursin("spatial", config_name) && !using_temp_semantics && (occursin("left", best_program) || occursin("right", best_program)) 
                        scores[config_name] = 1/length(locations_to_search) * alpha
                    else
                        scores[config_name] = 1/length(locations_to_search)
                    end
                    search_locations[config_name] = locations_to_search    
                end

            end
        end
    end

    total_score = sum([values(scores)...])
    return (round(total_score, digits=6), scores, search_locations, temp_semantics)
end

function save_results(sig_key, level_best_info, category_assignment, save_folder_name, save_dir_path_combined, new_split_folder_created, new_function_definition_str)
    best_definition, best_total_score, best_full_results, best_locations_to_search = level_best_info[sig_key]
    category_name = category_names[category_assignment]
    split_stage_count = length(readdir("$(split_results_dir)/$(category_name)"))
    if !new_split_folder_created[category_name]
        println(category_name)
        save_dir_path_split = "metalanguage/results/unordered_analogy/by_category/$(category_name)/stage_$(lpad(string(split_stage_count), 2, '0'))"
        if occursin("_language_augmented_", save_dir_path_split)
            num = split(save_dir_path_split, "_language_augmented_")[end]
            save_dir_path_split = "$(save_dir_path_split)_language_augmented_$(num)"
        end

        if !isdir(save_dir_path_split)
            mkdir(save_dir_path_split)
        end
        new_split_folder_created[category_name] = true
        push!(combined_to_split_mapping, (save_folder_name, "$(category_name)/stage_$(lpad(string(split_stage_count), 2, '0'))"))
    else
        save_dir_path_split = "metalanguage/results/unordered_analogy/by_category/$(category_name)/stage_$(lpad(string(split_stage_count - 1), 2, '0'))"
    end

    for save_dir_path in [save_dir_path_combined, save_dir_path_split]
        ## save the single new function definition learned 
        open("$(save_dir_path)/new_function_semantics.jl", "a") do f 
            write(f, new_function_definition_str)
        end

        ## save individual configuration results as images
        image_dir = "$(save_dir_path)/image_results"
        if !isdir(image_dir)
            mkdir(image_dir)
        end

        for config_name in keys(best_locations_to_search) 
            locations = best_locations_to_search[config_name]
            config = JSON.parsefile("spatial_config/configs/$(config_name)")
            # save result images
            save_filename = replace(config_name, ".json" => ".png")
            save_filepath = "$(image_dir)/$(save_filename)"
            println(save_filepath)
            if category_name == "left_of_blue"
                if occursin("special_corner", config_name)
                    p = visualize_special_corner_results(config, locations, save_filepath)
                elseif occursin("triangle", config_name)
                    p = visualize_triangle_results(config, locations, save_filepath)
                else
                    p = visualize_left_of_blue_results(config, locations, save_filepath)
                end
            elseif category_name == "spatial_lang_test"
                p = visualize_spatial_lang_results(config, locations, save_filepath)
            elseif category_name == "red_green_test"
                p = visualize_red_green_results(config, locations, save_filepath)
            end
        end

        ## save numerical results 
        number_dir = "$(save_dir_path)/numerical_results"
        if !isdir(number_dir)
            mkdir(number_dir)
        end

        ### save probabilities of correctness for each spatial config
        if category_name == "red_green_test"
            accuracies = []
            config_names = sort([keys(best_locations_to_search)...])
            for config_name in config_names 
                locations = best_locations_to_search[config_name]

                config_filepath = "spatial_config/configs/$(config_name)"
                config = JSON.parsefile(config_filepath)
                global scene = define_spatial_reasoning_problem(config_filepath)
                idxs = map(x -> findall(l -> l == x, scene.locations)[1], locations)
                labels = map(i -> config["order"][i], idxs)
                push!(accuracies, (category_name, config_name, round(length(filter(x -> x == "M", labels))/length(labels), digits=3)))
            end
        else
            accuracies = map(k -> (category_name, k, round(1/length(best_locations_to_search[k]), digits=3)), sort([keys(best_locations_to_search)...]))
        end

        # write accuracies to file
        if save_dir_path == save_dir_path_split 
            open("$(number_dir)/accuracies.txt", "w") do f 
                write(f, join(map(x -> string(x), accuracies), "\n"))
            end
        else
            open("$(number_dir)/accuracies.txt", "w+") do f 
                t = read(f, String)
                lines = split(t, "\n")
                if occursin("($(category_name), ", t)
                    lines = filter(x -> !occursin("($(category_name), "), lines)
                end
                new_lines = [lines..., map(x -> string(x), accuracies)...]
                write(f, join(new_lines, "\n"))
            end
        end

        ### save locations to search for each spatial config (and corresponding M/R/D labels, for red-green test)
        if category_name == "red_green_test"
            results = []
            config_names = sort([keys(best_locations_to_search)...])
            for config_name in config_names 
                locations = best_locations_to_search[config_name]

                config_filepath = "spatial_config/configs/$(config_name)"
                config = JSON.parsefile(config_filepath)
                scene = define_spatial_reasoning_problem(config_filepath)
                idxs = map(x -> findall(l -> l == x, scene.locations)[1], locations)
                labels = map(i -> config["order"][i], idxs)
                push!(results, string((category_name, config_name, labels, locations)))
            end
        else
            results = map(k -> string((category_name, k, best_locations_to_search[k])), sort([keys(best_locations_to_search)...]))
        end

        if save_dir_path == save_dir_path_split 
            open("$(number_dir)/locations_to_search.txt", "w") do f
                write(f, join(results, "\n"))
            end
        else
            open("$(number_dir)/locations_to_search.txt", "w+") do f
                t = read(f, String)
                lines = split(t, "\n")
                if occursin("($(category_name), ", t)
                    lines = filter(x -> !occursin("($(category_name), "), lines)
                end
                new_lines = [lines..., results...]
                write(f, join(new_lines, "\n"))
            end
        end

        ### save overall percentage of perfect benchmarks
        num_solved = count(tup -> tup[2] == 1.0, accuracies)
        percentage_solved = round(num_solved/length(accuracies), digits=3)

        if save_dir_path == save_dir_path_split 
            open("$(number_dir)/overall_benchmark_accuracy.txt", "w") do f 
                write(f, "$(category_name) => $(percentage_solved)")
            end
        else
            open("$(number_dir)/overall_benchmark_accuracy.txt", "w+") do f 
                t = read(f, String)
                lines = split(t, "\n")
                if occursin("$(category_name) =>", t)
                    lines = filter(x -> !occursin("$(category_name) =>", x), lines)
                    new_lines = [lines..., "$(category_name) => $(percentage_solved)"]
                    write(f, join(new_lines, "\n"))
                else
                    write(f, "$(t)\n$(category_name) => $(percentage_solved)")
                end
            end
        end
    end
end


function compute_initial_results(category_names, all_function_sigs, prev_best_scores, base_semantics_str, base_syntax)
    total_score, scores, search_locations, temp_semantics = evaluate_semantics(nothing, "", 0, base_semantics_str, base_syntax, 0, all_function_sigs)

    # save results before any function learning
    ## create new combined stage folder
    combined_stage_count = length(filter(x -> !occursin("language_augmented", x), readdir("$(combined_results_dir)")))
    save_folder_name = "stage_$(lpad(string(combined_stage_count), 2, '0'))" 
    save_dir_path_combined = "$(combined_results_dir)/$(save_folder_name)"
    if !isdir(save_dir_path_combined)
        mkdir(save_dir_path_combined)
    end

    new_split_folder_created = Dict(map(n -> n => false, category_names))
    for c in 1:3
        # category_names = ["left_of_blue", "spatial_lang_test", "red_green_test"]
        category_scores = Dict()
        category_search_locations = Dict()
        for k in keys(scores)
            if c == 1
                if occursin("room", k)
                    category_scores[k] = scores[k]
                    category_search_locations[k] = search_locations[k]
                end
            elseif c == 2 
                if occursin("spatial", k)
                    category_scores[k] = scores[k]
                    category_search_locations[k] = search_locations[k]
                end
            elseif c == 3 
                if occursin("green", k)
                    category_scores[k] = scores[k]
                    category_search_locations[k] = search_locations[k]
                end
            end
        end
        info = Dict()
        category_total_score = sum([values(category_scores)...])
        prev_best_scores[c] = category_total_score
        info["$(c)"] = ("", category_total_score, category_scores, category_search_locations)
        save_results("$(c)", info, c, save_folder_name, save_dir_path_combined, new_split_folder_created, "")
    end
end

# test()