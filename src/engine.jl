# operation on MATLAB engine sessions

###########################################################
#
#   Session open & close
#
###########################################################

# 64 K buffer should be sufficient to store the output text in most cases
const default_output_buffer_size = 64 * 1024

type MSession
    ptr::Ptr{Void}
    buffer::Vector{UInt8}
    bufptr::Ptr{UInt8}

    function MSession(bufsize::Integer)
        global libeng
        if libeng == C_NULL
            load_libeng()
        end
        @assert libeng != C_NULL

        ep = ccall(engfunc(:engOpen), Ptr{Void}, (Ptr{UInt8},), default_startcmd)
        if ep == C_NULL
            throw(MEngineError("Failed to open a MATLAB engine session."))
        end

        buf = Array(UInt8, bufsize)

        if bufsize > 0
            bufptr = pointer(buf)
            ccall(engfunc(:engOutputBuffer), Cint, (Ptr{Void}, Ptr{UInt8}, Cint),
                ep, bufptr, bufsize)
        else
            bufptr = convert(Ptr{UInt8}, C_NULL)
        end
        
        if OS_NAME == :Windows
            # Hide the MATLAB Command Window on Windows
            ccall(engfunc(:engSetVisible ), Cint, (Ptr{Void}, Cint), ep, 0)
        end

        println("A MATLAB session is open successfully")
        new(ep, buf, bufptr)
    end

    MSession() = MSession(default_output_buffer_size)
end

function close(session::MSession)
    # Close a MATLAB Engine session

    @assert libeng::Ptr{Void} != C_NULL

    r = ccall(engfunc(:engClose), Cint, (Ptr{Void},), session.ptr)
    if r != 0
        throw(MEngineError("Failed to close a MATLAB engine session (err = $r)"))
    end
end

# default session

default_msession = nothing

function restart_default_msession(bufsize::Integer)
    global default_msession
    if !(default_msession == nothing)
        close(default_msession)
    end
    default_msession = MSession(bufsize)
end

restart_default_msession() = restart_default_msession(default_output_buffer_size)

function get_default_msession()
    global default_msession
    if default_msession == nothing
        default_msession = MSession()
    end
    default_msession::MSession
end

function close_default_msession()
    global default_msession
    if !(default_msession == nothing)
        close(default_msession)
        default_msession = nothing
    end
end


###########################################################
#
#   communication with MATLAB session
#
###########################################################

function eval_string(session::MSession, stmt::ASCIIString)
    # Evaluate a MATLAB statement in a given MATLAB session

    @assert libeng::Ptr{Void} != C_NULL

    r::Cint = ccall(engfunc(:engEvalString), Cint,
        (Ptr{Void}, Ptr{UInt8}), session.ptr, stmt)

    if r != 0
        throw(MEngineError("Invalid engine session."))
    end

    bufptr::Ptr{UInt8} = session.bufptr
    if bufptr != C_NULL
        bs = bytestring(bufptr)
        if ~isempty(bs)
            print(bs)
        end
    end
end

eval_string(stmt::ASCIIString) = eval_string(get_default_msession(), stmt)


function put_variable(session::MSession, name::Symbol, v::MxArray)
    # Put a variable into a MATLAB engine session

    @assert libeng::Ptr{Void} != C_NULL

    r = ccall(engfunc(:engPutVariable), Cint,
        (Ptr{Void}, Ptr{UInt8}, Ptr{Void}), session.ptr, string(name), v.ptr)

    if r != 0
        throw(MEngineError("Failed to put the variable $(name) into a MATLAB session."))
    end
end

put_variable(session::MSession, name::Symbol, v) = put_variable(session, name, mxarray(v))

put_variable(name::Symbol, v) = put_variable(get_default_msession(), name, v)


function get_mvariable(session::MSession, name::Symbol)

    @assert libeng::Ptr{Void} != C_NULL

    pv = ccall(engfunc(:engGetVariable), Ptr{Void},
        (Ptr{Void}, Ptr{UInt8}), session.ptr, string(name))

    if pv == C_NULL
        throw(MEngineError("Failed to get the variable $(name) from a MATLAB session."))
    end
    MxArray(pv)
