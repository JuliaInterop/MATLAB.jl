# functions to deal with MATLAB arrays

mutable struct MxArray
    ptr::Ptr{Cvoid}
    own::Bool

    function MxArray(p::Ptr{Cvoid}, own::Bool)
        p == C_NULL && error("NULL pointer for MxArray.")
        self = new(p, own)
        if own
            finalizer(release, self)
        end
        return self
    end
end
MxArray(p::Ptr{Cvoid}) = MxArray(p, true)

mxarray(mx::MxArray) = mx


function release(mx::MxArray)
    if mx.own && mx.ptr != C_NULL
        ccall(mx_destroy_array[], Cvoid, (Ptr{Cvoid},), mx.ptr)
    end
    mx.ptr = C_NULL
    return nothing
end

# delete & copy

function delete(mx::MxArray)
    if mx.own
        ccall(mx_destroy_array[], Cvoid, (Ptr{Cvoid},), mx)
    end
    mx.ptr = C_NULL
    return nothing
end

function copy(mx::MxArray)
    pm = ccall(mx_duplicate_array[], Ptr{Cvoid}, (Ptr{Cvoid},), mx)
    return MxArray(pm)
end

function unsafe_convert(::Type{Ptr{Cvoid}}, mx::MxArray)
    ptr = mx.ptr
    ptr == C_NULL && throw(UndefRefError())
    return ptr
end
# functions to create mxArray from Julia values/arrays

const MxRealNum = Union{Float64, Float32, Int32, UInt32, Int64, UInt64, Int16, UInt16, Int8, UInt8, Bool}
const MxComplexNum = Union{ComplexF32, ComplexF64}
const MxNum = Union{MxRealNum, MxComplexNum}

###########################################################
#
#  MATLAB types
#
###########################################################

const mwSize = UInt
const mwIndex = Int

@enum mxClassID::Cint begin
    mxUNKNOWN_CLASS
    mxCELL_CLASS
    mxSTRUCT_CLASS
    mxLOGICAL_CLASS
    mxCHAR_CLASS
    mxVOID_CLASS
    mxDOUBLE_CLASS
    mxSINGLE_CLASS
    mxINT8_CLASS
    mxUINT8_CLASS
    mxINT16_CLASS
    mxUINT16_CLASS
    mxINT32_CLASS
    mxUINT32_CLASS
    mxINT64_CLASS
    mxUINT64_CLASS
    mxFUNCTION_CLASS
    mxOPAQUE_CLASS
    mxOBJECT_CLASS
end

@enum mxComplexity::Cint begin
    mxREAL
    mxCOMPLEX
end

mxclassid(::Type{Bool})    = mxLOGICAL_CLASS
mxclassid(::Union{Type{Float64}, Type{ComplexF64}}) = mxDOUBLE_CLASS
mxclassid(::Union{Type{Float32}, Type{ComplexF32}}) = mxSINGLE_CLASS
mxclassid(::Type{Int8})    = mxINT8_CLASS
mxclassid(::Type{UInt8})   = mxUINT8_CLASS
mxclassid(::Type{Int16})   = mxINT16_CLASS
mxclassid(::Type{UInt16})  = mxUINT16_CLASS
mxclassid(::Type{Int32})   = mxINT32_CLASS
mxclassid(::Type{UInt32})  = mxUINT32_CLASS
mxclassid(::Type{Int64})   = mxINT64_CLASS
mxclassid(::Type{UInt64})  = mxUINT64_CLASS

mxcomplexflag(::Type{T}) where {T<:MxRealNum}    = mxREAL
mxcomplexflag(::Type{T}) where {T<:MxComplexNum} = mxCOMPLEX

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

macro mxget_attr(fun, ret, mx)
    :(ccall($(esc(fun)), $(esc(ret)), (Ptr{Cvoid},), $(esc(mx))))
end

classid(mx::MxArray) = @mxget_attr(mx_get_classid[], mxClassID, mx)
nrows(mx::MxArray)   = convert(Int, @mxget_attr(mx_get_m[], UInt, mx))
ncols(mx::MxArray)   = convert(Int, @mxget_attr(mx_get_n[], UInt, mx))
nelems(mx::MxArray)  = convert(Int, @mxget_attr(mx_get_nelems[], UInt, mx))
ndims(mx::MxArray)   = convert(Int, @mxget_attr(mx_get_ndims[], mwSize, mx))

