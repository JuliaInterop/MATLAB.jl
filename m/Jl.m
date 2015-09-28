classdef Jl

  properties (Constant)

    % using the debug version?
    debug = false;

    % the mex function handle
    raw_call = Jl.get_mex_fn();

    % julia paths
    SUFFIX = Jl.get_suffix();
    JULIA_TOP = 'C:/tw/Julia-0.4.0-rc2';
    JULIA_LIB = [Jl.JULIA_TOP '/lib'];
    JULIA_BIN = [Jl.JULIA_TOP '/bin'];
    JULIA_IMG = [Jl.JULIA_LIB '/julia/sys' Jl.SUFFIX '.dll'];

    BOOT_FILE_DIR = Jl.get_boot_file_dir();

    % trick to force initialization
    booted = Jl.boot;
  end

  methods (Static)

    function info()
      Jl.raw_call();
    end

    function val = eval(expr)
      val = Jl.raw_call('mex_eval', expr);
    end

    function include(fn)
      Jl.eval(['include("' fn '")']);
    end

    function v = call(fn, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
      switch nargin
        case 1
          v = Jl.raw_call('mex_call', fn);
        case 2
          v = Jl.raw_call('mex_call', fn, a1);
        case 3
          v = Jl.raw_call('mex_call', fn, a1, a2);
        case 4
          v = Jl.raw_call('mex_call', fn, a1, a2, a3);
        case 5
          v = Jl.raw_call('mex_call', fn, a1, a2, a3, a4);
        case 6
          v = Jl.raw_call('mex_call', fn, a1, a2, a3, a4, a5);
        case 7
          v = Jl.raw_call('mex_call', fn, a1, a2, a3, a4, a5, a6);
        case 8
          v = Jl.raw_call('mex_call', fn, a1, a2, a3, a4, a5, a6, a7);
        case 9
          v = Jl.raw_call('mex_call', fn, a1, a2, a3, a4, a5, a6, a7, a8);
        case 10
          v = Jl.raw_call('mex_call', fn, a1, a2, a3, a4, a5, a6, a7, a8, a9);
        case 11
          v = Jl.raw_call('mex_call', fn, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10);
      end
    end

    function reboot()
      Jl.raw_include([Jl.BOOT_FILE_DIR '/boot.jl']);
    end
  end

  methods (Static)

    function hdl = get_mex_fn()
      if Jl.debug
        hdl = @jl_calld;
      else
        hdl = @jl_call;
      end
    end

    function sfx = get_suffix()
      if Jl.debug
        sfx = '-debug';
      else
        sfx = '';
      end
    end

    function bf = get_boot_file_dir()
      bits = strsplit(mfilename('fullpath'), filesep);
      bf = strjoin([bits(1:end-1)], '/');
    end

    function raw_eval(expr)
      Jl.raw_call(0, expr)
    end

    function raw_include(fn)
      Jl.raw_eval(['include("' fn '")']);
    end

    function bl = boot()
      % add julia bin directory to exe path
      setenv('PATH', [getenv('PATH') pathsep Jl.JULIA_BIN]);

      % initialize the runtime
      Jl.raw_call('', Jl.JULIA_BIN, Jl.JULIA_IMG);

      % load the user initialization file
      Jl.raw_eval('Base.load_juliarc()')

      % load the boot file
      Jl.reboot

      bl = true;
    end
  end
end