end

get_mvariable(name::Symbol) = get_mvariable(get_default_msession(), name)

get_variable(name::Symbol) = jvariable(get_mvariable(name))
get_variable(name::Symbol, kind) = jvariable(get_mvariable(name), kind)


###########################################################
#
#   macro to simplify syntax
#
###########################################################

function _mput_multi(vs::Symbol...)
    nv = length(vs)
    if nv == 1
        v = vs[1]
        :( MATLAB.put_variable($(Meta.quot(v)), $(v)) )
    else
        stmts = Array(Expr, nv)
        for i = 1 : nv
            v = vs[i]
            stmts[i] = :( MATLAB.put_variable($(Meta.quot(v)), $(v)) )
        end
        Expr(:block, stmts...)
    end
end

macro mput(vs...)
    esc( _mput_multi(vs...) )
end


function make_getvar_statement(v::Symbol)
    :( $(v) = MATLAB.get_variable($(Meta.quot(v))) )
end

function make_getvar_statement(ex::Expr)
    if !(ex.head == :(::))
        error("Invalid expression for @mget.")
    end
    v::Symbol = ex.args[1]
    k::Symbol = ex.args[2]
    
    :( $(v) = MATLAB.get_variable($(Meta.quot(v)), $(k)) )
end

@compat function _mget_multi(vs::Union{Symbol, Expr}...)
    nv = length(vs)
    if nv == 1
        make_getvar_statement(vs[1])
    else
        stmts = Array(Expr, nv)
        for i = 1 : nv
            stmts[i] = make_getvar_statement(vs[i])
        end
        Expr(:block, stmts...)
    end
end

macro mget(vs...)
    esc( _mget_multi(vs...) )
end

macro matlab(ex)
    :( MATLAB.eval_string($(mstatement(ex))) )
end


###########################################################
#
#   mxcall
#
###########################################################

# MATLAB does not allow underscore as prefix of a variable name
_gen_marg_name(mfun::Symbol, prefix::ASCIIString, i::Int) = "jx_$(mfun)_arg_$(prefix)_$(i)"
 
function mxcall(session::MSession, mfun::Symbol, nout::Integer, in_args...)
    nin = length(in_args)
    
    # generate tempoary variable names
    
    in_arg_names = Array(ASCIIString, nin)
    out_arg_names = Array(ASCIIString, nout)
     
    for i = 1 : nin
        in_arg_names[i] = _gen_marg_name(mfun, "in", i)
    end
    
    for i = 1 : nout
        out_arg_names[i] = _gen_marg_name(mfun, "out", i)
    end
    
    # generate MATLAB statement
    
    buf = IOBuffer()
    if nout > 0
        if nout > 1
            print(buf, "[")
        end
        print(buf, join(out_arg_names, ", "))
        if nout > 1
            print(buf, "]")
        end
        print(buf, " = ")
    end
    
    print(buf, string(mfun))
    print(buf, "(")
    if nin > 0
        print(buf, join(in_arg_names, ", "))
    end
    print(buf, ");")
    
    stmt = bytestring(buf)
    
    # put variables to MATLAB
    
    for i = 1 : nin
        put_variable(session, symbol(in_arg_names[i]), in_args[i])
    end
    
    # execute MATLAB statement
    
    eval_string(session, stmt)
    
    # get results from MATLAB
    
    ret = if nout == 1
        jvariable(get_mvariable(session, symbol(out_arg_names[1])))
    elseif nout >= 2
        results = Array(Any, nout)
        for i = 1 : nout
            results[i] = jvariable(get_mvariable(session, symbol(out_arg_names[i])))
        end
        tuple(results...)
    else
        nothing
    end
    
    # clear temporaries from MATLAB workspace
    
    for i = 1 : nin
        eval_string(session, string("clear ", in_arg_names[i], ";"))
    end
    
    for i = 1 : nout
        eval_string(session, string("clear ", out_arg_names[i], ";"))
    end
    
    # return 
    ret
end

mxcall(mfun::Symbol, nout::Integer, in_args...) = mxcall(get_default_msession(), mfun, nout, in_args...)