eltype(mx::MxArray)  = mxclassid_to_type(classid(mx))
elsize(mx::MxArray)  = convert(Int, @mxget_attr(mx_get_elemsize[], UInt, mx))
data_ptr(mx::MxArray) = convert(Ptr{eltype(mx)}, @mxget_attr(mx_get_data[], Ptr{Cvoid}, mx))
real_ptr(mx::MxArray) = convert(Ptr{eltype(mx)}, @mxget_attr(mx_get_pr[], Ptr{Cvoid}, mx))
imag_ptr(mx::MxArray) = convert(Ptr{eltype(mx)}, @mxget_attr(mx_get_pi[], Ptr{Cvoid}, mx))

mxnfields(mx::MxArray) = convert(Int, @mxget_attr(mx_get_nfields[], Cint, mx))

# validation functions

macro mx_test_is(fun, mx)
    :((ccall($(esc(fun)), Bool, (Ptr{Cvoid},), $(esc(mx)))))
end

is_double(mx::MxArray) = @mx_test_is(mx_is_double[], mx)
is_single(mx::MxArray) = @mx_test_is(mx_is_single[], mx)
is_int64(mx::MxArray)  = @mx_test_is(mx_is_int64[], mx)
is_uint64(mx::MxArray) = @mx_test_is(mx_is_uint64[], mx)
is_int32(mx::MxArray)  = @mx_test_is(mx_is_int32[], mx)
is_uint32(mx::MxArray) = @mx_test_is(mx_is_uint32[], mx)
is_int16(mx::MxArray)  = @mx_test_is(mx_is_int16[], mx)
is_uint16(mx::MxArray) = @mx_test_is(mx_is_uint16[], mx)
is_int8(mx::MxArray)   = @mx_test_is(mx_is_int8[], mx)
is_uint8(mx::MxArray)  = @mx_test_is(mx_is_uint8[], mx)

is_numeric(mx::MxArray) = @mx_test_is(mx_is_numeric[], mx)
is_logical(mx::MxArray) = @mx_test_is(mx_is_logical[], mx)
is_complex(mx::MxArray) = @mx_test_is(mx_is_complex[], mx)
is_sparse(mx::MxArray)  = @mx_test_is(mx_is_sparse[], mx)
is_struct(mx::MxArray)  = @mx_test_is(mx_is_struct[], mx)
is_cell(mx::MxArray)    = @mx_test_is(mx_is_cell[], mx)
is_char(mx::MxArray)    = @mx_test_is(mx_is_char[], mx)
is_empty(mx::MxArray)   = @mx_test_is(mx_is_empty[], mx)

# size function

function size(mx::MxArray)
    nd = ndims(mx)
    pdims::Ptr{mwSize} = @mxget_attr(mx_get_dims[], Ptr{mwSize}, mx)
    _dims = unsafe_wrap(Array, pdims, (nd,))
    dims = Vector{Int}(undef, nd)
    for i = 1:nd
        dims[i] = Int(_dims[i])
    end
    tuple(dims...)
end

function size(mx::MxArray, d::Integer)
    d <= 0 && throw(ArgumentError("The dimension must be a positive integer."))

    nd = ndims(mx)
    if nd == 2
        d == 1 ? nrows(mx) :
        d == 2 ? ncols(mx) : 1
    else
        pdims::Ptr{mwSize} = @mxget_attr(mx_get_dims[], Ptr{mwSize}, mx)
        _dims = unsafe_wrap(Array, pdims, (nd,))
        d <= nd ? Int(_dims[d]) : 1
    end
end


###########################################################
#
#  functions to create & delete MATLAB arrays
#
###########################################################


function _dims_to_mwSize(dims::Tuple{Vararg{Integer,N}}) where {N}
    _dims = Vector{mwSize}(undef,N)
    for i = 1:N
        _dims[i] = mwSize(dims[i])
    end
    _dims
end

function mxarray(::Type{T}, dims::Tuple{Vararg{Integer,N}}) where {T<:MxNum,N}
    pm = ccall(mx_create_numeric_array[], Ptr{Cvoid},
        (mwSize, Ptr{mwSize}, mxClassID, mxComplexity),
        N, _dims_to_mwSize(dims), mxclassid(T), mxcomplexflag(T))
    MxArray(pm)
end
mxarray(::Type{T}, dims::Integer...) where {T<:MxNum} = mxarray(T, dims)

# create scalars

