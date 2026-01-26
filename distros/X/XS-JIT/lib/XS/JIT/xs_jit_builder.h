/*
 * xs_jit_builder.h - C API for building C code strings for XS::JIT
 *
 * This header provides a fluent C API for generating C code dynamically.
 * It can be used directly from XS code without Perl overhead, making it
 * ideal for code generation in performance-critical modules like Meow.
 *
 * Example usage:
 *
 *   XS_JIT_Builder* b = xs_jit_builder_new(aTHX);
 *   xs_jit_ro_accessor(aTHX_ b, "MyClass_get_name", "name", 4);
 *   SV* code = xs_jit_builder_code(aTHX_ b);
 *   xs_jit_builder_free(aTHX_ b);
 */

#ifndef XS_JIT_BUILDER_H
#define XS_JIT_BUILDER_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* ============================================
 * Builder context structure
 * ============================================ */

typedef struct {
    SV* code;           /* The accumulated code (SV*) */
    int indent;         /* Current indentation level */
    int indent_width;   /* Spaces per indent (default 4) */
    int use_tabs;       /* Use tabs instead of spaces (default 0) */
    int in_function;    /* Currently inside a function */
    HV* enums;          /* Stored enum metadata (name => info) */
    HV* memoized;       /* Stored memoize metadata (name => info) */
} XS_JIT_Builder;

/* Attribute descriptor for constructors */
typedef struct {
    const char* name;
    STRLEN len;
} XS_JIT_Attr;

/* ============================================
 * Inline op types for cv_set_call_checker
 * ============================================ */

typedef enum {
    XS_JIT_INLINE_NONE      = 0,
    XS_JIT_INLINE_GETTER    = 1,  /* Read-only slot accessor */
    XS_JIT_INLINE_SETTER    = 2,  /* Read-write slot accessor */
    XS_JIT_INLINE_HV_GETTER = 3,  /* Hash-based read-only accessor */
    XS_JIT_INLINE_HV_SETTER = 4   /* Hash-based read-write accessor */
} XS_JIT_InlineType;

/* ============================================
 * Lifecycle
 * ============================================ */

/* Create a new builder */
XS_JIT_Builder* xs_jit_builder_new(pTHX);

/* Free the builder (does NOT free the code SV) */
void xs_jit_builder_free(pTHX_ XS_JIT_Builder* b);

/* Get the accumulated code as SV* (caller owns the reference) */
SV* xs_jit_builder_code(pTHX_ XS_JIT_Builder* b);

/* Get the accumulated code as a C string (pointer into SV, valid until SV is modified) */
const char* xs_jit_builder_cstr(pTHX_ XS_JIT_Builder* b);

/* Reset the builder for reuse (clears code, resets indent) */
void xs_jit_builder_reset(pTHX_ XS_JIT_Builder* b);

/* ============================================
 * Low-level output
 * ============================================ */

/* Add a formatted line with current indentation and newline */
void xs_jit_line(pTHX_ XS_JIT_Builder* b, const char* fmt, ...);

/* Add raw formatted text without indentation or newline */
void xs_jit_raw(pTHX_ XS_JIT_Builder* b, const char* fmt, ...);

/* Add a C comment: / * text * / */
void xs_jit_comment(pTHX_ XS_JIT_Builder* b, const char* text);

/* Add a blank line */
void xs_jit_blank(pTHX_ XS_JIT_Builder* b);

/* ============================================
 * Indentation control
 * ============================================ */

/* Increase indentation level */
void xs_jit_indent(XS_JIT_Builder* b);

/* Decrease indentation level */
void xs_jit_dedent(XS_JIT_Builder* b);

/* Set spaces per indentation level (default 4) */
void xs_jit_set_indent_width(XS_JIT_Builder* b, int width);

/* Use tabs instead of spaces for indentation */
void xs_jit_set_use_tabs(XS_JIT_Builder* b, int use_tabs);

/* ============================================
 * Blocks and structure
 * ============================================ */

/* Start a block: { with indent increase */
void xs_jit_block_start(pTHX_ XS_JIT_Builder* b);

/* End a block: } with indent decrease */
void xs_jit_block_end(pTHX_ XS_JIT_Builder* b);

/* ============================================
 * XS Function structure
 * ============================================ */

/* Start an XS function: XS_EUPXS(name) { */
void xs_jit_xs_function(pTHX_ XS_JIT_Builder* b, const char* name);

/* Add standard XS preamble: dVAR; dXSARGS; PERL_UNUSED_VAR(cv); */
void xs_jit_xs_preamble(pTHX_ XS_JIT_Builder* b);

/* End XS function (closes brace) */
void xs_jit_xs_end(pTHX_ XS_JIT_Builder* b);

/* XSRETURN(n); */
void xs_jit_xs_return(pTHX_ XS_JIT_Builder* b, int count);

/* ST(0) = &PL_sv_undef; XSRETURN(1); */
void xs_jit_xs_return_undef(pTHX_ XS_JIT_Builder* b);

/* croak_xs_usage(cv, "usage"); */
void xs_jit_croak_usage(pTHX_ XS_JIT_Builder* b, const char* usage);

/* ============================================
 * Control flow
 * ============================================ */

/* if (condition) { */
void xs_jit_if(pTHX_ XS_JIT_Builder* b, const char* cond);

/* } else if (condition) { */
void xs_jit_elsif(pTHX_ XS_JIT_Builder* b, const char* cond);

/* } else { */
void xs_jit_else(pTHX_ XS_JIT_Builder* b);

/* } (close if/else) */
void xs_jit_endif(pTHX_ XS_JIT_Builder* b);

/* for (init; cond; incr) { */
void xs_jit_for(pTHX_ XS_JIT_Builder* b, const char* init, const char* cond, const char* incr);

/* while (condition) { */
void xs_jit_while(pTHX_ XS_JIT_Builder* b, const char* cond);

/* } (close for/while) */
void xs_jit_endloop(pTHX_ XS_JIT_Builder* b);

/* ============================================
 * Variable declarations
 * ============================================ */

/* type name; or type name = value; (value can be NULL) */
void xs_jit_declare(pTHX_ XS_JIT_Builder* b, const char* type, const char* name, const char* value);

/* SV* name = value; */
void xs_jit_declare_sv(pTHX_ XS_JIT_Builder* b, const char* name, const char* value);

/* HV* name = value; */
void xs_jit_declare_hv(pTHX_ XS_JIT_Builder* b, const char* name, const char* value);

/* AV* name = value; */
void xs_jit_declare_av(pTHX_ XS_JIT_Builder* b, const char* name, const char* value);

