#include "easyxs/easyxs.h"

#include "wasm3/source/wasm3.h"

#include <stdint.h>
#include <inttypes.h>
#include <stdbool.h>

#define PERL_NS "Wasm::Wasm3"
#define PERL_RT_CLASS (PERL_NS "::Runtime")
#define PERL_MODULE_CLASS (PERL_NS "::Module")

#define MAX_UINT32 0xffffffff
#define MAX_MEMSIZE MAX_UINT32

#define _warn_if_global_destruct(self_sv, the_struct) \
    if (PL_dirty && (the_struct->pid == getpid())) { \
        warn("%" SVf " destroyed at global destruction; memory leak likely!", self_sv); \
    }

typedef struct {
    IM3Environment env;
    pid_t pid;
    uint32_t refcount;
} ww3_environ_s;

typedef struct {
    IM3Runtime rt;
    pid_t pid;
    bool any_modules_linked;

    SV* env_sv;
} ww3_runtime_s;

typedef struct {
    IM3Module module;
    pid_t pid;
    const uint8_t* bytes;
    STRLEN len;
    SV* runtime_sv;
} ww3_module_s;

typedef struct {
    SV** coderefs;
    unsigned coderefs_count;

#ifdef MULTIPLICITY
    pTHX;
#endif
} ww3_runtime_userdata_s;

static SV* _create_runtime (pTHX_ const char* classname, SV* stacksize_sv, SV* env_sv) {
    UV stacksize = exs_SvUV(stacksize_sv);
    if (stacksize > 0xffffffff) {
        croak("Stack size (%" UVf ") exceeds max allowed (%u)", stacksize, 0xffffffffU);
    }

    IM3Environment env;

    SvREFCNT_inc(env_sv);

    ww3_environ_s* env_sp = exs_structref_ptr(env_sv);
    env = env_sp->env;

    SV* self_sv = exs_new_structref(ww3_runtime_s, classname);
    ww3_runtime_s* rt_sp = exs_structref_ptr(self_sv);

    ww3_runtime_userdata_s* userdata_p;
    Newxz(userdata_p, 1, ww3_runtime_userdata_s);

#ifdef MULTIPLICITY
    userdata_p->aTHX = aTHX;
#endif

    *rt_sp = (ww3_runtime_s) {
        .rt = m3_NewRuntime(env, stacksize, userdata_p),
        .pid = getpid(),
        .env_sv = env_sv,
    };

    return self_sv;
}

static IM3Global _get_module_sv_global (pTHX_ SV* self_sv, SV* name_sv) {
    const char* name = exs_SvPVutf8_nolen(name_sv);

    ww3_module_s* mod_sp = exs_structref_ptr(self_sv);

    return m3_FindGlobal(mod_sp->module, name);
}

static void _perl_svs_to_wasm3 (pTHX_ SV** svs, unsigned count, M3ValueType* types, uint64_t* vals) {
    for (unsigned a=0; a<count; a++) {
        SV* cur_sv = svs[a];

        void* wasm3_datum_ptr = vals + a;

        switch (types[a]) {
            case c_m3Type_none:
                assert(0 /* c_m3Type_none */);

            case c_m3Type_i32:
                *( (int32_t*) wasm3_datum_ptr ) = SvIV( cur_sv );
                break;

            case c_m3Type_i64:
                *( (int64_t*) wasm3_datum_ptr ) = SvIV( cur_sv );
                break;

            case c_m3Type_f32:
                *( (float*) wasm3_datum_ptr ) = SvNV( cur_sv );
                break;

            case c_m3Type_f64:
                *( (double*) wasm3_datum_ptr ) = SvNV( cur_sv );
                break;

            default:
                assert(0 /* arg type unexpected */);
        }
    }
}

