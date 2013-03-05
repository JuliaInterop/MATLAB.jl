
using MATLAB
using Test

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

close_default_msession()
