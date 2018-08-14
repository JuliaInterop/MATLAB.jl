using MATLAB
using Test

@test mat"1" == 1
@test mat"[1, 2, 3]" == [1 2 3]

# Test interpolation
x = 1
@test mat"$x + 1" == 2

ret = mat"$y = $x + 2"
@test ret === nothing
@test y == 3

ret = mat"$y = $(x + 3)"
@test ret === nothing
@test y == 4

x = 5
@test mat"$x == 5"

# Test assignment
x = [1, 2, 3, 4, 5]
ret = mat"$x(1:3) = 1"
@test ret === nothing
@test x == [1, 1, 1, 4, 5]
ret = mat"$(x[1:3]) = 2"
@test ret === nothing
@test x == [2, 2, 2, 4, 5]

# Test a more complicated case with assignments on LHS and RHS
x = 20
mat"""
for i = 1:10
   $x = $x + 1;
end
"""

# Test assignment then use
ret = mat"""
$z = 5;
$q = $z;
"""
@test ret === nothing
@test z == 5
@test q == 5

# Test multiple assignment
ret = mat"[$a, $b] = sort([4, 3])"
@test ret === nothing
@test a == [3 4]
@test b == [2 1]

# Test comments
a = 5
@test mat"$a + 1; % = 2" == 6

# Test indexing
c = [1, 2]
@test mat"$c($c == 2)" == 2

# Test line continuations
ret = mat"""
$d ...
= 3
"""
@test ret === nothing
@test d == 3

# Test strings with =
text = "hello = world"
@test mat"strfind($text, 'o = w')" == 5
