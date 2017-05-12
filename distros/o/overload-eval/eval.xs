#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_sv_2pv_flags
#include "ppport.h"

int is_global() {
    return SvTRUE(get_sv("overload::eval::GLOBAL", 1));
}

OP* (*real_pp_eval)(pTHX);
PP(pp_overload_eval) {
    dSP; dTARG;
    SV* hook;
    SV* sv;
    HV* saved_hh = NULL;
    I32 count, c, ax;

#if ((PERL_VERSION == 13) && (PERL_SUBVERSION >= 7) || (PERL_VERSION > 13))
    hook = cophh_fetch_pvn(PL_curcop->cop_hints_hash, "overload::eval", 14, 0, 0);
#else
    hook = Perl_refcounted_he_fetch( aTHX_ PL_curcop->cop_hints_hash, Nullsv, "overload::eval", 14 /* strlen */, 0, 0);
#endif

    if ( !( is_global() || SvPOK( hook ) ) ) {
        return real_pp_eval(aTHX);
    }

    /* Take the source off the argument stack. */
    if (PL_op->op_private & OPpEVAL_HAS_HH) {
        saved_hh = (HV*) SvREFCNT_inc(POPs);
    }
    sv = POPs;

    /* I'm sure I'm doing this stack stuff the hard way. I'm just not
       confident enough to directly pass the output from the hook
       directly to my caller.

       I may also need to set TARG.
     */

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv);
    PUTBACK;

    count = call_sv( hook, GIMME_V );
    SPAGAIN;
    SP -= count;
    ax = (SP - PL_stack_base) + 1;
    for ( c = 0; c < count; ++c ) {
        SvREFCNT_inc( ST(c) );
    }

    FREETMPS;
    LEAVE;

    EXTEND(SP,count);
    for ( c = 0; c < count; ++c ) {
        PUSHs(sv_2mortal(ST(c)));
    }

    RETURN;
}

MODULE = overload::eval	PACKAGE = overload::eval PREFIX = overload_eval_

PROTOTYPES: ENABLE

void
_install_eval()
    CODE:
        /* Is this a race in threaded perl? */
        real_pp_eval = PL_ppaddr[OP_ENTEREVAL];
        PL_ppaddr[OP_ENTEREVAL] = Perl_pp_overload_eval;
