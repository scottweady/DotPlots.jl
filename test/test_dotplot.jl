# The plot window, the Braille dots, the time colours, the plot and its animation, on made-up curves: an ellipse
# with a circular hole, turning over five times (points as tuples), and the unit square.
using Test, DotPlots
using DotPlots: closecurves, box, raster, markpoints!, markershape, drawgrid, timestops, timecolour, timecode, isterminal, play,
                TIME_LIGHT, TIME_DARK, TIME_EITHER

ring(a, b, φ; n=64) = [(a * cos(s) * cos(φ) - b * sin(s) * sin(φ), a * cos(s) * sin(φ) + b * sin(s) * cos(φ))
                       for s in range(0, 2π; length=n + 1)[1:n]]
t = collect(range(0, 1; length=5))
frames = [[ring(1.5, 0.75, s), ring(0.3, 0.3, 0.0)] for s in t]
square = [[(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)]]

@testset "window" begin
    c = closecurves(frames)
    @test length(c) == 5 && all(length(z) == 65 && z[end] == z[1] for z in c[1])
    b = box(closecurves([square]))
    @test b.width == 60 && b.x0 < 0 < 1 < b.x1 && b.y0 < 0 < 1 < b.y1
    @test abs(b.height - 30) ≤ 1                                     # square in dots: 2 × 60 wide, 4 × 30 high
    @test (b.y1 - b.y0) ≈ 4b.height * b.h                            # the window is a whole number of lines
    tall = [[ring(0.5, 1.0, 0.0)]]
    bt = box(tall; maxheight=16)
    @test bt.height ≤ 16 && bt.width < 60                            # narrower to stay within maxheight
    @test b.hy == b.h                                                # one scale for x and y
    bf = box(closecurves([square]); width=40, height=7)              # or each to fill width × height
    @test bf.width == 40 && bf.height == 7 && bf.h ≈ (bf.x1 - bf.x0) / 80 && bf.hy ≈ (bf.y1 - bf.y0) / 28
    @test box(closecurves([square]); width=40, height=7, maxheight=5).height == 5
end

@testset "dots" begin
    grid, frame = raster(closecurves([square]), box(closecurves([square]); width=20))
    rows, cols = extrema(i -> i[1], findall(!iszero, grid)), extrema(i -> i[2], findall(!iszero, grid))
    (r1, r2), (c1, c2) = rows, cols
    @test all(!iszero, grid[r1, c1:c2]) && all(!iszero, grid[r2, c1:c2])   # the outline of the square
    @test all(!iszero, grid[r1:r2, c1]) && all(!iszero, grid[r1:r2, c2])
    @test all(iszero, grid[r1+1:r2-1, c1+1:c2-1])                          # and nothing inside
    @test all(frame[grid .!= 0] .== 1) && all(frame[grid .== 0] .== 0)
    two = closecurves([square, [[(0.25, 0.25), (0.75, 0.25), (0.75, 0.75), (0.25, 0.75)]]])
    _, owner = raster(two, box(two; width=20))
    @test sort(unique(owner)) == [0, 1, 2]                                  # the last frame to touch a character
    seg = [[[(0.0, 0.0), (1.0, 0.0)]]]                                      # an open curve: both ends drawn
    gs, _ = raster(seg, box(seg; width=20, height=1))
    @test gs[1, 1] != 0 && gs[1, 20] != 0
    out = sprint(io -> drawgrid(io, grid, frame, nothing))
    @test length(split(out, '\n'; keepempty=false)) == size(grid, 1) + 2
    @test all(length(l) == size(grid, 2) + 2 for l in split(out, '\n'; keepempty=false))
end

