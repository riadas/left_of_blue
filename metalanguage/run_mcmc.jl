include("run_unordered_analogy.jl")
using StatsBase 
using Combinatorics
global repeats = 11
global test_name = "mcmc_$(repeats)_new_sem_space_y"
global alpha_num_funcs = 0.000025 # 0.0025, 0.01, 0.5
global alpha_semantics_size = 0.5
global base_semantics_str = ""
global alpha_AST_weight = 10 # 10
global alpha_arg_weight = 2 # 2
global alpha_empty_prob = 0.05 # 0.0001
global alpha_empty_symmetry = 0.4
global alpha_symmetry_over_non_symmetry = 0.95
global first_decision_weights = Dict([
    "edit" => 3,
    "add" => 3, 
    "delete" => 3,
])

open("metalanguage/base_semantics.jl", "r") do f 
    global base_semantics_str = read(f, String)
end

# TODO: add same function name check in proposal/compute_transition_probability

function generative_prior(all_functions_with_sym)
    # group all functions including symmetries by type signature
    type_signature_groups = Dict()
    for f in all_functions_with_sym
        type_signature = repr(f.arg_types)
        if !(type_signature in keys(type_signature_groups))
            type_signature_groups[type_signature] = [f]
        else
            push!(type_signature_groups[type_signature], f)
        end
    end

    all_functions = []
    for k in keys(type_signature_groups)
        fs = sort(type_signature_groups[k], by=x -> x.name)
        if length(fs) > 1
            if rand() < 0.5
                push!(all_functions, fs[1])
            else
                push!(all_functions, fs[end])
            end
            push!(probs, 0.5)
        end
    end

    # if length(all_functions) != length(all_functions_with_sym)
    #     push!(probs, 0.5)
    # end
    

    # generate subset of functions to fill
    total_num_functions = length(all_functions)
    weights = map(x -> alpha_num_funcs^x, 1:total_num_functions)
    weights = weights .* 1/(sum(weights))
    
    probs = []

    if rand() < alpha_empty_prob 
        num_functions = 0
        push!(probs, alpha_empty_prob)
    else
        num_functions = sample(collect(1:total_num_functions), ProbabilityWeights(weights))
        push!(probs, (1 - alpha_empty_prob) * weights[num_functions])
    end
    # @show weights 
    # @show num_functions

    # prefix of length num_functions of all functions
    # functions_to_synth = all_functions[1:num_functions]
    functions_to_synth, prob = sample_function_subset(all_functions, num_functions, "prior")
    push!(probs, prob)

    # synthesize semantics for each
    for func in all_functions 
        if func in functions_to_synth 
            func, prob = sample_semantics(func, base_semantics) # samples a function def., and also returns the probability of choosing that def. 
            push!(probs, prob)
        end
    end

    # now handle symmetric functions (excluded in all_functions but included in symmetric functions)

    sym_count = 0
    acc_count = 0
    for f in all_functions_with_sym 
        if !(f in all_functions)
            type_signature = repr(f.arg_types)
            sym_fs = filter(x -> x != f, type_signature_groups[type_signature])
            if sym_fs != [] && sym_fs[1].definition != ""
                acc_count += 1
                filled_f, prob = sample_semantics(f, base_semantics, "prior", sym_fs[1].definition)
                push!(probs, prob)
                if filled_f.definition != ""
                    sym_count += 1
                end
            end
        end
    end

    # println(probs)
    final_prob = foldl(*, probs, init=1.0)

    # if length(all_functions) < length(all_functions_with_sym) && sym_count == acc_count
    #    final_prob = final_prob * 2
    # end
    for k in keys(type_signature_groups)
        fs = type_signature_groups[k]
        if length(fs) > 1
            both_empty = fs[1].definition == "" && fs[2].definition == ""
            both_filled = fs[1].definition != "" && fs[2].definition != ""
            if both_empty || both_filled 
                final_prob = final_prob * 2
            end
        end
    end

    return all_functions, final_prob
end

