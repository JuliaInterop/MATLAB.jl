
using MATLAB
using Test

eng = MSession()

a = [1. 2. 3.; 4. 5. 6.]
b = [2. 3. 4.; 8. 7. 6.]

put_variable(eng, :a, a)
put_variable(eng, :b, b)
eval_string(eng, "c = a .* b")

c_mx = get_variable(eng, :c)
c = jarray(c_mx)
@test isequal(c, a .* b)
delete(c_mx)

close(eng)
