using Plots 
using Statistics
using LaTeXStrings
using Plots.PlotMeasures

function std_err(xs, ys)
    s = 0
    for i in 1:length(xs)
        s += (xs[i] - ys[i])^2
    end
    sqrt(s)/length(xs)
end

# geocentric plot 
vals1 = [
    (0.5, 19/48, "LoB"), # all white, rectangle
    (0.5, 15/48, "LoB"), # blue wall, rectangle
    (0.25, 0.26, "LoB"), # all white, square, blue wall
    (0.25, 0.26, "LoB"), # all white, square, no blue wall
    (0.25, 0.234, "LoB"), # square, alternating red and blue walls
    # (0.25, 0.25), # anecdotal: square, center prize, no blue wall 
    # (0.25, 0.25), # anecdotal: square, center prize, blue wall

    (1, 0.96, "LoB"),
    (1, 0.7, "LoB"), # huttenlocher, triangle rooms
    (0.25, 0.27, "LoB"), # wang, hermer, spelke, 1999: square, corner, blue wall, one session familiarization
    (0.25, 0.23, "LoB"), # wang, hermer, spelke, 1999: square, corner, blue wall, multi-session familiarization
    (0.5, 0.625, "LoB"), # hermer, spelke, 1996: colored corner experiments
    (0, 0.296, "LoB"), # hermer, spelke, 1996: colored corner modified experiments
]

vals1_2 = [
    (0.5, 19/48, "LoB"), # all white, rectangle
    (0.5, 15/48, "LoB"), # blue wall, rectangle
    (0.25, 0.26, "LoB"), # all white, square, blue wall
    (0.25, 0.26, "LoB"), # all white, square, no blue wall
    (0.25, 0.234, "LoB"), # square, alternating red and blue walls
    # (0.25, 0.25), # anecdotal: square, center prize, no blue wall 
    # (0.25, 0.25), # anecdotal: square, center prize, blue wall

    (1, 0.96, "LoB"),
    (1, 0.7, "LoB"), # huttenlocher, triangle rooms
    (0.25, 0.27, "LoB"), # wang, hermer, spelke, 1999: square, corner, blue wall, one session familiarization
    (0.25, 0.23, "LoB"), # wang, hermer, spelke, 1999: square, corner, blue wall, multi-session familiarization
    (1, 0.625, "LoB"), # hermer, spelke, 1996: colored corner experiments
    (1, 0.296, "LoB"), # hermer, spelke, 1996: colored corner modified experiments
]

vals1_3 = [
    (0.5, 19/48, "LoB"), # all white, rectangle
    (0.5, 15/48, "LoB"), # blue wall, rectangle
    (0.25, 0.26, "LoB"), # all white, square, blue wall
    (0.25, 0.26, "LoB"), # all white, square, no blue wall
    (0.25, 0.234, "LoB"), # square, alternating red and blue walls
    # (0.25, 0.25), # anecdotal: square, center prize, no blue wall 
    # (1, 0.25), # anecdotal: square, center prize: blue wall
    
    (1, 0.96, "LoB"),
    (1, 0.7, "LoB"), # triangle rooms
    (0.25, 0.27, "LoB"), # wang, hermer, spelke, 1999: square, corner, blue wall, one session familiarization
    (0.25, 0.23, "LoB"), # wang, hermer, spelke, 1999: square, corner, blue wall, multi-session familiarization
    (1, 0.625, "LoB"), # hermer, spelke, 1996: colored corner experiments
    (1, 0.296, "LoB"), # hermer, spelke, 1996: colored corner modified experiments

]

vals1_4 = [
    (0.5, 19/48, "LoB"), # all white, rectangle
    (0.5, 15/48, "LoB"), # blue wall, rectangle
    (0.25, 0.26, "LoB"), # all white, square, blue wall
    (0.25, 0.26, "LoB"), # all white, square, no blue wall
    (0.25, 0.234, "LoB"), # square, alternating red and blue walls
    # (0.25, 0.25), # anecdotal: square, center prize, no blue wall 
    # (1, 0.25), # anecdotal: square, center prize: blue wall
    
    (1, 0.96, "LoB"),
    (1, 0.7, "LoB"), # triangle rooms
    (0.25, 0.27, "LoB"), # wang, hermer, spelke, 1999: square, corner, blue wall, one session familiarization
    (0.25, 0.23, "LoB"), # wang, hermer, spelke, 1999: square, corner, blue wall, multi-session familiarization
    (1, 0.625, "LoB"), # hermer, spelke, 1996: colored corner experiments
    (1, 0.296, "LoB"), # hermer, spelke, 1996: colored corner modified experiments

]

