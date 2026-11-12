# The plot of a sequence of frames, overlaid and coloured by time, and its animation in an interactive terminal.

"""
    dotplot([io,] frames; t = nothing, every = 1, closed = true, width = 60, maxheight = nothing,
            height = nothing, xscale = :linear, yscale = :linear, animate = false, duration = 2)
    dotplot([io,] x, y; closed = false, width = 60, maxheight = nothing, height = nothing, xscale, yscale)
    dotplot([io,] y; width = 60, height = width ÷ 4, …)

Draw the curves of `frames` in the terminal with Unicode Braille characters, `width` characters wide (narrower if
needed to stay within `maxheight` lines), with the x and y ranges below. x and y have one scale, so shapes keep
their aspect ratio; with `height`, they are scaled separately to fill `width` × `height` characters instead. `frames[k]` is the vector of curves at the
k-th time, a curve a vector of points (anything indexable as `p[1], p[2]`), closed by joining its last point to its
first unless `closed = false`; one picture is a one-element `frames`. Several frames are overlaid, and with their
times `t` and an output that takes colour they are coloured by time, with the times in their colours below.
`every` keeps every `every`-th frame. With `animate = true` and a terminal for output, the frames are first played
one at a time in place, over about `duration` seconds (at most 30 frames per second; Ctrl-C skips to the end), and
the overlay is drawn over the last one.

In a terminal (the REPL's included), or on an `IOContext` with a `:displaysize`, the plot fits the window: at
most its width, and in height its rows less two (for the REPL's blank line and the prompt), counting the ranges
and the legend, which wrap to the width.

With `xscale = :log` (`yscale = :log`), x (y) is on a log₁₀ scale, its range below in the data's units; every point
on a log axis must be positive. On log-log axes a decade is as long in x as in y; with one log axis, x and y are
scaled separately, as with `height = width ÷ 4` unless `height` is given.

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
                 maxheight=nothing, height=nothing, xscale::Symbol=:linear, yscale::Symbol=:linear,
                 animate::Bool=false, duration::Real=2)
    xlog, ylog = islog(xscale, "xscale"), islog(yscale, "yscale")
    ks = 1:every:length(frames)
    frames = logscale(frames[ks], xlog, ylog); t = t === nothing ? nothing : t[ks]
    closed && (frames = closecurves(frames))
    xlog != ylog && height === nothing && (height = max(1, width ÷ 4))  # one log axis: no common scale
    colour = t !== nothing && length(frames) > 1 && get(io, :color, false)
    code = colour ? timecode(length(frames)) : nothing
    labels = colour ? ["■ " * string(round(s; sigdigits=4)) for s in t] : String[]
    # in a terminal (or with a :displaysize), all of it fits: the frame, the ranges and the legend, and below
    # them the REPL's blank line and prompt
    fits = isterminal(io) || get(io, :displaysize, nothing) !== nothing
    rows, cols = fits ? displaysize(io) : (typemax(Int), typemax(Int))
    legend = wraplegend(labels, cols)
    if fits
        width = max(1, min(width, cols - 2))
        budget = max(1, rows - 2 - 1 - length(legend) - 2)
        maxheight = maxheight === nothing ? budget : min(maxheight, budget)
    end
    b = box(frames; width, maxheight, height)
    ranges = rangelabels(b, xlog, ylog)
    if textwidth(ranges[1] * ", " * ranges[2]) > cols       # the ranges on two lines, the box a line lower
        fits && b.height + 2 + 2 + length(legend) + 2 > rows &&
            (b = box(frames; width, maxheight=max(1, maxheight - 1), height); ranges = rangelabels(b, xlog, ylog))
        ranges = (ranges[1], "\n" * ranges[2])
    else
        ranges = (ranges[1] * ",", " " * ranges[2])
    end
    animate && t !== nothing && length(frames) > 1 && isterminal(io) &&
        play(io, frames, t; width=b.width, maxheight=b.height, height=height === nothing ? nothing : b.height, duration)
    drawgrid(io, raster(frames, b)..., code)
    print(io, ranges...)
    for (l, fs) in enumerate(legend)                         # the times in their colours
        print(io, l == 1 ? "\n t: " : "\n    ")
        for f in fs
            print(io, code(f), labels[f], "\e[39m", f < last(fs) ? "  " : "")
        end
    end
    println(io)
end

"""The x and y ranges of the box `b`, in the data's units."""
function rangelabels(b, xlog, ylog)
    lim(v, log) = round(log ? exp10(v) : v; sigdigits=3)
    (string(" x ∈ [", lim(b.x0, xlog), ", ", lim(b.x1, xlog), "]", xlog ? " (log)" : ""),
     string(" y ∈ [", lim(b.y0, ylog), ", ", lim(b.y1, ylog), "]", ylog ? " (log)" : ""))
end

"""The legend's labels in lines within `cols` characters (after the 4 of \" t: \"), as their indices."""
function wraplegend(labels, cols)
    lines = Vector{Int}[]; w = 0
    for (f, l) in enumerate(labels)
        n = textwidth(l)
        if isempty(lines) || w + 2 + n > cols
            push!(lines, [f]); w = 4 + n
        else
            push!(lines[end], f); w += 2 + n
        end
    end
    lines
end

"""Whether the scale `s` (`:linear` or `:log`) is logarithmic."""
islog(s::Symbol, name) = s === :log ? true : s === :linear ? false :
    throw(ArgumentError("$name must be :linear or :log, not :$s"))

"""The frames with x and/or y replaced by their log₁₀ (as is when neither), each point a tuple."""
function logscale(frames, xlog::Bool, ylog::Bool)
    xlog || ylog || return frames
    lg(v, on, name) = !on ? float(v) : v > 0 ? log10(v) : throw(DomainError(v, "$name must be positive on a log scale"))
    [[[(lg(p[1], xlog, "x"), lg(p[2], ylog, "y")) for p in z] for z in curves] for curves in frames]
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
