using MATLAB
using Test

is_ci() = lowercase(get(ENV, "CI", "false")) == "true"

if !is_ci() # only test if not CI
include("engine.jl")
include("matfile.jl")
include("matstr.jl")
include("mxarray.jl")
end
