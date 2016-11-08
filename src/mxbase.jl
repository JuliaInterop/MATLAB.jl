# Determine MATLAB library path and provide facilities to load libraries with
# this path

function get_paths()
    matlab_home = get(ENV, "MATLAB_HOME", "")

    if matlab_home == ""
        if is_linux()
            matlab_home = dirname(dirname(realpath(chomp(readstring(`which matlab`)))))
        elseif is_apple()
            default_dir = "/Applications"
            if isdir(default_dir)
                dirs = readdir(default_dir)
                filter!(app -> ismatch(r"^MATLAB_R[0-9]+[ab]\.app$", dirs), dirs)
            end
        elseif is_windows()
            default_dir = Sys.WORD_SIZE == 32 ? "C:\\Program Files (x86)\\MATLAB" : "C:\\Program Files\\MATLAB"
            if isdir(default_dir)
                dirs = readdir(default_dir)
                filter!(dir -> ismatch(r"^R[0-9]+[ab]$", dir), dirs)
            end
        end
    end

    if ~isempty(dirs)
        matlab_home = joinpath(default_dir, maximum(dirs))
    end
    if matlab_home == ""
        error("The MATLAB path could not be found. Set the MATLAB_HOME environmental variable to specify the MATLAB path.")
    end

    if !is_windows()
        default_startcmd = joinpath(matlab_home, "bin", "matlab")
        if !isfile(default_startcmd)
            error("The MATLAB path is invalid. Set the MATLAB_HOME evironmental variable to the MATLAB root.")
        end
        default_startcmd = "exec $(Base.shell_escape(default_startcmd))"
    elseif is_windows()
        default_startcmd = joinpath(matlab_home, "bin", (Sys.WORD_SIZE == 32 ? "win32" : "win64"), "MATLAB.exe")
        if !isfile(default_startcmd)
            error("The MATLAB path is invalid. Set the MATLAB_HOME evironmental variable to the MATLAB root.")
        end
    end
    default_startcmd *= " -nosplash"

    # Get path to MATLAB libraries
    matlab_lib_dir = if is_linux()
        Sys.WORD_SIZE == 32 ? "glnx86" : "glnxa64"
    elseif is_apple()
        Sys.WORD_SIZE == 32 ? "maci" : "maci64"
    elseif is_windows()
        Sys.WORD_SIZE == 32 ? "win32" : "win64"
    end
    matlab_lib_path = joinpath(matlab_home, "bin", matlab_lib_dir)
    if !isdir(matlab_lib_path)
        error("The MATLAB library path could not be found.")
    end

    return default_startcmd, matlab_lib_path
end

default_startcmd, matlab_lib_path = get_paths()

# helper library access function

engfunc(fun::Symbol) = Libdl.dlsym(_libeng[], fun)
mxfunc(fun::Symbol)  = Libdl.dlsym(_libmx[], fun)
matfunc(fun::Symbol) = Libdl.dlsym(_libmat[], fun)
