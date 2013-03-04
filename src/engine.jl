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
	buffer::Vector{Uint8}
	bufptr::Ptr{Uint8}
	
	function MSession(bufsize::Integer)
		global libeng
		if libeng == C_NULL
			load_libeng()
		end
		@assert libeng != C_NULL
	
		ep = ccall(engfunc(:engOpen), Ptr{Void}, (Ptr{Uint8},), 
			startcmd::ASCIIString)
		if ep == C_NULL
			throw(MEngineError("Failed to open a MATLAB engine session."))
		end	
		
		buf = Array(Uint8, bufsize)
		
		if bufsize > 0
			bufptr = pointer(buf)
			ccall(engfunc(:engOutputBuffer), Cint, (Ptr{Void}, Ptr{Uint8}, Cint), 
				ep, bufptr, bufsize)
		else
			bufptr = convert(Ptr{Uint8}, C_NULL)
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
		(Ptr{Void}, Ptr{Uint8}), session.ptr, stmt)
	
	if r != 0
		throw(MEngineError("Invalid engine session."))
	end
	
	bufptr::Ptr{Uint8} = session.bufptr
	if bufptr != C_NULL
		print(bytestring(bufptr))
	end
end

eval_string(stmt::ASCIIString) = eval_string(get_default_msession(), stmt)


function put_variable(session::MSession, name::Symbol, v::MxArray)
	# Put a variable into a MATLAB engine session
	
	@assert libeng::Ptr{Void} != C_NULL
	
	r = ccall(engfunc(:engPutVariable), Cint, 
		(Ptr{Void}, Ptr{Uint8}, Ptr{Void}), session.ptr, string(name), v.ptr)
	
	if r != 0
		throw(MEngineError("Failed to put the variable $(name) into a MATLAB session."))
	end
end

put_variable(session::MSession, name::Symbol, v) = put_variable(session, name, mxarray(v))

put_variable(name::Symbol, v) = put_variable(get_default_msession(), name, v)


function get_mvariable(session::MSession, name::Symbol)
	
	@assert libeng::Ptr{Void} != C_NULL
	
	pv = ccall(engfunc(:engGetVariable), Ptr{Void}, 
		(Ptr{Void}, Ptr{Uint8}), session.ptr, string(name))
		
	if pv == C_NULL
		throw(MEngineError("Failed to get the variable $(name) from a MATLAB session."))
	end
	MxArray(pv)
end

get_mvariable(name::Symbol) = get_mvariable(get_default_msession(), name)


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

macro mget(v)
	:( MATLAB.get_mvariable($(Meta.quot(v))) )
end






