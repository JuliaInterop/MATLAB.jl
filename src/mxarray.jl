# functions to deal with MATLAB arrays

type MxArray
    ptr::Ptr{Void}
    own::Bool
    
    function MxArray(p::Ptr{Void}, own::Bool)
        mx = new(p, own)
        if own
            finalizer(mx, delete)
        end
        mx
    end
    
    MxArray(p::Ptr{Void}) = MxArray(p, true)
end

# delete & duplicate

function delete(mx::MxArray)
    if mx.own && !(mx.ptr == C_NULL)
        ccall(mxfunc(:mxDestroyArray), Void, (Ptr{Void},), mx.ptr)
    end
    mx.ptr = C_NULL
end

function duplicate(mx::MxArray)
    pm::Ptr{Void} = ccall(mxfunc(:mxDuplicateArray), Ptr{Void}, (Ptr{Void},), mx.ptr)
    MxArray(pm)
end

copy(mx::MxArray) = duplicate(mx)

# functions to create mxArray from Julia values/arrays

MxNumerics = Union(Float64,Float32,Int32,Uint32,Int64,Uint64,Int16,Uint16,Int8,Uint8)
MxNumOrBool = Union(MxNumerics, Bool)

###########################################################
#
#  MATLAB types
#
###########################################################

typealias mwSize Uint
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

mxclassid(ty::Type{Bool})    = mxCELL_CLASS::Cint
mxclassid(ty::Type{Float64}) = mxDOUBLE_CLASS::Cint
mxclassid(ty::Type{Float32}) = mxSINGLE_CLASS::Cint
mxclassid(ty::Type{Int8})    = mxINT8_CLASS::Cint
mxclassid(ty::Type{Uint8})   = mxUINT8_CLASS::Cint
mxclassid(ty::Type{Int16})   = mxINT16_CLASS::Cint
mxclassid(ty::Type{Uint16})  = mxUINT16_CLASS::Cint
mxclassid(ty::Type{Int32})   = mxINT32_CLASS::Cint
mxclassid(ty::Type{Uint32})  = mxUINT32_CLASS::Cint
mxclassid(ty::Type{Int64})   = mxINT64_CLASS::Cint
mxclassid(ty::Type{Uint64})  = mxUINT64_CLASS::Cint

const classid_type_map = (mxClassID=>Type)[
    mxLOGICAL_CLASS => Bool,
    mxCHAR_CLASS    => Char,
    mxDOUBLE_CLASS  => Float64,
    mxSINGLE_CLASS  => Float32,
    mxINT8_CLASS    => Int8,
    mxUINT8_CLASS   => Uint8,
    mxINT16_CLASS   => Int16,
    mxUINT16_CLASS  => Uint16,
    mxINT32_CLASS   => Int32,
    mxUINT32_CLASS  => Uint32,
    mxINT64_CLASS   => Int64,
    mxUINT64_CLASS  => Uint64
]

function mxclassid_to_type(cid::mxClassID)
    ty = get(classid_type_map::Dict{mxClassID, Type}, cid, nothing)
    if ty == nothing
        throw(ArgumentError("The input class id is not a primitive type id."))
    end
    ty
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


# getting simple attributes

macro mxget_attr(fun, ret)
    :( ccall($(fun)::Ptr{Void}, $(ret), (Ptr{Void},), mx.ptr) )
end

classid(mx::MxArray) = @mxget_attr(_mx_get_classid, mxClassID)
nrows(mx::MxArray)   = convert(Int, @mxget_attr(_mx_get_m, Uint))
ncols(mx::MxArray)   = convert(Int, @mxget_attr(_mx_get_n, Uint))
nelems(mx::MxArray)  = convert(Int, @mxget_attr(_mx_get_nelems, Uint))
ndims(mx::MxArray)   = convert(Int, @mxget_attr(_mx_get_ndims, mwSize))

eltype(mx::MxArray)  = mxclassid_to_type(classid(mx))
elsize(mx::MxArray)  = convert(Int, @mxget_attr(_mx_get_elemsize, Uint))
data_ptr(mx::MxArray) = convert(Ptr{eltype(mx)}, @mxget_attr(_mx_get_data, Ptr{Void}))

