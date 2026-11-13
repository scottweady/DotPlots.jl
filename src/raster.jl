# The plot window around the frames, the Braille dots of the curves in it, and the framed grid of characters.

const BRAILLE = ((0x01, 0x08), (0x02, 0x10), (0x04, 0x20), (0x40, 0x80))   # dot bits by (row, column)

"""Each curve of each frame with its first point appended at the end."""
closecurves(frames) = [[[z; z[1:1]] for z in curves] for curves in frames]

"""
The plot window around all the frames: corners, dot width `h` and height `hy`, and size in characters. One scale
for x and y (`hy = h`, shapes keep their aspect ratio) unless `height` is given: then x and y are scaled
separately to fill `width` × `height` characters (at most `maxheight` lines). With a `margin`, about that many
dots more on each side, for the markers.
"""
function box(frames; width::Integer=60, maxheight=nothing, height=nothing, margin::Integer=0)
    pts = reduce(vcat, reduce(vcat, frames))
    (x0, x1), (y0, y1) = extrema(p -> p[1], pts), extrema(p -> p[2], pts)
    b = box(x0, x1, y0, y1; width, maxheight, height)
    margin == 0 && return b
    box(x0 - margin * b.h, x1 + margin * b.h, y0 - margin * b.hy, y1 + margin * b.hy; width, maxheight, height)
end

function box(x0, x1, y0, y1; width, maxheight, height)
    if height !== nothing
        height = max(1, maxheight === nothing ? height : min(height, maxheight))
        (x0, x1), (y0, y1) = padrange(x0, x1), padrange(y0, y1)
        return (; x0, x1, y0, y1, h=(x1 - x0) / 2width, hy=(y1 - y0) / 4height, width, height)
    end
    pad = 0.04 * max(x1 - x0, y1 - y0); x0 -= pad; x1 += pad; y0 -= pad; y1 += pad
    aspect = (y1 - y0) / (x1 - x0)                           # lines per character of width: aspect / 2
    maxheight === nothing || (width = max(10, min(width, floor(Int, 2maxheight / aspect))))
    h = (x1 - x0) / 2width                                   # dot size
    height = max(1, ceil(Int, (y1 - y0) / h / 4))
    yc = (y0 + y1) / 2; y0, y1 = yc - 2height * h, yc + 2height * h   # centre vertically
    (; x0, x1, y0, y1, h, hy=h, width, height)
end

"""The range [a, b] padded by 4% on each side, or ±0.5 around a single value."""
padrange(a, b) = (d = b > a ? 0.04 * (b - a) : 0.5; (a - d, b + d))

"""Braille dots of the frames in the box `b`, and the last frame to touch each character."""
function raster(frames, b)
    (; h, hy, width, height) = b
    grid = zeros(UInt8, height, width); frame = zeros(Int, height, width)
    plot!(p, f) = ((i, j) = dot(p, b); grid[j÷4+1, i÷2+1] |= BRAILLE[j%4+1][i%2+1]; frame[j÷4+1, i÷2+1] = f)
    for (f, curves) in enumerate(frames), z in curves
        for k in 1:length(z)-1
            a, c = z[k], z[k+1]; dx, dy = c[1] - a[1], c[2] - a[2]
            m = max(1, ceil(Int, 2sqrt(dx^2 + (dy * h / hy)^2) / h))    # two samples per dot along the segment
            for s in 0:m-1
                plot!((a[1] + (s / m) * dx, a[2] + (s / m) * dy), f)
            end
        end
        isempty(z) || plot!(z[end], f)                               # and the end of the last segment
    end
    grid, frame
end

"""The dots by which a marker reaches past its point: its radius, and none for a character or no marker."""
markerradius(m) = m isa NamedTuple ? m.radius : 0

"""The dot (column i, row j, from 0 at the top left) of the point `p` in the box `b`."""
dot(p, b) = (clamp(floor(Int, (p[1] - b.x0) / b.h), 0, 2b.width - 1), clamp(floor(Int, (b.y1 - p[2]) / b.hy), 0, 4b.height - 1))

