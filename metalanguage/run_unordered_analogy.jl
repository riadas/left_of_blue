include("metalanguage.jl")
include("../spatial_config/viz.jl")

global base_semantics_str = ""
open("metalanguage/base_semantics.jl", "r") do f 
    global base_semantics_str = read(f, String)
end

# reset results folders
category_names = ["left_of_blue", "spatial_lang_test", "red_green_test"]
combined_results_dir = "metalanguage/results/unordered/combined"
if isdir(combined_results_dir)
    rm(combined_results_dir, recursive=true)
end
mkdir(combined_results_dir)

split_results_dir = "metalanguage/results/unordered/by_category"
if isdir(split_results_dir)
    rm(split_results_dir, recursive=true)
end
mkdir(split_results_dir)
for category_name in category_names 
    mkdir("$(split_results_dir)/$(category_name)")
end
combined_to_split_mapping = []

function test()
    at_function = Function("at", ["location_arg", "color_arg"], [Wall, COLOR], "")
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

    function_sigs = [
                        at_function, 
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
                        right_of_function_wall
                    ] 

    sig_keys = map(sig -> split(format_new_function_string(sig), "\n")[1], function_sigs)
    sig_dict = Dict(zip(sig_keys, function_sigs))
    failed_AST_sizes = Dict(map(k -> k => [], sig_keys))

    categories = [[Wall, Corner, DEPTH, COLOR], [Spot], [Half, Whole]]
    synthesized_semantics = Dict(map(x -> x => [], 1:length(categories)))
    prev_best_scores = Dict(map(x -> x => -1.0, 1:length(categories)))
    name_biases = Dict()
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
                total_score, scores, search_locations = evaluate_semantics(function_sig, definition, category_assignment, level_base_semantics_str, updated_syntax)

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
            combined_stage_count = length(readdir("$(combined_results_dir)"))
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
                    total_score, scores, search_locations = evaluate_semantics(sig, analogous_definition, category_assignment, level_base_semantics_str, updated_syntax)
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

                    # evaluate new definition and see if it improves score
                    analogous_definition = generate_analogous_semantics(completed_sig, sig, false)
                    println("analogous definition")
                    println(analogous_definition)
                    sig.definition = analogous_definition
                    updated_syntax = update_syntax_cfg(base_syntax, sig)
                    total_score, scores, search_locations = evaluate_semantics(sig, analogous_definition, category_assignment, level_base_semantics_str, updated_syntax)
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
        end
    else
        []
    end
end

function evaluate_semantics(function_sig, definition, category_assignment, level_base_semantics_str, updated_syntax)
    println("-- trying definition")
    println(definition)
    function_sig.definition = definition
    new_function_definition_str = format_new_function_string(function_sig)

    # update semantics.jl file with new function and import file
    new_semantics_str = join([level_base_semantics_str, new_function_definition_str], "\n")
    open("metalanguage/intermediate_outputs/intermediate_semantics_unordered.jl", "w+") do f 
        write(f, new_semantics_str)
    end
    include("intermediate_outputs/intermediate_semantics_unordered.jl")

    # generate lots of programs in the new language, and measure performance across suite of spatial configurations
    # if performance is higher than base language, save that program and its score

    config_names = readdir("spatial_config/configs")
    if category_assignment == 1 # LoB experiments
        config_names = filter(x -> occursin("room", x), config_names)
    elseif category_assignment == 2 # spatial lang. experiments
        config_names = filter(x -> occursin("spatial", x), config_names)
    elseif category_assignment == 3 # red-green experiments
        config_names = filter(x -> occursin("green", x), config_names)
    end

    scores = Dict()
    search_locations = Dict()
    for config_name in config_names
        # all non-control input spatial problems
        if !occursin("no_blue", config_name) && !occursin(".DS_Store", config_name)
            # println("--- CONFIG NAME")
            # println(config_name)

            config_filepath = "spatial_config/configs/$(config_name)"
            config = JSON.parsefile(config_filepath)

            scene = define_spatial_reasoning_problem(config_filepath)
            global locations = scene.locations

            # generate a lot of possible spatial memory expressions
            rect = filter(l -> l isa Wall && l.depth == mid, scene.locations) == []
            shift = occursin("shift", config_name) ? parse(Int, replace(split(config_name, "shift_")[end], ".json" => "")) : 0

            # b = filter(l -> l isa Wall && l.color == blue, scene.locations) != []
            programs = []
            num_programs = 1000
            for _ in 1:num_programs
                program = generate_syntax(typeof(scene.prize), updated_syntax, rect=rect, shift=shift) # rect=rect, blue=b
                push!(programs, program)
            end
            programs = unique(programs)

            # exclude programs that don't include the input argument
            # println(programs)
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
                end
                push!(formatted_programs, program)
            end
            evaluated_lambdas = map(p -> eval(Meta.parse("location -> $(p)")), formatted_programs)
            # results = map(x -> filter(x, scene.locations), evaluated_lambdas)

            results = []
            for i in 1:length(evaluated_lambdas)
                # println("let's try! 1")
                global x = evaluated_lambdas[i]
                # println(formatted_programs[i])

                if !(scene.prize isa Whole)
                    # println("let's try! 2")
                    r = @eval filter($x, $locations) 
                    # println(r)
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

                # println("programs")
                # println(programs)
                # println("results")
                # println(results)

                if results == []
                    scores[config_name] = 1/3
                    search_locations[config_name] = scene.locations
                else
                    programs_and_results = sort([zip(programs, results)...], by=tup -> length(tup[1]))
                    program, res = programs_and_results[end]

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
                # println("best_program")
                # println(best_program)
                # println(locations_to_search)

                scores[config_name] = 1/length(locations_to_search)
                search_locations[config_name] = locations_to_search

            end
        end
    end

    total_score = sum([values(scores)...])
    return (round(total_score, digits=6), scores, search_locations)