function compute_prior_probability(all_functions_with_sym)
    probs = []

    # group all functions including symmetries by type signature
    type_signature_groups = Dict()
    for f in all_functions_with_sym
        type_signature = repr(f.arg_types)
        if !(type_signature in keys(type_signature_groups))
            type_signature_groups[type_signature] = [f]
        else
            push!(type_signature_groups[type_signature], f)
        end
    end

    all_functions = []
    first_pairs = []
    second_pairs = []
    for k in keys(type_signature_groups)
        fs = reverse(sort(type_signature_groups[k], by=x -> length(x.definition)))
        if length(fs) > 1
            push!(first_pairs, fs[1])
            push!(second_pairs, fs[2])
        else 
            push!(all_functions, fs[1])
        end
    end

    synthesized_first_pairs = filter(x -> x.definition != "", first_pairs)
    synthesized_second_pairs = filter(x -> x.definition != "", second_pairs)
    if length(synthesized_first_pairs) >= length(synthesized_second_pairs)
        push!(all_functions, first_pairs...)
        other_pairs = second_pairs
        chosen_pairs = first_pairs
    else
        push!(all_functions, second_pairs...)
        other_pairs = first_pairs
        chosen_pairs = second_pairs
    end

    # if length(all_functions) != length(all_functions_with_sym)
    #     push!(probs, 0.5)
    # end

    push!(probs, 0.5^(length(first_pairs)))

    synthesized_funcs = filter(x -> x.definition != "", all_functions)
    num_synthesized_funcs = length(synthesized_funcs)

    if num_synthesized_funcs == 0 
        push!(probs, alpha_empty_prob)
    else
        weights = map(x -> alpha_num_funcs^x, 1:length(all_functions))
        num_funcs_prob = (1 - alpha_empty_prob) * alpha_num_funcs^num_synthesized_funcs / sum(weights)
        push!(probs, num_funcs_prob)
    end

    prob = compute_function_subset_prob(all_functions)
    push!(probs, prob)

    for func in synthesized_funcs 
        _, prob = sample_semantics(func, base_semantics) # computes probability of choosing the current function definition
        push!(probs, prob)
    end

    # TODO: handle 'compressability' aspect of prior
    if length(all_functions) < length(all_functions_with_sym)
        for i in 1:length(other_pairs)
            chosen_func = chosen_pairs[i]
            sym_func = other_pairs[i] 
            if chosen_func.definition != ""
                if sym_func.definition == ""
                    old_definition = sym_func.definition
                    sym_func.definition = "done"
                    filled_f, prob = sample_semantics(sym_func, base_semantics, "prior", chosen_func.definition)    
                    sym_func.definition = old_definition
                else
                    filled_f, prob = sample_semantics(sym_func, base_semantics, "prior", chosen_func.definition)
                end
                push!(probs, prob)
            end
        end
    end

    final_prob = foldl(*, probs, init=1.0)
    # if length(all_functions) < length(all_functions_with_sym) && length(synthesized_first_pairs) == length(synthesized_second_pairs)
    #     final_prob = final_prob * 2
    # end

    for k in keys(type_signature_groups)
        fs = type_signature_groups[k]
        if length(fs) > 1
            both_empty = fs[1].definition == "" && fs[2].definition == ""
            both_filled = fs[1].definition != "" && fs[2].definition != ""
            if both_empty || both_filled 
                final_prob = final_prob * 2
            end
        end
    end

    # println(probs)
    return final_prob
end

function sample_function_subset(all_functions, subset_size, mode="prior")
    weights = compute_function_subset_weight_scores(all_functions, mode)
    subset = []
    probs = []
    funcs = all_functions
    for i in 1:subset_size

        normalized_weights = weights .* 1/sum(weights)
        # println("sample_function_subset")
        # @show normalized_weights
        f = sample(funcs, ProbabilityWeights(normalized_weights))
        push!(subset, f)

        index = findall(x -> x == f, funcs)[1]
        # @show index
        funcs = vcat(funcs[1:index - 1], funcs[index+1:end])
        weights = vcat(weights[1:index - 1], weights[index+1:end])
        push!(probs, normalized_weights[index])
    end

    all_functions_copy = deepcopy(all_functions)
    for i in 1:length(all_functions)
        if all_functions[i] in subset 
            all_functions_copy[i].definition = "true"
        else
            all_functions_copy[i].definition = ""
        end
    end

    final_prob = compute_function_subset_prob(all_functions_copy, mode)
    return subset, final_prob
