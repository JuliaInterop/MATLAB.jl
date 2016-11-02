using MATLAB
using Base.Test

# test MMAT file I/O

a32 = Int32[1 2 3; 4 5 6]
a64 = Int64[1 2 3; 4 5 6]
b = [1.2, 3.4, 5.6, 7.8]
c = [[0., 1.], [1., 2.], [1., 2., 3.]]
d = Dict("name"=>"MATLAB", "score"=>100.)

immutable S
    x::Float64
    y::Bool
    z::Vector{Float64}
end

ss = S[S(1.0, true, [1., 2.]), S(2.0, false, [3., 4.])]

write_matfile("test.mat"; a32=a32, a64=a64, b=b, c=c, d=d, ss=mxstructarray(ss))

r = read_matfile("test.mat")
@test isa(r, Dict{String, MxArray})
@test length(r) == 6

ra32 = Any(r["a32"])
ra64 = Any(r["a64"])
rb = Any(r["b"])
rc = Any(r["c"])
rd = Any(r["d"])
rss = r["ss"]

gc()  # make sure that ra, rb, rc, rd remain valid

@test ra32 == a32
@test ra64 == a64
@test rb == b
@test rc == c

@test rd["name"] == d["name"]
@test rd["score"] == d["score"]

@test is_struct(rss)
@test Any(get_field(rss, 1, "x")) == 1.0
@test Any(get_field(rss, 1, "y")) 
@test Any(get_field(rss, 1, "z")) == ss[1].z
@test Any(get_field(rss, 2, "x")) == 2.0
@test !Any(get_field(rss, 2, "y")) 
@test Any(get_field(rss, 2, "z")) == ss[2].z

