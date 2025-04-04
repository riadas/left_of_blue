using JSON, Plots

function visualize_spatial_reasoning_problem(filepath::String, display2D=true)
    config = JSON.parsefile(filepath)
    return visualize_spatial_reasoning_problem(config, display2D)
end

function visualize_spatial_reasoning_problem(config, display2D=true)
    if config["type"] == "left_of_blue"
        return visualize_left_of_blue_problem(config, display2D)
    elseif config["type"] == "spatial_lang_test"
        return visualize_spatial_lang_problem()
    end
end

function visualize_left_of_blue_problem(config, save_filepath="", display2D=true)
    rectangle(w, h, x, y) = Shape(x .+ [0,w,w,0], y .+ [0,0,h,h])
    l = config["length"]
    w = config["width"]
    accent_wall = config["accent_wall"]
    corner_prize = config["corner_prize"]

    smaller_dim = min(l, w)
    larger_dim = max(l, w)

    scaled_l = 4 
    scaled_w = smaller_dim * scaled_l / larger_dim

    # set up grid
    plot(0:5,0:5, linecolor="white")

    # draw rectangle
    plot!(rectangle(scaled_w,scaled_l,(5-scaled_w)/2,(5-scaled_l)/2), opacity=.5, grid=false, axis=([], false), legend=false, size=(400, 400), color="white")

    # draw viewer position
    scatter!([2.5], [2.5], markercolor="black", markerstrokecolor="black")

    # potentially add blue wall
    accent_width = 0.05
    if accent_wall
        plot!(rectangle(scaled_w, accent_width,(5-scaled_w)/2,(5-scaled_l)/2 + scaled_l), opacity=1, grid=false, axis=([], false), legend=false, size=(400, 400), color="blue")
    end

    # add prize location
    offset = accent_width * 4
    if corner_prize 
        location = [(5-scaled_w)/2 + offset, (5-scaled_l)/2 + scaled_l - offset]
    else
        location = [2.5, (5-scaled_l)/2 + scaled_l - offset]
    end
    scatter!(location[1:1], location[2:2], markershape=:star5, markersize=7, markercolor="red", markerstrokecolor="red")

    # add dimension labels
    width_label_x = 2.5
    width_label_y = (5-scaled_l)/2 - offset
    width_label = "$(smaller_dim)"
    # scatter!(width_label_x, width_label_y, markercolor="red", markerstrokecolor="red")
    annotate!.(width_label_x, width_label_y, text.(width_label, :black, :right, 10) )

    length_label_x = (5-scaled_w)/2 + scaled_w + offset * 1.25
    length_label_y = 2.5
    length_label = "$(larger_dim)"
    # scatter!(length_label_x, length_label_y, markercolor="red", markerstrokecolor="red")
    p = annotate!.(length_label_x, length_label_y, text.(length_label, :black, :right, 10) )

    if save_filepath != ""
        savefig(save_filepath)
    end

    return p
end

function visualize_left_of_blue_results(config, scene, locations_to_search, save_filepath="")
    p = visualize_left_of_blue_problem(config, "")

    l = config["length"]
    w = config["width"]
    accent_wall = config["accent_wall"]
    corner_prize = config["corner_prize"]

    smaller_dim = min(l, w)
    larger_dim = max(l, w)

    scaled_l = 4 
    scaled_w = smaller_dim * scaled_l / larger_dim

    accent_width = 0.05
    offset = accent_width * 4

    if length(locations_to_search) == 4 
        if locations_to_search[1] isa Wall 
            positions = [
                (2.5, (5-scaled_l)/2 + scaled_l - offset * 2),
                (2.5, (5-scaled_l)/2 + offset * 2),
                ((5-scaled_w)/2 + offset * 2, 2.5),
                ((5-scaled_w)/2 + scaled_w - offset * 2, 2.5),
            ]
        else
            positions = [
                ((5 - scaled_w)/2 + offset * 2, (5-scaled_l)/2 + scaled_l - offset * 2),
                ((5 - scaled_w)/2 + scaled_w - offset * 2, (5-scaled_l)/2 + scaled_l - offset * 2),
                ((5 - scaled_w)/2 + offset * 2, (5-scaled_l)/2 + offset * 2),
                ((5 - scaled_w)/2 + scaled_w - offset * 2, (5-scaled_l)/2 + offset * 2),
            ]
        end

        labels = ["0.25", "0.25", "0.25", "0.25"]
        for i in 1:length(labels)
            label = labels[i]
            label_x, label_y = positions[i]
            # scatter!([label_x], [label_y], markercolor="red", markerstrokecolor="red")
            p = annotate!.(label_x, label_y, text.(label, :green, 10) )
        end

    elseif length(locations_to_search) == 1 
        location = locations_to_search[1]
        if location isa Wall 
            # plot at center of blue wall
            label_x = 2.5
            label_y = (5-scaled_l)/2 + scaled_l - offset * 2
            label = "1.0"
            # scatter!(width_label_x, width_label_y, markercolor="red", markerstrokecolor="red")
            p = annotate!.(label_x, label_y, text.(label, :green, 10) )
        else
            # plot at corner of blue wall
            label_x = (5 - scaled_w)/2 + offset * 2
            label_y = (5-scaled_l)/2 + scaled_l - offset * 2
            label = "1.0"
            # scatter!(width_label_x, width_label_y, markercolor="red", markerstrokecolor="red")
            p = annotate!.(label_x, label_y, text.(label, :green, 10) )
        end

    elseif length(locations_to_search) == 2 
        if locations_to_search[1] isa Wall 
            positions = [
                (2.5, (5-scaled_l)/2 + scaled_l - offset * 2),
                (2.5, (5-scaled_l)/2 + offset * 2),
            ]
        else
            positions = [
                ((5 - scaled_w)/2 + offset * 2, (5-scaled_l)/2 + scaled_l - offset * 2),
                ((5 - scaled_w)/2 + scaled_w - offset * 2, (5-scaled_l)/2 + offset * 2),
            ]
        end
        labels = ["0.5", "0.5"]
        for i in 1:length(labels)
            label = labels[i]
            label_x, label_y = positions[i]
            # scatter!([label_x], [label_y], markercolor="red", markerstrokecolor="red")
            p = annotate!.(label_x, label_y, text.(label, :green, 10) )
        end
    end

    if save_filepath != ""
        savefig(save_filepath)
    end

    return p