end

function compute_function_subset_prob(all_functions, mode="prior")
    # println("compute_function_subset_prob")
    synthesized_funcs = filter(x -> x.definition != "", all_functions)
    final_probs = []
    for synth_funcs in collect(permutations(synthesized_funcs))
        @show synth_funcs
        weights = compute_function_subset_weight_scores(all_functions, mode)
        @show weights
        funcs = all_functions
        probs = []
        for i in 1:length(synth_funcs)
            f = synth_funcs[i]
            normalized_weights = weights .* 1/sum(weights)
            # @show normalized_weights
            index = findall(x -> x == f, funcs)[1]
            # @show index
            push!(probs, normalized_weights[index])
    
            funcs = filter(x -> x != f, funcs)
            weights = vcat(weights[1:index - 1], weights[index+1:end])
        end
        final_prob = foldl(*, probs, init=1.0)
        push!(final_probs, final_prob)
    end

    final_prob = foldl(+, final_probs, init=0.0)
    return final_prob
end

function compute_function_subset_weight_scores(all_functions, mode="prior")
    min_possible_AST_size_dict = Dict(map(x -> format_new_function_string(x) => size(Meta.parse(generate_all_semantics(x, base_semantics)[1])), all_functions))
    weight_scores = Dict()
    for func in all_functions 
        # @show func 
        min_possible_AST_size = min_possible_AST_size_dict[format_new_function_string(func)]
        # @show min_possible_AST_size 
        num_args = length(func.arg_names)
        # @show num_args
        if mode == "prior"
            weight_score = min_possible_AST_size*alpha_AST_weight + num_args * alpha_arg_weight
        else
            weight_score = 1
        end
        # weight_score = min_possible_AST_size^alpha_AST_weight + num_args
        # @show weight_score
        # weight_scores[format_new_function_string(func)] = 1/weight_score
        weight_scores[format_new_function_string(func)] = weight_score

    end
    weights = map(x -> weight_scores[format_new_function_string(x)], all_functions)
    weights = weights .- minimum(weights) .+ 1
    weights = map(x -> 1/x, weights)
    # println("final weights")
    # @show weights
    return weights .* 1/sum(weights)
end

function sample_semantics(function_sig, base_semantics, mode="prior", context="", remove_sym="")
    possible_semantics = generate_all_semantics(function_sig, base_semantics)
    if remove_sym != "" 
        possible_semantics = filter(x -> x != remove_sym, possible_semantics)
    end
    # @show possible_semantics

    # sample from set of possible semantics, biasing shorter semantics
    if context == ""
        if mode == "prior"
            alpha = alpha_semantics_size        
        elseif mode == "proposal"
            alpha = 1.0
        end
        semantics_weights = map(x -> alpha^size(Meta.parse(possible_semantics[x])), 1:length(possible_semantics)) # alpha^x
        semantics_weights = semantics_weights .* 1/sum(semantics_weights)
        if function_sig.definition == ""
            final_semantics = sample(possible_semantics, ProbabilityWeights(semantics_weights))
            function_sig.definition = final_semantics
        end

        index = findall(x -> x == function_sig.definition, possible_semantics)[1]

        # println("SEMANTICS_WEIGHTS")
        # println(possible_semantics)
        # println(semantics_weights)
        # println(index)

        prob = semantics_weights[index] 
        println(function_sig.definition)
        return (function_sig, prob)
    else
        # generate symmetric version
        symmetries = [
            ["next", "prev"],
            ["<", ">"],
            ["wall1", "wall2"]
        ]
        symmetric_definition = context
        for pair in symmetries 
            symmetric_definition = symmetric_replace(symmetric_definition, pair)
        end

        if function_sig.definition == ""
            # generate and compute associated probability
            if symmetric_definition == context || !(symmetric_definition in possible_semantics)
                if rand() < alpha_empty_symmetry 
                    return (function_sig, alpha_empty_symmetry)
                else
                    function_sig, prob = sample_semantics(function_sig, base_semantics, mode)
                    return (function_sig, prob * (1 - alpha_empty_symmetry))
                end
            else # symmetric definition exists in possible_semantics
                if rand() < alpha_empty_symmetry 
                    return (function_sig, alpha_empty_symmetry)
                else
                    if rand() < alpha_symmetry_over_non_symmetry
                        function_sig.definition = symmetric_definition 
                        return (function_sig, (1 - alpha_empty_symmetry) * alpha_symmetry_over_non_symmetry)
                    else
                        function_sig, prob = sample_semantics(function_sig, base_semantics, mode, "", symmetric_definition)
                        return (function_sig, (1 - alpha_empty_symmetry) * (1 - alpha_symmetry_over_non_symmetry) * prob)
                    end
                end
            end
        else
            # compute probability of existing definition
            if function_sig.definition == "done" # unfilled
                return (function_sig, alpha_empty_symmetry)
            elseif symmetric_definition == context || !(symmetric_definition in possible_semantics)
                function_sig, prob = sample_semantics(function_sig, base_semantics, mode)
                return (function_sig, prob * (1 - alpha_empty_symmetry))
            elseif function_sig.definition == symmetric_definition 
                return (function_sig, (1 - alpha_empty_symmetry) * alpha_symmetry_over_non_symmetry)
            else # filled with a non-symmetric definition
                function_sig, prob = sample_semantics(function_sig, base_semantics, mode, "", symmetric_definition)
                return (function_sig, (1 - alpha_empty_symmetry) * (1 - alpha_symmetry_over_non_symmetry) * prob)
            end

        end

    end
