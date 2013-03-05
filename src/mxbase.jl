
libmx = C_NULL
libeng = C_NULL

# libmx (loaded when the module is imported)

function load_libmx()
    global libmx
    if libmx == C_NULL
        libmx = dlopen("libmx", RTLD_GLOBAL | RTLD_LAZY)
        if libmx == C_NULL
            error("Failed to load libmx.")
        end
    end
end

load_libmx()

# libeng (loaded when needed)

function get_default_startcmd()
    if OS_NAME == :Darwin
        matlab_homepath = get(ENV, "MATLAB_HOME", "")
        if isempty(matlab_homepath)
            error("The environment variable MATLAB_HOME must be set to specify the MATLAB path.")
        end
        binfile = joinpath(matlab_homepath, "bin/matlab")
        if !isfile(binfile)
            error("$(matlab_homepath) seems not a valid MATLAB home path.")
        end
        binfile
    else
        C_NULL
    end
end

const default_startcmd = get_default_startcmd()

function load_libeng()
    global libeng
    if libeng == C_NULL
        libeng = dlopen("libeng", RTLD_GLOBAL | RTLD_LAZY)
        if libeng == C_NULL
            error("Failed to load libeng.")
        end
    end
end

engfunc(fun::Symbol) = dlsym(libeng::Ptr{Void}, fun)
mxfunc(fun::Symbol) = dlsym(libmx::Ptr{Void}, fun)
