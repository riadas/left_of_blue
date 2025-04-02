
abstract type Location end

# --- LoB PROBLEM SPECIFICATION ---
@enum DEPTH close=5 mid=10 far=15
Base.:(+)(a::DEPTH, b::DEPTH) = Int(a) + Int(b)
Base.:(-)(a::DEPTH, b::DEPTH) = Int(a) - Int(b)
Base.:(*)(a::DEPTH, b::DEPTH) = Int(a) * Int(b)
Base.:(/)(a::DEPTH, b::DEPTH) = Int(a) / Int(b)

@enum COLOR white blue

mutable struct Wall <: Location
    depth::DEPTH
    color::COLOR
end

mutable struct Corner <: Location
    wall1::Wall
    wall2::Wall
end

struct Scene
    locations::Vector{Location}
    prize::Location
end

# --- SPATIAL LANG. UNDERSTANDING PROBLEM SPECIFICATION ---
struct Position 
    x::Int 
    y::Int
    z::Int
end

struct Spot <: Location
    position::Position
end

# --- DEVELOPMENTAL STAGE 1 ---
# no wall color parameter in spatial memory; purely geometric

# --- DEVELOPMENTAL STAGE 2 ---
# "at"/"in" language learned
function at(wall::Wall, color::COLOR)
    wall.color == color
end

# --- DEVELOPMENTAL STAGE 3 ---
# LoB: intrinsic "left" language learned
function left(location::Corner, facing::DEPTH)
    corner.wall2.depth == facing
end

# LoB: intrinsic "right" language learned
function right(location::Corner, facing::DEPTH)
    corner.wall1.depth == facing
end

# spatial lang: intrinsic "left" language learned; not meaningful when viewer can rotate, e.g. LoB environments
function left(location::Spot)
    location.position.x < 0
end

# spatial lang: intrinsic "right" language learned; not meaningful when viewer can rotate, e.g. LoB environments
function right(location::Spot)
    location.position.x > 0
end

# --- DEVELOPMENTAL STAGE 4 ---
# LoB: relative "left" language learned
function left(corner::Corner, color::COLOR)
    corner.wall2.color == color
end

# LoB: relative "right" language learned
function right(corner::Corner, color::COLOR)
    corner.wall1.color == color
end

# spatial lang: relative "left" language learned
function left(location1::Spot, location2::Spot)
    location1.position.x < location2.position.x
end

# spatial lang: relative "right" language learned
function right(location1::Spot, location2::Spot)
    location1.position.x > location2.position.x
end

# --- DEFINE LoB TEST SCENE ---
# rectangular room, with one small/far wall that is blue
wall1 = Wall(close, white)
wall2 = Wall(far, blue)
wall3 = Wall(close, white)
wall4 = Wall(far, white)

corner1 = Corner(wall1, wall2) # corner to the left of the blue wall
corner2 = Corner(wall2, wall3)
corner3 = Corner(wall3, wall4)
corner4 = Corner(wall4, wall1)

# left-to-right ordered list of walls and corners
locations = [wall1, corner1, wall2, corner2, wall3, corner3, wall4, corner4] 

scene = Scene(locations, corner1)

# --- SPATIAL MEMORY REPRESENTATIONS ---
# possible spatial memory representations (type check is auto-added, only second argument to && is user-generated)
program1 = location -> location isa Corner && location.wall1.depth / location.wall2.depth > 1 # at a corner with this macroscopic geometry
program2 = location -> location isa Wall && location.depth == close # at the center of a close wall
program3 = location -> location isa Wall && location.depth == far # at the center of a far wall
program4 = location -> location isa Wall && at(location, blue) # at the center of the blue wall
program5 = location -> location isa Corner && left(location, close) # to *my* left, when facing the close wall 
program6 = location -> location isa Corner && left(location, blue) # to the left of the blue wall

locations_to_search = filter(program1, scene.locations)
searched = rand(locations_to_search) # uniform sampling over filtered search locations

# --- DEFINE SPATIAL LANG TEST SCENE ---
# 3x3 cube of positions, excluding corners
center = Spot(Position(0, 0, 0))
spots = [Spot(Position(-1, 0, 0)), 
         Spot(Position(1, 0, 0)), 
         Spot(Position(0, 0, -1)), 
         Spot(Position(0, 0, 1)), 
         Spot(Position(0, -1, 0)), 
         Spot(Position(0, 1, 0))]

scene = Scene(spots, spots[1])

# --- PLoT translations of natural language / image inputs ---
program1 = location -> true # no understanding of left/right
program2 = location -> left(location) # "location is to my left"
program3 = location -> left(location, center) # "location is to the left of the center" 

locations_to_search = filter(program2, scene.locations)
searched = rand(locations_to_search) # uniform sampling over filtered search locations