end

function symmetric_replace(definition, pair)
    new_definition = definition
    if occursin(pair[1], definition)
        new_definition = replace(new_definition, pair[1] => pair[2])        
    elseif occursin(pair[2], definition) 
        new_definition = replace(new_definition, pair[2] => pair[1])
    end
    new_definition
end

function generate_all_semantics(function_sig, base_semantics)
    possible_semantics = []
    for i in 1:1000
        semantics = generate_semantics(function_sig, base_semantics)
        push!(possible_semantics, semantics)
    end
    possible_semantics = unique(possible_semantics)
    # # println(possible_semantics)

    # exclude function definitions that don't use all of the input arguments
    possible_semantics = filter(x -> foldl(&, map(a -> occursin(a, x), function_sig.arg_names), init=true), possible_semantics)

    possible_semantics = filter(x -> !occursin("0 <", x) && !occursin("1 <", x) && !occursin("1 >", x) && !occursin("0 >", x), possible_semantics)

    possible_semantics = sort(possible_semantics, by=x -> size(Meta.parse(x)))
    size_dict = Dict()
    for s in possible_semantics 
        k = size(Meta.parse(s))
        if !(k in keys(size_dict))
            size_dict[k] = [s]
        else
            push!(size_dict[k], s)
        end
    end
    sizes = sort([keys(size_dict)...])
    possible_semantics = vcat(map(k -> sort(size_dict[k]), sizes)...)

    return possible_semantics
end

function compute_likelihood(all_functions, test_config_names, repeats=1)
    # update syntax
    synthesized_funcs = filter(x -> x.definition != "", all_functions)
    updated_syntax = deepcopy(base_syntax)

    for function_sig in synthesized_funcs 
        updated_syntax = update_syntax_cfg(updated_syntax, function_sig)
    end

    # update semantics.jl file
    function_definition_strs = map(x -> format_new_function_string(x), synthesized_funcs)

    # update semantics.jl file with new function and import file
    new_semantics_str = join([base_semantics_str, function_definition_strs...], "\n")

    # then run evaluate_semantics with the set of test_config_names (subset of all config_names)
    total_score, scores, search_locations, temp_semantics = evaluate_semantics(nothing, "", 0, new_semantics_str, updated_syntax, 0, all_function_sigs, test_config_names, test_name)

    # return product of probabilities in the `scores` dict
    probs = map(k -> scores[k], [keys(scores)...])
    println("COMPUTE LIKELIHOOD")
    @show probs
    println(join(function_definition_strs, "\n"))
    println("END COMPUTE LIKELIHOOD")
    return foldl(*, probs, init=1.0)^repeats
