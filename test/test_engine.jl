
using MATLAB
using Test

restart_default_msession()

a = [1. 2. 3.; 4. 5. 6.]
b = [2. 3. 4.; 8. 7. 6.]

put_variable(:a, a)
put_variable(:b, b)
eval_string("c = a .* b")

c_mx = get_mvariable(:c)
c = jarray(c_mx)
@test isequal(c, a .* b)
delete(c_mx)

close_default_msession()
