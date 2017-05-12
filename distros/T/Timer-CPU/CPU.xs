#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "cycle.h"



MODULE = Timer::CPU		PACKAGE = Timer::CPU

PROTOTYPES: ENABLE



double
measure_XS(callback)
        SV *callback
    CODE:
        ticks before, after;

        PUSHMARK(sp);

        before = getticks();

        perl_call_sv(callback, G_DISCARD|G_NOARGS);

        after = getticks();

        RETVAL = elapsed(after, before);
    OUTPUT:
        RETVAL
