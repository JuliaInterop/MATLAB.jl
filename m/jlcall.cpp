#include <mex.h>
#include <julia.h>

#define _X(s) #s
#define X(s) _X(s)

#define BUF_LEN 1024
char g_msg_buf[BUF_LEN];

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

  if(!jl_is_initialized()) {
    jl_init_with_image(X(JULIA_HOME), X(JULIA_IMAGE_FILE));
    mexAtExit(jl_atexit_hook_0);
    jl_check(jl_eval_string("Base.load_juliarc()"));
    jl_check(jl_eval_string("using MATLAB"));
    jl_check(jl_eval_string("mex_init()"));
  }

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

  } else { // evaluate the remaining arguments as strings
    for (int i = 1; i < nr; ++i) {
      char *expr = mxArrayToString(pr[i]);
      void *r = jl_eval_string(expr);
      mxFree(expr);
      jl_check(r);
    }
  }
}
