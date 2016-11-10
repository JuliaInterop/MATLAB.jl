# functions to deal with MATLAB arrays

type MxArray
    ptr::Ptr{Void}
    own::Bool

    function MxArray(p::Ptr{Void}, own::Bool)
        p == C_NULL && error("NULL pointer for MxArray.")
        self = new(p, own)
        if own
            finalizer(self, release)
        end
        return self
    end
end
MxArray(p::Ptr{Void}) = MxArray(p, true)

mxarray(mx::MxArray) = mx


function release(mx::MxArray)
    if mx.own && mx.ptr != C_NULL
        ccall(mxfunc(:mxDestroyArray), Void, (Ptr{Void},), mx.ptr)
    end
    mx.ptr = C_NULL
    return nothing
end

# delete & copy

function delete(mx::MxArray)
    if mx.own
        ccall(mxfunc(:mxDestroyArray), Void, (Ptr{Void},), mx)
    end
    mx.ptr = C_NULL
    return nothing
end

function copy(mx::MxArray)
    pm = ccall(mxfunc(:mxDuplicateArray), Ptr{Void}, (Ptr{Void},), mx)
    return MxArray(pm)
end

function unsafe_convert(::Type{Ptr{Void}}, mx::MxArray)
    ptr = mx.ptr
    ptr == C_NULL && throw(UndefRefError())
    return ptr
end
# functions to create mxArray from Julia values/arrays

typealias MxRealNum Union{Float64,Float32,Int32,UInt32,Int64,UInt64,Int16,UInt16,Int8,UInt8,Bool}
typealias MxComplexNum Union{Complex64, Complex128}
typealias MxNum Union{MxRealNum, MxComplexNum}

###########################################################
#
#  MATLAB types
#
###########################################################

typealias mwSize UInt
typealias mwIndex Int
typealias mxClassID Cint
typealias mxComplexity Cint

const mxUNKNOWN_CLASS  = convert(mxClassID, 0)
const mxCELL_CLASS     = convert(mxClassID, 1)
const mxSTRUCT_CLASS   = convert(mxClassID, 2)
const mxLOGICAL_CLASS  = convert(mxClassID, 3)
const mxCHAR_CLASS     = convert(mxClassID, 4)
const mxVOID_CLASS     = convert(mxClassID, 5)
const mxDOUBLE_CLASS   = convert(mxClassID, 6)
const mxSINGLE_CLASS   = convert(mxClassID, 7)
const mxINT8_CLASS     = convert(mxClassID, 8)
const mxUINT8_CLASS    = convert(mxClassID, 9)
const mxINT16_CLASS    = convert(mxClassID, 10)
const mxUINT16_CLASS   = convert(mxClassID, 11)
const mxINT32_CLASS    = convert(mxClassID, 12)
const mxUINT32_CLASS   = convert(mxClassID, 13)
const mxINT64_CLASS    = convert(mxClassID, 14)
const mxUINT64_CLASS   = convert(mxClassID, 15)
const mxFUNCTION_CLASS = convert(mxClassID, 16)
const mxOPAQUE_CLASS   = convert(mxClassID, 17)
const mxOBJECT_CLASS   = convert(mxClassID, 18)

const mxREAL    = convert(mxComplexity, 0)
const mxCOMPLEX = convert(mxComplexity, 1)

mxclassid(::Type{Bool})    = mxLOGICAL_CLASS::Cint
mxclassid(::Union{Type{Float64}, Type{Complex128}}) = mxDOUBLE_CLASS::Cint
mxclassid(::Union{Type{Float32}, Type{Complex64}}) = mxSINGLE_CLASS::Cint
mxclassid(::Type{Int8})    = mxINT8_CLASS::Cint
mxclassid(::Type{UInt8})   = mxUINT8_CLASS::Cint
mxclassid(::Type{Int16})   = mxINT16_CLASS::Cint
mxclassid(::Type{UInt16})  = mxUINT16_CLASS::Cint
mxclassid(::Type{Int32})   = mxINT32_CLASS::Cint
mxclassid(::Type{UInt32})  = mxUINT32_CLASS::Cint
mxclassid(::Type{Int64})   = mxINT64_CLASS::Cint
mxclassid(::Type{UInt64})  = mxUINT64_CLASS::Cint

