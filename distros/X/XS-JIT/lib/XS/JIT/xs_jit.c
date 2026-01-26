/*
 * xs_jit.c - Core C implementation for XS::JIT
 *
 * This file provides the JIT compilation functionality that can be
 * called directly from C (no Perl stack overhead) or via XS bindings.
 */

#include "xs_jit.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <errno.h>

/* Buffer growth size */
#define BUFFER_CHUNK 4096

/* Maximum path length */
#define MAX_PATH_LEN 4096

/* Dynamic string buffer */
typedef struct {
    char *data;
    size_t len;
    size_t capacity;
} StrBuf;

static void strbuf_init(StrBuf *buf) {
    buf->data = NULL;
    buf->len = 0;
    buf->capacity = 0;
}

static void strbuf_free(StrBuf *buf) {
    if (buf->data) {
        free(buf->data);
        buf->data = NULL;
    }
    buf->len = 0;
    buf->capacity = 0;
}

static int strbuf_ensure(StrBuf *buf, size_t needed) {
    if (buf->capacity >= needed) return 1;

    size_t new_cap = buf->capacity ? buf->capacity : BUFFER_CHUNK;
    while (new_cap < needed) new_cap *= 2;

    char *new_data = realloc(buf->data, new_cap);
    if (!new_data) return 0;

    buf->data = new_data;
    buf->capacity = new_cap;
    return 1;
}

static int strbuf_append(StrBuf *buf, const char *str) {
    size_t slen = strlen(str);
    if (!strbuf_ensure(buf, buf->len + slen + 1)) return 0;
    memcpy(buf->data + buf->len, str, slen + 1);
    buf->len += slen;
    return 1;
}

static int strbuf_appendf(StrBuf *buf, const char *fmt, ...) {
    va_list args, args2;
    va_start(args, fmt);
    va_copy(args2, args);

    int needed = vsnprintf(NULL, 0, fmt, args);
    va_end(args);

    if (needed < 0) {
        va_end(args2);
        return 0;
    }

    if (!strbuf_ensure(buf, buf->len + needed + 1)) {
        va_end(args2);
        return 0;
    }

    vsnprintf(buf->data + buf->len, needed + 1, fmt, args2);
    va_end(args2);
    buf->len += needed;
    return 1;
}

/* Convert module name to safe C identifier */
static void safe_name(const char *name, char *out, size_t outlen) {
    size_t i, j = 0;
    for (i = 0; name[i] && j < outlen - 1; i++) {
        char c = name[i];
        if (c == ':') {
            out[j++] = '_';
            if (name[i+1] == ':') i++;
        } else if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
                   (c >= '0' && c <= '9') || c == '_') {
            out[j++] = c;
        } else {
            out[j++] = '_';
        }
    }
    out[j] = '\0';
}

