abstract type Location end

mutable struct Scene
    locations::Vector{Location}
    prize::Location
    utterance::String
end

Scene(locations, prize) = Scene(locations, prize, "")

# --- LoB PROBLEM SPECIFICATION ---
@enum DEPTH close=5 mid=10 far=15
Base.:(+)(a::DEPTH, b::DEPTH) = Int(a) + Int(b)
Base.:(-)(a::DEPTH, b::DEPTH) = Int(a) - Int(b)
Base.:(*)(a::DEPTH, b::DEPTH) = Int(a) * Int(b)
Base.:(/)(a::DEPTH, b::DEPTH) = Int(a) / Int(b)

@enum COLOR white blue red

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

mutable struct SpecialCorner <: Location 
    wall1::Wall 
    wall2::Wall 
    color::COLOR
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
    coral::Half
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

# lower-level coord interface, not to be learned from data
function coord(location::Spot)
    location.position.x
end

function coord(location::Half)
    location.x
end

function coord(location::Whole)
    (location.coral.x + location.green.x) / 2
end

# coordinates are relative, in the LoB setting
function coord(location1::Union{Wall, Corner}, location2::Union{Wall, Corner}, locations::Vector{Union{Wall, Corner}})
    # second location is reference location; count # of prev's versus next's to reach location1 from location2, and
    # the signed count with minimum absolute value
    index1 = first(findall(x -> x == location1, locations))
    index2 = first(findall(x -> x == location2, locations))

    index1 - index2
end

# --- DEVELOPMENTAL STAGE 1 ---
# no wall color parameter in spatial memory; purely geometric
function at(location_arg::Wall, color_arg::COLOR)::Bool
    prev(location_arg, locations).wall1.color == color_arg
end

function my_left(location_arg::Spot)::Bool
    location_arg.position.x < 0
end

function left_of(location_arg::Corner, color_arg::COLOR)::Bool
    location_arg.wall2.color == color_arg
end