static void _wasm3_to_perl_svs (pTHX_ unsigned count, M3ValueType* types, uint64_t* vals, SV** svs) {

    for (unsigned r=0; r<count; r++) {
        SV* newret;
        void* val_ptr = vals + r;

        switch (types[r]) {
            case c_m3Type_none:
                assert(0 /* c_m3Type_none */);

            case c_m3Type_i32:
                newret = newSViv( *( (int32_t*) val_ptr ) );
                break;

            case c_m3Type_i64:
                newret = newSViv( *( (int64_t*) val_ptr ) );
                break;

            case c_m3Type_f32:
                newret = newSVnv( *( (float*) val_ptr ) );
                break;

            case c_m3Type_f64:
                newret = newSVnv( *( (double*) val_ptr ) );
                break;

            default:
                assert(0 /* arg type unexpected */);
                newret = NULL;  /* silence warning */
        }

        svs[r] = newret;
    }
}

static const void* _call_perl (IM3Runtime runtime, IM3ImportContext _ctx, uint64_t * _sp, void * _mem) {
#ifdef MULTIPLICITY
    ww3_runtime_userdata_s* rt_userdata_p = m3_GetUserData(runtime);
    pTHX = rt_userdata_p->aTHX;
#endif

    IM3Function wasm_func = _ctx->function;
    SV* callback = _ctx->userdata;

    int args_count = m3_GetArgCount(wasm_func);
    int rets_count = m3_GetRetCount(wasm_func);

    SV* arg_svs[1 + args_count];
    arg_svs[args_count] = NULL;

    M3ValueType arg_types[args_count];
    for (unsigned a=0; a<args_count; a++) {
        arg_types[a] = m3_GetArgType(wasm_func, a);
    }

    _wasm3_to_perl_svs(aTHX_ args_count, arg_types, _sp + rets_count, arg_svs);

    SV* err;

    /* Perl auto-frees ret_svs. */
    SV** ret_svs = exs_call_sv_list_trapped(callback, arg_svs, &err);

    const char* errstr = NULL;

    if (ret_svs) {
        int got_count = 0;
        if (ret_svs) {
            SV** p = ret_svs;
            while (*p++) got_count++;
        }

        if (got_count == rets_count) {
            M3ValueType types[got_count];
            for (unsigned r=0; r<got_count; r++) {
                types[r] = m3_GetRetType(wasm_func, r);
            }

            _perl_svs_to_wasm3( aTHX_ ret_svs, got_count, types, _sp );
        }
        else {
            errstr = "Mismatched return values";
        }

        if (ret_svs) {
            while (got_count--) SvREFCNT_dec(ret_svs[got_count]);
        }
    }
    else {
        warn_sv(err);
        errstr = "Perl callback threw exception";
    }

    if (errstr) m3ApiTrap(errstr);

    m3ApiSuccess();
}

#define _WW3_CROAK_IF_NO_MODULE_LOADED(rt_sp) \
    if (!rt_sp->any_modules_linked) croak("Load a module first.")

#define _function_sig_xsub(self_sv, name_sv, counter, getter) STMT_START {   \
    ww3_runtime_s* rt_sp = exs_structref_ptr(self_sv);      \
                                                            \
    const char* name = exs_SvPVutf8_nolen(name_sv);         \
                                                            \
    IM3Function o_function;                                 \
    M3Result res = m3_FindFunction( &o_function, rt_sp->rt, name ); \
    if (res) croak("Failed to find function %s: %s", name, res);    \
                                                            \
    uint32_t count = counter(o_function);       \
                                                            \
    EXTEND(SP, count);                                 \
                                                            \
    for (unsigned a=0; a<count; a++) {                 \
        mPUSHu( getter(o_function, a) );             \
    }                                                       \
                                                            \
    XSRETURN(count);                                   \
} STMT_END

/* ---------------------------------------------------------------------- */

MODULE = Wasm::Wasm3        PACKAGE = Wasm::Wasm3

PROTOTYPES: DISABLE

