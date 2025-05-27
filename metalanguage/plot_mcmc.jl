include("run_unordered_analogy.jl")
include("plot_scatter.jl")
include("generate_all_plots.jl")
using Plots 

age_groups = [1, 2, 3, 4]
# correlation_dict = Dict()
test_name = "test1"
test_config_names = [
    "square_room_blue_wall_center_prize.json",
    "square_room_blue_wall_center_prize_copy1.json",
    "square_room_blue_wall_center_prize_copy2.json",  
    "square_room_blue_wall_center_prize_copy3.json", 
    "square_room_blue_wall_center_prize_copy4.json",   
    "spatial_lang_test_left_true_shift_0.json", 
    "spatial_lang_test_copy_left_true_shift_0.json", 
    "spatial_lang_test_copy2_left_true_shift_0.json",
    "spatial_lang_test_copy3_left_true_shift_0.json", 
    "square_room_blue_wall_left_prize.json",
    # "square_room_blue_wall_far-left-corner_prize.json"
]

function symmetric_replace(definition, pair)
    new_definition = definition
    if occursin(pair[1], definition)
        new_definition = replace(new_definition, pair[1] => pair[2])        
    elseif occursin(pair[2], definition) 
        new_definition = replace(new_definition, pair[2] => pair[1])
    end
    new_definition
end

function generate_symmetric_variants(function_sigs, swap_name_pairs=[])
    same_different_bools = generate_same_different_bools(function_sigs)

    symmetries = [
        ["next", "prev"],
        ["<", ">"],
        ["wall1", "wall2"]
    ]

    synthesized_function_sigs = filter(x -> x.definition != "", function_sigs) 

    symmetry_sets = []
    for func in synthesized_function_sigs 
        symmetric_definitions = [func.definition]
        symmetric_definition = func.definition
        for pair in symmetries 
            symmetric_definition = symmetric_replace(symmetric_definition, pair)
        end
        push!(symmetric_definitions, symmetric_definition)
        unique!(symmetric_definitions)
        push!(symmetry_sets, symmetric_definitions)
    end

    perms = [Iterators.product(symmetry_sets...)...]
    filter!(tup -> length(unique([tup...])) == length(tup), perms)

    symmetric_variants = []
    for tup in perms 
        function_sigs_copy = deepcopy(function_sigs)
        synthesized_function_sigs = filter(x -> x.definition != "", function_sigs_copy)
        for i in 1:length(synthesized_function_sigs)
            synthesized_function_sigs[i].definition = tup[i]
        end

        same_different_bools_copy = generate_same_different_bools(function_sigs_copy)

        if same_different_bools_copy == same_different_bools 
            push!(symmetric_variants, function_sigs_copy)
        end
    end

    swap_variants = []
    for symmetric_variant in symmetric_variants 
        function_sigs_copy = deepcopy(symmetric_variant)
        for swap_pair in swap_name_pairs 
            if (swap_pair[1] in map(x -> x.name, function_sigs_copy)) && (swap_pair[2] in map(x -> x.name, function_sigs_copy))
                func1 = filter(x -> x.name == swap_pair[1], function_sigs_copy)[1]
                def1 = func1.definition
    
                func2 = filter(x -> x.name == swap_pair[2], function_sigs_copy)[1]
                def2 = func2.definition
    
                func1.definition = replace(def2, "color1_arg" => "color_arg") 
                func2.definition = replace(def1, "color_arg" => "color1_arg")
            end
        end 

        push!(swap_variants, function_sigs_copy)
    end

    symmetric_variants = map(y -> eval(Meta.parse(y)), unique(map(x -> repr(x), [symmetric_variants..., swap_variants...])))

    return symmetric_variants
end

function generate_same_different_bools(function_sigs)
    type_signature_groups = Dict()
    for f in function_sigs
        type_signature = repr([f.arg_names..., f.arg_types...])
        if !(type_signature in keys(type_signature_groups))
            type_signature_groups[type_signature] = [f]
        else
            push!(type_signature_groups[type_signature], f)
        end
    end

    bools = []
    type_signatures = sort([keys(type_signature_groups)...], by=x -> findall(y -> repr([y.arg_names..., y.arg_types...]) == x,  all_function_sigs)[1])
    for type_signature in type_signatures 
        fs = type_signature_groups[type_signature]
        if length(fs) > 1 
            if fs[1].definition == fs[2].definition # definitions are the same
                push!(bools, true)
            else # definition are different
                push!(bools, false)
            end
        else # only one definition, i.e. no paired function sig ('at')
            push!(bools, true)
        end
    end
    
    return bools
