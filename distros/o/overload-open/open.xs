#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

int is_global() {
    return SvTRUE(get_sv("overload::open::GLOBAL", 1));
}

OP* (*real_pp_open)(pTHX);
PP(pp_overload_open) {
    dSP; dTARG;
    SV* hook;
    SV* sv;
    HV* saved_hh = NULL;
    I32 count, c, ax;
/* hook is what we are calling instead of `open` */
    hook = get_sv("overload::open::GLOBAL", 0);
    int my_debug = 0;
    if ( !SvPOK( hook ) ) {
        return real_pp_open(aTHX);
    }

    if (my_debug) sv_dump(TOPs);
    sv = TOPs;


    ENTER;
    SAVETMPS;
    /* Marking has to do with getting the number of arguments ? maybe. pushmark is start of the arguments */
    PUSHMARK(SP);
    XPUSHs(sv);
    PUTBACK;
    /* SP = Stack Pointer.
     * count is the number of arguments. call calls the function */
    count = call_sv( hook, G_VOID | G_DISCARD );
    if (count) {
        warn("Blah");
    }
    SPAGAIN;
    /* FREETMPS and LEAV *probably* clean up the scope from the call_sv() */
    FREETMPS;
    LEAVE;
    if (my_debug) sv_dump(TOPs);
    return real_pp_open(aTHX);
}

MODULE = overload::open	PACKAGE = overload::open PREFIX = overload_open_

PROTOTYPES: ENABLE

void
_install_open()
    CODE:
        /* Is this a race in threaded perl? */
        real_pp_open = PL_ppaddr[OP_OPEN];
        PL_ppaddr[OP_OPEN] = Perl_pp_overload_open;
