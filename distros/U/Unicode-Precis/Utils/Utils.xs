#include <string.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* Perl <= 5.8.2 */
#ifndef SvIsCOW 
#    define SvIsCOW(sv) (SvREADONLY(sv) && SvFAKE(sv))
#endif
/* Perl <= 5.8.6 */
#ifndef UTF8_MAXBYTES_CASE
#    define UTF8_MAXBYTES_CASE UTF8_MAXLEN_FOLD
#endif
/* See perlguts(1). */
#if PERL_VERSION >= 18
#    define SvTRULYREADONLY(sv) SvREADONLY(sv)
#else
#    define SvTRULYREADONLY(sv) (SvREADONLY(sv) && !SvIsCOW(sv))
#endif

#include "precis_utils.c"

MODULE = Unicode::Precis::Utils		PACKAGE = Unicode::Precis::Utils

int
compareExactly(stringA, stringB)
	SV* stringA
	SV* stringB
    PROTOTYPE: $$
    INIT:
	char *bufA, *bufB;
	STRLEN lenA, lenB;
    CODE:
	if (!SvOK(stringA) || !SvOK(stringB))
	    XSRETURN_UNDEF;

	bufA = SvPV(stringA, lenA);
	bufB = SvPV(stringB, lenB);
	if (lenA != lenB)
	    RETVAL = 0;
	else if (strncmp(bufA, bufB, lenA))
	    RETVAL = 0;
	else
	    RETVAL = 1;
    OUTPUT:
	RETVAL

SV *
_map(string)
	SV *string
    PROTOTYPE: $
    ALIAS:
	foldCase       = 1 
	mapSpace       = 2
	decomposeWidth = 3
    PREINIT:
	char *buf, *new = NULL;
	STRLEN buflen, newlen;
    CODE:
	if (SvOK(string))
	    buf = SvPV(string, buflen);
	else
	    XSRETURN_UNDEF;

	newlen = _map((U8 **)&new, (U8 *)buf, buflen, ix);
	if (new == NULL)
	    XSRETURN_UNDEF;

	if (SvTRULYREADONLY(string)) {
	    RETVAL = newSVpvn(new, newlen);
	    if (SvUTF8(string))
		SvUTF8_on(RETVAL);
	} else {
	    sv_setpvn(string, new, newlen);
	    RETVAL = string;
	    SvREFCNT_inc(string);
	}
	free(new);
    OUTPUT:
	RETVAL
