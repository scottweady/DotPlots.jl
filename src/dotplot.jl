# The plot of a sequence of frames, overlaid and coloured by time, and its animation in an interactive terminal.

"""
    dotplot([io,] frames; t = nothing, every = 1, closed = true, width = 60, maxheight = nothing,
            height = nothing, animate = false, duration = 2)
    dotplot([io,] x, y; closed = false, width = 60, maxheight = nothing, height = nothing)
    dotplot([io,] y; width = 60, height = width ÷ 4, …)

Draw the curves of `frames` in the terminal with Unicode Braille characters, `width` characters wide (narrower if
needed to stay within `maxheight` lines), with the x and y ranges below. x and y have one scale, so shapes keep
their aspect ratio; with `height`, they are scaled separately to fill `width` × `height` characters instead. `frames[k]` is the vector of curves at the
k-th time, a curve a vector of points (anything indexable as `p[1], p[2]`), closed by joining its last point to its
first unless `closed = false`; one picture is a one-element `frames`. Several frames are overlaid, and with their
times `t` and an output that takes colour they are coloured by time, with the times in their colours below.
`every` keeps every `every`-th frame. With `animate = true` and a terminal for output, the frames are first played
one at a time in place, over about `duration` seconds (at most 30 frames per second; Ctrl-C skips to the end), and
the overlay is drawn over the last one; the window is then made smaller where needed to fit the terminal.

With two vectors of numbers, the one curve through the points `(x[i], y[i])`, open unless `closed = true`; with
one, `y` against its index, `(i, y[i])`, in a box of fixed shape, `width` × `width ÷ 4` characters.
"""
dotplot(frames; kw...) = dotplot(stdout, frames; kw...)
dotplot(y::AbstractVector{<:Real}; kw...) = dotplot(stdout, y; kw...)
dotplot(io::IO, y::AbstractVector{<:Real}; width::Integer=60, height::Integer=max(1, width ÷ 4), kw...) =
    dotplot(io, eachindex(y), y; width, height, kw...)
dotplot(x::AbstractVector{<:Real}, y::AbstractVector{<:Real}; kw...) = dotplot(stdout, x, y; kw...)
function dotplot(io::IO, x::AbstractVector{<:Real}, y::AbstractVector{<:Real}; closed::Bool=false, kw...)
    length(x) == length(y) || throw(DimensionMismatch("x has $(length(x)) points and y $(length(y))"))
    dotplot(io, [[collect(zip(x, y))]]; closed, kw...)
end
function dotplot(io::IO, frames; t=nothing, every::Integer=1, closed::Bool=true, width::Integer=60,
                 maxheight=nothing, height=nothing, animate::Bool=false, duration::Real=2)
    ks = 1:every:length(frames)
    frames = closed ? closecurves(frames[ks]) : frames[ks]; t = t === nothing ? nothing : t[ks]
    if animate && t !== nothing && length(frames) > 1 && isterminal(io)
        rows, cols = displaysize(io)                         # the window shrinks to fit the terminal
        width = min(width, cols - 2)
        maxheight = maxheight === nothing ? rows - 4 : min(maxheight, rows - 4)
        play(io, frames, t; width, maxheight, height, duration)
    end
    b = box(frames; width, maxheight, height)
    colour = t !== nothing && length(frames) > 1 && get(io, :color, false)
    code = colour ? timecode(length(frames)) : nothing
    drawgrid(io, raster(frames, b)..., code)
    print(io, " x ∈ [", round(b.x0; sigdigits=3), ", ", round(b.x1; sigdigits=3), "],  y ∈ [",
          round(b.y0; sigdigits=3), ", ", round(b.y1; sigdigits=3), "]")
    if colour                                                # the times in their colours
        print(io, "\n t: ")
        for (f, s) in enumerate(t)
            print(io, code(f), "■ ", round(s; sigdigits=4), "\e[39m", f < length(t) ? "  " : "")
        end
    end
end

"""
Whether `io` is a terminal, under its wrappers: IOContext, the REPL's TTYTerminal and (Julia ≥ 1.12) REPL.LimitIO,
which caps the bytes of one display; matched by name, since REPL is not a dependency.
"""
isterminal(io::IOContext) = isterminal(io.io)
isterminal(io::Base.Terminals.TTYTerminal) = isterminal(io.out_stream)
isterminal(io::IO) = io isa Base.TTY || (nameof(typeof(io)) === :LimitIO && isterminal(getfield(io, :io)))

"""
    play(io, frames, t; width = 60, maxheight = nothing, height = nothing, duration = 2)

Play the (closed) frames one at a time in the window of the overlay, in place (cursor up after each), and leave
the cursor at the top of the window with the rest of the screen cleared, for the overlay. Nothing when the window
does not fit in the terminal.
"""
function play(io::IO, frames, t; width::Integer=60, maxheight=nothing, height=nothing, duration::Real=2)
    b = box(frames; width, maxheight, height); rows, cols = displaysize(io)
    (b.height + 4 ≤ rows && b.width + 2 ≤ cols) || return
    n = length(frames); ks = unique(round.(Int, range(1, n; length=min(n, max(2, ceil(Int, 30duration))))))
    pause = clamp(duration / length(ks), 1 / 30, 0.5)
    code = get(io, :color, false) ? timecode(n) : nothing
    up = "\e[$(b.height + 2)A\r"                             # from the time line to the top of the box
    print(io, "\e[?25l")                                     # hide the cursor
    try
        for (j, k) in enumerate(ks)
            buf = IOContext(IOBuffer(), io)                  # one write per frame, against flicker
            j > 1 && print(buf, up)
            grid, frame = raster(frames[k:k], b)
            drawgrid(buf, grid, frame, code === nothing ? nothing : _ -> code(k))
            print(buf, " t = ", round(t[k]; sigdigits=4), "  (", k, "/", n, ")\e[K")
            write(io, take!(buf.io)); flush(io)
            sleep(pause)
        end
    catch e
        e isa InterruptException || rethrow()                # Ctrl-C: straight to the overlay
    finally
        print(io, up, "\e[J\e[?25h")
    end
    nothing
end