end

function proposal(current_state)
    old_functions = deepcopy(current_state) 
    synthesized_old_functions = filter(x -> x.definition != "", old_functions)
    probs = []

    if length(synthesized_old_functions) == length(old_functions)
        # all functions are filled: edit or delete 
        weights_dict = deepcopy(first_decision_weights)
        weights = [
            first_decision_weights["edit"],
            first_decision_weights["delete"]
        ]
        weights = weights .* 1/sum(weights)

        first_choice = sample(["edit", "delete"], ProbabilityWeights(weights))
        push!(probs, weights[findall(x -> x == first_choice, ["edit", "delete"])[1]])
        if first_choice == "edit"
            subset, prob = sample_function_subset(old_functions, 1, "proposal")
            println("starting from full: EDIT")
            println(subset[1])
            push!(probs, prob)
            subset[1].definition = ""
            _, prob = sample_semantics(subset[1], base_semantics, "proposal")
            push!(probs, prob)
        else # delete
            subset, prob = sample_function_subset(old_functions, 1, "proposal")
            println("starting from full: DELETE")
            println(subset[1])
            subset[1].definition = ""
            push!(probs, prob)
        end

    elseif length(synthesized_old_functions) == 0
        # no functions are filled: must choose one to initialize
        subset, _ = sample_function_subset(old_functions, 1, "proposal")
        println("starting from zero: ADD")
        println(subset[1])
        _, prob = sample_semantics(subset[1], base_semantics, "proposal")
        push!(probs, prob)
    else
        # all three options (add, edit, delete)
        weights = [
            first_decision_weights["edit"],
            first_decision_weights["delete"],
            first_decision_weights["add"]
        ]
        weights = weights .* 1/sum(weights)

        first_choice = sample(["edit", "delete", "add"], ProbabilityWeights(weights))
        push!(probs, weights[findall(x -> x == first_choice, ["edit", "delete", "add"])[1]])

        if first_choice == "edit"
            subset, prob = sample_function_subset(filter(x -> x.definition != "", old_functions), 1, "proposal")
            println("EDIT")
            println(subset[1])
            push!(probs, prob)
            subset[1].definition = ""
            x, prob = sample_semantics(subset[1], base_semantics, "proposal")
            println("SAMPLED DEFINITION")
            println(x)
            push!(probs, prob)

        elseif first_choice == "delete"
            subset, prob = sample_function_subset(filter(x -> x.definition != "", old_functions), 1, "proposal")
            println("DELETE")
            println(subset[1])
            subset[1].definition = ""
            push!(probs, prob)
        elseif first_choice == "add"
            subset, prob = sample_function_subset(filter(x -> x.definition == "", old_functions), 1, "proposal")
            println("ADD")
            println(subset[1])
            push!(probs, prob)
            _, prob = sample_semantics(subset[1], base_semantics, "proposal")
            push!(probs, prob)
        end
    end

    final_prob = foldl(*, probs, init=1.0)
    # return proposal ratio
    return (old_functions, final_prob)
end

