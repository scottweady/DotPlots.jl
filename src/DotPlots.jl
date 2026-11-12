"""
    DotPlots

Plots in the terminal, drawn with Unicode Braille characters: each character is a 2 × 4 grid of dots, which are
about square in a terminal, so shapes keep their aspect ratio. `dotplot` draws plane curves at a sequence of
times, overlaid and coloured by time when the output takes colour, or played one time at a time in place first.
Nothing here knows where the curves come from: a frame is a vector of curves, a curve a vector of points (anything
indexable as `p[1], p[2]`).

Colours: the frames are coloured from indigo through violet and pink to rose, a hue sweep so that overlapping
frames stay apart. The terminal's background is read from COLORFGBG when the terminal sets it (light or dark
tones); otherwise (Terminal.app, for one) the ramp is a mix of the two that reads on either.
24-bit colour when COLORTERM says so, else the nearest xterm-256 colour.

The pieces, for scripts that draw the same pictures elsewhere: `closecurves`, `box` (the plot window), `raster`
(the dots), `drawgrid`, `timecode` with the stops `TIME_LIGHT`, `TIME_DARK`, `TIME_EITHER`, `isterminal` and `play`
(the animation).
"""
module DotPlots

export dotplot

# the time ramp and its terminal escapes
include("colour.jl")
# the plot window, the dots and the framed grid
include("raster.jl")
# the plot and its animation
include("dotplot.jl")

end
