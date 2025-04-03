# import semantics

function generate_program(beacon; rect=true, blue=true)
    if beacon == Wall
        if rand() > 0.5
            if rect 
                choices = ["close", "far"]
            else
                choices = ["mid"]
            end
            return "location.depth == $(rand(choices))"
        else
            if blue 
                return "at(location, blue)"
            else
                return "at(location, white)"
            end
        end
    elseif beacon == Corner
        options = [1,2,3]
        option = rand(options)
        if option == 1
            direction_choices = ["left", "right"]
            if blue 
                color = "blue"
            else
                color = "white"
            end
            return "$(rand(direction_choices))(location, $(color))"
        elseif option == 2
            choices = [">", "<", "=="]
            return "location.wall1.depth $(rand(choices)) location.wall2.depth"
        else
            choices = ["left", "right"]
            if rect 
                facing_choices = ["close", "far"]
            else
                facing_choices = ["mid"]
            end
            return "$(rand(choices))(location, $(rand(facing_choices)))"
        end
    elseif beacon == Spot
        options = [1,2,3]
        option = rand(options)
        if option == 1 # relative left/right
            choices = ["left", "right"]
            return "$(rand(choices))(location, center)"
        elseif option == 2 # intrinsic left/right
            choices = ["left", "right"]
            return "$(rand(choices))(location)"
        else # default
            return "true"
        end
    else
        # throw error
    end
end