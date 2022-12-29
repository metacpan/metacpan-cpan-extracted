#ifndef P5_WASM_WASMER_H
#define P5_WASM_WASMER_H 1

#include <stdlib.h>
#include <string.h>

typedef size_t usize;

#define WASI_CLASS "Wasm::Wasmer::WASI"

#define EXTERN_CLASS "Wasm::Wasmer::Extern"
#define GLOBAL_CLASS "Wasm::Wasmer::Global"
#define MEMORY_CLASS "Wasm::Wasmer::Memory"
#define TABLE_CLASS "Wasm::Wasmer::Table"
#define FUNCTION_CLASS "Wasm::Wasmer::Function"

#define P5_WASM_WASMER_INSTANCE_CLASS "Wasm::Wasmer::Instance"

#define _IN_GLOBAL_DESTRUCTION (PL_dirty)

#define warn_destruct_if_needed(sv, startpid) STMT_START { \
    if (_IN_GLOBAL_DESTRUCTION && (getpid() == startpid)) warn( \
        "%" SVf " destroyed at global destruction; memory leak likely!", \
        sv \
    ); \
} STMT_END

typedef struct {
    wasm_externkind_t kind;
    const char* description;
} my_export_description_t;

static my_export_description_t export_descriptions[] = {
    { .kind = WASM_EXTERN_FUNC, .description = "function" },
    { .kind = WASM_EXTERN_GLOBAL, .description = "global" },
    { .kind = WASM_EXTERN_MEMORY, .description = "memory" },
    { .kind = WASM_EXTERN_TABLE, .description = "table" },
};

static inline const char* get_externkind_description(wasm_externkind_t kind) {
    unsigned total = sizeof(export_descriptions) / sizeof(my_export_description_t);
    for (unsigned t=0; t<total; t++) {
        if (kind == export_descriptions[t].kind) {
            return export_descriptions[t].description;
        }
    }

    assert(0 && "No description for extern type?!?");
    return NULL;    // silence compiler warning
}

static inline SV* ptr_to_svrv (pTHX_ void* ptr, HV* stash) {
    SV* referent = newSVuv( PTR2UV(ptr) );
    SV* retval = newRV_noinc(referent);
    sv_bless(retval, stash);

    return retval;
}

static inline void* svrv_to_ptr (pTHX_ SV *self_sv) {
    SV *referent = SvRV(self_sv);
    return INT2PTR(void*, SvUV(referent));
}

void croak_if_non_null_not_derived (pTHX_ SV *obj, const char* classname) {
    if (obj && !sv_derived_from(obj, classname)) {
        croak("Give a %s instance, or nothing. (Gave: %" SVf ")", classname, obj);
    }
}

#define WW_sv_eq_str(sv, str) (         \
    (SvCUR(sv) == strlen(str))          \
    && strEQ(SvPVbyte_nolen(sv), str)   \
)

#define WW_croak_bad_input_name(sv) \
    croak("Unrecognized input: %" SVf, sv);

#define WW_croak_bad_input_value(name, sv) \
    croak("Unrecognized `%s` value: %" SVf, name, sv);

#define _WASMER_HAS_ERROR (wasmer_last_error_length() > 0)

