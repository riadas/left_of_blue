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

function_sigs = [at_function, 
                 my_left_function, 
                 my_left_function_spot, 
                 my_left_function_whole,
                 left_of_function, 
                 left_of_function_spot,
                 left_of_function_whole]

sig_keys = map(sig -> split(format_new_function_string(sig), "\n")[1], function_sigs)
sig_dict = Dict(zip(sig_keys, function_sigs))

synthesized_semantics = []
while length(sig_dict) != 0
    sig_semantics = Dict()
    sig_AST_sizes = Dict()
    sig_keys = [keys(sig_dict)...]
    function_sigs = [values(sig_dict)...]

    for i in 1:length(function_sigs)
        function_sig = function_sigs[i]
        sig_key = sig_keys[i]

        possible_semantics = []
        for i in 1:1000
            semantics = generate_semantics(function_sig, base_semantics)
            push!(possible_semantics, semantics)
        end
        possible_semantics = unique(possible_semantics)

        # exclude function definitions that have been used before
        possible_semantics = filter(x -> !(x in synthesized_semantics), possible_semantics)

        # exclude function definitions that don't use all of the input arguments
        possible_semantics = filter(x -> foldl(&, map(a -> occursin(a, x), function_sig.arg_names), init=true), possible_semantics)

        possible_semantics = sort(possible_semantics)

        sig_semantics[sig_key] = possible_semantics
        sig_AST_sizes[sig_key] = unique(map(s -> size(Meta.parse(s)), possible_semantics))
    end

    all_AST_sizes = unique(vcat([values(sig_AST_sizes)...]...))

    min_AST_size = minimum(all_AST_sizes)

    sig_keys_with_min = filter(k -> min_AST_size in sig_AST_sizes[k], sig_keys)

    level_best_info = Dict()
    old_base_syntax = deepcopy(base_syntax)
    for sig_key in sig_keys_with_min 
        function_sig = sig_dict[sig_key]
        level_definitions = filter(d -> size(Meta.parse(d)) == min_AST_size, sig_semantics[sig_key])

        global base_syntax = old_base_syntax 
        old_base_syntax = deepcopy(old_base_syntax)
        updated_syntax = update_syntax_cfg(base_syntax, function_sig)

        # track best semantics
        best_definition = ""
        best_total_score = -1
        best_full_results = nothing

        for definition in level_definitions
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
            for config_name in readdir("spatial_config/configs")
                # all non-control input spatial problems
                if !occursin("no_blue", config_name) && !occursin(".DS_Store", config_name)
                    config_filepath = "spatial_config/configs/$(config_name)"
                    config = JSON.parsefile(config_filepath)

                    scene = define_spatial_reasoning_problem(config_filepath)
                    global locations = scene.locations

                    # generate a lot of possible spatial memory expressions
                    rect = filter(l -> l isa Wall && l.depth == mid, scene.locations) == []
                    # b = filter(l -> l isa Wall && l.color == blue, scene.locations) != []
                    programs = []
                    num_programs = 1000
                    for _ in 1:num_programs
                        program = generate_syntax(typeof(scene.prize), base_syntax, rect=rect) # rect=rect, blue=b
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
                            shift = (scene.prize.red.x + scene.prize.green.x)/2
                            shifted_prize = Whole(Half(scene.prize.green.x - shift), Half(scene.prize.red.x + shift), scene.prize.diagonal)
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
                            program, res = programs_and_results[end]
                            # println(program)
                            # println(res)
                            if scene.prize in res 
                                scores[config_name] = 1/length(res)
                            elseif length(res) == []
                                scores[config_name] = 1/3
                            else
                                scores[config_name] = 0
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
                println("new_best!")
                println(definition)
                best_definition = definition
                best_total_score = total_score
                best_full_results = scores
            end 

        end
        level_best_info[sig_key] = (best_definition, best_total_score, best_full_results)
    end

    categories = [[Wall, Corner], [Spot], [Half]]
    category_assignments = Dict(map(k -> k => findall(c -> intersect(sig_dict[k].arg_types, c) != [], categories)[1], sig_keys_with_min))

    conflicts = []
    for i in 1:length(categories)
        x = filter(k -> category_assignments[k] == i, sig_keys_with_min)
        if length(x) > 1 
            push!(conflicts, x)
        end
    end

    non_conflicting = sort(filter(k -> !(k in vcat(conflicts...)), sig_keys_with_min))

    global base_semantics_str = join([base_semantics_str, "# --- new stage begins ---"], "\n")

    open("metalanguage/final_semantics_unordered.jl", "w+") do f 
        write(f, base_semantics_str)
    end

    global base_syntax = deepcopy(old_base_syntax)
    all = sort([non_conflicting..., vcat(conflicts...)...], by=x -> findall(y -> occursin(y, x), ["at(", "my_left(", "left_of("])[1])
    for k in all # non_conflicting 
        function_sig = sig_dict[k]
        best_definition = level_best_info[k][1]
        # update final semantics and syntax with new function definition
        function_sig.definition = best_definition
        new_function_definition_str = format_new_function_string(function_sig)
        println("new function definition")
        println(new_function_definition_str)
        
        push!(synthesized_semantics, best_definition)

        global base_semantics_str = join([base_semantics_str, new_function_definition_str], "\n")

        open("metalanguage/final_semantics_unordered.jl", "w+") do f 
            write(f, base_semantics_str)
        end

        # update semantics cfg 
        # global base_semantics = update_semantics_cfg(base_semantics, function_sig)

        # update syntax cfg 
        global base_syntax = update_syntax_cfg(base_syntax, function_sig)

        delete!(sig_dict, k)
    end

    # handle conflicts 
    winners = []
    for arr in conflicts 
        # TODO
        println("oops")
        println(conflicts)
        # break
    end

    for winner in winners 
        delete!(sig_dict, winner)
    end 

    sig_keys = [keys(sig_dict)...]
    # break
end