end

function plot_relative_proportions(chains, mode, test_config_names, swap_name_pairs=[], save_suffix="", existing_plot=nothing, subset_start=-1)
    histograms = []
    map_estimates = []
    new_map_estimates = []
    corrected_map_estimates = []
    symmetric_variants_dict = Dict()
    for chain in chains 
        if length(chain) != length(chains[1])

        else
            q = map(y -> (y, count(z -> repr(z) == y, chain)), unique(map(x -> repr(x), filter(w -> true, chain))))
            q_sorted = reverse(sort(q, by=x -> x[2]))
            push!(histograms, q_sorted)
            
            map_estimate = q_sorted[1][1]
            println(length(histograms))
            println(map_estimate)
            push!(map_estimates, map_estimate)
            
            # correct left/right labels
            new_map_est = correct_reversed_left_right_labels(eval(Meta.parse(map_estimate)), "left", test_config_names)

            # correct left_of(_opposite)
            if length(chains[end]) == 7 
                if !("" in map(x -> x.definition, new_map_est))
                    for swap_pair in swap_name_pairs 
                    
                        func1 = filter(x -> x.name == swap_pair[1], new_map_est)[1]
                        def1 = func1.definition
            
                        func2 = filter(x -> x.name == swap_pair[2], new_map_est)[1]
                        def2 = func2.definition
            
                        func1.definition = replace(def2, "color1_arg" => "color_arg") 
                        func2.definition = replace(def1, "color_arg" => "color1_arg")
                    
                    end 
            
                end
            end

            push!(new_map_estimates, repr(new_map_est))
            symmetric_variants_dict[repr(new_map_est)] = generate_symmetric_variants(eval(Meta.parse(map_estimate)), swap_name_pairs)
        end 
    end

    @show symmetric_variants_dict 
    @show histograms 
    @show map_estimates
    @show new_map_estimates 
    @show corrected_map_estimates 

    new_to_old_map_estimate_dict = Dict(map(i -> new_map_estimates[i] => map_estimates[i], 1:length(new_map_estimates)))

    unique!(new_map_estimates)

    sort!(new_map_estimates, by=length)
    @show new_map_estimates
    plot_data = Dict()
    p = ""
    sums = zeros(length(chains) + 1)
    sums[1] = 1.0
    all_results = map(x -> [], 1:(length(chains) + 1)) 
    all_results[1] = [0.0, 0.0, 0.0, 1.0]
    for map_estimate_str_new in new_map_estimates 
        plot_data[map_estimate_str_new] = [0.0]
        for i in 1:length(histograms)
            histogram = histograms[i]
            total = 0.0
            for map_estimate in symmetric_variants_dict[map_estimate_str_new]
                map_estimate_str = repr(map_estimate)
                proportions = filter(tup -> tup[1] == map_estimate_str, histogram)
                if proportions != []
                    proportion = proportions[1][2]
                else
                    proportion = 0.0
                end
                total += proportion
            end
                        
            push!(plot_data[map_estimate_str_new], total)
            sums[i + 1] += total
            push!(all_results[i + 1], total) 
        end
    end

    map_estimates = new_map_estimates

    for i in 1:length(all_results)
        all_results[i] = sort(all_results[i])
    end

    legend_names = Dict([
        "geo" => "geometric",
        "at" => "associational",
        "my_right" => "intrinsic ego.",
        "right_of" => "relative ego." 
    ])

    age_group_legend_names = Dict([
        1 => "18-24 months",
        2 => "3-4 years", 
        3 => "4-6 years",
        4 => "6+ years",
    ])

    if mode == "proportion"
    
        if !isnothing(existing_plot)
            p = existing_plot
        else
            p = ""
        end

        seen_intrinsic = false
        for map_estimate_str in map_estimates 
            println(plot_data[map_estimate_str])
            println(sums)
            println(plot_data[map_estimate_str] ./ sums)
            println()
            l = filter(x -> x.definition != "", eval(Meta.parse(map_estimate_str)))
            if l == [] 
                l = "geo"
            else
                l = l[end].name
            end
            l = legend_names[l]
            println(l)

            if isnothing(existing_plot) || !isnothing(existing_plot) && l == "intrinsic ego."
                data = plot_data[map_estimate_str] ./ sums 
                # data = map(i -> findall(x -> x == plot_data[map_estimate_str][i], all_results[i])[1], 1:length(plot_data[map_estimate_str]))
                
                lstyle = !isnothing(existing_plot) ? :dot : :solid 
                cc = !isnothing(existing_plot) ? theme_palette(:auto)[9] : :auto
                
                if seen_intrinsic && l == "intrinsic ego." 
                    l_ = "certain L/R"
                    cc = :palegreen3
                elseif !isnothing(existing_plot)
                    l_ = "uncertain L/R"
                    # cc = :yellowgreen
                else
                    l_ = l
                end

                if l == "intrinsic ego." 
                    seen_intrinsic = true
                end

                if subset_start == -1
                    if p == ""
                        p = plot(collect(0:length(chains)), data, label=l_, linewidth=3, legend=:right, xlims = (0,length(chains)), xticks = 0:1:length(chains), ylims=(0, 1.1), yticks = 0:0.1:1, linestyle=lstyle, color=cc)
                    else
                        p = plot!(p, collect(0:length(chains)), data, label=l_, linewidth=3, legend=:right, xlims = (0,length(chains)), xticks = 0:1:length(chains), ylims=(0, 1.1), yticks = 0:0.1:1, linestyle=lstyle, color=cc)
                    end
                else
                    @show data
                    @show collect(subset_start:(subset_start - 1 + length(chains)))
                    p = plot!(p, collect(subset_start:(subset_start - 1 + length(chains))), data[2:end], label=l_, linewidth=4, legend=:right, xlims = (0,length(chains)), xticks = 0:1:length(chains), ylims=(0, 1.1), yticks = 0:0.1:1, linestyle=lstyle, color=theme_palette(:auto)[9])
                end
            end
        end

        xlabel!("Data", xguidefontsize=9)
        ylabel!("Proportion", yguidefontsize=9)
        title!("Relative Proportions of Spatial LoT Stages vs. Data Volume", titlefontsize=10)

    elseif mode == "rank"
        p = ""
        for map_estimate_str in map_estimates 
            println(plot_data[map_estimate_str])
            println(sums)
            println(plot_data[map_estimate_str] ./ sums)
            println()
            l = filter(x -> x.definition != "", eval(Meta.parse(map_estimate_str)))
            if l == [] 
                l = "geo"
            else
                l = l[end].name
            end
            l = legend_names[l]
            # data = plot_data[map_estimate_str] ./ sums 
            @show all_results
            data = map(i -> findall(x -> x == plot_data[map_estimate_str][i], all_results[i])[1], 1:length(plot_data[map_estimate_str]))
        
            if p == ""
                p = plot(collect(0:length(chains)), data, label=l, linewidth=3, legend=:right, xlims = (0,length(chains)), xticks = 0:1:length(chains))
            else
                p = plot!(p, collect(0:length(chains)), data, label=l, linewidth=3, legend=:right, xlims = (0,length(chains)), xticks = 0:1:length(chains))
            end
        end

        xlabel!("Data", xguidefontsize=9)
        ylabel!("Rank", yguidefontsize=9)
        title!("Relative Ranks of Spatial LoT Stages vs. Data Volume", titlefontsize=10)
    
    elseif mode == "correlation_map"

        age_group_plot_data = Dict(map(x -> x => [0.0], age_groups))
        names = []
        for t in 2:length(all_results)
            m = maximum(all_results[t])
            model_stage = findall(x -> plot_data[x][t] == m, map_estimates)[1]
            l = filter(x -> x.definition != "", eval(Meta.parse(map_estimates[model_stage])))
            if l == [] 
                l = "geo"
            else
                l = l[end].name
            end
            push!(names, l)
            for age_group in age_groups 
                if length(names) > 1 && names[end - 1] == "my_right"
                    println("hello")
                    vals = correlation_dict[("my_right_lang", age_group)]
                else
                    vals = correlation_dict[(l, age_group)]
                end
                c = round(cor(map(x -> x[1], vals), map(x -> x[2], vals)), digits=3)
                # c = c * c
                push!(age_group_plot_data[age_group], c)
            end
        end

        p = ""
        for age_group in age_groups 
            l = "$(age_group)"
            data = age_group_plot_data[age_group]
            if p == ""
                p = plot(collect(0:(length(data)- 1)), data, label=age_group_legend_names[age_group], linewidth=3, legend=:topright, xlims = (0,length(data) - 1), xticks = 0:1:(length(data) - 1), ylims=(0, 1.1), yticks = 0:0.1:1)
            else
                p = plot!(p, collect(0:length(chains)), data, label=age_group_legend_names[age_group], linewidth=3, legend=:topright, xlims = (0,length(data) - 1), xticks = 0:1:(length(data) - 1), ylims=(0, 1.1), yticks = 0:0.1:1)
            end
        end

        xlabel!("Data", xguidefontsize=9)
        ylabel!("R", yguidefontsize=9)
        title!("Correlation between MAP Spatial LoT Model Predictions\nand Empirical Results vs. Training Data Volume", titlefontsize=10)

    elseif mode == "correlation_avg"
        age_group_plot_data = Dict(map(x -> x => [0.0], age_groups))

        names = []
        for t in 2:length(all_results)
            m = maximum(all_results[t])
            model_stage = findall(x -> plot_data[x][t] == m, map_estimates)[1]
            l = filter(x -> x.definition != "", eval(Meta.parse(map_estimates[model_stage])))
            if l == [] 
                l = "geo"
            else
                l = l[end].name
            end
            push!(names, l)
        end

        for t in 2:length(all_results)
            for age_group in age_groups 
                weighted_correlations = []
                for map_estimate in keys(plot_data)
                    
                    l = filter(x -> x.definition != "", eval(Meta.parse(map_estimate)))
                    if l == [] 
                        l = "geo"
                    else
                        l = l[end].name
                    end
                    
                    println(names)
                    if t > 2 && names[t - 2] == "my_right"
                        println("hello 1")
                        if l == "my_right"
                            println("hello 2")
                            vals = correlation_dict[("my_right_lang", age_group)]
                            prop = 1.0
                        else
                            vals = correlation_dict[(l, age_group)]
                            prop = 0.0
                        end
                        # prop = plot_data[map_estimate][t - 1] / sums[t - 1]
                    else
                        vals = correlation_dict[(l, age_group)]
                        prop = plot_data[map_estimate][t] / sums[t]
                    end

                    c = round(cor(map(x -> x[1], vals), map(x -> x[2], vals)), digits=3)
                    # c = c * c
                    push!(weighted_correlations, c * prop)
                end
                push!(age_group_plot_data[age_group], sum(weighted_correlations))
            end 
        end

        p = ""
        for age_group in age_groups 
            l = "$(age_group)"
            data = age_group_plot_data[age_group]
            if p == ""
                p = plot(collect(0:(length(data)-1)), data, label=age_group_legend_names[age_group], linewidth=3, legend=:topright, xlims = (0,length(data) - 1), xticks = 0:1:(length(data) - 1), ylims=(0, 1.1), yticks = 0:0.1:1)
            else
                p = plot!(p, collect(0:length(chains)), data, label=age_group_legend_names[age_group], linewidth=3, legend=:topright, xlims = (0,length(data) - 1), xticks = 0:1:(length(data) - 1), ylims=(0, 1.1), yticks = 0:0.1:1)
            end
        end

        xlabel!("Data", xguidefontsize=9)
        ylabel!("R", yguidefontsize=9)
        title!("Correlation between Weighted Spatial LoT Model Predictions\nand Empirical Results vs. Training Data Volume", titlefontsize=10)

    end

    if save_suffix != ""
        savefig("$(mode)_$(save_suffix)_temp2_R.png")
    end

    return p