/* int name = value; */
void xs_jit_declare_int(pTHX_ XS_JIT_Builder* b, const char* name, const char* value);

/* IV name = value; */
void xs_jit_declare_iv(pTHX_ XS_JIT_Builder* b, const char* name, const char* value);

/* NV name = value; */
void xs_jit_declare_nv(pTHX_ XS_JIT_Builder* b, const char* name, const char* value);

/* const char* name = value; */
void xs_jit_declare_pv(pTHX_ XS_JIT_Builder* b, const char* name, const char* value);

/* var = value; (assignment) */
void xs_jit_assign(pTHX_ XS_JIT_Builder* b, const char* var, const char* value);

/* ============================================
 * Common XS patterns
 * ============================================ */

/* SV* self = ST(0); */
void xs_jit_get_self(pTHX_ XS_JIT_Builder* b);

/* SV* self = ST(0); HV* hv = (HV*)SvRV(self); */
void xs_jit_get_self_hv(pTHX_ XS_JIT_Builder* b);

/* SV* self = ST(0); AV* av = (AV*)SvRV(self); */
void xs_jit_get_self_av(pTHX_ XS_JIT_Builder* b);

/* ============================================
 * Hash operations
 * ============================================ */

/* SV** result_var = hv_fetch(hv, "key", len, 0); - literal key */
void xs_jit_hv_fetch(pTHX_ XS_JIT_Builder* b, const char* hv, const char* key, STRLEN len, const char* result_var);

/* SV** result_var = hv_fetch(hv, key_expr, len_expr, 0); - dynamic key */
void xs_jit_hv_fetch_sv(pTHX_ XS_JIT_Builder* b, const char* hv, const char* key_expr, const char* len_expr, const char* result_var);

/* (void)hv_store(hv, "key", len, value, 0); - literal key */
void xs_jit_hv_store(pTHX_ XS_JIT_Builder* b, const char* hv, const char* key, STRLEN len, const char* value);

/* (void)hv_store(hv, key_expr, len_expr, value, 0); - dynamic key */
void xs_jit_hv_store_sv(pTHX_ XS_JIT_Builder* b, const char* hv, const char* key_expr, const char* len_expr, const char* value);

/* Fetch from hash and return (with undef fallback) - complete pattern */
void xs_jit_hv_fetch_return(pTHX_ XS_JIT_Builder* b, const char* hv, const char* key, STRLEN len);

/* ============================================
 * Array operations
 * ============================================ */

/* SV** result_var = av_fetch(av, index, 0); */
void xs_jit_av_fetch(pTHX_ XS_JIT_Builder* b, const char* av, const char* index, const char* result_var);

/* av_store(av, index, value); */
void xs_jit_av_store(pTHX_ XS_JIT_Builder* b, const char* av, const char* index, const char* value);

/* av_push(av, value); */
void xs_jit_av_push(pTHX_ XS_JIT_Builder* b, const char* av, const char* value);

/* I32 result_var = av_len(av); */
void xs_jit_av_len(pTHX_ XS_JIT_Builder* b, const char* av, const char* result_var);

/* ============================================
 * SV creation
 * ============================================ */

/* SV* result_var = newSViv(value); */
void xs_jit_new_sv_iv(pTHX_ XS_JIT_Builder* b, const char* result_var, const char* value);

/* SV* result_var = newSVnv(value); */
void xs_jit_new_sv_nv(pTHX_ XS_JIT_Builder* b, const char* result_var, const char* value);

/* SV* result_var = newSVpvn("str", len); */
void xs_jit_new_sv_pv(pTHX_ XS_JIT_Builder* b, const char* result_var, const char* str, STRLEN len);

/* sv = sv_2mortal(sv); */
void xs_jit_mortal(pTHX_ XS_JIT_Builder* b, const char* sv);

/* ============================================
 * Type checking
 * ============================================ */

/* Check items count, croak with usage if wrong. max=-1 means no upper limit */
void xs_jit_check_items(pTHX_ XS_JIT_Builder* b, int min, int max, const char* usage);

/* if (!SvOK(sv)) croak(error_msg); */
void xs_jit_check_defined(pTHX_ XS_JIT_Builder* b, const char* sv, const char* error_msg);

/* Check reference type (SVt_PVHV, SVt_PVAV, etc.) */
void xs_jit_check_ref_type(pTHX_ XS_JIT_Builder* b, const char* sv, const char* type, const char* error_msg);

/* Check for hashref */
void xs_jit_check_hashref(pTHX_ XS_JIT_Builder* b, const char* sv, const char* error_msg);

/* Check for arrayref */
void xs_jit_check_arrayref(pTHX_ XS_JIT_Builder* b, const char* sv, const char* error_msg);

/* ============================================
 * SV conversion (extract values from SV)
 * ============================================ */

/* IV result_var = SvIV(sv); */
void xs_jit_sv_to_iv(pTHX_ XS_JIT_Builder* b, const char* result_var, const char* sv);

/* UV result_var = SvUV(sv); */
void xs_jit_sv_to_uv(pTHX_ XS_JIT_Builder* b, const char* result_var, const char* sv);

/* NV result_var = SvNV(sv); */
void xs_jit_sv_to_nv(pTHX_ XS_JIT_Builder* b, const char* result_var, const char* sv);

/* const char* result_var = SvPV(sv, len_var); len_var can be NULL */
void xs_jit_sv_to_pv(pTHX_ XS_JIT_Builder* b, const char* result_var, const char* len_var, const char* sv);

/* int result_var = SvTRUE(sv); */
void xs_jit_sv_to_bool(pTHX_ XS_JIT_Builder* b, const char* result_var, const char* sv);

/* ============================================
 * Return helpers
 * ============================================ */

/* ST(0) = sv_2mortal(newSViv(value)); XSRETURN(1); */
void xs_jit_return_iv(pTHX_ XS_JIT_Builder* b, const char* value);

/* ST(0) = sv_2mortal(newSVuv(value)); XSRETURN(1); */
void xs_jit_return_uv(pTHX_ XS_JIT_Builder* b, const char* value);

/* ST(0) = sv_2mortal(newSVnv(value)); XSRETURN(1); */
void xs_jit_return_nv(pTHX_ XS_JIT_Builder* b, const char* value);

/* ST(0) = sv_2mortal(newSVpvn(str, len)); XSRETURN(1); */
void xs_jit_return_pv(pTHX_ XS_JIT_Builder* b, const char* str, const char* len);

/* ST(0) = sv; XSRETURN(1); */
void xs_jit_return_sv(pTHX_ XS_JIT_Builder* b, const char* sv);

