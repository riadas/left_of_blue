abstract type Location end

mutable struct Scene
    locations::Vector{Location}
    prize::Location
end

# --- LoB PROBLEM SPECIFICATION ---
@enum DEPTH close=5 mid=10 far=15
Base.:(+)(a::DEPTH, b::DEPTH) = Int(a) + Int(b)
Base.:(-)(a::DEPTH, b::DEPTH) = Int(a) - Int(b)
Base.:(*)(a::DEPTH, b::DEPTH) = Int(a) * Int(b)
Base.:(/)(a::DEPTH, b::DEPTH) = Int(a) / Int(b)

@enum COLOR white blue

Base.:(==)(a::DEPTH, b::DEPTH) = Int(a) == Int(b)
Base.:(!=)(a::DEPTH, b::DEPTH) = Int(a) != Int(b)
Base.:(>)(a::DEPTH, b::DEPTH) = Int(a) > Int(b)
Base.:(<)(a::DEPTH, b::DEPTH) = Int(a) < Int(b)
Base.:(==)(a::COLOR, b::COLOR) = Int(a) == Int(b)
Base.:(!=)(a::COLOR, b::COLOR) = Int(a) != Int(b)

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

# --- RED/GREEN PROBLEM SPECIFICATION
struct Half
    x::Int
end

struct Whole <: Location
    green::Half
    red::Half
    diagonal::Bool
end

# --- LIBRARY FUNCTIONS ---
# "primitive" prev function for traversing list of locations like a doubly linked list; given, not to be learned from data
function prev(location::Location, locations)
    index = first(findall(x -> x == location, locations))
    prev_index = (index - 2 + length(locations)) % length(locations) + 1
    locations[prev_index]
end

# "primitive" next function for traversing list of locations like a doubly linked list; given, not to be learned from data
function next(location::Location, locations)
    index = first(findall(x -> x == location, locations))
    next_index = index % length(locations) + 1
    locations[next_index]
end

# --- DEVELOPMENTAL STAGE 1 ---
# no wall color parameter in spatial memory; purely geometric
# --- new stage begins ---
function at(location_arg::Wall, color_arg::COLOR)::Bool
    location_arg.color == color_arg
end

function my_left(half_arg::Half)::Bool
    half_arg.x < 0
end

# --- new stage begins ---
function my_left(location_arg::Spot)::Bool
    location_arg.position.x < 0
end

function my_left(location_arg::Corner, depth_arg::DEPTH)::Bool
    location_arg.wall2.depth == depth_arg
end

function left_of(half1_arg::Half, half2_arg::Half)::Bool
    half2_arg.x > half1_arg.x
end

function left_of(location_arg::Corner, color_arg::COLOR)::Bool
    location_arg.wall2.color == color_arg
end

# --- new stage begins ---
function left_of(location1_arg::Spot, location2_arg::Spot)::Bool
    location2_arg.position.x > location1_arg.position.x
end
