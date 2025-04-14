using Plots 

# within single categories 
overall_accuracy_results_split = Dict([
    "left_of_blue" => [0.0],
    "spatial_lang_test" => [0.0],
    "red_green_test" => [0.0],
])

probability_results_split = Dict([
    "left_of_blue" => [3/8],
    "spatial_lang_test" => [1/6],
    "red_green_test" => [1/3],
])

# across all categories
overall_accuracy_results = Dict([
    "left_of_blue" => [0.0],
    "spatial_lang_test" => [0.0],
    "red_green_test" => [0.0],
])

probability_results = Dict([
    "left_of_blue" => [3/8],
    "spatial_lang_test" => [1/6],
    "red_green_test" => [1/3],
])

combined_results_dir = "metalanguage/results/ordered/combined"
folder_names = sort(readdir(combined_results_dir))

for folder_name in folder_names 
    println(folder_name)
    if isdir("$(combined_results_dir)/$(folder_name)/image_results")
        num_experiments = length(readdir("$(combined_results_dir)/$(folder_name)/image_results"))
        if num_experiments == 10 
            category_name = "left_of_blue"
        elseif num_experiments == 6 
            category_name = "spatial_lang_test"
        else #if num_experiments == 24
            category_name = "red_green_test"
        end
    
        global accuracy = 0.0
        open("$(combined_results_dir)/$(folder_name)/numerical_results/overall_benchmark_accuracy.txt", "r") do f 
            global accuracy = parse(Float64, read(f, String))
        end
        println("accuracy")
        println(accuracy)
    
        global probabilities = []
        open("$(combined_results_dir)/$(folder_name)/numerical_results/accuracies.txt", "r") do f 
            global probabilities = map(tup -> eval(Meta.parse(tup))[2], split(read(f, String), "\n"))
        end
        average_probability = sum(probabilities)/length(probabilities)
        println("probabilities")
        println(probabilities)
        println(average_probability)
        for k in keys(overall_accuracy_results)
            if k == category_name 
                push!(overall_accuracy_results_split[k], accuracy)
                push!(probability_results_split[k], average_probability)
    
                push!(overall_accuracy_results[k], accuracy)
                push!(probability_results[k], average_probability)
            else
                # add a repeat of the last value, since no improvement at this stage
                push!(overall_accuracy_results[k], overall_accuracy_results[k][end])
                push!(probability_results[k], probability_results[k][end])
            end
        end
    else # no function learned during this stage
        for k in keys(overall_accuracy_results)
            # add a repeat of the last value, since no improvement at this stage
            push!(overall_accuracy_results[k], overall_accuracy_results[k][end])
            push!(probability_results[k], probability_results[k][end])
        end
    end
    
end

# plot single category results
for k in keys(overall_accuracy_results_split)
    # benchmark solved rate plot ("accuracy")
    ys = overall_accuracy_results_split[k]
    xs = collect(0:(length(ys) - 1))
    p = plot(xs, ys, xlims = (0,length(xs) - 1), xticks = 0:1:(length(xs) - 1), linewidth=3, yticks=0:0.1:1)
    scatter!(xs, ys)
    xlabel!("Stage", xguidefontsize=9)
    ylabel!("% Benchmarks Solved Exactly", yguidefontsize=9)
    title!("% Benchmarks Solved During Pre-Ordered Function Semantics Synthesis", titlefontsize=10)

    savefig("metalanguage/results/plots/ordered/individual_benchmarks/benchmark_accuracy_$(k).png")

    # probability plot
    ys = probability_results_split[k]
    xs = collect(0:(length(ys) - 1))
    p = plot(xs, ys, ylims=(0, 1), xlims = (0,length(xs) - 1), xticks = 0:1:(length(xs) - 1), linewidth=3, yticks=0:0.1:1)
    scatter!(xs, ys)
    xlabel!("Stage", xguidefontsize=9)
    ylabel!("Average Correctness Probability", yguidefontsize=9)
    title!("Avg. Correctness Prob. During Pre-Ordered Function Semantics Synthesis", titlefontsize=10)
    savefig("metalanguage/results/plots/ordered/individual_benchmarks/correctness_probability_$(k).png")
end 

