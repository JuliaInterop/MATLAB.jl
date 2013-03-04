
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

r1_mx = get_mvariable(:r1)
r1 = jarray(r1_mx)

r2_mx = get_mvariable(:r2)
r2 = jarray(r2_mx)

@test isequal(r1, a .* b)
@test isequal(r2, a + b)

delete(r1_mx)
delete(r2_mx)

close_default_msession()
