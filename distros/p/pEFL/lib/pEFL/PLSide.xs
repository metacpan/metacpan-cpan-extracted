#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "PLSide.h"

MODULE = pEFL::PLSide		PACKAGE = pEFL::PLSide

void
_free_perl_signal_callback(class, addr)
    SV* class
    SV* addr
PREINIT:
    UV address;
    _perl_signal_cb *data;
CODE:
    address = SvUV(addr);
    data = INT2PTR(_perl_signal_cb*,address);
    if (data == NULL) {
        croak("Could not delete smart callback\n");
    }
    else {
        Safefree(data);
    }
    
void
_free_perl_callback(class, addr)
    SV* class
    SV* addr
PREINIT:
    UV address;
    _perl_callback *data;
CODE:
    address = SvUV(addr);
    data = INT2PTR(_perl_callback*,address);
    if (SvOK(data->funcname)) {
        sv_2mortal(data->funcname);
    }
    
    if (data == NULL) {
        croak("Could not delete smart callback\n");
    }
    else {
        Safefree(data);
    }

void
_free_perl_gendata(class, addr)
    SV* class
    SV* addr
PREINIT:
    UV address;
    _perl_gendata *data;
CODE:
    address = SvUV(addr);
    if (SvTRUE(get_sv("pEFL::Debug",0)))
    	fprintf(stderr,"Freeing gendata with address %"UVuf"\n",address);
    data = INT2PTR(_perl_gendata*,address);
    
    if (data == NULL) {
        croak("Could not delete item's cstruct\n");
    }
    else {
        Safefree(data);
    }

SV*
int2blessedref(addr,pclass)
    IV addr
    SV *pclass
PREINIT:
    void *data;
    SV *ref;
CODE:
    ref = newSV(0);
    data = INT2PTR(void*,addr);
    if (strcmp(SvPV_nolen(pclass),"String") == 0) {
        sv_setpv(ref,(char*) data);
    }
    else {
        sv_setref_pv(ref, SvPV_nolen(pclass), data);
    }
    RETVAL = ref;
 OUTPUT:
    RETVAL

SV*
get_func_name(func_ref)
    SV* func_ref 
PREINIT:
    CV *func;
    SV *name;
CODE:
    name = newSV(0);
    func = (CV*) SvRV(func_ref);
    cv_name(func,name,0);
    RETVAL = name;
OUTPUT:
    RETVAL