/* ST(0) = &PL_sv_yes; XSRETURN(1); */
void xs_jit_return_yes(pTHX_ XS_JIT_Builder* b);

/* ST(0) = &PL_sv_no; XSRETURN(1); */
void xs_jit_return_no(pTHX_ XS_JIT_Builder* b);

/* ST(0) = self; XSRETURN(1); */
void xs_jit_return_self(pTHX_ XS_JIT_Builder* b);

/* ============================================
 * Common method patterns
 * ============================================ */

/* Start a method: xs_function + preamble + items check + get_self_hv */
void xs_jit_method_start(pTHX_ XS_JIT_Builder* b, const char* func_name, int min_args, int max_args, const char* usage);

/* Generate a predicate (has_foo) that returns true/false based on attribute */
void xs_jit_predicate(pTHX_ XS_JIT_Builder* b, const char* func_name, const char* attr_name, STRLEN attr_len);

/* Generate a clearer (clear_foo) that deletes an attribute */
void xs_jit_clearer(pTHX_ XS_JIT_Builder* b, const char* func_name, const char* attr_name, STRLEN attr_len);

/* ============================================
 * Error handling
 * ============================================ */

/* croak("message"); */
void xs_jit_croak(pTHX_ XS_JIT_Builder* b, const char* message);

/* warn("message"); */
void xs_jit_warn(pTHX_ XS_JIT_Builder* b, const char* message);

/* ============================================
 * Prebuilt patterns (generate complete code)
 * ============================================ */

/* Generate a complete read-only accessor function */
void xs_jit_ro_accessor(pTHX_ XS_JIT_Builder* b, const char* func_name, const char* attr_name, STRLEN attr_len);

/* Generate a complete read-write accessor function */
void xs_jit_rw_accessor(pTHX_ XS_JIT_Builder* b, const char* func_name, const char* attr_name, STRLEN attr_len);

/* Generate a constructor (attrs is NULL-terminated array) */
void xs_jit_constructor(pTHX_ XS_JIT_Builder* b, const char* func_name, const char* class_name, XS_JIT_Attr* attrs, int num_attrs);

/* Generate a minimal constructor: bless {}, $class */
void xs_jit_new_simple(pTHX_ XS_JIT_Builder* b, const char* func_name);

/* Generate a constructor that accepts either flat hash or hashref args:
 * Class->new(%args) or Class->new(\%args)
 * Copies all provided args into the object */
void xs_jit_new_hash(pTHX_ XS_JIT_Builder* b, const char* func_name);

/* Generate an array-based constructor (Meow-style):
 * Creates a blessed arrayref with specified number of slots */
void xs_jit_new_array(pTHX_ XS_JIT_Builder* b, const char* func_name, int num_slots);

/* Generate a constructor that calls BUILD if it exists */
void xs_jit_new_with_build(pTHX_ XS_JIT_Builder* b, const char* func_name);

/* ============================================
 * Constructor validation
 * ============================================ */

/* Generate a constructor that validates required attributes.
 * required_attrs is array of attr name strings, num_required is count.
 * Croaks if any required attr is missing or undef. */
void xs_jit_new_with_required(pTHX_ XS_JIT_Builder* b, const char* func_name,
                               const char** required_attrs, STRLEN* required_lens,
                               int num_required);

/* Generate a typed read-write accessor.
 * type is one of TYPE_* constants, error_msg is croak message on type failure. */
void xs_jit_rw_accessor_typed(pTHX_ XS_JIT_Builder* b, const char* func_name,
                               const char* attr_name, STRLEN attr_len,
                               int type, const char* error_msg);

/* ============================================
 * Clone methods
 * ============================================ */

/* Generate a shallow clone method for hash-based objects */
void xs_jit_clone_hash(pTHX_ XS_JIT_Builder* b, const char* func_name);

/* Generate a shallow clone method for array-based objects */
void xs_jit_clone_array(pTHX_ XS_JIT_Builder* b, const char* func_name);

/* ============================================
 * Unified constructor & weak refs (Phase 3)
 * ============================================ */

/* Attribute specification for new_complete */
typedef struct {
    const char* name;       /* Attribute name */
    STRLEN      len;        /* Attribute name length */
    int         required;   /* 1 if required, 0 otherwise */
    int         type;       /* TYPE_* constant for validation, 0 for none */
    const char* type_msg;   /* Error message for type failure (NULL = default) */
    int         weak;       /* 1 to weaken stored reference */
    const char* coerce;     /* Coercion method name (NULL = none) */
    STRLEN      coerce_len; /* Coercion method name length */
    int         has_default;/* Which default type: 0=none, 1=iv, 2=nv, 3=pv, 4=av, 5=hv */
    IV          default_iv; /* Default integer value */
    NV          default_nv; /* Default numeric value */
    const char* default_pv; /* Default string value */
    STRLEN      default_pv_len;
} XS_JIT_AttrSpec;

/* Default type constants for has_default field */
#define XS_JIT_DEFAULT_NONE  0
#define XS_JIT_DEFAULT_IV    1
#define XS_JIT_DEFAULT_NV    2
#define XS_JIT_DEFAULT_PV    3
#define XS_JIT_DEFAULT_AV    4
#define XS_JIT_DEFAULT_HV    5

/* Generate a unified constructor with full attribute handling.
 * Handles: required, defaults, types, weak refs, coercion, BUILD.
 * attrs is array of XS_JIT_AttrSpec, num_attrs is count.
 * call_build: 1 to call BUILD if exists, 0 otherwise. */
void xs_jit_new_complete(pTHX_ XS_JIT_Builder* b, const char* func_name,
                          XS_JIT_AttrSpec* attrs, int num_attrs,
                          int call_build);

/* Generate a read-write accessor that auto-weakens stored references */
void xs_jit_rw_accessor_weak(pTHX_ XS_JIT_Builder* b, const char* func_name,
                              const char* attr_name, STRLEN attr_len);

/* Low-level helper: store a value with weak reference */
void xs_jit_hv_store_weak(pTHX_ XS_JIT_Builder* b, const char* hv_name,
                           const char* key, int key_len, const char* value_expr);

/* ============================================
 * Callbacks & Triggers (Phase 4)
 * ============================================ */

/* Low-level: call a coderef with G_DISCARD (fire and forget).
 * cv_expr is a C expression evaluating to CV*, args is array of arg expressions. */
void xs_jit_call_sv(pTHX_ XS_JIT_Builder* b, const char* cv_expr,
                     const char** args, int num_args);

/* Low-level: call a method by name on an object.
 * method_name is the method to call, invocant is the object expression,
 * args is array of additional arg expressions. */