@testset "colours" begin
    withenv("COLORFGBG" => "0;15") do; @test timestops() === TIME_LIGHT; end
    withenv("COLORFGBG" => "15;0") do; @test timestops() === TIME_DARK; end
    withenv("COLORFGBG" => "15;default") do; @test timestops() === TIME_EITHER; end
    withenv("COLORFGBG" => nothing) do; @test timestops() === TIME_EITHER; end
    @test timecolour(0; stops=TIME_LIGHT, truecolor=true) == "\e[38;2;79;70;229m"
    @test timecolour(1; stops=TIME_DARK, truecolor=true) == "\e[38;2;240;84;112m"
    @test timecolour(0; stops=TIME_LIGHT, truecolor=false) == "\e[38;5;63m"  # nearest of the 6 × 6 × 6 cube
    @test timecolour(-1; stops=TIME_LIGHT, truecolor=true) == timecolour(0; stops=TIME_LIGHT, truecolor=true)
    withenv("COLORTERM" => "truecolor", "COLORFGBG" => nothing) do
        code = timecode(5)
        @test code(1) == timecolour(0; stops=TIME_EITHER, truecolor=true)
        @test code(5) == timecolour(1; stops=TIME_EITHER, truecolor=true)
    end
end

@testset "plot" begin
    plain = sprint(io -> dotplot(io, frames; t))
    @test !occursin('\e', plain) && occursin(" x ∈ [", plain)
    @test !occursin('\e', sprint(io -> dotplot(io, frames); context=:color => true))  # no times, no colour
    col = sprint(io -> dotplot(io, frames; t); context=:color => true)
    @test occursin("\e[38;", col) && count("■", col) == 5 && occursin("\n t: ", col)
    @test sprint(io -> dotplot(io, frames; t, every=2)) == sprint(io -> dotplot(io, frames[1:2:end]; t=t[1:2:end]))
    @test sprint(io -> dotplot(io, frames[1:1])) == sprint(io -> dotplot(io, frames[1:1]; t=t[1:1]); context=:color => true)
    open_ = [[(0.0, 0.0), (1.0, 0.0), (1.0, 1.0)]]
    @test sprint(io -> dotplot(io, [open_]; closed=false)) != sprint(io -> dotplot(io, [open_]))
    @test sprint(io -> dotplot(io, [open_])) == sprint(io -> dotplot(io, closecurves([open_]); closed=false))
    @test occursin("─"^40 * "┐", sprint(io -> dotplot(io, frames; width=40)))
    # two vectors of numbers: one open curve, closed on request
    x = range(0, 1, 10); y = x .^ 2
    @test sprint(io -> dotplot(io, x, y)) == sprint(io -> dotplot(io, [[collect(zip(x, y))]]; closed=false))
    @test sprint(io -> dotplot(io, x, y; closed=true, width=30)) == sprint(io -> dotplot(io, [[collect(zip(x, y))]]; width=30))
    @test_throws DimensionMismatch dotplot(IOBuffer(), x, y[1:end-1])
    # one vector: against its index, in a width × width ÷ 4 box
    @test sprint(io -> dotplot(io, y)) == sprint(io -> dotplot(io, 1:length(y), y; height=15))
    out = sprint(io -> dotplot(io, (1:10) .^ 2; width=40))
    @test countlines(IOBuffer(out)) == 10 + 3 && endswith(out, '\n')   # the frame, 10 lines and the ranges, a line each
    @test occursin("y ∈ [2.5, 3.5]", sprint(io -> dotplot(io, fill(3.0, 5))))   # a constant: ±0.5
end