mxcomplexflag{T<:MxRealNum}(::Type{T})    = mxREAL
mxcomplexflag{T<:MxComplexNum}(::Type{T}) = mxCOMPLEX

const classid_type_map = Dict{mxClassID,Type}(
    mxLOGICAL_CLASS => Bool,
    mxCHAR_CLASS    => Char,
    mxDOUBLE_CLASS  => Float64,
    mxSINGLE_CLASS  => Float32,
    mxINT8_CLASS    => Int8,
    mxUINT8_CLASS   => UInt8,
    mxINT16_CLASS   => Int16,
    mxUINT16_CLASS  => UInt16,
    mxINT32_CLASS   => Int32,
    mxUINT32_CLASS  => UInt32,
    mxINT64_CLASS   => Int64,
    mxUINT64_CLASS  => UInt64
)

function mxclassid_to_type(cid::mxClassID)
    ty = get(classid_type_map, cid, nothing)
    ty === nothing && throw(ArgumentError("The input class id is not a primitive type id."))
    return ty
end


###########################################################
#
#  Functions to access mxArray
#
#  Part of the functions (e.g. mxGetNumberOfDimensions)
#  are actually a macro replacement of an internal
#  function name as (xxxx_730)
#
###########################################################

# pre-cached some useful functions

const _mx_free = mxfunc(:mxFree)

const _mx_get_classid = mxfunc(:mxGetClassID)
const _mx_get_m = mxfunc(:mxGetM)
const _mx_get_n = mxfunc(:mxGetN)
const _mx_get_nelems = mxfunc(:mxGetNumberOfElements)
const _mx_get_ndims  = mxfunc(:mxGetNumberOfDimensions_730)
const _mx_get_elemsize = mxfunc(:mxGetElementSize)
const _mx_get_data = mxfunc(:mxGetData)
const _mx_get_dims = mxfunc(:mxGetDimensions_730)
const _mx_get_nfields = mxfunc(:mxGetNumberOfFields)
const _mx_get_pr = mxfunc(:mxGetPr)
const _mx_get_pi = mxfunc(:mxGetPi)
const _mx_get_ir = mxfunc(:mxGetIr_730)
const _mx_get_jc = mxfunc(:mxGetJc_730)

const _mx_is_double = mxfunc(:mxIsDouble)
const _mx_is_single = mxfunc(:mxIsSingle)
const _mx_is_int64  = mxfunc(:mxIsInt64)
const _mx_is_uint64 = mxfunc(:mxIsUint64)
const _mx_is_int32  = mxfunc(:mxIsInt32)
const _mx_is_uint32 = mxfunc(:mxIsUint32)
const _mx_is_int16  = mxfunc(:mxIsInt16)
const _mx_is_uint16 = mxfunc(:mxIsUint16)
const _mx_is_int8   = mxfunc(:mxIsInt8)
const _mx_is_uint8  = mxfunc(:mxIsUint8)
const _mx_is_char   = mxfunc(:mxIsChar)

const _mx_is_numeric = mxfunc(:mxIsNumeric)
const _mx_is_logical = mxfunc(:mxIsLogical)
const _mx_is_complex = mxfunc(:mxIsComplex)
const _mx_is_sparse  = mxfunc(:mxIsSparse)
const _mx_is_empty   = mxfunc(:mxIsEmpty)
const _mx_is_struct  = mxfunc(:mxIsStruct)
const _mx_is_cell    = mxfunc(:mxIsCell)

macro mxget_attr(fun, ret, mx)
    :(ccall($(esc(fun))::Ptr{Void}, $(esc(ret)), (Ptr{Void},), $(esc(mx))))
end

classid(mx::MxArray) = @mxget_attr(_mx_get_classid, mxClassID, mx)
nrows(mx::MxArray)   = convert(Int, @mxget_attr(_mx_get_m, UInt, mx))
ncols(mx::MxArray)   = convert(Int, @mxget_attr(_mx_get_n, UInt, mx))
nelems(mx::MxArray)  = convert(Int, @mxget_attr(_mx_get_nelems, UInt, mx))
ndims(mx::MxArray)   = convert(Int, @mxget_attr(_mx_get_ndims, mwSize, mx))

