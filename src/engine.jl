# operation on MATLAB engine sessions

type MSession
	ptr::Ptr{Void}
end


function open_msession()
	# Open a MATLAB Engine session
	
	global libeng
	if libeng == C_NULL
		load_libeng()
	end
	@assert libeng != C_NULL
	
	p = ccall(dlsym(libeng, :engOpen), Ptr{Void}, (Ptr{Uint8},), 
		startcmd::ASCIIString)
	if p == C_NULL
		throw(MEngineError("Failed to open a MATLAB engine session."))
	end	
	println("A MATLAB session is open successfully")
	MSession(p)
end

function close(session::MSession)
	# Close a MATLAB Engine session
	
	@assert libeng::Ptr{Void} != C_NULL
	
	r = ccall(engfunc(:engClose), Cint, (Ptr{Void},), session.ptr)
	if r != 0
		throw(MEngineError("Failed to close a MATLAB engine session (err = $r)"))
	end
end

function eval_string(session::MSession, stmt::ASCIIString)
	# Evaluate a MATLAB statement in a given MATLAB session
	
	@assert libeng::Ptr{Void} != C_NULL
	
	r::Cint = ccall(engfunc(:engEvalString), Cint, 
		(Ptr{Void}, Ptr{Uint8}), session.ptr, stmt)
	
	if r != 0
		throw(MEngineError("Invalid engine session."))
	end
end

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


function get_variable(session::MSession, name::Symbol)
	
	@assert libeng::Ptr{Void} != C_NULL
	
	pv = ccall(engfunc(:engGetVariable), Ptr{Void}, 
		(Ptr{Void}, Ptr{Uint8}), session.ptr, string(name))
		
	if pv == C_NULL
		throw(MEngineError("Failed to get the variable $(name) from a MATLAB session."))
	end
	MxArray(pv)
end


