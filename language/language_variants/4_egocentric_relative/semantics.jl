
abstract type Location end

# --- LoB ---
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

# --- spatial lang test ---
struct Position 
    x::Int 
    y::Int
    z::Int
end

struct Spot <: Location
    position::Position
end

# --- LIBRARY FUNCTIONS ---

# --- DEVELOPMENTAL STAGE 1 ---
# no wall color parameter in spatial memory; purely geometric

# --- DEVELOPMENTAL STAGE 2 ---
# "at"/"in" language learned
function at(wall::Wall, color::COLOR)
    wall.color == color
end

# --- DEVELOPMENTAL STAGE 3 ---
# LoB: intrinsic "left" language learned; not meaningful when viewer can rotate, e.g. LoB environments
function left(location::Union{Wall, Corner})
    true
end

# LoB: intrinsic "right" language learned; not meaningful when viewer can rotate, e.g. LoB environments
function right(location::Union{Wall, Corner})
    true
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