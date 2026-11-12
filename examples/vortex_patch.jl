# Kirchhoff's elliptical vortex: a patch of uniform vorticity ω with semi-axes a and b keeps its shape and turns
# at Ω = ωab/(a + b)² (Lamb 1932, §159). Five snapshots over a quarter turn, overlaid and coloured by time; at an
# interactive terminal they are played first.
#   julia --project=examples examples/vortex_patch.jl      (from src/DotPlots)
using DotPlots

ω, a, b = 1.0, 1.5, 0.5
Ω = ω * a * b / (a + b)^2
ellipse(φ) = [reim(cis(φ) * complex(a * cos(s), b * sin(s))) for s in range(0, 2π, 200)]   # turned by φ

t = range(0, π / 2Ω, 5)
println("Ω = ", Ω, ", a quarter turn by t = ", round(t[end]; sigdigits=4))
dotplot([[ellipse(Ω * s)] for s in t]; t, maxheight=20, animate=true)