nfields(mx::MxArray) = convert(Int, @mxget_attr(_mx_get_nfields, Cint))

# validation functions

macro mx_test_is(fun)
    :( ccall($(fun)::Ptr{Void}, Bool, (Ptr{Void},), mx.ptr) )
end

is_double(mx::MxArray) = @mx_test_is(_mx_is_double)
is_single(mx::MxArray) = @mx_test_is(_mx_is_single)
is_int64(mx::MxArray)  = @mx_test_is(_mx_is_int64)
is_uint64(mx::MxArray) = @mx_test_is(_mx_is_uint64)
is_int32(mx::MxArray)  = @mx_test_is(_mx_is_int32)
is_uint32(mx::MxArray) = @mx_test_is(_mx_is_uint32)
is_int16(mx::MxArray)  = @mx_test_is(_mx_is_int16)
is_uint16(mx::MxArray) = @mx_test_is(_mx_is_uint16)
is_int8(mx::MxArray)   = @mx_test_is(_mx_is_int8)
is_uint8(mx::MxArray)  = @mx_test_is(_mx_is_uint8)

is_numeric(mx::MxArray) = @mx_test_is(_mx_is_numeric)
is_logical(mx::MxArray) = @mx_test_is(_mx_is_logical)
is_complex(mx::MxArray) = @mx_test_is(_mx_is_complex)
is_sparse(mx::MxArray)  = @mx_test_is(_mx_is_sparse)
is_struct(mx::MxArray)  = @mx_test_is(_mx_is_struct)
is_cell(mx::MxArray)    = @mx_test_is(_mx_is_cell)
is_char(mx::MxArray)    = @mx_test_is(_mx_is_char)
is_empty(mx::MxArray)   = @mx_test_is(_mx_is_empty)

# size function

function size(mx::MxArray)
    nd = ndims(mx)
    pdims::Ptr{mwSize} = @mxget_attr(_mx_get_dims, Ptr{mwSize})
    _dims = pointer_to_array(pdims, (nd,), false)
    dims = Array(Int, nd)
    for i = 1 : nd
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
        pdims::Ptr{mwSize} = @mxget_attr(_mx_get_dims, Ptr{mwSize})
        _dims = pointer_to_array(pdims, (nd,), false)
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
const _mx_create_logical_mat = mxfunc(:mxCreateLogicalMatrix_730)

const _mx_create_numeric_arr = mxfunc(:mxCreateNumericArray_730)
const _mx_create_logical_arr = mxfunc(:mxCreateLogicalArray_730)

const _mx_create_double_scalar = mxfunc(:mxCreateDoubleScalar)
const _mx_create_logical_scalar = mxfunc(:mxCreateLogicalScalar)

const _mx_create_sparse = mxfunc(:mxCreateSparse_730)
const _mx_create_sparse_logical = mxfunc(:mxCreateSparseLogicalMatrix_730)

const _mx_create_string = mxfunc(:mxCreateString)
#const _mx_create_char_array = mxfunc(:mxCreateCharArray_730)

const _mx_create_cell_matrix = mxfunc(:mxCreateCellMatrix_730)
const _mx_create_cell_array = mxfunc(:mxCreateCellArray_730)

const _mx_create_struct_matrix = mxfunc(:mxCreateStructMatrix_730)
const _mx_create_struct_array = mxfunc(:mxCreateStructArray_730)

const _mx_get_cell = mxfunc(:mxGetCell_730)
const _mx_set_cell = mxfunc(:mxSetCell_730)

const _mx_get_field = mxfunc(:mxGetField_730)
const _mx_set_field = mxfunc(:mxSetField_730)
const _mx_get_field_bynum = mxfunc(:mxGetFieldByNumber_730)
const _mx_get_fieldname = mxfunc(:mxGetFieldNameByNumber)

# create zero arrays

function mxarray{T<:MxNumerics}(ty::Type{T}, n::Integer)
    pm = ccall(_mx_create_numeric_mat, Ptr{Void}, 
        (mwSize, mwSize, mxClassID, mxComplexity),
        n, 1, mxclassid(T), mxREAL)
    MxArray(pm)