function mxarray(x::Float64)
    pm = ccall(mx_create_double_scalar[], Ptr{Cvoid}, (Cdouble,), x)
    MxArray(pm)
end

function mxarray(x::Bool)
    pm = ccall(mx_create_logical_scalar[], Ptr{Cvoid}, (Bool,), x)
    MxArray(pm)
end

function mxarray(x::T) where T<:MxRealNum
    pm = ccall(mx_create_numeric_matrix[], Ptr{Cvoid},
        (mwSize, mwSize, mxClassID, mxComplexity),
        1, 1, mxclassid(T), mxcomplexflag(T))

    pdat = ccall(mx_get_data[], Ptr{T}, (Ptr{Cvoid},), pm)

    unsafe_wrap(Array, pdat, (1,))[1] = x
    MxArray(pm)
end
mxarray(x::T) where {T<:MxComplexNum} = mxarray([x])

# conversion from Julia variables to MATLAB
# Note: the conversion is deep-copy, as there is no way to let
# mxArray use Julia array's memory

function mxarray(a::Array{T}) where T<:MxRealNum
    mx = mxarray(T, size(a))
    ccall(:memcpy, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, UInt), data_ptr(mx), a, length(a)*sizeof(T))
    return mx
end

function mxarray(a::Array{T}) where T<:MxComplexNum
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
mxarray(a::AbstractRange) = mxarray([a;])

# sparse matrix

function mxsparse(ty::Type{Float64}, m::Integer, n::Integer, nzmax::Integer)
    pm = ccall(mx_create_sparse[], Ptr{Cvoid},
        (mwSize, mwSize, mwSize, mxComplexity), m, n, nzmax, mxREAL)
    MxArray(pm)
end

function mxsparse(ty::Type{ComplexF64}, m::Integer, n::Integer, nzmax::Integer)
    pm = ccall(mx_create_sparse[], Ptr{Cvoid},
        (mwSize, mwSize, mwSize, mxComplexity), m, n, nzmax, mxCOMPLEX)
    MxArray(pm)
end

function mxsparse(ty::Type{Bool}, m::Integer, n::Integer, nzmax::Integer)
    pm = ccall(mx_create_sparse_logical[], Ptr{Cvoid},
        (mwSize, mwSize, mwSize), m, n, nzmax)
    MxArray(pm)
end

function _copy_sparse_mat(a::SparseMatrixCSC{V,I}, ir_p::Ptr{mwIndex}, jc_p::Ptr{mwIndex}, pr_p::Ptr{Float64}, pi_p::Ptr{Float64}) where {V<:ComplexF64,I}
    colptr::Vector{I} = a.colptr
    rinds::Vector{I} = a.rowval
    vr::Vector{Float64} = real(a.nzval)
    vi::Vector{Float64} = imag(a.nzval)
    n::Int = a.n
    nnz::Int = length(vr)

    # Note: ir and jc contain zero-based indices

    ir = unsafe_wrap(Array, ir_p, (nnz,))
    for i = 1:nnz
        ir[i] = rinds[i] - 1
    end

    jc = unsafe_wrap(Array, jc_p, (n+1,))
    for i = 1:n+1
        jc[i] = colptr[i] - 1
    end

    copyto!(unsafe_wrap(Array, pr_p, (nnz,)), vr)
    copyto!(unsafe_wrap(Array, pi_p, (nnz,)), vi)
end

function _copy_sparse_mat(a::SparseMatrixCSC{V,I}, ir_p::Ptr{mwIndex}, jc_p::Ptr{mwIndex}, pr_p::Ptr{V}) where {V,I}
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

    copyto!(unsafe_wrap(Array, pr_p, (nnz,)), v)
end

function mxarray(a::SparseMatrixCSC{V,I}) where {V<:Union{Float64,ComplexF64,Bool},I}
    m::Int = a.m
    n::Int = a.n
    nnz = length(a.nzval)
    @assert nnz == a.colptr[n+1]-1

    mx = mxsparse(V, m, n, nnz)
    ir_p = ccall(mx_get_ir[], Ptr{mwIndex}, (Ptr{Cvoid},), mx)
    jc_p = ccall(mx_get_jc[], Ptr{mwIndex}, (Ptr{Cvoid},), mx)

    if V <: ComplexF64
        pr_p = ccall(mx_get_pr[], Ptr{Float64}, (Ptr{Cvoid},), mx)
        pi_p = ccall(mx_get_pi[], Ptr{Float64}, (Ptr{Cvoid},), mx)
        _copy_sparse_mat(a, ir_p, jc_p, pr_p, pi_p)
    else
        pr_p = ccall(mx_get_pr[], Ptr{V}, (Ptr{Cvoid},), mx)
        _copy_sparse_mat(a, ir_p, jc_p, pr_p)
    end
    return mx