eltype(mx::MxArray)  = mxclassid_to_type(classid(mx))
elsize(mx::MxArray)  = convert(Int, @mxget_attr(_mx_get_elemsize, UInt, mx))
data_ptr(mx::MxArray) = convert(Ptr{eltype(mx)}, @mxget_attr(_mx_get_data, Ptr{Void}, mx))
real_ptr(mx::MxArray) = convert(Ptr{eltype(mx)}, @mxget_attr(_mx_get_pr, Ptr{Void}, mx))
imag_ptr(mx::MxArray) = convert(Ptr{eltype(mx)}, @mxget_attr(_mx_get_pi, Ptr{Void}, mx))

mxnfields(mx::MxArray) = convert(Int, @mxget_attr(_mx_get_nfields, Cint, mx))

# validation functions

macro mx_test_is(fun, mx)
    :((ccall($(esc(fun))::Ptr{Void}, Bool, (Ptr{Void},), $(esc(mx)))))
end

is_double(mx::MxArray) = @mx_test_is(_mx_is_double, mx)
is_single(mx::MxArray) = @mx_test_is(_mx_is_single, mx)
is_int64(mx::MxArray)  = @mx_test_is(_mx_is_int64, mx)
is_uint64(mx::MxArray) = @mx_test_is(_mx_is_uint64, mx)
is_int32(mx::MxArray)  = @mx_test_is(_mx_is_int32, mx)
is_uint32(mx::MxArray) = @mx_test_is(_mx_is_uint32, mx)
is_int16(mx::MxArray)  = @mx_test_is(_mx_is_int16, mx)
is_uint16(mx::MxArray) = @mx_test_is(_mx_is_uint16, mx)
is_int8(mx::MxArray)   = @mx_test_is(_mx_is_int8, mx)
is_uint8(mx::MxArray)  = @mx_test_is(_mx_is_uint8, mx)

is_numeric(mx::MxArray) = @mx_test_is(_mx_is_numeric, mx)
is_logical(mx::MxArray) = @mx_test_is(_mx_is_logical, mx)
is_complex(mx::MxArray) = @mx_test_is(_mx_is_complex, mx)
is_sparse(mx::MxArray)  = @mx_test_is(_mx_is_sparse, mx)
is_struct(mx::MxArray)  = @mx_test_is(_mx_is_struct, mx)
is_cell(mx::MxArray)    = @mx_test_is(_mx_is_cell, mx)
is_char(mx::MxArray)    = @mx_test_is(_mx_is_char, mx)
is_empty(mx::MxArray)   = @mx_test_is(_mx_is_empty, mx)

# size function

function size(mx::MxArray)
    nd = ndims(mx)
    pdims::Ptr{mwSize} = @mxget_attr(_mx_get_dims, Ptr{mwSize}, mx)
    _dims = unsafe_wrap(Array, pdims, (nd,))
    dims = Array(Int, nd)
    for i = 1:nd
        dims[i] = convert(Int, _dims[i])
    end
    tuple(dims...)
end

function size(mx::MxArray, d::Integer)
    nd = ndims(mx)
    if d <= 0
        throw(ArgumentError("The dimension must be a positive integer."))
    end

    if nd == 2
        d == 1 ? nrows(mx) :
        d == 2 ? ncols(mx) : 1
    else
        pdims::Ptr{mwSize} = @mxget_attr(_mx_get_dims, Ptr{mwSize}, mx)
        _dims = unsafe_wrap(Array, pdims, (nd,))
        d <= nd ? convert(Int, _dims[d]) : 1
    end
end



###########################################################
#
#  functions to create & delete MATLAB arrays
#
###########################################################

# pre-cached functions

const _mx_create_numeric_mat = mxfunc(:mxCreateNumericMatrix_730)
const _mx_create_numeric_arr = mxfunc(:mxCreateNumericArray_730)

const _mx_create_double_scalar = mxfunc(:mxCreateDoubleScalar)
const _mx_create_logical_scalar = mxfunc(:mxCreateLogicalScalar)

const _mx_create_sparse = mxfunc(:mxCreateSparse_730)
const _mx_create_sparse_logical = mxfunc(:mxCreateSparseLogicalMatrix_730)

# const _mx_create_string = mxfunc(:mxCreateString)
const _mx_create_char_array = mxfunc(:mxCreateCharArray_730)

const _mx_create_cell_array = mxfunc(:mxCreateCellArray_730)

