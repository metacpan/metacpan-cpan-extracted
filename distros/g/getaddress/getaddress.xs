#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "QQWry.h"
//#include "ppport.h"

#include "const-c.inc"

MODULE = getaddress		PACKAGE = getaddress		

INCLUDE: const-xs.inc

PROTOTYPES: DISABLE

char* getipwhere (char *filename, char *ip)
	CODE:
	{
		RETVAL = getipwhere (filename, ip);
	}
	OUTPUT:
		RETVAL

