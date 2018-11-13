## MATLAB

The `MATLAB.jl` package provides an interface for using [MATLAB™](http://www.mathworks.com/products/matlab/) from [Julia](http://julialang.org) using the MATLAB C api.  In other words, this package allows users to call MATLAB functions within Julia, thus making it easy to interoperate with MATLAB from the Julia language.

You cannot use `MATLAB.jl` without having purchased and installed a copy of MATLAB™ from [MathWorks](http://www.mathworks.com/). This package is available free of charge and in no way replaces or alters any functionality of MathWorks's MATLAB product.

## Overview

Generally, this package is comprised of two aspects:

* Creating and manipulating mxArrays (the data structure that MATLAB used to represent arrays and other kinds of data)

* Communicating with MATLAB engine sessions

**Warning**:
MATLAB string arrays are not supported, and will throw an error exception. This also applies if they are nested within a MATLAB struct. This is a limitation of the MATLAB C api. The MATLAB function `convertContainedStringsToChars` may be used to facilitate conversion to a compatible format for use with `MATLAB.jl`.


## Installation

**Important**: The procedure to setup this package consists of the following steps.

By default, `MATLAB.jl` uses the MATLAB installation with the greatest version number. To specify that a specific MATLAB installation should be used, set the environment variable `MATLAB_HOME`.

### Windows

1. Start a Command Prompt as an Administrator and enter `matlab /regserver`.

2. From Julia run: `Pkg.add("MATLAB")`


### Linux

1. Make sure ``matlab`` is in executable path. 

2. Make sure ``csh`` is installed. (Note: MATLAB for Linux relies on ``csh`` to open an engine session.) 
	
	To install ``csh`` in Debian/Ubuntu/Linux Mint, you may type in the following command in terminal:
	
	```bash
	sudo apt-get install csh
	```

3. From Julia run: `Pkg.add("MATLAB")`


### Mac OS X

1. Ensure that MATLAB is installed in `/Applications` (for example, if you are using MATLAB R2012b, you may add the following command to `.profile`:  `export MATLAB_HOME=/Applications/MATLAB_R2012b.app`).

2. From Julia run: `Pkg.add("MATLAB")`


## Usage

### MxArray class

An instance of ``MxArray`` encapsulates a MATLAB variable. This package provides a series of functions to manipulate such instances.

#### Create MATLAB variables in Julia

One can use the function ``mxarray`` to create MATLAB variables (of type ``MxArray``), as follows

```julia
mxarray(Float64, n)   # creates an n-by-1 MATLAB zero array of double valued type
mxarray(Int32, m, n)  # creates an m-by-n MATLAB zero array of int32 valued type 
mxarray(Bool, m, n)   # creates a MATLAB logical array of size m-by-n

mxarray(Float64, (n1, n2, n3))  # creates a MATLAB array of size n1-by-n2-by-n3

mxcellarray(m, n)        # creates a MATLAB cell array
mxstruct("a", "b", "c")  # creates a MATLAB struct with given fields
```

You may also convert a Julia variable to MATLAB variable

```julia
a = rand(m, n)

x = mxarray(a)     # converts a to a MATLAB array
x = mxarray(1.2)   # converts a scalar 1.2 to a MATLAB variable

a = sprand(m, n, 0.1)
x = mxarray(a)     # converts a sparse matrix to a MATLAB sparse matrix

x = mxarray("abc") # converts a string to a MATLAB char array

x = mxarray(["a", 1, 2.3])  # converts a Julia array to a MATLAB cell array

x = mxarray(Dict("a"=>1, "b"=>"string", "c"=>[1,2,3])) # converts a Julia dictionary to a MATLAB struct
```

The function ``mxarray`` can also convert a compound type to a Julia struct:
```julia
struct S
    x::Float64
    y::Vector{Int32}
    z::Bool
end

s = S(1.2, Int32[1, 2], false)

x = mxarray(s)   # creates a MATLAB struct with three fields: x, y, z
xc = mxarray([s, s])  # creates a MATLAB cell array, each cell is a struct.
xs = mxstructarray([s, s])  # creates a MATLAB array of structs
```

**Note:** For safety, the conversation between MATLAB and Julia variables uses deep copy.

When you finish using a MATLAB variable, you may call ``delete`` to free the memory. But this is optional, it will be deleted when reclaimed by the garbage collector.

```julia
delete(x)
```

*Note:* if you put a MATLAB variable ``x`` to MATLAB engine session, then the MATLAB engine will take over the management of its life cylce, and you don't have to delete it explicitly.


#### Access MATLAB variables

You may access attributes and data of a MATLAB variable through the functions provided by this package.

```julia
# suppose x is of type MxArray
nrows(x)    # returns number of rows in x
ncols(x)    # returns number of columns in x 
nelems(x)   # returns number of elements in x
ndims(x)    # returns number of dimensions in x
size(x)     # returns the size of x as a tuple
size(x, d)  # returns the size of x along a specific dimension

eltype(x)   # returns element type of x (in Julia Type)
elsize(x)   # return number of bytes per element

data_ptr(x)   # returns pointer to data (in Ptr{T}), where T is eltype(x)

# suppose s is a MATLAB struct
mxnfields(s)	# returns the number of fields in struct s

```

You may also make tests on a MATLAB variable.

```julia
is_double(x)   # returns whether x is a double array
is_sparse(x)   # returns whether x is sparse
is_complex(x)  # returns whether x is complex
is_cell(x)     # returns whether x is a cell array
is_struct(x)   # returns whether x is a struct
is_empty(x)    # returns whether x is empty

...            # there are many more there
```

#### Convert MATLAB variables to Julia

```julia
a = jarray(x)   # converts x to a Julia array
a = jvector(x)  # converts x to a Julia vector (1D array) when x is a vector
a = jscalar(x)  # converts x to a Julia scalar
a = jmatrix(x)  # converts x to a Julia matrix
a = jstring(x)  # converts x to a Julia string
a = jdict(x)    # converts a MATLAB struct to a Julia dictionary (using fieldnames as keys)

a = jvalue(x)  # converts x to a Julia value in default manner
```

### Read/Write MAT Files

This package provides functions to manipulate MATLAB's mat files:

```julia
mf = MatFile(filename, mode)    # opens a MAT file using a specific mode, and returns a handle
mf = MatFile(filename)          # opens a MAT file for reading, equivalent to MatFile(filename, "r")
close(mf)                       # closes a MAT file.

get_mvariable(mf, name)   # gets a variable and returns an mxArray
get_variable(mf, name)    # gets a variable, but converts it to a Julia value using `jvalue`

put_variable(mf, name, v)   # puts a variable v to the MAT file
                            # v can be either an MxArray instance or normal variable
                            # If v is not an MxArray, it will be converted using `mxarray`

put_variables(mf; name1=v1, name2=v2, ...)  # put multiple variables using keyword arguments

variable_names(mf)   # get a vector of all variable names in a MAT file
```

There are also convenient functions that can get/put all variables in one call:

```julia
read_matfile(filename)    # returns a dictionary that maps each variable name
                          # to an MxArray instance

write_matfile(filename; name1=v1, name2=v2, ...)  # writes all variables given in the
                                                  # keyword argument list to a MAT file
```
Both ``read_matfile`` and ``write_matfile`` will close the MAT file handle before returning. 

**Examples:**

```julia
struct S
    x::Float64
    y::Bool
    z::Vector{Float64}
end

write_matfile("test.mat"; 
    a = Int32[1 2 3; 4 5 6], 
    b = [1.2, 3.4, 5.6, 7.8], 
    c = [[0.0, 1.0], [1.0, 2.0], [1.0, 2.0, 3.0]], 
    d = Dict("name"=>"MATLAB", "score"=>100.0), 
    s = "abcde",
    ss = [S(1.0, true, [1., 2.]), S(2.0, false, [3., 4.])] )
```

This example will create a MAT file called ``test.mat``, which contains six MATLAB variables:

* ``a``: a 2-by-3 int32 array
* ``b``: a 4-by-1 double array
* ``c``: a 3-by-1 cell array, each cell contains a double vector
* ``d``: a struct with two fields: name and score
* ``s``: a string (i.e. char array)
* ``ss``: an array of structs with two elements, and three fields: x, y, and z.


### Use MATLAB Engine

#### Basic Use

To evaluate expressions in MATLAB, one may open a MATLAB engine session and communicate with it. There are three ways to call MATLAB from Julia:

- The `mat""` custom string literal allows you to write MATLAB syntax inside Julia and use Julia variables directly from MATLAB via interpolation
- The `eval_string` evaluate a string containing MATLAB expressions (typically used with the helper macros `@mget` and `@mput`
- The `mxcall` function calls a given MATLAB function and returns the result

In general, the `mat""` custom string literal is the preferred method to interact with the MATLAB engine.

*Note:* There can be multiple (reasonable) ways to convert a MATLAB variable to Julia array. For example, MATLAB represents a scalar using a 1-by-1 matrix. Here we have two choices in terms of converting such a matrix back to Julia: (1) convert to a scalar number, or (2) convert to a matrix of size 1-by-1.

##### The `mat""` custom string literal

Text inside the `mat""` custom string literal is in MATLAB syntax. Variables from Julia can be "interpolated" into MATLAB code by prefixing them with a dollar sign as you would interpolate them into an ordinary string.

```julia
using MATLAB

x = range(-10.0, stop=10.0, length=500)
mat"plot($x, sin($x))"  # evaluate a MATLAB function

y = range(2.0, stop=3.0, length=500)
mat"""
    $u = $x + $y
	$v = $x - $y
"""
@show u v               # u and v are accessible from Julia
```

As with ordinary string literals, you can also interpolate whole Julia expressions, e.g. `mat"$(x[1]) = $(x[2]) + $(binomial(5, 2))"`.

##### `eval_string`

You may also use the `eval_string` function to evaluate MATLAB code as follows		
 ```julia
eval_string("a = sum([1,2,3])")
```

The `eval_string` function also takes an optional argument that specifies which MATLAB session to evaluate the code in, e.g.
```julia
julia> s = MSession();
julia> eval_string(s, "a = sum([1,2,3])")
a =
     6
```

##### `mxcall`

You may also directly call a MATLAB function on Julia variables using `mxcall`:

```julia
x = -10.0:0.1:10.0
y = -10.0:0.1:10.0
xx, yy = mxcall(:meshgrid, 2, x, y)
```
*Note:* Since MATLAB functions behavior depends on the number of outputs, you have to specify the number of output arguments in ``mxcall`` as the second argument.

``mxcall`` puts the input arguments to the MATLAB workspace (using mangled names), evaluates the function call in MATLAB, and retrieves the variable from the MATLAB session. This function is mainly provided for convenience. However, you should keep in mind that it may incur considerable overhead due to the communication between MATLAB and Julia domain.

##### `@mget` and `@mput`

The macro `@mget` can be used to extract the value of a MATLAB variable into Julia 
```julia
julia> mat"a = 6"
julia> @mget a
6.0
```

The macro `@mput` can be used to translate a Julia variable into MATLAB
```julia
julia> x = [1,2,3]
julia> @mput x
julia> eval_string("y = sum(x)")
julia> @mget y
6.0
julia> @show y
a = 63.0
```

#### Viewing the MATLAB Session (Windows only)

To open an interactive window for the MATLAB session, use the command `show_msession()` and to hide the window, use `hide_msession()`. *Warning: manually closing this window will result in an error or result in a segfault; it is advised that you only use the `hide_msession()` command to hide the interactive window.*

Note that this feature only works on Windows.

```julia
# default
show_msession() # open the default MATLAB session interactive window
get_msession_visiblity() # get the session's visibility state
hide_msession() # hide the default MATLAB session interactive window

# similarily
s = MSession()
show_msession(s)
get_msession_visiblity(a)
hide_msession(s)
```


#### Advanced use of MATLAB Engines

This package provides a series of functions for users to control the communication with MATLAB sessions.

Here is an example:

```julia
s1 = MSession()    # creates a MATLAB session
s2 = MSession(0)   # creates a MATLAB session without recording output

x = rand(3, 4)
put_variable(s1, :x, x)  # put x to session s1

y = rand(2, 3)
put_variable(s2, :y, y)  # put y to session s2

eval_string(s1, "r = sin(x)")  # evaluate sin(x) in session s1
eval_string(s2, "r = sin(y)")  # evaluate sin(y) in session s2

r1_mx = get_mvariable(s1, :r)  # get r from s1
r2_mx = get_mvariable(s2, :r)  # get r from s2

r1 = jarray(r1_mx)
r2 = jarray(r2_mx)

# ... do other stuff on r1 and r2

close(s1)  # close session s1
close(s2)  # close session s2
```

