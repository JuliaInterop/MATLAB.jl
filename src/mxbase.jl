# Determine MATLAB library path and provide facilities to load libraries with
# this path

function matlab_home_path()
    matlab_home = get(ENV, "MATLAB_HOME", "")
    if isempty(matlab_home)
        if islinux()
            matlab_home = dirname(dirname(realpath(chomp(read(`which matlab`, String)))))
        elseif isapple()
            default_dir = "/Applications"
            if isdir(default_dir)
                dirs = readdir(default_dir)
                filter!(app -> occursin(r"^MATLAB_R[0-9]+[ab]\.app$", app), dirs)
                if !isempty(dirs)
                    matlab_home = joinpath(default_dir, maximum(dirs))
                end
            end
        elseif iswindows()
            default_dir = Sys.WORD_SIZE == 32 ? "C:\\Program Files (x86)\\MATLAB" : "C:\\Program Files\\MATLAB"
            if isdir(default_dir)
                dirs = readdir(default_dir)
                filter!(dir -> occursin(r"^R[0-9]+[ab]$", dir), dirs)
                if !isempty(dirs)
                    matlab_home = joinpath(default_dir, maximum(dirs))
                end
            end
        end
    end
    if isempty(matlab_home)
        error("The MATLAB path could not be found. Set the MATLAB_HOME environmental variable to specify the MATLAB path.")
    end
    return matlab_home
end

function matlab_lib_path()
    # get path to MATLAB libraries
    matlab_home = matlab_home_path()
    matlab_lib_dir = if islinux()
        Sys.WORD_SIZE == 32 ? "glnx86" : "glnxa64"
    elseif isapple()
        Sys.WORD_SIZE == 32 ? "maci" : "maci64"
    elseif iswindows()
        Sys.WORD_SIZE == 32 ? "win32" : "win64"
    end
    matlab_lib_path = joinpath(matlab_home, "bin", matlab_lib_dir)
    if !isdir(matlab_lib_path)
        error("The MATLAB library path could not be found.")
    end
    return matlab_lib_path
end

function matlab_startcmd()
    matlab_home = matlab_home_path()
    if !iswindows()
        default_startcmd = joinpath(matlab_home, "bin", "matlab")
        if !isfile(default_startcmd)
            error("The MATLAB path is invalid. Set the MATLAB_HOME evironmental variable to the MATLAB root.")
        end
        default_startcmd = "exec $(Base.shell_escape(default_startcmd))"
    elseif iswindows()
        default_startcmd = joinpath(matlab_home, "bin", (Sys.WORD_SIZE == 32 ? "win32" : "win64"), "MATLAB.exe")
        if !isfile(default_startcmd)
            error("The MATLAB path is invalid. Set the MATLAB_HOME evironmental variable to the MATLAB root.")
        end
    end
    return default_startcmd
end

# helper library access function

engfunc(fun::Symbol) = Libdl.dlsym(libeng[], fun)
mxfunc(fun::Symbol)  = Libdl.dlsym(libmx[], fun)
matfunc(fun::Symbol) = Libdl.dlsym(libmat[], fun)
