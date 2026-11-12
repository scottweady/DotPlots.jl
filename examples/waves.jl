# Open curves (`closed = false`) at several times, overlaid and coloured by time: a travelling wave sin(x − t) and
# a standing wave sin x cos t over one wavelength. DotPlots keeps the aspect ratio, so the waves are as flat as
# they are: amplitude 1 over a length 2π.
#   julia --project=examples examples/waves.jl             (from src/DotPlots)
using DotPlots

x = range(0, 2π, 200)
frame(y) = [collect(zip(x, y))]                          # one curve through the points (x[i], y[i])

t = range(0, π / 2, 5)
println("travelling wave sin(x − t)")
dotplot([frame(sin.(x .- s)) for s in t]; t, closed=false)

t = range(0, π, 5)
println("\nstanding wave sin x cos t")
dotplot([frame(sin.(x) .* cos(s)) for s in t]; t, closed=false)
