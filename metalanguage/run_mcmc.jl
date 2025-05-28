include("run_unordered_analogy.jl")
using StatsBase 
using Combinatorics
global repeats = 5
global test_name = "mcmc_$(repeats)_new_sem_space_z"
global alpha_num_funcs = 0.0000025 # 0.0000015, 0.0025, 0.01, 0.5 # global alpha_num_funcs = 0.0000015 # 0.0000015, 0.0025, 0.01, 0.5
global alpha_semantics_size = 0.1
global base_semantics_str = ""
global alpha_AST_weight = 8 # 10
global alpha_arg_weight = 6 # 3
global alpha_name_length = 5
global alpha_empty_prob = 0.99999995 # 0.99995 # 0.0001
global alpha_empty_symmetry = 0.4
global alpha_symmetry_over_non_symmetry = 0.999999 # 0.95
global alpha_LR_uncertainty_bias = (0.5)^(5 * 7.5)
global alpha_double_delete = 0.5
global first_decision_weights = Dict([
    "edit" => 3,
    "add" => 3, 
    "delete" => 3,
])

# no "y" setting with four func's
# global alpha_num_funcs = 0.00000100 # 0.0000015, 0.0025, 0.01, 0.5 # global alpha_num_funcs = 0.0000015 # 0.0000015, 0.0025, 0.01, 0.5
# global alpha_semantics_size = 0.4

# "y" setting with four func's -- left_of/left_of_opposite come online at the same time
# global alpha_num_funcs = 0.00000200 # 0.0000015, 0.0025, 0.01, 0.5 # global alpha_num_funcs = 0.0000015 # 0.0000015, 0.0025, 0.01, 0.5
# global alpha_semantics_size = 0.1

open("metalanguage/base_semantics.jl", "r") do f 
    global base_semantics_str = read(f, String)
end

# TODO: add same function name check in proposal/compute_transition_probability

