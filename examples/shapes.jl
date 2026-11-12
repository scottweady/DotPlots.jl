# Single pictures of plane curves, at their true aspect ratio (a Braille dot is about square). A curve given as x
# and y vectors is `dotplot(x, y)`; θ runs to 2π, so each curve ends where it starts. Several curves in one
# picture, a disc with two holes, are one frame of curves.
#   julia --project=examples examples/shapes.jl            (from src/DotPlots)
using DotPlots

θ = range(0, 2π, 400)
rose, cardioid, lemniscate = cos.(3θ), 1 .- cos.(θ), 1 .+ sin.(θ) .^ 2
shapes = [
    "ellipse, 2:1"     => (2cos.(θ), sin.(θ)),
    "three-petal rose" => (rose .* cos.(θ), rose .* sin.(θ)),
    "cardioid"         => (cardioid .* cos.(θ), cardioid .* sin.(θ)),
    "lemniscate"       => (cos.(θ) ./ lemniscate, sin.(θ) .* cos.(θ) ./ lemniscate),
]
for (name, (x, y)) in shapes
    println(name)
    dotplot(x, y; width=40, maxheight=12)
    println()
end

circle(x0, y0, ρ) = [(x0 + ρ * cos(s), y0 + ρ * sin(s)) for s in θ]
println("a disc with two holes")
dotplot([[circle(0, 0, 1), circle(-0.4, 0.1, 0.3), circle(0.45, -0.2, 0.2)]]; width=40, maxheight=12)