@testset "log scale" begin
    x = exp10.(range(0, 3, 50)); y = x .^ 2
    plot(f) = split(sprint(f), '\n')[1:end-2]                 # the frame, without the ranges
    # the dots of the logs on linear axes, the ranges in the data's units
    @test plot(io -> dotplot(io, x, y; xscale=:log, yscale=:log)) == plot(io -> dotplot(io, log10.(x), log10.(y)))
    out = sprint(io -> dotplot(io, x, y; xscale=:log, yscale=:log))
    @test endswith(out, " x ∈ [0.575, 1740.0] (log),  y ∈ [0.565, 1.77e6] (log)\n")   # 4% of 6 decades each side
    # one log axis: x and y scaled separately, width × width ÷ 4 unless a height is given
    @test plot(io -> dotplot(io, log10.(x), y; yscale=:log, width=40)) == plot(io -> dotplot(io, log10.(x), log10.(y); width=40, height=10))
    @test countlines(IOBuffer(sprint(io -> dotplot(io, x, y; xscale=:log, height=6)))) == 6 + 3
    @test endswith(rstrip(sprint(io -> dotplot(io, 1:10, x[1:10]; yscale=:log))), "(log)")
    @test_throws DomainError dotplot(IOBuffer(), [1.0, 0.0, 2.0], [1.0, 2.0, 3.0]; xscale=:log)
    @test_throws DomainError dotplot(IOBuffer(), [-1.0, 2.0]; yscale=:log)
    @test_throws ArgumentError dotplot(IOBuffer(), x, y; xscale=:log2)
    @test sprint(io -> dotplot(io, x, y; xscale=:linear, yscale=:linear)) == sprint(io -> dotplot(io, x, y))
    # the frames method, with times: as before apart from the scale
    fl = [[[(exp10(p[1]), exp10(p[2])) for p in z] for z in curves] for curves in frames]
    @test plot(io -> dotplot(io, fl; t, xscale=:log, yscale=:log)) == plot(io -> dotplot(io, frames; t))
end

@testset "markers" begin
    x = 1:8; y = [1, 4, 2, 5, 3, 6, 2, 4]                     # points a few characters apart
    pts = [[collect(zip(x, y))]]
    # a shape in dots, centred on each point's dot, the inside of an open one cleared
    o = markershape(:o)
    @test markershape(:circle) == o && o.radius == 2 && length(o.set) == 12 && length(o.clear) == 9
    @test (0, 0) in o.clear && (0, 0) in markershape(:x).set && (0, 0) in markershape(:dot).set
    @test markershape(:x) == markershape(:xcross) && markershape(:+) == markershape(:cross)
    @test markershape('#') == '#'
    @test_throws ArgumentError markershape(:foo)
    @test_throws ArgumentError markershape('界')                # two columns wide
    @test_throws ArgumentError dotplot(IOBuffer(), x, y; marker=:foo)
    b = box(pts; width=40, height=8, margin=2)
    grid, frame = raster(pts, b); bare = copy(grid)
    markpoints!(grid, frame, pts, b, o)
    bit(g, (i, j)) = g[j÷4+1, i÷2+1] & DotPlots.BRAILLE[j%4+1][i%2+1] != 0
    for p in pts[1][1]
        i, j = DotPlots.dot(p, b)
        @test bit(bare, (i, j)) && !bit(grid, (i, j))            # the curve through the point, cleared inside
        @test all(bit(grid, (i + di, j + dj)) for (di, dj) in o.set)
    end
    # the window has room for the marker at the edges
    b0 = box(pts; width=40, height=8)
    @test b.x0 < b0.x0 && b.x1 > b0.x1 && b.y0 < b0.y0 && b.y1 > b0.y1
    @test all(2 ≤ i < 2b.width - 2 && 2 ≤ j < 4b.height - 2 for (i, j) in DotPlots.dot.(pts[1][1], Ref(b)))
    @test box(pts; width=40) == box(pts; width=40, margin=0)
    # through dotplot: as the pieces draw it, below the window with the margin
    out = sprint(io -> dotplot(io, x, y; marker=:o, width=40, height=8))
    @test out == sprint(io -> drawgrid(io, grid, frame, nothing)) * " x ∈ [0.516, 8.48],  y ∈ [0.435, 6.56]\n"
    @test sprint(io -> dotplot(io, x, y; marker=:none)) == sprint(io -> dotplot(io, x, y))
    @test sprint(io -> dotplot(io, x, y; marker=:x)) != sprint(io -> dotplot(io, x, y; marker=:o))
    # a Char marker: in place of the character holding the point
    out = sprint(io -> dotplot(io, x, y; marker='#', width=40, height=8))
    @test count('#', out) == 8 && occursin(r"[\u2801-\u28ff]", out)
    # each marker in the colour of its frame, a Char one too
    col = sprint(io -> dotplot(io, frames; t, marker=:o); context=:color => true)
    @test col != sprint(io -> dotplot(io, frames; t); context=:color => true) && occursin("\e[38;", col)
    col = sprint(io -> dotplot(io, frames; t, marker='o'); context=:color => true)
    @test occursin(r"\e\[38;[0-9;]*mo\e\[39m", col) && !occursin(r"[^m]o\e", col)
    # in a terminal it all still fits, and the animation draws the markers
    for (rows, cols) in ((24, 80), (15, 40))
        out = replace(sprint(io -> dotplot(io, frames; t, marker=:o); context=(:displaysize => (rows, cols), :color => true)),
                      r"\e\[[0-9;]*m" => "")
        @test countlines(IOBuffer(out)) ≤ rows - 2 && all(textwidth(l) ≤ cols for l in split(out, '\n'))
    end
    c = closecurves(frames)
    io = IOContext(IOBuffer(), :displaysize => (40, 100))
    play(io, c, t; marker='o', duration=0.2)
    @test count('o', String(take!(io.io))) > 0
