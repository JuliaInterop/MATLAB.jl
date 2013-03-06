# functions to deal with MATLAB arrays

type MxArray
    ptr::Ptr{Void}
    
    function MxArray(p::Ptr{Void})
        mx = new(p)
        finalizer(mx, delete)
        mx
    end
end

# delete & duplicate

function delete(mx::MxArray)
    if !(mx.ptr == C_NULL)
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

const _mx_create_string = mxfunc(:mxCreateString)
#const _mx_create_char_array = mxfunc(:mxCreateCharArray_730)

const _mx_create_cell_matrix = mxfunc(:mxCreateCellMatrix_730)
const _mx_create_cell_array = mxfunc(:mxCreateCellArray_730)

const _mx_create_struct_matrix = mxfunc(:mxCreateStructMatrix_730)
const _mx_create_struct_array = mxfunc(:mxCreateStructArray_730)


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

function mxarray{T<:MxNumerics}(ty::Type{T}, dims::Tuple)
    ndim = length(dims)
    _dims = Array(mwSize, ndim)
    for i = 1 : ndim
        _dims[i] = convert(mwSize, dims[i])
    end
        
    pm = ccall(_mx_create_numeric_arr, Ptr{Void}, 
        (mwSize, Ptr{mwSize}, mxClassID, mxComplexity), 
        ndim, _dims, mxclassid(ty), mxREAL)
        
    MxArray(pm)
end

function mxarray(ty::Type{Bool}, dims::Tuple)
    ndim = length(dims)
    _dims = Array(mwSize, ndim)
    for i = 1 : ndim
        _dims[i] = convert(mwSize, dims[i])
    end
        
    pm = ccall(_mx_create_numeric_arr, Ptr{Void}, 
        (mwSize, Ptr{mwSize}), ndim, _dims)
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

# char arrays and string

function mxarray(s::ASCIIString)
    pm = ccall(_mx_create_string, Ptr{Void}, (Ptr{Uint8},), s)
    MxArray(pm)
end

###########################################################
#
#  convert from MATLAB to Julia
#
###########################################################

const _mx_get_string = mxfunc(:mxGetString_730)

# shallow conversion from MATLAB variable to Julia array

function jarray(mx::MxArray)
    pointer_to_array(data_ptr(mx), size(mx), false)
end

function jvector(mx::MxArray)
    pointer_to_array(data_ptr(mx), (nelems(mx),), false)
end

function jmatrix(mx::MxArray)
    if ndims(mx) != 2
        throw(ArgumentError("jmatrix only applies to MATLAB arrays with ndims == 2."))
    end
    jarray(mx)
end

function jscalar(mx::MxArray)
    if nelems(mx) != 1
        throw(ArgumentError("jscalar only applies to MATLAB arrays with exactly one element."))
    end
    pointer_to_array(data_ptr(mx), (1,), false)[1]
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


# deep conversion from MATLAB variable to Julia array

function to_julia(mx::MxArray)
    is_char(mx) ? jstring(mx) : jarray(mx)
end

to_julia(mx::MxArray, ty::Type{Array}) = copy(jarray(mx))
to_julia(mx::MxArray, ty::Type{Vector}) = copy(jvector(mx))
to_julia(mx::MxArray, ty::Type{Matrix}) = copy(jmatrix(mx))
to_julia(mx::MxArray, ty::Type{Number}) = jscalar(mx)::Number
to_julia(mx::MxArray, ty::Type{String}) = jstring(mx)
to_julia(mx::MxArray, ty::Type{ASCIIString}) = jstring(mx)