function generative_prior(all_functions_with_sym)
    # group all functions including symmetries by type signature
    type_signature_groups = Dict()
    for f in all_functions_with_sym
        type_signature = repr([f.arg_names..., f.arg_types...])

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
            type_signature = repr([f.arg_names..., f.arg_types...])
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
    @show all_functions_with_sym
    probs = []

    # group all functions including symmetries by type signature
    type_signature_groups = Dict()
    for f in all_functions_with_sym
        type_signature = repr([f.arg_names..., f.arg_types...])
        if !(type_signature in keys(type_signature_groups))
            type_signature_groups[type_signature] = [f]
        else
            push!(type_signature_groups[type_signature], f)
        end
    end

    all_functions = []
    first_pairs = []
    second_pairs = []
    for k in sort([keys(type_signature_groups)...], by=x -> findall(y -> repr([y.arg_names..., y.arg_types...]) == x,  all_function_sigs)[1])
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
        name_length = length(split(func.name, "_"))
        # @show num_args
        if mode == "prior"
            weight_score = min_possible_AST_size*alpha_AST_weight + num_args * alpha_arg_weight + name_length * alpha_name_length
        else
            weight_score = 1
        end
        # weight_score = min_possible_AST_size^alpha_AST_weight + num_args
        # @show weight_score
        # weight_scores[format_new_function_string(func)] = 1/weight_score
        weight_scores[format_new_function_string(func)] = weight_score

    end
    weights = map(x -> weight_scores[format_new_function_string(x)], all_functions)
    @show all_functions
    println("pre-final weights")
    @show weights
    weights = weights .- minimum(weights) .+ 1
    @show weights
    weights = map(x -> 1/x, weights)
    println("final weights")
    @show weights
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

        # handle ALPHA (i.e. left/right uncertainty bias)
        @show possible_semantics
        alpha_augmented_semantics = filter(x -> occursin("update_alpha", x), possible_semantics)
        possible_semantics = filter(x -> !occursin("update_alpha", x), possible_semantics)

        semantics_weights = map(x -> alpha^size(Meta.parse(possible_semantics[x])), 1:length(possible_semantics)) # alpha^x
        if mode == "prior"
            alpha_augmented_semantics_weights = map(x -> alpha^(size(Meta.parse(x)) - 3) * alpha_LR_uncertainty_bias, alpha_augmented_semantics)
        else
            alpha_augmented_semantics_weights = map(x -> alpha^(size(Meta.parse(x))), alpha_augmented_semantics)
        end
        push!(semantics_weights, alpha_augmented_semantics_weights...)
        push!(possible_semantics, alpha_augmented_semantics...)

        @show alpha_augmented_semantics
        @show possible_semantics
        @show alpha_augmented_semantics_weights 
        @show semantics_weights

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

    # ALPHA handling
    alpha_augmentation_base_semantics = filter(x -> occursin("< 0", x) || occursin("> 0", x), possible_semantics)
    augmented_base_semantics = map(x -> "update_alpha(1.0) && $(x)", alpha_augmentation_base_semantics)
    possible_semantics = [possible_semantics..., augmented_base_semantics...]    

    possible_semantics = unique(possible_semantics)
    # # println(possible_semantics)

    # exclude function definitions that don't use all of the input arguments
    possible_semantics = filter(x -> foldl(&, map(a -> occursin(a, x), function_sig.arg_names), init=true), possible_semantics)

    possible_semantics = filter(x -> !occursin("0 <", x) && !occursin("1 <", x) && !occursin("1 >", x) && !occursin("0 >", x), possible_semantics)

    possible_semantics = filter(x -> !(x in [
        "next(location_arg, locations).color == color_arg", 
        "next(location_arg, locations).color == color1_arg",
        "prev(location_arg, locations).color == color_arg",
        "prev(location_arg, locations).color == color1_arg"
        ]), possible_semantics)

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
    total_score, scores, search_locations, temp_semantics = evaluate_semantics(nothing, "", 0, new_semantics_str, updated_syntax, 0, all_functions, test_config_names, test_name)

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
            signature = [subset[1].arg_names..., subset[1].arg_types]
            symmetric_functions = filter(x -> [x.arg_names..., x.arg_types] == signature && x.name != subset[1].name, old_functions)
            if symmetric_functions != []
                if rand() < alpha_double_delete 
                    symmetric_functions[1].definition = ""
                    push!(probs, alpha_double_delete)
                else
                    push!(probs, (1 - alpha_double_delete))
                end
            end
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
            signature = [subset[1].arg_names..., subset[1].arg_types]
            symmetric_functions = filter(x -> [x.arg_names..., x.arg_types] == signature && x.name != subset[1].name && x.definition != "", old_functions)
            if symmetric_functions != []
                if rand() < alpha_double_delete 
                    symmetric_functions[1].definition = ""
                    push!(probs, alpha_double_delete)
                else
                    push!(probs, (1 - alpha_double_delete))
                end
            end
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

            deleted_func_idxs = [] 
            for i in 1:length(old_functions)
                old_f = old_functions[i]
                new_f = new_functions[i]
                if old_f.name == new_f.name && old_f.definition != "" && new_f.definition == "" 
                    push!(deleted_func_idxs, i)
                end
            end

            deletion_probs = []
            for deleted_func_idx in deleted_func_idxs
                all_functions = deepcopy(current_state)
                for i in 1:length(all_functions)
                    f = all_functions[i]
                    if i != deleted_func_idx
                        f.definition = ""
                    end
                end
    
                prob = compute_function_subset_prob(all_functions, "proposal")

                signature = [all_functions[deleted_func_idx].arg_names..., all_functions[deleted_func_idx].arg_types]
                symmetric_functions = filter(x -> [x.arg_names..., x.arg_types] == signature && x.name != all_functions[deleted_func_idx].name, current_state)    

                if symmetric_functions != []
                    if length(deleted_func_idxs) > 1
                        push!(deletion_probs, prob * alpha_double_delete)
                    else 
                        push!(deletion_probs, prob * (1 - alpha_double_delete))
                    end
                else
                    push!(deletion_probs, prob)                    
                end
            end
            delete_prob = sum(deletion_probs)
            push!(probs, delete_prob)
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
            deleted_func_idxs = [] 
            for i in 1:length(old_functions)
                old_f = old_functions[i]
                new_f = new_functions[i]
                if old_f.name == new_f.name && old_f.definition != "" && new_f.definition == "" 
                    push!(deleted_func_idxs, i)
                end
            end

            deletion_probs = []
            for deleted_func_idx in deleted_func_idxs
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

                signature = [current_state_copy[deleted_func_idx].arg_names..., current_state_copy[deleted_func_idx].arg_types]
                symmetric_functions = filter(x -> [x.arg_names..., x.arg_types] == signature && x.name != current_state_copy[deleted_func_idx].name && x.definition != "", current_state)    

                if symmetric_functions != []
                    if length(deleted_func_idxs) > 1
                        push!(deletion_probs, prob * alpha_double_delete)
                    else 
                        push!(deletion_probs, prob * (1 - alpha_double_delete))
                    end
                else
                    push!(deletion_probs, prob)
                end
            end
            delete_prob = sum(deletion_probs)
            push!(probs, delete_prob)
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

