classdef Jl

  properties (Constant)
    config_file = Jl.get_config_file;
    julia_bin_dir = Jl.get_julia_bin_dir;
    is_init = Jl.init;
  end

  methods (Static)
    
    function info()
      jlcall();
    end

    function [v1, v2, v3, v4, v5] = eval(e1, e2, e3, e4, e5)
      switch nargin
        case 1
          v1 = jlcall('mex_eval', e1);
        case 2
          [v1, v2] = jlcall('mex_eval', e1, e2);
        case 3
          [v1, v2, v3] = jlcall('mex_eval', e1, e2, e3);
        case 4
          [v1, v2, v3, v4] = jlcall('mex_eval', e1, e2, e3, e4);
        case 5
          [v1, v2, v3, v4, v5] = jlcall('mex_eval', e1, e2, e3, e4, e5);
      end
    end

    function include(fn)
      Jl.eval(['include("' fn '")']);
    end

    function v = call(fn, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
      switch nargin
        case 1
          v = jlcall('mex_call', fn);
        case 2
          v = jlcall('mex_call', fn, a1);
        case 3
          v = jlcall('mex_call', fn, a1, a2);
        case 4
          v = jlcall('mex_call', fn, a1, a2, a3);
        case 5
          v = jlcall('mex_call', fn, a1, a2, a3, a4);
        case 6
          v = jlcall('mex_call', fn, a1, a2, a3, a4, a5);
        case 7
          v = jlcall('mex_call', fn, a1, a2, a3, a4, a5, a6);
        case 8
          v = jlcall('mex_call', fn, a1, a2, a3, a4, a5, a6, a7);
        case 9
          v = jlcall('mex_call', fn, a1, a2, a3, a4, a5, a6, a7, a8);
        case 10
          v = jlcall('mex_call', fn, a1, a2, a3, a4, a5, a6, a7, a8, a9);
        case 11
          v = jlcall('mex_call', fn, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10);
      end
    end
  end

  methods (Static, Access=private)
    
    function conf = get_config_file()
      bits = strsplit(mfilename('fullpath'), filesep);
      conf = strjoin([bits(1:end-1), 'jlconfig.mat'], filesep);
    end
    
    function v = read_config(nm)
      conf = matfile(Jl.config_file);
      v = conf.(nm);
    end
    
    function d = get_julia_bin_dir()
      d = Jl.read_config('julia_bin_dir');
    end

    function bl = init()
      % add julia bin directory to exe path
      setenv('PATH', [getenv('PATH') pathsep Jl.julia_bin_dir]);
      bl = true;
    end
  end
end
