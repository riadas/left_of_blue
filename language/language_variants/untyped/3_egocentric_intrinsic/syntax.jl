# import semantics
include("semantics.jl")

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
        if rand() > 0.5 
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
        if rand() > 0.5
            choices = ["left", "right"]
            return "$(rand(choices))(location)"
        else
            return "true"   
        end
    else
        # throw error
    end
end