void xs_jit_call_method(pTHX_ XS_JIT_Builder* b, const char* method_name,
                         const char* invocant, const char** args, int num_args);

/* Generate an accessor that calls a trigger method after set.
 * trigger_method is called as $self->$trigger_method($new_value). */
void xs_jit_rw_accessor_trigger(pTHX_ XS_JIT_Builder* b, const char* func_name,
                                 const char* attr_name, STRLEN attr_len,
                                 const char* trigger_method);

/* Generate an accessor with lazy builder.
 * On first access (when attr is undef), calls $self->$builder_method()
 * and caches the result. */
void xs_jit_accessor_lazy_builder(pTHX_ XS_JIT_Builder* b, const char* func_name,
                                   const char* attr_name, STRLEN attr_len,
                                   const char* builder_method);

/* Generate a DESTROY that calls DEMOLISH if it exists. */
void xs_jit_destroy_with_demolish(pTHX_ XS_JIT_Builder* b, const char* func_name);

/* ============================================
 * Control Flow & Extended Patterns (Phase 5)
 * ============================================ */

/* do { ... } while (condition); loop construct */
void xs_jit_do(pTHX_ XS_JIT_Builder* b);
void xs_jit_end_do_while(pTHX_ XS_JIT_Builder* b, const char* condition);

/* Branch on calling context */
void xs_jit_if_list_context(pTHX_ XS_JIT_Builder* b);
void xs_jit_if_scalar_context(pTHX_ XS_JIT_Builder* b);

/* Extend stack for returning multiple values */
void xs_jit_extend_stack(pTHX_ XS_JIT_Builder* b, const char* count_expr);

/* Return multiple values from XS */
void xs_jit_return_list(pTHX_ XS_JIT_Builder* b, const char** values, int num_values);

/* Declare with ternary initialization */
void xs_jit_declare_ternary(pTHX_ XS_JIT_Builder* b, const char* type,
                             const char* name, const char* cond,
                             const char* true_expr, const char* false_expr);

/* Ternary assignment */
void xs_jit_assign_ternary(pTHX_ XS_JIT_Builder* b, const char* var,
                            const char* cond, const char* true_expr,
                            const char* false_expr);

/* Delegate method call to attribute's method */
void xs_jit_delegate_method(pTHX_ XS_JIT_Builder* b, const char* func_name,
                             const char* attr_name, STRLEN attr_len,
                             const char* target_method);

/* ============================================
 * Singleton Pattern (Phase 6)
 * ============================================ */

/* Generate a singleton accessor that returns/creates the single instance.
 * The instance is stored in a package variable $Class::_instance.
 * class_name should be the fully qualified class name. */
void xs_jit_singleton_accessor(pTHX_ XS_JIT_Builder* b, const char* func_name,
                                const char* class_name);

/* Generate a singleton reset method that clears the instance.
 * Next call to singleton_accessor will create a fresh instance. */
void xs_jit_singleton_reset(pTHX_ XS_JIT_Builder* b, const char* func_name,
                             const char* class_name);

/* ============================================
 * Registry Pattern (Phase 7)
 * ============================================ */

/* Add an item to a registry hash stored in an attribute.
 * Usage: $obj->register($key, $value) */
void xs_jit_registry_add(pTHX_ XS_JIT_Builder* b, const char* func_name,
                          const char* registry_attr, STRLEN registry_len);

/* Get an item from the registry by key.
 * Usage: my $value = $obj->get($key) */
void xs_jit_registry_get(pTHX_ XS_JIT_Builder* b, const char* func_name,
                          const char* registry_attr, STRLEN registry_len);

/* Remove an item from the registry.
 * Usage: $obj->unregister($key) */
void xs_jit_registry_remove(pTHX_ XS_JIT_Builder* b, const char* func_name,
                             const char* registry_attr, STRLEN registry_len);

/* Return all items from registry (context-aware).
 * List context: returns list of values
 * Scalar context: returns hashref copy */
void xs_jit_registry_all(pTHX_ XS_JIT_Builder* b, const char* func_name,
                          const char* registry_attr, STRLEN registry_len);

/* ============================================
 * Method Modifiers (Phase 8)
 * Wrap methods with before/after/around hooks
 * ============================================ */

/* Generate a wrapper that calls before_cv then original.
 * before_cv receives same args, return value from original preserved. */
void xs_jit_wrap_before(pTHX_ XS_JIT_Builder* b, const char* func_name,
                         const char* orig_name, const char* before_cv_name);

/* Generate a wrapper that calls original then after_cv.
 * after_cv receives same args, return value from original preserved. */
void xs_jit_wrap_after(pTHX_ XS_JIT_Builder* b, const char* func_name,
                        const char* orig_name, const char* after_cv_name);

/* Generate a wrapper with around semantics.
 * around_cv receives $orig as first arg, can call through or skip. */
void xs_jit_wrap_around(pTHX_ XS_JIT_Builder* b, const char* func_name,
                         const char* orig_name, const char* around_cv_name);

/* ============================================
 * Op-based accessors (for array-based objects with inline ops)
 * These are faster than hash-based accessors and can be
 * combined with inline ops for compile-time optimization
 * ============================================ */

/* Generate a read-only op accessor: $obj->[slot] */
void xs_jit_op_ro_accessor(pTHX_ XS_JIT_Builder* b, const char* func_name, IV slot);

/* Generate a read-write op accessor: $obj->[slot] with optional setter */
void xs_jit_op_rw_accessor(pTHX_ XS_JIT_Builder* b, const char* func_name, IV slot);

/* ============================================
 * Custom op builder (for defining arbitrary inline ops)
 * 
 * Usage:
 *   xs_jit_pp_start(b, "my_op");
 *   xs_jit_pp_get_self(b);
 *   xs_jit_line(b, "NV result = ...");
 *   xs_jit_pp_return_nv(b, "result");
 *   xs_jit_pp_end(b);
 * ============================================ */

/* Start a pp (push-pop) function - the runtime part of a custom op */
void xs_jit_pp_start(pTHX_ XS_JIT_Builder* b, const char* name);

/* End a pp function */
void xs_jit_pp_end(pTHX_ XS_JIT_Builder* b);

/* pp preamble: dSP; */
void xs_jit_pp_dsp(pTHX_ XS_JIT_Builder* b);

/* Get self from top of stack: SV* self = TOPs; */
void xs_jit_pp_get_self(pTHX_ XS_JIT_Builder* b);

/* Pop self from stack: SV* self = POPs; */
void xs_jit_pp_pop_self(pTHX_ XS_JIT_Builder* b);

