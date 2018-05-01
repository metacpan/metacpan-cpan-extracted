#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdint.h>
#include <stdlib.h>

MODULE = Unix::OpenBSD::Random		PACKAGE = Unix::OpenBSD::Random		

PROTOTYPES: ENABLE

uint32_t
arc4random()

uint32_t
arc4random_uniform(upper_bound)
    IV upper_bound
    CODE:
        if (upper_bound < 0 || upper_bound > UINT32_MAX)
            Perl_croak(aTHX_ "upper_bound must be in the uint32_t range");
        RETVAL = arc4random_uniform(upper_bound);
    OUTPUT:
        RETVAL

PROTOTYPES: DISABLE

SV *
arc4random_buf(IV nbytes)
    PROTOTYPE: $
    CODE:
        if (nbytes < 0 || nbytes > SIZE_MAX)
            Perl_croak(aTHX_ "length must be in the size_t range");
        RETVAL = newSVpvn("", 0);
        arc4random_buf(SvGROW(RETVAL, nbytes), nbytes);
        SvCUR_set(RETVAL, nbytes);
        /* if an attacker can control this you probably have other problems */
        SvTAINTED_on(RETVAL);
    OUTPUT:
        RETVAL
