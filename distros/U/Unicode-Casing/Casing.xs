#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "hook_op_check.h"
#include "hook_op_ppaddr.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
    PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
    (PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

STATIC SV * dispatch = NULL;

STATIC OP *
execute_call_back (pTHX_ OP *op, void *user_data) {

    /* Called at execution time to override the system op.  It just
     * calls _dispatch() and returns its result */

    dSP;
    SV* result;
    int ret;

    ENTER;
    SAVETMPS;

    /* The top of the stack should be the scalar whose case is to be changed.
       Instead of popping and then pushing it, just claim the MARK is before 
       it */
    PUSHMARK(SP - 1);

    /* Add the name of the function this is replacing, 'uc', lcfirst', etc. */
    XPUSHs(sv_2mortal(newSVpv(PL_op_name[op->op_type], 0)));
    PUTBACK;

    if (dispatch == NULL) {
        dispatch = (SV *) get_cv("Unicode::Casing::_dispatch", 0);
    }
    if ((ret = call_sv(dispatch, GIMME_V)) != 1) {
        Perl_croak(aTHX_ "panic: Unicode::Casing::_dispatch returned %d values instead of 1\n", ret);
    }

    SPAGAIN;
    result = POPs;

    SvREFCNT_inc(result);

    FREETMPS;
    LEAVE;

    /* S_fold_constant expects us to return either a
     * temp (from the pad or otherwise) or an immortal,
     * and fails an assertion if we don't. So mark this
     * as a temp.
     */
    SvTEMP_on(result);
    XPUSHs(result);

    RETURN;
}


STATIC
OP *
check_call_back(pTHX_ OP *op, void *user_data) {

    /* Whenever 'op' is encountered in the parse, this function is
     * called.  It adds a hook to call our substitute function at
     * execution time */

    hook_op_ppaddr (op, execute_call_back, user_data);
    return op;
}

STATIC
opcode
opcode_from_name(pTHX_ const char* const name) {

    /* Strict input checking is not done, as this is tightly coupled
        * with Perl code that should do that for us */

    if (*name == 'u') {
        if (strlen(name) > 2) {
            return OP_UCFIRST;
        } else {
            return OP_UC;
        }
    }

#if PERL_VERSION_GE(5,15,8)

    else if (*name == 'f') {
        return OP_FC;
    }

#endif

    else if (strlen(name) > 2) {
        return OP_LCFIRST;
    }

    return OP_LC;
}


MODULE = Unicode::Casing		PACKAGE = Unicode::Casing		


UV
setup(type)
        char * type;

    PROTOTYPE: $
    CODE:

    /* setup() is called to set up function 'type': one of 'uc', 'ucfirst',
     * 'lc', 'lcfirst', or 'fc to be overridden by a user-defined equivalent. */

    /* Set check_call_back() to be called whenever 'op' is
        * encountered in the parse */
    RETVAL = (UV) hook_op_check(opcode_from_name(aTHX_ type),
                                check_call_back,
                                NULL);
    OUTPUT:
        RETVAL

void
teardown(type, id)
        char *type
        UV id;
    CODE:
        hook_op_check_remove(opcode_from_name(aTHX_ type), id);
