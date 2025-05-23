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

# --- LIBRARY FUNCTIONS ---
# "primitive" prev function for traversing list of locations like a doubly linked list; given, not to be learned from data
function prev(location::Location, locations::Vector{Location})
    index = first(findall(x -> x == location, locations))
    prev_index = (index - 2 + length(locations)) % length(locations) + 1
    locations[prev_index]
end

# "primitive" next function for traversing list of locations like a doubly linked list; given, not to be learned from data
function next(location::Location, locations::Vector{Location})
    index = first(findall(x -> x == location, locations))
    next_index = index % length(locations) + 1
    locations[next_index]
end

# --- DEVELOPMENTAL STAGE 1 ---
# no wall color parameter in spatial memory; purely geometric

# --- DEVELOPMENTAL STAGE 2 ---
# "at"/"in" language learned
function at(wall::Wall, color::COLOR)
    wall.color == color
end