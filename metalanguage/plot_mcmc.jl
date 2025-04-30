include("run_unordered_analogy.jl")
include("plot_scatter.jl")
using Plots 

age_groups = [1, 2, 3, 4]
# correlation_dict = Dict()

function plot_relative_proportions(chains, mode="proportion")
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
    println(map_estimates)
    plot_data = Dict()
    p = ""
    sums = zeros(length(chains) + 1)
    sums[1] = 1.0
    all_results = map(x -> [0.0], 1:(length(chains) + 1)) 
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
        "geo" => "geocentric",
        "at" => "associational",
        "my_left" => "intrinsic egocentric",
        "left_of" => "relative egocentric" 
    ])

    if mode == "proportion"

        p = plot(collect(0:length(chains)), [1.0, zeros(length(chains))...], label="geometric", linewidth=3, legend=:right, xlims = (0,length(chains)), xticks = 0:1:length(chains), ylims=(0, 1.1), yticks = 0:0.1:1)
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
            p = plot!(p, collect(0:length(chains)), data, label=l, linewidth=3)
        end

        xlabel!("Data", xguidefontsize=9)
        ylabel!("Proportion", yguidefontsize=9)
        title!("Relative Proportions of Spatial LoT Stages vs. Data Volume", titlefontsize=10)

    elseif mode == "rank"

        p = plot(collect(0:length(chains)), [4.0, ones(length(chains))...], label="geometric", linewidth=3, legend=:right, xlims = (0,length(chains)), xticks = 0:1:length(chains))
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
            data = map(i -> findall(x -> x == plot_data[map_estimate_str][i], all_results[i])[1], 1:length(plot_data[map_estimate_str]))
            p = plot!(p, collect(0:length(chains)), data, label=l, linewidth=3)
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
                push!(age_group_plot_data[age_group], c)
            end
        end

        p = ""
        for age_group in age_groups 
            l = "$(age_group)"
            data = age_group_plot_data[age_group]
            if p == ""
                p = plot(collect(0:(length(data)- 1)), data, label=age_group, linewidth=3, legend=:right, xlims = (0,length(data) - 1), xticks = 0:1:(length(data) - 1), ylims=(0, 1.1), yticks = 0:0.1:1)
            else
                p = plot!(p, collect(0:length(chains)), data, label=age_group, linewidth=3, legend=:right, xlims = (0,length(data) - 1), xticks = 0:1:(length(data) - 1), ylims=(0, 1.1), yticks = 0:0.1:1)
            end
        end

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
                    prop = plot_data[map_estimate][t] / sums[t]
                    
                    l = filter(x -> x.definition != "", eval(Meta.parse(map_estimate)))
                    if l == [] 
                        l = "geo"
                    else
                        l = l[end].name
                    end
    
                    if length(names) > 1 && names[end - 1] == "my_left"
                        println("hello 2")
                        vals = correlation_dict[("my_left_lang", age_group)]
                    else
                        vals = correlation_dict[(l, age_group)]
                    end

                    c = round(cor(map(x -> x[1], vals), map(x -> x[2], vals)), digits=3)
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
                p = plot(collect(0:(length(data)-1)), data, label=age_group, linewidth=3, legend=:right, xlims = (0,length(data) - 1), xticks = 0:1:(length(data) - 1), ylims=(0, 1.1), yticks = 0:0.1:1)
            else
                p = plot!(p, collect(0:length(chains)), data, label=age_group, linewidth=3, legend=:right, xlims = (0,length(data) - 1), xticks = 0:1:(length(data) - 1), ylims=(0, 1.1), yticks = 0:0.1:1)
            end
        end

    end

    savefig("$(mode).png")

    return p
end
# trial_name = "trial11_tiny_prior_copy"
trial_name = "trial11_tiny_prior_copy"
chain_filenames = readdir("metalanguage/results/mcmc/$(trial_name)")
chain_filenames = sort(chain_filenames, by=x -> parse(Int, replace(x[7:end], ".txt" => "")))
chains = []
for chain_filename in chain_filenames[1:end]
    open("metalanguage/results/mcmc/$(trial_name)/$(chain_filename)", "r") do f 
        text = read(f, String)
        obj = eval(Meta.parse(text))
        push!(chains, obj)
    end
end

p = plot_relative_proportions(chains, "rank")
p = plot_relative_proportions(chains, "proportion")
p = plot_relative_proportions(chains, "correlation_map")
p = plot_relative_proportions(chains, "correlation_avg")