module MATLAB

using Base.Libdl: dlopen, dlsym, RTLD_LAZY, RTLD_GLOBAL

import Base: eltype, close, size, copy, ndims, unsafe_convert

# mxarray
export MxArray, mxClassID, mxComplexity,
       mxclassid, data_ptr,
       classid, nrows, ncols, nelems, elsize

export is_double, is_single,
       is_int8, is_uint8, is_int16, is_uint16,
       is_int32, is_uint32, is_int64, is_uint64,
       is_numeric, is_complex, is_sparse, is_empty,
       is_logical, is_char, is_struct, is_cell

export mxarray, mxempty, mxsparse, delete, duplicate,
       mxcellarray, get_cell, set_cell,
       mxstruct, mxstructarray, mxnfields, get_fieldname, get_field, set_field,
       jvariable, jarray, jscalar, jvector, jmatrix, jsparse, jstring, jdict

# mstatments
export mstatement

# engine & matfile
export MSession, MatFile,
       get_default_msession, restart_default_msession, close_default_msession,
       eval_string, get_mvariable, get_variable, put_variable, put_variables,
       variable_names, read_matfile, write_matfile,
       mxcall,
       @mput, @mget, @matlab, @mat_str

# exceptions
type MEngineError <: Exception
    message::String
end

include("mxbase.jl")
include("mxarray.jl")
include("matfile.jl")

include("mstatements.jl")
include("engine.jl")
include("matstr.jl")

function __init__()
    if is_windows()
        global persistent_msession
        # workaround "primary message table for module 77" error
        # creates a dummy Engine session and keeps it open so the libraries used by all other
        # Engine clients are not loaded and unloaded repeatedly
        # see: https://www.mathworks.com/matlabcentral/answers/305877-what-is-the-primary-message-table-for-module-77
        persistent_msession = MSession(0)
    end
end

# deprecations
function nfields(mx::MxArray) 
    Base.depwarn("MATLAB.nfields is deprecated, use mxnfields instead.", :nfields)
    return mxfields(mx)
end

function jvariable(mx::MxArray, ty::Type{AbstractString}) 
    Base.depwarn("jvariable(mx::MxArray,ty::Type{AbstractString}) is 
    deprecated, use jvariable(mx::MxArray,ty::Type{String}) instead. 
    We now default to more strict typing on String types", :jvariable)
    return jstring(mx)::String
end

@deprecate duplicate(mx::MxArray) copy(mx::MxArray)

end