end

function mxarray{T<:MxNumerics}(ty::Type{T}, m::Integer, n::Integer)
    pm = ccall(_mx_create_numeric_mat, Ptr{Void}, 
        (mwSize, mwSize, mxClassID, mxComplexity),
        m, n, mxclassid(T), mxREAL)
    MxArray(pm)
end

mxempty() = mxarray(Float64, 0, 0)

function mxarray(ty::Type{Bool}, n::Integer)
    pm = ccall(_mx_create_logical_mat, Ptr{Void}, (mwSize, mwSize), n, 1)
    MxArray(pm)
end

function mxarray(ty::Type{Bool}, m::Integer, n::Integer)
    pm = ccall(_mx_create_logical_mat, Ptr{Void}, (mwSize, mwSize), m, n)
    MxArray(pm)
end

function _dims_to_mwSize(dims::(Int...))
    ndim = length(dims)
    _dims = Array(mwSize, ndim)
    for i = 1 : ndim
        _dims[i] = convert(mwSize, dims[i])
    end
    _dims
end

function mxarray{T<:MxNumerics}(ty::Type{T}, dims::(Int...))
    pm = ccall(_mx_create_numeric_arr, Ptr{Void}, 
        (mwSize, Ptr{mwSize}, mxClassID, mxComplexity), 
        length(dims), _dims_to_mwSize(dims), mxclassid(ty), mxREAL)
        
    MxArray(pm)
end

function mxarray(ty::Type{Bool}, dims::(Int...))
    pm = ccall(_mx_create_numeric_arr, Ptr{Void}, 
        (mwSize, Ptr{mwSize}), length(dims), _dims_to_mwSize(dims))
    MxArray(pm)
end

# create scalars

function mxarray(x::Float64)
    pm = ccall(_mx_create_double_scalar, Ptr{Void}, (Cdouble,), x)
    MxArray(pm)
end

function mxarray(x::Bool)
    pm = ccall(_mx_create_logical_scalar, Ptr{Void}, (Bool,), x)
    MxArray(pm)
end

function mxarray{T<:MxNumerics}(x::T)
    pm = ccall(_mx_create_numeric_mat, Ptr{Void}, 
        (mwSize, mwSize, mxClassID, mxComplexity),
        1, 1, mxclassid(T), mxREAL)
        
    pdat = convert(Ptr{T}, ccall(_mx_get_data, Ptr{Void}, (Ptr{Void},), pm))
    
    pointer_to_array(pdat, (1,), false)[1] = x
    MxArray(pm)
end

# conversion from Julia variables to MATLAB
# Note: the conversion is deep-copy, as there is no way to let
# mxArray use Julia array's memory

function mxarray{T<:MxNumOrBool}(a::Vector{T})
    n = length(a)
    pm = mxarray(T, n)
    ccall(:memcpy, Ptr{Void}, (Ptr{Void}, Ptr{Void}, Uint),
        data_ptr(pm), a, n * sizeof(T))
    pm
end

function mxarray{T<:MxNumOrBool}(a::Matrix{T})
    m = size(a, 1)
    n = size(a, 2)
    mx = mxarray(T, m, n)
    ccall(:memcpy, Ptr{Void}, (Ptr{Void}, Ptr{Void}, Uint),
        data_ptr(mx), a, m * n * sizeof(T))
    mx
end

function mxarray{T<:MxNumOrBool}(a::Array{T})
    mx = mxarray(T, size(a))
    ccall(:memcpy, Ptr{Void}, (Ptr{Void}, Ptr{Void}, Uint),
        data_ptr(mx), a, length(a) * sizeof(T))
    mx
end

mxarray(a::BitArray) = mxarray(convert(Array{Bool}, a))

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
    
    ir = pointer_to_array(ir_p, (nnz,), false)
    for i = 1 : nnz    
        ir[i] = rinds[i] - 1
    end
    
    jc = pointer_to_array(jc_p, (n+1,), false)
    for i = 1 : n+1
        jc[i] = colptr[i] - 1
    end
    
    ccall(:memcpy, Ptr{Void}, (Ptr{Void}, Ptr{Void}, Uint), pr_p, v, nnz * sizeof(V))
