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
            return "location.distance == $(rand(choices))"
        else
            choices = ["white", "blue"]
            return "at(location, $(rand(choices)))"
        end
    elseif beacon == Corner
        choices = [">", "<", "=="]
        return "location.wall1.distance / location.wall2.distance $(rand(choices)) 1"
    elseif beacon == Spot 
        return "true"
    else
        # throw error
    end
end