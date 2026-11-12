# The plot window around the frames, the Braille dots of the curves in it, and the framed grid of characters.

const BRAILLE = ((0x01, 0x08), (0x02, 0x10), (0x04, 0x20), (0x40, 0x80))   # dot bits by (row, column)

"""Each curve of each frame with its first point appended at the end."""
closecurves(frames) = [[[z; z[1:1]] for z in curves] for curves in frames]

"""
The plot window around all the frames: corners, dot width `h` and height `hy`, and size in characters. One scale
for x and y (`hy = h`, shapes keep their aspect ratio) unless `height` is given: then x and y are scaled
separately to fill `width` × `height` characters (at most `maxheight` lines).
"""
function box(frames; width::Integer=60, maxheight=nothing, height=nothing)
    pts = reduce(vcat, reduce(vcat, frames))
    x0, x1 = extrema(p -> p[1], pts); y0, y1 = extrema(p -> p[2], pts)
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
    (; x0, y1, h, hy, width, height) = b; nx, ny = 2width, 4height
    grid = zeros(UInt8, height, width); frame = zeros(Int, height, width)
    for (f, curves) in enumerate(frames), z in curves, k in 1:length(z)-1
        a, c = z[k], z[k+1]; dx, dy = c[1] - a[1], c[2] - a[2]
        m = max(1, ceil(Int, 2sqrt(dx^2 + (dy * h / hy)^2) / h))    # two samples per dot along the segment
        for s in 0:m-1
            px, py = a[1] + (s / m) * dx, a[2] + (s / m) * dy
            i = clamp(floor(Int, (px - x0) / h), 0, nx - 1); j = clamp(floor(Int, (y1 - py) / hy), 0, ny - 1)
            grid[j÷4+1, i÷2+1] |= BRAILLE[j%4+1][i%2+1]; frame[j÷4+1, i÷2+1] = f
        end
    end
    grid, frame
end

"""The framed grid, each character in the colour `code(frame)` when `code` is a function."""
function drawgrid(io::IO, grid, frame, code)
    height, width = size(grid)
    println(io, "┌", "─"^width, "┐")
    for r in 1:height
        print(io, "│")
        for c in 1:width
            ch = Char(0x2800 + grid[r, c])
            code !== nothing && frame[r, c] > 0 ? print(io, code(frame[r, c]), ch, "\e[39m") : print(io, ch)
        end
        println(io, "│")
    end
    println(io, "└", "─"^width, "┘")
end