/* Pop a value: SV* name = POPs; */
void xs_jit_pp_pop_sv(pTHX_ XS_JIT_Builder* b, const char* name);

/* Pop as NV: NV name = POPn; */
void xs_jit_pp_pop_nv(pTHX_ XS_JIT_Builder* b, const char* name);

/* Pop as IV: IV name = POPi; */
void xs_jit_pp_pop_iv(pTHX_ XS_JIT_Builder* b, const char* name);

/* Get array slots from self: SV** ary = AvARRAY((AV*)SvRV(self)); */
void xs_jit_pp_get_slots(pTHX_ XS_JIT_Builder* b);

/* Get slot value: SV* name = ary[slot] ? ary[slot] : &PL_sv_undef; */
void xs_jit_pp_slot(pTHX_ XS_JIT_Builder* b, const char* name, IV slot);

/* Set result and return: SETs(sv); return NORMAL; */
void xs_jit_pp_return_sv(pTHX_ XS_JIT_Builder* b, const char* sv_expr);

/* Return mortal NV: SETs(sv_2mortal(newSVnv(expr))); return NORMAL; */
void xs_jit_pp_return_nv(pTHX_ XS_JIT_Builder* b, const char* nv_expr);

/* Return mortal IV: SETs(sv_2mortal(newSViv(expr))); return NORMAL; */
void xs_jit_pp_return_iv(pTHX_ XS_JIT_Builder* b, const char* iv_expr);

/* Return mortal PV: SETs(sv_2mortal(newSVpv(expr, 0))); return NORMAL; */
void xs_jit_pp_return_pv(pTHX_ XS_JIT_Builder* b, const char* pv_expr);

/* Just return NORMAL; */
void xs_jit_pp_return(pTHX_ XS_JIT_Builder* b);

/* ============================================
 * Call checker builder (compile-time rewriting)
 * ============================================ */

/* Start a call checker function */
void xs_jit_ck_start(pTHX_ XS_JIT_Builder* b, const char* name);

/* End a call checker function */
void xs_jit_ck_end(pTHX_ XS_JIT_Builder* b);

/* Standard call checker preamble - extract args from entersub */
void xs_jit_ck_preamble(pTHX_ XS_JIT_Builder* b);

/* Build and return a UNOP custom op */
void xs_jit_ck_build_unop(pTHX_ XS_JIT_Builder* b, const char* pp_func, const char* targ_expr);

/* Build and return a BINOP custom op */
void xs_jit_ck_build_binop(pTHX_ XS_JIT_Builder* b, const char* pp_func, const char* targ_expr);

/* Return the original entersubop (fallback, no optimization) */
void xs_jit_ck_fallback(pTHX_ XS_JIT_Builder* b);

/* ============================================
 * XOP registration helpers
 * ============================================ */

/* Generate XOP struct and registration code */
void xs_jit_xop_declare(pTHX_ XS_JIT_Builder* b, const char* name, const char* pp_func, const char* desc);

/* Generate cv_set_call_checker_flags call */
void xs_jit_register_checker(pTHX_ XS_JIT_Builder* b, const char* cv_expr, const char* ck_func, const char* ckobj_expr);

/* ============================================
 * Inline op support (compile-time optimization)
 * 
 * Inline ops replace function calls with custom ops at compile time,
 * bypassing XS call overhead entirely. This provides ~2x speedup.
 * 
 * Usage:
 *   CV* cv = get_cv("MyClass::name", 0);
 *   xs_jit_inline_register(aTHX_ cv, XS_JIT_INLINE_GETTER, 0, NULL, 0);
 * ============================================ */

/* Initialize inline op subsystem (safe to call multiple times) */
void xs_jit_inline_init(pTHX);

/* Register an inline op for a CV */
int xs_jit_inline_register(pTHX_ CV* cv, XS_JIT_InlineType type, 
                           IV slot, const char* key, STRLEN key_len);

/* Check if a CV has an inline op registered */
XS_JIT_InlineType xs_jit_inline_get_type(pTHX_ CV* cv);

/* ============================================
 * Type constants for value checking
 * ============================================ */

typedef enum {
    XS_JIT_TYPE_ANY        = 0,   /* No type check */
    XS_JIT_TYPE_DEFINED    = 1,   /* SvOK - defined */
    XS_JIT_TYPE_INT        = 2,   /* SvIOK - integer */
    XS_JIT_TYPE_NUM        = 3,   /* SvNOK - number */
    XS_JIT_TYPE_STR        = 4,   /* SvPOK - string */
    XS_JIT_TYPE_REF        = 5,   /* SvROK - reference */
    XS_JIT_TYPE_ARRAYREF   = 6,   /* SvROK + SVt_PVAV */
    XS_JIT_TYPE_HASHREF    = 7,   /* SvROK + SVt_PVHV */
    XS_JIT_TYPE_CODEREF    = 8,   /* SvROK + SVt_PVCV */
    XS_JIT_TYPE_OBJECT     = 9,   /* sv_isobject */
    XS_JIT_TYPE_BLESSED    = 10   /* sv_isobject with specific class */
} XS_JIT_TypeCheck;

/* ============================================
 * Direct AvARRAY access (Meow-style fast slots)
 * These bypass av_fetch/av_store for maximum speed
 * ============================================ */

/* Get direct array pointer: SV** slots = AvARRAY((AV*)SvRV(self)); */
void xs_jit_av_direct(pTHX_ XS_JIT_Builder* b, const char* result_var, const char* av_expr);

/* Read slot value: SV* val = slots[idx] ? slots[idx] : &PL_sv_undef; */
void xs_jit_av_slot_read(pTHX_ XS_JIT_Builder* b, const char* result_var, 
                          const char* slots_var, IV slot);

/* Write slot value with ref counting */
void xs_jit_av_slot_write(pTHX_ XS_JIT_Builder* b, const char* slots_var, 
                           IV slot, const char* value);

/* ============================================
 * Type checking helpers
 * ============================================ */

/* Generate type check expression (returns condition string) */
const char* xs_jit_type_check_expr(pTHX_ XS_JIT_TypeCheck type, 
                                    const char* sv, const char* classname);

/* Generate full type check with croak on failure */
void xs_jit_check_value_type(pTHX_ XS_JIT_Builder* b, const char* sv, 
                              XS_JIT_TypeCheck type, const char* classname,
                              const char* error_msg);

/* ============================================
 * Lazy initialization accessors
 * ============================================ */

/* Lazy init with //= (defined-or-assign): $self->{attr} //= $default */
void xs_jit_lazy_init_dor(pTHX_ XS_JIT_Builder* b, const char* func_name,
                          const char* attr_name, STRLEN attr_len,
                          const char* default_expr, int is_mortal);

