module MATLAB

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

    # engine
    export MSession
    export get_default_msession, restart_default_msession, close_default_msession
    export eval_string, put_variable, get_mvariable, get_variable
    export mxcall
    export @mput, @mget, @matlab

    import Base.eltype, Base.close, Base.size, Base.copy, Base.ndims

    include("exceptions.jl")
    include("mxbase.jl")
    include("mxarray.jl")

    include("mstatements.jl")
    include("engine.jl")

end # module
