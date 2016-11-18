# mat file open & close

type MatFile
    ptr::Ptr{Void}
    filename::String

    function MatFile(filename::String, mode::String)
        p = ccall(mat_open[], Ptr{Void}, (Ptr{Cchar}, Ptr{Cchar}), filename, mode)
        self = new(p, filename)
        finalizer(self, release)
        return self
    end
end
MatFile(filename::String) = MatFile(filename, "r")

function unsafe_convert(::Type{Ptr{Void}}, f::MatFile)
    ptr = f.ptr
    ptr == C_NULL && throw(UndefRefError())
    return ptr
end

function release(f::MatFile)
    ptr = f.ptr
    if ptr != C_NULL
        ccall(mat_close[], Cint, (Ptr{Void},), ptr)
    end
    f.ptr = C_NULL
    return nothing
end

function close(f::MatFile)
    ret = ccall(mat_close[], Cint, (Ptr{Void},), f)
    ret != 0 && throw(MEngineError("failed to close file (err = $ret)"))
    f.ptr = C_NULL
    return nothing
end


# get & put variables

function get_mvariable(f::MatFile, name::String)
    pm = ccall(mat_get_variable[], Ptr{Void}, (Ptr{Void}, Ptr{Cchar}), f, name)
    pm == C_NULL && error("Attempt to get variable $(name) failed.")
    MxArray(pm)
end

get_mvariable(f::MatFile, name::Symbol) = get_mvariable(f, string(name))

get_variable(f::MatFile, name::String) = jvalue(get_mvariable(f, name))
get_variable(f::MatFile, name::Symbol) = jvalue(get_mvariable(f, name))

function put_variable(f::MatFile, name::String, v::MxArray)
    ret = ccall(mat_put_variable[], Cint, (Ptr{Void}, Ptr{Cchar}, Ptr{Void}), f, name, v)
    ret != 0 && error("Attempt to put variable $(name) failed.")
    return nothing
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
    put_variables(mf; kwargs...)
    close(mf)
end

function variable_names(f::MatFile)
    # get a list of all variable names
    _n = Cint[0]
    _a = ccall(mat_get_dir[], Ptr{Ptr{Cchar}}, (Ptr{Void}, Ptr{Cint}), f, _n)

    n = Int(_n[1])
    a = unsafe_wrap(Array, _a, (n,))

    names = String[unsafe_string(s) for s in a]
    ccall(mx_free[], Void, (Ptr{Void},), _a)
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
    r = read_matfile(f)
    close(f)
    return r
end