end


# char arrays and string

function mxarray(s::String)
    utf16string = transcode(UInt16, s)
    pm = ccall(mx_create_char_array[], Ptr{Cvoid}, (mwSize, Ptr{mwSize},), 2,
               _dims_to_mwSize((1, length(utf16string))))
    mx = MxArray(pm)
    ccall(:memcpy, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, UInt), data_ptr(mx), utf16string,
          length(utf16string)*sizeof(UInt16))
    return mx
end

# cell arrays

function mxcellarray(dims::Tuple{Vararg{Integer,N}}) where {N}
    pm = ccall(mx_create_cell_array[], Ptr{Cvoid}, (mwSize, Ptr{mwSize}),
        N, _dims_to_mwSize(dims))
    MxArray(pm)
end
mxcellarray(dims::Integer...) = mxcellarray(dims)

function get_cell(mx::MxArray, i::Integer)
    pm = ccall(mx_get_cell[], Ptr{Cvoid}, (Ptr{Cvoid}, mwIndex), mx, i-1)
    MxArray(pm, false)
end

function set_cell(mx::MxArray, i::Integer, v::MxArray)
    v.own = false
    ccall(mx_set_cell[], Cvoid, (Ptr{Cvoid}, mwIndex, Ptr{Cvoid}), mx, i - 1, v)
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
    a = Vector{Ptr{UInt8}}(undef, n)
    for i = 1:n
        a[i] = unsafe_convert(Ptr{UInt8}, fieldnames[i])
    end
    return a
end

function mxstruct(fns::Vector{String})
    a = _fieldname_array(fns...)
    pm = ccall(mx_create_struct_matrix[], Ptr{Cvoid},
        (mwSize, mwSize, Cint, Ptr{Ptr{UInt8}}), 1, 1, length(a), a)
    MxArray(pm)
end

function mxstruct(fn1::String, fnr::String...)
    a = _fieldname_array(fn1, fnr...)
    pm = ccall(mx_create_struct_matrix[], Ptr{Cvoid},
        (mwSize, mwSize, Cint, Ptr{Ptr{UInt8}}), 1, 1, length(a), a)
    MxArray(pm)
end

function set_field(mx::MxArray, i::Integer, f::String, v::MxArray)
    v.own = false
    ccall(mx_set_field[], Cvoid, (Ptr{Cvoid}, mwIndex, Ptr{UInt8}, Ptr{Cvoid}), mx, i-1, f, v)
    return nothing
end

set_field(mx::MxArray, f::String, v::MxArray) = set_field(mx, 1, f, v)

function get_field(mx::MxArray, i::Integer, f::String)
    pm = ccall(mx_get_field[], Ptr{Cvoid}, (Ptr{Cvoid}, mwIndex, Ptr{UInt8}), mx, i-1, f)
    pm == C_NULL && throw(ArgumentError("Failed to get field."))
    MxArray(pm, false)
end

get_field(mx::MxArray, f::String) = get_field(mx, 1, f)

function get_field(mx::MxArray, i::Integer, fn::Integer)
    pm = ccall(mx_get_field_bynum[], Ptr{Cvoid}, (Ptr{Cvoid}, mwIndex, Cint), mx, i-1, fn-1)
    pm == C_NULL && throw(ArgumentError("Failed to get field."))
    MxArray(pm, false)
end

get_field(mx::MxArray, fn::Integer) = get_field(mx, 1, fn)


function get_fieldname(mx::MxArray, i::Integer)
    p = ccall(mx_get_fieldname[], Ptr{UInt8}, (Ptr{Cvoid}, Cint), mx, i-1)
    unsafe_string(p)
end

const Pairs = Union{Pair, NTuple{2}}

function mxstruct(pairs::Pairs...)
    nf = length(pairs)
    fieldnames = Vector{String}(undef, nf)
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

function mxstruct(d::T) where T
    names = fieldnames(T)
    names_str = map(string, names)
    mx = mxstruct(names_str...)
    for i = 1:length(names)
        set_field(mx, names_str[i], mxarray(getfield(d, names[i])))
    end
    return mx
