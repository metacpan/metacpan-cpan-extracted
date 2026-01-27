/*
 * xs_jit.h - Public C API for XS::JIT
 *
 * This header can be included by other XS modules to use XS::JIT's
 * compilation functionality directly from C without Perl stack overhead.
 */

#ifndef XS_JIT_H
#define XS_JIT_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Function mapping structure */
typedef struct {
    const char *target;  /* "Package::funcname" - where to install */
    const char *source;  /* "c_func_name" - function in user's C code */
    int has_varargs;     /* 1 if function takes variable arguments */
    int is_xs_native;    /* 1 if function is already XS-native (no wrapper needed) */
} XS_JIT_Func;

/*
 * Main entry point - compile and load C code
 *
 * Parameters:
 *   code         - User's C code as a string
 *   name         - Module name for caching (e.g., "Meow::JIT::Foo_0")
 *   functions    - Array of function mappings (NULL-terminated)
 *   num_functions - Number of functions in array
 *   cache_dir    - Cache directory (NULL for default "_CACHED_XS")
 *   force        - 1 to force recompilation even if cached
 *   extra_cflags - Additional compiler flags (e.g., "-I/path/to/headers"), or NULL
 *   extra_ldflags - Additional linker flags (e.g., "-L/path/to/libs -lssl"), or NULL
 *
 * Returns: 1 on success, 0 on failure
 */
int xs_jit_compile(pTHX_
    const char *code,
    const char *name,
    XS_JIT_Func *functions,
    int num_functions,
    const char *cache_dir,
    int force,
    const char *extra_cflags,
    const char *extra_ldflags
);

/*
 * Generate complete C code with wrappers and boot function
 *
 * Parameters:
 *   user_code    - User's C code
 *   module_name  - Module name (used for boot function name)
 *   functions    - Array of function mappings
 *   num_funcs    - Number of functions
 *
 * Returns: Newly allocated string with complete C code (caller must free)
 */
char* xs_jit_generate_code(pTHX_
    const char *user_code,
    const char *module_name,
    XS_JIT_Func *functions,
    int num_funcs
);

/*
 * Compile C file to shared object
 *
 * Parameters:
 *   c_file        - Path to C source file
 *   so_file       - Path for output shared object
 *   extra_cflags  - Additional compiler flags, or NULL
 *   extra_ldflags - Additional linker flags, or NULL
 *
 * Returns: 1 on success, 0 on failure
 */
int xs_jit_compile_file(pTHX_ const char *c_file, const char *so_file,
                        const char *extra_cflags, const char *extra_ldflags);

/*
 * Load compiled module
 *
 * Parameters:
 *   module_name - Name of the module being loaded
 *   so_file     - Path to shared object file
 *
 * Returns: 1 on success, 0 on failure
 */
int xs_jit_load(pTHX_ const char *module_name, const char *so_file);

/*
 * Check if code is already cached
 *
 * Parameters:
 *   code      - User's C code
 *   name      - Module name
 *   cache_dir - Cache directory (NULL for default)
 *
 * Returns: 1 if cached, 0 if not
 */
int xs_jit_is_cached(pTHX_
    const char *code,
    const char *name,
    const char *cache_dir
);

/*
 * Get the path to a cached shared object
 *
 * Parameters:
 *   code      - User's C code
 *   name      - Module name
 *   cache_dir - Cache directory (NULL for default)
 *   out_path  - Buffer to receive path
 *   out_len   - Size of buffer
 *
 * Returns: 1 on success, 0 on failure
 */
int xs_jit_cache_path(pTHX_
    const char *code,
    const char *name,
    const char *cache_dir,
    char *out_path,
    size_t out_len
);

/* XS::JIT convenience macros */
#define JIT_ARGS  dTHX; dXSARGS   /* Initialize thread context and argument stack */

/* Inline::C compatibility macros */
#define Inline_Stack_Vars    dXSARGS
#define Inline_Stack_Items   items
#define Inline_Stack_Item(x) ST(x)
#define Inline_Stack_Reset   sp = mark
#define Inline_Stack_Push(x) XPUSHs(x)
#define Inline_Stack_Done    PUTBACK
#define Inline_Stack_Return(x) XSRETURN(x)
#define Inline_Stack_Void    XSRETURN(0)

#endif /* XS_JIT_H */