/* Simple MD5-like hash for cache key (uses Perl's Digest::MD5) */
static char* compute_cache_key(pTHX_ const char *code, const char *name) {
    dSP;
    SV *input;
    char *result = NULL;

    /* Build input string: code + name + archname + perl version */
    HV *config = get_hv("Config::Config", 0);
    SV **archname_sv = config ? hv_fetch(config, "archname", 8, 0) : NULL;
    const char *archname = (archname_sv && *archname_sv) ? SvPV_nolen(*archname_sv) : "unknown";

    input = newSVpvf("%s\n%s\n%s\n%s", code, name, archname, PERL_VERSION_STRING);

    ENTER;
    SAVETMPS;

    /* require Digest::MD5 */
    eval_pv("require Digest::MD5", G_DISCARD);
    if (SvTRUE(ERRSV)) {
        SvREFCNT_dec(input);
        FREETMPS;
        LEAVE;
        return NULL;
    }

    PUSHMARK(SP);
    XPUSHs(input);
    PUTBACK;

    int count = call_pv("Digest::MD5::md5_hex", G_SCALAR);
    SPAGAIN;

    if (count == 1) {
        SV *md5_sv = POPs;
        STRLEN len;
        const char *md5 = SvPV(md5_sv, len);
        result = (char*)malloc(len + 1);
        if (result) {
            memcpy(result, md5, len);
            result[len] = '\0';
        }
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    SvREFCNT_dec(input);
    return result;
}

/* Get cache directory path */
static const char* get_cache_dir(const char *cache_dir) {
    return cache_dir ? cache_dir : "_CACHED_XS";
}

/* Build path to cached .so file */
int xs_jit_cache_path(pTHX_ const char *code, const char *name,
                      const char *cache_dir, char *out_path, size_t out_len) {
    char *key = compute_cache_key(aTHX_ code, name);
    if (!key) return 0;

    HV *config = get_hv("Config::Config", 0);
    SV **dlext_sv = config ? hv_fetch(config, "dlext", 5, 0) : NULL;
    const char *dlext = (dlext_sv && *dlext_sv) ? SvPV_nolen(*dlext_sv) : "so";

    const char *dir = get_cache_dir(cache_dir);

    char safe[256];
    safe_name(name, safe, sizeof(safe));

    snprintf(out_path, out_len, "%s/lib/auto/%s/%s.%s",
             dir, safe, safe, dlext);

    free(key);
    return 1;
}

/* Check if cached version exists */
int xs_jit_is_cached(pTHX_ const char *code, const char *name,
                     const char *cache_dir) {
    char path[MAX_PATH_LEN];
    if (!xs_jit_cache_path(aTHX_ code, name, cache_dir, path, sizeof(path))) {
        return 0;
    }

    struct stat st;
    return stat(path, &st) == 0;
}

/* Generate XS wrapper/alias for a single function */
static int generate_wrapper(StrBuf *buf, const char *target,
                            const char *source, int has_varargs, int is_xs_native) {
    char safe_target[256];
    safe_name(target, safe_target, sizeof(safe_target));

    if (is_xs_native) {
        /* For XS-native functions, just create an alias - no wrapper needed.
         * The user function already has proper XS signature and handles
         * dXSARGS, ST(), XSRETURN, etc. itself.
         */
        strbuf_appendf(buf, "\n/* Alias for XS-native %s -> %s */\n", source, target);
        strbuf_appendf(buf, "#define XS_%s %s\n", safe_target, source);
    } else {
        strbuf_appendf(buf, "\n/* XS wrapper for %s -> %s */\n", source, target);
        strbuf_appendf(buf, "XS_EUPXS(XS_%s) {\n", safe_target);
        strbuf_append(buf, "    dVAR; dXSARGS;\n");

        if (has_varargs) {
            strbuf_append(buf, "    if (items < 1)\n");
            strbuf_appendf(buf, "        croak_xs_usage(cv, \"self, ...\");\n");
        }

        strbuf_append(buf, "    {\n");
        strbuf_append(buf, "        SV *RETVAL;\n");
        strbuf_append(buf, "        I32* temp = PL_markstack_ptr++;\n");
        strbuf_appendf(buf, "        RETVAL = %s(ST(0));\n", source);
        strbuf_append(buf, "        PL_markstack_ptr = temp;\n");
        strbuf_append(buf, "        if (RETVAL) {\n");
        strbuf_append(buf, "            RETVAL = sv_2mortal(RETVAL);\n");
        strbuf_append(buf, "        } else {\n");
        strbuf_append(buf, "            RETVAL = &PL_sv_undef;\n");
        strbuf_append(buf, "        }\n");
        strbuf_append(buf, "        ST(0) = RETVAL;\n");
        strbuf_append(buf, "    }\n");
        strbuf_append(buf, "    XSRETURN(1);\n");
        strbuf_append(buf, "}\n");
    }

    return 1;
}

/* Generate boot function */
static int generate_boot(StrBuf *buf, const char *module_name,
                         XS_JIT_Func *functions, int num_funcs) {
    char safe_module[256];
    safe_name(module_name, safe_module, sizeof(safe_module));

    strbuf_append(buf, "\n/* Boot function */\n");
    strbuf_append(buf, "#ifdef __cplusplus\n");
    strbuf_append(buf, "extern \"C\" {\n");
    strbuf_append(buf, "#endif\n");
    strbuf_appendf(buf, "XS_EXTERNAL(boot_%s);\n", safe_module);
    strbuf_appendf(buf, "XS_EXTERNAL(boot_%s) {\n", safe_module);
    strbuf_append(buf, "#if PERL_VERSION_LE(5, 21, 5)\n");
    strbuf_append(buf, "    dVAR; dXSARGS;\n");
    strbuf_append(buf, "#else\n");
    strbuf_append(buf, "    dVAR; dXSBOOTARGSXSAPIVERCHK;\n");
    strbuf_append(buf, "#endif\n");
    strbuf_append(buf, "#if PERL_VERSION_LE(5, 8, 999)\n");
    strbuf_append(buf, "    char* file = __FILE__;\n");
    strbuf_append(buf, "#else\n");
    strbuf_append(buf, "    const char* file = __FILE__;\n");
    strbuf_append(buf, "#endif\n");
    strbuf_append(buf, "\n");
    strbuf_append(buf, "    PERL_UNUSED_VAR(file);\n");
    strbuf_append(buf, "    PERL_UNUSED_VAR(cv);\n");
    strbuf_append(buf, "    PERL_UNUSED_VAR(items);\n");
    strbuf_append(buf, "\n");
    strbuf_append(buf, "#if PERL_VERSION_LE(5, 21, 5)\n");
    strbuf_append(buf, "    XS_VERSION_BOOTCHECK;\n");
    strbuf_append(buf, "#  ifdef XS_APIVERSION_BOOTCHECK\n");
    strbuf_append(buf, "    XS_APIVERSION_BOOTCHECK;\n");
    strbuf_append(buf, "#  endif\n");
    strbuf_append(buf, "#endif\n");
    strbuf_append(buf, "\n");

    /* Register each function */
    for (int i = 0; i < num_funcs; i++) {
        if (!functions[i].target) break;

        char safe_target[256];
        safe_name(functions[i].target, safe_target, sizeof(safe_target));

        strbuf_appendf(buf, "    newXS_deffile(\"%s\", XS_%s);\n",
                      functions[i].target, safe_target);
    }

    strbuf_append(buf, "\n");
    strbuf_append(buf, "#if PERL_VERSION_LE(5, 21, 5)\n");
    strbuf_append(buf, "#  if PERL_VERSION_GE(5, 9, 0)\n");
    strbuf_append(buf, "    if (PL_unitcheckav)\n");
    strbuf_append(buf, "        call_list(PL_scopestack_ix, PL_unitcheckav);\n");
    strbuf_append(buf, "#  endif\n");
    strbuf_append(buf, "    XSRETURN_YES;\n");
    strbuf_append(buf, "#else\n");
    strbuf_append(buf, "    Perl_xs_boot_epilog(aTHX_ ax);\n");
    strbuf_append(buf, "#endif\n");
    strbuf_append(buf, "}\n");
    strbuf_append(buf, "#ifdef __cplusplus\n");
    strbuf_append(buf, "}\n");
    strbuf_append(buf, "#endif\n");

    return 1;
}

/* Generate complete C code */
char* xs_jit_generate_code(pTHX_ const char *user_code,
                           const char *module_name,
                           XS_JIT_Func *functions,
                           int num_funcs) {
    StrBuf buf;
    strbuf_init(&buf);

    /* Standard headers */
    strbuf_append(&buf, "/*\n");
    strbuf_append(&buf, " * Generated by XS::JIT\n");
    strbuf_append(&buf, " * Do not edit this file directly.\n");
    strbuf_append(&buf, " */\n\n");

    strbuf_append(&buf, "#include \"EXTERN.h\"\n");
    strbuf_append(&buf, "#include \"perl.h\"\n");
    strbuf_append(&buf, "#include \"XSUB.h\"\n");
    strbuf_append(&buf, "\n");

    /* Version compatibility macros */
    strbuf_append(&buf, "#ifndef PERL_UNUSED_VAR\n");
    strbuf_append(&buf, "#  define PERL_UNUSED_VAR(var) if (0) var = var\n");
    strbuf_append(&buf, "#endif\n");
    strbuf_append(&buf, "\n");
    strbuf_append(&buf, "#ifndef dVAR\n");
    strbuf_append(&buf, "#  define dVAR dNOOP\n");
    strbuf_append(&buf, "#endif\n");
    strbuf_append(&buf, "\n");

    /* PERL_VERSION macros */
    strbuf_append(&buf, "#ifndef PERL_VERSION_DECIMAL\n");
    strbuf_append(&buf, "#  define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)\n");
    strbuf_append(&buf, "#endif\n");
    strbuf_append(&buf, "#ifndef PERL_DECIMAL_VERSION\n");
    strbuf_append(&buf, "#  define PERL_DECIMAL_VERSION \\\n");
    strbuf_append(&buf, "      PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)\n");
    strbuf_append(&buf, "#endif\n");
    strbuf_append(&buf, "#ifndef PERL_VERSION_GE\n");
    strbuf_append(&buf, "#  define PERL_VERSION_GE(r,v,s) \\\n");
    strbuf_append(&buf, "      (PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))\n");
    strbuf_append(&buf, "#endif\n");
    strbuf_append(&buf, "#ifndef PERL_VERSION_LE\n");
    strbuf_append(&buf, "#  define PERL_VERSION_LE(r,v,s) \\\n");
    strbuf_append(&buf, "      (PERL_DECIMAL_VERSION <= PERL_VERSION_DECIMAL(r,v,s))\n");
    strbuf_append(&buf, "#endif\n");
    strbuf_append(&buf, "\n");

    /* XS macros */
    strbuf_append(&buf, "#ifndef XS_EXTERNAL\n");
    strbuf_append(&buf, "#  define XS_EXTERNAL(name) XS(name)\n");
    strbuf_append(&buf, "#endif\n");
    strbuf_append(&buf, "#ifndef XS_INTERNAL\n");
    strbuf_append(&buf, "#  define XS_INTERNAL(name) XS(name)\n");
    strbuf_append(&buf, "#endif\n");
    strbuf_append(&buf, "#undef XS_EUPXS\n");
    strbuf_append(&buf, "#if defined(PERL_EUPXS_ALWAYS_EXPORT)\n");
    strbuf_append(&buf, "#  define XS_EUPXS(name) XS_EXTERNAL(name)\n");
    strbuf_append(&buf, "#else\n");
    strbuf_append(&buf, "#  define XS_EUPXS(name) XS_INTERNAL(name)\n");
    strbuf_append(&buf, "#endif\n");
    strbuf_append(&buf, "\n");

    /* newXS_deffile compatibility */
    strbuf_append(&buf, "#if PERL_VERSION_LE(5, 21, 5)\n");
    strbuf_append(&buf, "#  define newXS_deffile(a,b) Perl_newXS(aTHX_ a,b,file)\n");
    strbuf_append(&buf, "#else\n");
    strbuf_append(&buf, "#  define newXS_deffile(a,b) Perl_newXS_deffile(aTHX_ a,b)\n");
    strbuf_append(&buf, "#endif\n");
    strbuf_append(&buf, "\n");

    /* XS::JIT convenience macros */
    strbuf_append(&buf, "/* XS::JIT convenience macros */\n");
    strbuf_append(&buf, "#define JIT_ARGS  dTHX; dXSARGS\n");
    strbuf_append(&buf, "\n");

    /* Inline compatibility macros */
    strbuf_append(&buf, "/* Inline::C compatibility macros */\n");
    strbuf_append(&buf, "#define Inline_Stack_Vars    dXSARGS\n");
    strbuf_append(&buf, "#define Inline_Stack_Items   items\n");
    strbuf_append(&buf, "#define Inline_Stack_Item(x) ST(x)\n");
    strbuf_append(&buf, "#define Inline_Stack_Reset   sp = mark\n");
    strbuf_append(&buf, "#define Inline_Stack_Push(x) XPUSHs(x)\n");
    strbuf_append(&buf, "#define Inline_Stack_Done    PUTBACK\n");
    strbuf_append(&buf, "#define Inline_Stack_Return(x) XSRETURN(x)\n");
    strbuf_append(&buf, "#define Inline_Stack_Void    XSRETURN(0)\n");
    strbuf_append(&buf, "\n");

    /* User code */
    strbuf_append(&buf, "/* ========== User Code ========== */\n\n");
    strbuf_append(&buf, user_code);
    strbuf_append(&buf, "\n\n");
    strbuf_append(&buf, "/* ========== XS Wrappers ========== */\n");

    /* Generate wrapper for each function */
    for (int i = 0; i < num_funcs; i++) {
        if (!functions[i].target) break;
        generate_wrapper(&buf, functions[i].target, functions[i].source,
                        functions[i].has_varargs, functions[i].is_xs_native);
    }

    /* Generate boot function */
    generate_boot(&buf, module_name, functions, num_funcs);

    return buf.data;  /* Caller must free */
}

/* Create directory recursively */
static int mkdir_p(const char *path) {
    char tmp[MAX_PATH_LEN];
    char *p = NULL;
    size_t len;

    snprintf(tmp, sizeof(tmp), "%s", path);
    len = strlen(tmp);
    if (tmp[len - 1] == '/') tmp[len - 1] = 0;

    for (p = tmp + 1; *p; p++) {
        if (*p == '/') {
            *p = 0;
            mkdir(tmp, 0755);
            *p = '/';
        }
    }
    return mkdir(tmp, 0755) == 0 || errno == EEXIST;
}

/* Compile C file to shared object */
int xs_jit_compile_file(pTHX_ const char *c_file, const char *so_file) {
    HV *config = get_hv("Config::Config", 0);
    if (!config) {
        warn("XS::JIT: Cannot access %%Config");
        return 0;
    }

    SV **cc_sv = hv_fetch(config, "cc", 2, 0);
    SV **ccflags_sv = hv_fetch(config, "ccflags", 7, 0);
    SV **optimize_sv = hv_fetch(config, "optimize", 8, 0);
    SV **cccdlflags_sv = hv_fetch(config, "cccdlflags", 10, 0);
    SV **lddlflags_sv = hv_fetch(config, "lddlflags", 9, 0);
    SV **archlib_sv = hv_fetch(config, "archlib", 7, 0);

    const char *cc = (cc_sv && *cc_sv) ? SvPV_nolen(*cc_sv) : "cc";
    const char *ccflags = (ccflags_sv && *ccflags_sv) ? SvPV_nolen(*ccflags_sv) : "";
    const char *optimize = (optimize_sv && *optimize_sv) ? SvPV_nolen(*optimize_sv) : "-O2";
    const char *cccdlflags = (cccdlflags_sv && *cccdlflags_sv) ? SvPV_nolen(*cccdlflags_sv) : "";
    const char *lddlflags = (lddlflags_sv && *lddlflags_sv) ? SvPV_nolen(*lddlflags_sv) : "";
    const char *archlib = (archlib_sv && *archlib_sv) ? SvPV_nolen(*archlib_sv) : "";

    char o_file[MAX_PATH_LEN];
    snprintf(o_file, sizeof(o_file), "%s.o", c_file);

    char cmd[MAX_PATH_LEN * 2];
    int ret;

    /* Compile to object with optimization */
    snprintf(cmd, sizeof(cmd), "%s %s %s %s -c -o \"%s\" -I\"%s/CORE\" \"%s\" 2>&1",
             cc, ccflags, optimize, cccdlflags, o_file, archlib, c_file);

    ret = system(cmd);
    if (ret != 0) {
        warn("XS::JIT: Compilation failed: %s", cmd);
        return 0;
    }

    /* Link to shared object */
    snprintf(cmd, sizeof(cmd), "%s %s -o \"%s\" \"%s\" 2>&1",
             cc, lddlflags, so_file, o_file);

    ret = system(cmd);
    if (ret != 0) {
        warn("XS::JIT: Linking failed: %s", cmd);
        return 0;
    }

    /* Clean up object file */
    unlink(o_file);

    return 1;
}

/* Load compiled module using DynaLoader */
int xs_jit_load(pTHX_ const char *module_name, const char *so_file) {
    dSP;
    char safe_module[256];
    safe_name(module_name, safe_module, sizeof(safe_module));

    ENTER;
    SAVETMPS;

    /* require DynaLoader */
    eval_pv("require DynaLoader", G_DISCARD);
    if (SvTRUE(ERRSV)) {
        warn("XS::JIT: Cannot load DynaLoader: %s", SvPV_nolen(ERRSV));
        FREETMPS;
        LEAVE;
        return 0;
    }

    /* dl_load_file */
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(so_file, 0)));
    XPUSHs(sv_2mortal(newSViv(0)));  /* flags */
    PUTBACK;

    int count = call_pv("DynaLoader::dl_load_file", G_SCALAR);
    SPAGAIN;

    SV *libref_sv = NULL;
    if (count == 1) {
        libref_sv = POPs;
        SvREFCNT_inc(libref_sv);
    }
    PUTBACK;

    if (!libref_sv || !SvOK(libref_sv)) {
        /* Get error */
        PUSHMARK(SP);
        PUTBACK;
        call_pv("DynaLoader::dl_error", G_SCALAR);
        SPAGAIN;
        SV *err = POPs;
        warn("XS::JIT: dl_load_file failed: %s", SvPV_nolen(err));
        PUTBACK;
        FREETMPS;
        LEAVE;
        return 0;
    }

    /* dl_find_symbol for boot function */
    char boot_name[300];
    snprintf(boot_name, sizeof(boot_name), "boot_%s", safe_module);

    PUSHMARK(SP);
    XPUSHs(libref_sv);
    XPUSHs(sv_2mortal(newSVpv(boot_name, 0)));
    PUTBACK;

    count = call_pv("DynaLoader::dl_find_symbol", G_SCALAR);
    SPAGAIN;

    SV *symref_sv = NULL;
    if (count == 1) {
        symref_sv = POPs;
        SvREFCNT_inc(symref_sv);
    }
    PUTBACK;

    if (!symref_sv || !SvOK(symref_sv)) {
        PUSHMARK(SP);
        PUTBACK;
        call_pv("DynaLoader::dl_error", G_SCALAR);
        SPAGAIN;
        SV *err = POPs;
        warn("XS::JIT: dl_find_symbol failed for %s: %s", boot_name, SvPV_nolen(err));
        PUTBACK;
        SvREFCNT_dec(libref_sv);
        FREETMPS;
        LEAVE;
        return 0;
    }

    /* dl_install_xsub */
    char bootstrap_name[300];
    snprintf(bootstrap_name, sizeof(bootstrap_name), "%s::bootstrap", module_name);

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(bootstrap_name, 0)));
    XPUSHs(symref_sv);
    XPUSHs(sv_2mortal(newSVpv(so_file, 0)));
    PUTBACK;

    count = call_pv("DynaLoader::dl_install_xsub", G_SCALAR);
    SPAGAIN;

    SV *xs_sv = NULL;
    if (count == 1) {
        xs_sv = POPs;
    }
    PUTBACK;

    if (!xs_sv || !SvOK(xs_sv)) {
        warn("XS::JIT: dl_install_xsub failed for %s", bootstrap_name);
        SvREFCNT_dec(libref_sv);
        SvREFCNT_dec(symref_sv);
        FREETMPS;
        LEAVE;
        return 0;
    }

    /* Call the boot function */
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(module_name, 0)));
    PUTBACK;

    call_sv(xs_sv, G_DISCARD | G_EVAL);

    if (SvTRUE(ERRSV)) {
        warn("XS::JIT: boot function failed: %s", SvPV_nolen(ERRSV));
        SvREFCNT_dec(libref_sv);
        SvREFCNT_dec(symref_sv);
        FREETMPS;
        LEAVE;
        return 0;
    }

    SvREFCNT_dec(libref_sv);
    SvREFCNT_dec(symref_sv);
    FREETMPS;
    LEAVE;

    return 1;
}