vals1_5 = [
    (0.5, 19/48, "LoB"), # all white, rectangle
    (1, 15/48, "LoB"), # blue wall, rectangle
    (1, 0.26, "LoB"), # all white, square, blue wall
    (0.25, 0.26, "LoB"), # all white, square, no blue wall
    (0.5, 0.234, "LoB"), # square, alternating red and blue walls
    # (0.25, 0.25), # anecdotal: square, center prize, no blue wall 
    # (1, 0.25), # anecdotal: square, center prize: blue wall

    (1, 0.96, "LoB"),
    (1, 0.7, "LoB"), # triangle rooms
    (1, 0.27, "LoB"), # wang, hermer, spelke, 1999: square, corner, blue wall, one session familiarization
    (1, 0.23, "LoB"), # wang, hermer, spelke, 1999: square, corner, blue wall, multi-session familiarization
    (1, 0.625, "LoB"), # hermer, spelke, 1996: colored corner experiments
    (1, 0.296, "LoB"), # hermer, spelke, 1996: colored corner modified experiments

]

vals3 = [
    (1, 0.82, "LoB"), # rectangle, center, blue wall
    (0.5, 0.42, "LoB"), # rectangle, corner, blue wall

    (0.639 + 0.083, 0.545, "red-green"), # red-green test, no label
    (0.639 + 0.083, 0.608, "red-green"), # red-green test, directional label
    (0.639 + 0.083, 0.524, "red-green"), # red-green test, neutral label
    (0.25, 0.36, "LoB"), # LoB, square, corner, blue wall; low comprehension group

    (0.5, 0.50, "LoB"), # internal coherence paper

    (0.5, 0.59, "language_understanding"), # 3 y.o. LC, no label
    (0.5, 0.42, "language_understanding"), # 3 y.o. LC, directional

    (0.5, 0.50, "language_understanding"), # 3 y.o. LP, no label
    (0.5, 0.39, "language_understanding"), # 3 y.o. LP, directional

    (0.639 + 0.083, 0.476, "red-green"), # red-green test, no label, 0.5s
    (0.639 + 0.083, 0.56, "red-green"), # red-green test, directional label, 0.5s
    (0.639 + 0.083, 0.524, "red-green"), # red-green test, neutral label, 0.5s
]

vals3_1 = [
    (0.5, 0.82, "LoB"), # rectangle, center, blue wall
    (0.5, 0.42, "LoB"), # rectangle, corner, blue wall

    (1/3, 0.545, "red-green"), # red-green test, no label
    (1/3, 0.608, "red-green"), # red-green test, directional label
    (1/3, 0.524, "red-green"), # red-green test, neutral label
    (0.25, 0.36, "LoB"), # LoB, square, corner, blue wall; low comprehension group

    (0.5, 0.50, "LoB"), # internal coherence paper

    (0.25, 0.59, "language_understanding"), # 3 y.o. LC, no label
    (0.25, 0.42, "language_understanding"), # 3 y.o. LC, directional

    (0.25, 0.50, "language_understanding"), # 3 y.o. LP, no label
    (0.25, 0.39, "language_understanding"), # 3 y.o. LP, directional

    (1/3, 0.476, "red-green"), # red-green test, no label, 0.5s
    (1/3, 0.563, "red-green"), # red-green test, directional label, 0.5s
    (1/3, 0.524, "red-green"), # red-green test, neutral label, 0.5s
]

