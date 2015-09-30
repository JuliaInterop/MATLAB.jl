function jlconfig(exe)

if nargin < 1
  % try to guess the path of the julia executable
  if ispc
    [~, o] = system('where julia');
  else
    [~, o] = system('which julia');
  end
  exes = strsplit(o, {'\n','\r'}, 'CollapseDelimiters', true);
  exe = exes{1};
  if exist(exe, 'file') == 0
    exe = 'julia';
  end

  % get path of julia executable
  if ispc
    wc = '*.exe';
  else
    wc = '*';
  end
  [exe, pathexe] = uigetfile(wc,'Select the Julia executable', exe);
  exe = [pathexe exe];
end
assert(exist(exe, 'file') == 2);
fprintf('The path of the Julia executable is %s\n', exe);

julia_bin_dir = directory(exe);
assert(exist(julia_bin_dir, 'dir') == 7);
fprintf('The directory of the Julia executable is %s\n', julia_bin_dir);

% the config file - save the bin path
this_dir = directory(mfilename('fullpath'));
conf = matfile([this_dir filesep 'jlconfig.mat']);
conf.Properties.Writable = true;
conf.julia_bin_dir = julia_bin_dir;

% get home path
cmd = '%s -e println(%s)';
[~, julia_home] = system(sprintf(cmd, exe, 'JULIA_HOME'));
julia_home = chomp(julia_home);
assert(exist(julia_home, 'dir') == 7);
fprintf('JULIA_HOME is %s\n', julia_home);

% get library file
[~, julia_image_file] = system(sprintf(cmd, exe, 'bytestring(Base.JLOptions().image_file)'));
julia_image_file = chomp(julia_image_file);
assert(exist(julia_image_file, 'file') == 2);
fprintf('The Julia image file is %s\n', julia_image_file);

% get include dir
[~, julia_include_dir] = system(sprintf(cmd, exe, '"joinpath(match(r\"(.*)(bin)\",JULIA_HOME).captures[1],\"include\",\"julia\")"'));
julia_include_dir = chomp(julia_include_dir);
assert(exist(julia_include_dir, 'dir') == 7);
assert(exist([julia_include_dir filesep 'julia.h'], 'file') == 2);
fprintf('The Julia include directory is %s\n', julia_include_dir);

% get lib dir, opts
if ispc
  bits = strsplit(julia_image_file, filesep);
  julia_lib_dir = strjoin(bits(1:end-2), filesep);
  lib_opt = 'libjulia.dll.a';
else
  [~, julia_lib_dir] = system(sprintf(cmd, exe, 'abspath(dirname(Libdl.dlpath(\"libjulia\")))'));
  lib_opt = '-ljulia';
end
assert(exist(julia_lib_dir, 'dir') == 7);

mex_cmd = 'mex -v -largeArrayDims %s -output %s -outdir ''%s'' -DJULIA_HOME=''%s'' -DJULIA_IMAGE_FILE=''%s'' -I''%s'' -L''%s'' ''%s'' %s';
eval(sprintf(mex_cmd, '-O', 'jlcall', this_dir, np(julia_home), np(julia_image_file), julia_include_dir, julia_lib_dir, [this_dir filesep 'jlcall.cpp'], lib_opt));

% add this directory to the search path, if necessary

% check if it is on the path
path_dirs = strsplit(path, pathsep);
if ispc
  on_path = any(strcmpi(this_dir, path_dirs));
else
  on_path = any(strcmp(this_dir, path_dirs));
end

% if not, add it and save
if ~on_path
  fprintf('"%s" is not on the MATLAB path. Adding it and saving...\n', this_dir);
  path(this_dir, path);
  savepath;
else
  fprintf('"%s" is already on the MATLAB path.\n', this_dir);
end

fprintf('Configuration complete.\n');

end

% *** helper functions ***

% directory of path
function d = directory(p)
  bits = strsplit(p, filesep);
  d = strjoin(bits(1:end-1), filesep);
end

% remove leading, trailing whitespace
function str = chomp(str)
  str = regexprep(str, '^\s*', '');
  str = regexprep(str, '\s$', '');
end

function str = np(str)
  str = strjoin(strsplit(str, filesep), '/');
end