# left_of_opposite_function = Function("left_of_opposite", ["location_arg", "color1_arg", "color2_arg"], [Corner, COLOR, COLOR], "")
# right_of_opposite_function = Function("right_of_opposite", ["location_arg", "color1_arg", "color2_arg"], [Corner, COLOR, COLOR], "")

left_of_opposite_function = Function("left_of_wall_opposite", ["location_arg", "color1_arg"], [Corner, COLOR], "")
right_of_opposite_function = Function("right_of_wall_opposite", ["location_arg", "color1_arg"], [Corner, COLOR], "")

# all_function_sigs = [at_function, my_left_function_spot, left_of_function, my_right_function_spot, right_of_function] # left_of_opposite_function

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
    "square_room_blue_wall_center_prize_copy4.json",   
    "square_room_blue_wall_center_prize_copy5.json",
    "spatial_lang_test_left_true_shift_0.json", 
    "spatial_lang_test_copy_left_true_shift_0.json", 
    "spatial_lang_test_copy2_left_true_shift_0.json",
    "spatial_lang_test_copy3_left_true_shift_0.json", 
    "spatial_lang_test_copy4_left_true_shift_0.json", 
    "square_room_blue_wall_left_prize.json",
    "square_room_blue_wall_far-left-corner_prize.json"
]

all_function_sigs = [at_function, my_left_function_spot, left_of_function, left_of_opposite_function,  my_right_function_spot, right_of_function, right_of_opposite_function] # left_of_opposite_function
# all_function_sigs = [at_function, my_left_function_spot, left_of_function, my_right_function_spot, right_of_function] # left_of_opposite_function
# all_function_sigs = [at_function, my_left_function_spot, left_of_function, left_of_opposite_function, my_right_function_spot, right_of_function, right_of_opposite_function] # left_of_opposite_function
# results = []
# for r in 1:20
#     println("REPEATS = $(r)")
#     all_function_sigs_copy = deepcopy(all_function_sigs)

#     prior0 = compute_prior_probability(all_function_sigs_copy)
#     likelihood0 = compute_likelihood(all_function_sigs_copy, test_config_names, r)
#     posterior0 = prior0 * likelihood0

#     all_function_sigs_copy[1].definition = "location_arg.color == color_arg"
#     prior1 = compute_prior_probability(all_function_sigs_copy)
#     likelihood1 = compute_likelihood(all_function_sigs_copy, test_config_names, r)
#     posterior1 = prior1 * likelihood1

#     all_function_sigs_copy[2].definition = "location_arg.position.x < 0"
#     prior2 = compute_prior_probability(all_function_sigs_copy)
#     likelihood2 = compute_likelihood(all_function_sigs_copy, test_config_names, r)
#     posterior2 = prior2 * likelihood2

#     all_function_sigs_copy[3].definition = "location_arg.wall2.color == color_arg"
#     prior3 = compute_prior_probability(all_function_sigs_copy)
#     likelihood3 = compute_likelihood(all_function_sigs_copy, test_config_names, r)
#     posterior3 = prior3 * likelihood3

#     all_function_sigs_copy[3].definition = ""
#     all_function_sigs_copy[4].definition = "location_arg.wall2.color == color1_arg && location_arg.wall1.color == color2_arg"
#     prior4 = compute_prior_probability(all_function_sigs_copy)
#     likelihood4 = compute_likelihood(all_function_sigs_copy, test_config_names, r)
#     posterior4 = prior4 * likelihood4

