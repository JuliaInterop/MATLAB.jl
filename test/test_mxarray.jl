# Unit testing for MxArray

using MATLAB
using Test

m = 5
n = 6

# test basic types in 1D & 2D

macro mx_test_basic_types(ty, testfun)
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
        @test $(testfun)(a)
        delete(a)

        b = mxarray($(ty), m, n)
        @test elsize(b) == sizeof($(ty))
        @test eltype(b) === $(ty)
        @test nrows(b) == m
        @test ncols(b) == n
        @test nelems(b) == m * n
        @test ndims(b) == 2
        @test size(b) == (m, n)
        @test size(b, 1) == m
        @test size(b, 2) == n
        @test size(b, 3) == 1
        @test $(testfun)(b)
        delete(b)
    end
end

# empty array

a = mxempty()
@test nrows(a) == 0
@test ncols(a) == 0
@test nelems(a) == 0
@test ndims(a) == 2
@test eltype(a) == Float64
@test is_empty(a)

# basic arrays

@mx_test_basic_types Float64 is_double
@mx_test_basic_types Float32 is_single
@mx_test_basic_types Int64   is_int64
@mx_test_basic_types Uint64  is_uint64
@mx_test_basic_types Int32   is_int32
@mx_test_basic_types Uint32  is_uint32
@mx_test_basic_types Int16   is_int16
@mx_test_basic_types Uint16  is_uint16
@mx_test_basic_types Int8    is_int8
@mx_test_basic_types Uint8   is_uint8
@mx_test_basic_types Bool    is_logical

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
@test is_numeric(a)
@test !is_sparse(a)

a = mxarray(Bool, (6, 5, 4))
@test elsize(a) == 1
@test eltype(a) === Bool
@test size(a) == (6, 5, 4)
@test size(a, 1) == 6
@test size(a, 2) == 5
@test size(a, 3) == 4
@test size(a, 4) == 1
@test nelems(a) == 6 * 5 * 4
@test is_logical(a)
@test !is_sparse(a)

# scalars

a_mx = mxarray(3.25)
@test eltype(a_mx) == Float64
@test size(a_mx) == (1, 1)
@test jscalar(a_mx) == 3.25
delete(a_mx)

a_mx = mxarray(int32(12))
@test eltype(a_mx) == Int32
@test size(a_mx) == (1, 1)
@test jscalar(a_mx) == int32(12)
delete(a_mx)

a_mx = mxarray(true)
@test eltype(a_mx) == Bool
@test size(a_mx) == (1, 1)
@test jscalar(a_mx)
delete(a_mx)

a_mx = mxarray(false)
@test eltype(a_mx) == Bool
@test size(a_mx) == (1, 1)
@test !jscalar(a_mx)
delete(a_mx)

# conversion between Julia and MATLAB numeric arrays

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

# strings

s = "MATLAB.jl"
s_mx = mxarray(s)
@test classid(s_mx) == MATLAB.mxCHAR_CLASS
@test nrows(s_mx) == 1
@test ncols(s_mx) == length(s)
@test nelems(s_mx) == length(s)
@test ndims(s_mx) == 2
@test is_char(s_mx)

s2 = jstring(s_mx)
@test s == s2
delete(s_mx)

# cell arrays

a = mxcellarray(10)
@test nrows(a) == 10
@test ncols(a) == 1
@test nelems(a) == 10
@test classid(a) == MATLAB.mxCELL_CLASS
@test is_cell(a)
delete(a)

a = mxcellarray(4, 5)
@test nrows(a) == 4
@test ncols(a) == 5
@test nelems(a) == 20
@test classid(a) == MATLAB.mxCELL_CLASS
@test is_cell(a)
delete(a)

a = mxcellarray((3, 4, 5))
@test size(a) == (3, 4, 5)
@test nelems(a) == 60
@test classid(a) == MATLAB.mxCELL_CLASS
@test is_cell(a)
delete(a)

s = ["abc", "efg"]
s_mx = mxcellarray(s)
@test jstring(get_cell(s_mx, 1)) == "abc"
@test jstring(get_cell(s_mx, 2)) == "efg"
delete(s_mx)

# struct 

a = mxstruct("abc", "efg", "xyz")
@test is_struct(a)
@test nfields(a) == 3
@test nrows(a) == 1
@test ncols(a) == 1
@test nelems(a) == 1
@test ndims(a) == 2

@test get_fieldname(a, 1) == "abc"
@test get_fieldname(a, 2) == "efg"
@test get_fieldname(a, 3) == "xyz"
delete(a)

s = {"name"=>"MATLAB", "version"=>12.0, "data"=>[1,2,3]}
a = mxstruct(s)
# @test is_struct(a)
# @test nfields(a) == 3
# @test jstring(get_field(a, "name")) == "MATLAB"
# @test jscalar(get_field(a, "version")) == 12.0
# @test isequal(jvector(get_field(a, "data")), [1,2,3])
# delete(a)

#gc()


