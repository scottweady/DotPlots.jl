# A spirograph (hypotrochoid): a pen at distance d from the centre of a wheel of radius r rolling inside a ring of
# radius R. The curve is drawn in eight pieces, one per frame, so the overlay colours it by when each piece was
# traced (t in turns of the wheel's centre), and at an interactive terminal it is played piece by piece.
#   julia --project=examples examples/spirograph.jl        (from src/DotPlots)
using DotPlots

R, r, d = 8, 5, 5
pen(s) = ((R - r) * cos(s) + d * cos((R - r) / r * s), (R - r) * sin(s) - d * sin((R - r) / r * s))
turns = r ÷ gcd(R, r)                                    # the curve closes after this many turns
t = range(0, turns, 9)
pieces = [[[pen(2π * s) for s in range(t[k], t[k+1], 100)]] for k in 1:8]
dotplot(pieces; t=t[2:end], closed=false, maxheight=24, animate=true)
println()