#     all_function_sigs_copy[3].definition = "location_arg.wall2.color == color_arg"
#     all_function_sigs_copy[4].definition = "prev(prev(location_arg, locations), locations).wall1.color == color1_arg && location_arg.wall2.color == color2_arg"
#     prior5 = compute_prior_probability(all_function_sigs_copy)
#     likelihood5 = compute_likelihood(all_function_sigs_copy, test_config_names, r)
#     posterior5 = prior5 * likelihood5

#     all_posteriors = [posterior0, posterior1, posterior2, posterior3, posterior4, posterior5]
#     max_posterior = maximum(all_posteriors)
#     normalized_max_posterior = maximum(all_posteriors) / sum(all_posteriors)

#     push!(results, [r, normalized_max_posterior, [prior0, likelihood0, posterior0], [prior1, likelihood1, posterior1], [prior2, likelihood2, posterior2], [prior3, likelihood3, posterior3], [prior4, likelihood4, posterior4], [prior5, likelihood5, posterior5]])
# end

# for tup in results 
#     println("----- REPEATS = $(tup[1]) -----")
#     println("normalized max posterior = $(tup[2])")
#     for i in 3:length(tup)
#         t = tup[i]
#         println("prior$(i - 3) = $(t[1])")
#         println("likelihood$(i - 3) = $(t[2])")
#         println("posterior$(i - 3) = $(t[3])")
#         println("-----")
#     end
# end

# chain = run_mcmc(all_function_sigs, test_config_names, 1000, repeats)

# global repeats = 25
# all_function_sigs = [at_function, my_left_function_spot, left_of_function, left_of_opposite_function, my_right_function_spot, right_of_function, right_of_opposite_function] # left_of_opposite_function

# global repeats = 20
# results = []
# for repeats in 5:5
#     println("----- REPEATS = $(repeats) -----")
#     all_function_sigs = deepcopy([at_function, my_left_function_spot, left_of_function, left_of_opposite_function, my_right_function_spot, right_of_function, right_of_opposite_function]) # left_of_opposite_function

#     prior_ = compute_prior_probability(all_function_sigs)
#     likelihood_ = compute_likelihood(all_function_sigs, test_config_names, repeats)
    

#     all_function_sigs[1].definition = "location_arg.color == color_arg"
#     prior0 = compute_prior_probability(all_function_sigs)
#     likelihood0 = compute_likelihood(all_function_sigs, test_config_names, repeats)

#     all_function_sigs[2].definition = "location_arg.position.x < 0"
#     all_function_sigs[5].definition = "location_arg.position.x > 0"

#     prior1 = compute_prior_probability(all_function_sigs)
#     likelihood1 = compute_likelihood(all_function_sigs, test_config_names, repeats)

#     all_function_sigs[3].definition = "location_arg.wall2.color == color_arg"
#     all_function_sigs[6].definition = "location_arg.wall1.color == color_arg"

#     prior3 = compute_prior_probability(all_function_sigs)
#     likelihood3 = compute_likelihood(all_function_sigs, test_config_names, repeats)

#     all_function_sigs[3].definition = ""
#     all_function_sigs[6].definition = ""
#     all_function_sigs[2].definition = "update_alpha(1.0) && location_arg.position.x < 0"
#     all_function_sigs[5].definition = "update_alpha(1.0) && location_arg.position.x > 0"

#     prior2 = compute_prior_probability(all_function_sigs)
#     likelihood2 = compute_likelihood(all_function_sigs, test_config_names, repeats)

#     all_function_sigs[3].definition = "location_arg.wall2.color == color_arg"
#     all_function_sigs[6].definition = "location_arg.wall1.color == color_arg"
#     prior4 = compute_prior_probability(all_function_sigs)
#     likelihood4 = compute_likelihood(all_function_sigs, test_config_names, repeats)

#     all_function_sigs[3].definition = "prev(prev(location_arg, locations), locations).wall1.color == color_arg"
#     all_function_sigs[6].definition = "next(next(location_arg, locations), locations).wall2.color == color_arg"

#     prior5 = compute_prior_probability(all_function_sigs)
#     likelihood5 = compute_likelihood(all_function_sigs, test_config_names, repeats)