#define _croak_if_wasmer_error(prefix, ...)      \
    int wasmer_errlen = wasmer_last_error_length();     \
    if (wasmer_errlen > 0) {                            \
        char msg[wasmer_errlen];                        \
        wasmer_last_error_message(msg, wasmer_errlen);  \
                                                        \
        croak(prefix ": %.*s", ##__VA_ARGS__, wasmer_errlen, msg); \
    }

#define _croak_wasmer_error(prefix, ...) STMT_START {       \
    _croak_if_wasmer_error(prefix, ##__VA_ARGS__);          \
    croak(prefix " (no Wasmer error?!?)", ##__VA_ARGS__);   \
} STMT_END

void _croak_if_trap (pTHX_ wasm_trap_t* trap) {
    if (trap != NULL) {
        wasm_name_t message;
        wasm_trap_message(trap, &message);

        wasm_frame_t* origin = wasm_trap_origin(trap);

        SV* err_sv;

        if (origin) {
            err_sv = newSVpvf(
                "Wasmer trap: %.*s (func %u offset %zu)",
                (int) message.size,
                message.data,
                wasm_frame_func_index(origin),
                wasm_frame_func_offset(origin)
            );

            wasm_frame_delete(origin);
        }
        else {
            err_sv = newSVpvf(
                "Wasmer trap: %.*s",
                (int) message.size,
                message.data
            );
        }

        wasm_name_delete(&message);
        wasm_trap_delete(trap);

        // TODO: Exception object so it can contain the trap
        croak_sv(err_sv);
    }
}

static inline UV grok_uv (pTHX_ SV* sv) {
    if (SvUOK(sv)) return SvUV(sv);

    UV myuv = SvUV(sv);

    SV* sv2 = newSVuv(myuv);

    if (sv_eq(sv, sv2)) return myuv;

    croak("`%" SVf "` given where unsigned integer expected!", sv);
}

static inline U32 grok_u32 (pTHX_ SV* sv) {
    UV uv = grok_uv(aTHX_ sv);

    if (uv > U32_MAX) croak("%" UVuf " is too big for u32!", uv);

    return uv;
}

// This really ought to be in Perl’s API, or some standard XS toolkit …
static inline IV grok_iv (pTHX_ SV* sv) {
    if (!SvOK(sv)) croak("Integer expected, not undef");

    if (SvROK(sv)) croak("Integer expected, not reference (%" SVf ")", sv);

    if (SvIOK_notUV(sv)) return SvIV(sv);

    UV myuv;

    if (SvUOK(sv)) {
        myuv = SvUV(sv);
        if (myuv <= IV_MAX) return myuv;

        croak("%" SVf " cannot be signed (max=%" IVdf ")!", sv, IV_MAX);
    }

    STRLEN len;
    const char* str = SvPVbyte(sv, len);

    int flags = grok_number(str, len, &myuv);

    if (!flags || (flags & IS_NUMBER_NAN)) {
        croak("%" SVf " cannot be a number!", sv);
    }

    if (flags & IS_NUMBER_GREATER_THAN_UV_MAX) {
        croak("%" SVf " exceeds numeric limit (%" UVuf ")!", sv, UV_MAX);
    }

    if (!(flags & IS_NUMBER_IN_UV)) {
        croak("%" SVf " cannot be a number!", sv);
    }

    if (flags & IS_NUMBER_NOT_INT) {
        croak("%" SVf " cannot be an integer!", sv);
    }


    if (flags & IS_NUMBER_NEG) {

        // myuv is the absolute value.
        if (-myuv < IV_MIN) {
            croak("%" SVf " is too low to be signed on this system (min=%" IVdf ")!", sv, IV_MIN);
        }

        return -myuv;
    }

    if (myuv > IV_MAX) {
        croak("%" SVf " exceeds this system's maximum signed integer (max=%" IVdf ")!", sv, IV_MAX);
    }

    return myuv;
}

static inline I32 grok_i32 (pTHX_ SV* sv) {
    IV myiv = grok_iv(aTHX_ sv);

    if (myiv > I32_MAX) {
        croak("%" SVf " exceeds i32's maximum (%d)!", sv, I32_MAX);
    }

    if (myiv < I32_MIN) {
        croak("%" SVf " is less than i32's minimum (%d)!", sv, I32_MIN);
    }

    return myiv;
}

#define grok_f_reject_undef(sv) \
    if (!SvOK(sv)) croak("Integer expected, not undef");

#define grok_f_reject_ref(sv) \
    if (SvROK(sv)) croak("Integer expected, not reference (%" SVf ")", sv);

static inline double grok_f64 (pTHX_ SV* sv) {
    grok_f_reject_undef(sv);
    grok_f_reject_ref(sv);

    double mydouble = SvNV(sv);

    if (!SvNOK(sv)) {
        if (SvUOK(sv)) {
            UV uv = (UV) mydouble;
            if (uv != SvUV(sv)) {
                croak("%" SVf " cannot be a 64-bit float!", sv);
            }
        }
        else if (SvIOK(sv)) {
            IV iv = (IV) mydouble;
            if (iv != SvIV(sv)) {
                croak("%" SVf " cannot be a 64-bit float!", sv);
            }
        }
        else {
            const char *str = form("%g", mydouble);
            STRLEN mystrlen = strlen(str);

            STRLEN pvlen;
            const char *svstr = SvPVbyte(sv, pvlen);

            if (pvlen != mystrlen || !memEQ(str, svstr, pvlen)) {
                croak("%" SVf " cannot be a 64-bit float!", sv);
            }
        }
    }

    return mydouble;
}

static inline float grok_f32 (pTHX_ SV* sv) {
    grok_f_reject_undef(sv);
    grok_f_reject_ref(sv);

    float myfloat;

    if (SvNOK(sv)) {
        myfloat = (float) SvNV(sv);
        if (myfloat != SvNV(sv)) {
            croak("%" SVf " cannot be a 32-bit float!", sv);
        }
    }
    else if (SvUOK(sv)) {
        myfloat = (float) SvUV(sv);
        if (myfloat != SvUV(sv)) {
            croak("%" SVf " cannot be a 32-bit float!", sv);
        }
    }
    else if (SvIOK(sv)) {
        myfloat = (float) SvUV(sv);
        if (myfloat != SvIV(sv)) {
            croak("%" SVf " cannot be a 32-bit float!", sv);
        }
    }
    else if (SvOK(sv)) {
        STRLEN pvlen;
        const char *svstr = SvPVbyte(sv, pvlen);

        char *end = (char*) (pvlen + svstr);
        myfloat = strtof(svstr, &end);

        const char *svstr2 = form("%g", myfloat);
        STRLEN mystrlen = strlen(svstr2);

        if (pvlen != mystrlen || !memEQ(svstr, svstr2, pvlen)) {
            croak("%" SVf " cannot be a 32-bit float!", sv);
        }
    }
    else {
        croak("undef cannot be a 64-bit float!");
    }

    return myfloat;
}

#ifndef USE_64_BIT_INT
static_assert(0, "IV is 64-bit");
#endif

#define grok_i64 grok_iv

wasm_val_t grok_wasm_val (pTHX_ wasm_externkind_t kind, SV* given) {
    wasm_val_t ret;

    switch (kind) {
        case WASM_I32:
            ret = (wasm_val_t) WASM_I32_VAL( grok_i32( aTHX_ given ) );
            break;

        case WASM_I64:
            ret = (wasm_val_t) WASM_I64_VAL( grok_i64( aTHX_ given ) );
            break;

        case WASM_F32:
            ret = (wasm_val_t) WASM_F32_VAL( grok_f32( aTHX_ given ) );
            break;

        case WASM_F64:
            ret = (wasm_val_t) WASM_F64_VAL( grok_f64( aTHX_ given ) );
            break;

        default:
            ret = (wasm_val_t) WASM_I32_VAL(0); // silence compiler
            assert(0);
    }

    return ret;
}

static inline SV* ww_val2sv (pTHX_ wasm_val_t* val_p) {
    SV* ret;

    switch (val_p->kind) {
        case WASM_I32:
            ret = newSViv(val_p->of.i32);
            break;

        case WASM_I64:
            ret = newSViv(val_p->of.i64);
            break;

        case WASM_F32:
            ret = newSVnv(val_p->of.f32);
            break;

        case WASM_F64:
            ret = newSVnv(val_p->of.f64);
            break;

        default:
            ret = NULL; // silence compiler warnings
            assert(0 && "bad valtype");
    }

    return ret;
}

#endif