const _mx_create_struct_matrix = mxfunc(:mxCreateStructMatrix_730)
const _mx_create_struct_array = mxfunc(:mxCreateStructArray_730)

const _mx_get_cell = mxfunc(:mxGetCell_730)
const _mx_set_cell = mxfunc(:mxSetCell_730)

const _mx_get_field = mxfunc(:mxGetField_730)
const _mx_set_field = mxfunc(:mxSetField_730)
const _mx_get_field_bynum = mxfunc(:mxGetFieldByNumber_730)
const _mx_get_fieldname = mxfunc(:mxGetFieldNameByNumber)


function _dims_to_mwSize(dims::Tuple{Vararg{Int}})
    ndim = length(dims)
    _dims = Array(mwSize, ndim)
    for i = 1:ndim
        _dims[i] = convert(mwSize, dims[i])
    end
    _dims
end

function mxarray{T<:MxNum}(ty::Type{T}, dims::Tuple{Vararg{Int}})
    pm = ccall(_mx_create_numeric_arr, Ptr{Void},
        (mwSize, Ptr{mwSize}, mxClassID, mxComplexity),
        length(dims), _dims_to_mwSize(dims), mxclassid(ty), mxcomplexflag(ty))

    MxArray(pm)
end
mxarray{T<:MxNum}(ty::Type{T}, dims::Int...) = mxarray(ty, dims)

# create scalars

function mxarray(x::Float64)
    pm = ccall(_mx_create_double_scalar, Ptr{Void}, (Cdouble,), x)
    MxArray(pm)
end

function mxarray(x::Bool)
    pm = ccall(_mx_create_logical_scalar, Ptr{Void}, (Bool,), x)
    MxArray(pm)
end

function mxarray{T<:MxRealNum}(x::T)
    pm = ccall(_mx_create_numeric_mat, Ptr{Void},
        (mwSize, mwSize, mxClassID, mxComplexity),
        1, 1, mxclassid(T), mxcomplexflag(T))

    pdat = ccall(_mx_get_data, Ptr{T}, (Ptr{Void},), pm)

    unsafe_wrap(Array, pdat, (1,))[1] = x
    MxArray(pm)
end
mxarray{T<:MxComplexNum}(x::T) = mxarray([x])

# conversion from Julia variables to MATLAB
# Note: the conversion is deep-copy, as there is no way to let
# mxArray use Julia array's memory

function mxarray{T<:MxRealNum}(a::Array{T})
    mx = mxarray(T, size(a))
    ccall(:memcpy, Ptr{Void}, (Ptr{Void}, Ptr{Void}, UInt), data_ptr(mx), a, length(a)*sizeof(T))
    return mx
end

function mxarray{T<:MxComplexNum}(a::Array{T})
    mx = mxarray(T, size(a))
    na = length(a)
    rdat = unsafe_wrap(Array, real_ptr(mx), na)
    idat = unsafe_wrap(Array, imag_ptr(mx), na)
    for i = 1:na
        rdat[i] = real(a[i])
        idat[i] = imag(a[i])
    end
    mx
end

mxarray(a::BitArray) = mxarray(convert(Array{Bool}, a))
mxarray(a::Range) = mxarray([a;])

# sparse matrix

function mxsparse(ty::Type{Float64}, m::Integer, n::Integer, nzmax::Integer)
    pm = ccall(_mx_create_sparse, Ptr{Void},
        (mwSize, mwSize, mwSize, mxComplexity), m, n, nzmax, mxREAL)
    MxArray(pm)
end

function mxsparse(ty::Type{Bool}, m::Integer, n::Integer, nzmax::Integer)
    pm = ccall(_mx_create_sparse_logical, Ptr{Void},
        (mwSize, mwSize, mwSize), m, n, nzmax)
    MxArray(pm)
end

function _copy_sparse_mat{V,I}(a::SparseMatrixCSC{V,I},
    ir_p::Ptr{mwIndex}, jc_p::Ptr{mwIndex}, pr_p::Ptr{V})

    colptr::Vector{I} = a.colptr
    rinds::Vector{I} = a.rowval
    v::Vector{V} = a.nzval
    n::Int = a.n
    nnz::Int = length(v)

    # Note: ir and jc contain zero-based indices

    ir = unsafe_wrap(Array, ir_p, (nnz,))
    for i = 1:nnz
        ir[i] = rinds[i] - 1
    end

    jc = unsafe_wrap(Array, jc_p, (n+1,))
    for i = 1:n+1
        jc[i] = colptr[i] - 1
    end

    ccall(:memcpy, Ptr{Void}, (Ptr{Void}, Ptr{Void}, UInt), pr_p, v, nnz*sizeof(V))
