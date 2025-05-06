using Plots 
using Statistics

function std_err(xs, ys)
    s = 0
    for i in 1:length(xs)
        s += (xs[i] - ys[i])^2
    end
    sqrt(s)/length(xs)
end

# geocentric plot 
vals1 = [
    (0.5, 19/48), # all white, rectangle
    (0.5, 15/48), # blue wall, rectangle
    (0.25, 0.26), # all white, square, blue wall
    (0.25, 0.26), # all white, square, no blue wall
    (0.25, 0.234), # square, alternating red and blue walls
    # (0.25, 0.25), # anecdotal: square, center prize, no blue wall 
    # (0.25, 0.25), # anecdotal: square, center prize, blue wall

    (1, 0.7), # huttenlocher, triangle rooms
    (0.25, 0.27), # wang, hermer, spelke, 1999: square, corner, blue wall, one session familiarization
    (0.25, 0.23), # wang, hermer, spelke, 1999: square, corner, blue wall, multi-session familiarization
    (0.5, 0.625), # hermer, spelke, 1996: colored corner experiments
    (0, 0.296), # hermer, spelke, 1996: colored corner modified experiments
]

vals1_2 = [
    (0.5, 19/48), # all white, rectangle
    (0.5, 15/48), # blue wall, rectangle
    (0.25, 0.26), # all white, square, blue wall
    (0.25, 0.26), # all white, square, no blue wall
    (0.25, 0.234), # square, alternating red and blue walls
    # (0.25, 0.25), # anecdotal: square, center prize, no blue wall 
    # (0.25, 0.25), # anecdotal: square, center prize, blue wall

    (1, 0.7), # huttenlocher, triangle rooms
    (0.25, 0.27), # wang, hermer, spelke, 1999: square, corner, blue wall, one session familiarization
    (0.25, 0.23), # wang, hermer, spelke, 1999: square, corner, blue wall, multi-session familiarization
    (1, 0.625), # hermer, spelke, 1996: colored corner experiments
    (1, 0.296), # hermer, spelke, 1996: colored corner modified experiments
]

vals1_3 = [
    (0.5, 19/48), # all white, rectangle
    (0.5, 15/48), # blue wall, rectangle
    (0.25, 0.26), # all white, square, blue wall
    (0.25, 0.26), # all white, square, no blue wall
    (0.25, 0.234), # square, alternating red and blue walls
    # (0.25, 0.25), # anecdotal: square, center prize, no blue wall 
    # (1, 0.25), # anecdotal: square, center prize: blue wall
    
    (1, 0.7), # triangle rooms
    (0.25, 0.27), # wang, hermer, spelke, 1999: square, corner, blue wall, one session familiarization
    (0.25, 0.23), # wang, hermer, spelke, 1999: square, corner, blue wall, multi-session familiarization
    (1, 0.625), # hermer, spelke, 1996: colored corner experiments
    (1, 0.296), # hermer, spelke, 1996: colored corner modified experiments

]

vals1_4 = [
    (0.5, 19/48), # all white, rectangle
    (0.5, 15/48), # blue wall, rectangle
    (0.25, 0.26), # all white, square, blue wall
    (0.25, 0.26), # all white, square, no blue wall
    (0.25, 0.234), # square, alternating red and blue walls
    # (0.25, 0.25), # anecdotal: square, center prize, no blue wall 
    # (1, 0.25), # anecdotal: square, center prize: blue wall
    
    (1, 0.7), # triangle rooms
    (0.25, 0.27), # wang, hermer, spelke, 1999: square, corner, blue wall, one session familiarization
    (0.25, 0.23), # wang, hermer, spelke, 1999: square, corner, blue wall, multi-session familiarization
    (1, 0.625), # hermer, spelke, 1996: colored corner experiments
    (1, 0.296), # hermer, spelke, 1996: colored corner modified experiments

]

vals1_5 = [
    (0.5, 19/48), # all white, rectangle
    (1, 15/48), # blue wall, rectangle
    (1, 0.26), # all white, square, blue wall
    (0.25, 0.26), # all white, square, no blue wall
    (0.5, 0.234), # square, alternating red and blue walls
    # (0.25, 0.25), # anecdotal: square, center prize, no blue wall 
    # (1, 0.25), # anecdotal: square, center prize: blue wall

    (1, 0.7), # triangle rooms
    (1, 0.27), # wang, hermer, spelke, 1999: square, corner, blue wall, one session familiarization
    (1, 0.23), # wang, hermer, spelke, 1999: square, corner, blue wall, multi-session familiarization
    (1, 0.625), # hermer, spelke, 1996: colored corner experiments
    (1, 0.296), # hermer, spelke, 1996: colored corner modified experiments

]