BOOT:

    /* For compat with pre-5.20 perls we avoid using newCONSTSUB() to create
       a list-constant; instead, `use constant` in Perl: */
    newCONSTSUB(gv_stashpv(PERL_NS, 0), "_M3_VERSION_MAJOR", newSVuv(M3_VERSION_MAJOR));
    newCONSTSUB(gv_stashpv(PERL_NS, 0), "_M3_VERSION_MINOR", newSVuv(M3_VERSION_MINOR));
    newCONSTSUB(gv_stashpv(PERL_NS, 0), "_M3_VERSION_REV", newSVuv(M3_VERSION_REV));

    newCONSTSUB(gv_stashpv(PERL_NS, 0), "M3_VERSION_STRING", newSVpvs(M3_VERSION));
    newCONSTSUB(gv_stashpv(PERL_NS, 0), "TYPE_I32", newSVuv(c_m3Type_i32));
    newCONSTSUB(gv_stashpv(PERL_NS, 0), "TYPE_I64", newSVuv(c_m3Type_i64));
    newCONSTSUB(gv_stashpv(PERL_NS, 0), "TYPE_F32", newSVuv(c_m3Type_f32));
    newCONSTSUB(gv_stashpv(PERL_NS, 0), "TYPE_F64", newSVuv(c_m3Type_f64));

SV*
new (const char* classname)
    CODE:
        SV* env_sv = exs_new_structref(ww3_environ_s, classname);
        ww3_environ_s* env_sp = exs_structref_ptr(env_sv);

        *env_sp = (ww3_environ_s) {
            .env = m3_NewEnvironment(),
            .pid = getpid(),
        };

        RETVAL = env_sv;

    OUTPUT:
        RETVAL

SV*
create_runtime (SV* self_sv, SV* stacksize_sv)
    CODE:
        RETVAL = _create_runtime(aTHX_ PERL_RT_CLASS, stacksize_sv, self_sv);
    OUTPUT:
        RETVAL

SV* parse_module (SV* self_sv, SV* modbytes_sv)
    CODE:
        ww3_environ_s* env_sp = exs_structref_ptr(self_sv);

        STRLEN modlen;
        const char* modbytes_orig = SvPVbyte(modbytes_sv, modlen);

        const uint8_t* modbytes;
        Newx(modbytes, modlen, uint8_t);
        Copy(modbytes_orig, modbytes, modlen, uint8_t);

        IM3Module mod;
        M3Result err = m3_ParseModule(env_sp->env, &mod, modbytes, modlen);

        if (err) {
            Safefree(modbytes);
            croak("%s", err);
        }

        RETVAL = exs_new_structref(ww3_module_s, PERL_MODULE_CLASS);
        ww3_module_s* mod_sp = exs_structref_ptr(RETVAL);

        *mod_sp = (ww3_module_s) {
            .pid = getpid(),
            .bytes = modbytes,
            .len = modlen,
            .module = mod,
        };

    OUTPUT:
        RETVAL

void
DESTROY (SV* self_sv)
    CODE:
        ww3_environ_s* env_sp = exs_structref_ptr(self_sv);

        _warn_if_global_destruct(self_sv, env_sp);

        m3_FreeEnvironment(env_sp->env);

# ----------------------------------------------------------------------

MODULE = Wasm::Wasm3        PACKAGE = Wasm::Wasm3::Runtime

void
get_function_arguments (SV* self_sv, SV* name_sv)
    PPCODE:
        _function_sig_xsub(self_sv, name_sv, m3_GetArgCount, m3_GetArgType);


void
get_function_returns (SV* self_sv, SV* name_sv)
    PPCODE:
        _function_sig_xsub(self_sv, name_sv, m3_GetRetCount, m3_GetRetType);

