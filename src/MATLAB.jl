module MATLAB

using Base.Sys: islinux, iswindows, isapple
using Libdl
using SparseArrays

import Base: eltype, close, size, copy, ndims, unsafe_convert

# mxarray
export MxArray, mxClassID, mxComplexity,
       mxclassid, data_ptr,
       classid, nrows, ncols, nelems, elsize

export is_double, is_single,
       is_int8, is_uint8, is_int16, is_uint16,
       is_int32, is_uint32, is_int64, is_uint64,
       is_numeric, is_complex, is_sparse, is_empty,
       is_logical, is_char, is_struct, is_cell

export mxarray, mxsparse, delete,
       mxcellarray, get_cell, set_cell,
       mxstruct, mxstructarray, mxnfields, get_fieldname, get_field, set_field,
       jvalue, jarray, jscalar, jvector, jmatrix, jsparse, jstring, jdict

# engine & matfile
export MSession, MatFile,
       get_default_msession, restart_default_msession, close_default_msession,
       eval_string, get_mvariable, get_variable, put_variable, put_variables,
       variable_names, read_matfile, write_matfile,
       mxcall,
       @mput, @mget, @mat_str

if iswindows()
    export show_msession, hide_msession, get_msession_visiblity
end

# exceptions
struct MEngineError <: Exception
    message::String
end

include("init.jl") # initialize Refs
include("mxbase.jl")
include("mxarray.jl")
include("matfile.jl")
include("engine.jl")
include("matstr.jl")

if iswindows()
    # workaround "primary message table for module 77" error
    # creates a dummy Engine session and keeps it open so the libraries used by all other
    # Engine clients are not loaded and unloaded repeatedly
    # see: https://www.mathworks.com/matlabcentral/answers/305877-what-is-the-primary-message-table-for-module-77

    # initialization is delayed untill first call to MSession
    const persistent_msession_ref = Ref{MSession}()
    const persistent_msession_assigned = Ref(false)

    function assign_persistent_msession()
        if persistent_msession_assigned[] == false
            persistent_msession_assigned[] = true
            persistent_msession_ref[] = MSession(0)
        end
    end
end

function __init__()


    # load libraries

    libmx[]  = Libdl.dlopen(joinpath(matlab_libpath(), "libmx"), Libdl.RTLD_GLOBAL)
    libmat[] = Libdl.dlopen(joinpath(matlab_libpath(), "libmat"), Libdl.RTLD_GLOBAL)
    libeng[] = Libdl.dlopen(joinpath(matlab_libpath(), "libeng"), Libdl.RTLD_GLOBAL)

    # engine functions

    eng_open[]          = engfunc(:engOpen)
    eng_close[]         = engfunc(:engClose)
    eng_set_visible[]   = engfunc(:engSetVisible)
    eng_get_visible[]   = engfunc(:engGetVisible)
    eng_output_buffer[] = engfunc(:engOutputBuffer)
    eng_eval_string[]   = engfunc(:engEvalString)
    eng_put_variable[]  = engfunc(:engPutVariable)
    eng_get_variable[]  = engfunc(:engGetVariable)

    # mxarray functions

    mx_destroy_array[]   = mxfunc(:mxDestroyArray)
    mx_duplicate_array[] = mxfunc(:mxDuplicateArray)

    # load functions to access mxarray

    mx_free[]         = mxfunc(:mxFree)

    mx_get_classid[]  = mxfunc(:mxGetClassID)
    mx_get_m[]        = mxfunc(:mxGetM)
    mx_get_n[]        = mxfunc(:mxGetN)
    mx_get_nelems[]   = mxfunc(:mxGetNumberOfElements)
    mx_get_ndims[]    = mxfunc(:mxGetNumberOfDimensions_730)
    mx_get_elemsize[] = mxfunc(:mxGetElementSize)
    mx_get_data[]     = mxfunc(:mxGetData)
    mx_get_dims[]     = mxfunc(:mxGetDimensions_730)
    mx_get_nfields[]  = mxfunc(:mxGetNumberOfFields)
    mx_get_pr[]       = mxfunc(:mxGetPr)
    mx_get_pi[]       = mxfunc(:mxGetPi)
    mx_get_ir[]       = mxfunc(:mxGetIr_730)
    mx_get_jc[]       = mxfunc(:mxGetJc_730)

    mx_is_double[]    = mxfunc(:mxIsDouble)
    mx_is_single[]    = mxfunc(:mxIsSingle)
    mx_is_int64[]     = mxfunc(:mxIsInt64)
    mx_is_uint64[]    = mxfunc(:mxIsUint64)
    mx_is_int32[]     = mxfunc(:mxIsInt32)
    mx_is_uint32[]    = mxfunc(:mxIsUint32)
    mx_is_int16[]     = mxfunc(:mxIsInt16)
    mx_is_uint16[]    = mxfunc(:mxIsUint16)
    mx_is_int8[]      = mxfunc(:mxIsInt8)
    mx_is_uint8[]     = mxfunc(:mxIsUint8)
    mx_is_char[]      = mxfunc(:mxIsChar)

    mx_is_numeric[]   = mxfunc(:mxIsNumeric)
    mx_is_logical[]   = mxfunc(:mxIsLogical)
    mx_is_complex[]   = mxfunc(:mxIsComplex)
    mx_is_sparse[]    = mxfunc(:mxIsSparse)
    mx_is_empty[]     = mxfunc(:mxIsEmpty)
    mx_is_struct[]    = mxfunc(:mxIsStruct)
    mx_is_cell[]      = mxfunc(:mxIsCell)


    # load functions to create & delete MATLAB array

    mx_create_numeric_matrix[]   = mxfunc(:mxCreateNumericMatrix_730)
    mx_create_numeric_array[]    = mxfunc(:mxCreateNumericArray_730)

    mx_create_double_scalar[]  = mxfunc(:mxCreateDoubleScalar)
    mx_create_logical_scalar[] = mxfunc(:mxCreateLogicalScalar)

    mx_create_sparse[]         = mxfunc(:mxCreateSparse_730)
    mx_create_sparse_logical[] = mxfunc(:mxCreateSparseLogicalMatrix_730)

    mx_create_string[]         = mxfunc(:mxCreateString)
    mx_create_char_array[]     = mxfunc(:mxCreateCharArray_730)

    mx_create_cell_array[]     = mxfunc(:mxCreateCellArray_730)

    mx_create_struct_matrix[]  = mxfunc(:mxCreateStructMatrix_730)
    mx_create_struct_array[]   = mxfunc(:mxCreateStructArray_730)

    mx_get_cell[]              = mxfunc(:mxGetCell_730)
    mx_set_cell[]              = mxfunc(:mxSetCell_730)

    mx_get_field[]             = mxfunc(:mxGetField_730)
    mx_set_field[]             = mxfunc(:mxSetField_730)
    mx_get_field_bynum[]       = mxfunc(:mxGetFieldByNumber_730)
    mx_get_fieldname[]         = mxfunc(:mxGetFieldNameByNumber)

    mx_get_string[]            = mxfunc(:mxGetString_730)


    # load I/O mat functions

    mat_open[]         = matfunc(:matOpen)
    mat_close[]        = matfunc(:matClose)
    mat_get_variable[] = matfunc(:matGetVariable)
    mat_put_variable[] = matfunc(:matPutVariable)
    mat_get_dir[]      = matfunc(:matGetDir)

end


###########################################################
#
#   deprecations
#
###########################################################


end
