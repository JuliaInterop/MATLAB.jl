 # I/O with mat files

const _mat_open = matfunc(:matOpen)
const _mat_close = matfunc(:matClose)
const _mat_get_variable = matfunc(:matGetVariable)
const _mat_put_variable = matfunc(:matPutVariable)
const _mat_get_dir = matfunc(:matGetDir)

# mat file open & close

type MatFile
    ptr::Ptr{Void}
    filename::String

    function MatFile(filename::String, mode::String)
        p = ccall(_mat_open, Ptr{Void}, (Ptr{Cchar}, Ptr{Cchar}), 
            filename, mode)
        new(p, filename)        
    end
end
MatFile(filename::String) = MatFile(filename, "r")

function close(f::MatFile) 
    if f.ptr != C_NULL
        ret = ccall(_mat_close, Cint, (Ptr{Void},), f.ptr)
        ret == 0 || error("Failed to close file.")
    end
end

# get & put variables

function get_mvariable(f::MatFile, name::String)
    f.ptr != C_NULL || error("Cannot get variable from a null file.")
    pm = ccall(_mat_get_variable, Ptr{Void}, (Ptr{Void}, Ptr{Cchar}), 
        f.ptr, name)
    pm != C_NULL || error("Attempt to get variable $(name) failed.")
    MxArray(pm)
end

get_mvariable(f::MatFile, name::Symbol) = get_mvariable(f, string(name))

get_variable(f::MatFile, name::String) = jvariable(get_mvariable(f, name))
get_variable(f::MatFile, name::Symbol) = jvariable(get_mvariable(f, name))

function put_variable(f::MatFile, name::String, v::MxArray)
    f.ptr != C_NULL || error("Cannot put variable to a null file.")
    v.ptr != C_NULL || error("Cannot put an null variable.")
    ret = ccall(_mat_put_variable, Cint, (Ptr{Void}, Ptr{Cchar}, Ptr{Void}), 
        f.ptr, name, v.ptr)
    ret == 0 || error("Attempt to put variable $(name) failed.")
end

put_variable(f::MatFile, name::Symbol, v::MxArray) = put_variable(f, string(name), v)

put_variable(f::MatFile, name::String, v) = put_variable(f, name, mxarray(v))
put_variable(f::MatFile, name::Symbol, v) = put_variable(f, name, mxarray(v))

# operation over entire file

function put_variables(f::MatFile; kwargs...)
    for (name, val) in kwargs
        put_variable(f, name, val)
    end
end

function write_matfile(filename::String; kwargs...)
    mf = MatFile(filename, "w")
    try
        put_variables(mf; kwargs...)
    finally
        close(mf)
    end
end

function variable_names(f::MatFile)
    # get a list of all variable names
    _n = Cint[0]
    _a = ccall(_mat_get_dir, Ptr{Ptr{Cchar}}, (Ptr{Void}, Ptr{Cint}), 
        f.ptr, _n)

    n = Int(_n[1])
    a = unsafe_wrap(Array, _a, (n,))

    names = String[unsafe_string(s) for s in a]
    ccall(_mx_free, Void, (Ptr{Void},), _a)
    return names
end

function read_matfile(f::MatFile)
    # return a dictionary of all variables
    names = variable_names(f)
    r = Dict{String,MxArray}()
    sizehint!(r, length(names))
    for nam in names
        r[nam] = get_mvariable(f, nam)
    end
    return r
end

function read_matfile(filename::String)
    f = MatFile(filename, "r")
    local r
    try
        r = read_matfile(f)
    finally
        close(f)
    end
    return r
end

