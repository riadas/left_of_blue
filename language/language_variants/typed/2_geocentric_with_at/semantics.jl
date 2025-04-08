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