vals3_2 = [
    (1, 0.82, "LoB"), # rectangle, center, blue wall
    (0.5, 0.42, "LoB"), # rectangle, corner, blue wall

    (1/3, 0.545, "red-green"), # red-green test, no label
    (1/3, 0.608, "red-green"), # red-green test, directional label
    (1/3, 0.524, "red-green"), # red-green test, neutral label
    (0.25, 0.36, "LoB"), # LoB, square, corner, blue wall; low comprehension group

    (0.5, 0.50, "LoB"), # internal coherence paper

    (0.25, 0.59, "language_understanding"), # 3 y.o. LC, no label
    (0.25, 0.42, "language_understanding"), # 3 y.o. LC, directional

    (0.25, 0.50, "language_understanding"), # 3 y.o. LP, no label
    (0.25, 0.39, "language_understanding"), # 3 y.o. LP, directional

    (1/3, 0.476, "red-green"), # red-green test, no label, 0.5s
    (1/3, 0.563, "red-green"), # red-green test, directional label, 0.5s
    (1/3, 0.524, "red-green"), # red-green test, neutral label, 0.5s
]

vals3_4 = [
    (1, 0.82, "LoB"), # rectangle, center, blue wall
    (0.5, 0.42, "LoB"), # rectangle, corner, blue wall

    (0.639 + 0.083, 0.545, "red-green"), # red-green test, no label
    (1, 0.608, "red-green"), # red-green test, directional label
    (1, 0.524, "red-green"), # red-green test, prettier label
    (0.25, 0.36, "LoB"), # LoB, square, corner, blue wall; low comprehension group

    (0.5, 0.50, "LoB"), # internal coherence paper

    (0.5, 0.59, "language_understanding"), # 3 y.o. LC, no label
    (0.5, 0.42, "language_understanding"), # 3 y.o. LC, directional

    (0.75, 0.50, "language_understanding"), # 3 y.o. LP, no label
    (0.75, 0.39, "language_understanding"), # 3 y.o. LP, directional

    (0.639 + 0.083, 0.476, "red-green"), # red-green test, no label, 0.5s
    (1.0, 0.563, "red-green"), # red-green test, directional label, 0.5s
    (1.0, 0.524, "red-green"), # red-green test, neutral label, 0.5s
]

vals3_5 = [
    (1, 0.82, "LoB"), # rectangle, center, blue wall
    (1, 0.42, "LoB"), # rectangle, corner, blue wall

    (1, 0.545, "red-green"), # red-green test, no label
    (1, 0.608, "red-green"), # red-green test, directional label
    (1, 0.524, "red-green"), # red-green test, neutral label
    (1, 0.36, "LoB"), # LoB, square, corner, blue wall; low comprehension group

    (0.75, 0.50, "LoB"), # (1, 0.50), # internal coherence paper

    (1, 0.59, "language_understanding"), # 3 y.o. LC, no label
    (1, 0.42, "language_understanding"), # 3 y.o. LC, directional

    (1, 0.50, "language_understanding"), # 3 y.o. LP, no label
    (1, 0.39, "language_understanding"), # 3 y.o. LP, directional

    (1, 0.476, "red-green"), # red-green test, no label, 0.5s
    (1, 0.563, "red-green"), # red-green test, directional label, 0.5s
    (1, 0.524, "red-green"), # red-green test, neutral label, 0.5s
]

# intrinsic but can be language-augmented plot
vals4 = [
    (0.639 + 0.083, 0.660, "red-green"), # no label
    (0.639 + 0.083, 0.620, "red-green"), # neutral label
    (1, 0.822, "red-green"), # directional label 
    (0.639 + 0.083, 0.597, "red-green"), # flashing
    (0.639 + 0.083, 0.632, "red-green"), # growing
    (0.639 + 0.083, 0.637, "red-green"), # pointing
    (0.639 + 0.083, 0.646, "red-green"), # neutral label
    (1, 0.759, "red-green"), # directional label

    (0.639 + 0.083, 0.667, "red-green"), # no label 
    (1, 0.788, "red-green"), # directional label 
    (1, 0.788, "red-green"), # prettier label

    (0.25, 0.286, "LoB"), # LoB, square, corner, blue wall; high comprehension low production group

    (0.5, 0.45, "LoB"),
    (0.5, 0.55, "LoB"), # 1?
    (1, 0.77, "LoB"),
    (1, 0.72, "LoB"),

    (0.75, 0.44, "language_understanding"), # 4 y.o. LC, no label
    (0.75, 0.61, "language_understanding"), # 4 y.o. LC, directional

    (0.75, 0.53, "language_understanding"), # 4 y.o. LP, no label
    (0.75, 0.66, "language_understanding"), # 4 y.o. LP, directional

    (0.639 + 0.083, 0.559, "red-green"), # no label, 4s delay 
    (1, 0.747, "red-green"), # directional label, 4s delay
    (1, 0.625, "red-green"), # prettier label, 4s delay

    (0.75, 0.812, "language_understanding"), # Shusterman-Li spontaneous relative generalization
]

