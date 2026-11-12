# The time ramp: four stops from indigo to rose for light and dark terminals, and a mix that reads on either.

const TIME_LIGHT = ((0x4f, 0x46, 0xe5), (0x7c, 0x3a, 0xed), (0xdb, 0x27, 0x77), (0xe1, 0x1d, 0x48))
const TIME_DARK = ((0x68, 0x75, 0xf5), (0x9b, 0x6c, 0xf6), (0xe7, 0x55, 0x9c), (0xf0, 0x54, 0x70))
const TIME_EITHER = ((0x4f, 0x46, 0xe5), (0x9b, 0x6c, 0xf6), (0xe7, 0x55, 0x9c), (0xe1, 0x1d, 0x48))

"""The time-ramp stops for the terminal's background: COLORFGBG ("fg;bg", bg 7 or 15 light, other ANSI colours dark)."""
function timestops()
    bg = tryparse(Int, last(split(get(ENV, "COLORFGBG", ""), ';')))
    bg === nothing ? TIME_EITHER : bg in (7, 15) ? TIME_LIGHT : bg < 16 ? TIME_DARK : TIME_EITHER
end

"""ANSI foreground escape for the time ramp at s ∈ [0, 1]."""
function timecolour(s; stops=timestops(), truecolor=get(ENV, "COLORTERM", "") in ("truecolor", "24bit"))
    x = clamp(s, 0, 1) * (length(stops) - 1); k = min(floor(Int, x), length(stops) - 2); f = x - k
    c = round.(Int, (1 - f) .* stops[k+1] .+ f .* stops[k+2])
    truecolor && return "\e[38;2;$(c[1]);$(c[2]);$(c[3])m"
    l = map(v -> v < 48 ? 0 : v < 115 ? 1 : round(Int, (v - 35) / 40), c)   # nearest level of the 6 × 6 × 6 cube
    "\e[38;5;$(16 + 36l[1] + 6l[2] + l[3])m"
end

"""The escape of frame f of n, as a function of f (the ramp and the colour depth read once)."""
timecode(n) = (stops = timestops(); truecolor = get(ENV, "COLORTERM", "") in ("truecolor", "24bit");
               f -> timecolour((f - 1) / (n - 1); stops, truecolor))