vals3 = [
    (1, 0.82), # rectangle, center, blue wall
    (0.5, 0.42), # rectangle, corner, blue wall

    (0.639 + 0.083, 0.545), # red-green test, no label
    (0.639 + 0.083, 0.608), # red-green test, directional label
    (0.639 + 0.083, 0.524), # red-green test, neutral label
    (0.25, 0.36), # LoB, square, corner, blue wall; low comprehension group

    (0.5, 0.41),
]

vals3_1 = [
    (0.5, 0.82), # rectangle, center, blue wall
    (0.5, 0.42), # rectangle, corner, blue wall

    (1/2, 0.545), # red-green test, no label
    (1/2, 0.608), # red-green test, directional label
    (1/2, 0.524), # red-green test, neutral label
    (0.25, 0.36), # LoB, square, corner, blue wall; low comprehension group

    (0.5, 0.41),
]

vals3_2 = [
    (1, 0.82), # rectangle, center, blue wall
    (0.5, 0.42), # rectangle, corner, blue wall

    (1/2, 0.545), # red-green test, no label
    (1/2, 0.608), # red-green test, directional label
    (1/2, 0.524), # red-green test, neutral label
    (0.25, 0.36), # LoB, square, corner, blue wall; low comprehension group

    (0.5, 0.41),
]

vals3_4 = [
    (1, 0.82), # rectangle, center, blue wall
    (0.5, 0.42), # rectangle, corner, blue wall

    (0.639 + 0.083, 0.545), # red-green test, no label
    (1, 0.608), # red-green test, directional label
    (1, 0.524), # red-green test, prettier label
    (0.25, 0.36), # LoB, square, corner, blue wall; low comprehension group

    (0.5, 0.41),
]

vals3_5 = [
    (1, 0.82), # rectangle, center, blue wall
    (1, 0.42), # rectangle, corner, blue wall

    (1, 0.545), # red-green test, no label
    (1, 0.608), # red-green test, directional label
    (1, 0.524), # red-green test, neutral label
    (0.99, 0.36), # LoB, square, corner, blue wall; low comprehension group

    (1, 0.41),
]


# intrinsic but can be language-augmented plot
vals4 = [
    (0.639 + 0.083, 0.660), # no label
    (0.639 + 0.083, 0.620), # neutral label
    (1, 0.822), # directional label 
    (0.639 + 0.083, 0.597), # flashing
    (0.639 + 0.083, 0.632), # growing
    (0.639 + 0.083, 0.637), # pointing
    (0.639 + 0.083, 0.646), # neutral label
    (1, 0.759), # directional label

    (0.639 + 0.083, 0.667), # no label 
    (1, 0.788), # directional label 
    (1, 0.788), # prettier label

    (0.25, 0.286), # LoB, square, corner, blue wall; high comprehension low production group

    (0.5, 0.45),
    (0.5, 0.55),
    (1, 0.77),
    (1, 0.72),
]

vals4_1 = [
    (1/2, 0.660), # no label
    (1/2, 0.620), # neutral label
    (1/2, 0.822), # directional label 
    (1/2, 0.597), # flashing
    (1/2, 0.632), # growing
    (1/2, 0.637), # pointing
    (1/2, 0.646), # neutral label
    (1/2, 0.759), # directional label

    (1/2, 0.667), # no label 
    (1/2, 0.788), # directional label 
    (1/2, 0.788), # prettier label

    (0.25, 0.286), # LoB, square, corner, blue wall; high comprehension low production group

    (0.5, 0.45),
    (0.5, 0.55),
    (0.5, 0.77),
    (0.5, 0.72),
]

vals4_2 = [
    (1/2, 0.660), # no label
    (1/2, 0.620), # neutral label
    (1/2, 0.822), # directional label 
    (1/2, 0.597), # flashing
    (1/2, 0.632), # growing
    (1/2, 0.637), # pointing
    (1/2, 0.646), # neutral label
    (1/2, 0.759), # directional label

    (1/2, 0.667), # no label 
    (1/2, 0.788), # directional label 
    (1/2, 0.788), # prettier label

    (0.25, 0.286), # LoB, square, corner, blue wall; high comprehension low production group

    (0.5, 0.45),
    (0.5, 0.55),
    (0.5, 0.77),
    (0.5, 0.72),
]