/* Lazy init with ||= (or-assign): $self->{attr} ||= $default */
void xs_jit_lazy_init_or(pTHX_ XS_JIT_Builder* b, const char* func_name,
                         const char* attr_name, STRLEN attr_len,
                         const char* default_expr, int is_mortal);

/* Slot-based lazy init: $self->[slot] //= $default */
void xs_jit_slot_lazy_init_dor(pTHX_ XS_JIT_Builder* b, const char* func_name,
                               IV slot, const char* default_expr, int is_mortal);

/* Slot-based lazy init with ||= */
void xs_jit_slot_lazy_init_or(pTHX_ XS_JIT_Builder* b, const char* func_name,
                              IV slot, const char* default_expr, int is_mortal);

/* ============================================
 * Setter chain patterns
 * ============================================ */

/* Setter that returns $self for chaining: $obj->set_x($v)->set_y($v) */
void xs_jit_setter_chain(pTHX_ XS_JIT_Builder* b, const char* func_name,
                         const char* attr_name, STRLEN attr_len);

/* Slot-based setter chain */
void xs_jit_slot_setter_chain(pTHX_ XS_JIT_Builder* b, const char* func_name, IV slot);

/* Setter that returns the value set: my $v = $obj->set_x(5) */
void xs_jit_setter_return_value(pTHX_ XS_JIT_Builder* b, const char* func_name,
                                 const char* attr_name, STRLEN attr_len);

/* ============================================
 * Array attribute operations (push, pop, etc.)
 * ============================================ */

/* push @{$self->{attr}}, @values */
void xs_jit_attr_push(pTHX_ XS_JIT_Builder* b, const char* func_name,
                      const char* attr_name, STRLEN attr_len);

/* pop @{$self->{attr}} */
void xs_jit_attr_pop(pTHX_ XS_JIT_Builder* b, const char* func_name,
                     const char* attr_name, STRLEN attr_len);

/* shift @{$self->{attr}} */
void xs_jit_attr_shift(pTHX_ XS_JIT_Builder* b, const char* func_name,
                       const char* attr_name, STRLEN attr_len);

/* unshift @{$self->{attr}}, @values */
void xs_jit_attr_unshift(pTHX_ XS_JIT_Builder* b, const char* func_name,
                         const char* attr_name, STRLEN attr_len);

/* scalar @{$self->{attr}} */
void xs_jit_attr_count(pTHX_ XS_JIT_Builder* b, const char* func_name,
                       const char* attr_name, STRLEN attr_len);

/* @{$self->{attr}} = () */
void xs_jit_attr_clear(pTHX_ XS_JIT_Builder* b, const char* func_name,
                       const char* attr_name, STRLEN attr_len);

/* ============================================
 * Conditional DSL (Struct::Conditional format)
 * ============================================ */

/* Expression types for conditional DSL */
typedef enum {
    XS_JIT_EXPR_NONE   = 0,
    XS_JIT_EXPR_EQ     = 1,   /* string equality: strEQ() */
    XS_JIT_EXPR_NE     = 2,   /* string not equal: !strEQ() */
    XS_JIT_EXPR_GT     = 3,   /* numeric greater than: > */
    XS_JIT_EXPR_LT     = 4,   /* numeric less than: < */
    XS_JIT_EXPR_GTE    = 5,   /* numeric >= */
    XS_JIT_EXPR_LTE    = 6,   /* numeric <= */
    XS_JIT_EXPR_M      = 7,   /* regex/substring match */
    XS_JIT_EXPR_IM     = 8,   /* case-insensitive match */
    XS_JIT_EXPR_NM     = 9,   /* not match */
    XS_JIT_EXPR_INM    = 10,  /* case-insensitive not match */
    XS_JIT_EXPR_EXISTS = 11,  /* SvOK check */
    XS_JIT_EXPR_TRUE   = 12   /* SvTRUE check */
} XS_JIT_ExprType;

/* Action types for 'then' blocks */
typedef enum {
    XS_JIT_ACTION_LINE      = 0,  /* raw C line */
    XS_JIT_ACTION_RETURN_SV = 1,  /* return SV expression */
    XS_JIT_ACTION_RETURN_IV = 2,  /* return integer */
    XS_JIT_ACTION_RETURN_NV = 3,  /* return number */
    XS_JIT_ACTION_RETURN_PV = 4,  /* return string */
    XS_JIT_ACTION_CROAK     = 5   /* croak with message */
} XS_JIT_ActionType;

/* Single action in a then block */
typedef struct {
    XS_JIT_ActionType type;
    const char* value;
    STRLEN value_len;
} XS_JIT_Action;

/* A conditional clause (if/elsif/when) */
typedef struct XS_JIT_Clause {
    const char* key;              /* C variable to test */
    XS_JIT_ExprType expr_type;
    const char* expr_value;       /* value to compare against */
    STRLEN expr_value_len;
    XS_JIT_Action* actions;       /* array of actions for 'then' */
    int num_actions;
    struct XS_JIT_Clause* or_clause;   /* chained OR */
    struct XS_JIT_Clause* and_clause;  /* chained AND */
} XS_JIT_Clause;

/* Full conditional structure (if/elsif/else) */
typedef struct {
    XS_JIT_Clause* if_clause;
    XS_JIT_Clause** elsif_clauses;
    int num_elsif;
    XS_JIT_Action* else_actions;
    int num_else_actions;
} XS_JIT_Conditional;

/* Given/when structure (switch-like) */
typedef struct {
    const char* key;              /* C variable to switch on */
    XS_JIT_Clause** when_clauses;
    int num_when;
    XS_JIT_Action* default_actions;
    int num_default_actions;
} XS_JIT_Given;

/* Generate code from conditional structure */
void xs_jit_conditional(pTHX_ XS_JIT_Builder* b, XS_JIT_Conditional* cond);

/* Generate code from given/when structure */
void xs_jit_given(pTHX_ XS_JIT_Builder* b, XS_JIT_Given* given);

/* Parse a Perl hashref into a conditional clause (for XS bindings) */
XS_JIT_Clause* xs_jit_parse_clause(pTHX_ HV* clause_hv);

/* Parse a Perl structure into actions array */
XS_JIT_Action* xs_jit_parse_actions(pTHX_ SV* then_sv, int* num_actions);

/* Free a conditional structure */
void xs_jit_free_conditional(pTHX_ XS_JIT_Conditional* cond);

/* Free a given structure */
void xs_jit_free_given(pTHX_ XS_JIT_Given* given);

/* Free a clause (recursive) */
void xs_jit_free_clause(pTHX_ XS_JIT_Clause* clause);