vals4_1 = [
    (1/3, 0.660, "red-green"), # no label
    (1/3, 0.620, "red-green"), # neutral label
    (1/3, 0.822, "red-green"), # directional label 
    (1/3, 0.597, "red-green"), # flashing
    (1/3, 0.632, "red-green"), # growing
    (1/3, 0.637, "red-green"), # pointing
    (1/3, 0.646, "red-green"), # neutral label
    (1/3, 0.759, "red-green"), # directional label

    (1/3, 0.667, "red-green"), # no label 
    (1/3, 0.788, "red-green"), # directional label 
    (1/3, 0.788, "red-green"), # prettier label

    (0.25, 0.286, "LoB"), # LoB, square, corner, blue wall; high comprehension low production group

    (0.5, 0.45, "LoB"),
    (0.5, 0.55, "LoB"),
    (0.5, 0.77, "LoB"),
    (0.5, 0.72, "LoB"),

    (0.25, 0.44, "language_understanding"), # 4 y.o. LC, no label
    (0.25, 0.61, "language_understanding"), # 4 y.o. LC, directional

    (0.25, 0.53, "language_understanding"), # 4 y.o. LP, no label
    (0.25, 0.66, "language_understanding"), # 4 y.o. LP, directional

    (1/3, 0.559, "red-green"), # no label, 4s delay 
    (1/3, 0.747, "red-green"), # directional label, 4s delay
    (1/3, 0.625, "red-green"), # prettier label, 4s delay

    (0.5, 0.812, "language_understanding"), # Shusterman-Li spontaneous relative generalization
]

vals4_2 = [
    (1/3, 0.660, "red-green"), # no label
    (1/3, 0.620, "red-green"), # neutral label
    (1/3, 0.822, "red-green"), # directional label 
    (1/3, 0.597, "red-green"), # flashing
    (1/3, 0.632, "red-green"), # growing
    (1/3, 0.637, "red-green"), # pointing
    (1/3, 0.646, "red-green"), # neutral label
    (1/3, 0.759, "red-green"), # directional label

    (1/3, 0.667, "red-green"), # no label 
    (1/3, 0.788, "red-green"), # directional label 
    (1/3, 0.788, "red-green"), # prettier label

    (0.25, 0.286, "LoB"), # LoB, square, corner, blue wall; high comprehension low production group

    (0.5, 0.45, "LoB"),
    (0.5, 0.55, "LoB"),
    (0.5, 0.77, "LoB"),
    (0.5, 0.72, "LoB"),

    (0.25, 0.44, "language_understanding"), # 4 y.o. LC, no label
    (0.25, 0.61, "language_understanding"), # 4 y.o. LC, directional

    (0.25, 0.53, "language_understanding"), # 4 y.o. LP, no label
    (0.25, 0.66, "language_understanding"), # 4 y.o. LP, directional

    (1/3, 0.559, "red-green"), # no label, 4s delay 
    (1/3, 0.747, "red-green"), # directional label, 4s delay
    (1/3, 0.625, "red-green"), # prettier label, 4s delay

    (0.5, 0.812, "language_understanding"), # Shusterman-Li spontaneous relative generalization

]