# for computing the backwards probability
function compute_transition_probability(current_state, proposed_state)
    old_functions = deepcopy(current_state)
    synthesized_old_functions = filter(x -> x.definition != "", old_functions)

    new_functions = deepcopy(proposed_state) 
    synthesized_new_functions = filter(x -> x.definition != "", new_functions)    

    probs = []

    if length(synthesized_old_functions) == length(old_functions)
        # all functions are filled: edit or delete 
        weights_dict = deepcopy(first_decision_weights)
        weights = [
            first_decision_weights["edit"],
            first_decision_weights["delete"]
        ]
        weights = weights .* 1/sum(weights)

        if length(synthesized_old_functions) == length(synthesized_new_functions)
            # edit 
            push!(probs, weights[1])
            changed_func_idx = nothing 
            for i in 1:length(old_functions)
                old_f = old_functions[i]
                new_f = new_functions[i]
                if old_f.name == new_f.name && old_f.definition != new_f.definition 
                    changed_func_idx = i
                    break
                end
            end

            if !isnothing(changed_func_idx)


                all_functions = deepcopy(proposed_state)
                for i in 1:length(all_functions)
                    if i != changed_func_idx
                        all_functions[i].definition = ""
                    end
                end

                prob = compute_function_subset_prob(all_functions, "proposal")
                push!(probs, prob)

                _, prob = sample_semantics(all_functions[changed_func_idx], base_semantics, "proposal")
                push!(probs, prob)
            else
                probs_to_sum = []
                all_functions = []
                current_state_copy = deepcopy(current_state)
                for i in 1:length(current_state_copy)
                    f = current_state_copy[i]
                    if f.definition != ""
                        push!(all_functions, f)
                    end                
                end

                for i in 1:length(all_functions) 
                    all_functions_copy = deepcopy(all_functions)
                    for j in 1:length(all_functions_copy)
                        if i != j 
                            all_functions_copy[j].definition = ""
                        end
                    end

                    prob1 = compute_function_subset_prob(all_functions_copy, "proposal")
                    _, prob2 = sample_semantics(all_functions_copy[i], base_semantics, "proposal")

                    push!(probs_to_sum, prob1*prob2)
                end
                prob = sum(probs_to_sum)
                push!(probs, prob)

            end
        else
            # delete
            push!(probs, weights[2])

            deleted_func_idx = nothing 
            for i in 1:length(old_functions)
                old_f = old_functions[i]
                new_f = new_functions[i]
                if old_f.name == new_f.name && old_f.definition != "" && new_f.definition == "" 
                    deleted_func_idx = i
                    break
                end
            end

            all_functions = deepcopy(current_state)
            for i in 1:length(all_functions)
                f = all_functions[i]
                if i != deleted_func_idx
                    f.definition = ""
                end
            end

            prob = compute_function_subset_prob(all_functions, "proposal")
            push!(probs, prob)
        end

    elseif length(synthesized_old_functions) == 0
        # no functions are filled: must choose one to initialize
        prob = compute_function_subset_prob(new_functions, "proposal")
        push!(probs, prob)
        func = filter(x -> x != "", new_functions)[1]
        _, prob = sample_semantics(func, base_semantics, "proposal")
        push!(probs, prob)
    else

        weights = [
            first_decision_weights["edit"],
            first_decision_weights["delete"],
            first_decision_weights["add"]
        ]
        weights = weights .* 1/sum(weights)

        if length(synthesized_old_functions) == length(synthesized_new_functions)
            # edit
            push!(probs, weights[1])
            edited_func_idx = nothing 
            for i in 1:length(old_functions)
                old_f = old_functions[i]
                new_f = new_functions[i]
                if old_f.name == new_f.name && old_f.definition != new_f.definition 
                    edited_func_idx = i
                    break
                end
            end

            if !isnothing(edited_func_idx)
                all_functions = []
                current_state_copy = deepcopy(current_state)
                for i in 1:length(current_state_copy)
                    f = current_state_copy[i]
                    if f.definition != ""
                        if i != edited_func_idx
                            f.definition = ""
                        end
                        push!(all_functions, f)
                    end                
                end

                prob = compute_function_subset_prob(all_functions, "proposal")
                push!(probs, prob)
    
                _, prob = sample_semantics(new_functions[edited_func_idx], base_semantics, "proposal")
                push!(probs, prob)

            else
                probs_to_sum = []
                all_functions = []
                current_state_copy = deepcopy(current_state)
                for i in 1:length(current_state_copy)
                    f = current_state_copy[i]
                    if f.definition != ""
                        push!(all_functions, f)
                    end                
                end

                for i in 1:length(all_functions) 
                    all_functions_copy = deepcopy(all_functions)
                    for j in 1:length(all_functions_copy)
                        if i != j 
                            all_functions_copy[j].definition = ""
                        end
                    end

                    prob1 = compute_function_subset_prob(all_functions_copy, "proposal")
                    _, prob2 = sample_semantics(all_functions_copy[i], base_semantics, "proposal")

                    push!(probs_to_sum, prob1*prob2)
                end
                prob = sum(probs_to_sum)
                push!(probs, prob)
            end


        elseif length(synthesized_old_functions) < length(synthesized_new_functions)
            # add
            push!(probs, weights[3])
            added_func_idx = nothing 
            for i in 1:length(old_functions)
                old_f = old_functions[i]
                new_f = new_functions[i]
                if old_f.name == new_f.name && old_f.definition == "" && new_f.definition != "" 
                    added_func_idx = i
                    break
                end
            end

            all_functions = []
            proposed_state_copy = deepcopy(proposed_state)
            for i in 1:length(proposed_state_copy)
                f = proposed_state_copy[i]
                if f.definition == ""
                    push!(all_functions, f)
                end

                if i == added_func_idx
                    push!(all_functions, f)
                end
            end

            prob = compute_function_subset_prob(all_functions, "proposal")
            push!(probs, prob)

            _, prob = sample_semantics(new_functions[added_func_idx], base_semantics, "proposal")
            push!(probs, prob)
        else
            # delete
            push!(probs, weights[2])
            deleted_func_idx = nothing 
            for i in 1:length(old_functions)
                old_f = old_functions[i]
                new_f = new_functions[i]
                if old_f.name == new_f.name && old_f.definition != "" && new_f.definition == "" 
                    deleted_func_idx = i
                    break
                end
            end

            all_functions = []
            current_state_copy = deepcopy(current_state)
            for i in 1:length(current_state_copy)
                f = current_state_copy[i]
                if f.definition != ""
                    if i != deleted_func_idx
                        f.definition = ""
                    end
                    push!(all_functions, f)
                end                
            end

            prob = compute_function_subset_prob(all_functions, "proposal")
            push!(probs, prob)
        end
    end

    final_prob = foldl(*, probs, init=1.0)
    # return proposal ratio
    return final_prob
