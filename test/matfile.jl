# Test MATLAB MAT file I/O

using MATLAB, Compat, Base.Test
import Compat: ASCIIString

a = Int32[1 2 3; 4 5 6]
b = [1.2, 3.4, 5.6, 7.8]
c = Any[[0., 1.], [1., 2.], [1., 2., 3.]]
d = @compat Dict{Any,Any}("name"=>"MATLAB", "score"=>100.)

immutable S
    x::Float64
    y::Bool
    z::Vector{Float64}
end

ss = S[S(1.0, true, [1., 2.]), S(2.0, false, [3., 4.])]

write_matfile("test.mat"; a=a, b=b, c=c, d=d, ss=mxstructarray(ss))

r = read_matfile("test.mat")
@test isa(r, Dict{ASCIIString, MxArray})
@test length(r) == 5

ra = jmatrix(r["a"])
rb = jvector(r["b"])
rc = jvariable(r["c"])
rd = jdict(r["d"])
rss = r["ss"]

gc()  # make sure that ra, rb, rc, rd remain valid

@test ra == a
@test rb == b
@test rc == c

@test rd["name"] == d["name"]
@test rd["score"] == d["score"]

@test is_struct(rss)
@test jscalar(get_field(rss, 1, "x")) == 1.0
@test jscalar(get_field(rss, 1, "y")) 
@test jvector(get_field(rss, 1, "z")) == ss[1].z
@test jscalar(get_field(rss, 2, "x")) == 2.0
@test !jscalar(get_field(rss, 2, "y")) 
@test jvector(get_field(rss, 2, "z")) == ss[2].z