void
call (SV* self_sv, SV* name_sv, ...)
    PPCODE:
        ww3_runtime_s* rt_sp = exs_structref_ptr(self_sv);

        const char* name = exs_SvPVutf8_nolen(name_sv);

        IM3Function o_function;
        M3Result res = m3_FindFunction( &o_function, rt_sp->rt, name );
        if (res) croak("Failed to find function %s: %s", name, res);

        uint32_t args_count = m3_GetArgCount(o_function);

        int given_args_count = items - 2;
        if (given_args_count != args_count) {
            croak("%s needs %d argument%s; %d given", name, args_count, (args_count > 1) ? "s" : "", given_args_count);
        }

        /*
            List & void contexts are always OK.
            Scalar is OK as long as there aren’t multiple returns.
        */
        uint32_t returns_count = m3_GetRetCount(o_function);
        if (returns_count > 1) {
            if (GIMME_V == G_SCALAR) {
                croak("%s returns %d arguments and so cannot be called in scalar context", name, returns_count);
            }
        }

        void* argptrs[args_count];
        uint64_t args[args_count];
        M3ValueType types[args_count];

        for (unsigned a=0; a<args_count; a++) {
            argptrs[a] = args + a;
            types[a] = m3_GetArgType(o_function, a);
        }

        _perl_svs_to_wasm3( aTHX_ &ST(2), args_count, types, args );

        res = m3_Call( o_function, args_count, (const void **) argptrs );
        if (res) croak("%s(): %s", name, res);

        if (GIMME_V == G_VOID) {
            XSRETURN_EMPTY;
        }
        else {
            void* retptrs[returns_count];
            uint64_t retvals[returns_count];
            M3ValueType rettypes[returns_count];
            for (unsigned r=0; r<returns_count; r++) {
                retvals[r] = 0;
                retptrs[r] = &retvals[r];
                rettypes[r] = m3_GetRetType(o_function, r);
            }

            res = m3_GetResults( o_function, returns_count, (const void **) retptrs );
            if (res) croak("%s (m3_GetResults): %s", name, res);

            SV* ret_svs[returns_count];

            _wasm3_to_perl_svs( aTHX_ returns_count, rettypes, retvals, ret_svs );

            EXTEND(SP, returns_count);

            for (unsigned r=0; r<returns_count; r++) {
                mPUSHs(ret_svs[r]);
            }

            XSRETURN(returns_count);
        }

SV*
load_module (SV* self_sv, SV* module_sv)
    CODE:
        if (!SvROK(module_sv) || !sv_derived_from(module_sv, PERL_MODULE_CLASS)) {
            croak("Need %s instance, not %" SVf, PERL_MODULE_CLASS, module_sv);
        }

        ww3_runtime_s* rt_sp = exs_structref_ptr(self_sv);
        ww3_module_s* mod_sp = exs_structref_ptr(module_sv);

        M3Result res = m3_LoadModule(rt_sp->rt, mod_sp->module);

        if (res) croak("%s", res);

        mod_sp->runtime_sv = SvREFCNT_inc(self_sv);
        rt_sp->any_modules_linked = true;

        RETVAL = SvREFCNT_inc(self_sv);
    OUTPUT:
        RETVAL

SV*
get_memory (SV* self_sv, SV* offset_sv=NULL, SV* wantlen_sv=NULL)
    CODE:
        UV offset = (offset_sv && SvOK(offset_sv)) ? exs_SvUV(offset_sv) : 0;

        ww3_runtime_s* rt_sp = exs_structref_ptr(self_sv);

        _WW3_CROAK_IF_NO_MODULE_LOADED(rt_sp);

        uint32_t memsize;
        uint8_t* mem = m3_GetMemory(rt_sp->rt, &memsize, 0);

        if (offset > memsize) {
            croak("offset (%" UVf ") exceeds memory size (%" PRIu32 ")", offset, memsize);
        }

        UV wantlen = (wantlen_sv && SvOK(wantlen_sv)) ? exs_SvUV(wantlen_sv) : (memsize - offset);

        if (wantlen > (memsize - offset)) {
            wantlen = (memsize - offset);
        }

        RETVAL = newSVpvn((char*) (mem + offset), wantlen);

    OUTPUT:
        RETVAL

