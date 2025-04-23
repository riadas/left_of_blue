using Plots 
using Statistics


age_group_1_data = Dict({
    "rect_room_no_blue_wall_left_prize" => (nothing, 19/48),
    "rect_room_blue_wall_left_prize" => (nothing, 15/48),
    "square_room_blue_wall_left_prize" => (nothing, 0.26),
    "square_room_no_blue_wall_left_prize" => (nothing, 0.26),
    "square_room_alternating_blue_wall_left_prize" => (0.25, 0.234),
    "square_room_no_blue_wall_center_prize" => (nothing, 0.25), # anecdotal
    "square_room_blue_wall_center_prize" => (nothing, 0.25), # anecdotal
    "square_room_blue_wall_left_prize2" => (nothing, 0.27),
    "square_room_blue_wall_left_prize3" => (nothing, 0.23),
    "triangle" => (nothing, 0.7)
})

age_group_2_data = Dict({
    "rect_room_blue_wall_center_prize" => (nothing, 0.82),
    "rect_room_blue_wall_left_prize" => (nothing, 0.42),
    "square_room_blue_wall_left_prize" => (nothing, 0.36), # LoB, square, corner, blue wall; low comprehension group
    
    "green_red_test" => (nothing, 0.545),
    "green_red_test_directional" => (nothing, 0.608),
    "green_red_test_neutral" => (nothing, 0.524),
})

age_group_3_data = Dict({

    "green_red_test" => (nothing, 0.667),
    "green_red_test_directional" => (nothing, 0.788),
    "green_red_test_neutral" => (nothing, 0.788),

    "square_room_blue_wall_left_prize" => (nothing, 0.286), # LoB, square, corner, blue wall; high comprehension but low production group


    "green_red_test_old" => (nothing, 0.660),
    "green_red_test_old_directional" => (nothing, 0.822),
    "green_red_test_old_neutral" => (nothing, 0.620),

    "green_red_test_old_flashing" => (nothing, 0.597),
    "green_red_test_old_growing" => (nothing, 0.632),
    "green_red_test_old_pointing" => (nothing, 0.637),

    "green_red_test_old_directional2" => (nothing, 0.759),
    "green_red_test_old_neutral2" => (nothing, 0.646),
})

age_group_4_data = Dict({
    "green_red_test" => (nothing, 0.931),
    "green_red_test_directional" => (nothing, 0.962),
    "green_red_test_neutral" => (nothing, 0.837),

    "rect_room_no_blue_wall_left_prize" => (nothing, 0.57),
    "rect_room_blue_wall_left_prize" => (nothing, 0.96),

    "square_room_blue_wall_left_prize" => (nothing, 0.766), # LoB, square, corner, blue wall; high production group
})

age_stages = [age_group_1_data, age_group_2_data, age_group_3_data, age_group_4_data]
model_stages = ["", "", "", ""]
all_values = []
for model_stage in model_stages 
    results_folder = "$(model_stage)"
    for age_stage in age_stages 
        # get results from appropriate model stage folder for each task in the age stage dict
        for task_name in keys(age_stage)
            if occursin("green_red_test", task_name)

            else    

            end
            push!(all_values, [values(age_stage)...])
        end

    end

end

# # geocentric plot 
# vals1 = [
#     (0.5, 19/48), # all white, rectangle
#     (0.5, 15/48), # blue wall, rectangle
#     (0.25, 0.26), # all white, square, blue wall
#     (0.25, 0.26), # all white, square, no blue wall
#     (0.25, 0.234), # square, alternating red and blue walls
#     (0.25, 0.25), # anecdotal: square, center prize, no blue wall 
#     (0.25, 0.25) # anecdotal: square, center prize, blue wall
# ]

# vals1_3 = [
#     (0.5, 19/48), # all white, rectangle
#     (0.5, 15/48), # blue wall, rectangle
#     (0.25, 0.26), # all white, square, blue wall
#     (0.25, 0.26), # all white, square, no blue wall
#     (0.25, 0.234), # square, alternating red and blue walls
#     (0.25, 0.25), # anecdotal: square, center prize, no blue wall 
#     (1, 0.25) # anecdotal: square, center prize: blue wall
# ]