vals4_3 = [
    (0.639 + 0.083, 0.660), # no label
    (0.639 + 0.083, 0.620), # neutral label
    (0.639 + 0.083, 0.822), # directional label 
    (0.639 + 0.083, 0.597), # flashing
    (0.639 + 0.083, 0.632), # growing
    (0.639 + 0.083, 0.637), # pointing
    (0.639 + 0.083, 0.646), # neutral label
    (0.639 + 0.083, 0.759), # directional label

    (0.639 + 0.083, 0.667), # no label 
    (0.639 + 0.083, 0.788), # directional label 
    (0.639 + 0.083, 0.788), # prettier label

    (0.25, 0.286), # LoB, square, corner, blue wall; high comprehension low production group

    (0.5, 0.45),
    (0.5, 0.55),
    (0.5, 0.77),
    (0.5, 0.72),
]

vals4_5 = [
    (1, 0.660), # no label
    (1, 0.620), # neutral label
    (1, 0.822), # directional label 
    (1, 0.597), # flashing
    (1, 0.632), # growing
    (1, 0.637), # pointing
    (1, 0.646), # neutral label
    (1, 0.759), # directional label

    (1, 0.667), # no label 
    (1, 0.788), # directional label 
    (1, 0.788), # prettier label

    (0.99, 0.286), # LoB, square, corner, blue wall; high comprehension low production group

    (1, 0.45),
    (1, 0.55),
    (1, 0.77),
    (1, 0.72),
]

# relative plot 
vals5 = [
    (1, 0.931), # no label
    (1, 0.962), # directional label
    (1, 0.837), # neutral label

    # adults
    (0.5, 0.57), # LoB, rectangle, corner, no blue wall 
    (1, 0.96), # LoB, rectangle, corner, blue wall

    # children with high language production
    (1, 0.766),
]

vals5_1 = [
    (1/2, 0.931), # no label
    (1/2, 0.962), # directional label
    (1/2, 0.837), # neutral label

    # adults
    (0.5, 0.57), # LoB, rectangle, corner, no blue wall 
    (0.5, 0.96), # LoB, rectangle, corner, blue wall

    # children with high language production
    (0.25, 0.766),
]

vals5_2 = [
    (1/2, 0.931), # no label
    (1/2, 0.962), # directional label
    (1/2, 0.837), # neutral label

    # adults
    (0.5, 0.57), # LoB, rectangle, corner, no blue wall 
    (0.5, 0.96), # LoB, rectangle, corner, blue wall

    # children with high language production
    (0.25, 0.766),
]

vals5_3 = [
    (0.639 + 0.083, 0.931), # no label
    (0.639 + 0.083, 0.962), # directional label
    (0.639 + 0.083, 0.837), # neutral label

    # adults
    (0.5, 0.57), # LoB, rectangle, corner, no blue wall 
    (0.5, 0.96), # LoB, rectangle, corner, blue wall

    # children with high language production
    (0.25, 0.766),
]

vals5_4 = [
    (1, 0.931), # no label
    (1, 0.962), # directional label
    (1, 0.837), # neutral label

    # adults
    (0.5, 0.57), # LoB, rectangle, corner, no blue wall 
    (0.5, 0.96), # LoB, rectangle, corner, blue wall

    # children with high language production
    (0.25, 0.766),
]

all_values = [vals1, vals1_3, vals1_4, vals1_5, 
              vals3_1, vals3, vals3_4, vals3_5,
              vals4_1, vals4_3, vals4, vals4_5,
              vals5_1, vals5_3, vals5_4, vals5
]

rs = []
stes = []
plots = []
# all_values = [vals1, vals2, vals3, vals4, vals5]
diagonals = [1, 6, 11, 16]
for i in 1:16
    vals = all_values[i]
    r = round(cor(map(x -> x[1], vals), map(x -> x[2], vals)), digits=3)
    c = r < 0 ? 0 : r
    s = std_err(map(x -> x[1], vals), map(x -> x[2], vals))

    p = scatter(map(x -> x[1], vals), map(x -> x[2], vals), xlimits=(0.0, 1.1), ylimits=(0.0, 1.1), legend=false, ticks=false, background_color_subplot=RGB(c, c, c))
    p = plot!(p, 0:1, 0:1)
    p = xlabel!(p, "Model-Predicted Accuracy", xguidefontsize=5)
    p = ylabel!(p, "Empirical Accuracy", yguidefontsize=5)

    stage_number = i % 4 == 0 ? 4 : i % 4
    age_range = Int(round(i / 4))
    if i in diagonals 
        p = title!(p, "R=$(round(r, digits=3)), MSE=$(round(s, digits=3))", titlefontsize=7, titlefontcolor=:green)
    else
        p = title!(p, "R=$(round(r, digits=3)), MSE=$(round(s, digits=3))", titlefontsize=7)
    end

    push!(rs, r)
    push!(stes, s)
    
    push!(plots, p)