end

function compute_acceptance_probability(current_state, proposed_state, test_config_names, repeats=1)
    println("CURRENT STATE FUNCTIONS 1")
    println(join(map(x -> x.definition, current_state), "\n"))

    println("PROPOSED STATE FUNCTIONS 1")
    println(join(map(x -> x.definition, proposed_state), "\n"))

    current_prior = compute_prior_probability(current_state)
    current_likelihood = compute_likelihood(current_state, test_config_names, repeats)

    proposed_prior = compute_prior_probability(proposed_state)
    proposed_likelihood = compute_likelihood(proposed_state, test_config_names, repeats)

    ratio_numerator = compute_transition_probability(proposed_state, current_state) 
    ratio_denominator = compute_transition_probability(current_state, proposed_state)
    proposal_ratio = ratio_numerator / ratio_denominator

    acceptance_ratio = minimum([1.0, (proposed_prior * proposed_likelihood)/(current_prior * current_likelihood) * proposal_ratio])

    println("CURRENT STATE FUNCTIONS 2")
    println(join(map(x -> x.definition, current_state), "\n"))

    println("PROPOSED STATE FUNCTIONS 2")
    println(join(map(x -> x.definition, proposed_state), "\n"))

    @show current_prior 
    @show current_likelihood 
    @show ratio_numerator 
    @show proposed_prior 
    @show proposed_likelihood 
    @show ratio_denominator
    @show acceptance_ratio
    return acceptance_ratio
end

function run_mcmc(initial_state, test_config_names=[], iters=1000, repeats=1, intermediate_save_name="", test_name="", init=false)
    if test_name != ""
        global test_name = test_name
    end
    chain = nothing
    if init || intermediate_save_name == ""
        chain = [initial_state]
        current_state = initial_state 
    else
        open("metalanguage/intermediate_outputs/intermediate_chains/$(intermediate_save_name)", "r") do f 
            text = read(f, String)
            chain = eval(Meta.parse(text))
        end
        current_state = chain[end]
    end

    for i in 1:iters
        println("ITER $(i)")
        proposed_state, _ = proposal(current_state)
        println(current_state)
        println(proposed_state)
        acceptance_probability = compute_acceptance_probability(current_state, proposed_state, test_config_names, repeats)
        if rand() < acceptance_probability 
            # accept!
            println("----- ACCEPT!")
            current_state = proposed_state 
        end
        push!(chain, deepcopy(current_state))
    end
    chain
end

at_function = Function("at", ["location_arg", "color_arg"], [Wall, COLOR], "")
at_function_special_corner = Function("at", ["location_special_arg", "color_arg"], [SpecialCorner, COLOR], "")

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

