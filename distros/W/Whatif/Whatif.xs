#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


MODULE = Whatif	PACKAGE = Whatif

PROTOTYPES: DISABLE

void
setreadonly(name, value)
  char * name
  int  value
  CODE:
    GV *tmpgv;
    if ((tmpgv = gv_fetchpv(name, TRUE, SVt_PV))) {
        SvREADONLY_off(GvSV(tmpgv));
	sv_setiv(GvSV(tmpgv), value);
        SvREADONLY_on(GvSV(tmpgv));
    }