/* Free actions array */
void xs_jit_free_actions(pTHX_ XS_JIT_Action* actions, int num_actions);

/* ============================================
 * Switch Statement (Optimized multi-branch)
 * ============================================ */

/* Switch structure - optimized multi-branch conditional on single key */
typedef struct {
    const char* key;              /* C variable to switch on */
    XS_JIT_Clause** cases;        /* array of case clauses */
    int num_cases;
    XS_JIT_Action* default_actions;
    int num_default_actions;
} XS_JIT_Switch;

/* Generate optimized switch code.
 * Auto-detects if all cases use same type (string/numeric) and applies:
 * - String ops: caches SvPV once, uses memEQ with length check
 * - Numeric ops: caches SvIV once
 * - Mixed ops: falls back to standard condition building */
void xs_jit_switch(pTHX_ XS_JIT_Builder* b, XS_JIT_Switch* sw);

/* Free a switch structure */
void xs_jit_free_switch(pTHX_ XS_JIT_Switch* sw);

/* ============================================
 * Enum Generation
 * ============================================ */

/* Enum value descriptor */
typedef struct {
    const char* name;   /* Value name (e.g., "RED") */
    STRLEN name_len;
} XS_JIT_EnumValue;

/* Enum options */
typedef struct {
    IV start;           /* Starting value (default 0) */
    const char* prefix; /* Prefix for constants (default: uc(name) . "_") */
    STRLEN prefix_len;
} XS_JIT_EnumOpts;

/* Generate enum XS functions:
 * - <prefix><VALUE> constant functions for each value
 * - is_valid_<name>($val) - returns true if value is valid
 * - <name>_name($val) - returns string name for numeric value
 *
 * Parameters:
 * - name: Enum type name (e.g., "Color")
 * - values: Array of enum value descriptors
 * - num_values: Number of values
 * - opts: Optional configuration (can be NULL for defaults)
 */
void xs_jit_enum(pTHX_ XS_JIT_Builder* b, const char* name,
                 XS_JIT_EnumValue* values, int num_values,
                 XS_JIT_EnumOpts* opts);

/* ============================================
 * Memoization
 * ============================================ */

/* Memoization options */
typedef struct {
    const char* cache_attr;  /* Attribute name for cache (default: "_memoize_cache") */
    STRLEN cache_attr_len;
    IV ttl;                  /* Time-to-live in seconds (0 = no TTL) */
} XS_JIT_MemoizeOpts;

/* Generate memoized wrapper function and cache clearer:
 * - <func_name>_memoized - Wrapper that caches results
 * - clear_<func_name>_cache - Clears the cache
 *
 * The memoized function:
 * 1. Builds a cache key from all arguments (joined with \x1C)
 * 2. Checks if the key exists in the cache hash
 * 3. If TTL is set, checks if the cached value has expired
 * 4. If not cached/expired, calls _orig_<func_name> and caches result
 * 5. Returns the cached value
 *
 * Parameters:
 * - func_name: Original function name (e.g., "expensive_calc")
 * - opts: Optional configuration (can be NULL for defaults)
 */
void xs_jit_memoize(pTHX_ XS_JIT_Builder* b, const char* func_name,
                    XS_JIT_MemoizeOpts* opts);

/* Get enum function mappings for a package.
 * Returns a new HV* with function mappings:
 * - "${package}::${PREFIX}${VALUE}" => { source => "...", is_xs_native => 1 }
 * - "${package}::is_valid_${name}" => { source => "...", is_xs_native => 1 }
 * - "${package}::${name}_name" => { source => "...", is_xs_native => 1 }
 * Caller owns the returned HV*.
 */
HV* xs_jit_enum_functions(pTHX_ XS_JIT_Builder* b, const char* name,
                          const char* package);

/* Get memoize function mappings for a package.
 * Returns a new HV* with function mappings:
 * - "${package}::${func_name}" => { source => "..._memoized", is_xs_native => 1 }
 * - "${package}::clear_${func_name}_cache" => { source => "...", is_xs_native => 1 }
 * Caller owns the returned HV*.
 */
HV* xs_jit_memoize_functions(pTHX_ XS_JIT_Builder* b, const char* func_name,
                             const char* package);

/* ============================================
 * Role/Mixin Composer
 * ============================================ */

/* Role types */
typedef enum {
    XS_JIT_ROLE_COMPARABLE = 1,   /* compare(), equals(), lt(), gt(), le(), ge() */
    XS_JIT_ROLE_CLONEABLE = 2,    /* clone() */
    XS_JIT_ROLE_SERIALIZABLE = 3, /* TO_JSON(), TO_HASH() */
    XS_JIT_ROLE_OBSERVABLE = 4,   /* add_observer(), remove_observer(), notify_observers() */
} XS_JIT_RoleType;

/* Role options */
typedef struct {
    const char* compare_key;      /* For Comparable: attr to compare (default: "id") */
    STRLEN compare_key_len;
    const char* observers_attr;   /* For Observable: attr to store observers (default: "_observers") */
    STRLEN observers_attr_len;
} XS_JIT_RoleOpts;

/* Generate role methods:
 *
 * Comparable role generates:
 * - compare($other) - returns -1, 0, or 1
 * - equals($other) - returns true if compare == 0
 * - lt($other), gt($other), le($other), ge($other)
 *
 * Cloneable role generates:
 * - clone() - shallow clone of hash-based object
 *
 * Serializable role generates:
 * - TO_JSON() - returns hashref copy (for JSON::XS compatibility)
 * - TO_HASH() - returns hashref copy
 *
 * Observable role generates:
 * - add_observer($callback) - adds callback to observers list
 * - remove_observer($callback) - removes callback from list
 * - notify_observers(@args) - calls all observers with @args
 *
 * Parameters:
 * - role: Role type constant
 * - opts: Optional configuration (can be NULL for defaults)
 */
void xs_jit_role(pTHX_ XS_JIT_Builder* b, XS_JIT_RoleType role,
                 XS_JIT_RoleOpts* opts);

/* ============================================
 * Hash attribute operations
 * ============================================ */

/* keys %{$self->{attr}} */
void xs_jit_attr_keys(pTHX_ XS_JIT_Builder* b, const char* func_name,
                      const char* attr_name, STRLEN attr_len);

/* values %{$self->{attr}} */
void xs_jit_attr_values(pTHX_ XS_JIT_Builder* b, const char* func_name,
                        const char* attr_name, STRLEN attr_len);

/* delete $self->{attr}{$key} */
void xs_jit_attr_delete(pTHX_ XS_JIT_Builder* b, const char* func_name,
                        const char* attr_name, STRLEN attr_len);