# Marker shapes in dots, centred on the point's dot: '#' a dot, '-' a dot cleared (the inside of an open shape,
# so the curve does not run through it), '.' left as it is.
const SHAPES = Dict(
    :circle    => (".###.", "#---#", "#---#", "#---#", ".###."),
    :square    => ("#####", "#---#", "#---#", "#---#", "#####"),
    :diamond   => ("..#..", ".#-#.", "#---#", ".#-#.", "..#.."),
    :utriangle => ("..#..", ".#-#.", ".#-#.", "#---#", "#####"),
    :dtriangle => ("#####", "#---#", ".#-#.", ".#-#.", "..#.."),
    :xcross    => ("#...#", ".#.#.", "..#..", ".#.#.", "#...#"),
    :cross     => ("..#..", "..#..", "#####", "..#..", "..#.."),
    :star      => ("#.#.#", ".###.", "#####", ".###.", "#.#.#"),
    :dot       => (".###.", "#####", "#####", "#####", ".###."))
const ALIASES = Dict(:o => :circle, :s => :square, :d => :diamond, :^ => :utriangle, :v => :dtriangle,
                     :x => :xcross, :+ => :cross, :* => :star)

"""
The marker for `m`: a shape in dots, by name (`:circle`, `:square`, `:diamond`, `:utriangle`, `:dtriangle`,
`:xcross`, `:cross`, `:star`, `:dot`) or short name (`:o`, `:s`, `:d`, `:^`, `:v`, `:x`, `:+`, `:*`), as the
offsets (column, row) of its dots and of the dots it clears; or a `Char`, drawn over the character of the point.
"""
function markershape(m)
    if m isa Char
        textwidth(m) == 1 && return m
    elseif m isa Symbol && haskey(SHAPES, get(ALIASES, m, m))
        rows = SHAPES[get(ALIASES, m, m)]; c = length(rows) ÷ 2 + 1
        at(ch) = [(i - c, j - c) for (j, row) in enumerate(rows) for (i, x) in enumerate(row) if x == ch]
        return (; set=at('#'), clear=at('-'), radius=c - 1)
    end
    names = join([":$k" for k in sort!(collect(keys(SHAPES)))], ", ")
    short = join([":$k" for k in sort!(collect(keys(ALIASES)))], ", ")
    throw(ArgumentError("marker must be a shape ($names; or $short) or a one-column Char, not $(repr(m))"))
end

"""
The marker `shape` (from `markershape`) drawn into the Braille dots `grid` at each point of the frames in the box `b`,
over the curves, with `frame` updated to the last frame to draw in each character. Dots off the grid are dropped.
"""
function markpoints!(grid, frame, frames, b, shape)
    height, width = size(grid)
    for (f, curves) in enumerate(frames), z in curves, p in z
        i0, j0 = dot(p, b)
        for (offsets, on) in ((shape.clear, false), (shape.set, true)), (di, dj) in offsets
            i, j = i0 + di, j0 + dj; r, c = j ÷ 4 + 1, i ÷ 2 + 1
            (0 ≤ i < 2width && 0 ≤ j < 4height) || continue
            bit = BRAILLE[j%4+1][i%2+1]
            on ? (grid[r, c] |= bit; frame[r, c] = f) : (grid[r, c] &= ~bit)
        end
    end
    grid
end

"""
The characters of the Braille dots `grid` with the character `ch` over the character of each point of the frames
in the box `b`, and `frame` updated to the last frame to mark each.
"""
function markpoints!(grid, frame, frames, b, ch::Char)
    chars = Char.(0x2800 .+ grid)
    for (f, curves) in enumerate(frames), z in curves, p in z
        i, j = dot(p, b); chars[j÷4+1, i÷2+1] = ch; frame[j÷4+1, i÷2+1] = f
    end
    chars
end

"""
The framed grid (Braille dot bits, or characters), each character in the colour `code(frame)` when `code` is a
function.
"""
function drawgrid(io::IO, grid, frame, code)
    height, width = size(grid)
    println(io, "┌", "─"^width, "┐")
    for r in 1:height
        print(io, "│")
        for c in 1:width
            ch = grid[r, c] isa Char ? grid[r, c] : Char(0x2800 + grid[r, c])
            code !== nothing && frame[r, c] > 0 ? print(io, code(frame[r, c]), ch, "\e[39m") : print(io, ch)
        end
        println(io, "│")
    end
    println(io, "└", "─"^width, "┘")
end
