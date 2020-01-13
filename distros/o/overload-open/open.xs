#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#define SAVE_AND_REPLACE_PP_IF_UNSET(real_function, op_to_replace, overload_function, OP_replace_mutex) do {\
    MUTEX_LOCK(&OP_replace_mutex);\
    if (!real_function) {\
        real_function = PL_ppaddr[op_to_replace];\
    }\
    if (PL_ppaddr[op_to_replace] != overload_function) {\
        PL_ppaddr[op_to_replace] = overload_function;\
    }\
    else {\
        /* Would be nice if we could warn here. */\
    }\
    MUTEX_UNLOCK(&OP_replace_mutex);\
} while (0)

#define overload_open_die_with_xs_sub 1
#define overload_open_max_function_pointers 2
OP* (*stuff_array[overload_open_max_function_pointers])(pTHX);
/* Declare function pointers for OP's */
OP* (*real_pp_open)(pTHX) = NULL;
OP* (*real_pp_sysopen)(pTHX) = NULL;

#define overload_open_max_args 99
#ifdef USE_ITHREADS
static perl_mutex OP_OPEN_replace_mutex;
static perl_mutex OP_SYSOPEN_replace_mutex;
#endif

OP * (*real_pp_open)(pTHX);
OP * (*real_pp_sysopen)(pTHX);

OP * overload_allopen(char *opname, char *global, OP* (*real_pp_func)(pTHX)) {
    SV *hook = get_sv(global, 0);
    /* If the hook evaluates as false, we should just call the original
     * function ( AKA overload::open->prehook_open() has not been called yet ) */
    if ( !hook || !SvTRUE( hook ) ) {
        return real_pp_func(aTHX);
    }
    /* Check to make sure we have a coderef */
    if ( !SvROK( hook ) || SvTYPE( SvRV(hook) ) != SVt_PVCV ) {
        warn("override::open expected a code reference, but got something else");
        return real_pp_func(aTHX);
    }
    /* Get the CV* that the reference refers to */
    CV* code_hook = (CV*) SvRV(hook);
    if ( CvISXSUB( code_hook ) ) {
        if ( overload_open_die_with_xs_sub )
            die("overload::open error. Cowardly refusing to hook an XS sub into %s", opname);
        return real_pp_func(aTHX);
    }
    /* CvDEPTH > 0 that means our hook is calling OP_OPEN. This is ok
     * just ensure we direct things to the original function */
    if ( 0 < CvDEPTH( code_hook ) ) {
        return real_pp_func(aTHX);
    }
    ENTER;
        /* Save the temporaries stack */
        SAVETMPS;
            /* sp (stack pointer) is used by some macros we call below. mysp is *ours* */
            SV **sp = PL_stack_sp;
            /* Save the stack pointer location */
            SV **mysp = PL_stack_sp;
            assert((PL_markstack_ptr > PL_markstack) || !"MARK underflow");
            /* DON'T call dMARK... it has unintended side effects.
             * it actually calls POPMARK! sad! */
            /* Initialize mark ourselves instead. */
            SV **mark = PL_stack_base + *PL_markstack_ptr;
            /* Save the number of items (number of arguments) */
            ssize_t myitems = (ssize_t)(sp - PL_stack_base - *PL_markstack_ptr);
            if (myitems < 0) {
                SV *suppress_warnings = get_sv("overload::open::SUPPRESS_WARNINGS", 0);
                if (SvTRUE(suppress_warnings)) {
                }
                else {
                    warn("overload::open internal error. Unable to save arguments, unexpected behavior could also occur in your program.");
                }
            }
            else {
                PUSHMARK(sp);
                    EXTEND(sp, myitems);
                    ssize_t c;
                    for ( c = 0; c < myitems; c++) {
                        /* We are going from last to first */
                        ssize_t i = myitems - 1 - c;
                        mPUSHs( newSVsv(*(mysp - i)) );
                    }
                /*  PL_stack_sp = sp */
                PUTBACK; /* Closing bracket for XSUB arguments */
                I32 count = call_sv( (SV*)code_hook, G_VOID | G_DISCARD );
                /* G_VOID and G_DISCARD should cause us to not ask for any return
                * arguments from the call. */
                if (count) warn("call_sv was not supposed to get any arguments");
                /* The purpose of the macro "SPAGAIN" is to refresh the local copy of
                * the stack pointer. This is necessary because it is possible that
                * the memory allocated to the Perl stack has been reallocated during
                * the *call_pv* call */
                /*  sp = PL_stack_sp */
                SPAGAIN;
            }

        /* FREETMPS cleans up all stuff on the temporaries stack added since SAVETMPS was called */
        FREETMPS;
    LEAVE;
    OP *real_rtrn = real_pp_func(aTHX);
    return real_rtrn;
}

PP(pp_overload_open) {
    return overload_allopen("open", "overload::open::GLOBAL_OPEN", real_pp_open);
}

PP(pp_overload_sysopen) {
    return overload_allopen("sysopen", "overload::open::GLOBAL_SYSOPEN",
        real_pp_sysopen);
}

MODULE = overload::open	PACKAGE = overload::open PREFIX = overload_open_

PROTOTYPES: ENABLE

void
_test_xs_function(...)
    CODE:
        printf("running test xs function\n");

void
_install_open()
    CODE:
        SAVE_AND_REPLACE_PP_IF_UNSET(real_pp_open, OP_OPEN, Perl_pp_overload_open, OP_OPEN_replace_mutex);

void
_install_sysopen()
    CODE:
        SAVE_AND_REPLACE_PP_IF_UNSET(real_pp_sysopen, OP_SYSOPEN, Perl_pp_overload_sysopen, OP_SYSOPEN_replace_mutex);
