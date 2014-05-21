tests = ["mxarray", 
         "matfile",
         "mstatements",
         "engine"]

println("Testing MATLAB.jl")
for t in tests
    fp = joinpath("test", "$(t).jl")
    println("* running $fp ...")
    include(fp)
end
