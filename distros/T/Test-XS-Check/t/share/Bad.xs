#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Bad       PACKAGE = Bad

PROTOTYPES: ENABLE

void
bad()
    PREINIT:
        char *str;
        int len = 42;
        SV *sv;

    CODE:
        char *str = Perl_SvPV(sv, len);
