#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "lib/XS/JIT/xs_jit.h"
#include "lib/XS/JIT/xs_jit_builder.h"

MODULE = XS::JIT  PACKAGE = XS::JIT

PROTOTYPES: DISABLE

int
compile(class, ...)
    SV *class
    PREINIT:
        const char *code = NULL;
        const char *name = NULL;
        const char *cache_dir = NULL;
        int force = 0;
        HV *functions_hv = NULL;
        XS_JIT_Func *functions = NULL;
        int num_functions = 0;
        int i;
        HE *entry;
    CODE:
        PERL_UNUSED_VAR(class);

        /* Parse named arguments */
        if ((items - 1) % 2 != 0) {
            croak("XS::JIT->compile requires key => value pairs");
        }

        for (i = 1; i < items; i += 2) {
            const char *key = SvPV_nolen(ST(i));
            SV *val = ST(i + 1);

            if (strEQ(key, "code")) {
                code = SvPV_nolen(val);
            } else if (strEQ(key, "name")) {
                name = SvPV_nolen(val);
            } else if (strEQ(key, "cache_dir")) {
                if (SvOK(val)) {
                    cache_dir = SvPV_nolen(val);
                }
            } else if (strEQ(key, "force")) {
                force = SvTRUE(val) ? 1 : 0;
            } else if (strEQ(key, "functions")) {
                if (!SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVHV) {
                    croak("XS::JIT->compile: 'functions' must be a hashref");
                }
                functions_hv = (HV*)SvRV(val);
            }
        }

        /* Validate required arguments */
        if (!code) {
            croak("XS::JIT->compile: 'code' is required");
        }
        if (!name) {
            croak("XS::JIT->compile: 'name' is required");
        }
        if (!functions_hv) {
            croak("XS::JIT->compile: 'functions' is required");
        }

        /* Count and allocate functions array */
        num_functions = HvKEYS(functions_hv);
        if (num_functions == 0) {
            croak("XS::JIT->compile: 'functions' must not be empty");
        }

        Newx(functions, num_functions + 1, XS_JIT_Func);

        /* Fill functions array from hash
         * Value can be:
         *   - A simple string: 'Package::func' => 'source_func'
         *   - A hashref: 'Package::func' => { source => 'source_func', is_xs_native => 1 }
         */
        i = 0;
        hv_iterinit(functions_hv);
        while ((entry = hv_iternext(functions_hv)) != NULL) {
            I32 klen;
            const char *target = hv_iterkey(entry, &klen);
            SV *val = hv_iterval(functions_hv, entry);
            const char *source;
            int is_xs_native = 0;

            if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
                /* Hashref with options */
                HV *opts = (HV*)SvRV(val);
                SV **source_sv = hv_fetch(opts, "source", 6, 0);
                SV **native_sv = hv_fetch(opts, "is_xs_native", 12, 0);

                if (!source_sv || !SvOK(*source_sv)) {
                    croak("XS::JIT->compile: function '%s' missing 'source' key", target);
                }
                source = SvPV_nolen(*source_sv);
                if (native_sv && SvTRUE(*native_sv)) {
                    is_xs_native = 1;
                }
            } else {
                /* Simple string value */
                source = SvPV_nolen(val);
            }

            /* Duplicate strings since they might be temporary */
            functions[i].target = savepv(target);
            functions[i].source = savepv(source);
            functions[i].has_varargs = 1;  /* Default to varargs for safety */
            functions[i].is_xs_native = is_xs_native;
            i++;
        }
        functions[i].target = NULL;
        functions[i].source = NULL;
        functions[i].has_varargs = 0;
        functions[i].is_xs_native = 0;

        /* Call the C compile function */
        RETVAL = xs_jit_compile(aTHX_ code, name, functions, num_functions,
                                cache_dir, force);

        /* Clean up */
        for (i = 0; i < num_functions; i++) {
            Safefree((char*)functions[i].target);
            Safefree((char*)functions[i].source);
        }
        Safefree(functions);

    OUTPUT:
        RETVAL

int
is_cached(class, code, name, ...)
    SV *class
    const char *code
    const char *name
    PREINIT:
        const char *cache_dir = NULL;
    CODE:
        PERL_UNUSED_VAR(class);
        if (items > 3 && SvOK(ST(3))) {
            cache_dir = SvPV_nolen(ST(3));
        }
        RETVAL = xs_jit_is_cached(aTHX_ code, name, cache_dir);
    OUTPUT:
        RETVAL

SV *
generate_code(class, code, name, functions_hv)
    SV *class
    const char *code
    const char *name
    HV *functions_hv
    PREINIT:
        XS_JIT_Func *functions = NULL;
        int num_functions = 0;
        int i;
        HE *entry;
        char *generated;
    CODE:
        PERL_UNUSED_VAR(class);

        num_functions = HvKEYS(functions_hv);
        if (num_functions == 0) {
            croak("XS::JIT->generate_code: functions must not be empty");
        }

        Newx(functions, num_functions + 1, XS_JIT_Func);

        i = 0;
        hv_iterinit(functions_hv);
        while ((entry = hv_iternext(functions_hv)) != NULL) {
            I32 klen;
            const char *target = hv_iterkey(entry, &klen);
            SV *source_sv = hv_iterval(functions_hv, entry);
            const char *source = SvPV_nolen(source_sv);

            functions[i].target = savepv(target);
            functions[i].source = savepv(source);
            functions[i].has_varargs = 1;
            functions[i].is_xs_native = 0;
            i++;
        }
        functions[i].target = NULL;
        functions[i].source = NULL;
        functions[i].has_varargs = 0;
        functions[i].is_xs_native = 0;

        generated = xs_jit_generate_code(aTHX_ code, name, functions, num_functions);

        for (i = 0; i < num_functions; i++) {
            Safefree((char*)functions[i].target);
            Safefree((char*)functions[i].source);
        }
        Safefree(functions);

        if (generated) {
            RETVAL = newSVpv(generated, 0);
            free(generated);
        } else {
            RETVAL = &PL_sv_undef;
        }
    OUTPUT:
        RETVAL
        