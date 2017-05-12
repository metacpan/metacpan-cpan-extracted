//--------------------------------------------------------------------
//
//   Win32::ChangeNotify
//   Copyright 1998 by Christopher J. Madsen
//
//   XS file for the Win32::ChangeNotify IPC module
//
//--------------------------------------------------------------------

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* #include "ppport.h" */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

typedef bool TRUEFALSE;

static DWORD
constant(char* name)
{
    errno = 0;
        if (strnNE(name, "FILE_NOTIFY_CHANGE_", 19))
          goto invalid;

	if (strEQ(name+19, "ATTRIBUTES"))
#ifdef FILE_NOTIFY_CHANGE_ATTRIBUTES
	    return FILE_NOTIFY_CHANGE_ATTRIBUTES;
#else
	    goto not_there;
#endif
	if (strEQ(name+19, "DIR_NAME"))
#ifdef FILE_NOTIFY_CHANGE_DIR_NAME
	    return FILE_NOTIFY_CHANGE_DIR_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name+19, "FILE_NAME"))
#ifdef FILE_NOTIFY_CHANGE_FILE_NAME
	    return FILE_NOTIFY_CHANGE_FILE_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name+19, "LAST_WRITE"))
#ifdef FILE_NOTIFY_CHANGE_LAST_WRITE
	    return FILE_NOTIFY_CHANGE_LAST_WRITE;
#else
	    goto not_there;
#endif
	if (strEQ(name+19, "SECURITY"))
#ifdef FILE_NOTIFY_CHANGE_SECURITY
	    return FILE_NOTIFY_CHANGE_SECURITY;
#else
	    goto not_there;
#endif
	if (strEQ(name+19, "SIZE"))
#ifdef FILE_NOTIFY_CHANGE_SIZE
	    return FILE_NOTIFY_CHANGE_SIZE;
#else
	    goto not_there;
#endif

 invalid:
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
} /* end constant */

MODULE = Win32::ChangeNotify	PACKAGE = Win32::ChangeNotify

PROTOTYPES: ENABLE

DWORD
constant(name)
    char *name


HANDLE
_new(className,path,watchsubtree,filter)
    char*  className
    LPCSTR path
    TRUEFALSE   watchsubtree
    DWORD  filter
CODE:
    RETVAL = FindFirstChangeNotificationA(path, watchsubtree, filter);
    if (RETVAL == INVALID_HANDLE_VALUE)
      XSRETURN_UNDEF;
OUTPUT:
    RETVAL


BOOL
reset(handle)
    HANDLE handle
CODE:
    RETVAL = FindNextChangeNotification(handle);
OUTPUT:
    RETVAL


BOOL
close(handle)
    HANDLE handle
CODE:
    if (handle != INVALID_HANDLE_VALUE) {
      RETVAL = FindCloseChangeNotification(handle);
      sv_setiv(SvRV(ST(0)), (IV)INVALID_HANDLE_VALUE);
    } else XSRETURN_UNDEF;
OUTPUT:
    RETVAL


void
DESTROY(handle)
    HANDLE handle
CODE:
    if (handle != INVALID_HANDLE_VALUE)
      FindCloseChangeNotification(handle);