end

function mxarray{V<:Union{Float64,Bool},I}(a::SparseMatrixCSC{V,I})
    m::Int = a.m
    n::Int = a.n
    nnz = length(a.nzval)
    @assert nnz == a.colptr[n+1]-1

    mx = mxsparse(V, m, n, nnz)

    ir_p = ccall(_mx_get_ir, Ptr{mwIndex}, (Ptr{Void},), mx)
    jc_p = ccall(_mx_get_jc, Ptr{mwIndex}, (Ptr{Void},), mx)
    pr_p = ccall(_mx_get_pr, Ptr{V}, (Ptr{Void},), mx)

    _copy_sparse_mat(a, ir_p, jc_p, pr_p)
    return mx
end


# char arrays and string

function mxarray(s::String)
    utf16string = transcode(UInt16, s)
    pm = ccall(_mx_create_char_array, Ptr{Void}, (mwSize, Ptr{mwSize},), 2,
               _dims_to_mwSize((1, length(utf16string))))
    mx = MxArray(pm)
    ccall(:memcpy, Ptr{Void}, (Ptr{Void}, Ptr{Void}, UInt), data_ptr(mx), utf16string,
          length(utf16string)*sizeof(UInt16))
    mx
end

# cell arrays

function mxcellarray(dims::Tuple{Vararg{Int}})
    pm = ccall(_mx_create_cell_array, Ptr{Void}, (mwSize, Ptr{mwSize}),
        length(dims), _dims_to_mwSize(dims))
    MxArray(pm)
end
mxcellarray(dims::Int...) = mxcellarray(dims)

function get_cell(mx::MxArray, i::Integer)
    pm = ccall(_mx_get_cell, Ptr{Void}, (Ptr{Void}, mwIndex), mx, i-1)
    MxArray(pm, false)
end

function set_cell(mx::MxArray, i::Integer, v::MxArray)
    v.own = false
    ccall(_mx_set_cell, Void, (Ptr{Void}, mwIndex, Ptr{Void}), mx, i - 1, v)
    return nothing
end

function mxcellarray(a::Array)
    pm = mxcellarray(size(a))
    for i = 1:length(a)
        set_cell(pm, i, mxarray(a[i]))
    end
    return pm
end

mxarray(a::Array) = mxcellarray(a)

# struct arrays

function _fieldname_array(fieldnames::String...)
    n = length(fieldnames)
    a = Array(Ptr{UInt8}, n)
    for i = 1:n
        a[i] = unsafe_convert(Ptr{UInt8}, fieldnames[i])
    end
    return a
end

function mxstruct(fns::Vector{String})
    a = _fieldname_array(fns...)
    pm = ccall(_mx_create_struct_matrix, Ptr{Void},
        (mwSize, mwSize, Cint, Ptr{Ptr{UInt8}}), 1, 1, length(a), a)
    MxArray(pm)
end

function mxstruct(fn1::String, fnr::String...)
    a = _fieldname_array(fn1, fnr...)
    pm = ccall(_mx_create_struct_matrix, Ptr{Void},
        (mwSize, mwSize, Cint, Ptr{Ptr{UInt8}}), 1, 1, length(a), a)
    MxArray(pm)
end

function set_field(mx::MxArray, i::Integer, f::String, v::MxArray)
    v.own = false
    ccall(_mx_set_field, Void, (Ptr{Void}, mwIndex, Ptr{UInt8}, Ptr{Void}), mx, i-1, f, v)
    return nothing
end

set_field(mx::MxArray, f::String, v::MxArray) = set_field(mx, 1, f, v)

function get_field(mx::MxArray, i::Integer, f::String)
    pm = ccall(_mx_get_field, Ptr{Void}, (Ptr{Void}, mwIndex, Ptr{UInt8}), mx, i-1, f)
    pm == C_NULL && throw(ArgumentError("Failed to get field."))
    MxArray(pm, false)
