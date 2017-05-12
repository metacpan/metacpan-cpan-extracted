#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "unicode_bidirule.c"

MODULE = Unicode::BiDiRule		PACKAGE = Unicode::BiDiRule		

char *
UnicodeVersion()
    PROTOTYPE:
    CODE:
	RETVAL = BIDIRULE_UNICODE_VERSION;
    OUTPUT:
	RETVAL

int
_propname()
    ALIAS:
	BIDIRULE_NOTBIDI = 0
	BIDIRULE_LTR     = BDR_LTR
	BIDIRULE_RTL     = BDR_RTL
	BIDIRULE_INVALID = BDR_INVALID
    CODE:
	RETVAL = ix;
    OUTPUT:
	RETVAL

void
check(string, strict = 1)
	SV *string
	int strict
    PROTOTYPE: $;$
    PREINIT:
	char *buf;
	U8 *err;
	STRLEN buflen, errlen, errulen, idx;
	int retval;
	U32 cp;
    PPCODE:
	if (SvOK(string))
	    buf = SvPV(string, buflen);
	else
	    XSRETURN_EMPTY;

	switch (GIMME_V) {
	case G_SCALAR:
	    retval = bidirule_check((U8 *)buf, buflen,
		NULL, NULL, NULL, NULL, NULL, strict);
	    switch (retval) {
	    case BDR_AVOIDED:
	    case BDR_INVALID:
		XSRETURN_EMPTY;

	    default:
		XPUSHs(sv_2mortal(newSViv(retval)));
		XSRETURN(1);
	    }

	case G_ARRAY:
	    retval = bidirule_check((U8 *)buf, buflen,
		&err, &errlen, &errulen, &idx, &cp, strict);
	    XPUSHs(sv_2mortal(newSVpv("result", 0)));
	    XPUSHs(sv_2mortal(newSViv(
		(retval == BDR_AVOIDED) ? BDR_INVALID : retval)));
	    XPUSHs(sv_2mortal(newSVpv("offset", 0)));
	    if (SvUTF8(string))
		XPUSHs(sv_2mortal(newSViv(idx)));
	    else
		XPUSHs(sv_2mortal(newSViv(err - (U8 *)buf)));
	    if (errlen == 0)
		XSRETURN(4);
	    if (retval != BDR_INVALID && retval != BDR_AVOIDED)
		XSRETURN(4);

	    XPUSHs(sv_2mortal(newSVpv("length", 0)));
	    if (SvUTF8(string))
		XPUSHs(sv_2mortal(newSViv(errulen)));
	    else
		XPUSHs(sv_2mortal(newSViv(errlen)));
	    XPUSHs(sv_2mortal(newSVpv("ord", 0)));
	    XPUSHs(sv_2mortal(newSViv(cp)));
	    if (retval != BDR_AVOIDED)
		XSRETURN(8);

	    XPUSHs(sv_2mortal(newSVpv("unsafe", 0)));
	    XPUSHs(sv_2mortal(newSViv(1)));
	    XSRETURN(10);
	default:
	    XSRETURN_EMPTY;
	}

