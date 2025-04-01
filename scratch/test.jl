
abstract type Location end

@enum DISTANCE close=5 mid=10 far=15
Base.:(+)(a::DISTANCE, b::DISTANCE) = Int(a) + Int(b)
Base.:(-)(a::DISTANCE, b::DISTANCE) = Int(a) - Int(b)
Base.:(*)(a::DISTANCE, b::DISTANCE) = Int(a) * Int(b)
Base.:(/)(a::DISTANCE, b::DISTANCE) = Int(a) / Int(b)

@enum COLOR white blue

struct Wall <: Location
    distance::DISTANCE
    color::COLOR
end

struct Corner <: Location
    wall1::Wall
    wall2::Wall
end

struct Scene
    locations::Vector{Location}
    prize::Location
end

# --- DEVELOPMENTAL STAGE 1 ---
# no wall color parameter in spatial memory; purely geometric

# --- DEVELOPMENTAL STAGE 2 ---
# "at"/"in" language learned
function at(wall::Wall, color::COLOR)
    wall.color == color
end

# --- DEVELOPMENTAL STAGE 3 ---
# intrinsic "left" language learned; not meaningful when viewer can rotate, e.g. LoB environments
function left(location::Union{Wall, Corner})
    true
end

# intrinsic "right" language learned; not meaningful when viewer can rotate, e.g. LoB environments
function right(location::Union{Wall, Corner})
    true
end

# --- DEVELOPMENTAL STAGE 4 ---
# relative "left" language learned
function left(corner::Corner, color::COLOR)
    corner.wall2.color == color
end

# relative "right" language learned
function right(corner::Corner, color::COLOR)
    corner.wall1.color == color
end

# --- DEFINE SCENE ---
# rectangular room, with one small/far wall that is blue
wall1 = Wall(close, white)
wall2 = Wall(far, blue)
wall3 = Wall(close, white)
wall4 = Wall(far, white)
walls = [wall1, wall2, wall3, wall4]

corner1 = Corner(wall1, wall2) # corner to the left of the blue wall
corner2 = Corner(wall2, wall3)
corner3 = Corner(wall3, wall4)
corner4 = Corner(wall4, wall1)
corners = [corner1, corner2, corner3, corner4]

locations = [walls..., corners...]
scene = Scene(locations, corner1)

# --- SPATIAL MEMORY REPRESENTATIONS ---
# possible spatial memory representations (type check is auto-added, only second argument to && is user-generated)
program1 = location -> location isa Corner && location.wall1.distance / location.wall2.distance > 1 # at a corner with this macroscopic geometry
program2 = location -> location isa Wall && location.distance == close # at the center of a close wall
program3 = location -> location isa Wall && location.distance == far # at the center of a far wall
program4 = location -> location isa Wall && at(location, blue) # at the center of the blue wall
program5 = location -> location isa Corner && left(location, blue) # left of the blue wall

locations_to_search = filter(program1, scene.locations)
searched = rand(locations_to_search) # uniform sampling over filtered search locations