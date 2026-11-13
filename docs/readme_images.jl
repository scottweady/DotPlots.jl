# The README's pictures: each plot drawn as in a colour terminal, then turned into an SVG (the Braille dots as
# circles, so no font is needed for them), with the frame and labels in a grey that follows a light or dark page.
#   julia --project docs/readme_images.jl                  (from src/DotPlots; writes docs/*.svg)
using DotPlots

const CW, CH = 8, 16                                     # a character cell, px: 2 × 4 dots 4 px apart
const BITS = ((0x01, 0x08), (0x02, 0x10), (0x04, 0x20), (0x40, 0x80))    # Braille dot bit at (row, column)

"""The plot `f(io)` draws, in 24-bit colour on the ramp for either background."""
function capture(f)
    withenv("COLORTERM" => "truecolor", "COLORFGBG" => nothing) do
        buf = IOBuffer(); f(IOContext(buf, :color => true)); String(take!(buf))
    end
end

"""Split a line into (character, colour or nothing) pairs, dropping the escapes."""
function cells(line)
    out = Tuple{Char,Union{Nothing,String}}[]; colour = nothing
    for m in eachmatch(r"\e\[([0-9;]*)m|(.)"s, line)
        if m[1] !== nothing
            p = parse.(Int, split(m[1], ';'))
            colour = p[1] == 38 && length(p) == 5 ? "rgb($(p[3]),$(p[4]),$(p[5]))" : nothing
        else
            push!(out, (m[2][1], colour))
        end
    end
    out
end

esc(c) = c == '&' ? "&amp;" : c == '<' ? "&lt;" : c == '>' ? "&gt;" : string(c)

function svg(text)
    lines = cells.(split(rstrip(text, '\n'), '\n'))
    frame = filter(l -> !isempty(l) && l[1][1] in "┌│└", lines); labels = filter(l -> l ∉ frame, lines)
    width = max(maximum(length, frame) * CW, ceil(Int, maximum(length, labels; init=0) * 8.5))    # labels' glyphs wider
    height = length(lines) * CH
    io = IOBuffer()
    print(io, """<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">
    <style>.fg{fill:#57606a}.ln{stroke:#8c959f}text{font:13px ui-monospace,SFMono-Regular,Menlo,Consolas,monospace}
    @media (prefers-color-scheme:dark){.fg{fill:#9198a1}.ln{stroke:#6e7681}}</style>
    """)
    for (r, line) in enumerate(lines)
        y = (r - 1) * CH
        if !isempty(line) && line[1][1] in "┌│└"                       # the frame and the dots
            line[1][1] == '┌' && print(io, """<rect class="ln" fill="none" x="$(CW/2)" y="$(y + CH/2)" """,
                                       """width="$((length(line) - 1) * CW)" height="$((count(l -> !isempty(l) && l[1][1] == '│', lines) + 1) * CH)"/>\n""")
            for (c, (ch, colour)) in enumerate(line)
                bits = UInt32(ch) - 0x2800; 0 < bits <= 0xff || continue
                fill = colour === nothing ? "class=\"fg\"" : "fill=\"$colour\""
                print(io, "<g $fill>")
                for (j, row) in enumerate(BITS), (i, bit) in enumerate(row)
                    bits & bit != 0 && print(io, """<circle cx="$((c - 1) * CW + 2 + 4(i - 1))" cy="$(y + 2 + 4(j - 1))" r="1.5"/>""")
                end
                print(io, "</g>")
            end
            println(io)
        else                                                            # the labels below
            print(io, """<text class="fg" x="0" y="$(y + 12)" xml:space="preserve">""")
            k = 1
            while k <= length(line)                                     # runs of one colour
                colour = line[k][2]; e = k
                while e < length(line) && line[e+1][2] == colour; e += 1; end
                run = join(esc(line[i][1]) for i in k:e)
                print(io, colour === nothing ? run : "<tspan fill=\"$colour\">$run</tspan>"); k = e + 1
            end
            println(io, "</text>")
        end
    end
    print(io, "</svg>\n"); String(take!(io))
end

save(name, f) = (write(joinpath(@__DIR__, name * ".svg"), svg(capture(f))); println("docs/", name, ".svg"))

# an ellipse turning about a hole, as in the README's Use
ring(a, b, φ) = [(a * cos(s) * cos(φ) - b * sin(s) * sin(φ), a * cos(s) * sin(φ) + b * sin(s) * cos(φ))
                 for s in range(0, 2π; length=65)[1:64]]
t = 0:0.25:1
save("ellipse", io -> dotplot(io, [[ring(1.5, 0.75, s), ring(0.3, 0.3, 0)] for s in t]; t))

# the spirograph of examples/spirograph.jl, coloured by when each piece was traced
R, r, d = 8, 5, 5
pen(s) = ((R - r) * cos(s) + d * cos((R - r) / r * s), (R - r) * sin(s) - d * sin((R - r) / r * s))
ts = range(0, r ÷ gcd(R, r), 9)
save("spirograph", io -> dotplot(io, [[[pen(2π * s) for s in range(ts[k], ts[k+1], 100)]] for k in 1:8];
                                 t=ts[2:end], closed=false, maxheight=24))

# the travelling wave of examples/waves.jl
x = range(0, 2π, 200)
save("wave", io -> dotplot(io, [[collect(zip(x, sin.(x .- s)))] for s in range(0, π / 2, 5)];
                           t=range(0, π / 2, 5), closed=false))

# a single curve from x and y vectors: a three-petal rose, at its true aspect ratio
θ = range(0, 2π, 400)
save("rose", io -> dotplot(io, cos.(3θ) .* cos.(θ), cos.(3θ) .* sin.(θ); maxheight=16))

# the heat equation, u = e^(-t) sin x + e^(-9t) sin 3x / 3, sampled at nine points: markers, coloured by time
xs = range(0, π, 9); th = [0, 0.1, 0.5]
save("heat", io -> dotplot(io, [[collect(zip(xs, exp(-s) .* sin.(xs) .+ exp(-9s) .* sin.(3xs) ./ 3))] for s in th];
                           t=th, closed=false, marker=:o, height=12))

# log-log: a power law that turns over, x² / (1 + x³), slopes 2 and -1
xl = exp10.(range(-2, 2, 200))
save("loglog", io -> dotplot(io, xl, xl .^ 2 ./ (1 .+ xl .^ 3); xscale=:log, yscale=:log, width=40))

# a log y axis, with square markers: n! against n
save("factorial", io -> dotplot(io, 0:2:20, factorial.(0:2:20); yscale=:log, marker=:s, height=12))
