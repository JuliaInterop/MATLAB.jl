# Testing the generation of mstatements

using MATLAB
using Base.Test

@test mstatement(:abc) == "abc"

@test mstatement(:(-a)) == "-(a)"

@test mstatement(:(a + b)) == "(a) + (b)"
@test mstatement(:(a - b)) == "(a) - (b)"
@test mstatement(:(a * b)) == "(a) * (b)"
@test mstatement(:(a / b)) == "(a) / (b)"
@test mstatement(:(a \ b)) == "(a) \\ (b)"
@test mstatement(:(a ^ b)) == "(a) ^ (b)"

@test mstatement(:(a .+ b)) == "(a) .+ (b)"
@test mstatement(:(a .- b)) == "(a) .- (b)"
@test mstatement(:(a .* b)) == "(a) .* (b)"
@test mstatement(:(a ./ b)) == "(a) ./ (b)"
@test mstatement(:(a .^ b)) == "(a) .^ (b)"

@test mstatement(:(sin(x))) == "sin(x)"
@test mstatement(:(hypot(x, y))) == "hypot(x, y)"
@test mstatement(:(plot3(x, y, z))) == "plot3(x, y, z)"

@test mstatement(:(x * 2)) == "(x) * (2)"

@test mstatement(:(y = x(1) + x(2))) == "y = (x(1)) + (x(2))"

@test mstatement(:([1 2 3])) == "[1, 2, 3]"
@test mstatement(:([x; y; z])) == "[x; y; z]"
@test mstatement(:([1 2 3; 4 5 6])) == "[[1, 2, 3]; [4, 5, 6]]"
@test mstatement(:({1, 2, 3})) == "{1, 2, 3}"
@test mstatement(:({1 2 3; 4 5 6})) == "{1 2 3; 4 5 6}"

@test mstatement(:(a{1})) == "a{1}"
@test mstatement(:(a{1, 1})) == "a{1, 1}"

@test mstatement(:(x')) == "(x)'"
@test mstatement(:(x.')) == "(x).'"

@test mstatement(:(plot(x, y, 'r'))) == "plot(x, y, 'r')"
@test mstatement(:(plot(x, y, "r"))) == "plot(x, y, 'r')"

@test mstatement(:((x, y) = fun(z))) == "[x, y] = fun(z)"
