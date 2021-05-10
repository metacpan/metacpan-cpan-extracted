#define WINVER 0x0603
#define _WIN32_WINNT 0x0603

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <windows.h>

/*
 * This XS used to have binary compat back to
 * Windows XP / 2003 thru Vista, but support
 * for those operating systems has been ended
 * years and years ago so I am removing it
 * @plicease 5/6/2021
 */

MODULE = Win32::ErrorMode PACKAGE = Win32::ErrorMode

unsigned int
GetErrorMode()
  CODE:
    RETVAL = GetErrorMode();
  OUTPUT:
    RETVAL

unsigned int
SetErrorMode(mode)
    unsigned int mode

unsigned int
GetThreadErrorMode()
  CODE:
    RETVAL = GetThreadErrorMode();
  OUTPUT:
    RETVAL

unsigned int
SetThreadErrorMode(mode)
    unsigned int mode
  PREINIT:
    DWORD old;
    BOOL ok;
  CODE:
    ok = SetThreadErrorMode(mode, &old);
    if(!ok)
      croak("error setting thread error mode");
    RETVAL = old;
  OUTPUT:
    RETVAL

