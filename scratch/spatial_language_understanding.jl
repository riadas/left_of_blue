
abstract type Location end

struct Position 
    x::Int 
    y::Int
    z::Int
end

struct Spot <: Location
    position::Position
end

mutable struct Scene
    locations::Vector{Location}
    prize::Location
end

# --- DEVELOPMENTAL STAGE 1 (GEOCENTRIC SPATIAL LANGUAGE) ---
# no spatial language

# --- DEVELOPMENTAL STAGE 2 (INSTRINSIC, EGOCENTRIC SPATIAL LANGUAGE) ---
# intrinsic "left" language learned; not meaningful when viewer can rotate, e.g. LoB environments
function left(location::Spot)
    location.position.x < 0
end

# intrinsic "right" language learned; not meaningful when viewer can rotate, e.g. LoB environments
function right(location::Spot)
    location.position.x > 0
end

# --- DEVELOPMENTAL STAGE 3 (RELATIVE, EGOCENTRIC SPATIAL LANGUAGE) ---
# relative "left" language learned
function left(location1::Spot, location2::Spot)
    location1.position.x < location2.position.x
end

# relative "right" language learned
function right(location1::Spot, location2::Spot)
    location1.position.x > location2.position.x
end

# --- DEFINE SCENE ---
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