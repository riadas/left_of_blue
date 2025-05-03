include("run_mcmc.jl")

all_function_sigs = [
    at_function, 
    my_left_function_spot, 
    left_of_function, 
    # left_of_opposite_function,
    # my_right_function_spot,
    # right_of_function, 
    # right_of_opposite_function,
]

global repeats = parse(Int, ARGS[1])

possible_semantics = []

for function_sig in all_function_sigs 
    x = generate_all_semantics(function_sig, base_semantics)
    x = ["", x...]
    push!(possible_semantics, x)
end

all_permutations = [Iterators.product(possible_semantics...)...]

println("length(all_permutations)")
println(length(all_permutations))

all_results = []

global max_elt = []
# @show max_elt
for p_idx in 1:length(all_permutations)
    @show p_idx
    p = all_permutations[p_idx]
    # @show max_elt
    for function_sig in all_function_sigs 
        function_sig.definition = ""
    end

    for i in 1:length(p)
        # print(p)
        all_function_sigs[i].definition = p[i]
    end

    # compute prior 
    prior = compute_prior_probability(all_function_sigs)

    # compute likelihood 
    likelihood = compute_likelihood(all_function_sigs, test_config_names, repeats)

    posterior_proxy = prior * likelihood

    result = [p, posterior_proxy]
    # @show max_elt
    if max_elt == []
        global max_elt = result
    elseif posterior_proxy > max_elt[2]
        global max_elt = result
    end

    push!(all_results, result)
end

reverse!(sort!(all_results, by=x -> x[2]))

println(max_elt)

open("metalanguage/posteriors/posterior_$(length(all_function_sigs))_functions_$(repeats)_repeats.txt", "w+") do f 
    write(f, string(all_results))
end

open("metalanguage/posteriors/map_$(length(all_function_sigs))_functions_$(repeats)_repeats.txt", "w+") do f 
    write(f, string(max_elt))
end