vals4_3 = [
    (0.639 + 0.083, 0.660, "red-green"), # no label
    (0.639 + 0.083, 0.620, "red-green"), # neutral label
    (0.639 + 0.083, 0.822, "red-green"), # directional label 
    (0.639 + 0.083, 0.597, "red-green"), # flashing
    (0.639 + 0.083, 0.632, "red-green"), # growing
    (0.639 + 0.083, 0.637, "red-green"), # pointing
    (0.639 + 0.083, 0.646, "red-green"), # neutral label
    (0.639 + 0.083, 0.759, "red-green"), # directional label

    (0.639 + 0.083, 0.667, "red-green"), # no label 
    (0.639 + 0.083, 0.788, "red-green"), # directional label 
    (0.639 + 0.083, 0.788, "red-green"), # prettier label

    (0.25, 0.286, "LoB"), # LoB, square, corner, blue wall; high comprehension low production group

    (0.5, 0.45, "LoB"),
    (0.5, 0.55, "LoB"),
    (0.5, 0.77, "LoB"),
    (0.5, 0.72, "LoB"),

    (0.5, 0.44, "language_understanding"), # 4 y.o. LC, no label
    (0.5, 0.61, "language_understanding"), # 4 y.o. LC, directional

    (0.5, 0.53, "language_understanding"), # 4 y.o. LP, no label
    (0.5, 0.66, "language_understanding"), # 4 y.o. LP, directional

    (0.639 + 0.083, 0.559, "red-green"), # no label, 4s delay 
    (0.639 + 0.083, 0.747, "red-green"), # directional label, 4s delay
    (0.639 + 0.083, 0.625, "red-green"), # prettier label, 4s delay

    (0.5, 0.812, "language_understanding"), # Shusterman-Li spontaneous relative generalization

]

vals4_5 = [
    (1, 0.660, "red-green"), # no label
    (1, 0.620, "red-green"), # neutral label
    (1, 0.822, "red-green"), # directional label 
    (1, 0.597, "red-green"), # flashing
    (1, 0.632, "red-green"), # growing
    (1, 0.637, "red-green"), # pointing
    (1, 0.646, "red-green"), # neutral label
    (1, 0.759, "red-green"), # directional label

    (1, 0.667, "red-green"), # no label 
    (1, 0.788, "red-green"), # directional label 
    (1, 0.788, "red-green"), # prettier label

    (1, 0.286, "LoB"), # LoB, square, corner, blue wall; high comprehension low production group

    (1, 0.45, "LoB"),
    (1, 0.55, "LoB"),
    (1, 0.77, "LoB"),
    (1, 0.72, "LoB"),

    (1, 0.44, "language_understanding"), # 4 y.o. LC, no label
    (1, 0.61, "language_understanding"), # 4 y.o. LC, directional

    (1, 0.53, "language_understanding"), # 4 y.o. LP, no label
    (1, 0.66, "language_understanding"), # 4 y.o. LP, directional

    (1, 0.559, "red-green"), # no label, 4s delay 
    (1, 0.747, "red-green"), # directional label, 4s delay
    (1, 0.625, "red-green"), # prettier label, 4s delay

    (1.0, 0.812, "language_understanding"), # Shusterman-Li spontaneous relative generalization
]

for i in 1:length(vals4_5)
    v = vals4_5[i] 
    v_arr = [v...]
    v_arr[1] = v[1] - rand() * 0.01
    vals4_5[i] = Tuple(v_arr)
end

# relative plot 
vals5 = [
    (1, 0.931, "red-green"), # no label
    (1, 0.962, "red-green"), # directional label
    (1, 0.837, "red-green"), # neutral label

    # adults
    (0.5, 0.57, "LoB"), # LoB, rectangle, corner, no blue wall 
    (1, 0.96, "LoB"), # LoB, rectangle, corner, blue wall

    # children with high language production
    (1, 0.766, "LoB"),

    (1, 0.937, "language_understanding"), # 6 y.o. LC
    (1, 0.91, "language_understanding"), # 6 y.o. LP

    (1, 0.837, "red-green"), # no label, 4s delay
    (1, 0.899, "red-green"), # directional label, 4s delay
    (1, 0.813, "red-green"), # neutral label, 4s delay

]

