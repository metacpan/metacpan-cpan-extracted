#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <unistd.h>

MODULE = Unix::Pledge		PACKAGE = Unix::Pledge		

void
pledge(promises, ...)
    const char *promises
PROTOTYPE: $;$
INIT:
    // Check that if 2nd param provided it is an array ref
    if (items > 1) {
        SvGETMAGIC(ST(1));
        if ((!SvROK(ST(1))) || (SvTYPE(SvRV(ST(1))) != SVt_PVAV))
        {
            croak("unable to pledge: %s", "whitelist parameter must be an array ref");
        }
    }
CODE:
    SSize_t numpaths = 0, n;

    // whitelist provided
    if (items > 1 && (numpaths = av_top_index((AV *)SvRV(ST(1))) >= 0)) {

        const char *wpaths[numpaths+1];

        for (n = 0; n < numpaths; n++) {
            STRLEN l;
            wpaths[n] = SvPV(*av_fetch((AV *)SvRV(ST(1)), n, 0), l);
        }
        wpaths[numpaths] = NULL;

        if (pledge(promises, wpaths) == -1) {
            croak("unable to pledge: %s", strerror(errno));
        }
    }
    // no whitelist provided
    else {
        if (pledge(promises, NULL) == -1) {
            croak("unable to pledge: %s", strerror(errno));
        }
    }