left_of_function_with_depth = Function("left_of", ["location_arg", "color_arg", "depth_arg"], [Corner, COLOR, DEPTH], "")
right_of_function_with_depth = Function("right_of", ["location_arg", "color_arg", "depth_arg"], [Corner, COLOR, DEPTH], "")

left_of_opposite_function = Function("left_of", ["location_arg", "color1_arg", "color2_arg"], [Corner, COLOR, COLOR], "")
right_of_opposite_function = Function("right_of", ["location_arg", "color1_arg", "color2_arg"], [Corner, COLOR, COLOR], "")

all_function_sigs = [at_function, my_left_function_spot, left_of_function, my_right_function_spot, right_of_function] # left_of_opposite_function

# new_function_sigs, prob1 = generative_prior(all_function_sigs)
# # at_function.definition = "location_arg.color == color_arg"
# # println(new_function_sigs)
# # println(join(map(x -> format_new_function_string(x), new_function_sigs), "\n"))
# prob2 = compute_prior_probability(all_function_sigs)
# # println(prob1)
# # println(prob2)

# test_config_names = ["rect_room_blue_wall_center_prize.json",  "spatial_lang_test_left_true_shift_0.json", "rect_room_blue_wall_left_prize.json"]
test_config_names = [
    "square_room_blue_wall_center_prize.json",
    "square_room_blue_wall_center_prize_copy1.json",
    "square_room_blue_wall_center_prize_copy2.json",  
    "square_room_blue_wall_center_prize_copy3.json",  
    "spatial_lang_test_left_true_shift_0.json", 
    "spatial_lang_test_copy_left_true_shift_0.json", 
    "spatial_lang_test_copy2_left_true_shift_0.json", 
    "square_room_blue_wall_left_prize.json",
    # "square_room_blue_wall_far-left-corner_prize.json"
]

# chain = run_mcmc(all_function_sigs, test_config_names, 500, repeats)

# println("PRIOR ONE")
# println(compute_prior_probability(all_function_sigs))

# println("LIKELIHOOD ONE")
# println(compute_likelihood(all_function_sigs, test_config_names, 1))

# println("PRIOR TWO")
# all_function_sigs[1].definition = "location_arg.color == color_arg"
# println(compute_prior_probability(all_function_sigs))
# println("LIKELIHOOD TWO")
# println(compute_likelihood(all_function_sigs, test_config_names, 1))
# all_function_sigs = eval(Meta.parse("Function[Function(\"at\", [\"location_arg\", \"color_arg\"], DataType[Wall, COLOR], \"location_arg.color == color_arg\"), Function(\"my_left\", [\"location_arg\"], DataType[Spot], \"location_arg.position.x < 0\"), Function(\"left_of\", [\"location_arg\", \"color_arg\"], DataType[Corner, COLOR], \"location_arg.wall2.color == color_arg\"), Function(\"my_right\", [\"location_arg\"], DataType[Spot], \"location_arg.position.x > 0\"), Function(\"right_of\", [\"location1_arg\", \"location2_arg\"], DataType[Spot, Spot], \"\")]"))

# at_function.definition = "location_arg.color == color_arg"
# my_left_function_spot.definition = "location_arg.position.x < 0"
# right_of_function.definition = "next(location_arg, locations).color == color_arg"
# all_function_sigs = [at_function, my_left_function_spot, left_of_function, my_right_function_spot, right_of_function] # left_of_opposite_function

# current_state = deepcopy(all_function_sigs)
# left_of_function.definition = "prev(location_arg, locations).color == color_arg"
# proposed_state = deepcopy(all_function_sigs)

# println("----- PRIOR")
# println(compute_prior_probability(all_function_sigs))
# println("----- LIKELIHOOD")
# println(compute_likelihood(all_function_sigs, test_config_names))

# println("----- ACCEPTANCE PROBABILITY")
# println(compute_acceptance_probability(current_state, proposed_state, test_config_names))

# println("----- ACCEPTANCE PROBABILITY REVERSE")
# println(compute_acceptance_probability(proposed_state, current_state, test_config_names))