# vals1_4 = [
#     (0.5, 19/48), # all white, rectangle
#     (0.5, 15/48), # blue wall, rectangle
#     (0.25, 0.26), # all white, square, blue wall
#     (0.25, 0.26), # all white, square, no blue wall
#     (0.25, 0.234), # square, alternating red and blue walls
#     (0.25, 0.25), # anecdotal: square, center prize, no blue wall 
#     (1, 0.25) # anecdotal: square, center prize: blue wall
# ]

# vals1_5 = [
#     (0.5, 19/48), # all white, rectangle
#     (1, 15/48), # blue wall, rectangle
#     (1, 0.26), # all white, square, blue wall
#     (0.25, 0.26), # all white, square, no blue wall
#     (0.5, 0.234), # square, alternating red and blue walls
#     (0.25, 0.25), # anecdotal: square, center prize, no blue wall 
#     (1, 0.25) # anecdotal: square, center prize: blue wall
# ]

# vals3 = [
#     (1, 0.82), # rectangle, center, blue wall
#     (0.5, 0.42), # rectangle, corner, blue wall

#     (0.639 + 0.083, 0.545), # red-green test, no label
#     (0.639 + 0.083, 0.608), # red-green test, directional label
#     (0.639 + 0.083, 0.524), # red-green test, neutral label
#     (0.25, 0.36), # LoB, square, corner, blue wall; low comprehension group
# ]

# vals3_1 = [
#     (0.5, 0.82), # rectangle, center, blue wall
#     (0.5, 0.42), # rectangle, corner, blue wall
#     (0.25, 0.36), # low comprehension group

#     (1/2, 0.545), # red-green test, no label
#     (1/2, 0.608), # red-green test, directional label
#     (1/2, 0.524), # red-green test, neutral label
#     (0.25, 0.36), # LoB, square, corner, blue wall; low comprehension group
# ]

# vals3_4 = [
#     (1, 0.82), # rectangle, center, blue wall
#     (0.5, 0.42), # rectangle, corner, blue wall
#     (0.25, 0.36), # low comprehension group

#     (0.639 + 0.083, 0.545), # red-green test, no label
#     (1, 0.608), # red-green test, directional label
#     (1, 0.524), # red-green test, neutral label
#     (0.25, 0.36), # LoB, square, corner, blue wall; low comprehension group
# ]

# vals3_5 = [
#     (1, 0.82), # rectangle, center, blue wall
#     (1, 0.42), # rectangle, corner, blue wall
#     (1, 0.36), # low comprehension group

#     (1, 0.545), # red-green test, no label
#     (1, 0.608), # red-green test, directional label
#     (1, 0.524), # red-green test, neutral label
#     (0.99, 0.36), # LoB, square, corner, blue wall; low comprehension group
# ]


# # intrinsic but can be language-augmented plot
# vals4 = [
#     (0.639 + 0.083, 0.660), # no label
#     (0.639 + 0.083, 0.620), # neutral label
#     (1, 0.822), # directional label 
#     (0.639 + 0.083, 0.597), # flashing
#     (0.639 + 0.083, 0.632), # growing
#     (0.639 + 0.083, 0.637), # pointing
#     (0.639 + 0.083, 0.646), # neutral label
#     (1, 0.759), # directional label

#     (0.639 + 0.083, 0.667), # no label 
#     (1, 0.788), # directional label 
#     (1, 0.788), # prettier label

#     (0.25, 0.286) # LoB, square, corner, blue wall; high comprehension low production group
# ]

# vals4_1 = [
#     (1/2, 0.660), # no label
#     (1/2, 0.620), # neutral label
#     (1/2, 0.822), # directional label 
#     (1/2, 0.597), # flashing
#     (1/2, 0.632), # growing
#     (1/2, 0.637), # pointing
#     (1/2, 0.646), # neutral label
#     (1/2, 0.759), # directional label

#     (1/2, 0.667), # no label 
#     (1/2, 0.788), # directional label 
#     (1/2, 0.788), # prettier label

#     (0.25, 0.286) # LoB, square, corner, blue wall; high comprehension low production group
# ]

# vals4_3 = [
#     (0.639 + 0.083, 0.660), # no label
#     (0.639 + 0.083, 0.620), # neutral label
#     (0.639 + 0.083, 0.822), # directional label 
#     (0.639 + 0.083, 0.597), # flashing
#     (0.639 + 0.083, 0.632), # growing
#     (0.639 + 0.083, 0.637), # pointing
#     (0.639 + 0.083, 0.646), # neutral label
#     (0.639 + 0.083, 0.759), # directional label