end

# include("run_unordered_analogy.jl")
# include("plot_scatter.jl")
# include("generate_all_plots.jl")
# using Plots 

# age_groups = [1, 2, 3, 4]
# # correlation_dict = Dict()

# function plot_relative_proportions(chains, mode="proportion", save_suffix="")
#     histograms = []
#     map_estimates = []
#     for chain in chains 
#         if length(chain) != length(chains[1])

#         else
#             q = map(y -> (y, count(z -> repr(z) == y, chain)), unique(map(x -> repr(x), filter(w -> true, chain))))
#             q_sorted = reverse(sort(q, by=x -> x[2]))
#             push!(histograms, q_sorted)
            
#             map_estimate = q_sorted[1][1]
#             println(length(histograms))
#             println(map_estimate)
#             push!(map_estimates, map_estimate)
#         end 
#     end

#     unique!(map_estimates)

#     sort!(map_estimates, by=length)
#     @show map_estimates
#     plot_data = Dict()
#     p = ""
#     sums = zeros(length(chains) + 1)
#     sums[1] = 1.0
#     all_results = map(x -> [], 1:(length(chains) + 1)) 
#     all_results[1] = [0.0, 0.0, 0.0, 1.0]
#     for map_estimate_str in map_estimates 
#         plot_data[map_estimate_str] = [0.0]
#         for i in 1:length(histograms)
#             histogram = histograms[i]
#             proportions = filter(tup -> tup[1] == map_estimate_str, histogram)
            
