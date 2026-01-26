/*
 * xs_jit_builder.c - C implementation for XS::JIT code builder
 *
 * This provides a fluent C API for generating C code strings dynamically.
 */

#define PERL_NO_GET_CONTEXT
#include "xs_jit_builder.h"
#include <stdarg.h>

/* ============================================
 * Internal helpers
 * ============================================ */

static void add_indent(pTHX_ XS_JIT_Builder* b) {
    int i;
    if (b->use_tabs) {
        for (i = 0; i < b->indent; i++) {
            sv_catpvs(b->code, "\t");
        }
    } else {
        int spaces = b->indent * b->indent_width;
        for (i = 0; i < spaces; i++) {
            sv_catpvs(b->code, " ");
        }
    }
}

/* ============================================
 * Lifecycle
 * ============================================ */

XS_JIT_Builder* xs_jit_builder_new(pTHX) {
    XS_JIT_Builder* b;
    Newxz(b, 1, XS_JIT_Builder);
    b->code = newSVpvs("");
    b->indent = 0;
    b->indent_width = 4;
    b->use_tabs = 0;
    b->in_function = 0;
    b->enums = newHV();
    b->memoized = newHV();
    return b;
}

void xs_jit_builder_free(pTHX_ XS_JIT_Builder* b) {
    /* Note: does NOT free code SV - caller should get it first if needed */
    if (b) {
        SvREFCNT_dec(b->code);
        if (b->enums) SvREFCNT_dec((SV*)b->enums);
        if (b->memoized) SvREFCNT_dec((SV*)b->memoized);
        Safefree(b);
    }
}

SV* xs_jit_builder_code(pTHX_ XS_JIT_Builder* b) {
    SvREFCNT_inc(b->code);
    return b->code;
}

const char* xs_jit_builder_cstr(pTHX_ XS_JIT_Builder* b) {
    return SvPV_nolen(b->code);
}

void xs_jit_builder_reset(pTHX_ XS_JIT_Builder* b) {
    SvREFCNT_dec(b->code);
    b->code = newSVpvs("");
    b->indent = 0;
    b->in_function = 0;
}

/* ============================================
 * Low-level output
 * ============================================ */

void xs_jit_line(pTHX_ XS_JIT_Builder* b, const char* fmt, ...) {
    va_list args;
    
    add_indent(aTHX_ b);
    
    va_start(args, fmt);
    sv_vcatpvf(b->code, fmt, &args);
    va_end(args);
    
    sv_catpvs(b->code, "\n");
}

void xs_jit_raw(pTHX_ XS_JIT_Builder* b, const char* fmt, ...) {
    va_list args;
    
    va_start(args, fmt);
    sv_vcatpvf(b->code, fmt, &args);
    va_end(args);
}

void xs_jit_comment(pTHX_ XS_JIT_Builder* b, const char* text) {
    add_indent(aTHX_ b);
    sv_catpvf(b->code, "/* %s */\n", text);
}

void xs_jit_blank(pTHX_ XS_JIT_Builder* b) {
    sv_catpvs(b->code, "\n");
}

/* ============================================
 * Indentation control
 * ============================================ */

void xs_jit_indent(XS_JIT_Builder* b) {
    b->indent++;
}

void xs_jit_dedent(XS_JIT_Builder* b) {
    if (b->indent > 0) {
        b->indent--;
    }
}

void xs_jit_set_indent_width(XS_JIT_Builder* b, int width) {
    b->indent_width = width;
}

void xs_jit_set_use_tabs(XS_JIT_Builder* b, int use_tabs) {
    b->use_tabs = use_tabs;
}

/* ============================================
 * Blocks and structure
 * ============================================ */

void xs_jit_block_start(pTHX_ XS_JIT_Builder* b) {
    xs_jit_line(aTHX_ b, "{");
    b->indent++;
}

void xs_jit_block_end(pTHX_ XS_JIT_Builder* b) {
    b->indent--;
    xs_jit_line(aTHX_ b, "}");
}

/* ============================================
 * XS Function structure
 * ============================================ */

void xs_jit_xs_function(pTHX_ XS_JIT_Builder* b, const char* name) {
    xs_jit_line(aTHX_ b, "XS_EUPXS(%s) {", name);
    b->indent++;
    b->in_function = 1;
}

void xs_jit_xs_preamble(pTHX_ XS_JIT_Builder* b) {
    xs_jit_line(aTHX_ b, "dVAR; dXSARGS;");
    xs_jit_line(aTHX_ b, "PERL_UNUSED_VAR(cv);");
}

void xs_jit_xs_end(pTHX_ XS_JIT_Builder* b) {
    b->indent--;
    xs_jit_line(aTHX_ b, "}");
    b->in_function = 0;
}

void xs_jit_xs_return(pTHX_ XS_JIT_Builder* b, int count) {
    xs_jit_line(aTHX_ b, "XSRETURN(%d);", count);
}

void xs_jit_xs_return_undef(pTHX_ XS_JIT_Builder* b) {
    xs_jit_line(aTHX_ b, "ST(0) = &PL_sv_undef;");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
}

void xs_jit_croak_usage(pTHX_ XS_JIT_Builder* b, const char* usage) {
    xs_jit_line(aTHX_ b, "croak_xs_usage(cv, \"%s\");", usage);
}

/* ============================================
 * Control flow
 * ============================================ */

void xs_jit_if(pTHX_ XS_JIT_Builder* b, const char* cond) {
    xs_jit_line(aTHX_ b, "if (%s) {", cond);
    b->indent++;
}

void xs_jit_elsif(pTHX_ XS_JIT_Builder* b, const char* cond) {
    b->indent--;
    xs_jit_line(aTHX_ b, "} else if (%s) {", cond);
    b->indent++;
}

void xs_jit_else(pTHX_ XS_JIT_Builder* b) {
    b->indent--;
    xs_jit_line(aTHX_ b, "} else {");
    b->indent++;
}

void xs_jit_endif(pTHX_ XS_JIT_Builder* b) {
    b->indent--;
    xs_jit_line(aTHX_ b, "}");
}

void xs_jit_for(pTHX_ XS_JIT_Builder* b, const char* init, const char* cond, const char* incr) {
    xs_jit_line(aTHX_ b, "for (%s; %s; %s) {", init, cond, incr);
    b->indent++;
}

void xs_jit_while(pTHX_ XS_JIT_Builder* b, const char* cond) {
    xs_jit_line(aTHX_ b, "while (%s) {", cond);
    b->indent++;
}

void xs_jit_endloop(pTHX_ XS_JIT_Builder* b) {
    b->indent--;
    xs_jit_line(aTHX_ b, "}");
}

/* ============================================
 * Variable declarations
 * ============================================ */

void xs_jit_declare(pTHX_ XS_JIT_Builder* b, const char* type, const char* name, const char* value) {
    if (value && *value) {
        xs_jit_line(aTHX_ b, "%s %s = %s;", type, name, value);
    } else {
        xs_jit_line(aTHX_ b, "%s %s;", type, name);
    }
}

void xs_jit_declare_sv(pTHX_ XS_JIT_Builder* b, const char* name, const char* value) {
    xs_jit_declare(aTHX_ b, "SV*", name, value);
}

void xs_jit_declare_hv(pTHX_ XS_JIT_Builder* b, const char* name, const char* value) {
    xs_jit_declare(aTHX_ b, "HV*", name, value);
}

void xs_jit_declare_av(pTHX_ XS_JIT_Builder* b, const char* name, const char* value) {
    xs_jit_declare(aTHX_ b, "AV*", name, value);
}

void xs_jit_declare_int(pTHX_ XS_JIT_Builder* b, const char* name, const char* value) {
    xs_jit_declare(aTHX_ b, "int", name, value);
}

void xs_jit_declare_iv(pTHX_ XS_JIT_Builder* b, const char* name, const char* value) {
    xs_jit_declare(aTHX_ b, "IV", name, value);
}

void xs_jit_declare_nv(pTHX_ XS_JIT_Builder* b, const char* name, const char* value) {
    xs_jit_declare(aTHX_ b, "NV", name, value);
}

void xs_jit_declare_pv(pTHX_ XS_JIT_Builder* b, const char* name, const char* value) {
    xs_jit_declare(aTHX_ b, "const char*", name, value);
}

void xs_jit_assign(pTHX_ XS_JIT_Builder* b, const char* var, const char* value) {
    xs_jit_line(aTHX_ b, "%s = %s;", var, value);
}

/* ============================================
 * Common XS patterns
 * ============================================ */

void xs_jit_get_self(pTHX_ XS_JIT_Builder* b) {
    xs_jit_declare_sv(aTHX_ b, "self", "ST(0)");
}

void xs_jit_get_self_hv(pTHX_ XS_JIT_Builder* b) {
    xs_jit_declare_sv(aTHX_ b, "self", "ST(0)");
    xs_jit_declare_hv(aTHX_ b, "hv", "(HV*)SvRV(self)");
}

void xs_jit_get_self_av(pTHX_ XS_JIT_Builder* b) {
    xs_jit_declare_sv(aTHX_ b, "self", "ST(0)");
    xs_jit_declare_av(aTHX_ b, "av", "(AV*)SvRV(self)");
}

/* ============================================
 * Hash operations
 * ============================================ */

void xs_jit_hv_fetch(pTHX_ XS_JIT_Builder* b, const char* hv, const char* key, STRLEN len, const char* result_var) {
    xs_jit_line(aTHX_ b, "SV** %s = hv_fetch(%s, \"%s\", %lu, 0);", result_var, hv, key, (unsigned long)len);
}

void xs_jit_hv_fetch_sv(pTHX_ XS_JIT_Builder* b, const char* hv, const char* key_expr, const char* len_expr, const char* result_var) {
    xs_jit_line(aTHX_ b, "SV** %s = hv_fetch(%s, %s, %s, 0);", result_var, hv, key_expr, len_expr);
}

void xs_jit_hv_store(pTHX_ XS_JIT_Builder* b, const char* hv, const char* key, STRLEN len, const char* value) {
    xs_jit_line(aTHX_ b, "(void)hv_store(%s, \"%s\", %lu, %s, 0);", hv, key, (unsigned long)len, value);
}

void xs_jit_hv_store_sv(pTHX_ XS_JIT_Builder* b, const char* hv, const char* key_expr, const char* len_expr, const char* value) {
    xs_jit_line(aTHX_ b, "(void)hv_store(%s, %s, %s, %s, 0);", hv, key_expr, len_expr, value);
}

void xs_jit_hv_fetch_return(pTHX_ XS_JIT_Builder* b, const char* hv, const char* key, STRLEN len) {
    xs_jit_line(aTHX_ b, "SV** valp = hv_fetch(%s, \"%s\", %lu, 0);", hv, key, (unsigned long)len);
    xs_jit_line(aTHX_ b, "ST(0) = (valp && *valp) ? *valp : &PL_sv_undef;");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
}

/* ============================================
 * Array operations
 * ============================================ */

void xs_jit_av_fetch(pTHX_ XS_JIT_Builder* b, const char* av, const char* index, const char* result_var) {
    xs_jit_line(aTHX_ b, "SV** %s = av_fetch(%s, %s, 0);", result_var, av, index);
}

void xs_jit_av_store(pTHX_ XS_JIT_Builder* b, const char* av, const char* index, const char* value) {
    xs_jit_line(aTHX_ b, "av_store(%s, %s, %s);", av, index, value);
}

void xs_jit_av_push(pTHX_ XS_JIT_Builder* b, const char* av, const char* value) {
    xs_jit_line(aTHX_ b, "av_push(%s, %s);", av, value);
}

void xs_jit_av_len(pTHX_ XS_JIT_Builder* b, const char* av, const char* result_var) {
    xs_jit_line(aTHX_ b, "I32 %s = av_len(%s);", result_var, av);
}

/* ============================================
 * SV creation
 * ============================================ */

void xs_jit_new_sv_iv(pTHX_ XS_JIT_Builder* b, const char* result_var, const char* value) {
    xs_jit_line(aTHX_ b, "SV* %s = newSViv(%s);", result_var, value);
}

void xs_jit_new_sv_nv(pTHX_ XS_JIT_Builder* b, const char* result_var, const char* value) {
    xs_jit_line(aTHX_ b, "SV* %s = newSVnv(%s);", result_var, value);
}

void xs_jit_new_sv_pv(pTHX_ XS_JIT_Builder* b, const char* result_var, const char* str, STRLEN len) {
    xs_jit_line(aTHX_ b, "SV* %s = newSVpvn(\"%s\", %lu);", result_var, str, (unsigned long)len);
}

void xs_jit_mortal(pTHX_ XS_JIT_Builder* b, const char* sv) {
    xs_jit_line(aTHX_ b, "%s = sv_2mortal(%s);", sv, sv);
}

/* ============================================
 * Type checking
 * ============================================ */

void xs_jit_check_items(pTHX_ XS_JIT_Builder* b, int min, int max, const char* usage) {
    char cond[128];
    if (min == max) {
        snprintf(cond, sizeof(cond), "items != %d", min);
    } else if (max < 0) {
        snprintf(cond, sizeof(cond), "items < %d", min);
    } else {
        snprintf(cond, sizeof(cond), "items < %d || items > %d", min, max);
    }
    xs_jit_if(aTHX_ b, cond);
    xs_jit_croak_usage(aTHX_ b, usage);
    xs_jit_endif(aTHX_ b);
}

void xs_jit_check_defined(pTHX_ XS_JIT_Builder* b, const char* sv, const char* error_msg) {
    char cond[128];
    snprintf(cond, sizeof(cond), "!SvOK(%s)", sv);
    xs_jit_if(aTHX_ b, cond);
    xs_jit_croak(aTHX_ b, error_msg);
    xs_jit_endif(aTHX_ b);
}

void xs_jit_check_ref_type(pTHX_ XS_JIT_Builder* b, const char* sv, const char* type, const char* error_msg) {
    char cond[256];
    snprintf(cond, sizeof(cond), "!SvROK(%s) || SvTYPE(SvRV(%s)) != %s", sv, sv, type);
    xs_jit_if(aTHX_ b, cond);
    xs_jit_croak(aTHX_ b, error_msg);
    xs_jit_endif(aTHX_ b);
}

void xs_jit_check_hashref(pTHX_ XS_JIT_Builder* b, const char* sv, const char* error_msg) {
    xs_jit_check_ref_type(aTHX_ b, sv, "SVt_PVHV", error_msg);
}

void xs_jit_check_arrayref(pTHX_ XS_JIT_Builder* b, const char* sv, const char* error_msg) {
    xs_jit_check_ref_type(aTHX_ b, sv, "SVt_PVAV", error_msg);
}

/* ============================================
 * SV conversion (extract values from SV)
 * ============================================ */

void xs_jit_sv_to_iv(pTHX_ XS_JIT_Builder* b, const char* result_var, const char* sv) {
    xs_jit_line(aTHX_ b, "IV %s = SvIV(%s);", result_var, sv);
}

void xs_jit_sv_to_uv(pTHX_ XS_JIT_Builder* b, const char* result_var, const char* sv) {
    xs_jit_line(aTHX_ b, "UV %s = SvUV(%s);", result_var, sv);
}

void xs_jit_sv_to_nv(pTHX_ XS_JIT_Builder* b, const char* result_var, const char* sv) {
    xs_jit_line(aTHX_ b, "NV %s = SvNV(%s);", result_var, sv);
}

void xs_jit_sv_to_pv(pTHX_ XS_JIT_Builder* b, const char* result_var, const char* len_var, const char* sv) {
    if (len_var && *len_var) {
        xs_jit_line(aTHX_ b, "STRLEN %s;", len_var);
        xs_jit_line(aTHX_ b, "const char* %s = SvPV(%s, %s);", result_var, sv, len_var);
    } else {
        xs_jit_line(aTHX_ b, "const char* %s = SvPV_nolen(%s);", result_var, sv);
    }
}

void xs_jit_sv_to_bool(pTHX_ XS_JIT_Builder* b, const char* result_var, const char* sv) {
    xs_jit_line(aTHX_ b, "int %s = SvTRUE(%s);", result_var, sv);
}

/* ============================================
 * Return helpers
 * ============================================ */

void xs_jit_return_iv(pTHX_ XS_JIT_Builder* b, const char* value) {
    xs_jit_line(aTHX_ b, "ST(0) = sv_2mortal(newSViv(%s));", value);
    xs_jit_xs_return(aTHX_ b, 1);
}

void xs_jit_return_uv(pTHX_ XS_JIT_Builder* b, const char* value) {
    xs_jit_line(aTHX_ b, "ST(0) = sv_2mortal(newSVuv(%s));", value);
    xs_jit_xs_return(aTHX_ b, 1);
}

void xs_jit_return_nv(pTHX_ XS_JIT_Builder* b, const char* value) {
    xs_jit_line(aTHX_ b, "ST(0) = sv_2mortal(newSVnv(%s));", value);
    xs_jit_xs_return(aTHX_ b, 1);
}

void xs_jit_return_pv(pTHX_ XS_JIT_Builder* b, const char* str, const char* len) {
    /* str is used as-is - caller must quote literal strings with \" */
    if (len && *len) {
        xs_jit_line(aTHX_ b, "ST(0) = sv_2mortal(newSVpvn(%s, %s));", str, len);
    } else {
        xs_jit_line(aTHX_ b, "ST(0) = sv_2mortal(newSVpv(%s, 0));", str);
    }
    xs_jit_xs_return(aTHX_ b, 1);
}

void xs_jit_return_sv(pTHX_ XS_JIT_Builder* b, const char* sv) {
    xs_jit_line(aTHX_ b, "ST(0) = %s;", sv);
    xs_jit_xs_return(aTHX_ b, 1);
}

void xs_jit_return_yes(pTHX_ XS_JIT_Builder* b) {
    xs_jit_line(aTHX_ b, "ST(0) = &PL_sv_yes;");
    xs_jit_xs_return(aTHX_ b, 1);
}

void xs_jit_return_no(pTHX_ XS_JIT_Builder* b) {
    xs_jit_line(aTHX_ b, "ST(0) = &PL_sv_no;");
    xs_jit_xs_return(aTHX_ b, 1);
}

void xs_jit_return_self(pTHX_ XS_JIT_Builder* b) {
    xs_jit_line(aTHX_ b, "ST(0) = self;");
    xs_jit_xs_return(aTHX_ b, 1);
}

/* ============================================
 * Common method patterns
 * ============================================ */

void xs_jit_method_start(pTHX_ XS_JIT_Builder* b, const char* func_name, int min_args, int max_args, const char* usage) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    if (min_args > 0 || max_args >= 0) {
        xs_jit_check_items(aTHX_ b, min_args, max_args, usage);
    }
    xs_jit_get_self_hv(aTHX_ b);
}

/* Predicate (returns true/false based on attribute existence) */
void xs_jit_predicate(pTHX_ XS_JIT_Builder* b, const char* func_name, const char* attr_name, STRLEN attr_len) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_get_self_hv(aTHX_ b);
    xs_jit_line(aTHX_ b, "SV** valp = hv_fetch(hv, \"%s\", %lu, 0);", attr_name, (unsigned long)attr_len);
    xs_jit_if(aTHX_ b, "valp != NULL");
    xs_jit_return_yes(aTHX_ b);
    xs_jit_else(aTHX_ b);
    xs_jit_return_no(aTHX_ b);
    xs_jit_endif(aTHX_ b);
    xs_jit_xs_end(aTHX_ b);
}

/* Clearer (deletes an attribute) */
void xs_jit_clearer(pTHX_ XS_JIT_Builder* b, const char* func_name, const char* attr_name, STRLEN attr_len) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_get_self_hv(aTHX_ b);
    xs_jit_line(aTHX_ b, "(void)hv_delete(hv, \"%s\", %lu, G_DISCARD);", attr_name, (unsigned long)attr_len);
    xs_jit_return_self(aTHX_ b);
    xs_jit_xs_end(aTHX_ b);
}

/* ============================================
 * Error handling
 * ============================================ */

void xs_jit_croak(pTHX_ XS_JIT_Builder* b, const char* message) {
    xs_jit_line(aTHX_ b, "croak(\"%s\");", message);
}

void xs_jit_warn(pTHX_ XS_JIT_Builder* b, const char* message) {
    xs_jit_line(aTHX_ b, "warn(\"%s\");", message);
}

/* ============================================
 * Prebuilt patterns
 * ============================================ */

