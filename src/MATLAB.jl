module MATLAB
	
	# mxarray
	export MxArray, mxClassID, mxComplexity
	export mxclassid
	export classid, nrows, ncols, nelems, ndims, elsize
	export mxarray, delete, duplicate, jarray
	
	# engine
	export MSession, eval_string, put_variable, get_variable

	import Base.eltype, Base.close
	
	include("exceptions.jl")
	include("mxbase.jl")
	include("mxarray.jl")
	include("engine.jl")
	
end # module