#             if proportions != []
#                 proportion = proportions[1][2]
#             else
#                 proportion = 0.0
#             end
            
#             push!(plot_data[map_estimate_str], proportion)
#             sums[i + 1] += proportion
#             push!(all_results[i + 1], proportion) 
#         end
#     end

#     for i in 1:length(all_results)
#         all_results[i] = sort(all_results[i])
#     end

#     legend_names = Dict([
#         "geo" => "geometric",
#         "at" => "associational",
#         "my_left" => "intrinsic egocentric",
#         "left_of" => "relative egocentric" 
#     ])

#     age_group_legend_names = Dict([
#         1 => "18-24 months",
#         2 => "3-4 years", 
#         3 => "4-6 years",
#         4 => "6+ years",
#     ])

#     all_correlation_dicts = Dict()
#     for map_estimate_str in map_estimates 
#         l = filter(x -> x.definition != "", eval(Meta.parse(map_estimate_str)))
#         if l == [] 
#             l = "geo"
#         else
#             l = l[end].name
#         end

#         correlation_dict = generate_correlation_dict(eval(Meta.parse(map_estimate_str)), empirical_data, false)
#         all_correlation_dicts[l] = correlation_dict

#         if l == "my_left"
#             correlation_dict = generate_correlation_dict(eval(Meta.parse(map_estimate_str)), empirical_data, true)
#             all_correlation_dicts["my_left_lang"] = correlation_dict
#         end
#     end

