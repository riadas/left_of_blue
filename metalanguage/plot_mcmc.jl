include("run_unordered_analogy.jl")
include("plot_scatter.jl")
using Plots 

age_groups = [1, 2, 3, 4]
# correlation_dict = Dict()

function plot_relative_proportions(chains, mode="proportion", save_suffix="")
    histograms = []
    map_estimates = []
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
        end 
    end

    unique!(map_estimates)

    sort!(map_estimates, by=length)
    @show map_estimates
    plot_data = Dict()
    p = ""
    sums = zeros(length(chains) + 1)
    sums[1] = 1.0
    all_results = map(x -> [], 1:(length(chains) + 1)) 
    all_results[1] = [0.0, 0.0, 0.0, 1.0]
    for map_estimate_str in map_estimates 
        plot_data[map_estimate_str] = [0.0]
        for i in 1:length(histograms)
            histogram = histograms[i]
            proportions = filter(tup -> tup[1] == map_estimate_str, histogram)
            
            if proportions != []
                proportion = proportions[1][2]
            else
                proportion = 0.0
            end
            
            push!(plot_data[map_estimate_str], proportion)
            sums[i + 1] += proportion
            push!(all_results[i + 1], proportion) 
        end
    end

    for i in 1:length(all_results)
        all_results[i] = sort(all_results[i])
    end

    legend_names = Dict([
        "geo" => "geometric",
        "at" => "associational",
        "my_left" => "intrinsic egocentric",
        "left_of" => "relative egocentric" 
    ])

    age_group_legend_names = Dict([
        1 => "18-24 months",
        2 => "3-4 years", 
        3 => "4-6 years",
        4 => "6+ years",
    ])

    if mode == "proportion"
    
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
            data = plot_data[map_estimate_str] ./ sums 
            # data = map(i -> findall(x -> x == plot_data[map_estimate_str][i], all_results[i])[1], 1:length(plot_data[map_estimate_str]))
            
            if p == ""
                p = plot(collect(0:length(chains)), data, label=l, linewidth=3, legend=:right, xlims = (0,length(chains)), xticks = 0:1:length(chains), ylims=(0, 1.1), yticks = 0:0.1:1)
            else
                p = plot!(p, collect(0:length(chains)), data, label=l, linewidth=3, legend=:right, xlims = (0,length(chains)), xticks = 0:1:length(chains), ylims=(0, 1.1), yticks = 0:0.1:1)
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
                if length(names) > 1 && names[end - 1] == "my_left"
                    println("hello")
                    vals = correlation_dict[("my_left_lang", age_group)]
                else
                    vals = correlation_dict[(l, age_group)]
                end
                c = round(cor(map(x -> x[1], vals), map(x -> x[2], vals)), digits=3)
                c = c * c
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
        ylabel!("R^2", yguidefontsize=9)
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
                    if t > 2 && names[t - 2] == "my_left"
                        println("hello 1")
                        if l == "my_left"
                            println("hello 2")
                            vals = correlation_dict[("my_left_lang", age_group)]
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
                    c = c * c
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
        ylabel!("R^2", yguidefontsize=9)
        title!("Correlation between Weighted Spatial LoT Model Predictions\nand Empirical Results vs. Training Data Volume", titlefontsize=10)

    end

    if save_suffix != ""
        savefig("$(mode)_$(save_suffix).png")
    end

    return p
end
# trial_name = "trial11_tiny_prior_copy"
# trial_name = "trial13_tinier_prior_tiny_empty_prob"
trial_name = "trial14_tinier_prior_tiny_empty_prob_REPEAT"
chain_filenames = readdir("metalanguage/results/mcmc/$(trial_name)")
chain_filenames = sort(chain_filenames, by=x -> parse(Int, replace(x[7:end], ".txt" => "")))
chains = []
for chain_filename in chain_filenames #[1:10]
    open("metalanguage/results/mcmc/$(trial_name)/$(chain_filename)", "r") do f 
        text = read(f, String)
        obj = eval(Meta.parse(text))
        push!(chains, obj)
    end
end

p = plot_relative_proportions(chains, "rank", trial_name)
p = plot_relative_proportions(chains, "proportion", trial_name)
p = plot_relative_proportions(chains, "correlation_map", trial_name)
p = plot_relative_proportions(chains, "correlation_avg", trial_name)