end

plot(plots..., layout = (4, 4))

function plot_scatter(all_correlation_dicts)
    num_models = 4
    num_age_groups = length(keys(all_correlation_dicts[[keys(all_correlation_dicts)...][1]]))

    rs = []
    stes = []    
    plots = []
    diagonals = [1, 6, 11, 16]
    for age_group_id in 1:num_age_groups 
        for model_id in ["geo", "my_right", "my_right_lang", "right_of"] 
            vals = all_correlation_dicts[model_id][age_group_id]
            r = round(cor(map(x -> x[1], vals), map(x -> x[2], vals)), digits=3)
            c = r < 0 ? 0 : r
            s = std_err(map(x -> x[1], vals), map(x -> x[2], vals))
        
            p = scatter(map(x -> x[1], vals), map(x -> x[2], vals), xlimits=(0.0, 1.1), ylimits=(0.0, 1.1), legend=false, ticks=false, background_color_subplot=RGB(c, c, c))
            p = plot!(p, 0:1, 0:1)
            p = xlabel!(p, "Model-Predicted Accuracy", xguidefontsize=5)
            p = ylabel!(p, "Empirical Accuracy", yguidefontsize=5)
        
            stage_number = i % 4 == 0 ? 4 : i % 4
            age_range = Int(round(i / 4))
            if i in diagonals 
                p = title!(p, "R=$(round(r, digits=3)), MSE=$(round(s, digits=3))", titlefontsize=7, titlefontcolor=:green)
            else
                p = title!(p, "R=$(round(r, digits=3)), MSE=$(round(s, digits=3))", titlefontsize=7)
            end
        
            push!(rs, r)
            push!(stes, s)
            
            push!(plots, p)
        end
    end
    p = plot(plots..., layout = (4, num_age_groups))
    return p
end

correlation_dict = Dict([
    ("geo", 1) => vals1,
    ("geo", 2) => vals3_1,
    ("geo", 3) => vals4_1,
    ("geo", 4) => vals5_1,

    ("at", 1) => vals1_2,
    ("at", 2) => vals3_2,
    ("at", 3) => vals4_2,
    ("at", 4) => vals5_2,

    ("my_right", 1) => vals1_3,
    ("my_right", 2) => vals3,
    ("my_right", 3) => vals4_3,
    ("my_right", 4) => vals5_3,

    ("my_right_lang", 1) => vals1_4,
    ("my_right_lang", 2) => vals3_4,
    ("my_right_lang", 3) => vals4,
    ("my_right_lang", 4) => vals5_4,

    ("right_of", 1) => vals1_5,
    ("right_of", 2) => vals3_5,
    ("right_of", 3) => vals4_5,
    ("right_of", 4) => vals5,
])

# plots = []
# all_values = [vals1, vals2, vals3, vals4, vals5]
# for i in 1:5 
#     vals = all_values[i]
#     p = scatter(map(x -> x[1], vals), map(x -> x[2], vals), xlimits=(0.0, 1.1), ylimits=(0.0, 1.1), legend=false)
#     p = plot!(p, 0:1, 0:1)
#     p = xlabel!(p, "Model-Predicted Accuracy", xguidefontsize=6)
#     p = ylabel!(p, "Empirical Accuracy", yguidefontsize=6)
#     p = title!(p, "Stage $(i)", titlefontsize=8)

#     push!(plots, p)
# end
# plot(plots..., layout = 5)

# ls = [1, 0.5, 1, 0, 0, 1]
# rs = [0.5, 1, 0, 1, 1, 0]

# possibilities = []

# n = 6
# for i in 0:(2^n - 1) 
#     s = bitstring(i)[end - (n - 1) : end]
#     println(s)
#     tup = []
#     for idx in 1:n
#         if s[idx] == '0'
#             push!(tup, ls[idx])
#         else        
#             push!(tup, rs[idx])
#         end
#     end
#     println(tup)
#     push!(possibilities, sum(tup)/length(tup))
# end

# sum(possibilities)/length(possibilities)