#     if mode == "proportion"
    
#         p = ""
#         for map_estimate_str in map_estimates 
#             println(plot_data[map_estimate_str])
#             println(sums)
#             println(plot_data[map_estimate_str] ./ sums)
#             println()
#             l = filter(x -> x.definition != "", eval(Meta.parse(map_estimate_str)))
#             if l == [] 
#                 l = "geo"
#             else
#                 l = l[end].name
#             end
#             l = legend_names[l]
#             data = plot_data[map_estimate_str] ./ sums 
#             # data = map(i -> findall(x -> x == plot_data[map_estimate_str][i], all_results[i])[1], 1:length(plot_data[map_estimate_str]))
            
#             if p == ""
#                 p = plot(collect(0:length(chains)), data, label=l, linewidth=3, legend=:right, xlims = (0,length(chains)), xticks = 0:1:length(chains), ylims=(0, 1.1), yticks = 0:0.1:1)
#             else
#                 p = plot!(p, collect(0:length(chains)), data, label=l, linewidth=3, legend=:right, xlims = (0,length(chains)), xticks = 0:1:length(chains), ylims=(0, 1.1), yticks = 0:0.1:1)
#             end
#         end

#         xlabel!("Data", xguidefontsize=9)
#         ylabel!("Proportion", yguidefontsize=9)
#         title!("Relative Proportions of Spatial LoT Stages vs. Data Volume", titlefontsize=10)

