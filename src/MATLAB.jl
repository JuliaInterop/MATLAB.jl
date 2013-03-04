module MATLAB
	
	# mxarray
	export MxArray, mxClassID, mxComplexity
	export mxclassid
	export classid, nrows, ncols, nelems, ndims, elsize
	export mxarray, delete, duplicate, jarray
	
	# engine
	export MSession
	export get_default_msession, restart_default_msession, close_default_msession
	export eval_string, put_variable, get_mvariable

	import Base.eltype, Base.close
	
	include("exceptions.jl")
	include("mxbase.jl")
	include("mxarray.jl")
	include("engine.jl")
	
end # module
