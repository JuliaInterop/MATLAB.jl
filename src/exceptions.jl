struct MEngineError <: Exception
    message::String
end

"""
    MEngineError(message::String)

Exception thrown by MATLAB, e.g. due to syntax errors in the code
passed to `eval_string` or `mat"..."`.
"""
struct MatlabException <: Exception
    identifier::String
    message::String
end