#     elseif mode == "rank"
#         p = ""
#         for map_estimate_str in map_estimates 
#             println(plot_data[map_estimate_str])
#             println(sums)
#             println(plot_data[map_estimate_str] ./ sums)
#             println()
#             l = filter(x -> x.definition != "", eval(Meta.parse(map_estimate_str)))
#             if l == [] 
#                 l = "geo"
#             else
#                 l = l[end].name
#             end
#             l = legend_names[l]
#             # data = plot_data[map_estimate_str] ./ sums 
#             @show all_results
#             data = map(i -> findall(x -> x == plot_data[map_estimate_str][i], all_results[i])[1], 1:length(plot_data[map_estimate_str]))
        
#             if p == ""
#                 p = plot(collect(0:length(chains)), data, label=l, linewidth=3, legend=:right, xlims = (0,length(chains)), xticks = 0:1:length(chains))
#             else
#                 p = plot!(p, collect(0:length(chains)), data, label=l, linewidth=3, legend=:right, xlims = (0,length(chains)), xticks = 0:1:length(chains))
#             end
#         end

#         xlabel!("Data", xguidefontsize=9)
#         ylabel!("Rank", yguidefontsize=9)
#         title!("Relative Ranks of Spatial LoT Stages vs. Data Volume", titlefontsize=10)
    
#     elseif mode == "correlation_map"

#         age_group_plot_data = Dict(map(x -> x => [0.0], age_groups))
#         names = []
#         for t in 2:length(all_results)
#             m = maximum(all_results[t])
#             model_stage = findall(x -> plot_data[x][t] == m, map_estimates)[1]
#             l = filter(x -> x.definition != "", eval(Meta.parse(map_estimates[model_stage])))
#             if l == [] 
#                 l = "geo"
#             else
#                 l = l[end].name
#             end
#             push!(names, l)
#             for age_group in age_groups 
#                 if length(names) > 1 && names[end - 1] == "my_left"
#                     println("hello")
#                     vals = all_correlation_dicts["my_left_lang"][age_group]
#                 else
#                     vals = all_correlation_dicts[l][age_group]
#                 end
#                 c = round(cor(map(x -> x[1], vals), map(x -> x[2], vals)), digits=3)
#                 # c = c * c
#                 push!(age_group_plot_data[age_group], c)
#             end
#         end

#         p = ""
#         for age_group in age_groups 
#             l = "$(age_group)"
#             data = age_group_plot_data[age_group]
#             if p == ""
#                 p = plot(collect(0:(length(data)- 1)), data, label=age_group_legend_names[age_group], linewidth=3, legend=:topright, xlims = (0,length(data) - 1), xticks = 0:1:(length(data) - 1), ylims=(0, 1.1), yticks = 0:0.1:1)
#             else
#                 p = plot!(p, collect(0:length(chains)), data, label=age_group_legend_names[age_group], linewidth=3, legend=:topright, xlims = (0,length(data) - 1), xticks = 0:1:(length(data) - 1), ylims=(0, 1.1), yticks = 0:0.1:1)
#             end
#         end

#         xlabel!("Data", xguidefontsize=9)
#         ylabel!("R", yguidefontsize=9)
#         title!("Correlation between MAP Spatial LoT Model Predictions\nand Empirical Results vs. Training Data Volume", titlefontsize=10)

#     elseif mode == "correlation_avg"
#         age_group_plot_data = Dict(map(x -> x => [0.0], age_groups))

#         names = []
#         for t in 2:length(all_results)
#             m = maximum(all_results[t])
#             model_stage = findall(x -> plot_data[x][t] == m, map_estimates)[1]
#             l = filter(x -> x.definition != "", eval(Meta.parse(map_estimates[model_stage])))
#             if l == [] 
#                 l = "geo"
#             else
#                 l = l[end].name
#             end
#             push!(names, l)
#         end

#         for t in 2:length(all_results)
#             for age_group in age_groups 
#                 weighted_correlations = []
#                 for map_estimate in keys(plot_data)
                    
#                     l = filter(x -> x.definition != "", eval(Meta.parse(map_estimate)))
#                     if l == [] 
#                         l = "geo"
#                     else
#                         l = l[end].name
#                     end
                    
#                     println(names)
#                     if t > 2 && names[t - 2] == "my_left"
#                         println("hello 1")
#                         if l == "my_left"
#                             println("hello 2")
#                             vals = all_correlation_dicts["my_left_lang"][age_group]
#                             prop = 1.0
#                         else
#                             vals = all_correlation_dicts[l][age_group]
#                             prop = 0.0
#                         end
#                         # prop = plot_data[map_estimate][t - 1] / sums[t - 1]
#                     else
#                         vals = all_correlation_dicts[l][age_group]
#                         prop = plot_data[map_estimate][t] / sums[t]
#                     end

