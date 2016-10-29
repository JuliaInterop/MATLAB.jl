using MATLAB
using Base.Test

# test engine

restart_default_msession()

a = [1. 2. 3.; 4. 5. 6.]
b = [2. 3. 4.; 8. 7. 6.]

@mput a b
@matlab begin
    r1 = a .* b
    r2 = a + b
end
@mget r1 r2

@test isequal(r1, a .* b)
@test isequal(r2, a + b)

@mget r1::Vector
@test isequal(r1, vec(a .* b))

s = sparse([1. 0. 0.; 2. 3. 0.; 0. 4. 5.])
put_variable(:s, s)
s2 = get_variable(:s)
@test isequal(s, s2)

# mxcall

r = mxcall(:plus, 1, a, b)
@test isequal(r, a + b)

(xx, yy) = mxcall(:meshgrid, 2, [1., 2.], [3., 4.])
@test isequal(xx, [1. 2.; 1. 2.])
@test isequal(yy, [3. 3.; 4. 4.])

close_default_msession()
