abstract type Location end

struct Scene
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

# --- DEVELOPMENTAL STAGE 3 ---
# LoB: intrinsic "left" language learned
function left(location::Corner, facing::DEPTH)
    location.wall2.depth == facing
end

# LoB: intrinsic "right" language learned
function right(location::Corner, facing::DEPTH)
    location.wall1.depth == facing
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
# LoB: relative "left" language learned -- is this corner left of a wall with this color?
function left(corner::Corner, color::COLOR)
    corner.wall2.color == color
end

# LoB: relative "left" language learned -- is this wall left of a wall with this color?
function left(wall::Wall, color::COLOR, locations::Vector{Location})
    prev(wall, locations).wall1.color == color
end

# LoB: relative "right" language learned -- is this corner right of a wall with this color?
function right(corner::Corner, color::COLOR)
    corner.wall1.color == color
end

# LoB: relative "right" language learned -- is this wall right of a wall with this color?
function right(wall::Wall, color::COLOR, locations::Vector{Location})
    next(wall, locations).wall2.color == color
end

# spatial lang: relative "left" language learned
function left(location1::Spot, location2::Spot)
    location1.position.x < location2.position.x
end

# spatial lang: relative "right" language learned
function right(location1::Spot, location2::Spot)
    location1.position.x > location2.position.x
end

# --- AMBIGUOUS DEVELOPMENTAL STAGE: ORDER UNKNOWN ---
# LoB: "between" language learned -- is this wall between walls with these colors?
function between(wall::Wall, color1::COLOR, color2::COLOR, locations::Vector{Location})
    prev(wall, locations).wall1.color == color1 && next(wall, locations).wall2.color == color2
end

# LoB: "between" language learned -- is this corner between walls with these colors?
function between(corner::Corner, color1::COLOR, color2::COLOR)
    corner.wall1.color == color1 && corner.wall2.color == color2
end