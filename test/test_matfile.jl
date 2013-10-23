# Test MATLAB MAT file I/O

using MATLAB
using Base.Test

a = Int32[1 2 3; 4 5 6]
b = [1.2, 3.4, 5.6, 7.8]
c = {[1.], [1., 2.], [1., 2., 3.]}
d = {"name"=>"MATLAB", "score"=>100.}

immutable S
	x::Float64
	y::Bool
	z::Vector{Float64}
end

ss = S[S(1.0, true, [1., 2.]), S(2.0, false, [3., 4.])]

write_matfile("test.mat"; a=a, b=b, c=c, d=d, ss=mxstructarray(ss))