#     (0.639 + 0.083, 0.667), # no label 
#     (0.639 + 0.083, 0.788), # directional label 
#     (0.639 + 0.083, 0.788), # prettier label

#     (0.25, 0.286) # LoB, square, corner, blue wall; high comprehension low production group
# ]

# vals4_5 = [
#     (1, 0.660), # no label
#     (1, 0.620), # neutral label
#     (1, 0.822), # directional label 
#     (1, 0.597), # flashing
#     (1, 0.632), # growing
#     (1, 0.637), # pointing
#     (1, 0.646), # neutral label
#     (1, 0.759), # directional label

#     (1, 0.667), # no label 
#     (1, 0.788), # directional label 
#     (1, 0.788), # prettier label

#     (0.25, 0.286) # LoB, square, corner, blue wall; high comprehension low production group
# ]

# # relative plot 
# vals5 = [
#     (1, 0.931), # no label
#     (1, 0.962), # directional label
#     (1, 0.837), # neutral label

#     # adults
#     (0.5, 0.57), # LoB, rectangle, corner, no blue wall 
#     (1, 0.96), # LoB, rectangle, corner, blue wall

#     # children with high language production
#     (1, 0.766),
# ]

# vals5_1 = [
#     (1/2, 0.931), # no label
#     (1/2, 0.962), # directional label
#     (1/2, 0.837), # neutral label

#     # adults
#     (0.5, 0.57), # LoB, rectangle, corner, no blue wall 
#     (0.5, 0.96), # LoB, rectangle, corner, blue wall

#     # children with high language production
#     (0.25, 0.766),
# ]

# vals5_3 = [
#     (0.639 + 0.083, 0.931), # no label
#     (0.639 + 0.083, 0.962), # directional label
#     (0.639 + 0.083, 0.837), # neutral label

#     # adults
#     (0.5, 0.57), # LoB, rectangle, corner, no blue wall 
#     (0.5, 0.96), # LoB, rectangle, corner, blue wall

#     # children with high language production
#     (0.25, 0.766),
# ]

# vals5_4 = [
#     (1, 0.931), # no label
#     (1, 0.962), # directional label
#     (1, 0.837), # neutral label

#     # adults
#     (0.5, 0.57), # LoB, rectangle, corner, no blue wall 
#     (0.5, 0.96), # LoB, rectangle, corner, blue wall

#     # children with high language production
#     (0.25, 0.766),
# ]

# all_values = [vals1, vals1_3, vals1_4, vals1_5, 
#               vals3_1, vals3, vals3_4, vals3_5,
#               vals4_1, vals4_3, vals4, vals4_5,
#               vals5_1, vals5_3, vals5_4, vals5
# ]

# rs = []
# stes = []
# plots = []
# # all_values = [vals1, vals2, vals3, vals4, vals5]
# diagonals = [1, 6, 11, 16]
# for i in 1:16
#     vals = all_values[i]
#     r = round(cor(map(x -> x[1], vals), map(x -> x[2], vals)), digits=3)
#     c = r < 0 ? 0 : r
#     s = std_err(map(x -> x[1], vals), map(x -> x[2], vals))

#     p = scatter(map(x -> x[1], vals), map(x -> x[2], vals), xlimits=(0.0, 1.1), ylimits=(0.0, 1.1), legend=false, ticks=false, background_color_subplot=RGB(c, c, c))
#     p = plot!(p, 0:1, 0:1)
#     p = xlabel!(p, "Model-Predicted Accuracy", xguidefontsize=5)
#     p = ylabel!(p, "Empirical Accuracy", yguidefontsize=5)

#     stage_number = i % 4 == 0 ? 4 : i % 4
#     age_range = Int(round(i / 4))
#     if i in diagonals 
#         p = title!(p, "R=$(round(r, digits=3))", titlefontsize=7, titlefontcolor=:green)
#     else
#         p = title!(p, "R=$(round(r, digits=3))", titlefontsize=7)
#     end

#     push!(rs, r)
#     push!(stes, s)
    
#     push!(plots, p)
# end

# plot(plots..., layout = (4, 4))

# function std_err(xs, ys)
#     s = 0
#     for i in 1:length(xs)
#         s += (xs[i] - ys[i])^2
#     end
#     sqrt(s)
# end