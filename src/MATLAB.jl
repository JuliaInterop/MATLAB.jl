module MATLAB
    using Compat, Compat.Libdl
    using Compat.Libdl: dlopen, dlsym

    # mxarray
    export MxArray, mxClassID, mxComplexity
    export mxclassid, data_ptr
    export classid, nrows, ncols, nelems, elsize
    
    export is_double, is_single
    export is_int8, is_uint8, is_int16, is_uint16
    export is_int32, is_uint32, is_int64, is_uint64
    export is_numeric, is_complex, is_sparse, is_empty
    export is_logical, is_char, is_struct, is_cell
    
    export mxarray, mxempty, mxsparse, delete, duplicate
    export mxcellarray, get_cell, set_cell
    export mxstruct, mxstructarray, nfields, get_fieldname, get_field, set_field
    export jvariable, jarray, jscalar, jvector, jmatrix, jsparse, jstring, jdict

    # mstatments
    export mstatement

    # engine & matfile
    export MSession, MatFile
    export get_default_msession, restart_default_msession, close_default_msession
    export eval_string, get_mvariable, get_variable, put_variable, put_variables
    export variable_names, read_matfile, write_matfile
    export mxcall
    export @mput, @mget, @matlab, @mat_str, @mat_mstr


    import Base.eltype, Base.close, Base.size, Base.copy, Base.ndims, Compat.unsafe_convert, Compat.ASCIIString, Compat.String

    include("exceptions.jl")
    include("mxbase.jl")
    include("mxarray.jl")
    include("matfile.jl")

    include("mstatements.jl")
    include("engine.jl")
    include("matstr.jl")
end # module