end

get_field(mx::MxArray, f::String) = get_field(mx, 1, f)

function get_field(mx::MxArray, i::Integer, fn::Integer)
    pm = ccall(_mx_get_field_bynum, Ptr{Void}, (Ptr{Void}, mwIndex, Cint), mx, i-1, fn-1)
    pm == C_NULL && throw(ArgumentError("Failed to get field."))
    MxArray(pm, false)
end

get_field(mx::MxArray, fn::Integer) = get_field(mx, 1, fn)


function get_fieldname(mx::MxArray, i::Integer)
    p = ccall(_mx_get_fieldname, Ptr{UInt8}, (Ptr{Void}, Cint), mx, i-1)
    unsafe_string(p)
end

typealias Pairs Union{Pair,NTuple{2}}

function mxstruct(pairs::Pairs...)
    nf = length(pairs)
    fieldnames = Array(String, nf)
    for i = 1:nf
        fn = pairs[i][1]
        fieldnames[i] = string(fn)
    end
    mx = mxstruct(fieldnames)
    for i = 1:nf
        set_field(mx, fieldnames[i], mxarray(pairs[i][2]))
    end
    return mx
end

function mxstruct{T}(d::T)
    names = fieldnames(T)
    names_str = map(string, names)
    mx = mxstruct(names_str...)
    for i = 1:length(names)
        set_field(mx, names_str[i], mxarray(getfield(d, names[i])))
    end
    mx
end

function mxstructarray{T}(d::Array{T})
    names = fieldnames(T)
    names_str = map(string, names)
    a = _fieldname_array(names_str...)

    pm = ccall(_mx_create_struct_array, Ptr{Void}, (mwSize, Ptr{mwSize}, Cint,
        Ptr{Ptr{UInt8}}), ndims(d), _dims_to_mwSize(size(d)), length(a), a)
    mx = MxArray(pm)

    for i = 1:length(d), j = 1:length(names)
        set_field(mx, i, names_str[j], mxarray(getfield(d[i], names[j])))
    end
    return mx
end

mxstruct(d::Associative) = mxstruct(collect(d)...)
mxarray(d) = mxstruct(d)


###########################################################
#
#  convert from MATLAB to Julia
#
###########################################################

# const _mx_get_string = mxfunc(:mxGetString_730)

# use deep-copy from MATLAB variable to Julia array
# in practice, MATLAB variable often has shorter life-cycle

function _jarrayx(fun::String, mx::MxArray, siz::Tuple)
    if is_numeric(mx) || is_logical(mx)
        @assert !is_sparse(mx)
        T = eltype(mx)
        if is_complex(mx)
            rdat = unsafe_wrap(Array, real_ptr(mx), siz)
            idat = unsafe_wrap(Array, imag_ptr(mx), siz)
            a = complex(rdat, idat)
        else
            a = Array(T, siz)
            if !isempty(a)
                ccall(:memcpy, Ptr{Void}, (Ptr{Void}, Ptr{Void}, UInt), a, data_ptr(mx), length(a)*sizeof(T))
            end
        end
        return a
        #unsafe_wrap(Array, data_ptr(mx), siz)
    elseif is_cell(mx)
        a = Array(Any, siz)
        for i = 1:length(a)
            a[i] = jvalue(get_cell(mx, i))
        end
        return a
    else
        throw(ArgumentError("$(fun) only applies to numeric, logical or cell arrays."))
    end
end

jarray(mx::MxArray) = _jarrayx("jarray", mx, size(mx))
jvector(mx::MxArray) = _jarrayx("jvector", mx, (nelems(mx),))

function jmatrix(mx::MxArray)
    if ndims(mx) != 2
        throw(ArgumentError("jmatrix only applies to MATLAB arrays with ndims == 2."))
    end
    return _jarrayx("jmatrix", mx, (nrows(mx), ncols(mx)))
end

function jscalar(mx::MxArray)
    if !(nelems(mx) == 1 && (is_logical(mx) || is_numeric(mx)))
        throw(ArgumentError("jscalar only applies to numeric or logical arrays with exactly one element."))
    end
    @assert !is_sparse(mx)
    if is_complex(mx)
        return unsafe_wrap(Array, real_ptr(mx), (1,))[1] + im*unsafe_wrap(Array, imag_ptr(mx), (1,))[1]
    else
        return unsafe_wrap(Array, data_ptr(mx), (1,))[1]
    end