vals5_1 = [
    (1/3, 0.931, "red-green"), # no label
    (1/3, 0.962, "red-green"), # directional label
    (1/3, 0.837, "red-green"), # neutral label

    # adults
    (0.5, 0.57, "LoB"), # LoB, rectangle, corner, no blue wall 
    (0.5, 0.96, "LoB"), # LoB, rectangle, corner, blue wall

    # children with high language production
    (0.25, 0.766, "LoB"),

    (0.25, 0.937, "language_understanding"), # 6 y.o. LC
    (0.25, 0.91, "language_understanding"), # 6 y.o. LP

    (1/3, 0.837, "red-green"), # no label, 4s delay
    (1/3, 0.899, "red-green"), # directional label, 4s delay
    (1/3, 0.813, "red-green"), # neutral label, 4s delay
]

vals5_2 = [
    (1/3, 0.931, "red-green"), # no label
    (1/3, 0.962, "red-green"), # directional label
    (1/3, 0.837, "red-green"), # neutral label

    # adults
    (0.5, 0.57, "LoB"), # LoB, rectangle, corner, no blue wall 
    (0.5, 0.96, "LoB"), # LoB, rectangle, corner, blue wall

    # children with high language production
    (0.25, 0.766, "LoB"),

    (0.25, 0.937, "language_understanding"), # 6 y.o. LC
    (0.25, 0.91, "language_understanding"), # 6 y.o. LP

    (1/3, 0.837, "red-green"), # no label, 4s delay
    (1/3, 0.899, "red-green"), # directional label, 4s delay
    (1/3, 0.813, "red-green"), # neutral label, 4s delay

]

vals5_3 = [
    (0.639 + 0.083, 0.931, "red-green"), # no label
    (0.639 + 0.083, 0.962, "red-green"), # directional label
    (0.639 + 0.083, 0.837, "red-green"), # neutral label

    # adults
    (0.5, 0.57, "LoB"), # LoB, rectangle, corner, no blue wall 
    (0.5, 0.96, "LoB"), # LoB, rectangle, corner, blue wall

    # children with high language production
    (0.25, 0.766, "LoB"),

    (0.5, 0.937, "language_understanding"), # 6 y.o. LC
    (0.5, 0.91, "language_understanding"), # 6 y.o. LP

    (0.639 + 0.083, 0.837, "red-green"), # no label, 4s delay
    (0.639 + 0.083, 0.899, "red-green"), # directional label, 4s delay
    (0.639 + 0.083, 0.813, "red-green"), # neutral label, 4s delay

]

