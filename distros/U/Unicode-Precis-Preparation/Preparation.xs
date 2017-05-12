#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "precis_preparation.h"

/* for Win32 with Visual Studio (MSVC) */
#ifdef _MSC_VER
#  define strcasecmp _stricmp
#endif /* _MSC_VER */

MODULE = Unicode::Precis::Preparation		PACKAGE = Unicode::Precis::Preparation		

int
_classname()
    ALIAS:
	ValidUTF8       = 0
	FreeFormClass   = PRECIS_FREE_FORM_CLASS
	IdentifierClass = PRECIS_IDENTIFIER_CLASS
    CODE:
	RETVAL = ix;
    OUTPUT:
	RETVAL

int
_propname()
    ALIAS:
	UNASSIGNED = PRECIS_UNASSIGNED
	PVALID     = PRECIS_PVALID
	CONTEXTJ   = PRECIS_CONTEXTJ
	CONTEXTO   = PRECIS_CONTEXTO
	DISALLOWED = PRECIS_DISALLOWED
    CODE:
	RETVAL = ix;
    OUTPUT:
	RETVAL

void
_prepare(string, stringclass = 0, unicode_version = 0)
	SV *string
	int stringclass
	int unicode_version
    PROTOTYPE: $;$$
    PREINIT:
	char *buf;
	U8 *err;
	STRLEN buflen, errlen, idx;
	int retval;
	U32 cp;
    PPCODE:
	if (SvOK(string))
	    buf = SvPV(string, buflen);
	else
	    XSRETURN_EMPTY;

	switch (stringclass) {
	case 0:
	case PRECIS_FREE_FORM_CLASS:
	case PRECIS_IDENTIFIER_CLASS:
	    break;
	default:
	    XSRETURN_EMPTY;
	}

	if (unicode_version < 0 || 0xFF < unicode_version)
	    XSRETURN_EMPTY;

	switch (GIMME_V) {
	case G_SCALAR:
	    retval = precis_prepare((U8 *)buf, buflen, stringclass,
		unicode_version, NULL, NULL, NULL, NULL);
	    if (retval != PRECIS_PVALID)
		XSRETURN_EMPTY;
	    XPUSHs(sv_2mortal(newSViv(1)));
	    XSRETURN(1);

	case G_ARRAY:
	    retval = precis_prepare((U8 *)buf, buflen, stringclass,
		unicode_version, &err, &errlen, &idx, &cp);
	    XPUSHs(sv_2mortal(newSVpv("result", 0)));
	    XPUSHs(sv_2mortal(newSViv(retval)));
	    XPUSHs(sv_2mortal(newSVpv("offset", 0)));
	    if (SvUTF8(string))
		XPUSHs(sv_2mortal(newSViv(idx)));
	    else
		XPUSHs(sv_2mortal(newSViv(err - (U8 *)buf)));
	    if (retval == PRECIS_PVALID || errlen == 0)
		XSRETURN(4);

	    XPUSHs(sv_2mortal(newSVpv("length", 0)));
	    if (SvUTF8(string))
		XPUSHs(sv_2mortal(newSViv(1)));
	    else
		XPUSHs(sv_2mortal(newSViv(errlen)));
	    XPUSHs(sv_2mortal(newSVpv("ord", 0)));
	    XPUSHs(sv_2mortal(newSViv(cp)));
	    XSRETURN(8);

	default:
	    XSRETURN_EMPTY;
	}

void
__utf8_on(string)
	SV *string
    PROTOTYPE: $
    PPCODE:
	if (SvOK(string))
	    SvUTF8_on(string);