end

function mxarray{V<:Union(Float64,Bool),I}(a::SparseMatrixCSC{V,I})
    m::Int = a.m
    n::Int = a.n
    nnz = length(a.nzval)
    @assert nnz == a.colptr[n+1]-1
    
    mx = mxsparse(V, m, n, nnz)
    
    ir_p = ccall(_mx_get_ir, Ptr{mwIndex}, (Ptr{Void},), mx.ptr)
    jc_p = ccall(_mx_get_jc, Ptr{mwIndex}, (Ptr{Void},), mx.ptr)
    pr_p = ccall(_mx_get_pr, Ptr{V}, (Ptr{Void},), mx.ptr)

    _copy_sparse_mat(a, ir_p, jc_p, pr_p)
    mx
end


# char arrays and string

function mxarray(s::ASCIIString)
    pm = ccall(_mx_create_string, Ptr{Void}, (Ptr{Uint8},), s)
    MxArray(pm)
end

# cell arrays

function mxcellarray(n::Integer)
    pm = ccall(_mx_create_cell_matrix, Ptr{Void}, (mwSize, mwSize), n, 1)
    MxArray(pm)
end

function mxcellarray(m::Integer, n::Integer)
    pm = ccall(_mx_create_cell_matrix, Ptr{Void}, (mwSize, mwSize), m, n)
    MxArray(pm)
end

function mxcellarray(dims::(Int...))
    pm = ccall(_mx_create_cell_array, Ptr{Void}, (mwSize, Ptr{mwSize}), 
        length(dims), _dims_to_mwSize(dims))
    MxArray(pm) 
end

function get_cell(mx::MxArray, i::Integer)
    pm = ccall(_mx_get_cell, Ptr{Void}, (Ptr{Void}, mwIndex), mx.ptr, i-1)
    MxArray(pm, false)
end

function set_cell(mx::MxArray, i::Integer, v::MxArray)    
    v.own = false
    ccall(_mx_set_cell, Void, (Ptr{Void}, mwIndex, Ptr{Void}), 
        mx.ptr, i - 1, v.ptr)
end

function mxcellarray(a::Vector)
    n = length(a)
    pm = mxcellarray(n)
    for i = 1 : n
        set_cell(pm, i, mxarray(a[i]))
    end
    pm
end

function mxcellarray(a::Matrix)
    m = size(a, 1)
    n = size(a, 2)
    pm = mxcellarray(m, n)
    for i = 1 : m * n
        set_cell(pm, i, mxarray(a[i]))
    end
    pm
end

function mxcellarray(a::Array)
    pm = mxcellarray(size(a))
    for i = 1 : length(a)
        set_cell(pm, i, mxarray(a[i]))
    end
    pm
end

mxarray(a::Array) = mxcellarray(a)

# struct arrays

function _fieldname_array(fieldnames::ASCIIString...)
    n = length(fieldnames)
    a = Array(Ptr{Uint8}, n)
    for i = 1 : n
        a[i] = convert(Ptr{Uint8}, fieldnames[i])
    end
    a
end

function mxstruct(fns::Vector{ASCIIString})
    a = _fieldname_array(fns...)
    pm = ccall(_mx_create_struct_matrix, Ptr{Void}, 
        (mwSize, mwSize, Cint, Ptr{Ptr{Uint8}}), 
        1, 1, length(a), a)
    MxArray(pm)
end

function mxstruct(fn1::ASCIIString, fnr::ASCIIString...)
    a = _fieldname_array(fn1, fnr...)
    pm = ccall(_mx_create_struct_matrix, Ptr{Void}, 
        (mwSize, mwSize, Cint, Ptr{Ptr{Uint8}}), 
        1, 1, length(a), a)
    MxArray(pm)
end

function set_field(mx::MxArray, i::Integer, f::ASCIIString, v::MxArray)
    v.own = false
    ccall(_mx_set_field, Void, 
        (Ptr{Void}, mwIndex, Ptr{Uint8}, Ptr{Void}), 
        mx.ptr, i-1, f, v.ptr)
