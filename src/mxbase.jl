
libmx = C_NULL
libeng = C_NULL

# Determine MATLAB library path and provide facilities to load libraries with
# this path

function get_paths()
    global matlab_homepath = get(ENV, "MATLAB_HOME", "")
    global default_startcmd = C_NULL
    global matlab_library_path = nothing

    if matlab_homepath == ""
        if OS_NAME == :Linux
            matlab_homepath = dirname(dirname(realpath(chomp(readall(`which matlab`)))))
        elseif OS_NAME == :Darwin
            apps = readdir("/Applications")
            filter!(app -> ismatch(r"^MATLAB_R[0-9]+[ab]\.app$", app), apps)
            if ~isempty(apps)
                matlab_homepath = joinpath("/Applications", min(apps))
            end
        end
    end

    if matlab_homepath == ""
        error("The MATLAB path could be found. Set the MATLAB_HOME environmental variable to specify the MATLAB path.")
    end

    if OS_NAME != :Windows
        default_startcmd = joinpath(matlab_homepath, "bin", "matlab")
        if !isexecutable(default_startcmd)
            error("The MATLAB path is invalid. Set the MATLAB_HOME evironmental variable to the MATLAB root.")
        end
        default_startcmd *= " -nosplash"
    end

    # Get path to MATLAB libraries
    matlab_library_path = nothing
    if OS_NAME == :Linux
        matlab_library_path = joinpath(matlab_homepath, "bin", (Int == Int32 ? "glnx86" : "glnxa64"))
    elseif OS_NAME == :Darwin
        matlab_library_path = joinpath(matlab_homepath, "bin", (Int == Int32 ? "maci" : "maci64"))
    end

    if matlab_library_path != nothing && !isdir(matlab_library_path)
        matlab_library_path = nothing
    end
end
get_paths()

matlab_library(lib::String) =
    matlab_library_path == nothing ? lib : joinpath(matlab_library_path, lib)

# libmx (loaded when the module is imported)

function load_libmx()
    global libmx
    if libmx == C_NULL
        libmx = dlopen(matlab_library("libmx"), RTLD_GLOBAL | RTLD_LAZY)

        if libmx == C_NULL
            error("Failed to load libmx.")
        end
    end
end

load_libmx()

# libeng (loaded when needed)

function load_libeng()
    global libeng
    if libeng == C_NULL
        libeng = dlopen(matlab_library("libeng"), RTLD_GLOBAL | RTLD_LAZY)
        if libeng == C_NULL
            error("Failed to load libeng.")
        end
    end
end

engfunc(fun::Symbol) = dlsym(libeng::Ptr{Void}, fun)
mxfunc(fun::Symbol) = dlsym(libmx::Ptr{Void}, fun)