#                     c = round(cor(map(x -> x[1], vals), map(x -> x[2], vals)), digits=3)
#                     # c = c * c
#                     push!(weighted_correlations, c * prop)
#                 end
#                 push!(age_group_plot_data[age_group], sum(weighted_correlations))
#             end 
#         end

#         p = ""
#         for age_group in age_groups 
#             l = "$(age_group)"
#             data = age_group_plot_data[age_group]
#             if p == ""
#                 p = plot(collect(0:(length(data)-1)), data, label=age_group_legend_names[age_group], linewidth=3, legend=:topright, xlims = (0,length(data) - 1), xticks = 0:1:(length(data) - 1), ylims=(0, 1.1), yticks = 0:0.1:1)
#             else
#                 p = plot!(p, collect(0:length(chains)), data, label=age_group_legend_names[age_group], linewidth=3, legend=:topright, xlims = (0,length(data) - 1), xticks = 0:1:(length(data) - 1), ylims=(0, 1.1), yticks = 0:0.1:1)
#             end
#         end

#         xlabel!("Data", xguidefontsize=9)
#         ylabel!("R", yguidefontsize=9)
#         title!("Correlation between Weighted Spatial LoT Model Predictions\nand Empirical Results vs. Training Data Volume", titlefontsize=10)

#     elseif mode == "scatter"
#         p = plot_scatter(all_correlation_dicts)
#     end

#     if save_suffix != ""
#         savefig("$(mode)_$(save_suffix).png")
#     end

#     return p
# end
# trial_name = "trial11_tiny_prior_copy"
# trial_name = "trial13_tinier_prior_tiny_empty_prob"
# trial_name = "trial14_tinier_prior_tiny_empty_prob_REPEAT"
# trial_name = "left_right_run2_repeats_"
trial_name = "left_right_run_LR_uncertainty_repeats_"
# chain_filenames = readdir("metalanguage/results/mcmc/$(trial_name)")
chain_filenames = filter(x -> occursin(trial_name, x) && !occursin("OLD", x) && !occursin("_v", x), readdir("metalanguage/intermediate_outputs/intermediate_chains"))
chain_filenames = sort(chain_filenames, by=x -> parse(Int, replace(split(x, "_")[end], ".txt" => "")))
# chain_filenames = [chain_filenames[1:12]..., chain_filenames[14:15]...]

println(chain_filenames)

chains = []
orig_chains = []
for chain_filename in chain_filenames #[10:10] #[1:10]
    open("metalanguage/intermediate_outputs/intermediate_chains/$(chain_filename)", "r") do f 
        text = read(f, String)
        obj = eval(Meta.parse(text)) #[200:end]

        formatted_obj = deepcopy(obj)
        for x in formatted_obj 
            if occursin("update_alpha(1.0) && location_arg.position.x < 0", repr(x)) && occursin("update_alpha(1.0) && location_arg.position.x > 0", repr(x))
                
                for f in x 
                    f.definition = replace(f.definition, "update_alpha(1.0) && location_arg.position.x < 0" => "location_arg.position.x < 0")
                    f.definition = replace(f.definition, "update_alpha(1.0) && location_arg.position.x > 0" => "location_arg.position.x > 0")
                end

            end
        end
        push!(chains, formatted_obj)
        push!(orig_chains, obj)
    end
end

p = plot_relative_proportions(chains, "proportion", test_config_names, [["left_of", "left_of_opposite"], ["right_of", "right_of_opposite"]], "$(trial_name)_debug")

# p = plot_relative_proportions(chains, "proportion", test_config_names, [], trial_name)
# p = plot_relative_proportions(orig_chains, "proportion", test_config_names, [], trial_name, p)

# p = plot_relative_proportions(chains, "rank", test_config_names, [], trial_name)
# p = plot_relative_proportions(chains, "correlation_map", test_config_names, [], trial_name)
# p = plot_relative_proportions(chains, "correlation_avg", test_config_names, [], trial_name)
# # p = plot_relative_proportions(chains, "scatter", [], trial_name)