end

function mxstructarray(d::Array{T}) where T
    names = fieldnames(T)
    names_str = map(string, names)
    a = _fieldname_array(names_str...)

    pm = ccall(mx_create_struct_array[], Ptr{Cvoid}, (mwSize, Ptr{mwSize}, Cint,
        Ptr{Ptr{UInt8}}), ndims(d), _dims_to_mwSize(size(d)), length(a), a)
    mx = MxArray(pm)

    for i = 1:length(d), j = 1:length(names)
        set_field(mx, i, names_str[j], mxarray(getfield(d[i], names[j])))
    end
    return mx
end

mxstruct(d::AbstractDict) = mxstruct(collect(d)...)
mxarray(d) = mxstruct(d)


###########################################################
#
#  convert from MATLAB to Julia
#
###########################################################

# use deep-copy from MATLAB variable to Julia array
# in practice, MATLAB variable often has shorter life-cycle

function _jarrayx(fun::String, mx::MxArray, siz::Tuple)
    if is_numeric(mx) || is_logical(mx)
        @assert !is_sparse(mx)
        T = eltype(mx)
        if is_complex(mx)
            rdat = unsafe_wrap(Array, real_ptr(mx), siz)
            idat = unsafe_wrap(Array, imag_ptr(mx), siz)
            a = complex.(rdat, idat)
        else
            a = Array{T}(undef, siz)
            if !isempty(a)
                ccall(:memcpy, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, UInt), a, data_ptr(mx), length(a)*sizeof(T))
            end
        end
        return a
        #unsafe_wrap(Array, data_ptr(mx), siz)
    elseif is_cell(mx)
        a = Array{Any}(undef, siz)
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

function _jsparse(ty::Type{T}, mx::MxArray) where T<:MxRealNum
    m = nrows(mx)
    n = ncols(mx)
    ir_ptr = ccall(mx_get_ir[], Ptr{mwIndex}, (Ptr{Cvoid},), mx)
    jc_ptr = ccall(mx_get_jc[], Ptr{mwIndex}, (Ptr{Cvoid},), mx)

    jc_a::Vector{mwIndex} = unsafe_wrap(Array, jc_ptr, (n+1,))
    nnz = jc_a[n+1]

    ir = Vector{Int}(undef, nnz)
    jc = Vector{Int}(undef, n+1)

    ir_x = unsafe_wrap(Array, ir_ptr, (nnz,))
    for i = 1:nnz
        ir[i] = ir_x[i] + 1
    end

    jc_x = unsafe_wrap(Array, jc_ptr, (n+1,))
    for i = 1:n+1
        jc[i] = jc_x[i] + 1
    end

    pr_ptr = ccall(mx_get_pr[], Ptr{T}, (Ptr{Cvoid},), mx)
    pr::Vector{T} = copy(unsafe_wrap(Array, pr_ptr, (nnz,)))
    if is_complex(mx)
        pi_ptr = ccall(mx_get_pi[], Ptr{T}, (Ptr{Cvoid},), mx)
        pi::Vector{T} = copy(unsafe_wrap(Array, pi_ptr, (nnz,)))
        return SparseMatrixCSC(m, n, jc, ir, pr + im.*pi)
    else
        return SparseMatrixCSC(m, n, jc, ir, pr)
    end
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
    fnames = Vector{String}(undef, nf)
    fvals = Vector{Any}(undef, nf)
    for i = 1:nf
        fnames[i] = get_fieldname(mx, i)
        pv = ccall(mx_get_field_bynum[], Ptr{Cvoid}, (Ptr{Cvoid}, mwIndex, Cint), mx, 0, i-1)
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

jvalue(mx::MxArray, ::Type{Array})  = jarray(mx)
jvalue(mx::MxArray, ::Type{Vector}) = jvector(mx)
jvalue(mx::MxArray, ::Type{Matrix}) = jmatrix(mx)
jvalue(mx::MxArray, ::Type{Number}) = jscalar(mx)::Number
jvalue(mx::MxArray, ::Type{String}) = String(mx)
jvalue(mx::MxArray, ::Type{Dict}) = Dict(mx)
jvalue(mx::MxArray, ::Type{SparseMatrixCSC}) = jsparse(mx)

# legacy support (eventually drop, when all constructors added)
jdict(mx::MxArray) = Dict(mx)
jstring(mx::MxArray) = String(mx)
