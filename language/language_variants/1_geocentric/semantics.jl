
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