#     all_function_sigs[3].definition = ""
#     all_function_sigs[6].definition = ""
#     all_function_sigs[4].definition = "prev(prev(location_arg, locations), locations).wall1.color == color1_arg"
#     all_function_sigs[7].definition = "location_arg.wall2.color == color1_arg"

#     prior5_5 = compute_prior_probability(all_function_sigs)
#     likelihood5_5 = compute_likelihood(all_function_sigs, test_config_names, repeats)

# println("PRIOR TWO")
# println(prior2)
# println("LIKELIHOOD TWO")
# println(compute_likelihood(all_function_sigs, test_config_names, 1))
# println(likelihood2)
# println("POSTERIOR TWO")
# println(prior2 * likelihood2)
#     all_function_sigs[4].definition = "location_arg.wall2.color == color1_arg"
#     all_function_sigs[7].definition = "location_arg.wall1.color == color1_arg"

#     prior5_75 = compute_prior_probability(all_function_sigs)
#     likelihood5_75 = compute_likelihood(all_function_sigs, test_config_names, repeats)

#     all_function_sigs[3].definition = "location_arg.wall2.color == color_arg"
#     all_function_sigs[6].definition = "location_arg.wall1.color == color_arg"
#     all_function_sigs[4].definition = "prev(prev(location_arg, locations), locations).wall1.color == color1_arg"
#     all_function_sigs[7].definition = "next(next(location_arg, locations), locations).wall2.color == color1_arg"
#     prior6 = compute_prior_probability(all_function_sigs)
#     likelihood6 = compute_likelihood(all_function_sigs, test_config_names, repeats)


#     push!(results, [repeats, prior4*likelihood4, prior5_5*likelihood5_5, prior6*likelihood6])

#     println("PRIOR _")
#     println(prior_)
#     println("LIKELIHOOD _")
#     println(likelihood_)
#     println("POSTERIOR _")
#     println(prior_ * likelihood_)

#     println("PRIOR ZERO")
#     println(prior0)
#     println("LIKELIHOOD ZERO")
#     println(likelihood0)
#     println("POSTERIOR ZERO")
#     println(prior0 * likelihood0)

#     println("PRIOR ONE")
#     println(prior1)
#     println("LIKELIHOOD ONE")
#     println(likelihood1)
#     println("POSTERIOR ONE")
#     println(prior1 * likelihood1)

#     println("PRIOR TWO")
#     println(prior2)
#     println("LIKELIHOOD TWO")
#     println(likelihood2)
#     println("POSTERIOR TWO")
#     println(prior2 * likelihood2)

#     println("PRIOR THREE")
#     println(prior3)
#     println("LIKELIHOOD THREE")
#     println(likelihood3)
#     println("POSTERIOR THREE")
#     println(prior3 * likelihood3)

#     println("PRIOR FOUR")
#     println(prior4)
#     println("LIKELIHOOD FOUR")
#     println(likelihood4)
#     println("POSTERIOR FOUR")
#     println(prior4 * likelihood4)

#     println("PRIOR FIVE")
#     println(prior5)
#     println("LIKELIHOOD FIVE")
#     println(likelihood5)
#     println("POSTERIOR FIVE")
#     println(prior5 * likelihood5)

#     println("PRIOR 5.5")
#     println(prior5_5)
#     println("LIKELIHOOD 5.5")
#     println(likelihood5_5)
#     println("POSTERIOR 5.5")
#     println(prior5_5 * likelihood5_5)

#     println("PRIOR 5.75")
#     println(prior5_75)
#     println("LIKELIHOOD 5.75")
#     println(likelihood5_75)
#     println("POSTERIOR 5.75")
#     println(prior5_75 * likelihood5_75)

#     println("PRIOR SIX")
#     println(prior6)
#     println("LIKELIHOOD SIX")
#     println(likelihood6)
#     println("POSTERIOR SIX")
#     println(prior6 * likelihood6)
# end

# for r in results 
#     println("----- REPEATS = $(r[1]) -----")
#     println("POSTERIOR FOUR")
#     println(r[2])
#     println("POSTERIOR 5.5")
#     println(r[3])
#     println("POSTERIOR SIX")
#     println(r[4])
# end


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
