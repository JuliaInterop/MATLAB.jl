 # I/O with mat files

const _mat_open = matfunc(:matOpen)
const _mat_close = matfunc(:matClose)
const _mat_get_variable = matfunc(:matGetVariable)
const _mat_put_variable = matfunc(:matPutVariable)
const _mat_get_dir = matfunc(:matGetDir)

type MatFile
	ptr::Ptr{Void}
	filename::ASCIIString

	function MatFile(filename::ASCIIString, mode::ASCIIString)
		p = ccall(_mat_open, Ptr{Void}, (Ptr{Cchar}, Ptr{Cchar}), 
			filename, mode)
		new(p, filename)		
	end
end

function close(f::MatFile) 
	if f.ptr != C_NULL
		ret = ccall(_mat_close, Cint, (Ptr{Void},), f.ptr)
		ret == 0 || error("Failed to close file.")
	end
end

function get_mvariable(f::MatFile, name::ASCIIString)
	f.ptr != C_NULL || error("Cannot get variable from a null file.")
	pm = ccall(_mat_get_variable, Ptr{Void}, (Ptr{Void}, Ptr{Void}), 
		f.ptr, name)
	pm != C_NULL || error("Attempt to get variable $(name) failed.")
	MxArray(pm)
end

get_mvariable(f::MatFile, name::Symbol) = get_mvariable(f, string(name))

get_variable(f::MatFile, name::ASCIIString) = jvariable(get_mvariable(f, name))
get_variable(f::MatFile, name::Symbol) = jvariable(get_mvariable(f, name))

function put_variable(f::MatFile, name::ASCIIString, v::MxArray)
	f.ptr != C_NULL || error("Cannot put variable to a null file.")
	v.ptr != C_NULL || error("Cannot put an null variable.")
	ret = ccall(_mat_put_variable, Cint, (Ptr{Void}, Ptr{Void}, Ptr{Void}), 
		f.ptr, name, v.ptr)
	ret == 0 || error("Attempt to put variable $(name) failed.")
end

put_variable(f::MatFile, name::Symbol, v::MxArray) = put_variable(f, string(name), v)