/* Check if any of the target functions are already defined */
static int functions_already_loaded(pTHX_ XS_JIT_Func *functions, int num_functions) {
    for (int i = 0; i < num_functions && functions[i].target; i++) {
        /* Split target into package and function name */
        const char *target = functions[i].target;
        const char *last_colon = strrchr(target, ':');
        if (last_colon && last_colon > target && *(last_colon - 1) == ':') {
            /* Extract package name */
            size_t pkg_len = last_colon - target - 1;
            char pkg[256];
            if (pkg_len >= sizeof(pkg)) pkg_len = sizeof(pkg) - 1;
            strncpy(pkg, target, pkg_len);
            pkg[pkg_len] = '\0';

            /* Check if function exists in the stash */
            HV *stash = gv_stashpv(pkg, 0);
            if (stash) {
                const char *func_name = last_colon + 1;
                GV *gv = (GV*)hv_fetch(stash, func_name, strlen(func_name), 0);
                if (gv && *(SV**)gv && GvCV(*(GV**)gv)) {
                    /* Function already exists */
                    return 1;
                }
            }
        }
    }
    return 0;
}

/* Main compile function */
int xs_jit_compile(pTHX_ const char *code, const char *name,
                   XS_JIT_Func *functions, int num_functions,
                   const char *cache_dir, int force) {
    char so_path[MAX_PATH_LEN];
    char c_path[MAX_PATH_LEN];
    char dir_path[MAX_PATH_LEN];

    /* Check if already loaded in this process (unless force) */
    if (!force && functions_already_loaded(aTHX_ functions, num_functions)) {
        return 1;  /* Already loaded, nothing to do */
    }

    /* Build paths */
    const char *dir = get_cache_dir(cache_dir);
    char safe[256];
    safe_name(name, safe, sizeof(safe));

    HV *config = get_hv("Config::Config", 0);
    SV **dlext_sv = config ? hv_fetch(config, "dlext", 5, 0) : NULL;
    const char *dlext = (dlext_sv && *dlext_sv) ? SvPV_nolen(*dlext_sv) : "so";

    snprintf(dir_path, sizeof(dir_path), "%s/lib/auto/%s", dir, safe);
    snprintf(so_path, sizeof(so_path), "%s/%s.%s", dir_path, safe, dlext);
    snprintf(c_path, sizeof(c_path), "%s/%s.c", dir_path, safe);

    /* Check cache unless force */
    if (!force) {
        struct stat st;
        if (stat(so_path, &st) == 0) {
            /* Cached - just load */
            return xs_jit_load(aTHX_ name, so_path);
        }
    }

    /* Generate code */
    char *generated = xs_jit_generate_code(aTHX_ code, name, functions, num_functions);
    if (!generated) {
        warn("XS::JIT: Failed to generate code");
        return 0;
    }

    /* Create cache directory */
    if (!mkdir_p(dir_path)) {
        warn("XS::JIT: Failed to create directory %s", dir_path);
        free(generated);
        return 0;
    }

    /* Write C file */
    FILE *fp = fopen(c_path, "w");
    if (!fp) {
        warn("XS::JIT: Failed to write %s: %s", c_path, strerror(errno));
        free(generated);
        return 0;
    }
    fputs(generated, fp);
    fclose(fp);
    free(generated);

    /* Compile */
    if (!xs_jit_compile_file(aTHX_ c_path, so_path)) {
        return 0;
    }

    /* Load */
    return xs_jit_load(aTHX_ name, so_path);
}
