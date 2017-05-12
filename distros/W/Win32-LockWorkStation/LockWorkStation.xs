#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <windows.h>
#include <winuser.h>

MODULE = Win32::LockWorkStation PACKAGE = Win32::LockWorkStation

PROTOTYPES: DISABLE

int
w32_LockWorkStation(void)
    CODE:
    {
        if (LockWorkStation() == 0)
	    XSRETURN_UNDEF;
        else
            RETVAL = 1;
    }
    OUTPUT:
        RETVAL
