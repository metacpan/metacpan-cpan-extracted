#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


MODULE = Test::ZeroCopy		PACKAGE = Test::ZeroCopy

PROTOTYPES: ENABLE


unsigned long
get_pv_address(str)
        SV *str
    CODE:
        char *strp;
        size_t len;

        if (!SvPOK(str)) {
          XSRETURN_UNDEF;
        }

        len = SvCUR(str);
        strp = SvPV(str, len);

        RETVAL = (unsigned long) strp;
    OUTPUT:
        RETVAL


unsigned long
get_pv_cur(str)
        SV *str
    CODE:
        size_t len;

        if (!SvPOK(str)) {
          XSRETURN_UNDEF;
        }

        len = SvCUR(str);

        RETVAL = (unsigned long) len;
    OUTPUT:
        RETVAL