end

@testset "fit" begin
    # in a terminal, or with a :displaysize, all of it fits, with two lines to spare for the REPL's blank line and
    # prompt: the frame, the ranges (on two lines when they are too wide) and the legend (wrapped)
    visible(s) = replace(s, r"\e\[[0-9;]*m" => "")
    function fits(rows, cols, f)
        out = visible(sprint(f; context=(:displaysize => (rows, cols), :color => true)))
        countlines(IOBuffer(out)) ≤ rows - 2 && all(textwidth(l) ≤ cols for l in split(out, '\n'))
    end
    many = [[ring(1.5, 0.75, s), ring(0.3, 0.3, 0.0)] for s in range(0, 1, 21)]; tm = range(0, 10, 21)
    for (rows, cols) in ((24, 80), (24, 100), (15, 40), (40, 30), (60, 200))
        @test fits(rows, cols, io -> dotplot(io, frames; t))
        @test fits(rows, cols, io -> dotplot(io, many; t=tm))                   # a legend over several lines
        @test fits(rows, cols, io -> dotplot(io, (1:10) .^ 2))                  # x and y scaled separately
        @test fits(rows, cols, io -> dotplot(io, exp10.(1:5), 1:5; xscale=:log, width=200))
        @test fits(rows, cols, io -> dotplot(io, frames; t, width=500, maxheight=500))
    end
    out = visible(sprint(io -> dotplot(io, many; t=tm); context=(:displaysize => (24, 40), :color => true)))
    @test count(startswith(" t: "), split(out, '\n')) == 1 && count(startswith("    ■"), split(out, '\n')) ≥ 2
    out = sprint(io -> dotplot(io, frames; t); context=:displaysize => (24, 30))
    @test occursin("]\n y ∈", out)                                              # the ranges on two lines
    # a plot that already fits is unchanged
    @test sprint(io -> dotplot(io, frames; t, width=30); context=:displaysize => (60, 200)) ==
          sprint(io -> dotplot(io, frames; t, width=30))
end

@testset "animation" begin
    @test !isterminal(IOBuffer()) && !isterminal(IOContext(IOBuffer(), :color => true))
    # off a terminal the plot is unchanged
    @test sprint(io -> dotplot(io, frames; t, animate=true)) == sprint(io -> dotplot(io, frames; t))
    # played in place, one frame per time, then cleared
    io = IOContext(IOBuffer(), :displaysize => (40, 100), :color => true)
    c = closecurves(frames)
    play(io, c, t; duration=0.2)
    out = String(take!(io.io)); b = box(c)
    @test count("┌", out) == length(t) && count("\e[$(b.height + 2)A", out) == length(t)
    @test startswith(out, "\e[?25l") && endswith(out, "\e[J\e[?25h")
    # nothing when the window does not fit
    small = IOContext(IOBuffer(), :displaysize => (5, 20))
    play(small, c, t; duration=0.2)
    @test isempty(take!(small.io))
end
