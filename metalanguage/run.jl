include("metalanguage.jl")
include("../spatial_config/spatial_config.jl")

global base_semantics_str = ""
open("metalanguage/base_semantics.jl", "r") do f 
    global base_semantics_str = read(f, String)
end

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

# ordered_function_sigs = [my_left_function_whole, left_of_function_whole]
categories = [[Wall, Corner, DEPTH, COLOR], [Spot], [Half, Whole]]
synthesized_semantics = Dict(map(x -> x => [], 1:length(categories)))
prev_best_scores = Dict(map(x -> x => -1.0, 1:length(categories)))
for function_sig in ordered_function_sigs
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

    for definition in possible_semantics 
        function_sig.definition = definition
        new_function_definition_str = format_new_function_string(function_sig)

        # update semantics.jl file with new function and import file
        new_semantics_str = join([base_semantics_str, new_function_definition_str], "\n")
        open("metalanguage/intermediate_semantics.jl", "w+") do f 
            write(f, new_semantics_str)
        end
        include("intermediate_semantics.jl")

        # generate lots of programs in the new language, and measure performance across suite of spatial configurations
        # if performance is higher than base language, save that program and its score

        scores = Dict()

        config_names = readdir("spatial_config/configs")
        if category_assignment == 1 # LoB experiments
            config_names = filter(x -> occursin("room", x), config_names)
        elseif category_assignment == 2 # spatial lang. experiments
            config_names = filter(x -> occursin("spatial", x), config_names)
        elseif category_assignment == 3 # red-green experiments
            config_names = filter(x -> occursin("green", x), config_names)
        end

        for config_name in config_names
            # all non-control input spatial problems
            if !occursin("no_blue", config_name) && !occursin(".DS_Store", config_name)
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
                        res = filter(x, new_locations)

                        final_res = nothing
                        if res == [] 
                            final_res = nothing
                        else
                            final_res = filter(x, scene.locations)
                        end

                        push!(results, final_res)
                    end

                end

                if scene.prize isa Whole 
                    # println("----- config name: $(config_name)")
                    idxs = findall(x -> !isnothing(x), results)
                    programs = map(i -> programs[i], idxs)
                    results = map(i -> results[i], idxs)
                    
                    # println("programs")
                    # println(programs)
                    # println("results")
                    # println(results)

                    if results == []
                        scores[config_name] = 1/3
                    else
                        programs_and_results = sort([zip(programs, results)...], by=tup -> length(tup[1]))
                        # for tup in programs_and_results 
                        #     println("program and result")
                        #     println(tup[1])
                        #     println(tup[2])
                        # end
                        program, res = programs_and_results[end]
                        # println(program)
                        # println(res)
                        # println("score")
                        if scene.prize in res 
                            scores[config_name] = 1/length(res)
                            # println(1/length(res))
                        elseif length(res) == []
                            scores[config_name] = 1/3
                            # println(1/3)
                        else
                            scores[config_name] = 0
                            # println(0)
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
                end

            end
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
    else
        # remove function from syntax CFG 
        updated_syntax = update_syntax_cfg(base_syntax, function_sig, remove=true)
    end

end

# TODO: 
# 1. "grouped" introduction of new function signatures, e.g. left/right (edit distance?)
# 2. fully joint introduction of new function signatures -- i.e. by taking advantage of AST length 