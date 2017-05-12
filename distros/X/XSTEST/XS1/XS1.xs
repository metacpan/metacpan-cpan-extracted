#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#define DESTROY(x)	sv = av_pop(x); printf("ok %d\n", SvIV(sv) );

int ok16() { return 16; } /* Inc3.xsh */
int froybox(int v, int h) { return( v + h ); } /* Inc6.xsh */

MODULE = XSTEST::XS1		PACKAGE = XSTEST::XS1

REQUIRE: 1.931

INCLUDE:  cat Inc1.xsh |

INCLUDE:  Inc4.xsh

PROTOTYPES: ENABLE

void
ok3()
CODE:
printf("ok 3\n");

void
ok4()
	CODE:
	printf("ok 4\n");

BOOT:
	printf("ok 1\n");

PROTOTYPES: DISABLE

void
ok6()
CODE:
	printf("ok 6\n");

BOOT:
	printf("ok 2\n");

VERSIONCHECK: DISABLE
VERSIONCHECK: ENABLE

void
DESTROY(self)
	PREINIT:
	SV *sv;
	INPUT:
	AV *self
	PROTOTYPE: $
	INIT:
	printf("# init\n");

PROTOTYPES: ENABLE

AV *
new1(CLASS,num)
	char *CLASS
	int num
	PROTOTYPE: @
	CODE:
	SV *sv = newSViv( num );
	RETVAL = newAV();
	av_push( RETVAL, sv );
	OUTPUT:
	RETVAL
	CLEANUP:
	# Undo the extra refcount bump from the typemap's newRV.
	SvREFCNT_dec( RETVAL );

int
froxbox(win,v,h)
CASE: sv_isobject(ST(0))
	AV *win
	int v
	int h
	PREINIT:
	SV *sv;
	CODE:
	sv = av_shift( win );
	v += SvIV( sv );
	RETVAL = v + h;
	OUTPUT:
	RETVAL
CASE: SvIOK(ST(0))
	int win
	int v
	int h
	CODE:
	RETVAL = win + v + h;
	OUTPUT:
	RETVAL
CASE:
	CODE:
	RETVAL = 0;
	OUTPUT:
	RETVAL

PROTOTYPES: DISABLE

AV *
new2(CLASS,num)
	INPUT:
	char *CLASS
	PREINIT:
	SV *sv;
	PROTOTYPE: $$
	INPUT:
	SV *num
	CODE:
	sv = newSVsv( num );
	RETVAL = newAV();
	av_push( RETVAL, sv );
	OUTPUT:
	RETVAL
	CLEANUP:
	# Undo the extra refcount bump from the typemap's newRV.
	SvREFCNT_dec( RETVAL );

INCLUDE:  cat Inc2.xsh |

void
twoface(i)
	int i
	ALIAS:
	main::twoface_main = 2
	PPCODE:
	printf("# name (%s)  ix=%d\n", GvNAME(CvGV(cv)), ix );
	printf("ok %d\n", i );

INCLUDE: sed 's/^#//' Inc3.xsh |