end

function visualize_spatial_lang_problem(save_filepath="")
    function plot_cube(p, center_shift, col=nothing)
        println(p)
        println(center_shift)
        println(col)
        xp = [0, 0, 0, 0, 1, 1, 1, 1] .+ center_shift[1]
        yp = [0, 1, 0, 1, 0, 0, 1, 1] .+ center_shift[2]
        zp = [0, 0, 1, 1, 1, 0, 0, 1] .+ center_shift[3]
    
        connections = [(1,2,3), (4,2,3), (4,7,8), (7,5,6), (2,4,7), (1,6,2), (2,7,6), (7,8,5), (4,8,5), (4,5,3), (1,6,3), (6,3,5)]
    
        xe = [0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0] .+ center_shift[1]
        ye = [0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0, 1, 1] .+ center_shift[2]
        ze = [0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1] .+ center_shift[3]
        
        if p == ""
            println("hello")
            p = plot(xe,ye,ze; lc=:black, lw=0.5, lims=(-0.25,3.25), grid=false, axis=([], false), legend=false)
        else
            p = plot!(p, xe,ye,ze; lc=:black, lw=0.5, lims=(-0.25,3.25), grid=false, axis=([], false), legend=false)
        end
        
        if !isnothing(col)
            p = scatter!(p, (0.5,0.5,0.5) .+ center_shift; c=col, ms=6, msw=0.1, grid=false, axis=([], false), legend=false)
            p = mesh3d!(xp,yp,zp; connections, proj_type=:persp, fc=col, lc=:black, fa=0.1, lw=0, grid=false, axis=([], false), legend=false)
        end
        # if !isnothing(col)
        #     p = mesh3d!(xp,yp,zp; connections, proj_type=:persp, fc=:lime, lc=:black, fa=0.1, lw=0)
        # end
        return p
    end
    
    p = plot_cube("", (1, 1, 1), :red)
    
    for x in 0:2 
        for y in 0:2 
            for z in 0:2 
                if (x, y, z) in [(2, 1, 1), (1, 2, 1), (1, 1, 2), (0, 1, 1), (1, 0, 1), (1, 1, 0)]
                    p = plot_cube(p, (x, y, z), :blue)
                else 
                    # p = plot_cube(p, (x, y, z))
                end
            end
        end
    end

    if save_filepath != ""
        savefig(save_filepath)
    end

    return p    
end

function visualize_spatial_lang_results(config, locations_to_search, save_filepath="")
    p = visualize_spatial_lang_problem()

    # add labeled points
    label = "$(round(1/length(locations_to_search), digits=2))"

    for spot in locations_to_search 
        center_shift = (spot.position.x, spot.position.y, spot.position.z) .* 1.5 .+ (1, 1, 1)
        final_position = (0.5,0.5,0.5) .+ center_shift
        # p = scatter!(p, final_position; c=:blue, ms=6, msw=0.1, grid=false, axis=([], false), legend=false)
        p = annotate!.(final_position[1], final_position[2], final_position[3], text.(label, :black, 10) )
    end

    if save_filepath != ""
        savefig(save_filepath)
    end

    return p
end