end

set_field(mx::MxArray, f::ASCIIString, v::MxArray) = set_field(mx, 1, f, v)

function get_field(mx::MxArray, i::Integer, f::ASCIIString)
    pm = ccall(_mx_get_field, Ptr{Void}, (Ptr{Void}, mwIndex, Ptr{Uint8}), 
        mx.ptr, i-1, f)
    if pm == C_NULL
        throw(ArgumentError("Failed to get field."))
    end
    MxArray(pm, false)
end

get_field(mx::MxArray, f::ASCIIString) = get_field(mx, 1, f)

function get_field(mx::MxArray, i::Integer, fn::Integer)
    pm = ccall(_mx_get_field_bynum, Ptr{Void}, (Ptr{Void}, mwIndex, Cint), 
        mx.ptr, i-1, fn-1)
    if pm == C_NULL
        throw(ArgumentError("Failed to get field."))
    end
    MxArray(pm, false)
end

get_field(mx::MxArray, fn::Integer) = get_field(mx, 1, fn)


function get_fieldname(mx::MxArray, i::Integer)
    p = ccall(_mx_get_fieldname, Ptr{Uint8}, (Ptr{Void}, Cint), 
        mx.ptr, i-1)
    bytestring(p)
end

function mxstruct(pairs::NTuple{2}...)
    nf = length(pairs)
    fieldnames = Array(ASCIIString, nf)
    for i = 1 : nf
        fn = pairs[i][1]
        fieldnames[i] = string(fn)
    end
    mx = mxstruct(fieldnames)
    for i = 1 : nf
        set_field(mx, fieldnames[i], mxarray(pairs[i][2]))
    end
    mx
end

function mxstruct{T}(d::T)
    fieldnames = T.names
    fieldnames_str = map(string, fieldnames)
    mx = mxstruct(fieldnames_str...)
    for i = 1:length(fieldnames)
        set_field(mx, fieldnames_str[i], mxarray(getfield(d, fieldnames[i])))
    end
    mx
end

function mxstructarray{T}(d::Array{T})
    fieldnames = T.names
    fieldnames_str = map(string, fieldnames)
    a = _fieldname_array(fieldnames_str...)

    pm = ccall(_mx_create_struct_array, Ptr{Void}, (mwSize, Ptr{mwSize}, Cint,
        Ptr{Ptr{Uint8}}), ndims(d), _dims_to_mwSize(size(d)), length(a), a)
    mx = MxArray(pm)

    for i = 1:length(d), j = 1:length(fieldnames)
        set_field(mx, i, fieldnames_str[j],
            mxarray(getfield(d[i], fieldnames[j])))
    end
    mx
end

mxstruct(d::Associative) = mxstruct(collect(d)...)
mxarray(d) = mxstruct(d)


###########################################################
#
#  convert from MATLAB to Julia
#
###########################################################

const _mx_get_string = mxfunc(:mxGetString_730)

# shallow conversion from MATLAB variable to Julia array

function _jarrayx(fun::String, mx::MxArray, siz::Tuple)
    if is_numeric(mx) || is_logical(mx)
        @assert !is_sparse(mx)
        T = eltype(mx)
        a = Array(T, siz)
        ccall(:memcpy, Ptr{Void}, (Ptr{Void}, Ptr{Void}, Uint), 
            a, data_ptr(mx), sizeof(T) * length(a))
        a
        #pointer_to_array(data_ptr(mx), siz, false)
    elseif is_cell(mx)
        a = Array(Any, siz)
        for i = 1 : length(a)
            a[i] = jvariable(get_cell(mx, i))
        end
        a
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
    _jarrayx("jmatrix", mx, (nrows(mx), ncols(mx)))
end

function jscalar(mx::MxArray)
    if !(nelems(mx) == 1 && (is_logical(mx) || is_numeric(mx)))
        throw(ArgumentError("jscalar only applies to numeric or logical arrays with exactly one element."))
    end
    @assert !is_sparse(mx)
    pointer_to_array(data_ptr(mx), (1,), false)[1]
end

