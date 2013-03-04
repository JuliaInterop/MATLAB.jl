# functions to deal with MATLAB arrays

type MxArray
	ptr::Ptr{Void}
end

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
mxclassid(ty::Type{Char})    = mxCHAR_CLASS::Cint
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

mxget_attr(mx::MxArray, fun::Symbol, ret::Type) = ccall(mxfunc(fun), ret, (Ptr{Void},), mx.ptr)

classid(mx::MxArray) = mxget_attr(mx, :mxGetClassID, mxClassID)
nrows(mx::MxArray)   = mxget_attr(mx, :mxGetM, Uint)
ncols(mx::MxArray)   = mxget_attr(mx, :mxGetN, Uint)
nelems(mx::MxArray)  = mxget_attr(mx, :mxGetNumberOfElements, Uint)
ndims(mx::MxArray)   = mxget_attr(mx, :mxGetNumberOfDimensions_730, mwSize)

eltype(mx::MxArray)  = mxclassid_to_type(classid(mx))
elsize(mx::MxArray)  = mxget_attr(mx, :mxGetElementSize, Uint)

function data_ptr(mx::MxArray)
	p0::Ptr{Void} = mxget_attr(mx, :mxGetData, Ptr{Void})
	convert(Ptr{eltype(mx)}, p0)
end


###########################################################
#
#  functions to create & delete MATLAB arrays
#
###########################################################

# create zero arrays

function mxarray{T<:MxNumerics}(ty::Type{T}, n::Integer)
	pm = ccall(mxfunc(:mxCreateNumericMatrix_730), 
		Ptr{Void}, (mwSize, mwSize, mxClassID, mxComplexity), 
		n, 1, mxclassid(T), mxREAL)
	MxArray(pm)
end

function mxarray{T<:MxNumerics}(ty::Type{T}, m::Integer, n::Integer)
	pm = ccall(mxfunc(:mxCreateNumericMatrix_730), 
		Ptr{Void}, (mwSize, mwSize, mxClassID, mxComplexity), 
		m, n, mxclassid(T), mxREAL)
	MxArray(pm)
end

function mxarray(ty::Type{Bool}, n::Integer)
	pm = ccall(mxfunc(:mxCreateLogicalMatrix_730), 
		Ptr{Void}, (mwSize, mwSize), n, 1)
	MxArray(pm)
end

function mxarray(ty::Type{Bool}, m::Integer, n::Integer)
	pm = ccall(mxfunc(:mxCreateLogicalMatrix_730), 
		Ptr{Void}, (mwSize, mwSize), m, n)
	MxArray(pm)
end

# delete & duplicate

function delete(mx::MxArray)
	ccall(mxfunc(:mxDestroyArray), Void, (Ptr{Void},), mx.ptr)
end

function duplicate(mx::MxArray)
	pm::Ptr{Void} = ccall(mxfunc(:mxDuplicateArray), Ptr{Void}, (Ptr{Void},), mx.ptr)
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

# conversion from MATLAB variable to Julia array
# jarray returns a light-weight wrapper using pointer_to_array
# The resultant array is valid until mx is explicitly deleted

function jarray(mx::MxArray)
	T = eltype(mx)
	if !(ndims(mx) == 2 && (T <: MxNumOrBool))
		error("jarray currenly only supports 2D arrays of primitive types.")
	end
	m = convert(Int, nrows(mx))
	n = convert(Int, ncols(mx))
	pointer_to_array(data_ptr(mx), (m, n), false)
end