SV*
set_memory (SV* self_sv, SV* offset_sv, SV* new_content)
    CODE:
        UV offset = exs_SvUV(offset_sv);
        STRLEN newlen;
        const uint8_t* newbytes = (uint8_t*) SvPVbyte(new_content, newlen);

        ww3_runtime_s* rt_sp = exs_structref_ptr(self_sv);

        _WW3_CROAK_IF_NO_MODULE_LOADED(rt_sp);

        uint32_t memsize;
        uint8_t* mem = m3_GetMemory(rt_sp->rt, &memsize, 0);

        if ((newlen + offset) > memsize) {
            croak("Memory overflow: offset %" UVf " + length %zu = %" UVf ", exceeds %" PRIu32, offset, newlen, offset + newlen, memsize);
        }

        Copy(newbytes, mem + offset, newlen, uint8_t);

        RETVAL = SvREFCNT_inc(self_sv);

    OUTPUT:
        RETVAL

UV
get_memory_size (SV* self_sv)
    CODE:
        ww3_runtime_s* rt_sp = exs_structref_ptr(self_sv);

        _WW3_CROAK_IF_NO_MODULE_LOADED(rt_sp);

        uint32_t memsize = 0;
        m3_GetMemory(rt_sp->rt, &memsize, 0);

        RETVAL = memsize;

    OUTPUT:
        RETVAL

void
DESTROY (SV* self_sv)
    CODE:
        ww3_runtime_s* rt_sp = exs_structref_ptr(self_sv);

        _warn_if_global_destruct(self_sv, rt_sp);

        ww3_runtime_userdata_s* userdata = m3_GetUserData(rt_sp->rt);
        if (userdata) {
            for (unsigned c=0; c < userdata->coderefs_count; c++) {
                SvREFCNT_dec(userdata->coderefs[c]);
            }

            Safefree(userdata->coderefs);
            Safefree(userdata);
        }

        m3_FreeRuntime(rt_sp->rt);

        if (rt_sp->env_sv) SvREFCNT_dec(rt_sp->env_sv);

# ----------------------------------------------------------------------

MODULE = Wasm::Wasm3        PACKAGE = Wasm::Wasm3::Module

const char*
get_name (SV* self_sv)
    CODE:
        ww3_module_s* mod_sp = exs_structref_ptr(self_sv);

        RETVAL = m3_GetModuleName(mod_sp->module);

    OUTPUT:
        RETVAL

SV*
set_name (SV* self_sv, SV* name_sv)
    CODE:
        const char* name = exs_SvPVutf8_nolen(name_sv);

        ww3_module_s* mod_sp = exs_structref_ptr(self_sv);

        m3_SetModuleName(mod_sp->module, name);

        RETVAL = SvREFCNT_inc(self_sv);

    OUTPUT:
        RETVAL

SV*
get_global_type (SV* self_sv, SV* name_sv)
    CODE:
        IM3Global i_global = _get_module_sv_global(aTHX_ self_sv, name_sv);

        if (i_global) {
            RETVAL = newSVuv( m3_GetGlobalType(i_global) );
        }
        else {
            RETVAL = &PL_sv_undef;
        }

    OUTPUT:
        RETVAL

SV*
get_global (SV* self_sv, SV* name_sv)
    CODE:
        IM3Global i_global = _get_module_sv_global(aTHX_ self_sv, name_sv);

        if (i_global) {
            M3TaggedValue tagged;
            M3Result res = m3_GetGlobal(i_global, &tagged);
            if (res) croak("%s", res);

            switch (tagged.type) {
                case c_m3Type_none:
                    croak("Global “%" SVf "” is untyped!", name_sv);

                case c_m3Type_i32:
                    RETVAL = newSViv( tagged.value.i32 );
                    break;

                case c_m3Type_i64:
                    RETVAL = newSViv( tagged.value.i64 );
                    break;

                case c_m3Type_f32:
                    RETVAL = newSVnv( tagged.value.f32 );
                    break;

                case c_m3Type_f64:
                    RETVAL = newSVnv( tagged.value.f64 );
                    break;

                default:
                    croak("Global “%" SVf "” is of unexpected type (%d)!", name_sv, tagged.type);
            }
        }
        else {
            RETVAL = &PL_sv_undef;
        }

    OUTPUT:
        RETVAL