# plot all categories results 
p = ""
for k in sort([keys(overall_accuracy_results)...], by=length)
    # benchmark solved rate plot ("accuracy")
    ys = overall_accuracy_results[k]
    xs = collect(0:(length(ys) - 1))
    if p == ""
        p = plot(xs, ys, label=k, xlims = (0,length(xs) - 1), xticks = 0:1:(length(xs) - 1), linewidth=3)
    else
        p = plot!(p, xs, ys, label=k, xlims = (0,length(xs) - 1), xticks = 0:1:(length(xs) - 1), linewidth=3)
    end
end
plot!(legend=:bottomright)
xlabel!("Stage (Total # of Functions Synthesized)", xguidefontsize=9)
ylabel!("% Benchmarks Solved Exactly", yguidefontsize=9)
title!("% Benchmarks Solved During Pre-Ordered Function Semantics Synthesis", titlefontsize=10)

savefig("metalanguage/results/plots/ordered/all_benchmarks/benchmark_accuracy_all.png")

p = ""
for k in sort([keys(overall_accuracy_results)...], by=length)
    # probability plot
    ys = probability_results[k]
    xs = collect(0:(length(ys) - 1))
    if p == ""
        p = plot(xs, ys, label=k, ylims=(0,1), xlims = (0,length(xs) - 1), xticks = 0:1:(length(xs) - 1), linewidth=3, yticks=0:0.1:1)
    else
        p = plot!(p, xs, ys, label=k, ylims=(0,1), xlims = (0,length(xs) - 1), xticks = 0:1:(length(xs) - 1), linewidth=3, yticks=0:0.1:1)
    end
end
plot!(legend=:bottomright)
xlabel!("Stage", xguidefontsize=9)
ylabel!("Average Correctness Probability", yguidefontsize=9)
title!("Avg. Correctness Prob. During Pre-Ordered Function Semantics Synthesis", titlefontsize=10)

savefig("metalanguage/results/plots/ordered/all_benchmarks/correctness_probability_all.png")


split_results_dir = "metalanguage/results/ordered/by_category/red_green_test/stage_01/numerical_results"
global locations_to_search = []
open("$(split_results_dir)/locations_to_search.txt") do f 
    global locations_to_search = map(x -> eval(Meta.parse(x)), split(read(f, String),"\n"))
end

bar_chart_values = Dict(["M" => 0.0, "R" => 0.0, "D" => 0.0])

for tup in locations_to_search 
    labels = tup[2]
    for label in labels 
        bar_chart_values[label] += 1/length(labels)
    end
end

for k in keys(bar_chart_values)
    bar_chart_values[k] = bar_chart_values[k] / length(locations_to_search)
end

labels = ["M", "R", "D"]
formatted_labels = ["Match", "Reflection", "Different"]
values = map(x -> bar_chart_values[x] * 100, labels)
bar(
    formatted_labels,
    values,
    color = [:white, :black, :gray],
    legend=false,
    yticks=0:20:100,
    ylims=(0, 100),
    bar_width=0.5,
)
annotate!(formatted_labels, values, map(x -> ("$(round(x, digits=1))%", 10, :bottom), values))
xlabel!("Choice")
ylabel!("Percentage Choice")
title!("Model-Predicted Performance: Intrinsic\nbut not Relative Left/Right", titlefontsize=10)

savefig("metalanguage/results/plots/ordered/red_green_intrinsic_left_right_histogram.png")


# combined_results_dir = "metalanguage/results/ordered/combined"
# folder_names = sort(readdir(combined_results_dir))

# for folder_name in folder_names 
#     if isdir("$(combined_results_dir)/$(folder_name)/image_results")
#         num_experiments = length(readdir("$(combined_results_dir)/$(folder_name)/image_results"))
#         if num_experiments == 10 
#             category_name = "left_of_blue"
#         elseif num_experiments == 6 
#             category_name = "spatial_lang_test"
#         else #if num_experiments == 24
#             category_name = "red_green_test"
#         end

#         if category_name == "red_green_test"
#             println("woo!")
#             println(folder_name)

#             global probabilities = []
#             open("$(combined_results_dir)/$(folder_name)/numerical_results/accuracies.txt", "r") do f 
#                 global probabilities = map(tup -> eval(Meta.parse(tup))[2], split(read(f, String), "\n"))
#             end
#             total_exactly_correct = count(x -> x == 1.0, probabilities)
#             accuracy = total_exactly_correct/length(probabilities)

#             open("$(combined_results_dir)/$(folder_name)/numerical_results/overall_benchmark_accuracy.txt", "w") do f 
#                 write(f, string(round(accuracy, digits=3)))
#             end
#         end
#     end
# end