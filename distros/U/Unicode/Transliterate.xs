#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "transwrap/transwrap.h"
#include <unicode/urep.h>
#include <unicode/utypes.h>
#include <unicode/utrans.h>
#include <unicode/utf.h>

#define str_eq(s1,s2)  (!strcmp ((s1),(s2)))

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int len, int arg)
{
    errno = EINVAL;
    return 0;
}

MODULE = Unicode::Transliterate		PACKAGE = Unicode::Transliterate		


double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL


char*
_myxs_transliterate(id, dir, string)
    char*    id
    char*    dir
    char*    string
    PREINIT:
	int     direction;
	int     err;
        int*    err_PTR;
    CODE:
	if (str_eq (dir, "REVERSE"))
        {
            direction = UTRANS_REVERSE;
        }
	else
        {
            direction = UTRANS_FORWARD;
        }
	err = 0;
	err_PTR = &err;
        RETVAL = utf8_transliterate_MALLOC (id, direction, string, err_PTR);
    OUTPUT:
        RETVAL


int
_myxs_countAvailableIDs()
    CODE:
        RETVAL = utrans_countAvailableIDs();
    OUTPUT:
        RETVAL


char*
_myxs_getAvailableID(index)
    int index
    PREINIT:
        int   length;
        int   bufferLength;
        char* id; 
    CODE:
        length = utrans_getAvailableID (index, NULL, 0);
        bufferLength = (length + 1) * sizeof (char);
        id = (char*)malloc (bufferLength);
        length = utrans_getAvailableID (index, id, bufferLength);
        RETVAL = id;
    OUTPUT:
        RETVAL
