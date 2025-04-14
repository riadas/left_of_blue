include("metalanguage.jl")
include("../spatial_config/viz.jl")

global base_semantics_str = ""
open("metalanguage/base_semantics.jl", "r") do f 
    global base_semantics_str = read(f, String)
end

didactic = false
if didactic
    results_dir = "metalanguage/results/didactic"
else
    results_dir = "metalanguage/results"
end

# reset results folders
category_names = ["left_of_blue", "spatial_lang_test", "red_green_test"]
combined_results_dir = "$(results_dir)/ordered/combined"
if isdir(combined_results_dir)
    rm(combined_results_dir, recursive=true)
end
mkdir(combined_results_dir)

split_results_dir = "$(results_dir)/ordered/by_category"
if isdir(split_results_dir)
    rm(split_results_dir, recursive=true)
end
mkdir(split_results_dir)
for category_name in category_names 
    mkdir("$(split_results_dir)/$(category_name)")
end
combined_to_split_mapping = []

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

ordered_function_sigs = [
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

didactic_examples = [left_of_function, "left_of(location, blue)", "rect_room_blue_wall_left_prize.json"]

# ordered_function_sigs = [my_left_function_whole, left_of_function_whole]
categories = [[Wall, Corner, DEPTH, COLOR], [Spot], [Half, Whole]]
synthesized_semantics = Dict(map(x -> x => [], 1:length(categories)))
prev_best_scores = Dict(map(x -> x => -1.0, 1:length(categories)))
for function_index in 1:length(ordered_function_sigs)
    function_sig = ordered_function_sigs[function_index]
    category_assignment = findall(c -> intersect(function_sig.arg_types, c) != [], categories)[1]

    possible_semantics = []
    for i in 1:1000
        semantics = generate_semantics(function_sig, base_semantics)
        push!(possible_semantics, semantics)
    end
    possible_semantics = unique(possible_semantics)
    # println(possible_semantics)
    # exclude function definitions that have been used before
    possible_semantics = filter(x -> !(x in synthesized_semantics[category_assignment]), possible_semantics)

    # exclude function definitions that don't use all of the input arguments
    possible_semantics = filter(x -> foldl(&, map(a -> occursin(a, x), function_sig.arg_names), init=true), possible_semantics)

    possible_semantics = sort(possible_semantics)

    # update syntax cfg to include function
    updated_syntax = update_syntax_cfg(base_syntax, function_sig)

    # track best semantics
    best_definition = ""
    best_total_score = -1
    best_full_results = nothing
    best_locations_to_search = Dict()

    for definition in possible_semantics 
        function_sig.definition = definition
        new_function_definition_str = format_new_function_string(function_sig)

        # update semantics.jl file with new function and import file
        new_semantics_str = join([base_semantics_str, new_function_definition_str], "\n")
        open("metalanguage/intermediate_outputs/intermediate_semantics.jl", "w+") do f 
            write(f, new_semantics_str)
        end
        include("intermediate_outputs/intermediate_semantics.jl")

        # generate lots of programs in the new language, and measure performance across suite of spatial configurations
        # if performance is higher than base language, save that program and its score

        scores = Dict()
        search_locations = Dict()

        config_names = readdir("spatial_config/configs")
        if category_assignment == 1 # LoB experiments
            config_names = filter(x -> occursin("room", x), config_names)
        elseif category_assignment == 2 # spatial lang. experiments
            config_names = filter(x -> occursin("spatial", x), config_names)
        elseif category_assignment == 3 # red-green experiments
            config_names = filter(x -> occursin("green", x), config_names)
        end

        didactic_failed = false
        for config_name in config_names
            # all non-control input spatial problems
            if !occursin("no_blue", config_name) && !occursin(".DS_Store", config_name)
                # println(config_name)
                config_filepath = "spatial_config/configs/$(config_name)"
                config = JSON.parsefile(config_filepath)

                scene = define_spatial_reasoning_problem(config_filepath)
                global locations = scene.locations

                if didactic 
                    didactic_function_sig, didactic_program, didactic_config_name = didactic_examples[1]
                    if didactic_function_sig.name == function_sig.name && didactic_config_name == config_name 
                        if scene.prize isa Wall 
                            didactic_program = "location isa Wall && $(didactic_program)"
                        elseif scene.prize isa Corner
                            didactic_program = "location isa Corner && $(didactic_program)"
                        end

                        evaluated_lambda = eval(Meta.parse("location -> $(didactic_program)"))
                        results = filter(evaluated_lambda, scene.locations)
                        if !(scene.prize in results) 
                            didactic_failed = true
                            continue
                        end
                    end
                end

                # generate a lot of possible spatial memory expressions
                rect = filter(l -> l isa Wall && l.depth == mid, scene.locations) == []
                shift = occursin("shift", config_name) ? parse(Int, replace(split(config_name, "shift_")[end], ".json" => "")) : 0
                # b = filter(l -> l isa Wall && l.color == blue, scene.locations) != []
                programs = []
                num_programs = 1000
                for _ in 1:num_programs
                    program = generate_syntax(typeof(scene.prize), base_syntax, rect=rect, shift=shift) # rect=rect, blue=b
                    push!(programs, program)
                end
                programs = unique(programs)

                # exclude programs that don't include the input argument
                # println(programs)
                programs = filter(x -> x == "true" || occursin("location", x), programs)
                # println(programs)

                # evaluate all the possible spatial memory representations and select the best one
                formatted_programs = []
                for program in programs
                    # println(program) 
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
                    x = evaluated_lambdas[i]
                    # println(formatted_programs[i])

                    if !(scene.prize isa Whole)
                        push!(results, filter(x, scene.locations))
                    else
                        shift = (scene.prize.coral.x + scene.prize.green.x)/2
                        shifted_prize = Whole(Half(scene.prize.green.x - shift), Half(scene.prize.coral.x - shift), scene.prize.diagonal)
                        new_locations = [shifted_prize]
                        res = filter(x, new_locations) # programs that evaluate to true on the centered prize

                        final_res = nothing
                        if res == [] # no programs match the centered prize
                            final_res = nothing
                        else
                            final_res = filter(x, scene.locations) # final locations on which this program is true
                        end

                        push!(results, final_res)
                    end

                end

                if scene.prize isa Whole 
                    println("----- config name: $(config_name)")
                    idxs = findall(x -> !isnothing(x), results)
                    programs = map(i -> programs[i], idxs)
                    results = map(i -> results[i], idxs)
                    
                    println("programs")
                    println(programs)
                    println("results")
                    println(results)

                    if results == []
                        scores[config_name] = 1/3
                        search_locations[config_name] = scene.locations
                    else
                        programs_and_results = sort([zip(programs, results)...], by=tup -> length(tup[1]))
                        for tup in programs_and_results 
                            println("program and result")
                            println(tup[1])
                            println(tup[2])
                        end
                        program, res = programs_and_results[end]
                        println(program)
                        println(res)
                        println("score")
                        if scene.prize in res 
                            scores[config_name] = 1/length(res)
                            search_locations[config_name] = res
                            println(1/length(res))
                        elseif length(res) == 0
                            scores[config_name] = 1/3
                            search_locations[config_name] = scene.locations
                            println(1/3)
                        else
                            scores[config_name] = 0
                            search_locations[config_name] = res
                            println(0)
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
                    # println(best_program)
                    # println(locations_to_search)
                    # println(filter(x -> occursin("left_of", x), programs))
                    # println(base_syntax[typeof(scene.prize)])
                    # println("\n")
    
                    scores[config_name] = 1/length(locations_to_search)
                    search_locations[config_name] = locations_to_search
                end

            end
        end

        if didactic_failed 
            continue
        end

        total_score = sum([values(scores)...])
        update_best = false
        if total_score > best_total_score
            update_best = true
        elseif total_score == best_total_score 
            if size(Meta.parse(best_definition)) > size(Meta.parse(definition)) 
                update_best = true
            elseif size(Meta.parse(best_definition)) == size(Meta.parse(definition)) && length(best_definition) > length(definition)
                update_best = true 
            elseif length(best_definition) == length(definition) && best_definition < definition
                update_best = true
            end
        end

        if update_best 
            best_definition = definition
            best_total_score = total_score
            best_full_results = scores
            best_locations_to_search = search_locations
            println("----- new best!")
            println(definition)
            println(total_score)
            # println(scores)
        else
            # println("----- discarding...")
            # println(definition)
            # println(total_score)
        end 

    end

    # println(best_full_results)

    # update final semantics and syntax with new function definition
    if best_total_score > prev_best_scores[category_assignment]
        prev_best_scores[category_assignment] = best_total_score
        function_sig.definition = best_definition
        new_function_definition_str = format_new_function_string(function_sig)
        println("new function definition")
        println(new_function_definition_str)
        
        push!(synthesized_semantics[category_assignment], best_definition)
    
        global base_semantics_str = join([base_semantics_str, new_function_definition_str], "\n")
    
        open("metalanguage/final_semantics.jl", "w+") do f 
            write(f, base_semantics_str)
        end
    
        # update semantics cfg 
        global base_semantics = update_semantics_cfg(base_semantics, function_sig)

        # save results
        save_folder_name = "stage_$(lpad(string(function_index), 2, '0'))" 
        save_dir_path_combined = "$(combined_results_dir)/$(save_folder_name)"
        if !isdir(save_dir_path_combined)
            mkdir(save_dir_path_combined)
        end

        category_name = category_names[category_assignment]
        println(category_name)
        split_stage_count = length(readdir("$(split_results_dir)/$(category_name)"))
        save_dir_path_split = "$(results_dir)/ordered/by_category/$(category_name)/stage_$(lpad(string(split_stage_count + 1), 2, '0'))"
        if !isdir(save_dir_path_split)
            mkdir(save_dir_path_split)
        end

        push!(combined_to_split_mapping, (save_folder_name, "$(category_name)/stage_$(lpad(string(split_stage_count + 1), 2, '0'))"))

        for save_dir_path in [save_dir_path_combined, save_dir_path_split]
            ## save the single new function definition learned 
            open("$(save_dir_path)/new_function_semantics.jl", "w") do f 
                write(f, new_function_definition_str)
            end

            open("$(save_dir_path_split)/new_function_semantics.jl", "w") do f 
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
                    scene = define_spatial_reasoning_problem(config_filepath)
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


    else
        # remove function from syntax CFG 
        updated_syntax = update_syntax_cfg(base_syntax, function_sig, remove=true)

        # save results
        save_folder_name = "stage_$(lpad(string(function_index), 2, '0'))" 
        save_dir_path_combined = "$(results_dir)/ordered/combined/$(save_folder_name)"
        if !isdir(save_dir_path_combined)
            mkdir(save_dir_path_combined)
        end

        category_name = category_names[category_assignment]
        split_stage_count = length(readdir("$(results_dir)/ordered/by_category/$(category_name)"))
        save_dir_path_split = "$(results_dir)/ordered/by_category/$(category_name)/stage_$(lpad(string(split_stage_count + 1), 2, '0'))"
        if !isdir(save_dir_path_split)
            mkdir(save_dir_path_split)
        end

        for save_dir_path in [save_dir_path_combined, save_dir_path_split]
            ## save the single new function definition learned 
            open("$(save_dir_path)/new_function_semantics.jl", "w") do f 
                write(f, "no function learned -- accuracy does not improve")
            end
        end

    end

end

open("$(results_dir)/ordered/combined_to_by_category_mapping.txt", "w") do f 
    write(f, join(map(tup -> string(tup), combined_to_split_mapping), "\n"))
end

# TODO: 
# 1. "grouped" introduction of new function signatures, e.g. left/right (edit distance?)
# 2. fully joint introduction of new function signatures -- i.e. by taking advantage of AST length 