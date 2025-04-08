# abstract scene representation -- specializes to different input spatial reasoning problems
abstract type Location end

mutable struct Scene
    locations::Vector{Location}
    prize::Location
end

# typed booleans for distinguishing geometric, non-geometric, and hybrid predicates
abstract type TypedBool end

struct GeoBool <: TypedBool
    val::Bool
end

struct NonGeoBool <: TypedBool 
    val::Bool
end

struct HybridBool <: TypedBool 
    val::Bool
end

## conjunction of the same categories doesn't change the category
Base.:(&)(a::GeoBool, b::GeoBool) = GeoBool(a.val & b.val)
Base.:(&)(a::NonGeoBool, b::NonGeoBool) = NonGeoBool(a.val & b.val)
Base.:(&)(a::HybridBool, b::HybridBool) = HybridBool(a.val & b.val)

## mixing categories always results in hybrid bool
Base.:(&)(a::GeoBool, b::NonGeoBool) = HybridBool(a.val & b.val)
Base.:(&)(a::NonGeoBool, b::GeoBool) = HybridBool(a.val & b.val)
Base.:(&)(a::HybridBool, b::GeoBool) = HybridBool(a.val & b.val)
Base.:(&)(a::HybridBool, b::NonGeoBool) = HybridBool(a.val & b.val)
Base.:(&)(a::GeoBool, b::HybridBool) = HybridBool(a.val & b.val)
Base.:(&)(a::NonGeoBool, b::HybridBool) = HybridBool(a.val & b.val)

# --- LoB PROBLEM SPECIFICATION ---
## coarsification of depths of walls (i.e. distances from viewer facing walls)
@enum DEPTH close=5 mid=10 far=15
Base.:(+)(a::DEPTH, b::DEPTH) = Int(a) + Int(b)
Base.:(-)(a::DEPTH, b::DEPTH) = Int(a) - Int(b)
Base.:(*)(a::DEPTH, b::DEPTH) = Int(a) * Int(b)
Base.:(/)(a::DEPTH, b::DEPTH) = Int(a) / Int(b)

## colors
@enum COLOR white blue

## comparisons of depths is geometric information
Base.:(==)(a::DEPTH, b::DEPTH) = GeoBool(Int(a) == Int(b))
Base.:(!=)(a::DEPTH, b::DEPTH) = GeoBool(Int(a) != Int(b))
Base.:(>)(a::DEPTH, b::DEPTH) = GeoBool(Int(a) > Int(b))
Base.:(<)(a::DEPTH, b::DEPTH) = GeoBool(Int(a) < Int(b))

## comparisons of colors is non-geometric information
Base.:(==)(a::COLOR, b::COLOR) = NonGeoBool(Int(a) == Int(b))
Base.:(!=)(a::COLOR, b::COLOR) = NonGeoBool(Int(a) != Int(b))

## types of locations in LoB setting
mutable struct Wall <: Location
    depth::DEPTH
    color::COLOR
end

mutable struct Corner <: Location
    wall1::Wall
    wall2::Wall
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

# --- LIBRARY FUNCTIONS ---
# "primitive" prev function for traversing list of locations like a doubly linked list; given, not to be learned from data
function prev(location::Location, locations::Vector{Location})::Location
    index = first(findall(x -> x == location, locations))
    prev_index = (index - 2 + length(locations)) % length(locations) + 1
    locations[prev_index]
end

# "primitive" next function for traversing list of locations like a doubly linked list; given, not to be learned from data
function next(location::Location, locations::Vector{Location})::Location
    index = first(findall(x -> x == location, locations))
    next_index = index % length(locations) + 1
    locations[next_index]
end

# --- DEVELOPMENTAL STAGE 1 ---
# no wall color parameter in spatial memory; purely geometric

# --- DEVELOPMENTAL STAGE 2 ---
# "at"/"in" language learned
function at(wall::Wall, color::COLOR)::HybridBool
    HybridBool(wall.color == color)
