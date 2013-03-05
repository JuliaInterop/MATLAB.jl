# Unit testing for MxArray

using MATLAB
using Test

m = 5
n = 6

# test basic types in 1D & 2D

macro mx_test_basic_types(ty)
	quote
		a = mxarray($(ty), n)
		@test elsize(a) == sizeof($(ty))
		@test eltype(a) === $(ty)
		@test nrows(a) == n
		@test ncols(a) == 1
		@test nelems(a) == n
		@test ndims(a) == 2
		delete(a)
		
		b = mxarray($(ty), m, n)
		@test elsize(a) == sizeof($(ty))
		@test eltype(a) === $(ty)
		@test nrows(a) == m
		@test ncols(a) == n
		@test nelems(a) == m * n
		@test ndims(a) == 2
		delete(b)
	end
end

@mx_test_basic_types Float64
@mx_test_basic_types Float32
@mx_test_basic_types Int64
@mx_test_basic_types Uint64
@mx_test_basic_types Int32
@mx_test_basic_types Uint32
@mx_test_basic_types Int16
@mx_test_basic_types Uint16
@mx_test_basic_types Int8
@mx_test_basic_types Uint8
@mx_test_basic_types Bool

# test conversion between Julia and MATLAB array

a = rand(5, 6)
a_mx = mxarray(a)
a2 = jarray(a_mx)

@test isequal(a, a2)
delete(a_mx)

a = rand(1)
a_mx = mxarray(a)
av = jscalar(a_mx)

@test av == a[1]
delete(a_mx)

a = rand(5)
a_mx = mxarray(a)
a2 = jvector(a_mx)
@test isequal(a, a2)
delete(a_mx)

a_t = reshape(a, 1, 5)
a_mx = mxarray(a_t)
a2 = jvector(a_mx)
@test isequal(a, a2)
delete(a_mx)


