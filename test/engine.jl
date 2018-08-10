using MATLAB
using Test
using SparseArrays

# test engine

restart_default_msession()

a = [1. 2. 3.; 4. 5. 6.]
b = [2. 3. 4.; 8. 7. 6.]

@mput a b
mat"""
    r1 = a .* b;
    r2 = a + b;
"""
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

# test for segfault

s = MSession()
close(s)
@test_throws UndefRefError close(s)


# segfault on deleted references
x = mxarray(3.0)
delete(x)
@test_throws UndefRefError delete(x)
@test_throws UndefRefError nrows(x)
@test_throws UndefRefError is_numeric(x)
@test_throws UndefRefError jscalar(x)
@test_throws UndefRefError jvalue(x)

# make sure restart_default_msession() doesn't error on null references on
# default msession
s = get_default_msession()
close(s)
restart_default_msession()
