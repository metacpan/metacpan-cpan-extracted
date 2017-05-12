/*
 * Perl extension for the Tiger Hash Function
 *
 * This module by Rafael R. Sevilla <dido@pacific.net.ph> following example
 * of SHA module.
 *
 * This extension may be distributed under either the GPL or the Artistic
 * License.  The Tiger code is GPL.
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "endian.h"
#include "_tiger.h"

typedef TIGER_CONTEXT *Tiger;

MODULE = Tiger PACKAGE = Tiger

PROTOTYPES: DISABLE

Tiger
new(packname = "")
	char *		packname
    CODE:
	{
	    RETVAL = (TIGER_CONTEXT *) safemalloc(sizeof(TIGER_CONTEXT));
	    tiger_init(RETVAL);
	}
    OUTPUT:
	RETVAL

void
DESTROY(context)
	Tiger	context
    CODE:
	{
	    safefree((char *) context);
	}

void
reset(context)
	Tiger	context
    CODE:
	{
	    tiger_init(context);
	}

void
add(context, ...)
	Tiger	context
    CODE:
	{
	    SV *svdata;
	    STRLEN len;
	    unsigned char *data;
	    int i;

	    for (i = 1; i < items; i++) {
		data = (unsigned char *) (SvPV(ST(i), len));
		tiger_update(context, data, len);
	    }
	}

SV *
digest(context)
	Tiger	context
    CODE:
	{
	    unsigned char d_str[24];

	    tiger_final(d_str, context);
	    ST(0) = sv_2mortal(newSVpv(d_str, 24));
	}
