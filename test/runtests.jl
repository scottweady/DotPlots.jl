# DotPlots tests (test_*.jl here), on curves made up in the tests: the plot window, the dots, the colours, the plot
# and its animation. Each file runs in its own module.
# From this package's directory:
#   julia --project -e 'using Pkg; Pkg.test()'
using Test

files = sort(filter(f -> startswith(f, "test_") && endswith(f, ".jl"), readdir(@__DIR__)))
isempty(ARGS) || (files = filter(f -> f[6:end-3] in ARGS, files))

@testset "DotPlots" begin
    for f in files
        @testset verbose=true "$f" begin
            m = Core.eval(Main, :(module $(Symbol(f[1:end-3])) end))
            Base.include(m, joinpath(@__DIR__, f))
        end
    end
end