end

function _jsparse{T<:MxRealNum}(ty::Type{T}, mx::MxArray)
    m = nrows(mx)
    n = ncols(mx)
    ir_ptr = ccall(_mx_get_ir, Ptr{mwIndex}, (Ptr{Void},), mx)
    jc_ptr = ccall(_mx_get_jc, Ptr{mwIndex}, (Ptr{Void},), mx)
    pr_ptr = ccall(_mx_get_pr, Ptr{T}, (Ptr{Void},), mx)

    jc_a::Vector{mwIndex} = unsafe_wrap(Array, jc_ptr, (n+1,))
    nnz = jc_a[n+1]

    ir = Array(Int, nnz)
    jc = Array(Int, n+1)

    ir_x = unsafe_wrap(Array, ir_ptr, (nnz,))
    for i = 1:nnz
        ir[i] = ir_x[i] + 1
    end

    jc_x = unsafe_wrap(Array, jc_ptr, (n+1,))
    for i = 1:n+1
        jc[i] = jc_x[i] + 1
    end

    pr::Vector{T} = copy(unsafe_wrap(Array, pr_ptr, (nnz,)))
    return SparseMatrixCSC(m, n, jc, ir, pr)
end

function jsparse(mx::MxArray)
    if !is_sparse(mx)
        throw(ArgumentError("jsparse only applies to sparse matrices."))
    end
    return _jsparse(eltype(mx), mx)
end

function String(mx::MxArray)
    if !(classid(mx) == mxCHAR_CLASS && ((ndims(mx) == 2 && nrows(mx) == 1) || is_empty(mx)))
        throw(ArgumentError("String(mx::MxArray) only applies to strings (i.e. char vectors)"))
    end
    return transcode(String, unsafe_wrap(Array, Ptr{UInt16}(data_ptr(mx)), ncols(mx)))
end

function Dict(mx::MxArray)
    if !(is_struct(mx) && nelems(mx) == 1)
        throw(ArgumentError("Dict(mx::MxArray) only applies to a single struct"))
    end
    nf = mxnfields(mx)
    fnames = Array(String, nf)
    fvals = Array(Any, nf)
    for i = 1:nf
        fnames[i] = get_fieldname(mx, i)
        pv::Ptr{Void} = ccall(_mx_get_field_bynum,
            Ptr{Void}, (Ptr{Void}, mwIndex, Cint), mx, 0, i-1)
        fx = MxArray(pv, false)
        fvals[i] = jvalue(fx)
    end
    Dict(zip(fnames, fvals))
end

function jvalue(mx::MxArray)
    if is_numeric(mx) || is_logical(mx)
        if !is_sparse(mx)
            nelems(mx) == 1 ? jscalar(mx) :
            ndims(mx) == 2 ? (ncols(mx) == 1 ? jvector(mx) : jmatrix(mx)) :
            jarray(mx)
        else
            jsparse(mx)
        end
    elseif is_char(mx) && (nrows(mx) == 1 || is_empty(mx))
        String(mx)
    elseif is_cell(mx)
        ndims(mx) == 2 ? (ncols(mx) == 1 ? jvector(mx) : jmatrix(mx)) :
        jarray(mx)
    elseif is_struct(mx) && nelems(mx) == 1
        Dict(mx)    
    else
        throw(ArgumentError("Unsupported kind of variable."))
    end
end

# deep conversion from MATLAB variable to Julia array

jvalue(mx::MxArray, ty::Type{Array})  = jarray(mx)
jvalue(mx::MxArray, ty::Type{Vector}) = jvector(mx)
jvalue(mx::MxArray, ty::Type{Matrix}) = jmatrix(mx)
jvalue(mx::MxArray, ty::Type{Number}) = jscalar(mx)::Number
jvalue(mx::MxArray, ty::Type{String}) = String(mx)
jvalue(mx::MxArray, ty::Type{Dict}) = Dict(mx)
jvalue(mx::MxArray, ty::Type{SparseMatrixCSC}) = jsparse(mx)

# legacy support (eventually drop, when all constructors added)
jdict(mx::MxArray) = Dict(mx)
jstring(mx::MxArray) = String(mx)
