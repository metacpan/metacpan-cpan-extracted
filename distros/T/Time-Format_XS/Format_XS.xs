#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "format.c"


MODULE = Time::Format_XS		PACKAGE = Time::Format_XS		

SV *
time_format(char *fmt, SV * in_time);
    CODE:
        char *ret = time_format(fmt, in_time);
        RETVAL = newSVpv(ret, 0);
        free(ret);
    OUTPUT:
        RETVAL