function _jsparse{T<:MxNumOrBool}(ty::Type{T}, mx::MxArray)
    m = nrows(mx)
    n = ncols(mx)
    ir_ptr = ccall(_mx_get_ir, Ptr{mwIndex}, (Ptr{Void},), mx.ptr)
    jc_ptr = ccall(_mx_get_jc, Ptr{mwIndex}, (Ptr{Void},), mx.ptr)
    pr_ptr = ccall(_mx_get_pr, Ptr{T}, (Ptr{Void},), mx.ptr)
    
    jc_a::Vector{mwIndex} = pointer_to_array(jc_ptr, (n+1,), false)
    nnz = jc_a[n+1]
    
    ir = Array(Int, nnz)
    jc = Array(Int, n+1)
    
    ir_x = pointer_to_array(ir_ptr, (nnz,), false)
    for i = 1 : nnz
        ir[i] = ir_x[i] + 1
    end
    
    jc_x = pointer_to_array(jc_ptr, (n+1,), false)
    for i = 1 : n+1
        jc[i] = jc_x[i] + 1
    end
    
    pr::Vector{T} = copy(pointer_to_array(pr_ptr, (nnz,), false))
    SparseMatrixCSC(m, n, jc, ir, pr)
end


function jsparse(mx::MxArray)
    if !is_sparse(mx)
        throw(ArgumentError("jsparse only applies to sparse matrices."))
    end
    _jsparse(eltype(mx), mx)
end


function jstring(mx::MxArray)
    if !(classid(mx) == mxCHAR_CLASS && ndims(mx) == 2 && nrows(mx) == 1)
        throw(ArgumentError("jstring only applies to strings (i.e. char vectors)."))
    end
    len = ncols(mx) + 2
    tmp = Array(Uint8, len)
    ccall(_mx_get_string, Cint, (Ptr{Void}, Ptr{Uint8}, mwSize), 
        mx.ptr, tmp, len)
    bytestring(pointer(tmp))
end

function jdict(mx::MxArray)
    if !(is_struct(mx) && nelems(mx) == 1)
        throw(ArgumentError("jdict only applies to a single struct."))
    end
    nf = nfields(mx)
    fnames = Array(String, nf)
    fvals = Array(Any, nf)
    for i = 1 : nf
        fnames[i] = get_fieldname(mx, i)
        pv::Ptr{Void} = ccall(_mx_get_field_bynum, 
            Ptr{Void}, (Ptr{Void}, mwIndex, Cint),
            mx.ptr, 0, i-1)
        fx = MxArray(pv, false)
        fvals[i] = jvariable(fx)
    end
    Dict(fnames, fvals)
end

function jvariable(mx::MxArray)
    if is_numeric(mx) || is_logical(mx)
        if !is_sparse(mx)
            nelems(mx) == 1 ? jscalar(mx) :
            ndims(mx) == 2 ? (ncols(mx) == 1 ? jvector(mx) : jmatrix(mx)) :
            jarray(mx)
        else
            jsparse(mx)
        end
    elseif is_char(mx) && nrows(mx) == 1
        jstring(mx)
    elseif is_cell(mx)
        ndims(mx) == 2 ? (ncols(mx) == 1 ? jvector(mx) : jmatrix(mx)) :
        jarray(mx)
    elseif is_struct(mx) && nelems(mx) == 1
        jdict(mx)    
    else
        throw(ArgumentError("Unsupported kind of variable."))
    end
end

# deep conversion from MATLAB variable to Julia array

jvariable(mx::MxArray, ty::Type{Array})  = jarray(mx)
jvariable(mx::MxArray, ty::Type{Vector}) = jvector(mx)
jvariable(mx::MxArray, ty::Type{Matrix}) = jmatrix(mx)
jvariable(mx::MxArray, ty::Type{Number}) = jscalar(mx)::Number
jvariable(mx::MxArray, ty::Type{String}) = jstring(mx)::ASCIIString
jvariable(mx::MxArray, ty::Type{ASCIIString}) = jstring(mx)::ASCIIString
jvariable(mx::MxArray, ty::Type{Dict}) = jdict(mx)
jvariable(mx::MxArray, ty::Type{SparseMatrixCSC}) = jsparse(mx)

