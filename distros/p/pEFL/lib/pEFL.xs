#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


MODULE = pEFL		PACKAGE = pEFL		

char*
ev_info2s(ev_info)
    SV *ev_info
PREINIT:
    void *event_info;
    IV adress;
CODE:
{
        adress = SvIV(ev_info);
        event_info = INT2PTR(void*,adress);
        RETVAL = (char*) event_info;
}
OUTPUT:
    RETVAL

SV*
ev_info2obj(ev_info,class)
    SV *ev_info
    SV *class
PREINIT:
    void *event_info;
    IV adress;
    SV *pobj;
CODE:
{
        pobj = newSV(0);
        char *c = SvPV_nolen(class);
        adress = SvIV(ev_info);
        event_info = INT2PTR(void*,adress);
        sv_setref_pv(pobj,c, event_info);
        // RETVAL = sv_2mortal(pobj);
        RETVAL = pobj;
}
OUTPUT:
    RETVAL