end

# --- DEVELOPMENTAL STAGE 3 ---
# LoB: intrinsic "left" language learned
function left(location::Corner, facing::DEPTH)::GeoBool
    GeoBool(location.wall2.depth == facing)
end

# LoB: intrinsic "right" language learned
function right(location::Corner, facing::DEPTH)::GeoBool
    GeoBool(location.wall1.depth == facing)
end

# spatial lang: intrinsic "left" language learned; not meaningful when viewer can rotate, e.g. LoB environments
function left(location::Spot)::GeoBool
    GeoBool(location.position.x < 0)
end

# spatial lang: intrinsic "right" language learned; not meaningful when viewer can rotate, e.g. LoB environments
function right(location::Spot)::GeoBool
    GeoBool(location.position.x > 0)
end

# --- DEVELOPMENTAL STAGE 4 ---
# LoB: relative "left" language learned -- is this corner left of a wall with this color?
function left(corner::Corner, color::COLOR)::HybridBool
    HybridBool(corner.wall2.color == color)
end

# LoB: relative "left" language learned -- is this wall left of a wall with this color?
function left(wall::Wall, color::COLOR, locations::Vector{Location})::HybridBool
    HybridBool(prev(wall, locations).wall1.color == color)
end

# LoB: relative "right" language learned -- is this corner right of a wall with this color?
function right(corner::Corner, color::COLOR)::HybridBool
    HybridBool(corner.wall1.color == color)
end

# LoB: relative "right" language learned -- is this wall right of a wall with this color?
function right(wall::Wall, color::COLOR, locations::Vector{Location})::HybridBool
    HybridBool(next(wall, locations).wall2.color == color)
end

# spatial lang: relative "left" language learned
function left(location1::Spot, location2::Spot)::GeoBool
    GeoBool(location1.position.x < location2.position.x)
end

# spatial lang: relative "right" language learned
function right(location1::Spot, location2::Spot)::GeoBool
    GeoBool(location1.position.x > location2.position.x)
end

# --- AMBIGUOUS DEVELOPMENTAL STAGE: ORDER UNKNOWN ---
# LoB: "between" language learned -- is this wall between walls with these colors?
function between(wall::Wall, color1::COLOR, color2::COLOR, locations::Vector{Location})::HybridBool
    HybridBool(prev(wall, locations).wall1.color == color1 && next(wall, locations).wall2.color == color2)
end

# LoB: "between" language learned -- is this corner between walls with these colors?
function between(corner::Corner, color1::COLOR, color2::COLOR)::HybridBool
    HybridBool(corner.wall1.color == color1 && corner.wall2.color == color2)
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
program1 = location -> location isa Corner && (location.wall1.depth > location.wall2.depth).val # at a corner with this macroscopic geometry
program2 = location -> location isa Wall && (location.depth == close).val # at the center of a close wall
program3 = location -> location isa Wall && (location.depth == far).val # at the center of a far wall
program4 = location -> location isa Wall && (at(location, blue)).val # at the center of the blue wall
program5 = location -> location isa Corner && (left(location, close)).val # to *my* left, when facing the close wall 
program6 = location -> location isa Corner && (left(location, blue)).val # to the left of the blue wall
program7 = location -> location isa Wall && (between(location, blue, blue, locations)).val # between two blue walls
program8 = location -> location isa Wall && (between(location, blue, white, locations)).val # between blue wall and white wall (order matters! TODO: consider adding 'or' so it doesn't matter)
program9 = location -> location isa Corner && (between(location, blue, white)).val # between blue wall and white wall (order matters! TODO: consider adding 'or' so it doesn't matter)

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
program2 = location -> left(location).val # "location is to my left"
program3 = location -> left(location, center).val # "location is to the left of the center" 

locations_to_search = filter(program2, scene.locations)
searched = rand(locations_to_search) # uniform sampling over filtered search locations