SV*
link_function (SV* self_sv, SV* modname_sv, SV* funcname_sv, SV* signature_sv, SV* coderef)
    CODE:
        const char* modname = exs_SvPVutf8_nolen(modname_sv);
        const char* funcname = exs_SvPVutf8_nolen(funcname_sv);
        const char* signature = exs_SvPVutf8_nolen(signature_sv);

        if (!SvROK(coderef) || (SVt_PVCV != SvTYPE(SvRV(coderef)))) {
            croak("Last argument must be a coderef, not “%" SVf "”", coderef);
        }

        ww3_module_s* mod_sp = exs_structref_ptr(self_sv);

        IM3Runtime rt = m3_GetModuleRuntime(mod_sp->module);
        if (!rt) croak("No runtime set up!");

        ww3_runtime_userdata_s* rt_userdata_p = m3_GetUserData(rt);
        if (rt_userdata_p->coderefs_count) {
            Renew(rt_userdata_p->coderefs, 1 + rt_userdata_p->coderefs_count, SV*);
        }
        else {
            Newx(rt_userdata_p->coderefs, 1, SV*);
        }

        rt_userdata_p->coderefs[rt_userdata_p->coderefs_count] = SvREFCNT_inc(coderef);
        rt_userdata_p->coderefs_count++;

        M3Result res = m3_LinkRawFunctionEx(
            mod_sp->module,
            modname,
            funcname,
            signature,
            _call_perl,
            coderef
        );
        if (res) croak("%s", res);

        RETVAL = SvREFCNT_inc(self_sv);

    OUTPUT:
        RETVAL

SV*
set_global (SV* self_sv, SV* name_sv, SV* value_sv)
    CODE:
        SvGETMAGIC(value_sv);

        if (SvROK(value_sv)) {
            croak("References cannot be WASM global values!");
        }

        IM3Global i_global = _get_module_sv_global(aTHX_ self_sv, name_sv);

        if (!i_global) croak("Global “%" SVf "” not found!", name_sv);

        M3TaggedValue tagged_val = {
            .type = m3_GetGlobalType(i_global),
        };

        switch ( tagged_val.type ) {
            case c_m3Type_none:
                croak("Global “%" SVf "” is untyped!", name_sv);

            case c_m3Type_i32:
                tagged_val.value.i32 = SvIV(value_sv);
                break;

            case c_m3Type_i64:
                tagged_val.value.i64 = SvIV(value_sv);
                break;

            case c_m3Type_f32:
                tagged_val.value.f32 = SvNV(value_sv);
                break;

            case c_m3Type_f64:
                tagged_val.value.f64 = SvNV(value_sv);
                break;

            default:
                croak("Global “%" SVf "” is of unexpected type (%d)!", name_sv, tagged_val.type);
        }

        M3Result res = m3_SetGlobal(i_global, &tagged_val);
        if (res) croak("%s", res);

        RETVAL = SvREFCNT_inc(self_sv);
    OUTPUT:
        RETVAL

void
DESTROY (SV* self_sv)
    CODE:
        ww3_module_s* mod_sp = exs_structref_ptr(self_sv);

        _warn_if_global_destruct(self_sv, mod_sp);

        SV* runtime_sv = mod_sp->runtime_sv;

        if (runtime_sv) {
            SvREFCNT_dec(runtime_sv);
        }
        else {
            Safefree(mod_sp->bytes);
            m3_FreeModule(mod_sp->module);
        }