vals5_4 = [
    (0.639 + 0.083, 0.931, "red-green"), # no label
    (1, 0.962, "red-green"), # directional label
    (1, 0.837, "red-green"), # neutral label

    # adults
    (0.5, 0.57, "LoB"), # LoB, rectangle, corner, no blue wall 
    (0.5, 0.96, "LoB"), # LoB, rectangle, corner, blue wall

    # children with high language production
    (0.25, 0.766, "LoB"),

    (0.75, 0.937, "language_understanding"), # 6 y.o. LC
    (0.75, 0.91, "language_understanding"), # 6 y.o. LP

    (0.639 + 0.083, 0.837, "red-green"), # no label, 4s delay
    (1, 0.899, "red-green"), # directional label, 4s delay
    (1, 0.813, "red-green"), # neutral label, 4s delay
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
    r = cor(map(x -> x[1], vals), map(x -> x[2], vals))
    c = r < 0 ? 0 : r * r
    s = std_err(map(x -> x[1], vals), map(x -> x[2], vals))
    p = nothing 
    for v in vals 
        if v[3] == "LoB"
            mcolor = theme_palette(:auto)[1]
        elseif v[3] == "red-green"
            mcolor = theme_palette(:auto)[3]
        else
            mcolor = theme_palette(:auto)[4]
        end
        if isnothing(p)
            p = scatter([v[1]], [v[2]], xlimits=(0.0, 1.05), ylimits=(0.0, 1.05), legend=false, ticks=false, background_color_subplot=RGB(c, c, c), markershape=:diamond, color=mcolor, markerstrokewidth=1)
        else
            p = scatter(p, [v[1]], [v[2]], xlimits=(0.0, 1.05), ylimits=(0.0, 1.05), legend=false, ticks=false, background_color_subplot=RGB(c, c, c), markershape=:diamond, color=mcolor, markerstrokewidth=1)
        end
    end
    p = plot!(p, 0:0.1:1.1, 0:0.1:1.1, color=theme_palette(:auto)[2],xticks=0:0.25:1, xtickfontsize=5, yticks=0:0.25:1, ytickfontsize=5, margin=0mm, grid=false)
    p = xlabel!(p, "Model-Predicted Accuracy", xguidefontsize=6)
    p = ylabel!(p, "Empirical Accuracy", yguidefontsize=6)

    stage_number = i % 4 == 0 ? 4 : i % 4
    age_range = Int(round(i / 4))
    r_title = L"\textbf{R^2=}"
    if i in diagonals 
        p = title!(p, "$(r_title)$(round(r * r, digits=4))", titlefontsize=9, titlefontcolor=:green) # , MSE=$(round(s, digits=3))
    else
        p = title!(p, "$(r_title)$(round(r * r, digits=4))", titlefontsize=9) # , MSE=$(round(s, digits=3))
    end

    push!(rs, r)
    push!(stes, s)
    
    push!(plots, p)
end

plot(plots..., layout = (4, 4), size=(650, 650))

# function plot_scatter(all_correlation_dicts)
#     num_models = 4
#     num_age_groups = length(keys(all_correlation_dicts[[keys(all_correlation_dicts)...][1]]))

#     rs = []
#     stes = []    
#     plots = []
#     diagonals = [1, 6, 11, 16]
#     for age_group_id in 1:num_age_groups 
#         for model_id in ["geo", "my_right", "my_right_lang", "right_of"] 
#             vals = all_correlation_dicts[model_id][age_group_id]
#             r = round(cor(map(x -> x[1], vals), map(x -> x[2], vals)), digits=3)
#             c = r < 0 ? 0 : r
#             s = std_err(map(x -> x[1], vals), map(x -> x[2], vals))
        
#             p = scatter(map(x -> x[1], vals), map(x -> x[2], vals), xlimits=(0.0, 1.1), ylimits=(0.0, 1.1), legend=false, ticks=false, background_color_subplot=RGB(c, c, c))
#             p = plot!(p, 0:1, 0:1)
#             p = xlabel!(p, "Model-Predicted Accuracy", xguidefontsize=5)
#             p = ylabel!(p, "Empirical Accuracy", yguidefontsize=5)
        
#             stage_number = i % 4 == 0 ? 4 : i % 4
#             age_range = Int(round(i / 4))
#             if i in diagonals 
#                 p = title!(p, "R=$(round(r, digits=3)), MSE=$(round(s, digits=3))", titlefontsize=7, titlefontcolor=:green)
#             else
#                 p = title!(p, "R=$(round(r, digits=3)), MSE=$(round(s, digits=3))", titlefontsize=7)
#             end
        
#             push!(rs, r)
#             push!(stes, s)
            
#             push!(plots, p)
#         end
#     end
#     p = plot(plots..., layout = (4, num_age_groups))
#     return p
# end

# correlation_dict = Dict([
#     ("geo", 1) => vals1,
#     ("geo", 2) => vals3_1,
#     ("geo", 3) => vals4_1,
#     ("geo", 4) => vals5_1,

#     ("at", 1) => vals1_2,
#     ("at", 2) => vals3_2,
#     ("at", 3) => vals4_2,
#     ("at", 4) => vals5_2,

#     ("my_right", 1) => vals1_3,
#     ("my_right", 2) => vals3,
#     ("my_right", 3) => vals4_3,
#     ("my_right", 4) => vals5_3,

#     ("my_right_lang", 1) => vals1_4,
#     ("my_right_lang", 2) => vals3_4,
#     ("my_right_lang", 3) => vals4,
#     ("my_right_lang", 4) => vals5_4,

#     ("right_of", 1) => vals1_5,
#     ("right_of", 2) => vals3_5,
#     ("right_of", 3) => vals4_5,
#     ("right_of", 4) => vals5,
# ])

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