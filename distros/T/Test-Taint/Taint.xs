#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

MODULE = Test::Taint               PACKAGE = Test::Taint

void
_taint(...)

    CODE:

        IV i;
        for (i = 0; i < items; i++)
            SvTAINTED_on(ST(i));
