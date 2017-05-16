#include <mex.h>
#include <julia.h>

// string buffers
#define BUF_LEN 1024
char g_msg_buf[BUF_LEN];
char g_julia_home[BUF_LEN];
char g_image_file[BUF_LEN];

void jl_check(void *result) {
  if(result != NULL) return;
  jl_value_t *e = jl_exception_occurred();
  if(e) {
    snprintf(g_msg_buf, BUF_LEN,
            "A julia exception of type %s occurred",
            jl_typeof_str(e));
    jlbacktrace();
    jl_exception_clear();
    mexErrMsgTxt(g_msg_buf);
  }
}

void jl_atexit_hook_0() {
  jl_atexit_hook(0);
}

void mexFunction(int nl, mxArray* pl[], int nr, const mxArray* pr[]) {

  if (nr == 0) { // dump some info

    mexPrintf("version: %s\n", jl_ver_string());
    mexPrintf("debug build?: ");
    if(jl_is_debugbuild()) {
      mexPrintf("yes\n");
    } else {
      mexPrintf("no\n");
    }
    mexPrintf("home: %s\n", jl_options.julia_home);
    mexPrintf("image: %s\n", jl_options.image_file);

  } else if (mxIsChar(pr[0])) { // call a function with this name

    if(mxGetDimensions(pr[0])[0] == 0) { // empty string means initialization

      if (jl_is_initialized()) return;

      if(nr < 3 || !mxIsChar(pr[1]) || !mxIsChar(pr[2])) {
        mexErrMsgTxt(
          "Initialization requires 2 string arguments:\n"
          "\t1. The Julia lib directory;\n"
          "\t2. The path of the system image.");
      }

      mxGetString(pr[1], g_julia_home, BUF_LEN);
      mxGetString(pr[2], g_image_file, BUF_LEN);

      libsupport_init();
      jl_options.julia_home = g_julia_home;
      jl_options.image_file = g_image_file;
      julia_init(JL_IMAGE_JULIA_HOME);
      jl_exception_clear();
      mexAtExit(jl_atexit_hook_0);

    } else {

      char *fnName = mxArrayToString(pr[0]);
      jl_function_t *fn = jl_get_function(jl_main_module, fnName);
      mxFree(fnName);
      if(!fn) mexErrMsgTxt("Function not found.");

      jl_value_t *args[4];
      args[0] = jl_box_int32(nl);
      args[1] = jl_box_voidpointer(pl);
      args[2] = jl_box_int32(nr-1);
      args[3] = jl_box_voidpointer(pr+1);
      jl_check(jl_call(fn, args, 4));
    }
  } else { // evaluate the remaining arguments as strings
    for (int i = 1; i < nr; ++i) {
      char *expr = mxArrayToString(pr[i]);
      void *r = jl_eval_string(expr);
      mxFree(expr);
      jl_check(r);
    }
  }
}