void xs_jit_ro_accessor(pTHX_ XS_JIT_Builder* b, const char* func_name, const char* attr_name, STRLEN attr_len) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_line(aTHX_ b, "dXSARGS;");
    xs_jit_line(aTHX_ b, "PERL_UNUSED_VAR(cv); PERL_UNUSED_VAR(items);");

    /* Use hv_fetch for reliable hash lookup */
    xs_jit_line(aTHX_ b, "SV** valp = hv_fetch((HV*)SvRV(ST(0)), \"%s\", %lu, 0);",
                attr_name, (unsigned long)attr_len);
    xs_jit_line(aTHX_ b, "ST(0) = (valp && *valp) ? *valp : &PL_sv_undef;");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");

    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_rw_accessor(pTHX_ XS_JIT_Builder* b, const char* func_name, const char* attr_name, STRLEN attr_len) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_line(aTHX_ b, "dXSARGS;");
    xs_jit_line(aTHX_ b, "PERL_UNUSED_VAR(cv);");

    xs_jit_line(aTHX_ b, "HV* hv = (HV*)SvRV(ST(0));");

    xs_jit_if(aTHX_ b, "items > 1");
    /* Setter: use hv_store */
    xs_jit_line(aTHX_ b, "SV* val = newSVsv(ST(1));");
    xs_jit_line(aTHX_ b, "SV** slot = hv_store(hv, \"%s\", %lu, val, 0);",
                attr_name, (unsigned long)attr_len);
    xs_jit_line(aTHX_ b, "ST(0) = slot ? *slot : val;");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    xs_jit_endif(aTHX_ b);

    /* Getter: use hv_fetch */
    xs_jit_line(aTHX_ b, "SV** valp = hv_fetch(hv, \"%s\", %lu, 0);",
                attr_name, (unsigned long)attr_len);
    xs_jit_line(aTHX_ b, "ST(0) = (valp && *valp) ? *valp : &PL_sv_undef;");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");

    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_constructor(pTHX_ XS_JIT_Builder* b, const char* func_name, const char* class_name, XS_JIT_Attr* attrs, int num_attrs) {
    int i;
    
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Get class name");
    xs_jit_declare_sv(aTHX_ b, "class_sv", "ST(0)");
    xs_jit_line(aTHX_ b, "const char* classname = SvPV_nolen(class_sv);");
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Parse args hash if provided");
    xs_jit_declare_hv(aTHX_ b, "args", "NULL");
    xs_jit_if(aTHX_ b, "items > 1 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV");
    xs_jit_line(aTHX_ b, "args = (HV*)SvRV(ST(1));");
    xs_jit_endif(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Create new hash for object");
    xs_jit_declare_hv(aTHX_ b, "hv", "newHV()");
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Process attributes");
    for (i = 0; i < num_attrs; i++) {
        const char* name = attrs[i].name;
        STRLEN len = attrs[i].len;
        
        xs_jit_line(aTHX_ b, "{");
        b->indent++;
        xs_jit_line(aTHX_ b, "SV** %s_valp = args ? hv_fetch(args, \"%s\", %lu, 0) : NULL;", name, name, (unsigned long)len);
        /* Build condition string for if */
        SV* cond_sv = newSVpvf("%s_valp && SvOK(*%s_valp)", name, name);
        xs_jit_if(aTHX_ b, SvPV_nolen(cond_sv));
        SvREFCNT_dec(cond_sv);
        xs_jit_line(aTHX_ b, "(void)hv_store(hv, \"%s\", %lu, newSVsv(*%s_valp), 0);", name, (unsigned long)len, name);
        xs_jit_endif(aTHX_ b);
        b->indent--;
        xs_jit_line(aTHX_ b, "}");
    }
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Bless and return");
    xs_jit_declare_sv(aTHX_ b, "self", "newRV_noinc((SV*)hv)");
    xs_jit_line(aTHX_ b, "sv_bless(self, gv_stashpv(classname, GV_ADD));");
    xs_jit_line(aTHX_ b, "ST(0) = sv_2mortal(self);");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    
    xs_jit_xs_end(aTHX_ b);
}

/* ============================================
 * New constructor variants
 * ============================================ */

void xs_jit_new_simple(pTHX_ XS_JIT_Builder* b, const char* func_name) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_line(aTHX_ b, "dXSARGS;");
    xs_jit_line(aTHX_ b, "PERL_UNUSED_VAR(cv); PERL_UNUSED_VAR(items);");
    
    xs_jit_line(aTHX_ b, "SV* class_sv = ST(0);");
    xs_jit_line(aTHX_ b, "const char* classname = SvPV_nolen(class_sv);");
    xs_jit_line(aTHX_ b, "HV* hv = newHV();");
    xs_jit_line(aTHX_ b, "SV* self = newRV_noinc((SV*)hv);");
    xs_jit_line(aTHX_ b, "sv_bless(self, gv_stashpv(classname, GV_ADD));");
    xs_jit_line(aTHX_ b, "ST(0) = sv_2mortal(self);");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_new_hash(pTHX_ XS_JIT_Builder* b, const char* func_name) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Get class name");
    xs_jit_line(aTHX_ b, "SV* class_sv = ST(0);");
    xs_jit_line(aTHX_ b, "const char* classname = SvPV_nolen(class_sv);");
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Create object hash");
    xs_jit_line(aTHX_ b, "HV* hv = newHV();");
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Parse args - accept hashref or flat list");
    xs_jit_if(aTHX_ b, "items > 1");
    xs_jit_if(aTHX_ b, "SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV");
    xs_jit_comment(aTHX_ b, "Hashref: Class->new(\\%args)");
    xs_jit_line(aTHX_ b, "HV* args = (HV*)SvRV(ST(1));");
    xs_jit_line(aTHX_ b, "hv_iterinit(args);");
    xs_jit_line(aTHX_ b, "HE* entry;");
    xs_jit_while(aTHX_ b, "(entry = hv_iternext(args)) != NULL");
    xs_jit_line(aTHX_ b, "STRLEN klen;");
    xs_jit_line(aTHX_ b, "const char* key = HePV(entry, klen);");
    xs_jit_line(aTHX_ b, "SV* val = HeVAL(entry);");
    xs_jit_line(aTHX_ b, "hv_store(hv, key, klen, newSVsv(val), 0);");
    xs_jit_endloop(aTHX_ b);
    xs_jit_else(aTHX_ b);
    xs_jit_comment(aTHX_ b, "Flat list: Class->new(key => val, ...)");
    xs_jit_if(aTHX_ b, "(items - 1) % 2 != 0");
    xs_jit_croak(aTHX_ b, "Odd number of arguments to new()");
    xs_jit_endif(aTHX_ b);
    xs_jit_line(aTHX_ b, "int i;");
    xs_jit_for(aTHX_ b, "i = 1", "i < items", "i += 2");
    xs_jit_line(aTHX_ b, "STRLEN klen;");
    xs_jit_line(aTHX_ b, "const char* key = SvPV(ST(i), klen);");
    xs_jit_line(aTHX_ b, "SV* val = ST(i + 1);");
    xs_jit_line(aTHX_ b, "hv_store(hv, key, klen, newSVsv(val), 0);");
    xs_jit_endloop(aTHX_ b);
    xs_jit_endif(aTHX_ b);
    xs_jit_endif(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Bless and return");
    xs_jit_line(aTHX_ b, "SV* self = newRV_noinc((SV*)hv);");
    xs_jit_line(aTHX_ b, "sv_bless(self, gv_stashpv(classname, GV_ADD));");
    xs_jit_line(aTHX_ b, "ST(0) = sv_2mortal(self);");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_new_array(pTHX_ XS_JIT_Builder* b, const char* func_name, int num_slots) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_line(aTHX_ b, "dXSARGS;");
    xs_jit_line(aTHX_ b, "PERL_UNUSED_VAR(cv); PERL_UNUSED_VAR(items);");
    
    xs_jit_comment(aTHX_ b, "Get class name");
    xs_jit_line(aTHX_ b, "SV* class_sv = ST(0);");
    xs_jit_line(aTHX_ b, "const char* classname = SvPV_nolen(class_sv);");
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Create array with pre-extended size");
    xs_jit_line(aTHX_ b, "AV* av = newAV();");
    if (num_slots > 0) {
        char cond_buf[64];
        xs_jit_line(aTHX_ b, "av_extend(av, %d);", num_slots - 1);
        xs_jit_comment(aTHX_ b, "Initialize slots to undef");
        xs_jit_line(aTHX_ b, "int i;");
        snprintf(cond_buf, sizeof(cond_buf), "i < %d", num_slots);
        xs_jit_for(aTHX_ b, "i = 0", cond_buf, "i++");
        xs_jit_line(aTHX_ b, "av_store(av, i, newSV(0));");
        xs_jit_endloop(aTHX_ b);
    }
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Bless and return");
    xs_jit_line(aTHX_ b, "SV* self = newRV_noinc((SV*)av);");
    xs_jit_line(aTHX_ b, "sv_bless(self, gv_stashpv(classname, GV_ADD));");
    xs_jit_line(aTHX_ b, "ST(0) = sv_2mortal(self);");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_new_with_build(pTHX_ XS_JIT_Builder* b, const char* func_name) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Get class name");
    xs_jit_line(aTHX_ b, "SV* class_sv = ST(0);");
    xs_jit_line(aTHX_ b, "const char* classname = SvPV_nolen(class_sv);");
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Create object hash and args hash");
    xs_jit_line(aTHX_ b, "HV* hv = newHV();");
    xs_jit_line(aTHX_ b, "HV* args = newHV();");
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Parse args - accept hashref or flat list");
    xs_jit_if(aTHX_ b, "items > 1");
    xs_jit_if(aTHX_ b, "SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV");
    xs_jit_comment(aTHX_ b, "Hashref: Class->new(\\%args)");
    xs_jit_line(aTHX_ b, "HV* src = (HV*)SvRV(ST(1));");
    xs_jit_line(aTHX_ b, "hv_iterinit(src);");
    xs_jit_line(aTHX_ b, "HE* entry;");
    xs_jit_while(aTHX_ b, "(entry = hv_iternext(src)) != NULL");
    xs_jit_line(aTHX_ b, "STRLEN klen;");
    xs_jit_line(aTHX_ b, "const char* key = HePV(entry, klen);");
    xs_jit_line(aTHX_ b, "SV* val = newSVsv(HeVAL(entry));");
    xs_jit_line(aTHX_ b, "hv_store(hv, key, klen, val, 0);");
    xs_jit_line(aTHX_ b, "hv_store(args, key, klen, newSVsv(val), 0);");
    xs_jit_endloop(aTHX_ b);
    xs_jit_else(aTHX_ b);
    xs_jit_comment(aTHX_ b, "Flat list: Class->new(key => val, ...)");
    xs_jit_if(aTHX_ b, "(items - 1) % 2 != 0");
    xs_jit_croak(aTHX_ b, "Odd number of arguments to new()");
    xs_jit_endif(aTHX_ b);
    xs_jit_line(aTHX_ b, "int i;");
    xs_jit_for(aTHX_ b, "i = 1", "i < items", "i += 2");
    xs_jit_line(aTHX_ b, "STRLEN klen;");
    xs_jit_line(aTHX_ b, "const char* key = SvPV(ST(i), klen);");
    xs_jit_line(aTHX_ b, "SV* val = newSVsv(ST(i + 1));");
    xs_jit_line(aTHX_ b, "hv_store(hv, key, klen, val, 0);");
    xs_jit_line(aTHX_ b, "hv_store(args, key, klen, newSVsv(val), 0);");
    xs_jit_endloop(aTHX_ b);
    xs_jit_endif(aTHX_ b);
    xs_jit_endif(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Bless object");
    xs_jit_line(aTHX_ b, "SV* self = newRV_noinc((SV*)hv);");
    xs_jit_line(aTHX_ b, "HV* stash = gv_stashpv(classname, GV_ADD);");
    xs_jit_line(aTHX_ b, "sv_bless(self, stash);");
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Call BUILD if it exists");
    xs_jit_line(aTHX_ b, "GV* build_gv = gv_fetchmeth(stash, \"BUILD\", 5, 0);");
    xs_jit_if(aTHX_ b, "build_gv");
    xs_jit_line(aTHX_ b, "dSP;");
    xs_jit_line(aTHX_ b, "ENTER;");
    xs_jit_line(aTHX_ b, "SAVETMPS;");
    xs_jit_line(aTHX_ b, "PUSHMARK(SP);");
    xs_jit_line(aTHX_ b, "XPUSHs(self);");
    xs_jit_line(aTHX_ b, "XPUSHs(newRV_noinc((SV*)args));");
    xs_jit_line(aTHX_ b, "PUTBACK;");
    xs_jit_line(aTHX_ b, "call_sv((SV*)GvCV(build_gv), G_DISCARD);");
    xs_jit_line(aTHX_ b, "FREETMPS;");
    xs_jit_line(aTHX_ b, "LEAVE;");
    xs_jit_else(aTHX_ b);
    xs_jit_line(aTHX_ b, "SvREFCNT_dec((SV*)args);");
    xs_jit_endif(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "ST(0) = sv_2mortal(self);");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    
    xs_jit_xs_end(aTHX_ b);
}

/* ============================================
 * Constructor validation
 * ============================================ */

void xs_jit_new_with_required(pTHX_ XS_JIT_Builder* b, const char* func_name,
                               const char** required_attrs, STRLEN* required_lens,
                               int num_required) {
    int i;
    
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Get class name");
    xs_jit_line(aTHX_ b, "SV* class_sv = ST(0);");
    xs_jit_line(aTHX_ b, "const char* classname = SvPV_nolen(class_sv);");
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Create object hash");
    xs_jit_line(aTHX_ b, "HV* hv = newHV();");
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Parse args - accept hashref or flat list");
    xs_jit_if(aTHX_ b, "items > 1");
    xs_jit_if(aTHX_ b, "SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV");
    xs_jit_comment(aTHX_ b, "Hashref: Class->new(\\%args)");
    xs_jit_line(aTHX_ b, "HV* src = (HV*)SvRV(ST(1));");
    xs_jit_line(aTHX_ b, "hv_iterinit(src);");
    xs_jit_line(aTHX_ b, "HE* entry;");
    xs_jit_while(aTHX_ b, "(entry = hv_iternext(src)) != NULL");
    xs_jit_line(aTHX_ b, "STRLEN klen;");
    xs_jit_line(aTHX_ b, "const char* key = HePV(entry, klen);");
    xs_jit_line(aTHX_ b, "SV* val = newSVsv(HeVAL(entry));");
    xs_jit_line(aTHX_ b, "hv_store(hv, key, klen, val, 0);");
    xs_jit_endloop(aTHX_ b);
    xs_jit_else(aTHX_ b);
    xs_jit_comment(aTHX_ b, "Flat list: Class->new(key => val, ...)");
    xs_jit_if(aTHX_ b, "(items - 1) % 2 != 0");
    xs_jit_croak(aTHX_ b, "Odd number of arguments to new()");
    xs_jit_endif(aTHX_ b);
    xs_jit_line(aTHX_ b, "int i;");
    xs_jit_for(aTHX_ b, "i = 1", "i < items", "i += 2");
    xs_jit_line(aTHX_ b, "STRLEN klen;");
    xs_jit_line(aTHX_ b, "const char* key = SvPV(ST(i), klen);");
    xs_jit_line(aTHX_ b, "SV* val = newSVsv(ST(i + 1));");
    xs_jit_line(aTHX_ b, "hv_store(hv, key, klen, val, 0);");
    xs_jit_endloop(aTHX_ b);
    xs_jit_endif(aTHX_ b);
    xs_jit_endif(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    
    /* Validate required attributes */
    if (num_required > 0) {
        xs_jit_comment(aTHX_ b, "Validate required attributes");
        for (i = 0; i < num_required; i++) {
            xs_jit_line(aTHX_ b, "{");
            xs_jit_indent(b);
            xs_jit_line(aTHX_ b, "SV** valp = hv_fetch(hv, \"%s\", %d, 0);",
                        required_attrs[i], (int)required_lens[i]);
            xs_jit_if(aTHX_ b, "!valp || !SvOK(*valp)");
            xs_jit_line(aTHX_ b, "SvREFCNT_dec((SV*)hv);");
            xs_jit_line(aTHX_ b, "croak(\"Missing required attribute '%s'\");",
                        required_attrs[i]);
            xs_jit_endif(aTHX_ b);
            xs_jit_dedent(b);
            xs_jit_line(aTHX_ b, "}");
        }
        xs_jit_blank(aTHX_ b);
    }
    
    xs_jit_comment(aTHX_ b, "Bless object");
    xs_jit_line(aTHX_ b, "SV* self = newRV_noinc((SV*)hv);");
    xs_jit_line(aTHX_ b, "HV* stash = gv_stashpv(classname, GV_ADD);");
    xs_jit_line(aTHX_ b, "sv_bless(self, stash);");
    xs_jit_blank(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "ST(0) = sv_2mortal(self);");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_rw_accessor_typed(pTHX_ XS_JIT_Builder* b, const char* func_name,
                               const char* attr_name, STRLEN attr_len,
                               int type, const char* error_msg) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "SV* self = ST(0);");
    xs_jit_line(aTHX_ b, "HV* hv = (HV*)SvRV(self);");
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Setter with type validation");
    xs_jit_if(aTHX_ b, "items > 1");
    xs_jit_line(aTHX_ b, "SV* val = ST(1);");
    
    /* Type checking - only check if value is defined (undef bypasses unless TYPE_DEFINED) */
    if (type == 1) { /* TYPE_DEFINED */
        xs_jit_if(aTHX_ b, "!SvOK(val)");
        xs_jit_croak(aTHX_ b, error_msg);
        xs_jit_endif(aTHX_ b);
    } else if (type == 2) { /* TYPE_INT */
        xs_jit_if(aTHX_ b, "SvOK(val) && !SvIOK(val) && !(SvNOK(val) && SvNV(val) == (NV)(IV)SvNV(val))");
        xs_jit_croak(aTHX_ b, error_msg);
        xs_jit_endif(aTHX_ b);
    } else if (type == 3) { /* TYPE_NUM */
        xs_jit_if(aTHX_ b, "SvOK(val) && !SvNOK(val) && !SvIOK(val) && !looks_like_number(val)");
        xs_jit_croak(aTHX_ b, error_msg);
        xs_jit_endif(aTHX_ b);
    } else if (type == 4) { /* TYPE_STR */
        xs_jit_if(aTHX_ b, "SvOK(val) && SvROK(val)");
        xs_jit_croak(aTHX_ b, error_msg);
        xs_jit_endif(aTHX_ b);
    } else if (type == 5) { /* TYPE_REF */
        xs_jit_if(aTHX_ b, "SvOK(val) && !SvROK(val)");
        xs_jit_croak(aTHX_ b, error_msg);
        xs_jit_endif(aTHX_ b);
    } else if (type == 6) { /* TYPE_ARRAYREF */
        xs_jit_if(aTHX_ b, "SvOK(val) && !(SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV)");
        xs_jit_croak(aTHX_ b, error_msg);
        xs_jit_endif(aTHX_ b);
    } else if (type == 7) { /* TYPE_HASHREF */
        xs_jit_if(aTHX_ b, "SvOK(val) && !(SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV)");
        xs_jit_croak(aTHX_ b, error_msg);
        xs_jit_endif(aTHX_ b);
    } else if (type == 8) { /* TYPE_CODEREF */
        xs_jit_if(aTHX_ b, "SvOK(val) && !(SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV)");
        xs_jit_croak(aTHX_ b, error_msg);
        xs_jit_endif(aTHX_ b);
    } else if (type == 9) { /* TYPE_OBJECT */
        xs_jit_if(aTHX_ b, "SvOK(val) && !sv_isobject(val)");
        xs_jit_croak(aTHX_ b, error_msg);
        xs_jit_endif(aTHX_ b);
    }
    /* TYPE_ANY (0) and TYPE_BLESSED (10) - no check for TYPE_ANY, 
       TYPE_BLESSED requires classname which we don't have here */
    
    xs_jit_line(aTHX_ b, "hv_store(hv, \"%s\", %d, newSVsv(val), 0);",
                attr_name, (int)attr_len);
    xs_jit_endif(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Getter");
    xs_jit_line(aTHX_ b, "SV** valp = hv_fetch(hv, \"%s\", %d, 0);",
                attr_name, (int)attr_len);
    xs_jit_if(aTHX_ b, "valp && *valp");
    xs_jit_line(aTHX_ b, "ST(0) = *valp;");
    xs_jit_else(aTHX_ b);
    xs_jit_line(aTHX_ b, "ST(0) = &PL_sv_undef;");
    xs_jit_endif(aTHX_ b);
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    
    xs_jit_xs_end(aTHX_ b);
}

/* ============================================
 * Clone methods
 * ============================================ */

void xs_jit_clone_hash(pTHX_ XS_JIT_Builder* b, const char* func_name) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Get self and source hash");
    xs_jit_line(aTHX_ b, "SV* self = ST(0);");
    xs_jit_line(aTHX_ b, "if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV) {");
    xs_jit_indent(b);
    xs_jit_croak(aTHX_ b, "clone requires a hash-based object");
    xs_jit_dedent(b);
    xs_jit_line(aTHX_ b, "}");
    xs_jit_line(aTHX_ b, "HV* src = (HV*)SvRV(self);");
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Create new hash and copy all entries");
    xs_jit_line(aTHX_ b, "HV* dst = newHV();");
    xs_jit_line(aTHX_ b, "hv_iterinit(src);");
    xs_jit_line(aTHX_ b, "HE* entry;");
    xs_jit_while(aTHX_ b, "(entry = hv_iternext(src)) != NULL");
    xs_jit_line(aTHX_ b, "SV* key_sv = hv_iterkeysv(entry);");
    xs_jit_line(aTHX_ b, "SV* val = hv_iterval(src, entry);");
    xs_jit_line(aTHX_ b, "hv_store_ent(dst, key_sv, newSVsv(val), 0);");
    xs_jit_endloop(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Bless with same class as original");
    xs_jit_line(aTHX_ b, "SV* clone = newRV_noinc((SV*)dst);");
    xs_jit_line(aTHX_ b, "sv_bless(clone, SvSTASH(SvRV(self)));");
    xs_jit_blank(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "ST(0) = sv_2mortal(clone);");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_clone_array(pTHX_ XS_JIT_Builder* b, const char* func_name) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Get self and source array");
    xs_jit_line(aTHX_ b, "SV* self = ST(0);");
    xs_jit_line(aTHX_ b, "if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV) {");
    xs_jit_indent(b);
    xs_jit_croak(aTHX_ b, "clone requires an array-based object");
    xs_jit_dedent(b);
    xs_jit_line(aTHX_ b, "}");
    xs_jit_line(aTHX_ b, "AV* src = (AV*)SvRV(self);");
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Create new array and copy all elements");
    xs_jit_line(aTHX_ b, "SSize_t len = av_len(src) + 1;");
    xs_jit_line(aTHX_ b, "AV* dst = newAV();");
    xs_jit_line(aTHX_ b, "av_extend(dst, len - 1);");
    xs_jit_line(aTHX_ b, "SSize_t i;");
    xs_jit_for(aTHX_ b, "i = 0", "i < len", "i++");
    xs_jit_line(aTHX_ b, "SV** elem = av_fetch(src, i, 0);");
    xs_jit_line(aTHX_ b, "if (elem && *elem) {");
    xs_jit_indent(b);
    xs_jit_line(aTHX_ b, "av_store(dst, i, newSVsv(*elem));");
    xs_jit_dedent(b);
    xs_jit_line(aTHX_ b, "} else {");
    xs_jit_indent(b);
    xs_jit_line(aTHX_ b, "av_store(dst, i, newSV(0));");
    xs_jit_dedent(b);
    xs_jit_line(aTHX_ b, "}");
    xs_jit_endloop(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Bless with same class as original");
    xs_jit_line(aTHX_ b, "SV* clone = newRV_noinc((SV*)dst);");
    xs_jit_line(aTHX_ b, "sv_bless(clone, SvSTASH(SvRV(self)));");
    xs_jit_blank(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "ST(0) = sv_2mortal(clone);");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    
    xs_jit_xs_end(aTHX_ b);
}

/* ============================================
 * Unified constructor & weak refs (Phase 3)
 * ============================================ */

void xs_jit_hv_store_weak(pTHX_ XS_JIT_Builder* b, const char* hv_name,
                           const char* key, int key_len, const char* value_expr) {
    xs_jit_line(aTHX_ b, "{");
    xs_jit_indent(b);
    xs_jit_line(aTHX_ b, "SV* weak_val = %s;", value_expr);
    xs_jit_if(aTHX_ b, "SvROK(weak_val)");
    xs_jit_line(aTHX_ b, "sv_rvweaken(weak_val);");
    xs_jit_endif(aTHX_ b);
    xs_jit_line(aTHX_ b, "hv_store(%s, \"%s\", %d, weak_val, 0);",
                hv_name, key, key_len);
    xs_jit_dedent(b);
    xs_jit_line(aTHX_ b, "}");
}

void xs_jit_rw_accessor_weak(pTHX_ XS_JIT_Builder* b, const char* func_name,
                              const char* attr_name, STRLEN attr_len) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Get self hash");
    xs_jit_get_self_hv(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Setter with weak reference");
    xs_jit_if(aTHX_ b, "items > 1");
    xs_jit_line(aTHX_ b, "SV* val = newSVsv(ST(1));");
    xs_jit_if(aTHX_ b, "SvROK(val)");
    xs_jit_line(aTHX_ b, "sv_rvweaken(val);");
    xs_jit_endif(aTHX_ b);
    xs_jit_line(aTHX_ b, "hv_store(hv, \"%s\", %d, val, 0);",
                attr_name, (int)attr_len);
    xs_jit_endif(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Getter");
    xs_jit_line(aTHX_ b, "SV** valp = hv_fetch(hv, \"%s\", %d, 0);",
                attr_name, (int)attr_len);
    xs_jit_if(aTHX_ b, "valp && SvOK(*valp)");
    xs_jit_line(aTHX_ b, "ST(0) = *valp;");
    xs_jit_else(aTHX_ b);
    xs_jit_line(aTHX_ b, "ST(0) = &PL_sv_undef;");
    xs_jit_endif(aTHX_ b);
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_new_complete(pTHX_ XS_JIT_Builder* b, const char* func_name,
                          XS_JIT_AttrSpec* attrs, int num_attrs,
                          int call_build) {
    int i;
    
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Get class and create object hash");
    xs_jit_line(aTHX_ b, "SV* class_sv = ST(0);");
    xs_jit_line(aTHX_ b, "const char* classname;");
    xs_jit_line(aTHX_ b, "HV* stash;");
    xs_jit_blank(aTHX_ b);
    
    xs_jit_if(aTHX_ b, "SvROK(class_sv)");
    xs_jit_line(aTHX_ b, "stash = SvSTASH(SvRV(class_sv));");
    xs_jit_line(aTHX_ b, "classname = HvNAME(stash);");
    xs_jit_else(aTHX_ b);
    xs_jit_line(aTHX_ b, "classname = SvPV_nolen(class_sv);");
    xs_jit_line(aTHX_ b, "stash = gv_stashsv(class_sv, GV_ADD);");
    xs_jit_endif(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "HV* hv = newHV();");
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Parse args - accept hashref or flat list");
    xs_jit_line(aTHX_ b, "HV* args = NULL;");
    xs_jit_if(aTHX_ b, "items > 1");
    xs_jit_if(aTHX_ b, "SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV");
    xs_jit_comment(aTHX_ b, "Hashref: Class->new(\\%args)");
    xs_jit_line(aTHX_ b, "args = (HV*)SvRV(ST(1));");
    xs_jit_else(aTHX_ b);
    xs_jit_comment(aTHX_ b, "Flat list: Class->new(key => val, ...)");
    xs_jit_if(aTHX_ b, "(items - 1) % 2 != 0");
    xs_jit_croak(aTHX_ b, "Odd number of arguments to new()");
    xs_jit_endif(aTHX_ b);
    xs_jit_line(aTHX_ b, "args = newHV();");
    xs_jit_line(aTHX_ b, "int i;");
    xs_jit_for(aTHX_ b, "i = 1", "i < items", "i += 2");
    xs_jit_line(aTHX_ b, "STRLEN klen;");
    xs_jit_line(aTHX_ b, "const char* key = SvPV(ST(i), klen);");
    xs_jit_line(aTHX_ b, "hv_store(args, key, klen, newSVsv(ST(i + 1)), 0);");
    xs_jit_endloop(aTHX_ b);
    xs_jit_endif(aTHX_ b);
    xs_jit_endif(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    
    /* Process each attribute */
    for (i = 0; i < num_attrs; i++) {
        XS_JIT_AttrSpec* attr = &attrs[i];
        
        xs_jit_line(aTHX_ b, "/* Process attribute '%s' */", attr->name);
        xs_jit_line(aTHX_ b, "{");
        xs_jit_indent(b);
        
        xs_jit_line(aTHX_ b, "SV** valp = args ? hv_fetch(args, \"%s\", %d, 0) : NULL;",
                    attr->name, (int)attr->len);
        xs_jit_line(aTHX_ b, "SV* val = (valp && SvOK(*valp)) ? *valp : NULL;");
        xs_jit_blank(aTHX_ b);
        
        /* Coercion: call method to transform value */
        if (attr->coerce && attr->coerce_len > 0) {
            xs_jit_if(aTHX_ b, "val");
            xs_jit_line(aTHX_ b, "{");
            xs_jit_indent(b);
            xs_jit_line(aTHX_ b, "dSP;");
            xs_jit_line(aTHX_ b, "ENTER;");
            xs_jit_line(aTHX_ b, "SAVETMPS;");
            xs_jit_line(aTHX_ b, "PUSHMARK(SP);");
            xs_jit_line(aTHX_ b, "XPUSHs(class_sv);");
            xs_jit_line(aTHX_ b, "XPUSHs(val);");
            xs_jit_line(aTHX_ b, "PUTBACK;");
            xs_jit_line(aTHX_ b, "int count = call_method(\"%s\", G_SCALAR);", attr->coerce);
            xs_jit_line(aTHX_ b, "SPAGAIN;");
            xs_jit_if(aTHX_ b, "count > 0");
            xs_jit_line(aTHX_ b, "val = newSVsv(POPs);");
            xs_jit_endif(aTHX_ b);
            xs_jit_line(aTHX_ b, "PUTBACK;");
            xs_jit_line(aTHX_ b, "FREETMPS;");
            xs_jit_line(aTHX_ b, "LEAVE;");
            xs_jit_dedent(b);
            xs_jit_line(aTHX_ b, "}");
            xs_jit_endif(aTHX_ b);
        }
        
        /* Required check */
        if (attr->required) {
            xs_jit_if(aTHX_ b, "!val");
            xs_jit_line(aTHX_ b, "SvREFCNT_dec((SV*)hv);");
            xs_jit_line(aTHX_ b, "croak(\"Missing required attribute '%s'\");", attr->name);
            xs_jit_endif(aTHX_ b);
        }
        
        /* Type validation */
        if (attr->type > 0 && attr->type_msg) {
            xs_jit_if(aTHX_ b, "val");
            
            switch (attr->type) {
                case 1: /* TYPE_DEFINED */
                    /* Already checked via val != NULL */
                    break;
                case 2: /* TYPE_INT */
                    xs_jit_if(aTHX_ b, "!SvIOK(val) && !(SvNOK(val) && SvNV(val) == (NV)(IV)SvNV(val))");
                    xs_jit_line(aTHX_ b, "SvREFCNT_dec((SV*)hv);");
                    xs_jit_croak(aTHX_ b, attr->type_msg);
                    xs_jit_endif(aTHX_ b);
                    break;
                case 3: /* TYPE_NUM */
                    xs_jit_if(aTHX_ b, "!SvNOK(val) && !SvIOK(val) && !looks_like_number(val)");
                    xs_jit_line(aTHX_ b, "SvREFCNT_dec((SV*)hv);");
                    xs_jit_croak(aTHX_ b, attr->type_msg);
                    xs_jit_endif(aTHX_ b);
                    break;
                case 4: /* TYPE_STR */
                    xs_jit_if(aTHX_ b, "SvROK(val)");
                    xs_jit_line(aTHX_ b, "SvREFCNT_dec((SV*)hv);");
                    xs_jit_croak(aTHX_ b, attr->type_msg);
                    xs_jit_endif(aTHX_ b);
                    break;
                case 5: /* TYPE_REF */
                    xs_jit_if(aTHX_ b, "!SvROK(val)");
                    xs_jit_line(aTHX_ b, "SvREFCNT_dec((SV*)hv);");
                    xs_jit_croak(aTHX_ b, attr->type_msg);
                    xs_jit_endif(aTHX_ b);
                    break;
                case 6: /* TYPE_ARRAYREF */
                    xs_jit_if(aTHX_ b, "!(SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV)");
                    xs_jit_line(aTHX_ b, "SvREFCNT_dec((SV*)hv);");
                    xs_jit_croak(aTHX_ b, attr->type_msg);
                    xs_jit_endif(aTHX_ b);
                    break;
                case 7: /* TYPE_HASHREF */
                    xs_jit_if(aTHX_ b, "!(SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV)");
                    xs_jit_line(aTHX_ b, "SvREFCNT_dec((SV*)hv);");
                    xs_jit_croak(aTHX_ b, attr->type_msg);
                    xs_jit_endif(aTHX_ b);
                    break;
                case 8: /* TYPE_CODEREF */
                    xs_jit_if(aTHX_ b, "!(SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV)");
                    xs_jit_line(aTHX_ b, "SvREFCNT_dec((SV*)hv);");
                    xs_jit_croak(aTHX_ b, attr->type_msg);
                    xs_jit_endif(aTHX_ b);
                    break;
                case 9: /* TYPE_OBJECT */
                    xs_jit_if(aTHX_ b, "!sv_isobject(val)");
                    xs_jit_line(aTHX_ b, "SvREFCNT_dec((SV*)hv);");
                    xs_jit_croak(aTHX_ b, attr->type_msg);
                    xs_jit_endif(aTHX_ b);
                    break;
            }
            
            xs_jit_endif(aTHX_ b);
        }
        
        /* Store value or apply default */
        xs_jit_if(aTHX_ b, "val");
        
        if (attr->weak) {
            xs_jit_line(aTHX_ b, "SV* store_val = newSVsv(val);");
            xs_jit_if(aTHX_ b, "SvROK(store_val)");
            xs_jit_line(aTHX_ b, "sv_rvweaken(store_val);");
            xs_jit_endif(aTHX_ b);
            xs_jit_line(aTHX_ b, "hv_store(hv, \"%s\", %d, store_val, 0);",
                        attr->name, (int)attr->len);
        } else {
            xs_jit_line(aTHX_ b, "hv_store(hv, \"%s\", %d, newSVsv(val), 0);",
                        attr->name, (int)attr->len);
        }
        
        xs_jit_else(aTHX_ b);
        
        /* Apply default if no value */
        switch (attr->has_default) {
            case 1: /* IV */
                xs_jit_line(aTHX_ b, "hv_store(hv, \"%s\", %d, newSViv(%" IVdf "), 0);",
                            attr->name, (int)attr->len, attr->default_iv);
                break;
            case 2: /* NV */
                xs_jit_line(aTHX_ b, "hv_store(hv, \"%s\", %d, newSVnv(%g), 0);",
                            attr->name, (int)attr->len, attr->default_nv);
                break;
            case 3: /* PV */
                xs_jit_line(aTHX_ b, "hv_store(hv, \"%s\", %d, newSVpvn(\"%s\", %d), 0);",
                            attr->name, (int)attr->len,
                            attr->default_pv, (int)attr->default_pv_len);
                break;
            case 4: /* AV (empty arrayref) */
                xs_jit_line(aTHX_ b, "hv_store(hv, \"%s\", %d, newRV_noinc((SV*)newAV()), 0);",
                            attr->name, (int)attr->len);
                break;
            case 5: /* HV (empty hashref) */
                xs_jit_line(aTHX_ b, "hv_store(hv, \"%s\", %d, newRV_noinc((SV*)newHV()), 0);",
                            attr->name, (int)attr->len);
                break;
            default:
                /* No default, leave undefined */
                break;
        }
        
        xs_jit_endif(aTHX_ b);
        
        xs_jit_dedent(b);
        xs_jit_line(aTHX_ b, "}");
        xs_jit_blank(aTHX_ b);
    }
    
    xs_jit_comment(aTHX_ b, "Bless and return");
    xs_jit_line(aTHX_ b, "SV* self = newRV_noinc((SV*)hv);");
    xs_jit_line(aTHX_ b, "sv_bless(self, stash);");
    xs_jit_blank(aTHX_ b);
    
    /* Call BUILD if requested */
    if (call_build) {
        xs_jit_comment(aTHX_ b, "Call BUILD if it exists");
        xs_jit_line(aTHX_ b, "GV* build_gv = gv_fetchmethod_autoload(stash, \"BUILD\", 0);");
        xs_jit_if(aTHX_ b, "build_gv");
        xs_jit_line(aTHX_ b, "dSP;");
        xs_jit_line(aTHX_ b, "ENTER;");
        xs_jit_line(aTHX_ b, "SAVETMPS;");
        xs_jit_line(aTHX_ b, "PUSHMARK(SP);");
        xs_jit_line(aTHX_ b, "XPUSHs(self);");
        xs_jit_if(aTHX_ b, "args");
        xs_jit_line(aTHX_ b, "XPUSHs(sv_2mortal(newRV_inc((SV*)args)));");
        xs_jit_endif(aTHX_ b);
        xs_jit_line(aTHX_ b, "PUTBACK;");
        xs_jit_line(aTHX_ b, "call_method(\"BUILD\", G_DISCARD);");
        xs_jit_line(aTHX_ b, "FREETMPS;");
        xs_jit_line(aTHX_ b, "LEAVE;");
        xs_jit_endif(aTHX_ b);
        xs_jit_blank(aTHX_ b);
    }
    
    xs_jit_line(aTHX_ b, "ST(0) = sv_2mortal(self);");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    
    xs_jit_xs_end(aTHX_ b);
}

/* ============================================
 * Callbacks & Triggers (Phase 4)
 * ============================================ */

void xs_jit_call_sv(pTHX_ XS_JIT_Builder* b, const char* cv_expr,
                     const char** args, int num_args) {
    int i;
    
    xs_jit_line(aTHX_ b, "{");
    xs_jit_indent(b);
    xs_jit_line(aTHX_ b, "dSP;");
    xs_jit_line(aTHX_ b, "ENTER;");
    xs_jit_line(aTHX_ b, "SAVETMPS;");
    xs_jit_line(aTHX_ b, "PUSHMARK(SP);");
    
    for (i = 0; i < num_args; i++) {
        xs_jit_line(aTHX_ b, "XPUSHs(%s);", args[i]);
    }
    
    xs_jit_line(aTHX_ b, "PUTBACK;");
    xs_jit_line(aTHX_ b, "call_sv(%s, G_DISCARD);", cv_expr);
    xs_jit_line(aTHX_ b, "FREETMPS;");
    xs_jit_line(aTHX_ b, "LEAVE;");
    xs_jit_dedent(b);
    xs_jit_line(aTHX_ b, "}");
}

void xs_jit_call_method(pTHX_ XS_JIT_Builder* b, const char* method_name,
                         const char* invocant, const char** args, int num_args) {
    int i;
    
    xs_jit_line(aTHX_ b, "{");
    xs_jit_indent(b);
    xs_jit_line(aTHX_ b, "dSP;");
    xs_jit_line(aTHX_ b, "ENTER;");
    xs_jit_line(aTHX_ b, "SAVETMPS;");
    xs_jit_line(aTHX_ b, "PUSHMARK(SP);");
    xs_jit_line(aTHX_ b, "XPUSHs(%s);", invocant);
    
    for (i = 0; i < num_args; i++) {
        xs_jit_line(aTHX_ b, "XPUSHs(%s);", args[i]);
    }
    
    xs_jit_line(aTHX_ b, "PUTBACK;");
    xs_jit_line(aTHX_ b, "call_method(\"%s\", G_DISCARD);", method_name);
    xs_jit_line(aTHX_ b, "FREETMPS;");
    xs_jit_line(aTHX_ b, "LEAVE;");
    xs_jit_dedent(b);
    xs_jit_line(aTHX_ b, "}");
}

void xs_jit_rw_accessor_trigger(pTHX_ XS_JIT_Builder* b, const char* func_name,
                                 const char* attr_name, STRLEN attr_len,
                                 const char* trigger_method) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Get self hash");
    xs_jit_get_self_hv(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Setter with trigger");
    xs_jit_if(aTHX_ b, "items > 1");
    xs_jit_line(aTHX_ b, "SV* new_val = newSVsv(ST(1));");
    xs_jit_line(aTHX_ b, "hv_store(hv, \"%s\", %d, new_val, 0);",
                attr_name, (int)attr_len);
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Call trigger method");
    xs_jit_line(aTHX_ b, "{");
    xs_jit_indent(b);
    xs_jit_line(aTHX_ b, "dSP;");
    xs_jit_line(aTHX_ b, "ENTER;");
    xs_jit_line(aTHX_ b, "SAVETMPS;");
    xs_jit_line(aTHX_ b, "PUSHMARK(SP);");
    xs_jit_line(aTHX_ b, "XPUSHs(self);");
    xs_jit_line(aTHX_ b, "XPUSHs(new_val);");
    xs_jit_line(aTHX_ b, "PUTBACK;");
    xs_jit_line(aTHX_ b, "call_method(\"%s\", G_DISCARD);", trigger_method);
    xs_jit_line(aTHX_ b, "FREETMPS;");
    xs_jit_line(aTHX_ b, "LEAVE;");
    xs_jit_dedent(b);
    xs_jit_line(aTHX_ b, "}");
    
    xs_jit_endif(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Getter");
    xs_jit_line(aTHX_ b, "SV** valp = hv_fetch(hv, \"%s\", %d, 0);",
                attr_name, (int)attr_len);
    xs_jit_if(aTHX_ b, "valp && SvOK(*valp)");
    xs_jit_line(aTHX_ b, "ST(0) = *valp;");
    xs_jit_else(aTHX_ b);
    xs_jit_line(aTHX_ b, "ST(0) = &PL_sv_undef;");
    xs_jit_endif(aTHX_ b);
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_accessor_lazy_builder(pTHX_ XS_JIT_Builder* b, const char* func_name,
                                   const char* attr_name, STRLEN attr_len,
                                   const char* builder_method) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Get self hash");
    xs_jit_get_self_hv(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Setter - just store value");
    xs_jit_if(aTHX_ b, "items > 1");
    xs_jit_line(aTHX_ b, "hv_store(hv, \"%s\", %d, newSVsv(ST(1)), 0);",
                attr_name, (int)attr_len);
    xs_jit_endif(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Getter with lazy builder");
    xs_jit_line(aTHX_ b, "SV** valp = hv_fetch(hv, \"%s\", %d, 0);",
                attr_name, (int)attr_len);
    
    xs_jit_if(aTHX_ b, "!valp || !SvOK(*valp)");
    xs_jit_comment(aTHX_ b, "Call builder method and cache result");
    xs_jit_line(aTHX_ b, "{");
    xs_jit_indent(b);
    xs_jit_line(aTHX_ b, "dSP;");
    xs_jit_line(aTHX_ b, "int count;");
    xs_jit_line(aTHX_ b, "ENTER;");
    xs_jit_line(aTHX_ b, "SAVETMPS;");
    xs_jit_line(aTHX_ b, "PUSHMARK(SP);");
    xs_jit_line(aTHX_ b, "XPUSHs(self);");
    xs_jit_line(aTHX_ b, "PUTBACK;");
    xs_jit_line(aTHX_ b, "count = call_method(\"%s\", G_SCALAR);", builder_method);
    xs_jit_line(aTHX_ b, "SPAGAIN;");
    xs_jit_if(aTHX_ b, "count > 0");
    xs_jit_line(aTHX_ b, "SV* built = POPs;");
    xs_jit_line(aTHX_ b, "SV* stored = newSVsv(built);");
    xs_jit_line(aTHX_ b, "hv_store(hv, \"%s\", %d, stored, 0);",
                attr_name, (int)attr_len);
    xs_jit_line(aTHX_ b, "PUTBACK;");
    xs_jit_line(aTHX_ b, "FREETMPS;");
    xs_jit_line(aTHX_ b, "LEAVE;");
    xs_jit_line(aTHX_ b, "ST(0) = stored;");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    xs_jit_else(aTHX_ b);
    xs_jit_line(aTHX_ b, "PUTBACK;");
    xs_jit_line(aTHX_ b, "FREETMPS;");
    xs_jit_line(aTHX_ b, "LEAVE;");
    xs_jit_line(aTHX_ b, "ST(0) = &PL_sv_undef;");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    xs_jit_endif(aTHX_ b);
    xs_jit_dedent(b);
    xs_jit_line(aTHX_ b, "}");
    xs_jit_endif(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Return cached value");
    xs_jit_line(aTHX_ b, "ST(0) = *valp;");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_destroy_with_demolish(pTHX_ XS_JIT_Builder* b, const char* func_name) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Get self");
    xs_jit_line(aTHX_ b, "SV* self = ST(0);");
    xs_jit_if(aTHX_ b, "!SvROK(self)");
    xs_jit_line(aTHX_ b, "XSRETURN_EMPTY;");
    xs_jit_endif(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Check if DEMOLISH exists");
    xs_jit_line(aTHX_ b, "HV* stash = SvSTASH(SvRV(self));");
    xs_jit_line(aTHX_ b, "GV* demolish_gv = gv_fetchmethod_autoload(stash, \"DEMOLISH\", 0);");
    xs_jit_blank(aTHX_ b);
    
    xs_jit_if(aTHX_ b, "demolish_gv");
    xs_jit_comment(aTHX_ b, "Call DEMOLISH");
    xs_jit_line(aTHX_ b, "{");
    xs_jit_indent(b);
    xs_jit_line(aTHX_ b, "dSP;");
    xs_jit_line(aTHX_ b, "ENTER;");
    xs_jit_line(aTHX_ b, "SAVETMPS;");
    xs_jit_line(aTHX_ b, "PUSHMARK(SP);");
    xs_jit_line(aTHX_ b, "XPUSHs(self);");
    xs_jit_line(aTHX_ b, "XPUSHs(boolSV(PL_dirty));");  /* in_global_destruction */
    xs_jit_line(aTHX_ b, "PUTBACK;");
    xs_jit_line(aTHX_ b, "call_method(\"DEMOLISH\", G_DISCARD);");
    xs_jit_line(aTHX_ b, "FREETMPS;");
    xs_jit_line(aTHX_ b, "LEAVE;");
    xs_jit_dedent(b);
    xs_jit_line(aTHX_ b, "}");
    xs_jit_endif(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "XSRETURN_EMPTY;");
    
    xs_jit_xs_end(aTHX_ b);
}

/* ============================================
 * Control Flow & Extended Patterns (Phase 5)
 * ============================================ */

void xs_jit_do(pTHX_ XS_JIT_Builder* b) {
    xs_jit_line(aTHX_ b, "do {");
    xs_jit_indent(b);
}

void xs_jit_end_do_while(pTHX_ XS_JIT_Builder* b, const char* condition) {
    xs_jit_dedent(b);
    xs_jit_line(aTHX_ b, "} while (%s);", condition);
}

void xs_jit_if_list_context(pTHX_ XS_JIT_Builder* b) {
    xs_jit_if(aTHX_ b, "GIMME_V == G_LIST");
}

void xs_jit_if_scalar_context(pTHX_ XS_JIT_Builder* b) {
    xs_jit_if(aTHX_ b, "GIMME_V == G_SCALAR");
}

void xs_jit_extend_stack(pTHX_ XS_JIT_Builder* b, const char* count_expr) {
    xs_jit_line(aTHX_ b, "EXTEND(SP, %s);", count_expr);
}

void xs_jit_return_list(pTHX_ XS_JIT_Builder* b, const char** values, int num_values) {
    int i;
    
    if (num_values > 0) {
        xs_jit_line(aTHX_ b, "EXTEND(SP, %d);", num_values);
        for (i = 0; i < num_values; i++) {
            xs_jit_line(aTHX_ b, "ST(%d) = sv_2mortal(%s);", i, values[i]);
        }
    }
    xs_jit_line(aTHX_ b, "XSRETURN(%d);", num_values);
}

void xs_jit_declare_ternary(pTHX_ XS_JIT_Builder* b, const char* type,
                             const char* name, const char* cond,
                             const char* true_expr, const char* false_expr) {
    xs_jit_line(aTHX_ b, "%s %s = (%s) ? %s : %s;",
                type, name, cond, true_expr, false_expr);
}

void xs_jit_assign_ternary(pTHX_ XS_JIT_Builder* b, const char* var,
                            const char* cond, const char* true_expr,
                            const char* false_expr) {
    xs_jit_line(aTHX_ b, "%s = (%s) ? %s : %s;",
                var, cond, true_expr, false_expr);
}

void xs_jit_delegate_method(pTHX_ XS_JIT_Builder* b, const char* func_name,
                             const char* attr_name, STRLEN attr_len,
                             const char* target_method) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Get self hash and fetch delegate");
    xs_jit_get_self_hv(aTHX_ b);
    xs_jit_line(aTHX_ b, "SV** delegate_p = hv_fetch(hv, \"%s\", %d, 0);",
                attr_name, (int)attr_len);
    xs_jit_blank(aTHX_ b);
    
    xs_jit_if(aTHX_ b, "!delegate_p || !SvOK(*delegate_p) || !SvROK(*delegate_p)");
    xs_jit_line(aTHX_ b, "croak(\"Cannot delegate: '%s' is not set or not a reference\");",
                attr_name);
    xs_jit_endif(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Call method on delegate, passing remaining args");
    xs_jit_line(aTHX_ b, "{");
    xs_jit_indent(b);
    xs_jit_line(aTHX_ b, "dSP;");
    xs_jit_line(aTHX_ b, "int i, count;");
    xs_jit_line(aTHX_ b, "SV* result = NULL;");
    xs_jit_line(aTHX_ b, "ENTER;");
    xs_jit_line(aTHX_ b, "SAVETMPS;");
    xs_jit_line(aTHX_ b, "PUSHMARK(SP);");
    xs_jit_line(aTHX_ b, "XPUSHs(*delegate_p);");
    
    xs_jit_comment(aTHX_ b, "Pass through any additional arguments");
    xs_jit_for(aTHX_ b, "i = 1", "i < items", "i++");
    xs_jit_line(aTHX_ b, "XPUSHs(ST(i));");
    xs_jit_endloop(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "PUTBACK;");
    xs_jit_line(aTHX_ b, "count = call_method(\"%s\", G_SCALAR);", target_method);
    xs_jit_line(aTHX_ b, "SPAGAIN;");
    xs_jit_blank(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Capture result before cleanup");
    xs_jit_if(aTHX_ b, "count > 0");
    xs_jit_line(aTHX_ b, "result = newSVsv(POPs);");
    xs_jit_endif(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "PUTBACK;");
    xs_jit_line(aTHX_ b, "FREETMPS;");
    xs_jit_line(aTHX_ b, "LEAVE;");
    xs_jit_blank(aTHX_ b);
    
    xs_jit_if(aTHX_ b, "result");
    xs_jit_line(aTHX_ b, "ST(0) = sv_2mortal(result);");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    xs_jit_else(aTHX_ b);
    xs_jit_line(aTHX_ b, "XSRETURN_EMPTY;");
    xs_jit_endif(aTHX_ b);
    xs_jit_dedent(b);
    xs_jit_line(aTHX_ b, "}");
    
    xs_jit_xs_end(aTHX_ b);
}

/* ============================================
 * Singleton Pattern (Phase 6)
 * ============================================ */

void xs_jit_singleton_accessor(pTHX_ XS_JIT_Builder* b, const char* func_name,
                                const char* class_name) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Get or create the singleton instance");
    xs_jit_line(aTHX_ b, "HV* stash = gv_stashpv(\"%s\", GV_ADD);", class_name);
    xs_jit_line(aTHX_ b, "GV* gv = gv_fetchpv(\"%s::_instance\", GV_ADD, SVt_PV);", class_name);
    xs_jit_line(aTHX_ b, "SV* instance = GvSV(gv);");
    xs_jit_blank(aTHX_ b);
    
    xs_jit_if(aTHX_ b, "!instance || !SvOK(instance) || !SvROK(instance)");
    xs_jit_comment(aTHX_ b, "Create new instance");
    xs_jit_line(aTHX_ b, "HV* hv = newHV();");
    xs_jit_line(aTHX_ b, "SV* self = newRV_noinc((SV*)hv);");
    xs_jit_line(aTHX_ b, "sv_bless(self, stash);");
    xs_jit_line(aTHX_ b, "SvSetSV(GvSVn(gv), self);");
    xs_jit_line(aTHX_ b, "SvREFCNT_dec(self);");  /* gv now owns it */
    xs_jit_line(aTHX_ b, "instance = GvSV(gv);");
    xs_jit_endif(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "ST(0) = instance;");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_singleton_reset(pTHX_ XS_JIT_Builder* b, const char* func_name,
                             const char* class_name) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Clear the singleton instance");
    xs_jit_line(aTHX_ b, "GV* gv = gv_fetchpv(\"%s::_instance\", GV_ADD, SVt_PV);", class_name);
    xs_jit_line(aTHX_ b, "sv_setsv(GvSVn(gv), &PL_sv_undef);");
    xs_jit_line(aTHX_ b, "XSRETURN_EMPTY;");
    
    xs_jit_xs_end(aTHX_ b);
}

/* ============================================
 * Registry Pattern (Phase 7)
 * ============================================ */

void xs_jit_registry_add(pTHX_ XS_JIT_Builder* b, const char* func_name,
                          const char* registry_attr, STRLEN registry_len) {
    PERL_UNUSED_VAR(registry_len);
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Add an item to the registry hash");
    xs_jit_line(aTHX_ b, "if (items < 3) croak(\"Usage: $self->%s($key, $value)\");", func_name);
    xs_jit_line(aTHX_ b, "SV* self = ST(0);");
    xs_jit_line(aTHX_ b, "SV* key = ST(1);");
    xs_jit_line(aTHX_ b, "SV* value = ST(2);");
    xs_jit_line(aTHX_ b, "HV* obj = (HV*)SvRV(self);");
    
    xs_jit_comment(aTHX_ b, "Get or create the registry hash");
    xs_jit_line(aTHX_ b, "SV** registry_ptr = hv_fetch(obj, \"%s\", %d, 0);", registry_attr, (int)strlen(registry_attr));
    xs_jit_line(aTHX_ b, "HV* registry;");
    xs_jit_if(aTHX_ b, "registry_ptr && SvROK(*registry_ptr) && SvTYPE(SvRV(*registry_ptr)) == SVt_PVHV");
    xs_jit_line(aTHX_ b, "registry = (HV*)SvRV(*registry_ptr);");
    xs_jit_else(aTHX_ b);
    xs_jit_comment(aTHX_ b, "Create new registry hash");
    xs_jit_line(aTHX_ b, "registry = newHV();");
    xs_jit_line(aTHX_ b, "hv_store(obj, \"%s\", %d, newRV_noinc((SV*)registry), 0);", registry_attr, (int)strlen(registry_attr));
    xs_jit_endif(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Store the value in registry");
    xs_jit_line(aTHX_ b, "STRLEN klen;");
    xs_jit_line(aTHX_ b, "const char* kstr = SvPV(key, klen);");
    xs_jit_line(aTHX_ b, "hv_store(registry, kstr, klen, newSVsv(value), 0);");
    
    xs_jit_line(aTHX_ b, "ST(0) = self;");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_registry_get(pTHX_ XS_JIT_Builder* b, const char* func_name,
                          const char* registry_attr, STRLEN registry_len) {
    PERL_UNUSED_VAR(registry_len);
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Get an item from the registry hash");
    xs_jit_line(aTHX_ b, "if (items < 2) croak(\"Usage: $self->%s($key)\");", func_name);
    xs_jit_line(aTHX_ b, "SV* self = ST(0);");
    xs_jit_line(aTHX_ b, "SV* key = ST(1);");
    xs_jit_line(aTHX_ b, "HV* obj = (HV*)SvRV(self);");
    
    xs_jit_comment(aTHX_ b, "Get the registry hash");
    xs_jit_line(aTHX_ b, "SV** registry_ptr = hv_fetch(obj, \"%s\", %d, 0);", registry_attr, (int)strlen(registry_attr));
    xs_jit_if(aTHX_ b, "!registry_ptr || !SvROK(*registry_ptr)");
    xs_jit_line(aTHX_ b, "XSRETURN_UNDEF;");
    xs_jit_endif(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "HV* registry = (HV*)SvRV(*registry_ptr);");
    xs_jit_line(aTHX_ b, "STRLEN klen;");
    xs_jit_line(aTHX_ b, "const char* kstr = SvPV(key, klen);");
    xs_jit_line(aTHX_ b, "SV** val_ptr = hv_fetch(registry, kstr, klen, 0);");
    
    xs_jit_if(aTHX_ b, "val_ptr && *val_ptr");
    xs_jit_line(aTHX_ b, "ST(0) = *val_ptr;");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    xs_jit_endif(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "XSRETURN_UNDEF;");
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_registry_remove(pTHX_ XS_JIT_Builder* b, const char* func_name,
                             const char* registry_attr, STRLEN registry_len) {
    PERL_UNUSED_VAR(registry_len);
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Remove an item from the registry hash");
    xs_jit_line(aTHX_ b, "if (items < 2) croak(\"Usage: $self->%s($key)\");", func_name);
    xs_jit_line(aTHX_ b, "SV* self = ST(0);");
    xs_jit_line(aTHX_ b, "SV* key = ST(1);");
    xs_jit_line(aTHX_ b, "HV* obj = (HV*)SvRV(self);");
    
    xs_jit_comment(aTHX_ b, "Get the registry hash");
    xs_jit_line(aTHX_ b, "SV** registry_ptr = hv_fetch(obj, \"%s\", %d, 0);", registry_attr, (int)strlen(registry_attr));
    xs_jit_if(aTHX_ b, "!registry_ptr || !SvROK(*registry_ptr)");
    xs_jit_line(aTHX_ b, "XSRETURN_UNDEF;");
    xs_jit_endif(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "HV* registry = (HV*)SvRV(*registry_ptr);");
    xs_jit_line(aTHX_ b, "STRLEN klen;");
    xs_jit_line(aTHX_ b, "const char* kstr = SvPV(key, klen);");
    
    xs_jit_comment(aTHX_ b, "Delete and return the removed value");
    xs_jit_line(aTHX_ b, "SV* deleted = hv_delete(registry, kstr, klen, 0);");
    xs_jit_if(aTHX_ b, "deleted");
    xs_jit_line(aTHX_ b, "ST(0) = deleted;");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    xs_jit_endif(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "XSRETURN_UNDEF;");
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_registry_all(pTHX_ XS_JIT_Builder* b, const char* func_name,
                          const char* registry_attr, STRLEN registry_len) {
    PERL_UNUSED_VAR(registry_len);
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Return all items from the registry");
    xs_jit_line(aTHX_ b, "SV* self = ST(0);");
    xs_jit_line(aTHX_ b, "HV* obj = (HV*)SvRV(self);");
    
    xs_jit_comment(aTHX_ b, "Get the registry hash");
    xs_jit_line(aTHX_ b, "SV** registry_ptr = hv_fetch(obj, \"%s\", %d, 0);", registry_attr, (int)strlen(registry_attr));
    xs_jit_if(aTHX_ b, "!registry_ptr || !SvROK(*registry_ptr)");
    xs_jit_comment(aTHX_ b, "Return empty list or empty hashref based on context");
    xs_jit_line(aTHX_ b, "if (GIMME_V == G_ARRAY) { XSRETURN_EMPTY; }");
    xs_jit_line(aTHX_ b, "else { ST(0) = sv_2mortal(newRV_noinc((SV*)newHV())); XSRETURN(1); }");
    xs_jit_endif(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "HV* registry = (HV*)SvRV(*registry_ptr);");
    
    xs_jit_comment(aTHX_ b, "Context-aware return");
    xs_jit_if(aTHX_ b, "GIMME_V == G_ARRAY");
    xs_jit_comment(aTHX_ b, "List context: return key-value pairs");
    xs_jit_line(aTHX_ b, "I32 count = hv_iterinit(registry);");
    xs_jit_line(aTHX_ b, "EXTEND(SP, count * 2);");
    xs_jit_line(aTHX_ b, "HE* entry;");
    xs_jit_line(aTHX_ b, "I32 i = 0;");
    xs_jit_line(aTHX_ b, "while ((entry = hv_iternext(registry))) {");
    xs_jit_line(aTHX_ b, "    ST(i++) = hv_iterkeysv(entry);");
    xs_jit_line(aTHX_ b, "    ST(i++) = hv_iterval(registry, entry);");
    xs_jit_line(aTHX_ b, "}");
    xs_jit_line(aTHX_ b, "XSRETURN(i);");
    xs_jit_else(aTHX_ b);
    xs_jit_comment(aTHX_ b, "Scalar context: return shallow copy as hashref");
    xs_jit_line(aTHX_ b, "HV* copy = newHV();");
    xs_jit_line(aTHX_ b, "hv_iterinit(registry);");
    xs_jit_line(aTHX_ b, "HE* entry;");
    xs_jit_line(aTHX_ b, "while ((entry = hv_iternext(registry))) {");
    xs_jit_line(aTHX_ b, "    SV* key = hv_iterkeysv(entry);");
    xs_jit_line(aTHX_ b, "    SV* val = hv_iterval(registry, entry);");
    xs_jit_line(aTHX_ b, "    STRLEN klen;");
    xs_jit_line(aTHX_ b, "    const char* kstr = SvPV(key, klen);");
    xs_jit_line(aTHX_ b, "    hv_store(copy, kstr, klen, newSVsv(val), 0);");
    xs_jit_line(aTHX_ b, "}");
    xs_jit_line(aTHX_ b, "ST(0) = sv_2mortal(newRV_noinc((SV*)copy));");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    xs_jit_endif(aTHX_ b);
    
    xs_jit_xs_end(aTHX_ b);
}

/* ============================================
 * Method Modifiers (Phase 8)
 * ============================================ */

void xs_jit_wrap_before(pTHX_ XS_JIT_Builder* b, const char* func_name,
                         const char* orig_name, const char* before_cv_name) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Method modifier: before");
    xs_jit_line(aTHX_ b, "I32 gimme = GIMME_V;");
    xs_jit_line(aTHX_ b, "I32 i;");
    xs_jit_line(aTHX_ b, "I32 count;");
    xs_jit_line(aTHX_ b, "AV* saved_results;");
    
    xs_jit_comment(aTHX_ b, "Get the before CV and original CV");
    xs_jit_line(aTHX_ b, "SV* before_cv = get_sv(\"%s\", 0);", before_cv_name);
    xs_jit_line(aTHX_ b, "SV* orig_cv = get_sv(\"%s\", 0);", orig_name);
    
    xs_jit_comment(aTHX_ b, "Save args for re-use");
    xs_jit_line(aTHX_ b, "AV* saved_args = newAV();");
    xs_jit_line(aTHX_ b, "sv_2mortal((SV*)saved_args);");
    xs_jit_line(aTHX_ b, "for (i = 0; i < items; i++) av_push(saved_args, newSVsv(ST(i)));");
    
    xs_jit_comment(aTHX_ b, "Call the before hook (discard return value)");
    xs_jit_line(aTHX_ b, "{");
    xs_jit_line(aTHX_ b, "    dSP;");
    xs_jit_line(aTHX_ b, "    I32 argc = av_len(saved_args) + 1;");
    xs_jit_line(aTHX_ b, "    ENTER; SAVETMPS;");
    xs_jit_line(aTHX_ b, "    PUSHMARK(SP);");
    xs_jit_line(aTHX_ b, "    EXTEND(SP, argc);");
    xs_jit_line(aTHX_ b, "    for (i = 0; i < argc; i++) PUSHs(*av_fetch(saved_args, i, 0));");
    xs_jit_line(aTHX_ b, "    PUTBACK;");
    xs_jit_line(aTHX_ b, "    call_sv(before_cv, G_DISCARD);");
    xs_jit_line(aTHX_ b, "    FREETMPS; LEAVE;");
    xs_jit_line(aTHX_ b, "}");
    
    xs_jit_comment(aTHX_ b, "Call the original and save return values");
    xs_jit_line(aTHX_ b, "saved_results = newAV();");
    xs_jit_line(aTHX_ b, "sv_2mortal((SV*)saved_results);");
    xs_jit_line(aTHX_ b, "{");
    xs_jit_line(aTHX_ b, "    dSP;");
    xs_jit_line(aTHX_ b, "    I32 argc = av_len(saved_args) + 1;");
    xs_jit_line(aTHX_ b, "    ENTER; SAVETMPS;");
    xs_jit_line(aTHX_ b, "    PUSHMARK(SP);");
    xs_jit_line(aTHX_ b, "    EXTEND(SP, argc);");
    xs_jit_line(aTHX_ b, "    for (i = 0; i < argc; i++) PUSHs(*av_fetch(saved_args, i, 0));");
    xs_jit_line(aTHX_ b, "    PUTBACK;");
    xs_jit_line(aTHX_ b, "    count = call_sv(orig_cv, gimme | G_EVAL);");
    xs_jit_line(aTHX_ b, "    SPAGAIN;");
    xs_jit_line(aTHX_ b, "    if (SvTRUE(ERRSV)) { FREETMPS; LEAVE; croak_sv(ERRSV); }");
    xs_jit_line(aTHX_ b, "    for (i = count - 1; i >= 0; i--) av_store(saved_results, i, newSVsv(POPs));");
    xs_jit_line(aTHX_ b, "    FREETMPS; LEAVE;");
    xs_jit_line(aTHX_ b, "}");
    
    xs_jit_comment(aTHX_ b, "Return the saved results");
    xs_jit_line(aTHX_ b, "count = av_len(saved_results) + 1;");
    xs_jit_line(aTHX_ b, "if (gimme == G_ARRAY) {");
    xs_jit_line(aTHX_ b, "    for (i = 0; i < count; i++) ST(i) = sv_2mortal(SvREFCNT_inc(*av_fetch(saved_results, i, 0)));");
    xs_jit_line(aTHX_ b, "    XSRETURN(count);");
    xs_jit_line(aTHX_ b, "} else if (gimme == G_SCALAR && count > 0) {");
    xs_jit_line(aTHX_ b, "    ST(0) = sv_2mortal(SvREFCNT_inc(*av_fetch(saved_results, count - 1, 0)));");
    xs_jit_line(aTHX_ b, "    XSRETURN(1);");
    xs_jit_line(aTHX_ b, "}");
    xs_jit_line(aTHX_ b, "XSRETURN(0);");
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_wrap_after(pTHX_ XS_JIT_Builder* b, const char* func_name,
                        const char* orig_name, const char* after_cv_name) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Method modifier: after");
    xs_jit_line(aTHX_ b, "I32 gimme = GIMME_V;");
    xs_jit_line(aTHX_ b, "I32 i;");
    xs_jit_line(aTHX_ b, "I32 orig_count = 0;");
    xs_jit_line(aTHX_ b, "AV* saved_results = NULL;");
    
    xs_jit_comment(aTHX_ b, "Get the original CV and after CV");
    xs_jit_line(aTHX_ b, "SV* orig_cv = get_sv(\"%s\", 0);", orig_name);
    xs_jit_line(aTHX_ b, "SV* after_cv = get_sv(\"%s\", 0);", after_cv_name);
    
    xs_jit_comment(aTHX_ b, "Save original args for after hook");
    xs_jit_line(aTHX_ b, "AV* saved_args = newAV();");
    xs_jit_line(aTHX_ b, "sv_2mortal((SV*)saved_args);");
    xs_jit_line(aTHX_ b, "for (i = 0; i < items; i++) av_push(saved_args, newSVsv(ST(i)));");
    
    xs_jit_comment(aTHX_ b, "Call the original and save return values");
    xs_jit_line(aTHX_ b, "saved_results = newAV();");
    xs_jit_line(aTHX_ b, "sv_2mortal((SV*)saved_results);");
    xs_jit_line(aTHX_ b, "{");
    xs_jit_line(aTHX_ b, "    dSP;");
    xs_jit_line(aTHX_ b, "    I32 argc = av_len(saved_args) + 1;");
    xs_jit_line(aTHX_ b, "    ENTER; SAVETMPS;");
    xs_jit_line(aTHX_ b, "    PUSHMARK(SP);");
    xs_jit_line(aTHX_ b, "    EXTEND(SP, argc);");
    xs_jit_line(aTHX_ b, "    for (i = 0; i < argc; i++) PUSHs(*av_fetch(saved_args, i, 0));");
    xs_jit_line(aTHX_ b, "    PUTBACK;");
    xs_jit_line(aTHX_ b, "    orig_count = call_sv(orig_cv, gimme | G_EVAL);");
    xs_jit_line(aTHX_ b, "    SPAGAIN;");
    xs_jit_line(aTHX_ b, "    if (SvTRUE(ERRSV)) { FREETMPS; LEAVE; croak_sv(ERRSV); }");
    xs_jit_line(aTHX_ b, "    for (i = orig_count - 1; i >= 0; i--) av_store(saved_results, i, newSVsv(POPs));");
    xs_jit_line(aTHX_ b, "    FREETMPS; LEAVE;");
    xs_jit_line(aTHX_ b, "}");
    
    xs_jit_comment(aTHX_ b, "Call the after hook (discard return value)");
    xs_jit_line(aTHX_ b, "{");
    xs_jit_line(aTHX_ b, "    dSP;");
    xs_jit_line(aTHX_ b, "    I32 argc = av_len(saved_args) + 1;");
    xs_jit_line(aTHX_ b, "    ENTER; SAVETMPS;");
    xs_jit_line(aTHX_ b, "    PUSHMARK(SP);");
    xs_jit_line(aTHX_ b, "    EXTEND(SP, argc);");
    xs_jit_line(aTHX_ b, "    for (i = 0; i < argc; i++) PUSHs(*av_fetch(saved_args, i, 0));");
    xs_jit_line(aTHX_ b, "    PUTBACK;");
    xs_jit_line(aTHX_ b, "    call_sv(after_cv, G_DISCARD);");
    xs_jit_line(aTHX_ b, "    FREETMPS; LEAVE;");
    xs_jit_line(aTHX_ b, "}");
    
    xs_jit_comment(aTHX_ b, "Return the saved results from original");
    xs_jit_line(aTHX_ b, "orig_count = av_len(saved_results) + 1;");
    xs_jit_line(aTHX_ b, "if (gimme == G_ARRAY) {");
    xs_jit_line(aTHX_ b, "    for (i = 0; i < orig_count; i++) ST(i) = sv_2mortal(SvREFCNT_inc(*av_fetch(saved_results, i, 0)));");
    xs_jit_line(aTHX_ b, "    XSRETURN(orig_count);");
    xs_jit_line(aTHX_ b, "} else if (gimme == G_SCALAR && orig_count > 0) {");
    xs_jit_line(aTHX_ b, "    ST(0) = sv_2mortal(SvREFCNT_inc(*av_fetch(saved_results, orig_count - 1, 0)));");
    xs_jit_line(aTHX_ b, "    XSRETURN(1);");
    xs_jit_line(aTHX_ b, "}");
    xs_jit_line(aTHX_ b, "XSRETURN(0);");
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_wrap_around(pTHX_ XS_JIT_Builder* b, const char* func_name,
                         const char* orig_name, const char* around_cv_name) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    
    xs_jit_comment(aTHX_ b, "Method modifier: around");
    xs_jit_line(aTHX_ b, "I32 gimme = GIMME_V;");
    xs_jit_line(aTHX_ b, "I32 i;");
    
    xs_jit_comment(aTHX_ b, "Get the around CV and original CV");
    xs_jit_line(aTHX_ b, "SV* around_cv = get_sv(\"%s\", 0);", around_cv_name);
    xs_jit_line(aTHX_ b, "SV* orig_cv = get_sv(\"%s\", 0);", orig_name);
    
    xs_jit_comment(aTHX_ b, "Save original args");
    xs_jit_line(aTHX_ b, "AV* saved_args = newAV();");
    xs_jit_line(aTHX_ b, "sv_2mortal((SV*)saved_args);");
    xs_jit_line(aTHX_ b, "for (i = 0; i < items; i++) av_push(saved_args, newSVsv(ST(i)));");
    
    xs_jit_comment(aTHX_ b, "Call around with $orig as first arg, then original args");
    xs_jit_line(aTHX_ b, "{");
    xs_jit_line(aTHX_ b, "    dSP;");
    xs_jit_line(aTHX_ b, "    I32 count;");
    xs_jit_line(aTHX_ b, "    I32 argc = av_len(saved_args) + 1;");
    xs_jit_line(aTHX_ b, "    AV* saved_results = newAV();");
    xs_jit_line(aTHX_ b, "    sv_2mortal((SV*)saved_results);");
    xs_jit_line(aTHX_ b, "    ENTER; SAVETMPS;");
    xs_jit_line(aTHX_ b, "    PUSHMARK(SP);");
    xs_jit_line(aTHX_ b, "    EXTEND(SP, argc + 1);");
    xs_jit_line(aTHX_ b, "    PUSHs(orig_cv);");
    xs_jit_line(aTHX_ b, "    for (i = 0; i < argc; i++) PUSHs(*av_fetch(saved_args, i, 0));");
    xs_jit_line(aTHX_ b, "    PUTBACK;");
    xs_jit_line(aTHX_ b, "    count = call_sv(around_cv, gimme | G_EVAL);");
    xs_jit_line(aTHX_ b, "    SPAGAIN;");
    xs_jit_line(aTHX_ b, "    if (SvTRUE(ERRSV)) { FREETMPS; LEAVE; croak_sv(ERRSV); }");
    xs_jit_line(aTHX_ b, "    for (i = count - 1; i >= 0; i--) av_store(saved_results, i, newSVsv(POPs));");
    xs_jit_line(aTHX_ b, "    FREETMPS; LEAVE;");
    xs_jit_line(aTHX_ b, "    count = av_len(saved_results) + 1;");
    xs_jit_line(aTHX_ b, "    if (gimme == G_ARRAY) {");
    xs_jit_line(aTHX_ b, "        for (i = 0; i < count; i++) ST(i) = sv_2mortal(SvREFCNT_inc(*av_fetch(saved_results, i, 0)));");
    xs_jit_line(aTHX_ b, "        XSRETURN(count);");
    xs_jit_line(aTHX_ b, "    } else if (gimme == G_SCALAR && count > 0) {");
    xs_jit_line(aTHX_ b, "        ST(0) = sv_2mortal(SvREFCNT_inc(*av_fetch(saved_results, count - 1, 0)));");
    xs_jit_line(aTHX_ b, "        XSRETURN(1);");
    xs_jit_line(aTHX_ b, "    }");
    xs_jit_line(aTHX_ b, "    XSRETURN(0);");
    xs_jit_line(aTHX_ b, "}");
    
    xs_jit_xs_end(aTHX_ b);
}

/* ============================================
 * Op-based accessors (array-based objects with inline ops)
 * ============================================ */

void xs_jit_op_ro_accessor(pTHX_ XS_JIT_Builder* b, const char* func_name, IV slot) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    
    xs_jit_if(aTHX_ b, "items > 1");
    xs_jit_croak(aTHX_ b, "Read only attributes cannot be set");
    xs_jit_endif(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "SV** ary = AvARRAY((AV*)SvRV(ST(0)));");
    xs_jit_line(aTHX_ b, "ST(0) = ary[%ld] ? ary[%ld] : &PL_sv_undef;", (long)slot, (long)slot);
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_op_rw_accessor(pTHX_ XS_JIT_Builder* b, const char* func_name, IV slot) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "AV* av = (AV*)SvRV(ST(0));");
    
    xs_jit_if(aTHX_ b, "items > 1");
    xs_jit_line(aTHX_ b, "SV* new_val = newSVsv(ST(1));");
    xs_jit_line(aTHX_ b, "av_store(av, %ld, new_val);", (long)slot);
    xs_jit_line(aTHX_ b, "ST(0) = new_val;");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    xs_jit_endif(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "SV** ary = AvARRAY(av);");
    xs_jit_line(aTHX_ b, "ST(0) = ary[%ld] ? ary[%ld] : &PL_sv_undef;", (long)slot, (long)slot);
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    
    xs_jit_xs_end(aTHX_ b);
}

/* ============================================
 * Custom op builder (pp functions)
 * ============================================ */

void xs_jit_pp_start(pTHX_ XS_JIT_Builder* b, const char* name) {
    xs_jit_line(aTHX_ b, "static OP* S_pp_%s(pTHX) {", name);
    b->indent++;
}

void xs_jit_pp_end(pTHX_ XS_JIT_Builder* b) {
    b->indent--;
    xs_jit_line(aTHX_ b, "}");
    xs_jit_blank(aTHX_ b);
}

void xs_jit_pp_dsp(pTHX_ XS_JIT_Builder* b) {
    xs_jit_line(aTHX_ b, "dSP;");
}

void xs_jit_pp_get_self(pTHX_ XS_JIT_Builder* b) {
    xs_jit_line(aTHX_ b, "SV* self = TOPs;");
}

void xs_jit_pp_pop_self(pTHX_ XS_JIT_Builder* b) {
    xs_jit_line(aTHX_ b, "SV* self = POPs;");
}

void xs_jit_pp_pop_sv(pTHX_ XS_JIT_Builder* b, const char* name) {
    xs_jit_line(aTHX_ b, "SV* %s = POPs;", name);
}

void xs_jit_pp_pop_nv(pTHX_ XS_JIT_Builder* b, const char* name) {
    xs_jit_line(aTHX_ b, "NV %s = POPn;", name);
}

void xs_jit_pp_pop_iv(pTHX_ XS_JIT_Builder* b, const char* name) {
    xs_jit_line(aTHX_ b, "IV %s = POPi;", name);
}

void xs_jit_pp_get_slots(pTHX_ XS_JIT_Builder* b) {
    xs_jit_line(aTHX_ b, "SV** ary = AvARRAY((AV*)SvRV(self));");
}

void xs_jit_pp_slot(pTHX_ XS_JIT_Builder* b, const char* name, IV slot) {
    xs_jit_line(aTHX_ b, "SV* %s = ary[%ld] ? ary[%ld] : &PL_sv_undef;", name, (long)slot, (long)slot);
}

void xs_jit_pp_return_sv(pTHX_ XS_JIT_Builder* b, const char* sv_expr) {
    xs_jit_line(aTHX_ b, "SETs(%s);", sv_expr);
    xs_jit_line(aTHX_ b, "return NORMAL;");
}

void xs_jit_pp_return_nv(pTHX_ XS_JIT_Builder* b, const char* nv_expr) {
    xs_jit_line(aTHX_ b, "SETs(sv_2mortal(newSVnv(%s)));", nv_expr);
    xs_jit_line(aTHX_ b, "return NORMAL;");
}

void xs_jit_pp_return_iv(pTHX_ XS_JIT_Builder* b, const char* iv_expr) {
    xs_jit_line(aTHX_ b, "SETs(sv_2mortal(newSViv(%s)));", iv_expr);
    xs_jit_line(aTHX_ b, "return NORMAL;");
}

void xs_jit_pp_return_pv(pTHX_ XS_JIT_Builder* b, const char* pv_expr) {
    xs_jit_line(aTHX_ b, "SETs(sv_2mortal(newSVpv(%s, 0)));", pv_expr);
    xs_jit_line(aTHX_ b, "return NORMAL;");
}

void xs_jit_pp_return(pTHX_ XS_JIT_Builder* b) {
    xs_jit_line(aTHX_ b, "return NORMAL;");
}

/* ============================================
 * Call checker builder
 * ============================================ */

void xs_jit_ck_start(pTHX_ XS_JIT_Builder* b, const char* name) {
    xs_jit_line(aTHX_ b, "static OP* S_ck_%s(pTHX_ OP* entersubop, GV* namegv, SV* ckobj) {", name);
    b->indent++;
    xs_jit_line(aTHX_ b, "PERL_UNUSED_ARG(namegv);");
}

void xs_jit_ck_end(pTHX_ XS_JIT_Builder* b) {
    b->indent--;
    xs_jit_line(aTHX_ b, "}");
    xs_jit_blank(aTHX_ b);
}

void xs_jit_ck_preamble(pTHX_ XS_JIT_Builder* b) {
    xs_jit_line(aTHX_ b, "OP* parent = entersubop;");
    xs_jit_line(aTHX_ b, "OP* pushmark = cUNOPx(entersubop)->op_first;");
    xs_jit_blank(aTHX_ b);
    xs_jit_line(aTHX_ b, "if (!OpHAS_SIBLING(pushmark)) {");
    b->indent++;
    xs_jit_line(aTHX_ b, "parent = pushmark;");
    xs_jit_line(aTHX_ b, "pushmark = cUNOPx(pushmark)->op_first;");
    b->indent--;
    xs_jit_line(aTHX_ b, "}");
    xs_jit_blank(aTHX_ b);
    xs_jit_line(aTHX_ b, "OP* selfop = OpSIBLING(pushmark);");
    xs_jit_line(aTHX_ b, "if (!selfop || selfop->op_type == OP_RV2CV || selfop->op_type == OP_NULL) {");
    b->indent++;
    xs_jit_line(aTHX_ b, "return entersubop;");
    b->indent--;
    xs_jit_line(aTHX_ b, "}");
    xs_jit_blank(aTHX_ b);
}

void xs_jit_ck_build_unop(pTHX_ XS_JIT_Builder* b, const char* pp_func, const char* targ_expr) {
    xs_jit_line(aTHX_ b, "op_sibling_splice(parent, pushmark, 1, NULL);");
    xs_jit_line(aTHX_ b, "op_free(entersubop);");
    xs_jit_blank(aTHX_ b);
    xs_jit_line(aTHX_ b, "UNOP* newop;");
    xs_jit_line(aTHX_ b, "NewOp(1234, newop, 1, UNOP);");
    xs_jit_line(aTHX_ b, "newop->op_type = OP_CUSTOM;");
    xs_jit_line(aTHX_ b, "newop->op_ppaddr = %s;", pp_func);
    xs_jit_line(aTHX_ b, "newop->op_flags = OPf_KIDS | OPf_WANT_SCALAR;");
    xs_jit_line(aTHX_ b, "newop->op_private = 0;");
    xs_jit_line(aTHX_ b, "newop->op_targ = (PADOFFSET)(%s);", targ_expr);
    xs_jit_blank(aTHX_ b);
    xs_jit_line(aTHX_ b, "op_sibling_splice((OP*)newop, NULL, 0, selfop);");
    xs_jit_blank(aTHX_ b);
    xs_jit_line(aTHX_ b, "return (OP*)newop;");
}

void xs_jit_ck_build_binop(pTHX_ XS_JIT_Builder* b, const char* pp_func, const char* targ_expr) {
    xs_jit_line(aTHX_ b, "OP* valop = OpSIBLING(selfop);");
    xs_jit_line(aTHX_ b, "if (!valop || valop->op_type == OP_RV2CV || valop->op_type == OP_NULL) {");
    b->indent++;
    xs_jit_line(aTHX_ b, "return entersubop;");
    b->indent--;
    xs_jit_line(aTHX_ b, "}");
    xs_jit_blank(aTHX_ b);
    xs_jit_line(aTHX_ b, "op_sibling_splice(parent, pushmark, 2, NULL);");
    xs_jit_line(aTHX_ b, "op_free(entersubop);");
    xs_jit_blank(aTHX_ b);
    xs_jit_line(aTHX_ b, "BINOP* newop;");
    xs_jit_line(aTHX_ b, "NewOp(1234, newop, 1, BINOP);");
    xs_jit_line(aTHX_ b, "newop->op_type = OP_CUSTOM;");
    xs_jit_line(aTHX_ b, "newop->op_ppaddr = %s;", pp_func);
    xs_jit_line(aTHX_ b, "newop->op_flags = OPf_KIDS | OPf_STACKED | OPf_WANT_SCALAR;");
    xs_jit_line(aTHX_ b, "newop->op_private = 1;");
    xs_jit_line(aTHX_ b, "newop->op_targ = (PADOFFSET)(%s);", targ_expr);
    xs_jit_blank(aTHX_ b);
    xs_jit_line(aTHX_ b, "OpMORESIB_set(selfop, valop);");
    xs_jit_line(aTHX_ b, "OpLASTSIB_set(valop, (OP*)newop);");
    xs_jit_line(aTHX_ b, "newop->op_first = selfop;");
    xs_jit_line(aTHX_ b, "newop->op_last = valop;");
    xs_jit_blank(aTHX_ b);
    xs_jit_line(aTHX_ b, "return (OP*)newop;");
}

void xs_jit_ck_fallback(pTHX_ XS_JIT_Builder* b) {
    xs_jit_line(aTHX_ b, "return entersubop;");
}

/* ============================================
 * XOP registration helpers
 * ============================================ */

void xs_jit_xop_declare(pTHX_ XS_JIT_Builder* b, const char* name, const char* pp_func, const char* desc) {
    xs_jit_line(aTHX_ b, "static XOP xop_%s;", name);
    xs_jit_blank(aTHX_ b);
    xs_jit_line(aTHX_ b, "static void register_xop_%s(pTHX) {", name);
    b->indent++;
    xs_jit_line(aTHX_ b, "static int registered = 0;");
    xs_jit_line(aTHX_ b, "if (registered) return;");
    xs_jit_blank(aTHX_ b);
    xs_jit_line(aTHX_ b, "XopENTRY_set(&xop_%s, xop_name, \"%s\");", name, name);
    xs_jit_line(aTHX_ b, "XopENTRY_set(&xop_%s, xop_desc, \"%s\");", name, desc);
    xs_jit_line(aTHX_ b, "XopENTRY_set(&xop_%s, xop_class, OA_UNOP);", name);
    xs_jit_line(aTHX_ b, "Perl_custom_op_register(aTHX_ %s, &xop_%s);", pp_func, name);
    xs_jit_blank(aTHX_ b);
    xs_jit_line(aTHX_ b, "registered = 1;");
    b->indent--;
    xs_jit_line(aTHX_ b, "}");
    xs_jit_blank(aTHX_ b);
}

void xs_jit_register_checker(pTHX_ XS_JIT_Builder* b, const char* cv_expr, const char* ck_func, const char* ckobj_expr) {
    xs_jit_line(aTHX_ b, "cv_set_call_checker_flags(%s, %s, %s, 0);", cv_expr, ck_func, ckobj_expr);
}

/* ============================================
 * Inline op support
 * ============================================ */

/* For cv_set_call_checker - need Perl 5.14+ */
#ifndef cv_set_call_checker_flags
#define cv_set_call_checker_flags(cv, ckfun, ckobj, ckflags) \
    cv_set_call_checker(cv, ckfun, ckobj)
#endif

/* XOP descriptors for custom ops */
static XOP xs_jit_xop_getter;
static XOP xs_jit_xop_setter;
static int xs_jit_xops_registered = 0;

/* Forward declarations */
static OP* S_pp_xs_jit_get(pTHX);
static OP* S_pp_xs_jit_set(pTHX);
static OP* S_ck_xs_jit_get(pTHX_ OP* entersubop, GV* namegv, SV* ckobj);
static OP* S_ck_xs_jit_set(pTHX_ OP* entersubop, GV* namegv, SV* ckobj);

/* Initialize inline op subsystem */
void xs_jit_inline_init(pTHX) {
    if (xs_jit_xops_registered) return;
    
    /* Initialize getter XOP */
    XopENTRY_set(&xs_jit_xop_getter, xop_name, "xs_jit_get");
    XopENTRY_set(&xs_jit_xop_getter, xop_desc, "XS::JIT inline getter");
    XopENTRY_set(&xs_jit_xop_getter, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ S_pp_xs_jit_get, &xs_jit_xop_getter);
    
    /* Initialize setter XOP */
    XopENTRY_set(&xs_jit_xop_setter, xop_name, "xs_jit_set");
    XopENTRY_set(&xs_jit_xop_setter, xop_desc, "XS::JIT inline setter");
    XopENTRY_set(&xs_jit_xop_setter, xop_class, OA_BINOP);
    Perl_custom_op_register(aTHX_ S_pp_xs_jit_set, &xs_jit_xop_setter);
    
    xs_jit_xops_registered = 1;
}

/*
 * pp_xs_jit_get - Ultra-fast getter custom op
 * 
 * Stack: self -> [result]
 * Slot index stored in op_targ
 */
static OP* S_pp_xs_jit_get(pTHX) {
    dSP;
    SV* self = TOPs;
    PADOFFSET slot_index = PL_op->op_targ;
    
    SV** ary = AvARRAY((AV*)SvRV(self));
    SETs(ary[slot_index] ? ary[slot_index] : &PL_sv_undef);
    
    return NORMAL;
}

/*
 * pp_xs_jit_set - Ultra-fast setter custom op
 *
 * Stack: self, [value] -> [result]
 * Slot index stored in op_targ
 */
static OP* S_pp_xs_jit_set(pTHX) {
    dSP;
    PADOFFSET slot_index = PL_op->op_targ;
    
    /* Check if we have a value argument (setter mode) */
    if (PL_op->op_private & 1) {
        /* Setter: self, value on stack */
        SV* value = POPs;
        SV* self = TOPs;
        AV* av = (AV*)SvRV(self);
        
        SvREFCNT_inc(value);
        av_store(av, slot_index, value);
        SETs(value);
    } else {
        /* Getter: just self on stack */
        SV* self = TOPs;
        SV** ary = AvARRAY((AV*)SvRV(self));
        SETs(ary[slot_index] ? ary[slot_index] : &PL_sv_undef);
    }
    
    return NORMAL;
}

/*
 * S_ck_xs_jit_get - Call checker for read-only accessors
 */
static OP* S_ck_xs_jit_get(pTHX_ OP* entersubop, GV* namegv, SV* ckobj) {
    OP* parent;
    OP* pushmark;
    OP* selfop;
    UNOP* newop;
    
    PERL_UNUSED_ARG(namegv);
    
    IV slot_index = SvIV(ckobj);
    
    parent = entersubop;
    pushmark = cUNOPx(entersubop)->op_first;
    
    if (!OpHAS_SIBLING(pushmark)) {
        parent = pushmark;
        pushmark = cUNOPx(pushmark)->op_first;
    }
    
    selfop = OpSIBLING(pushmark);
    
    if (!selfop || selfop->op_type == OP_RV2CV || selfop->op_type == OP_NULL) {
        return entersubop;
    }
    
    /* Check for extra arguments (setter call on ro) */
    OP* nextop = OpSIBLING(selfop);
    if (nextop && nextop->op_type != OP_RV2CV && nextop->op_type != OP_NULL) {
        return entersubop;
    }
    
    /* Detach selfop */
    op_sibling_splice(parent, pushmark, 1, NULL);
    op_free(entersubop);
    
    /* Create custom UNOP */
    NewOp(1234, newop, 1, UNOP);
    newop->op_type = OP_CUSTOM;
    newop->op_ppaddr = S_pp_xs_jit_get;
    newop->op_flags = OPf_KIDS | OPf_WANT_SCALAR;
    newop->op_private = 0;
    newop->op_targ = (PADOFFSET)slot_index;
    
    op_sibling_splice((OP*)newop, NULL, 0, selfop);
    
    return (OP*)newop;
}

/*
 * S_ck_xs_jit_set - Call checker for read-write accessors
 */
static OP* S_ck_xs_jit_set(pTHX_ OP* entersubop, GV* namegv, SV* ckobj) {
    OP* parent;
    OP* pushmark;
    OP* selfop;
    OP* valop;
    
    PERL_UNUSED_ARG(namegv);
    
    IV slot_index = SvIV(ckobj);
    
    parent = entersubop;
    pushmark = cUNOPx(entersubop)->op_first;
    
    if (!OpHAS_SIBLING(pushmark)) {
        parent = pushmark;
        pushmark = cUNOPx(pushmark)->op_first;
    }
    
    selfop = OpSIBLING(pushmark);
    if (!selfop || selfop->op_type == OP_RV2CV || selfop->op_type == OP_NULL) {
        return entersubop;
    }
    
    valop = OpSIBLING(selfop);
    
    /* Determine getter vs setter */
    int is_setter = 0;
    if (valop && valop->op_type != OP_RV2CV && valop->op_type != OP_NULL) {
        OP* afterval = OpSIBLING(valop);
        if (!afterval || afterval->op_type == OP_RV2CV || afterval->op_type == OP_NULL) {
            is_setter = 1;
        } else {
            return entersubop;
        }
    }
    
    if (is_setter) {
        BINOP* newop;
        
        op_sibling_splice(parent, pushmark, 2, NULL);
        op_free(entersubop);
        
        NewOp(1234, newop, 1, BINOP);
        newop->op_type = OP_CUSTOM;
        newop->op_ppaddr = S_pp_xs_jit_set;
        newop->op_flags = OPf_KIDS | OPf_STACKED | OPf_WANT_SCALAR;
        newop->op_private = 1;  /* Flag: is setter */
        newop->op_targ = (PADOFFSET)slot_index;
        
        OpMORESIB_set(selfop, valop);
        OpLASTSIB_set(valop, (OP*)newop);
        newop->op_first = selfop;
        newop->op_last = valop;
        
        return (OP*)newop;
    } else {
        UNOP* newop;
        
        op_sibling_splice(parent, pushmark, 1, NULL);
        op_free(entersubop);
        
        NewOp(1234, newop, 1, UNOP);
        newop->op_type = OP_CUSTOM;
        newop->op_ppaddr = S_pp_xs_jit_set;
        newop->op_flags = OPf_KIDS | OPf_WANT_SCALAR;
        newop->op_private = 0;  /* Flag: is getter */
        newop->op_targ = (PADOFFSET)slot_index;
        
        op_sibling_splice((OP*)newop, NULL, 0, selfop);
        
        return (OP*)newop;
    }
}

/* Register inline op for a CV */
int xs_jit_inline_register(pTHX_ CV* cv, XS_JIT_InlineType type, 
                           IV slot, const char* key, STRLEN key_len) {
    PERL_UNUSED_ARG(key);
    PERL_UNUSED_ARG(key_len);
    
    if (!cv) return 0;
    
    xs_jit_inline_init(aTHX);
    
    SV* ckobj = newSViv(slot);
    
    switch (type) {
        case XS_JIT_INLINE_GETTER:
            cv_set_call_checker_flags(cv, S_ck_xs_jit_get, ckobj, 0);
            break;
        case XS_JIT_INLINE_SETTER:
            cv_set_call_checker_flags(cv, S_ck_xs_jit_set, ckobj, 0);
            break;
        case XS_JIT_INLINE_HV_GETTER:
        case XS_JIT_INLINE_HV_SETTER:
            /* TODO: Implement hash-based inline ops */
            SvREFCNT_dec(ckobj);
            return 0;
        default:
            SvREFCNT_dec(ckobj);
            return 0;
    }
    
    return 1;
}

/* Check if CV has inline op */
XS_JIT_InlineType xs_jit_inline_get_type(pTHX_ CV* cv) {
    MAGIC* mg;
    
    if (!cv) return XS_JIT_INLINE_NONE;
    
    mg = mg_find((SV*)cv, PERL_MAGIC_checkcall);
    if (!mg) return XS_JIT_INLINE_NONE;
    
    /* Check which checker function is registered */
    if (mg->mg_ptr == (char*)S_ck_xs_jit_get) {
        return XS_JIT_INLINE_GETTER;
    } else if (mg->mg_ptr == (char*)S_ck_xs_jit_set) {
        return XS_JIT_INLINE_SETTER;
    }
    
    return XS_JIT_INLINE_NONE;
}

/* ============================================
 * Direct AvARRAY access (Meow-style fast slots)
 * ============================================ */

void xs_jit_av_direct(pTHX_ XS_JIT_Builder* b, const char* result_var, const char* av_expr) {
    xs_jit_line(aTHX_ b, "SV** %s = AvARRAY(%s);", result_var, av_expr);
}

void xs_jit_av_slot_read(pTHX_ XS_JIT_Builder* b, const char* result_var, 
                          const char* slots_var, IV slot) {
    xs_jit_line(aTHX_ b, "SV* %s = %s[%ld] ? %s[%ld] : &PL_sv_undef;", 
                result_var, slots_var, (long)slot, slots_var, (long)slot);
}

void xs_jit_av_slot_write(pTHX_ XS_JIT_Builder* b, const char* slots_var, 
                           IV slot, const char* value) {
    xs_jit_line(aTHX_ b, "SvREFCNT_dec(%s[%ld]);", slots_var, (long)slot);
    xs_jit_line(aTHX_ b, "%s[%ld] = SvREFCNT_inc(%s);", slots_var, (long)slot, value);
}

/* ============================================
 * Type checking helpers
 * ============================================ */

/* Static buffer for type check expressions (non-reentrant but sufficient for code gen) */
static char xs_jit_type_check_buf[256];

const char* xs_jit_type_check_expr(pTHX_ XS_JIT_TypeCheck type, 
                                    const char* sv, const char* classname) {
    PERL_UNUSED_ARG(my_perl);
    switch (type) {
        case XS_JIT_TYPE_ANY:
            return "1";
        case XS_JIT_TYPE_DEFINED:
            snprintf(xs_jit_type_check_buf, sizeof(xs_jit_type_check_buf),
                     "SvOK(%s)", sv);
            break;
        case XS_JIT_TYPE_INT:
            snprintf(xs_jit_type_check_buf, sizeof(xs_jit_type_check_buf),
                     "SvIOK(%s)", sv);
            break;
        case XS_JIT_TYPE_NUM:
            snprintf(xs_jit_type_check_buf, sizeof(xs_jit_type_check_buf),
                     "(SvNOK(%s) || SvIOK(%s))", sv, sv);
            break;
        case XS_JIT_TYPE_STR:
            snprintf(xs_jit_type_check_buf, sizeof(xs_jit_type_check_buf),
                     "SvPOK(%s)", sv);
            break;
        case XS_JIT_TYPE_REF:
            snprintf(xs_jit_type_check_buf, sizeof(xs_jit_type_check_buf),
                     "SvROK(%s)", sv);
            break;
        case XS_JIT_TYPE_ARRAYREF:
            snprintf(xs_jit_type_check_buf, sizeof(xs_jit_type_check_buf),
                     "(SvROK(%s) && SvTYPE(SvRV(%s)) == SVt_PVAV)", sv, sv);
            break;
        case XS_JIT_TYPE_HASHREF:
            snprintf(xs_jit_type_check_buf, sizeof(xs_jit_type_check_buf),
                     "(SvROK(%s) && SvTYPE(SvRV(%s)) == SVt_PVHV)", sv, sv);
            break;
        case XS_JIT_TYPE_CODEREF:
            snprintf(xs_jit_type_check_buf, sizeof(xs_jit_type_check_buf),
                     "(SvROK(%s) && SvTYPE(SvRV(%s)) == SVt_PVCV)", sv, sv);
            break;
        case XS_JIT_TYPE_OBJECT:
            snprintf(xs_jit_type_check_buf, sizeof(xs_jit_type_check_buf),
                     "sv_isobject(%s)", sv);
            break;
        case XS_JIT_TYPE_BLESSED:
            if (classname && *classname) {
                snprintf(xs_jit_type_check_buf, sizeof(xs_jit_type_check_buf),
                         "sv_derived_from(%s, \"%s\")", sv, classname);
            } else {
                snprintf(xs_jit_type_check_buf, sizeof(xs_jit_type_check_buf),
                         "sv_isobject(%s)", sv);
            }
            break;
        default:
            return "1";
    }
    return xs_jit_type_check_buf;
}

void xs_jit_check_value_type(pTHX_ XS_JIT_Builder* b, const char* sv, 
                              XS_JIT_TypeCheck type, const char* classname,
                              const char* error_msg) {
    const char* check = xs_jit_type_check_expr(aTHX_ type, sv, classname);
    char cond[280];
    snprintf(cond, sizeof(cond), "!(%s)", check);
    xs_jit_if(aTHX_ b, cond);
    xs_jit_croak(aTHX_ b, error_msg);
    xs_jit_endif(aTHX_ b);
}

/* ============================================
 * Lazy initialization accessors
 * ============================================ */

void xs_jit_lazy_init_dor(pTHX_ XS_JIT_Builder* b, const char* func_name,
                          const char* attr_name, STRLEN attr_len,
                          const char* default_expr, int is_mortal) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_line(aTHX_ b, "dXSARGS;");
    xs_jit_line(aTHX_ b, "PERL_UNUSED_VAR(cv); PERL_UNUSED_VAR(items);");
    
    xs_jit_line(aTHX_ b, "HV* hv = (HV*)SvRV(ST(0));");
    xs_jit_line(aTHX_ b, "SV** valp = hv_fetch(hv, \"%s\", %lu, 0);",
                attr_name, (unsigned long)attr_len);
    xs_jit_line(aTHX_ b, "SV* val = (valp && *valp) ? *valp : NULL;");
    
    xs_jit_if(aTHX_ b, "!val || !SvOK(val)");
    if (is_mortal) {
        xs_jit_line(aTHX_ b, "val = sv_2mortal(%s);", default_expr);
    } else {
        xs_jit_line(aTHX_ b, "val = %s;", default_expr);
    }
    xs_jit_line(aTHX_ b, "hv_store(hv, \"%s\", %lu, SvREFCNT_inc(val), 0);",
                attr_name, (unsigned long)attr_len);
    xs_jit_endif(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "ST(0) = val;");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_lazy_init_or(pTHX_ XS_JIT_Builder* b, const char* func_name,
                         const char* attr_name, STRLEN attr_len,
                         const char* default_expr, int is_mortal) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_line(aTHX_ b, "dXSARGS;");
    xs_jit_line(aTHX_ b, "PERL_UNUSED_VAR(cv); PERL_UNUSED_VAR(items);");
    
    xs_jit_line(aTHX_ b, "HV* hv = (HV*)SvRV(ST(0));");
    xs_jit_line(aTHX_ b, "SV** valp = hv_fetch(hv, \"%s\", %lu, 0);",
                attr_name, (unsigned long)attr_len);
    xs_jit_line(aTHX_ b, "SV* val = (valp && *valp) ? *valp : NULL;");
    
    xs_jit_if(aTHX_ b, "!val || !SvTRUE(val)");
    if (is_mortal) {
        xs_jit_line(aTHX_ b, "val = sv_2mortal(%s);", default_expr);
    } else {
        xs_jit_line(aTHX_ b, "val = %s;", default_expr);
    }
    xs_jit_line(aTHX_ b, "hv_store(hv, \"%s\", %lu, SvREFCNT_inc(val), 0);",
                attr_name, (unsigned long)attr_len);
    xs_jit_endif(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "ST(0) = val;");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_slot_lazy_init_dor(pTHX_ XS_JIT_Builder* b, const char* func_name,
                               IV slot, const char* default_expr, int is_mortal) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_line(aTHX_ b, "dXSARGS;");
    xs_jit_line(aTHX_ b, "PERL_UNUSED_VAR(cv); PERL_UNUSED_VAR(items);");
    
    xs_jit_line(aTHX_ b, "AV* av = (AV*)SvRV(ST(0));");
    xs_jit_line(aTHX_ b, "SV** ary = AvARRAY(av);");
    xs_jit_line(aTHX_ b, "SV* val = ary[%ld];", (long)slot);
    
    xs_jit_if(aTHX_ b, "!val || !SvOK(val)");
    if (is_mortal) {
        xs_jit_line(aTHX_ b, "val = sv_2mortal(%s);", default_expr);
    } else {
        xs_jit_line(aTHX_ b, "val = %s;", default_expr);
    }
    xs_jit_line(aTHX_ b, "ary[%ld] = SvREFCNT_inc(val);", (long)slot);
    xs_jit_endif(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "ST(0) = val;");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_slot_lazy_init_or(pTHX_ XS_JIT_Builder* b, const char* func_name,
                              IV slot, const char* default_expr, int is_mortal) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_line(aTHX_ b, "dXSARGS;");
    xs_jit_line(aTHX_ b, "PERL_UNUSED_VAR(cv); PERL_UNUSED_VAR(items);");
    
    xs_jit_line(aTHX_ b, "AV* av = (AV*)SvRV(ST(0));");
    xs_jit_line(aTHX_ b, "SV** ary = AvARRAY(av);");
    xs_jit_line(aTHX_ b, "SV* val = ary[%ld];", (long)slot);
    
    xs_jit_if(aTHX_ b, "!val || !SvTRUE(val)");
    if (is_mortal) {
        xs_jit_line(aTHX_ b, "val = sv_2mortal(%s);", default_expr);
    } else {
        xs_jit_line(aTHX_ b, "val = %s;", default_expr);
    }
    xs_jit_line(aTHX_ b, "ary[%ld] = SvREFCNT_inc(val);", (long)slot);
    xs_jit_endif(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "ST(0) = val;");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    
    xs_jit_xs_end(aTHX_ b);
}

/* ============================================
 * Setter chain patterns
 * ============================================ */

void xs_jit_setter_chain(pTHX_ XS_JIT_Builder* b, const char* func_name,
                         const char* attr_name, STRLEN attr_len) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_line(aTHX_ b, "dXSARGS;");
    xs_jit_line(aTHX_ b, "PERL_UNUSED_VAR(cv);");
    
    xs_jit_if(aTHX_ b, "items < 2");
    xs_jit_croak(aTHX_ b, "Usage: $self->%s($value)");
    xs_jit_endif(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "SV* self = ST(0);");
    xs_jit_line(aTHX_ b, "HV* hv = (HV*)SvRV(self);");
    xs_jit_line(aTHX_ b, "SV* val = newSVsv(ST(1));");
    xs_jit_line(aTHX_ b, "hv_store(hv, \"%s\", %lu, val, 0);",
                attr_name, (unsigned long)attr_len);
    xs_jit_line(aTHX_ b, "ST(0) = self;");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_slot_setter_chain(pTHX_ XS_JIT_Builder* b, const char* func_name, IV slot) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_line(aTHX_ b, "dXSARGS;");
    xs_jit_line(aTHX_ b, "PERL_UNUSED_VAR(cv);");
    
    xs_jit_if(aTHX_ b, "items < 2");
    xs_jit_croak(aTHX_ b, "Usage: $self->setter($value)");
    xs_jit_endif(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "SV* self = ST(0);");
    xs_jit_line(aTHX_ b, "AV* av = (AV*)SvRV(self);");
    xs_jit_line(aTHX_ b, "SV* val = newSVsv(ST(1));");
    xs_jit_line(aTHX_ b, "av_store(av, %ld, val);", (long)slot);
    xs_jit_line(aTHX_ b, "ST(0) = self;");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_setter_return_value(pTHX_ XS_JIT_Builder* b, const char* func_name,
                                 const char* attr_name, STRLEN attr_len) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_line(aTHX_ b, "dXSARGS;");
    xs_jit_line(aTHX_ b, "PERL_UNUSED_VAR(cv);");
    
    xs_jit_if(aTHX_ b, "items < 2");
    xs_jit_croak(aTHX_ b, "Usage: $self->%s($value)");
    xs_jit_endif(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "HV* hv = (HV*)SvRV(ST(0));");
    xs_jit_line(aTHX_ b, "SV* val = newSVsv(ST(1));");
    xs_jit_line(aTHX_ b, "hv_store(hv, \"%s\", %lu, val, 0);",
                attr_name, (unsigned long)attr_len);
    xs_jit_line(aTHX_ b, "ST(0) = val;");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    
    xs_jit_xs_end(aTHX_ b);
}

/* ============================================
 * Array attribute operations
 * ============================================ */

void xs_jit_attr_push(pTHX_ XS_JIT_Builder* b, const char* func_name,
                      const char* attr_name, STRLEN attr_len) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_get_self_hv(aTHX_ b);
    
    xs_jit_hv_fetch(aTHX_ b, "hv", attr_name, attr_len, "aref");
    xs_jit_if(aTHX_ b, "!aref || !SvROK(*aref) || SvTYPE(SvRV(*aref)) != SVt_PVAV");
    xs_jit_croak(aTHX_ b, "Attribute is not an arrayref");
    xs_jit_endif(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "AV* av = (AV*)SvRV(*aref);");
    xs_jit_line(aTHX_ b, "I32 i;");
    xs_jit_line(aTHX_ b, "for (i = 1; i < items; i++) {");
    b->indent++;
    xs_jit_line(aTHX_ b, "av_push(av, newSVsv(ST(i)));");
    b->indent--;
    xs_jit_line(aTHX_ b, "}");
    
    xs_jit_return_iv(aTHX_ b, "av_len(av) + 1");
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_attr_pop(pTHX_ XS_JIT_Builder* b, const char* func_name,
                     const char* attr_name, STRLEN attr_len) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_get_self_hv(aTHX_ b);
    
    xs_jit_hv_fetch(aTHX_ b, "hv", attr_name, attr_len, "aref");
    xs_jit_if(aTHX_ b, "!aref || !SvROK(*aref) || SvTYPE(SvRV(*aref)) != SVt_PVAV");
    xs_jit_croak(aTHX_ b, "Attribute is not an arrayref");
    xs_jit_endif(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "AV* av = (AV*)SvRV(*aref);");
    xs_jit_line(aTHX_ b, "SV* val = av_pop(av);");
    xs_jit_line(aTHX_ b, "ST(0) = val ? sv_2mortal(val) : &PL_sv_undef;");
    xs_jit_xs_return(aTHX_ b, 1);
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_attr_shift(pTHX_ XS_JIT_Builder* b, const char* func_name,
                       const char* attr_name, STRLEN attr_len) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_get_self_hv(aTHX_ b);
    
    xs_jit_hv_fetch(aTHX_ b, "hv", attr_name, attr_len, "aref");
    xs_jit_if(aTHX_ b, "!aref || !SvROK(*aref) || SvTYPE(SvRV(*aref)) != SVt_PVAV");
    xs_jit_croak(aTHX_ b, "Attribute is not an arrayref");
    xs_jit_endif(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "AV* av = (AV*)SvRV(*aref);");
    xs_jit_line(aTHX_ b, "SV* val = av_shift(av);");
    xs_jit_line(aTHX_ b, "ST(0) = val ? sv_2mortal(val) : &PL_sv_undef;");
    xs_jit_xs_return(aTHX_ b, 1);
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_attr_unshift(pTHX_ XS_JIT_Builder* b, const char* func_name,
                         const char* attr_name, STRLEN attr_len) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_get_self_hv(aTHX_ b);
    
    xs_jit_hv_fetch(aTHX_ b, "hv", attr_name, attr_len, "aref");
    xs_jit_if(aTHX_ b, "!aref || !SvROK(*aref) || SvTYPE(SvRV(*aref)) != SVt_PVAV");
    xs_jit_croak(aTHX_ b, "Attribute is not an arrayref");
    xs_jit_endif(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "AV* av = (AV*)SvRV(*aref);");
    xs_jit_line(aTHX_ b, "I32 i;");
    xs_jit_line(aTHX_ b, "av_unshift(av, items - 1);");
    xs_jit_line(aTHX_ b, "for (i = 1; i < items; i++) {");
    b->indent++;
    xs_jit_line(aTHX_ b, "av_store(av, i - 1, newSVsv(ST(i)));");
    b->indent--;
    xs_jit_line(aTHX_ b, "}");
    
    xs_jit_return_iv(aTHX_ b, "av_len(av) + 1");
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_attr_count(pTHX_ XS_JIT_Builder* b, const char* func_name,
                       const char* attr_name, STRLEN attr_len) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_get_self_hv(aTHX_ b);
    
    xs_jit_hv_fetch(aTHX_ b, "hv", attr_name, attr_len, "aref");
    xs_jit_if(aTHX_ b, "!aref || !SvROK(*aref) || SvTYPE(SvRV(*aref)) != SVt_PVAV");
    xs_jit_return_iv(aTHX_ b, "0");
    xs_jit_endif(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "AV* av = (AV*)SvRV(*aref);");
    xs_jit_return_iv(aTHX_ b, "av_len(av) + 1");
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_attr_clear(pTHX_ XS_JIT_Builder* b, const char* func_name,
                       const char* attr_name, STRLEN attr_len) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_get_self_hv(aTHX_ b);
    
    xs_jit_hv_fetch(aTHX_ b, "hv", attr_name, attr_len, "aref");
    xs_jit_if(aTHX_ b, "aref && SvROK(*aref) && SvTYPE(SvRV(*aref)) == SVt_PVAV");
    xs_jit_line(aTHX_ b, "av_clear((AV*)SvRV(*aref));");
    xs_jit_endif(aTHX_ b);
    
    xs_jit_return_self(aTHX_ b);
    xs_jit_xs_end(aTHX_ b);
}

/* ============================================
 * Hash attribute operations
 * ============================================ */

void xs_jit_attr_keys(pTHX_ XS_JIT_Builder* b, const char* func_name,
                      const char* attr_name, STRLEN attr_len) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_get_self_hv(aTHX_ b);
    
    xs_jit_hv_fetch(aTHX_ b, "hv", attr_name, attr_len, "href");
    xs_jit_if(aTHX_ b, "!href || !SvROK(*href) || SvTYPE(SvRV(*href)) != SVt_PVHV");
    xs_jit_xs_return(aTHX_ b, 0);
    xs_jit_endif(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "HV* ahv = (HV*)SvRV(*href);");
    xs_jit_line(aTHX_ b, "I32 count = 0;");
    xs_jit_line(aTHX_ b, "hv_iterinit(ahv);");
    xs_jit_line(aTHX_ b, "HE* entry;");
    xs_jit_line(aTHX_ b, "while ((entry = hv_iternext(ahv))) {");
    b->indent++;
    xs_jit_line(aTHX_ b, "XST_mPV(count, HePV(entry, PL_na));");
    xs_jit_line(aTHX_ b, "count++;");
    b->indent--;
    xs_jit_line(aTHX_ b, "}");
    xs_jit_line(aTHX_ b, "XSRETURN(count);");
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_attr_values(pTHX_ XS_JIT_Builder* b, const char* func_name,
                        const char* attr_name, STRLEN attr_len) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_get_self_hv(aTHX_ b);
    
    xs_jit_hv_fetch(aTHX_ b, "hv", attr_name, attr_len, "href");
    xs_jit_if(aTHX_ b, "!href || !SvROK(*href) || SvTYPE(SvRV(*href)) != SVt_PVHV");
    xs_jit_xs_return(aTHX_ b, 0);
    xs_jit_endif(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "HV* ahv = (HV*)SvRV(*href);");
    xs_jit_line(aTHX_ b, "I32 count = 0;");
    xs_jit_line(aTHX_ b, "hv_iterinit(ahv);");
    xs_jit_line(aTHX_ b, "HE* entry;");
    xs_jit_line(aTHX_ b, "while ((entry = hv_iternext(ahv))) {");
    b->indent++;
    xs_jit_line(aTHX_ b, "ST(count) = HeVAL(entry);");
    xs_jit_line(aTHX_ b, "count++;");
    b->indent--;
    xs_jit_line(aTHX_ b, "}");
    xs_jit_line(aTHX_ b, "XSRETURN(count);");
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_attr_delete(pTHX_ XS_JIT_Builder* b, const char* func_name,
                        const char* attr_name, STRLEN attr_len) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    
    xs_jit_check_items(aTHX_ b, 2, 2, "$self->delete($key)");
    xs_jit_get_self_hv(aTHX_ b);
    
    xs_jit_hv_fetch(aTHX_ b, "hv", attr_name, attr_len, "href");
    xs_jit_if(aTHX_ b, "!href || !SvROK(*href) || SvTYPE(SvRV(*href)) != SVt_PVHV");
    xs_jit_xs_return_undef(aTHX_ b);
    xs_jit_endif(aTHX_ b);
    
    xs_jit_line(aTHX_ b, "HV* ahv = (HV*)SvRV(*href);");
    xs_jit_line(aTHX_ b, "STRLEN klen;");
    xs_jit_line(aTHX_ b, "const char* key = SvPV(ST(1), klen);");
    xs_jit_line(aTHX_ b, "SV* deleted = hv_delete(ahv, key, klen, 0);");
    xs_jit_line(aTHX_ b, "ST(0) = deleted ? deleted : &PL_sv_undef;");
    xs_jit_xs_return(aTHX_ b, 1);
    
    xs_jit_xs_end(aTHX_ b);
}

void xs_jit_attr_hash_clear(pTHX_ XS_JIT_Builder* b, const char* func_name,
                            const char* attr_name, STRLEN attr_len) {
    xs_jit_xs_function(aTHX_ b, func_name);
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_get_self_hv(aTHX_ b);

    xs_jit_hv_fetch(aTHX_ b, "hv", attr_name, attr_len, "href");
    xs_jit_if(aTHX_ b, "href && SvROK(*href) && SvTYPE(SvRV(*href)) == SVt_PVHV");
    xs_jit_line(aTHX_ b, "hv_clear((HV*)SvRV(*href));");
    xs_jit_endif(aTHX_ b);

    xs_jit_return_self(aTHX_ b);
    xs_jit_xs_end(aTHX_ b);
}

/* ============================================
 * Conditional DSL (Struct::Conditional format)
 * ============================================ */

/* Build C condition string from a clause */
static SV* xs_jit_build_condition(pTHX_ XS_JIT_Clause* clause) {
    SV* cond = newSVpvs("");
    const char* key = clause->key;
    const char* val = clause->expr_value;

    switch (clause->expr_type) {
        case XS_JIT_EXPR_NONE:
            sv_catpvs(cond, "1");  /* always true */
            break;
        case XS_JIT_EXPR_GT:
            sv_catpvf(cond, "SvIV(%s) > %s", key, val);
            break;
        case XS_JIT_EXPR_LT:
            sv_catpvf(cond, "SvIV(%s) < %s", key, val);
            break;
        case XS_JIT_EXPR_GTE:
            sv_catpvf(cond, "SvIV(%s) >= %s", key, val);
            break;
        case XS_JIT_EXPR_LTE:
            sv_catpvf(cond, "SvIV(%s) <= %s", key, val);
            break;
        case XS_JIT_EXPR_EQ:
            sv_catpvf(cond, "strEQ(SvPV_nolen(%s), \"%s\")", key, val);
            break;
        case XS_JIT_EXPR_NE:
            sv_catpvf(cond, "!strEQ(SvPV_nolen(%s), \"%s\")", key, val);
            break;
        case XS_JIT_EXPR_M:
            /* For simple substring match, use strstr */
            sv_catpvf(cond, "strstr(SvPV_nolen(%s), \"%s\") != NULL", key, val);
            break;
        case XS_JIT_EXPR_IM:
            /* Case-insensitive: use strcasestr if available, or manual loop */
            sv_catpvf(cond, "strcasestr(SvPV_nolen(%s), \"%s\") != NULL", key, val);
            break;
        case XS_JIT_EXPR_NM:
            sv_catpvf(cond, "strstr(SvPV_nolen(%s), \"%s\") == NULL", key, val);
            break;
        case XS_JIT_EXPR_INM:
            sv_catpvf(cond, "strcasestr(SvPV_nolen(%s), \"%s\") == NULL", key, val);
            break;
        case XS_JIT_EXPR_EXISTS:
            sv_catpvf(cond, "SvOK(%s)", key);
            break;
        case XS_JIT_EXPR_TRUE:
            sv_catpvf(cond, "SvTRUE(%s)", key);
            break;
    }

    /* Handle AND chaining */
    if (clause->and_clause) {
        SV* and_cond = xs_jit_build_condition(aTHX_ clause->and_clause);
        sv_catpvf(cond, " && (%s)", SvPV_nolen(and_cond));
        SvREFCNT_dec(and_cond);
    }

    /* Handle OR chaining */
    if (clause->or_clause) {
        SV* or_cond = xs_jit_build_condition(aTHX_ clause->or_clause);
        sv_catpvf(cond, " || (%s)", SvPV_nolen(or_cond));
        SvREFCNT_dec(or_cond);
    }

    return cond;
}

/* Emit actions for a then block */
static void xs_jit_emit_actions(pTHX_ XS_JIT_Builder* b,
                                 XS_JIT_Action* actions, int num) {
    int i;
    for (i = 0; i < num; i++) {
        switch (actions[i].type) {
            case XS_JIT_ACTION_LINE:
                xs_jit_line(aTHX_ b, "%s", actions[i].value);
                break;
            case XS_JIT_ACTION_RETURN_IV:
                xs_jit_line(aTHX_ b, "XSRETURN_IV(%s);", actions[i].value);
                break;
            case XS_JIT_ACTION_RETURN_NV:
                xs_jit_line(aTHX_ b, "ST(0) = sv_2mortal(newSVnv(%s)); XSRETURN(1);", actions[i].value);
                break;
            case XS_JIT_ACTION_RETURN_PV:
                xs_jit_line(aTHX_ b, "XSRETURN_PV(%s);", actions[i].value);
                break;
            case XS_JIT_ACTION_RETURN_SV:
                xs_jit_return_sv(aTHX_ b, actions[i].value);
                break;
            case XS_JIT_ACTION_CROAK:
                xs_jit_croak(aTHX_ b, actions[i].value);
                break;
        }
    }
}

/* Main conditional generator */
void xs_jit_conditional(pTHX_ XS_JIT_Builder* b, XS_JIT_Conditional* cond) {
    int i;

    if (!cond || !cond->if_clause) {
        return;
    }

    /* Generate if clause */
    SV* if_cond = xs_jit_build_condition(aTHX_ cond->if_clause);
    xs_jit_if(aTHX_ b, SvPV_nolen(if_cond));
    SvREFCNT_dec(if_cond);

    xs_jit_emit_actions(aTHX_ b, cond->if_clause->actions,
                       cond->if_clause->num_actions);

    /* Generate elsif clauses */
    for (i = 0; i < cond->num_elsif; i++) {
        SV* elsif_cond = xs_jit_build_condition(aTHX_ cond->elsif_clauses[i]);
        xs_jit_elsif(aTHX_ b, SvPV_nolen(elsif_cond));
        SvREFCNT_dec(elsif_cond);

        xs_jit_emit_actions(aTHX_ b, cond->elsif_clauses[i]->actions,
                           cond->elsif_clauses[i]->num_actions);
    }

    /* Generate else clause */
    if (cond->num_else_actions > 0) {
        xs_jit_else(aTHX_ b);
        xs_jit_emit_actions(aTHX_ b, cond->else_actions,
                           cond->num_else_actions);
    }

    xs_jit_endif(aTHX_ b);
}

/* Given/when generator (generates if-elsif chain) */
void xs_jit_given(pTHX_ XS_JIT_Builder* b, XS_JIT_Given* given) {
    int i;

    if (!given || given->num_when == 0) {
        /* No when clauses, just emit default if present */
        if (given && given->num_default_actions > 0) {
            xs_jit_emit_actions(aTHX_ b, given->default_actions,
                               given->num_default_actions);
        }
        return;
    }

    for (i = 0; i < given->num_when; i++) {
        XS_JIT_Clause* when = given->when_clauses[i];

        /* Inherit key from given if not set on when clause */
        if (!when->key && given->key) {
            when->key = given->key;
        }

        SV* cond = xs_jit_build_condition(aTHX_ when);

        if (i == 0) {
            xs_jit_if(aTHX_ b, SvPV_nolen(cond));
        } else {
            xs_jit_elsif(aTHX_ b, SvPV_nolen(cond));
        }
        SvREFCNT_dec(cond);

        xs_jit_emit_actions(aTHX_ b, when->actions, when->num_actions);
    }

    /* Default clause becomes else */
    if (given->num_default_actions > 0) {
        xs_jit_else(aTHX_ b);
        xs_jit_emit_actions(aTHX_ b, given->default_actions,
                           given->num_default_actions);
    }

    xs_jit_endif(aTHX_ b);
}

/* ============================================
 * Conditional DSL parsing helpers
 * ============================================ */

/* Parse actions from 'then' value - can be hashref or arrayref */
XS_JIT_Action* xs_jit_parse_actions(pTHX_ SV* then_sv, int* num_actions) {
    XS_JIT_Action* actions = NULL;
    int count = 0;

    if (!then_sv || !SvOK(then_sv)) {
        *num_actions = 0;
        return NULL;
    }

    if (SvROK(then_sv) && SvTYPE(SvRV(then_sv)) == SVt_PVHV) {
        /* Single action hashref: { line => '...' } or { return_iv => 42 } */
        HV* then_hv = (HV*)SvRV(then_sv);
        SV** val;

        /* Allocate for single action */
        Newxz(actions, 1, XS_JIT_Action);
        count = 1;

        if ((val = hv_fetchs(then_hv, "line", 0)) && SvOK(*val)) {
            actions[0].type = XS_JIT_ACTION_LINE;
            actions[0].value = SvPV(*val, actions[0].value_len);
        }
        else if ((val = hv_fetchs(then_hv, "return_iv", 0)) && SvOK(*val)) {
            actions[0].type = XS_JIT_ACTION_RETURN_IV;
            actions[0].value = SvPV(*val, actions[0].value_len);
        }
        else if ((val = hv_fetchs(then_hv, "return_nv", 0)) && SvOK(*val)) {
            actions[0].type = XS_JIT_ACTION_RETURN_NV;
            actions[0].value = SvPV(*val, actions[0].value_len);
        }
        else if ((val = hv_fetchs(then_hv, "return_pv", 0)) && SvOK(*val)) {
            actions[0].type = XS_JIT_ACTION_RETURN_PV;
            actions[0].value = SvPV(*val, actions[0].value_len);
        }
        else if ((val = hv_fetchs(then_hv, "return_sv", 0)) && SvOK(*val)) {
            actions[0].type = XS_JIT_ACTION_RETURN_SV;
            actions[0].value = SvPV(*val, actions[0].value_len);
        }
        else if ((val = hv_fetchs(then_hv, "croak", 0)) && SvOK(*val)) {
            actions[0].type = XS_JIT_ACTION_CROAK;
            actions[0].value = SvPV(*val, actions[0].value_len);
        }
        else {
            /* No recognized action, free and return NULL */
            Safefree(actions);
            actions = NULL;
            count = 0;
        }
    }
    else if (SvROK(then_sv) && SvTYPE(SvRV(then_sv)) == SVt_PVAV) {
        /* Array of actions: [ { line => '...' }, { line => '...' } ] */
        AV* then_av = (AV*)SvRV(then_sv);
        I32 len = av_len(then_av) + 1;
        int i;

        if (len > 0) {
            Newxz(actions, len, XS_JIT_Action);

            for (i = 0; i < len; i++) {
                SV** elem = av_fetch(then_av, i, 0);
                if (elem && SvOK(*elem)) {
                    int sub_count;
                    XS_JIT_Action* sub_actions = xs_jit_parse_actions(aTHX_ *elem, &sub_count);
                    if (sub_actions && sub_count > 0) {
                        actions[count] = sub_actions[0];
                        count++;
                        Safefree(sub_actions);
                    }
                }
            }
        }
    }

    *num_actions = count;
    return actions;
}

/* Parse a clause hashref into XS_JIT_Clause */
XS_JIT_Clause* xs_jit_parse_clause(pTHX_ HV* clause_hv) {
    XS_JIT_Clause* clause;
    SV** val;

    if (!clause_hv) {
        return NULL;
    }

    Newxz(clause, 1, XS_JIT_Clause);

    /* Get key (C variable name) */
    if ((val = hv_fetchs(clause_hv, "key", 0)) && SvOK(*val)) {
        clause->key = SvPV_nolen(*val);
    }

    /* Determine expression type and value */
    clause->expr_type = XS_JIT_EXPR_NONE;

    if ((val = hv_fetchs(clause_hv, "gt", 0)) && SvOK(*val)) {
        clause->expr_type = XS_JIT_EXPR_GT;
        clause->expr_value = SvPV(*val, clause->expr_value_len);
    }
    else if ((val = hv_fetchs(clause_hv, "lt", 0)) && SvOK(*val)) {
        clause->expr_type = XS_JIT_EXPR_LT;
        clause->expr_value = SvPV(*val, clause->expr_value_len);
    }
    else if ((val = hv_fetchs(clause_hv, "gte", 0)) && SvOK(*val)) {
        clause->expr_type = XS_JIT_EXPR_GTE;
        clause->expr_value = SvPV(*val, clause->expr_value_len);
    }
    else if ((val = hv_fetchs(clause_hv, "lte", 0)) && SvOK(*val)) {
        clause->expr_type = XS_JIT_EXPR_LTE;
        clause->expr_value = SvPV(*val, clause->expr_value_len);
    }
    else if ((val = hv_fetchs(clause_hv, "eq", 0)) && SvOK(*val)) {
        clause->expr_type = XS_JIT_EXPR_EQ;
        clause->expr_value = SvPV(*val, clause->expr_value_len);
    }
    else if ((val = hv_fetchs(clause_hv, "ne", 0)) && SvOK(*val)) {
        clause->expr_type = XS_JIT_EXPR_NE;
        clause->expr_value = SvPV(*val, clause->expr_value_len);
    }
    else if ((val = hv_fetchs(clause_hv, "m", 0)) && SvOK(*val)) {
        clause->expr_type = XS_JIT_EXPR_M;
        clause->expr_value = SvPV(*val, clause->expr_value_len);
    }
    else if ((val = hv_fetchs(clause_hv, "im", 0)) && SvOK(*val)) {
        clause->expr_type = XS_JIT_EXPR_IM;
        clause->expr_value = SvPV(*val, clause->expr_value_len);
    }
    else if ((val = hv_fetchs(clause_hv, "nm", 0)) && SvOK(*val)) {
        clause->expr_type = XS_JIT_EXPR_NM;
        clause->expr_value = SvPV(*val, clause->expr_value_len);
    }
    else if ((val = hv_fetchs(clause_hv, "inm", 0)) && SvOK(*val)) {
        clause->expr_type = XS_JIT_EXPR_INM;
        clause->expr_value = SvPV(*val, clause->expr_value_len);
    }
    else if ((val = hv_fetchs(clause_hv, "exists", 0)) && SvOK(*val)) {
        clause->expr_type = XS_JIT_EXPR_EXISTS;
    }
    else if ((val = hv_fetchs(clause_hv, "true", 0)) && SvOK(*val)) {
        clause->expr_type = XS_JIT_EXPR_TRUE;
    }

    /* Parse 'then' actions */
    if ((val = hv_fetchs(clause_hv, "then", 0)) && SvOK(*val)) {
        clause->actions = xs_jit_parse_actions(aTHX_ *val, &clause->num_actions);
    }

    /* Parse chained 'and' clause */
    if ((val = hv_fetchs(clause_hv, "and", 0)) && SvOK(*val) && SvROK(*val)) {
        clause->and_clause = xs_jit_parse_clause(aTHX_ (HV*)SvRV(*val));
    }

    /* Parse chained 'or' clause */
    if ((val = hv_fetchs(clause_hv, "or", 0)) && SvOK(*val) && SvROK(*val)) {
        clause->or_clause = xs_jit_parse_clause(aTHX_ (HV*)SvRV(*val));
    }

    return clause;
}

/* Free functions */
void xs_jit_free_actions(pTHX_ XS_JIT_Action* actions, int num_actions) {
    PERL_UNUSED_ARG(num_actions);
    if (actions) {
        Safefree(actions);
    }
}

void xs_jit_free_clause(pTHX_ XS_JIT_Clause* clause) {
    if (!clause) return;

    xs_jit_free_actions(aTHX_ clause->actions, clause->num_actions);

    if (clause->and_clause) {
        xs_jit_free_clause(aTHX_ clause->and_clause);
    }
    if (clause->or_clause) {
        xs_jit_free_clause(aTHX_ clause->or_clause);
    }

    Safefree(clause);
}

void xs_jit_free_conditional(pTHX_ XS_JIT_Conditional* cond) {
    int i;

    if (!cond) return;

    if (cond->if_clause) {
        xs_jit_free_clause(aTHX_ cond->if_clause);
    }

    for (i = 0; i < cond->num_elsif; i++) {
        xs_jit_free_clause(aTHX_ cond->elsif_clauses[i]);
    }
    if (cond->elsif_clauses) {
        Safefree(cond->elsif_clauses);
    }

    xs_jit_free_actions(aTHX_ cond->else_actions, cond->num_else_actions);
}

void xs_jit_free_given(pTHX_ XS_JIT_Given* given) {
    int i;

    if (!given) return;

    for (i = 0; i < given->num_when; i++) {
        xs_jit_free_clause(aTHX_ given->when_clauses[i]);
    }
    if (given->when_clauses) {
        Safefree(given->when_clauses);
    }

    xs_jit_free_actions(aTHX_ given->default_actions, given->num_default_actions);
}

/* ============================================
 * Switch Statement (Optimized multi-branch)
 * ============================================ */

/* Detect if all cases use same operator type for optimization.
 * Returns: 1 = all string ops, 2 = all numeric ops, 0 = mixed */
static int xs_jit_switch_detect_type(XS_JIT_Switch* sw) {
    int string_ops = 0, numeric_ops = 0, other_ops = 0;
    int i;

    for (i = 0; i < sw->num_cases; i++) {
        XS_JIT_Clause* c = sw->cases[i];
        /* Skip clauses with AND/OR chaining - can't optimize those */
        if (c->and_clause || c->or_clause) {
            other_ops++;
            continue;
        }
        switch (c->expr_type) {
            case XS_JIT_EXPR_EQ:
            case XS_JIT_EXPR_NE:
                string_ops++;
                break;
            case XS_JIT_EXPR_M:
            case XS_JIT_EXPR_IM:
            case XS_JIT_EXPR_NM:
            case XS_JIT_EXPR_INM:
                /* Pattern matching - string but different optimization */
                other_ops++;
                break;
            case XS_JIT_EXPR_GT:
            case XS_JIT_EXPR_LT:
            case XS_JIT_EXPR_GTE:
            case XS_JIT_EXPR_LTE:
                numeric_ops++;
                break;
            default:
                other_ops++;
        }
    }

    if (string_ops > 0 && numeric_ops == 0 && other_ops == 0)
        return 1;  /* all string eq/ne */
    if (numeric_ops > 0 && string_ops == 0 && other_ops == 0)
        return 2;  /* all numeric comparisons */
    return 0;      /* mixed - no optimization */
}

/* Build optimized condition for string equality using cached pv/len */
static SV* xs_jit_build_string_eq_opt(pTHX_ const char* pv_var,
                                       const char* len_var,
                                       const char* value, STRLEN vlen,
                                       int negated) {
    SV* cond = newSVpvs("");
    if (negated) {
        sv_catpvf(cond, "!(%s == %lu && memEQ(%s, \"%s\", %lu))",
                  len_var, (unsigned long)vlen, pv_var, value, (unsigned long)vlen);
    } else {
        sv_catpvf(cond, "%s == %lu && memEQ(%s, \"%s\", %lu)",
                  len_var, (unsigned long)vlen, pv_var, value, (unsigned long)vlen);
    }
    return cond;
}

/* Build optimized condition for numeric comparison using cached iv */
static SV* xs_jit_build_numeric_opt(pTHX_ const char* iv_var,
                                     XS_JIT_ExprType expr_type,
                                     const char* value) {
    SV* cond = newSVpvs("");
    switch (expr_type) {
        case XS_JIT_EXPR_GT:
            sv_catpvf(cond, "%s > %s", iv_var, value);
            break;
        case XS_JIT_EXPR_LT:
            sv_catpvf(cond, "%s < %s", iv_var, value);
            break;
        case XS_JIT_EXPR_GTE:
            sv_catpvf(cond, "%s >= %s", iv_var, value);
            break;
        case XS_JIT_EXPR_LTE:
            sv_catpvf(cond, "%s <= %s", iv_var, value);
            break;
        default:
            sv_catpvf(cond, "%s == %s", iv_var, value);
    }
    return cond;
}

void xs_jit_switch(pTHX_ XS_JIT_Builder* b, XS_JIT_Switch* sw) {
    int i;
    int opt_type;
    const char* key;

    if (!sw) return;

    /* Handle empty cases - just emit default */
    if (sw->num_cases == 0) {
        if (sw->num_default_actions > 0) {
            xs_jit_emit_actions(aTHX_ b, sw->default_actions,
                               sw->num_default_actions);
        }
        return;
    }

    key = sw->key;
    opt_type = xs_jit_switch_detect_type(sw);

    /* Open block for cache variables */
    xs_jit_line(aTHX_ b, "{");
    xs_jit_indent(b);

    if (opt_type == 1) {
        /* String optimization: cache SvPV once */
        xs_jit_line(aTHX_ b, "STRLEN _sw_len;");
        xs_jit_line(aTHX_ b, "const char* _sw_pv = SvPV(%s, _sw_len);", key);
    } else if (opt_type == 2) {
        /* Numeric optimization: cache SvIV once */
        xs_jit_line(aTHX_ b, "IV _sw_iv = SvIV(%s);", key);
    }

    for (i = 0; i < sw->num_cases; i++) {
        XS_JIT_Clause* c = sw->cases[i];
        SV* cond;

        if (opt_type == 1 && (c->expr_type == XS_JIT_EXPR_EQ ||
                              c->expr_type == XS_JIT_EXPR_NE)) {
            /* Optimized string equality/inequality */
            int negated = (c->expr_type == XS_JIT_EXPR_NE);
            cond = xs_jit_build_string_eq_opt(aTHX_ "_sw_pv", "_sw_len",
                                              c->expr_value, c->expr_value_len,
                                              negated);
        } else if (opt_type == 2) {
            /* Optimized numeric - use cached _sw_iv */
            cond = xs_jit_build_numeric_opt(aTHX_ "_sw_iv",
                                            c->expr_type, c->expr_value);
        } else {
            /* No optimization - use standard condition builder */
            if (!c->key) c->key = key;
            cond = xs_jit_build_condition(aTHX_ c);
        }

        if (i == 0) {
            xs_jit_if(aTHX_ b, SvPV_nolen(cond));
        } else {
            xs_jit_elsif(aTHX_ b, SvPV_nolen(cond));
        }
        SvREFCNT_dec(cond);

        xs_jit_emit_actions(aTHX_ b, c->actions, c->num_actions);
    }

    /* Default becomes else */
    if (sw->num_default_actions > 0) {
        xs_jit_else(aTHX_ b);
        xs_jit_emit_actions(aTHX_ b, sw->default_actions,
                           sw->num_default_actions);
    }

    xs_jit_endif(aTHX_ b);

    /* Close block */
    xs_jit_dedent(b);
    xs_jit_line(aTHX_ b, "}");
}

void xs_jit_free_switch(pTHX_ XS_JIT_Switch* sw) {
    int i;

    if (!sw) return;

    for (i = 0; i < sw->num_cases; i++) {
        xs_jit_free_clause(aTHX_ sw->cases[i]);
    }
    if (sw->cases) {
        Safefree(sw->cases);
    }

    xs_jit_free_actions(aTHX_ sw->default_actions, sw->num_default_actions);
}

/* ============================================
 * Enum Generation
 * ============================================ */

void xs_jit_enum(pTHX_ XS_JIT_Builder* b, const char* name,
                 XS_JIT_EnumValue* values, int num_values,
                 XS_JIT_EnumOpts* opts) {
    int i;
    IV start = 0;
    const char* prefix = NULL;
    SV* prefix_sv = NULL;
    SV* lc_name_sv = NULL;
    const char* lc_name;
    IV max_val;
    char func_buf[256];
    char const_buf[256];

    if (!b || !name || !values || num_values <= 0) return;

    /* Process options */
    if (opts) {
        start = opts->start;
        if (opts->prefix) {
            prefix = opts->prefix;
        }
    }

    /* Generate lowercase name */
    lc_name_sv = newSVpv(name, 0);
    sv_catpvn(lc_name_sv, "", 0); /* Ensure null terminator */
    {
        char* p = SvPVX(lc_name_sv);
        STRLEN len = SvCUR(lc_name_sv);
        STRLEN j;
        for (j = 0; j < len; j++) {
            p[j] = toLOWER(p[j]);
        }
    }
    lc_name = SvPV_nolen(lc_name_sv);

    /* Generate default prefix if not provided: UC(name) + "_" */
    if (!prefix) {
        prefix_sv = newSVpv(name, 0);
        {
            char* p = SvPVX(prefix_sv);
            STRLEN len = SvCUR(prefix_sv);
            STRLEN j;
            for (j = 0; j < len; j++) {
                p[j] = toUPPER(p[j]);
            }
        }
        sv_catpvn(prefix_sv, "_", 1);
        prefix = SvPV_nolen(prefix_sv);
    }

    max_val = start + num_values - 1;

    /* Generate constant functions for each value */
    for (i = 0; i < num_values; i++) {
        IV val = start + i;
        SV* uc_val_sv = newSVpv(values[i].name, values[i].name_len);
        const char* uc_val;
        char val_str[32];
        {
            char* p = SvPVX(uc_val_sv);
            STRLEN len = SvCUR(uc_val_sv);
            STRLEN j;
            for (j = 0; j < len; j++) {
                p[j] = toUPPER(p[j]);
            }
        }
        uc_val = SvPV_nolen(uc_val_sv);

        /* Function name: <lc_name>_const_<value> */
        snprintf(func_buf, sizeof(func_buf), "%s_const_%s", lc_name, values[i].name);
        /* Constant name for comment: <PREFIX><UC_VALUE> */
        snprintf(const_buf, sizeof(const_buf), "%s%s", prefix, uc_val);
        /* Value as string */
        snprintf(val_str, sizeof(val_str), "%ld", (long)val);

        xs_jit_xs_function(aTHX_ b, func_buf);
        xs_jit_xs_preamble(aTHX_ b);
        xs_jit_comment(aTHX_ b, const_buf);
        xs_jit_line(aTHX_ b, "PERL_UNUSED_VAR(items);");
        xs_jit_return_iv(aTHX_ b, val_str);
        xs_jit_xs_end(aTHX_ b);
        xs_jit_blank(aTHX_ b);

        SvREFCNT_dec(uc_val_sv);
    }

    /* Generate is_valid_<name> function */
    snprintf(func_buf, sizeof(func_buf), "is_valid_%s", lc_name);
    xs_jit_xs_function(aTHX_ b, func_buf);
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_check_items(aTHX_ b, 1, 1, "val");
    xs_jit_declare_iv(aTHX_ b, "val", "SvIV(ST(0))");
    {
        char cond_buf[128];
        snprintf(cond_buf, sizeof(cond_buf), "val >= %ld && val <= %ld",
                 (long)start, (long)max_val);
        xs_jit_if(aTHX_ b, cond_buf);
    }
    xs_jit_return_yes(aTHX_ b);
    xs_jit_else(aTHX_ b);
    xs_jit_return_no(aTHX_ b);
    xs_jit_endif(aTHX_ b);
    xs_jit_xs_end(aTHX_ b);
    xs_jit_blank(aTHX_ b);

    /* Generate <name>_name function using switch */
    snprintf(func_buf, sizeof(func_buf), "%s_name", lc_name);
    xs_jit_xs_function(aTHX_ b, func_buf);
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_check_items(aTHX_ b, 1, 1, "val");
    xs_jit_declare_iv(aTHX_ b, "val", "SvIV(ST(0))");
    xs_jit_line(aTHX_ b, "{");
    xs_jit_indent(b);
    for (i = 0; i < num_values; i++) {
        IV val = start + i;
        char case_cond[64];
        snprintf(case_cond, sizeof(case_cond), "val == %ld", (long)val);
        if (i == 0) {
            xs_jit_if(aTHX_ b, case_cond);
        } else {
            xs_jit_elsif(aTHX_ b, case_cond);
        }
        xs_jit_line(aTHX_ b, "ST(0) = sv_2mortal(newSVpvn(\"%s\", %lu));",
                    values[i].name, (unsigned long)values[i].name_len);
        xs_jit_line(aTHX_ b, "XSRETURN(1);");
    }
    xs_jit_else(aTHX_ b);
    xs_jit_line(aTHX_ b, "ST(0) = sv_2mortal(newSVpvn(\"\", 0));");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    xs_jit_endif(aTHX_ b);
    xs_jit_dedent(b);
    xs_jit_line(aTHX_ b, "}");
    xs_jit_xs_end(aTHX_ b);
    xs_jit_blank(aTHX_ b);

    /* Store enum metadata for later retrieval */
    {
        HV* info = newHV();
        AV* vals = newAV();
        
        hv_stores(info, "name", newSVpv(name, 0));
        hv_stores(info, "prefix", newSVpv(prefix, 0));
        hv_stores(info, "lc_name", newSVpv(lc_name, 0));
        hv_stores(info, "start", newSViv(start));
        
        for (i = 0; i < num_values; i++) {
            HV* val_info = newHV();
            hv_stores(val_info, "name", newSVpvn(values[i].name, values[i].name_len));
            hv_stores(val_info, "index", newSViv(start + i));
            av_push(vals, newRV_noinc((SV*)val_info));
        }
        hv_stores(info, "values", newRV_noinc((SV*)vals));
        
        (void)hv_store(b->enums, name, strlen(name), newRV_noinc((SV*)info), 0);
    }

    /* Cleanup */
    if (lc_name_sv) SvREFCNT_dec(lc_name_sv);
    if (prefix_sv) SvREFCNT_dec(prefix_sv);
}

HV* xs_jit_enum_functions(pTHX_ XS_JIT_Builder* b, const char* name,
                          const char* package) {
    SV** info_svp;
    HV* info;
    HV* result;
    const char* lc_name;
    const char* prefix;
    AV* vals;
    I32 i, num_vals;
    char buf[512];

    if (!b || !name || !package) return NULL;

    info_svp = hv_fetch(b->enums, name, strlen(name), 0);
    if (!info_svp || !SvROK(*info_svp)) {
        croak("No enum named '%s' found", name);
    }
    info = (HV*)SvRV(*info_svp);

    lc_name = SvPV_nolen(*hv_fetchs(info, "lc_name", 0));
    prefix = SvPV_nolen(*hv_fetchs(info, "prefix", 0));
    vals = (AV*)SvRV(*hv_fetchs(info, "values", 0));
    num_vals = av_len(vals) + 1;

    result = newHV();

    /* Constant functions */
    for (i = 0; i < num_vals; i++) {
        HV* val_info = (HV*)SvRV(*av_fetch(vals, i, 0));
        const char* val_name = SvPV_nolen(*hv_fetchs(val_info, "name", 0));
        char uc_name[256];
        STRLEN j, len = strlen(val_name);
        HV* entry = newHV();
        
        /* Uppercase the name */
        for (j = 0; j < len && j < sizeof(uc_name) - 1; j++) {
            uc_name[j] = toUPPER(val_name[j]);
        }
        uc_name[j] = '\0';
        
        snprintf(buf, sizeof(buf), "%s::%s%s", package, prefix, uc_name);
        hv_stores(entry, "source", newSVpvf("%s_const_%s", lc_name, val_name));
        hv_stores(entry, "is_xs_native", newSViv(1));
        (void)hv_store(result, buf, strlen(buf), newRV_noinc((SV*)entry), 0);
    }

    /* is_valid function */
    {
        HV* entry = newHV();
        snprintf(buf, sizeof(buf), "%s::is_valid_%s", package, lc_name);
        hv_stores(entry, "source", newSVpvf("is_valid_%s", lc_name));
        hv_stores(entry, "is_xs_native", newSViv(1));
        (void)hv_store(result, buf, strlen(buf), newRV_noinc((SV*)entry), 0);
    }

    /* name function */
    {
        HV* entry = newHV();
        snprintf(buf, sizeof(buf), "%s::%s_name", package, lc_name);
        hv_stores(entry, "source", newSVpvf("%s_name", lc_name));
        hv_stores(entry, "is_xs_native", newSViv(1));
        (void)hv_store(result, buf, strlen(buf), newRV_noinc((SV*)entry), 0);
    }

    return result;
}

/* ============================================
 * Memoization
 * ============================================ */

void xs_jit_memoize(pTHX_ XS_JIT_Builder* b, const char* func_name,
                    XS_JIT_MemoizeOpts* opts) {
    const char* cache_attr = "_memoize_cache";
    STRLEN cache_attr_len = 15;
    IV ttl = 0;
    char func_buf[256];
    char len_buf[32];

    if (!b || !func_name) return;

    /* Process options */
    if (opts) {
        if (opts->cache_attr) {
            cache_attr = opts->cache_attr;
            cache_attr_len = opts->cache_attr_len;
        }
        ttl = opts->ttl;
    }

    snprintf(len_buf, sizeof(len_buf), "%lu", (unsigned long)cache_attr_len);

    /* Generate memoized wrapper function */
    snprintf(func_buf, sizeof(func_buf), "%s_memoized", func_name);
    xs_jit_xs_function(aTHX_ b, func_buf);
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_line(aTHX_ b, "PERL_UNUSED_VAR(items);");
    xs_jit_get_self_hv(aTHX_ b);
    xs_jit_blank(aTHX_ b);

    xs_jit_comment(aTHX_ b, "Build cache key from all arguments");
    xs_jit_declare_sv(aTHX_ b, "cache_key", "newSVpvs(\"\")");
    xs_jit_line(aTHX_ b, "IV i;");
    xs_jit_for(aTHX_ b, "i = 1", "i < items", "i++");
    xs_jit_if(aTHX_ b, "i > 1");
    xs_jit_line(aTHX_ b, "sv_catpvs(cache_key, \"\\x1C\");");
    xs_jit_endif(aTHX_ b);
    xs_jit_line(aTHX_ b, "sv_catsv(cache_key, ST(i));");
    xs_jit_endloop(aTHX_ b);
    xs_jit_blank(aTHX_ b);

    xs_jit_comment(aTHX_ b, "Get or create the cache hash");
    xs_jit_hv_fetch(aTHX_ b, "hv", cache_attr, cache_attr_len, "cache_svp");
    xs_jit_declare_hv(aTHX_ b, "cache", "NULL");
    xs_jit_if(aTHX_ b, "cache_svp && SvROK(*cache_svp) && SvTYPE(SvRV(*cache_svp)) == SVt_PVHV");
    xs_jit_assign(aTHX_ b, "cache", "(HV*)SvRV(*cache_svp)");
    xs_jit_else(aTHX_ b);
    xs_jit_assign(aTHX_ b, "cache", "newHV()");
    xs_jit_hv_store(aTHX_ b, "hv", cache_attr, cache_attr_len, "newRV_noinc((SV*)cache)");
    xs_jit_endif(aTHX_ b);
    xs_jit_blank(aTHX_ b);

    xs_jit_comment(aTHX_ b, "Check cache for existing value");
    xs_jit_line(aTHX_ b, "STRLEN key_len;");
    xs_jit_line(aTHX_ b, "const char* key_str = SvPV(cache_key, key_len);");
    xs_jit_line(aTHX_ b, "SV** cached_svp = hv_fetch(cache, key_str, key_len, 0);");

    if (ttl > 0) {
        /* With TTL support - cache stores [timestamp, value] */
        xs_jit_if(aTHX_ b, "cached_svp && SvROK(*cached_svp) && SvTYPE(SvRV(*cached_svp)) == SVt_PVAV");
        xs_jit_declare_av(aTHX_ b, "cached_av", "(AV*)SvRV(*cached_svp)");
        xs_jit_line(aTHX_ b, "SV** ts_svp = av_fetch(cached_av, 0, 0);");
        xs_jit_line(aTHX_ b, "SV** val_svp = av_fetch(cached_av, 1, 0);");
        {
            char ttl_cond[128];
            snprintf(ttl_cond, sizeof(ttl_cond),
                     "ts_svp && val_svp && (time(NULL) - SvIV(*ts_svp)) < %ld", (long)ttl);
            xs_jit_if(aTHX_ b, ttl_cond);
        }
        xs_jit_line(aTHX_ b, "SvREFCNT_dec(cache_key);");
        xs_jit_return_sv(aTHX_ b, "SvREFCNT_inc(*val_svp)");
        xs_jit_endif(aTHX_ b);
        xs_jit_endif(aTHX_ b);
    } else {
        /* Without TTL - simple cache lookup */
        xs_jit_if(aTHX_ b, "cached_svp");
        xs_jit_line(aTHX_ b, "SvREFCNT_dec(cache_key);");
        xs_jit_return_sv(aTHX_ b, "SvREFCNT_inc(*cached_svp)");
        xs_jit_endif(aTHX_ b);
    }

    xs_jit_blank(aTHX_ b);
    xs_jit_comment(aTHX_ b, "Cache miss - call original function");
    xs_jit_block_start(aTHX_ b);
    xs_jit_line(aTHX_ b, "dSP;");
    xs_jit_line(aTHX_ b, "int count;");
    xs_jit_line(aTHX_ b, "SV* result;");
    xs_jit_blank(aTHX_ b);
    xs_jit_line(aTHX_ b, "ENTER;");
    xs_jit_line(aTHX_ b, "SAVETMPS;");
    xs_jit_line(aTHX_ b, "PUSHMARK(SP);");
    xs_jit_comment(aTHX_ b, "Push all original arguments");
    xs_jit_for(aTHX_ b, "i = 0", "i < items", "i++");
    xs_jit_line(aTHX_ b, "XPUSHs(ST(i));");
    xs_jit_endloop(aTHX_ b);
    xs_jit_line(aTHX_ b, "PUTBACK;");
    xs_jit_blank(aTHX_ b);
    xs_jit_line(aTHX_ b, "count = call_method(\"_orig_%s\", G_SCALAR);", func_name);
    xs_jit_blank(aTHX_ b);
    xs_jit_line(aTHX_ b, "SPAGAIN;");
    xs_jit_if(aTHX_ b, "count > 0");
    xs_jit_line(aTHX_ b, "result = SvREFCNT_inc(POPs);");
    xs_jit_else(aTHX_ b);
    xs_jit_line(aTHX_ b, "result = &PL_sv_undef;");
    xs_jit_endif(aTHX_ b);
    xs_jit_line(aTHX_ b, "PUTBACK;");
    xs_jit_line(aTHX_ b, "FREETMPS;");
    xs_jit_line(aTHX_ b, "LEAVE;");
    xs_jit_blank(aTHX_ b);
    xs_jit_comment(aTHX_ b, "Store in cache");

    if (ttl > 0) {
        /* With TTL - store [timestamp, value] */
        xs_jit_line(aTHX_ b, "AV* entry = newAV();");
        xs_jit_line(aTHX_ b, "av_push(entry, newSViv(time(NULL)));");
        xs_jit_line(aTHX_ b, "av_push(entry, SvREFCNT_inc(result));");
        xs_jit_line(aTHX_ b, "(void)hv_store(cache, key_str, key_len, newRV_noinc((SV*)entry), 0);");
    } else {
        /* Without TTL - store value directly */
        xs_jit_line(aTHX_ b, "(void)hv_store(cache, key_str, key_len, SvREFCNT_inc(result), 0);");
    }

    xs_jit_line(aTHX_ b, "SvREFCNT_dec(cache_key);");
    xs_jit_line(aTHX_ b, "ST(0) = sv_2mortal(result);");
    xs_jit_line(aTHX_ b, "XSRETURN(1);");
    xs_jit_block_end(aTHX_ b);
    xs_jit_xs_end(aTHX_ b);
    xs_jit_blank(aTHX_ b);

    /* Generate clear_<func_name>_cache method */
    snprintf(func_buf, sizeof(func_buf), "clear_%s_cache", func_name);
    xs_jit_xs_function(aTHX_ b, func_buf);
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_line(aTHX_ b, "PERL_UNUSED_VAR(items);");
    xs_jit_get_self_hv(aTHX_ b);
    xs_jit_hv_fetch(aTHX_ b, "hv", cache_attr, cache_attr_len, "cache_svp");
    xs_jit_if(aTHX_ b, "cache_svp && SvROK(*cache_svp) && SvTYPE(SvRV(*cache_svp)) == SVt_PVHV");
    xs_jit_line(aTHX_ b, "hv_clear((HV*)SvRV(*cache_svp));");
    xs_jit_endif(aTHX_ b);
    xs_jit_return_self(aTHX_ b);
    xs_jit_xs_end(aTHX_ b);
    xs_jit_blank(aTHX_ b);

    /* Store memoize metadata for later retrieval */
    {
        HV* info = newHV();
        hv_stores(info, "name", newSVpv(func_name, 0));
        hv_stores(info, "cache_attr", newSVpv(cache_attr, cache_attr_len));
        hv_stores(info, "ttl", newSViv(ttl));
        (void)hv_store(b->memoized, func_name, strlen(func_name), newRV_noinc((SV*)info), 0);
    }
}

HV* xs_jit_memoize_functions(pTHX_ XS_JIT_Builder* b, const char* func_name,
                              const char* package) {
    SV** info_svp;
    HV* result;
    char buf[512];

    if (!b || !func_name || !package) return NULL;

    info_svp = hv_fetch(b->memoized, func_name, strlen(func_name), 0);
    if (!info_svp || !SvROK(*info_svp)) {
        croak("No memoized function named '%s' found", func_name);
    }

    result = newHV();

    /* Memoized wrapper */
    {
        HV* entry = newHV();
        snprintf(buf, sizeof(buf), "%s::%s", package, func_name);
        hv_stores(entry, "source", newSVpvf("%s_memoized", func_name));
        hv_stores(entry, "is_xs_native", newSViv(1));
        (void)hv_store(result, buf, strlen(buf), newRV_noinc((SV*)entry), 0);
    }

    /* Cache clearer */
    {
        HV* entry = newHV();
        snprintf(buf, sizeof(buf), "%s::clear_%s_cache", package, func_name);
        hv_stores(entry, "source", newSVpvf("clear_%s_cache", func_name));
        hv_stores(entry, "is_xs_native", newSViv(1));
        (void)hv_store(result, buf, strlen(buf), newRV_noinc((SV*)entry), 0);
    }

    return result;
}

/* ============================================
 * Role/Mixin Composer
 * ============================================ */

/* Generate Comparable role methods */
static void xs_jit_role_comparable(pTHX_ XS_JIT_Builder* b, XS_JIT_RoleOpts* opts) {
    const char* compare_key = "id";
    STRLEN compare_key_len = 2;
    char len_buf[32];

    if (opts && opts->compare_key) {
        compare_key = opts->compare_key;
        compare_key_len = opts->compare_key_len;
    }

    snprintf(len_buf, sizeof(len_buf), "%lu", (unsigned long)compare_key_len);

    /* compare($other) - returns -1, 0, or 1 */
    xs_jit_xs_function(aTHX_ b, "compare");
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_check_items(aTHX_ b, 2, 2, "$self, $other");
    xs_jit_get_self_hv(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    xs_jit_comment(aTHX_ b, "Get other object's hash");
    xs_jit_line(aTHX_ b, "SV* other = ST(1);");
    xs_jit_if(aTHX_ b, "!SvROK(other) || SvTYPE(SvRV(other)) != SVt_PVHV");
    xs_jit_croak(aTHX_ b, "compare() requires another object");
    xs_jit_endif(aTHX_ b);
    xs_jit_declare_hv(aTHX_ b, "other_hv", "(HV*)SvRV(other)");
    xs_jit_blank(aTHX_ b);
    xs_jit_comment(aTHX_ b, "Fetch compare key from both objects");
    xs_jit_hv_fetch(aTHX_ b, "hv", compare_key, compare_key_len, "self_svp");
    xs_jit_hv_fetch(aTHX_ b, "other_hv", compare_key, compare_key_len, "other_svp");
    xs_jit_blank(aTHX_ b);
    xs_jit_comment(aTHX_ b, "Compare values");
    xs_jit_line(aTHX_ b, "SV* self_val = (self_svp && *self_svp) ? *self_svp : &PL_sv_undef;");
    xs_jit_line(aTHX_ b, "SV* other_val = (other_svp && *other_svp) ? *other_svp : &PL_sv_undef;");
    xs_jit_line(aTHX_ b, "int cmp = sv_cmp(self_val, other_val);");
    xs_jit_return_iv(aTHX_ b, "cmp < 0 ? -1 : (cmp > 0 ? 1 : 0)");
    xs_jit_xs_end(aTHX_ b);
    xs_jit_blank(aTHX_ b);

    /* equals($other) - returns true if compare == 0 */
    xs_jit_xs_function(aTHX_ b, "equals");
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_check_items(aTHX_ b, 2, 2, "$self, $other");
    xs_jit_get_self_hv(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    xs_jit_line(aTHX_ b, "SV* other = ST(1);");
    xs_jit_if(aTHX_ b, "!SvROK(other) || SvTYPE(SvRV(other)) != SVt_PVHV");
    xs_jit_return_no(aTHX_ b);
    xs_jit_endif(aTHX_ b);
    xs_jit_declare_hv(aTHX_ b, "other_hv", "(HV*)SvRV(other)");
    xs_jit_hv_fetch(aTHX_ b, "hv", compare_key, compare_key_len, "self_svp");
    xs_jit_hv_fetch(aTHX_ b, "other_hv", compare_key, compare_key_len, "other_svp");
    xs_jit_line(aTHX_ b, "SV* self_val = (self_svp && *self_svp) ? *self_svp : &PL_sv_undef;");
    xs_jit_line(aTHX_ b, "SV* other_val = (other_svp && *other_svp) ? *other_svp : &PL_sv_undef;");
    xs_jit_if(aTHX_ b, "sv_eq(self_val, other_val)");
    xs_jit_return_yes(aTHX_ b);
    xs_jit_else(aTHX_ b);
    xs_jit_return_no(aTHX_ b);
    xs_jit_endif(aTHX_ b);
    xs_jit_xs_end(aTHX_ b);
    xs_jit_blank(aTHX_ b);

    /* lt($other) - returns true if self < other */
    xs_jit_xs_function(aTHX_ b, "lt");
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_check_items(aTHX_ b, 2, 2, "$self, $other");
    xs_jit_get_self_hv(aTHX_ b);
    xs_jit_line(aTHX_ b, "SV* other = ST(1);");
    xs_jit_if(aTHX_ b, "!SvROK(other) || SvTYPE(SvRV(other)) != SVt_PVHV");
    xs_jit_return_no(aTHX_ b);
    xs_jit_endif(aTHX_ b);
    xs_jit_declare_hv(aTHX_ b, "other_hv", "(HV*)SvRV(other)");
    xs_jit_hv_fetch(aTHX_ b, "hv", compare_key, compare_key_len, "self_svp");
    xs_jit_hv_fetch(aTHX_ b, "other_hv", compare_key, compare_key_len, "other_svp");
    xs_jit_line(aTHX_ b, "SV* self_val = (self_svp && *self_svp) ? *self_svp : &PL_sv_undef;");
    xs_jit_line(aTHX_ b, "SV* other_val = (other_svp && *other_svp) ? *other_svp : &PL_sv_undef;");
    xs_jit_if(aTHX_ b, "sv_cmp(self_val, other_val) < 0");
    xs_jit_return_yes(aTHX_ b);
    xs_jit_else(aTHX_ b);
    xs_jit_return_no(aTHX_ b);
    xs_jit_endif(aTHX_ b);
    xs_jit_xs_end(aTHX_ b);
    xs_jit_blank(aTHX_ b);

    /* gt($other) - returns true if self > other */
    xs_jit_xs_function(aTHX_ b, "gt");
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_check_items(aTHX_ b, 2, 2, "$self, $other");
    xs_jit_get_self_hv(aTHX_ b);
    xs_jit_line(aTHX_ b, "SV* other = ST(1);");
    xs_jit_if(aTHX_ b, "!SvROK(other) || SvTYPE(SvRV(other)) != SVt_PVHV");
    xs_jit_return_no(aTHX_ b);
    xs_jit_endif(aTHX_ b);
    xs_jit_declare_hv(aTHX_ b, "other_hv", "(HV*)SvRV(other)");
    xs_jit_hv_fetch(aTHX_ b, "hv", compare_key, compare_key_len, "self_svp");
    xs_jit_hv_fetch(aTHX_ b, "other_hv", compare_key, compare_key_len, "other_svp");
    xs_jit_line(aTHX_ b, "SV* self_val = (self_svp && *self_svp) ? *self_svp : &PL_sv_undef;");
    xs_jit_line(aTHX_ b, "SV* other_val = (other_svp && *other_svp) ? *other_svp : &PL_sv_undef;");
    xs_jit_if(aTHX_ b, "sv_cmp(self_val, other_val) > 0");
    xs_jit_return_yes(aTHX_ b);
    xs_jit_else(aTHX_ b);
    xs_jit_return_no(aTHX_ b);
    xs_jit_endif(aTHX_ b);
    xs_jit_xs_end(aTHX_ b);
    xs_jit_blank(aTHX_ b);

    /* le($other) - returns true if self <= other */
    xs_jit_xs_function(aTHX_ b, "le");
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_check_items(aTHX_ b, 2, 2, "$self, $other");
    xs_jit_get_self_hv(aTHX_ b);
    xs_jit_line(aTHX_ b, "SV* other = ST(1);");
    xs_jit_if(aTHX_ b, "!SvROK(other) || SvTYPE(SvRV(other)) != SVt_PVHV");
    xs_jit_return_no(aTHX_ b);
    xs_jit_endif(aTHX_ b);
    xs_jit_declare_hv(aTHX_ b, "other_hv", "(HV*)SvRV(other)");
    xs_jit_hv_fetch(aTHX_ b, "hv", compare_key, compare_key_len, "self_svp");
    xs_jit_hv_fetch(aTHX_ b, "other_hv", compare_key, compare_key_len, "other_svp");
    xs_jit_line(aTHX_ b, "SV* self_val = (self_svp && *self_svp) ? *self_svp : &PL_sv_undef;");
    xs_jit_line(aTHX_ b, "SV* other_val = (other_svp && *other_svp) ? *other_svp : &PL_sv_undef;");
    xs_jit_if(aTHX_ b, "sv_cmp(self_val, other_val) <= 0");
    xs_jit_return_yes(aTHX_ b);
    xs_jit_else(aTHX_ b);
    xs_jit_return_no(aTHX_ b);
    xs_jit_endif(aTHX_ b);
    xs_jit_xs_end(aTHX_ b);
    xs_jit_blank(aTHX_ b);

    /* ge($other) - returns true if self >= other */
    xs_jit_xs_function(aTHX_ b, "ge");
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_check_items(aTHX_ b, 2, 2, "$self, $other");
    xs_jit_get_self_hv(aTHX_ b);
    xs_jit_line(aTHX_ b, "SV* other = ST(1);");
    xs_jit_if(aTHX_ b, "!SvROK(other) || SvTYPE(SvRV(other)) != SVt_PVHV");
    xs_jit_return_no(aTHX_ b);
    xs_jit_endif(aTHX_ b);
    xs_jit_declare_hv(aTHX_ b, "other_hv", "(HV*)SvRV(other)");
    xs_jit_hv_fetch(aTHX_ b, "hv", compare_key, compare_key_len, "self_svp");
    xs_jit_hv_fetch(aTHX_ b, "other_hv", compare_key, compare_key_len, "other_svp");
    xs_jit_line(aTHX_ b, "SV* self_val = (self_svp && *self_svp) ? *self_svp : &PL_sv_undef;");
    xs_jit_line(aTHX_ b, "SV* other_val = (other_svp && *other_svp) ? *other_svp : &PL_sv_undef;");
    xs_jit_if(aTHX_ b, "sv_cmp(self_val, other_val) >= 0");
    xs_jit_return_yes(aTHX_ b);
    xs_jit_else(aTHX_ b);
    xs_jit_return_no(aTHX_ b);
    xs_jit_endif(aTHX_ b);
    xs_jit_xs_end(aTHX_ b);
    xs_jit_blank(aTHX_ b);
}

/* Generate Cloneable role methods */
static void xs_jit_role_cloneable(pTHX_ XS_JIT_Builder* b, XS_JIT_RoleOpts* opts) {
    PERL_UNUSED_ARG(opts);

    /* clone() - shallow clone of hash-based object */
    xs_jit_xs_function(aTHX_ b, "clone");
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_check_items(aTHX_ b, 1, 1, "$self");
    xs_jit_get_self_hv(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    xs_jit_comment(aTHX_ b, "Create new hash and copy all keys");
    xs_jit_declare_hv(aTHX_ b, "clone_hv", "newHV()");
    xs_jit_line(aTHX_ b, "HE* entry;");
    xs_jit_line(aTHX_ b, "hv_iterinit(hv);");
    xs_jit_while(aTHX_ b, "(entry = hv_iternext(hv)) != NULL");
    xs_jit_line(aTHX_ b, "SV* key_sv = hv_iterkeysv(entry);");
    xs_jit_line(aTHX_ b, "SV* val = hv_iterval(hv, entry);");
    xs_jit_line(aTHX_ b, "STRLEN key_len;");
    xs_jit_line(aTHX_ b, "const char* key = SvPV(key_sv, key_len);");
    xs_jit_comment(aTHX_ b, "Use newSVsv to create a true copy of the value");
    xs_jit_line(aTHX_ b, "(void)hv_store(clone_hv, key, key_len, newSVsv(val), 0);");
    xs_jit_endloop(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    xs_jit_comment(aTHX_ b, "Bless into same class and return");
    xs_jit_line(aTHX_ b, "SV* clone_ref = sv_2mortal(newRV_noinc((SV*)clone_hv));");
    xs_jit_line(aTHX_ b, "const char* classname = sv_reftype(SvRV(self), 1);");
    xs_jit_line(aTHX_ b, "sv_bless(clone_ref, gv_stashpv(classname, GV_ADD));");
    xs_jit_return_sv(aTHX_ b, "SvREFCNT_inc(clone_ref)");
    xs_jit_xs_end(aTHX_ b);
    xs_jit_blank(aTHX_ b);
}

/* Generate Serializable role methods */
static void xs_jit_role_serializable(pTHX_ XS_JIT_Builder* b, XS_JIT_RoleOpts* opts) {
    PERL_UNUSED_ARG(opts);

    /* TO_JSON() - returns hashref copy for JSON::XS compatibility */
    xs_jit_xs_function(aTHX_ b, "TO_JSON");
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_check_items(aTHX_ b, 1, 1, "$self");
    xs_jit_get_self_hv(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    xs_jit_comment(aTHX_ b, "Create shallow copy of hash");
    xs_jit_declare_hv(aTHX_ b, "copy", "newHV()");
    xs_jit_line(aTHX_ b, "HE* entry;");
    xs_jit_line(aTHX_ b, "hv_iterinit(hv);");
    xs_jit_while(aTHX_ b, "(entry = hv_iternext(hv)) != NULL");
    xs_jit_line(aTHX_ b, "SV* key_sv = hv_iterkeysv(entry);");
    xs_jit_line(aTHX_ b, "SV* val = hv_iterval(hv, entry);");
    xs_jit_line(aTHX_ b, "STRLEN key_len;");
    xs_jit_line(aTHX_ b, "const char* key = SvPV(key_sv, key_len);");
    xs_jit_comment(aTHX_ b, "Skip private attributes (starting with _)");
    xs_jit_if(aTHX_ b, "key_len > 0 && key[0] == '_'");
    xs_jit_line(aTHX_ b, "continue;");
    xs_jit_endif(aTHX_ b);
    xs_jit_line(aTHX_ b, "(void)hv_store(copy, key, key_len, SvREFCNT_inc(val), 0);");
    xs_jit_endloop(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    xs_jit_return_sv(aTHX_ b, "sv_2mortal(newRV_noinc((SV*)copy))");
    xs_jit_xs_end(aTHX_ b);
    xs_jit_blank(aTHX_ b);

    /* TO_HASH() - returns hashref copy (all keys including private) */
    xs_jit_xs_function(aTHX_ b, "TO_HASH");
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_check_items(aTHX_ b, 1, 1, "$self");
    xs_jit_get_self_hv(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    xs_jit_comment(aTHX_ b, "Create shallow copy of hash (all keys)");
    xs_jit_declare_hv(aTHX_ b, "copy", "newHV()");
    xs_jit_line(aTHX_ b, "HE* entry;");
    xs_jit_line(aTHX_ b, "hv_iterinit(hv);");
    xs_jit_while(aTHX_ b, "(entry = hv_iternext(hv)) != NULL");
    xs_jit_line(aTHX_ b, "SV* key_sv = hv_iterkeysv(entry);");
    xs_jit_line(aTHX_ b, "SV* val = hv_iterval(hv, entry);");
    xs_jit_line(aTHX_ b, "STRLEN key_len;");
    xs_jit_line(aTHX_ b, "const char* key = SvPV(key_sv, key_len);");
    xs_jit_line(aTHX_ b, "(void)hv_store(copy, key, key_len, SvREFCNT_inc(val), 0);");
    xs_jit_endloop(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    xs_jit_return_sv(aTHX_ b, "sv_2mortal(newRV_noinc((SV*)copy))");
    xs_jit_xs_end(aTHX_ b);
    xs_jit_blank(aTHX_ b);
}

/* Generate Observable role methods */
static void xs_jit_role_observable(pTHX_ XS_JIT_Builder* b, XS_JIT_RoleOpts* opts) {
    const char* observers_attr = "_observers";
    STRLEN observers_attr_len = 10;
    char len_buf[32];

    if (opts && opts->observers_attr) {
        observers_attr = opts->observers_attr;
        observers_attr_len = opts->observers_attr_len;
    }

    snprintf(len_buf, sizeof(len_buf), "%lu", (unsigned long)observers_attr_len);

    /* add_observer($callback) - adds callback to observers list */
    xs_jit_xs_function(aTHX_ b, "add_observer");
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_check_items(aTHX_ b, 2, 2, "$self, $callback");
    xs_jit_get_self_hv(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    xs_jit_line(aTHX_ b, "SV* callback = ST(1);");
    xs_jit_if(aTHX_ b, "!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV");
    xs_jit_croak(aTHX_ b, "add_observer() requires a code reference");
    xs_jit_endif(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    xs_jit_comment(aTHX_ b, "Get or create observers array");
    xs_jit_hv_fetch(aTHX_ b, "hv", observers_attr, observers_attr_len, "obs_svp");
    xs_jit_declare_av(aTHX_ b, "observers", "NULL");
    xs_jit_if(aTHX_ b, "obs_svp && SvROK(*obs_svp) && SvTYPE(SvRV(*obs_svp)) == SVt_PVAV");
    xs_jit_assign(aTHX_ b, "observers", "(AV*)SvRV(*obs_svp)");
    xs_jit_else(aTHX_ b);
    xs_jit_assign(aTHX_ b, "observers", "newAV()");
    xs_jit_hv_store(aTHX_ b, "hv", observers_attr, observers_attr_len, "newRV_noinc((SV*)observers)");
    xs_jit_endif(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    xs_jit_comment(aTHX_ b, "Add callback to list");
    xs_jit_av_push(aTHX_ b, "observers", "SvREFCNT_inc(callback)");
    xs_jit_return_self(aTHX_ b);
    xs_jit_xs_end(aTHX_ b);
    xs_jit_blank(aTHX_ b);

    /* remove_observer($callback) - removes callback from list */
    xs_jit_xs_function(aTHX_ b, "remove_observer");
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_check_items(aTHX_ b, 2, 2, "$self, $callback");
    xs_jit_get_self_hv(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    xs_jit_line(aTHX_ b, "SV* callback = ST(1);");
    xs_jit_hv_fetch(aTHX_ b, "hv", observers_attr, observers_attr_len, "obs_svp");
    xs_jit_if(aTHX_ b, "!obs_svp || !SvROK(*obs_svp) || SvTYPE(SvRV(*obs_svp)) != SVt_PVAV");
    xs_jit_return_self(aTHX_ b);
    xs_jit_endif(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    xs_jit_declare_av(aTHX_ b, "observers", "(AV*)SvRV(*obs_svp)");
    xs_jit_av_len(aTHX_ b, "observers", "len");
    xs_jit_line(aTHX_ b, "IV i;");
    xs_jit_for(aTHX_ b, "i = 0", "i <= len", "i++");
    xs_jit_av_fetch(aTHX_ b, "observers", "i", "elem_svp");
    xs_jit_if(aTHX_ b, "elem_svp && *elem_svp && sv_eq(*elem_svp, callback)");
    xs_jit_comment(aTHX_ b, "Remove this element - av_delete returns SV without changing refcnt");
    xs_jit_line(aTHX_ b, "(void)av_delete(observers, i, G_DISCARD);");
    xs_jit_line(aTHX_ b, "break;");
    xs_jit_endif(aTHX_ b);
    xs_jit_endloop(aTHX_ b);
    xs_jit_return_self(aTHX_ b);
    xs_jit_xs_end(aTHX_ b);
    xs_jit_blank(aTHX_ b);

    /* notify_observers(@args) - calls all observers with @args */
    xs_jit_xs_function(aTHX_ b, "notify_observers");
    xs_jit_xs_preamble(aTHX_ b);
    xs_jit_line(aTHX_ b, "PERL_UNUSED_VAR(items);");
    xs_jit_get_self_hv(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    xs_jit_hv_fetch(aTHX_ b, "hv", observers_attr, observers_attr_len, "obs_svp");
    xs_jit_if(aTHX_ b, "!obs_svp || !SvROK(*obs_svp) || SvTYPE(SvRV(*obs_svp)) != SVt_PVAV");
    xs_jit_return_self(aTHX_ b);
    xs_jit_endif(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    xs_jit_declare_av(aTHX_ b, "observers", "(AV*)SvRV(*obs_svp)");
    xs_jit_av_len(aTHX_ b, "observers", "len");
    xs_jit_line(aTHX_ b, "IV i, j;");
    xs_jit_blank(aTHX_ b);
    xs_jit_comment(aTHX_ b, "Call each observer with all args passed to notify_observers");
    xs_jit_comment(aTHX_ b, "First, save args since we'll modify the stack");
    xs_jit_line(aTHX_ b, "AV* args_av = NULL;");
    xs_jit_if(aTHX_ b, "items > 1");
    xs_jit_line(aTHX_ b, "args_av = newAV();");
    xs_jit_for(aTHX_ b, "j = 1", "j < items", "j++");
    xs_jit_line(aTHX_ b, "av_push(args_av, SvREFCNT_inc(ST(j)));");
    xs_jit_endloop(aTHX_ b);
    xs_jit_endif(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    xs_jit_for(aTHX_ b, "i = 0", "i <= len", "i++");
    xs_jit_av_fetch(aTHX_ b, "observers", "i", "cb_svp");
    xs_jit_if(aTHX_ b, "!cb_svp || !*cb_svp || !SvOK(*cb_svp)");
    xs_jit_line(aTHX_ b, "continue;");
    xs_jit_endif(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    xs_jit_block_start(aTHX_ b);
    xs_jit_line(aTHX_ b, "ENTER;");
    xs_jit_line(aTHX_ b, "SAVETMPS;");
    xs_jit_line(aTHX_ b, "PUSHMARK(SP);");
    xs_jit_comment(aTHX_ b, "Push saved arguments");
    xs_jit_if(aTHX_ b, "args_av");
    xs_jit_line(aTHX_ b, "SSize_t args_len = av_len(args_av);");
    xs_jit_for(aTHX_ b, "j = 0", "j <= args_len", "j++");
    xs_jit_line(aTHX_ b, "SV** arg_svp = av_fetch(args_av, j, 0);");
    xs_jit_if(aTHX_ b, "arg_svp && *arg_svp");
    xs_jit_line(aTHX_ b, "XPUSHs(*arg_svp);");
    xs_jit_endif(aTHX_ b);
    xs_jit_endloop(aTHX_ b);
    xs_jit_endif(aTHX_ b);
    xs_jit_line(aTHX_ b, "PUTBACK;");
    xs_jit_line(aTHX_ b, "call_sv(*cb_svp, G_DISCARD);");
    xs_jit_line(aTHX_ b, "SPAGAIN;");
    xs_jit_line(aTHX_ b, "FREETMPS;");
    xs_jit_line(aTHX_ b, "LEAVE;");
    xs_jit_block_end(aTHX_ b);
    xs_jit_endloop(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    xs_jit_comment(aTHX_ b, "Free saved args");
    xs_jit_if(aTHX_ b, "args_av");
    xs_jit_line(aTHX_ b, "SvREFCNT_dec((SV*)args_av);");
    xs_jit_endif(aTHX_ b);
    xs_jit_blank(aTHX_ b);
    xs_jit_return_self(aTHX_ b);
    xs_jit_xs_end(aTHX_ b);
    xs_jit_blank(aTHX_ b);
}

/* Main role dispatcher */
void xs_jit_role(pTHX_ XS_JIT_Builder* b, XS_JIT_RoleType role, XS_JIT_RoleOpts* opts) {
    if (!b) return;

    switch (role) {
        case XS_JIT_ROLE_COMPARABLE:
            xs_jit_role_comparable(aTHX_ b, opts);
            break;
        case XS_JIT_ROLE_CLONEABLE:
            xs_jit_role_cloneable(aTHX_ b, opts);
            break;
        case XS_JIT_ROLE_SERIALIZABLE:
            xs_jit_role_serializable(aTHX_ b, opts);
            break;
        case XS_JIT_ROLE_OBSERVABLE:
            xs_jit_role_observable(aTHX_ b, opts);
            break;
        default:
            croak("Unknown role type: %d", (int)role);
    }
}
