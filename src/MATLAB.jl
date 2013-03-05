module MATLAB

    # mxarray
    export MxArray, mxClassID, mxComplexity
    export mxclassid
    export classid, nrows, ncols, nelems, ndims, elsize
    export mxarray, delete, duplicate, jarray, jscalar, jvector

    # mstatments
    export mstatement

    # engine
    export MSession
    export get_default_msession, restart_default_msession, close_default_msession
    export eval_string, put_variable, get_mvariable
    export @mput, @mget, @matlab

    import Base.eltype, Base.close, Base.size

    include("exceptions.jl")
    include("mxbase.jl")
    include("mxarray.jl")

    include("mstatements.jl")
    include("engine.jl")

end # module
