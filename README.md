# DotPlots.jl

Plots in the terminal, in Unicode Braille characters (2 × 4 dots each, about square, so shapes keep their aspect
ratio), with no dependencies. `dotplot` draws plane curves at a sequence of times: overlaid, coloured by time when
the terminal shows colour, and, at an interactive terminal, played one time at a time first.

## Gallery

As a colour terminal shows them; the pictures are made by `julia --project docs/readme_images.jl`.

**Curves at a sequence of times**, overlaid and coloured by time. An ellipse turning about a fixed hole, the frames
of [Use](#use) below: `dotplot(frames; t)`

<img src="docs/ellipse.svg" alt="an ellipse turning about a hole, five frames overlaid, indigo to rose">

A spirograph drawn in eight pieces, coloured by when each piece was traced (`examples/spirograph.jl`)

<img src="docs/spirograph.svg" alt="a hypotrochoid, an eight-pointed star, coloured indigo to rose along its length">

A travelling wave sin(x − t), open curves at five times (`examples/waves.jl`)

<img src="docs/wave.svg" alt="a sine wave at five times, shifting right, indigo to rose">

**A single curve** from x and y vectors, at its true aspect ratio: a three-petal rose, `dotplot(x, y)`

<img src="docs/rose.svg" alt="a three-petal rose in grey">

**Markers.** The heat equation, u = e⁻ᵗ sin x + e⁻⁹ᵗ sin 3x / 3, sampled at nine points at three times:
`dotplot(frames; t, closed = false, marker = :o, height = 12)`

<img src="docs/heat.svg" alt="three curves of nine circled points each, flattening and decaying with time, indigo to rose">

**Log scales.** A power law that turns over, x² / (1 + x³), on log-log axes, slopes 2 and −1:
`dotplot(x, y; xscale = :log, yscale = :log)`

<img src="docs/loglog.svg" alt="a curve rising at slope 2 and falling at slope -1 on log-log axes, in grey">

n! for even n up to 20, on a log y axis, with square markers: `dotplot(n, factorial.(n); yscale = :log, marker = :s)`

<img src="docs/factorial.svg" alt="eleven square markers rising, curving upward, on a log y axis, in grey">

## Use

```julia
using DotPlots

# an ellipse turning, with a hole: one frame per time, a frame a vector of curves, a curve a vector of points
ring(a, b, φ) = [(a * cos(s) * cos(φ) - b * sin(s) * sin(φ), a * cos(s) * sin(φ) + b * sin(s) * cos(φ))
                 for s in range(0, 2π; length=65)[1:64]]
t = 0:0.25:1
frames = [[ring(1.5, 0.75, s), ring(0.3, 0.3, 0)] for s in t]

dotplot(frames[1:1])                          # one picture
dotplot(frames; t)                            # overlaid, coloured by time
dotplot(frames; t, animate = true)            # played first, over about 2 s

x = range(0, 1, 100)
dotplot(x, x .^ 2)                            # one open curve through the points (x[i], y[i])
dotplot(x .^ 2)                               # against the index, (i, y[i]), filling a 60 × 15 box
dotplot(x, exp.(10x); yscale = :log)          # y on a log scale: a straight line
dotplot(1:8, [1, 4, 2, 5, 3, 6, 2, 4]; marker = :o)   # each point marked with an o
```

`dotplot([io,] frames; t, every, closed, width, maxheight, xscale, yscale, marker, animate, duration)`:
- `frames[k]` is the vector of curves at the k-th time; a point is anything indexable as `p[1], p[2]`;
- `t`, the times, colour the frames (and label them) when the output takes colour; `every` keeps every k-th frame;
- curves are closed (last point joined to the first) unless `closed = false`;
- `width` characters wide, narrower if needed to stay within `maxheight` lines, and in a terminal (the REPL's
  included) within the window, ranges and legend too, with the prompt still in view;
- `xscale`, `yscale` are `:linear` (the default) or `:log`, a log₁₀ scale with the ranges below in the data's
  units (every point positive on a log axis); log-log keeps one scale, a decade as long in x as in y, and one log
  axis fills `width` × `width ÷ 4` like `dotplot(y)`;
- `marker` marks each point over the curves, in its frame's colour, with a shape 5 dots across centred on the
  point's dot: `:circle` (`:o`), `:square` (`:s`), `:diamond` (`:d`), `:utriangle` (`:^`), `:dtriangle` (`:v`),
  open, or `:xcross` (`:x`), `:cross` (`:+`), `:star` (`:*`), `:dot`; the window leaves room for them at the edges.
  A `Char` (`'#'`) is drawn in place of the character holding the point, to the nearest character only;
- `animate = true` plays the frames in place first, over about `duration` seconds, when the output is a terminal
  (Ctrl-C skips to the overlay); otherwise the output is the same as without it.

`dotplot([io,] x, y; closed, width, maxheight, xscale, yscale, marker)` is the one curve through the points `(x[i], y[i])`, open unless
`closed = true`: `dotplot([[collect(zip(x, y))]]; closed = false)`. `dotplot([io,] y)` is `y` against its index, with x and y scaled separately to fill `width` × `width ÷ 4`
characters. Otherwise x and y have one scale, so shapes keep their aspect ratio; `height = n` stretches any plot
to fill `width` × `n` characters instead.

The colours run from indigo to rose, in tones for a light or a dark background when the terminal says which
(COLORFGBG), and in 24-bit colour when COLORTERM says so. The pieces (`box`, `raster`, `markpoints!`, `drawgrid`, `timecode`,
`play`, …) are described in the module docstring, `?DotPlots`.

## Examples

In `examples/`, an environment of their own with DotPlots only (from src/DotPlots):

```bash
julia --project=examples -e 'using Pkg; Pkg.instantiate()'    # once
julia --project=examples examples/shapes.jl
```

| | |
|:--|:--|
| `shapes.jl` | one picture each with `dotplot(x, y)`: an ellipse, a rose, a cardioid, a lemniscate; and a disc with two holes (several curves in one frame) |
| `vortex_patch.jl` | Kirchhoff's elliptical vortex turning at Ω = ωab/(a + b)², overlaid and coloured by time, played first |
| `waves.jl` | open curves (`closed = false`) at several times: a travelling and a standing wave |
| `spirograph.jl` | a hypotrochoid drawn in eight pieces, coloured by when each piece was traced, played piece by piece |

The animations play when the output is an interactive terminal; run from a terminal to see them.

## Tests

```bash
julia --project -e 'using Pkg; Pkg.test()'
```

## See also

[UnicodePlots.jl](https://github.com/JuliaPlots/UnicodePlots.jl), the full-featured package for plotting in the
terminal with Braille characters (scatter, line, bar, histogram, heatmap, surface, …). Use it for anything beyond what
DotPlots does; DotPlots is a small, dependency-free tool for curves at a sequence of times.
