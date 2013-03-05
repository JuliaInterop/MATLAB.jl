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
        @test size(a) == (n, 1)
        @test size(a, 1) == n
        @test size(a, 2) == 1
        @test size(a, 3) == 1
        delete(a)

        b = mxarray($(ty), m, n)
        @test elsize(a) == sizeof($(ty))
        @test eltype(a) === $(ty)
        @test nrows(a) == m
        @test ncols(a) == n
        @test nelems(a) == m * n
        @test ndims(a) == 2
        @test size(a) == (m, n)
        @test size(a, 1) == m
        @test size(a, 2) == n
        @test size(a, 3) == 1
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

# test creating multi-dimensional arrays

a = mxarray(Float64, (6, 5, 4))
@test elsize(a) == sizeof(Float64)
@test eltype(a) === Float64
@test size(a) == (6, 5, 4)
@test size(a, 1) == 6
@test size(a, 2) == 5
@test size(a, 3) == 4
@test size(a, 4) == 1
@test nelems(a) == 6 * 5 * 4

a = mxarray(Bool, (6, 5, 4))
@test elsize(a) == 1
@test eltype(a) === Bool
@test size(a) == (6, 5, 4)
@test size(a, 1) == 6
@test size(a, 2) == 5
@test size(a, 3) == 4
@test size(a, 4) == 1
@test nelems(a) == 6 * 5 * 4

# scalars

a_mx = mxscalar(3.25)
@test eltype(a_mx) == Float64
@test size(a_mx) == (1, 1)
@test jscalar(a_mx) == 3.25
delete(a_mx)

a_mx = mxscalar(int32(12))
@test eltype(a_mx) == Int32
@test size(a_mx) == (1, 1)
@test jscalar(a_mx) == int32(12)
delete(a_mx)

a_mx = mxscalar(true)
@test eltype(a_mx) == Bool
@test size(a_mx) == (1, 1)
@test jscalar(a_mx)
delete(a_mx)

a_mx = mxscalar(false)
@test eltype(a_mx) == Bool
@test size(a_mx) == (1, 1)
@test !jscalar(a_mx)
delete(a_mx)


# test conversion between Julia and MATLAB array

a = rand(5, 6)
a_mx = mxarray(a)
a2 = jarray(a_mx)
@test isequal(a, a2)
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


