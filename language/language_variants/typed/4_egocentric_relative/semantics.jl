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

GeoBool(x::GeoBool) = GeoBool(x.val)
GeoBool(x::NonGeoBool) = GeoBool(x.val)
GeoBool(x::HybridBool) = GeoBool(x.val)

NonGeoBool(x::GeoBool) = NonGeoBool(x.val)
NonGeoBool(x::NonGeoBool) = NonGeoBool(x.val)
NonGeoBool(x::HybridBool) = NonGeoBool(x.val)

HybridBool(x::GeoBool) = HybridBool(x.val)
HybridBool(x::NonGeoBool) = HybridBool(x.val)
HybridBool(x::HybridBool) = HybridBool(x.val)

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
    HybridBool((prev(wall, locations).wall1.color == color1) & (next(wall, locations).wall2.color == color2))
end

# LoB: "between" language learned -- is this corner between walls with these colors?
function between(corner::Corner, color1::COLOR, color2::COLOR)::HybridBool
    HybridBool((corner.wall1.color == color1) & (corner.wall2.color == color2))
end