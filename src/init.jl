# libraries

const _libeng = Ref{Ptr{Void}}()
const _libmx  = Ref{Ptr{Void}}()
const _libmat = Ref{Ptr{Void}}()

# functions to access mxArray

const _mx_free         = Ref{Ptr{Void}}()

const _mx_get_classid  = Ref{Ptr{Void}}()
const _mx_get_m        = Ref{Ptr{Void}}()
const _mx_get_n        = Ref{Ptr{Void}}()
const _mx_get_nelems   = Ref{Ptr{Void}}()
const _mx_get_ndims    = Ref{Ptr{Void}}()
const _mx_get_elemsize = Ref{Ptr{Void}}()
const _mx_get_data     = Ref{Ptr{Void}}()
const _mx_get_dims     = Ref{Ptr{Void}}()
const _mx_get_nfields  = Ref{Ptr{Void}}()
const _mx_get_pr       = Ref{Ptr{Void}}()
const _mx_get_pi       = Ref{Ptr{Void}}()
const _mx_get_ir       = Ref{Ptr{Void}}()
const _mx_get_jc       = Ref{Ptr{Void}}()

const _mx_is_double    = Ref{Ptr{Void}}()
const _mx_is_single    = Ref{Ptr{Void}}()
const _mx_is_int64     = Ref{Ptr{Void}}()
const _mx_is_uint64    = Ref{Ptr{Void}}()
const _mx_is_int32     = Ref{Ptr{Void}}()
const _mx_is_uint32    = Ref{Ptr{Void}}()
const _mx_is_int16     = Ref{Ptr{Void}}()
const _mx_is_uint16    = Ref{Ptr{Void}}()
const _mx_is_int8      = Ref{Ptr{Void}}()
const _mx_is_uint8     = Ref{Ptr{Void}}()
const _mx_is_char      = Ref{Ptr{Void}}()

const _mx_is_numeric   = Ref{Ptr{Void}}()
const _mx_is_logical   = Ref{Ptr{Void}}()
const _mx_is_complex   = Ref{Ptr{Void}}()
const _mx_is_sparse    = Ref{Ptr{Void}}()
const _mx_is_empty     = Ref{Ptr{Void}}()
const _mx_is_struct    = Ref{Ptr{Void}}()
const _mx_is_cell      = Ref{Ptr{Void}}()

# functions to create & delete MATLAB arrays

const _mx_create_numeric_mat    = Ref{Ptr{Void}}()
const _mx_create_numeric_arr    = Ref{Ptr{Void}}()

const _mx_create_double_scalar  = Ref{Ptr{Void}}()
const _mx_create_logical_scalar = Ref{Ptr{Void}}()

const _mx_create_sparse         = Ref{Ptr{Void}}()
const _mx_create_sparse_logical = Ref{Ptr{Void}}()

const _mx_create_string         = Ref{Ptr{Void}}()
const _mx_create_char_array     = Ref{Ptr{Void}}()

const _mx_create_cell_array     = Ref{Ptr{Void}}()

const _mx_create_struct_matrix  = Ref{Ptr{Void}}()
const _mx_create_struct_array   = Ref{Ptr{Void}}()

const _mx_get_cell              = Ref{Ptr{Void}}()
const _mx_set_cell              = Ref{Ptr{Void}}()

const _mx_get_field             = Ref{Ptr{Void}}()
const _mx_set_field             = Ref{Ptr{Void}}()
const _mx_get_field_bynum       = Ref{Ptr{Void}}()
const _mx_get_fieldname         = Ref{Ptr{Void}}()

const _mx_get_string = Ref{Ptr{Void}}(0)

# load I/O mat functions

const _mat_open         = Ref{Ptr{Void}}()
const _mat_close        = Ref{Ptr{Void}}()
const _mat_get_variable = Ref{Ptr{Void}}()
const _mat_put_variable = Ref{Ptr{Void}}()
const _mat_get_dir      = Ref{Ptr{Void}}()
