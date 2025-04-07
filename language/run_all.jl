using JSON
language_variant = "4_egocentric_relative"
typed = "untyped"

# import syntax, which also imports semantics
include("language_variants/$(typed)/$(language_variant)/syntax.jl")

# define spatial configuration
include("../spatial_config/spatial_config.jl")

scores = Dict()
for config_name in readdir("spatial_config/configs")
    # all non-control input spatial problems
    if !occursin("square", config_name) && !occursin(".DS_Store", config_name)
        config_filepath = "spatial_config/configs/$(config_name).json"
        config = JSON.parsefile(config_filepath)

        scene = define_spatial_reasoning_problem(config_filepath)
        locations = scene.locations

        # generate a lot of possible spatial memory expressions
        # rect = filter(l -> l isa Wall && l.depth == mid, scene.locations) == []
        # b = filter(l -> l isa Wall && l.color == blue, scene.locations) != []
        programs = []
        num_programs = 1000
        for _ in 1:num_programs
            program = generate_program(scene.prize) # rect=rect, blue=b
            push!(programs, program)
        end
        programs = unique(programs)

        # evaluate all the possible spatial memory representations and select the best one
        formatted_programs = []
        for program in programs
            println(program) 
            if typed == "typed"
                program = "let x = $(program); x isa TypedBool ? x.val : x end"
            end

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
            println(formatted_programs[i])
            push!(results, filter(x, scene.locations))
        end

        programs_and_results = [zip(programs, results)...]
        programs_and_results = filter(tup -> scene.prize in tup[2], programs_and_results)

        best_indices = findall(t -> length(t[2]) == minimum(map(tup -> length(tup[2]), programs_and_results)), programs_and_results)
        best_programs = map(i -> programs_and_results[i], best_indices)

        sort!(best_programs, by=tup -> length(tup[1]))
        best_program, locations_to_search = best_programs[1]
        println(best_program)
        println(locations_to_search)

        # record generated programs
        intermediate_programs_output_dir = "language/outputs/generated_programs/$(config_name)"
        if !isdir(intermediate_programs_output_dir)
            mkdir(intermediate_programs_output_dir)
        end

        open("$(intermediate_programs_output_dir)/$(language_variant).txt", "w+") do f 
            write(f, join(programs, "\n"))
        end

        scores[config_name] = 1/length(locations_to_search)

        # # visualize results
        # include("../spatial_config/viz.jl")

        # config_output_dir = "language/outputs/results/$(config_name)"
        # if !isdir(config_output_dir)
        #     mkdir(config_output_dir)
        # end

        # if config["type"] == "left_of_blue"
        #     p = visualize_left_of_blue_results(config, scene, locations_to_search, "$(config_output_dir)/$(language_variant).png")
        # else
        #     p = visualize_spatial_lang_results(config, locations_to_search, "$(config_output_dir)/$(language_variant).png")
        # end

        # run(language_variant, config_name)
    end
end

for pair in scores 
    println(pair)
end