/* %{$self->{attr}} = () */
void xs_jit_attr_hash_clear(pTHX_ XS_JIT_Builder* b, const char* func_name,
                            const char* attr_name, STRLEN attr_len);


/* ============================================
 * Convenience macros
 * Assumes 'b' is the builder variable name
 * ============================================ */

#define JIT_FUNC(name)              xs_jit_xs_function(aTHX_ b, name)
#define JIT_PREAMBLE                xs_jit_xs_preamble(aTHX_ b)
#define JIT_END                     xs_jit_xs_end(aTHX_ b)
#define JIT_LINE(...)               xs_jit_line(aTHX_ b, __VA_ARGS__)
#define JIT_RAW(...)                xs_jit_raw(aTHX_ b, __VA_ARGS__)
#define JIT_COMMENT(text)           xs_jit_comment(aTHX_ b, text)
#define JIT_BLANK                   xs_jit_blank(aTHX_ b)

#define JIT_IF(cond)                xs_jit_if(aTHX_ b, cond)
#define JIT_ELSIF(cond)             xs_jit_elsif(aTHX_ b, cond)
#define JIT_ELSE                    xs_jit_else(aTHX_ b)
#define JIT_ENDIF                   xs_jit_endif(aTHX_ b)
#define JIT_FOR(i, c, n)            xs_jit_for(aTHX_ b, i, c, n)
#define JIT_WHILE(cond)             xs_jit_while(aTHX_ b, cond)
#define JIT_ENDLOOP                 xs_jit_endloop(aTHX_ b)

#define JIT_BLOCK_START             xs_jit_block_start(aTHX_ b)
#define JIT_BLOCK_END               xs_jit_block_end(aTHX_ b)

#define JIT_DECLARE(t, n, v)        xs_jit_declare(aTHX_ b, t, n, v)
#define JIT_DECLARE_SV(n, v)        xs_jit_declare_sv(aTHX_ b, n, v)
#define JIT_DECLARE_HV(n, v)        xs_jit_declare_hv(aTHX_ b, n, v)
#define JIT_DECLARE_AV(n, v)        xs_jit_declare_av(aTHX_ b, n, v)
#define JIT_DECLARE_INT(n, v)       xs_jit_declare_int(aTHX_ b, n, v)

#define JIT_SELF                    xs_jit_get_self(aTHX_ b)
#define JIT_SELF_HV                 xs_jit_get_self_hv(aTHX_ b)
#define JIT_SELF_AV                 xs_jit_get_self_av(aTHX_ b)

#define JIT_HV_FETCH(h, k, l, r)    xs_jit_hv_fetch(aTHX_ b, h, k, l, r)
#define JIT_HV_STORE(h, k, l, v)    xs_jit_hv_store(aTHX_ b, h, k, l, v)
#define JIT_HV_FETCH_RET(h, k, l)   xs_jit_hv_fetch_return(aTHX_ b, h, k, l)

#define JIT_AV_FETCH(a, i, r)       xs_jit_av_fetch(aTHX_ b, a, i, r)
#define JIT_AV_STORE(a, i, v)       xs_jit_av_store(aTHX_ b, a, i, v)
#define JIT_AV_PUSH(a, v)           xs_jit_av_push(aTHX_ b, a, v)
#define JIT_AV_LEN(a, r)            xs_jit_av_len(aTHX_ b, a, r)

#define JIT_CROAK(msg)              xs_jit_croak(aTHX_ b, msg)
#define JIT_WARN(msg)               xs_jit_warn(aTHX_ b, msg)
#define JIT_CROAK_USAGE(usage)      xs_jit_croak_usage(aTHX_ b, usage)

#define JIT_CHECK_ITEMS(min, max, u) xs_jit_check_items(aTHX_ b, min, max, u)
#define JIT_CHECK_DEFINED(sv, msg)  xs_jit_check_defined(aTHX_ b, sv, msg)
#define JIT_CHECK_HASHREF(sv, msg)  xs_jit_check_hashref(aTHX_ b, sv, msg)
#define JIT_CHECK_ARRAYREF(sv, msg) xs_jit_check_arrayref(aTHX_ b, sv, msg)

#define JIT_SV_TO_IV(r, sv)         xs_jit_sv_to_iv(aTHX_ b, r, sv)
#define JIT_SV_TO_UV(r, sv)         xs_jit_sv_to_uv(aTHX_ b, r, sv)
#define JIT_SV_TO_NV(r, sv)         xs_jit_sv_to_nv(aTHX_ b, r, sv)
#define JIT_SV_TO_PV(r, l, sv)      xs_jit_sv_to_pv(aTHX_ b, r, l, sv)
#define JIT_SV_TO_BOOL(r, sv)       xs_jit_sv_to_bool(aTHX_ b, r, sv)

#define JIT_RETURN(n)               xs_jit_xs_return(aTHX_ b, n)
#define JIT_RETURN_UNDEF            xs_jit_xs_return_undef(aTHX_ b)
#define JIT_RETURN_IV(v)            xs_jit_return_iv(aTHX_ b, v)
#define JIT_RETURN_UV(v)            xs_jit_return_uv(aTHX_ b, v)
#define JIT_RETURN_NV(v)            xs_jit_return_nv(aTHX_ b, v)
#define JIT_RETURN_PV(s, l)         xs_jit_return_pv(aTHX_ b, s, l)
#define JIT_RETURN_SV(sv)           xs_jit_return_sv(aTHX_ b, sv)
#define JIT_RETURN_YES              xs_jit_return_yes(aTHX_ b)
#define JIT_RETURN_NO               xs_jit_return_no(aTHX_ b)
#define JIT_RETURN_SELF             xs_jit_return_self(aTHX_ b)

#define JIT_METHOD_START(f, min, max, u) xs_jit_method_start(aTHX_ b, f, min, max, u)
#define JIT_PREDICATE(f, a, l)      xs_jit_predicate(aTHX_ b, f, a, l)
#define JIT_CLEARER(f, a, l)        xs_jit_clearer(aTHX_ b, f, a, l)

#define JIT_RO_ACCESSOR(f, a, l)    xs_jit_ro_accessor(aTHX_ b, f, a, l)
#define JIT_RW_ACCESSOR(f, a, l)    xs_jit_rw_accessor(aTHX_ b, f, a, l)

#define JIT_OP_RO(f, s)             xs_jit_op_ro_accessor(aTHX_ b, f, s)
#define JIT_OP_RW(f, s)             xs_jit_op_rw_accessor(aTHX_ b, f, s)

#endif /* XS_JIT_BUILDER_H */
