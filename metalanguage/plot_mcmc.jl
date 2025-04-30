include("run_unordered_analogy.jl")
using Plots 

function plot_relative_proportions(chains)
    histograms = []
    map_estimates = []
    for chain in chains 
        if length(chain) != length(chains[1])

        else
            q = map(y -> (y, count(z -> repr(z) == y, chain)), unique(map(x -> repr(x), filter(w -> true, chain))))
            q_sorted = reverse(sort(q, by=x -> x[2]))
            push!(histograms, q_sorted)

            map_estimate = q_sorted[1][1]
            println(map_estimate)
            push!(map_estimates, map_estimate)
        end 
    end

    unique!(map_estimates)

    sort!(map_estimates, by=length)
    plot_data = Dict()
    p = ""
    for map_estimate_str in map_estimates 
        plot_data[map_estimate_str] = []
        for histogram in histograms 
            proportions = filter(tup -> tup[1] == map_estimate_str, histogram)
            
            if proportions != []
                proportion = proportions[1][2]
            else
                proportion = 0.0
            end
            
            push!(plot_data[map_estimate_str], proportion)
            
        end
        if p == ""
            p = plot(collect(1:length(chains)), plot_data[map_estimate_str], label=map_estimate_str, linewidth=3)
        else
            p = plot!(p, collect(1:length(chains)), plot_data[map_estimate_str], label=map_estimate_str, linewidth=3)
        end
    end

    return p
end

trial_name = "trial6_extra_data_new_prior_new_sem_space"
chain_filenames = readdir("metalanguage/results/mcmc/$(trial_name)")
chain_filenames = sort(chain_filenames, by=x -> parse(Int, replace(x[7:end], ".txt" => "")))
chains = []
for chain_filename in chain_filenames 
    open("metalanguage/results/mcmc/$(trial_name)/$(chain_filename)", "r") do f 
        text = read(f, String)
        obj = eval(Meta.parse(text))
        push!(chains, obj)
    end
end

p = plot_relative_proportions(chains)
