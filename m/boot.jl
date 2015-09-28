using MATLAB

libmex = Libdl.dlopen(MATLAB.matlab_library("libmex"), Libdl.RTLD_GLOBAL | Libdl.RTLD_LAZY)
mex_fn(fun::Symbol) = dlsym(libmex::Ptr{Void}, fun)

# would be great to redirect STD[IN|OUT|ERR]...

function mex_args(nrhs, prhs)
  ins  = pointer_to_array(convert(Ptr{Ptr{Void}}, prhs), nrhs, false)
  args = [ jvariable(MxArray(mx, false)) for mx in ins ]
end

function mex_return(nlhs, plhs, vs...)
  @assert nlhs == length(vs)
  outs = pointer_to_array(convert(Ptr{Ptr{Void}}, plhs), nlhs, false)
  for i in 1:nlhs
    mx = mxarray(vs[i])
    mx.own = false
    outs[i] = mx.ptr
  end
end

function mex_showerror(e)
  buf = IOBuffer()
  showerror(buf, e)
  seek(buf, 0)
  ccall(mex_fn(:mexErrMsgTxt), Void, (Ptr{Uint8},), readall(buf))
end

# define a proper eval
function mex_eval(nlhs::Int32, plhs::Ptr{Void}, nrhs::Int32, prhs::Ptr{Void})
  @assert nlhs == nrhs
  try
    mex_return(nlhs, plhs, [ eval(parse(e)) for e in mex_args(nrhs, prhs) ]...)
  catch e
    mex_showerror(e)
  end
end

# call an arbitrary julia function (or other callable)
function mex_call(nlhs::Int32, plhs::Ptr{Void}, nrhs::Int32, prhs::Ptr{Void})
  @assert nlhs == 1 && nrhs >= 1
  try
    args = mex_args(nrhs, prhs)
    mex_return(1, plhs, eval(parse(args[1]))(args[2:end]...))
  catch e
    mex_showerror(e)
  end
end
