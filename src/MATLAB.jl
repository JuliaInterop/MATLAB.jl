module MATLAB

using Base: unsafe_convert
using Base.Libdl: dlopen, dlsym, RTLD_LAZY, RTLD_GLOBAL

import Base.eltype, Base.close, Base.size, Base.copy, Base.ndims

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
       mxstruct, mxstructarray, nfields, get_fieldname, get_field, set_field,
       jvariable, jarray, jscalar, jvector, jmatrix, jsparse, jstring, jdict

# mstatments
export mstatement

# engine & matfile
export MSession, MatFile,
       get_default_msession, restart_default_msession, close_default_msession,
       eval_string, get_mvariable, get_variable, put_variable, put_variables,
       variable_names, read_matfile, write_matfile,
       mxcall,
       @mput, @mget, @matlab, @mat_str, @mat_mstr

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

end