end

function save_results(sig_key, level_best_info, category_assignment, save_folder_name, save_dir_path_combined, new_split_folder_created, new_function_definition_str)
    best_definition, best_total_score, best_full_results, best_locations_to_search = level_best_info[sig_key]
    category_name = category_names[category_assignment]
    split_stage_count = length(readdir("$(split_results_dir)/$(category_name)"))
    if !new_split_folder_created[category_name]
        println(category_name)
        save_dir_path_split = "metalanguage/results/unordered/by_category/$(category_name)/stage_$(lpad(string(split_stage_count + 1), 2, '0'))"
        if !isdir(save_dir_path_split)
            mkdir(save_dir_path_split)
        end
        new_split_folder_created[category_name] = true
        push!(combined_to_split_mapping, (save_folder_name, "$(category_name)/stage_$(lpad(string(split_stage_count + 1), 2, '0'))"))
    else
        save_dir_path_split = "metalanguage/results/unordered/by_category/$(category_name)/stage_$(lpad(string(split_stage_count), 2, '0'))"
    end

    for save_dir_path in [save_dir_path_combined, save_dir_path_split]
        ## save the single new function definition learned 
        open("$(save_dir_path)/new_function_semantics.jl", "a") do f 
            write(f, new_function_definition_str)
        end

        open("$(save_dir_path_split)/new_function_semantics.jl", "a") do f 
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
                p = visualize_left_of_blue_results(config, locations, save_filepath)
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
                push!(accuracies, (config_name, round(length(filter(x -> x == "M", labels))/length(labels), digits=3)))
            end
            open("$(number_dir)/accuracies.txt", "w") do f 
                write(f, join(map(x -> string(x), accuracies), "\n"))
            end
        else
            accuracies = map(k -> (k, round(1/length(best_locations_to_search[k]), digits=3)), sort([keys(best_locations_to_search)...]))
            open("$(number_dir)/accuracies.txt", "w") do f 
                write(f, join(map(x -> string(x), accuracies), "\n"))
            end
        end

        ### save locations to search for each spatial config (and corresponding M/R/D labels, for red-green test)
        open("$(number_dir)/locations_to_search.txt", "w") do f
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
                    push!(results, string((config_name, labels, locations)))
                end
                write(f, join(results, "\n"))
            else
                write(f, join(map(k -> string((k, best_locations_to_search[k])), sort([keys(best_locations_to_search)...])), "\n"))
            end
        end

        ### save overall percentage of perfect benchmarks
        num_solved = count(tup -> tup[2] == 1.0, accuracies)
        percentage_solved = round(num_solved/length(accuracies), digits=3)

        open("$(number_dir)/overall_benchmark_accuracy.txt", "w") do f 
            write(f, string(percentage_solved))
        end
    end
end

test()