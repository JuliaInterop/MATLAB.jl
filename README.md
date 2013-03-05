## MATLAB.jl

A package to support calling MATLAB functions and manipulating MATLAB arrays in Julia.

[Julia](http://julialang.org) is a technical computing language, which relies on LLVM to achieve efficiency comparable to C. As a young language, many useful functions are still lacking (*e.g.* 3D plot). This package allows users to call MATLAB functions from within Julia, thus making it easier to use the sheer amount of toolboxes available in MATLAB.

### Overview

Generally, this package is comprised of two aspects:

* Creating and manipulating mxArrays (the data structure that MATLAB used to represent arrays and other kinds of data)

* Communicating with MATLAB engine sessions

### Installation

The procedure to setup this package consists of three steps. 

##### Linux

1. Make sure ``matlab`` is in executable path. 

2. Make sure ``csh`` is installed. (Note: MATLAB for Linux relies on ``csh`` to open an engine session.) 
	
	To install ``csh`` in Debian/Ubuntu/Linux Mint, you may type in the following command in terminal:
	
	```
	sudo apt-get install csh
	```

3. Clone this package from the GitHub repo to your Julia package directory, as

	```
	cd <your/julia/package/path>
	git clone https://github.com/lindahua/MATLAB.jl.git MATLAB
	```

##### Mac OS X

1. Make sure ``matlab`` is in executable path. 

2. Export an environment variable ``MATLAB_HOME``. For example, if you are using MATLAB R2012b, you may add the following command to ``.profile``:
	
	```
	export MATLAB_HOME=/Applications/MATLAB_R2012b.app
	```

3. Clone this package from the GitHub repo to your Julia package directory, as



### MxArray class




