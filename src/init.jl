# libraries

const libeng = Ref{Ptr{Cvoid}}()
const libmx  = Ref{Ptr{Cvoid}}()
const libmat = Ref{Ptr{Cvoid}}()

# matlab engine functions

const eng_open          = Ref{Ptr{Cvoid}}()
const eng_close         = Ref{Ptr{Cvoid}}()
const eng_set_visible   = Ref{Ptr{Cvoid}}()
const eng_get_visible   = Ref{Ptr{Cvoid}}()
const eng_output_buffer = Ref{Ptr{Cvoid}}()
const eng_eval_string   = Ref{Ptr{Cvoid}}()
const eng_put_variable  = Ref{Ptr{Cvoid}}()
const eng_get_variable  = Ref{Ptr{Cvoid}}()

# mxarray functions

const mx_destroy_array   = Ref{Ptr{Cvoid}}()
const mx_duplicate_array = Ref{Ptr{Cvoid}}()

# functions to access mxarray

const mx_free         = Ref{Ptr{Cvoid}}()

const mx_get_classid  = Ref{Ptr{Cvoid}}()
const mx_get_m        = Ref{Ptr{Cvoid}}()
const mx_get_n        = Ref{Ptr{Cvoid}}()
const mx_get_nelems   = Ref{Ptr{Cvoid}}()
const mx_get_ndims    = Ref{Ptr{Cvoid}}()
const mx_get_elemsize = Ref{Ptr{Cvoid}}()
const mx_get_data     = Ref{Ptr{Cvoid}}()
const mx_get_dims     = Ref{Ptr{Cvoid}}()
const mx_get_nfields  = Ref{Ptr{Cvoid}}()
const mx_get_pr       = Ref{Ptr{Cvoid}}()
const mx_get_pi       = Ref{Ptr{Cvoid}}()
const mx_get_ir       = Ref{Ptr{Cvoid}}()
const mx_get_jc       = Ref{Ptr{Cvoid}}()

const mx_is_double    = Ref{Ptr{Cvoid}}()
const mx_is_single    = Ref{Ptr{Cvoid}}()
const mx_is_int64     = Ref{Ptr{Cvoid}}()
const mx_is_uint64    = Ref{Ptr{Cvoid}}()
const mx_is_int32     = Ref{Ptr{Cvoid}}()
const mx_is_uint32    = Ref{Ptr{Cvoid}}()
const mx_is_int16     = Ref{Ptr{Cvoid}}()
const mx_is_uint16    = Ref{Ptr{Cvoid}}()
const mx_is_int8      = Ref{Ptr{Cvoid}}()
const mx_is_uint8     = Ref{Ptr{Cvoid}}()
const mx_is_char      = Ref{Ptr{Cvoid}}()

const mx_is_numeric   = Ref{Ptr{Cvoid}}()
const mx_is_logical   = Ref{Ptr{Cvoid}}()
const mx_is_complex   = Ref{Ptr{Cvoid}}()
const mx_is_sparse    = Ref{Ptr{Cvoid}}()
const mx_is_empty     = Ref{Ptr{Cvoid}}()
const mx_is_struct    = Ref{Ptr{Cvoid}}()
const mx_is_cell      = Ref{Ptr{Cvoid}}()

# functions to create & delete MATLAB arrays

const mx_create_numeric_matrix = Ref{Ptr{Cvoid}}()
const mx_create_numeric_array  = Ref{Ptr{Cvoid}}()

const mx_create_double_scalar  = Ref{Ptr{Cvoid}}()
const mx_create_logical_scalar = Ref{Ptr{Cvoid}}()

const mx_create_sparse         = Ref{Ptr{Cvoid}}()
const mx_create_sparse_logical = Ref{Ptr{Cvoid}}()

const mx_create_string         = Ref{Ptr{Cvoid}}()
const mx_create_char_array     = Ref{Ptr{Cvoid}}()

const mx_create_cell_array     = Ref{Ptr{Cvoid}}()

const mx_create_struct_matrix  = Ref{Ptr{Cvoid}}()
const mx_create_struct_array   = Ref{Ptr{Cvoid}}()

const mx_get_cell              = Ref{Ptr{Cvoid}}()
const mx_set_cell              = Ref{Ptr{Cvoid}}()

const mx_get_field             = Ref{Ptr{Cvoid}}()
const mx_set_field             = Ref{Ptr{Cvoid}}()
const mx_get_field_bynum       = Ref{Ptr{Cvoid}}()
const mx_get_fieldname         = Ref{Ptr{Cvoid}}()

const mx_get_string = Ref{Ptr{Cvoid}}()

# load I/O mat functions

const mat_open         = Ref{Ptr{Cvoid}}()
const mat_close        = Ref{Ptr{Cvoid}}()
const mat_get_variable = Ref{Ptr{Cvoid}}()
const mat_put_variable = Ref{Ptr{Cvoid}}()
const mat_get_dir      = Ref{Ptr{Cvoid}}()
