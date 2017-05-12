/* File.cpp
 *
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


/* constant function for exporting NT definitions. */
static long constant(char *name)
{
    errno = 0;
    switch (*name) {
    case 'A':
	if (strEQ(name, "ARCHIVE"))
#ifdef FILE_ATTRIBUTE_ARCHIVE
		return FILE_ATTRIBUTE_ARCHIVE;
#else
		goto not_there;
#endif	
	break;
    case 'B':
	break;
    case 'C':
	if (strEQ(name, "COMPRESSED"))
#ifdef FILE_ATTRIBUTE_COMPRESSED
		return FILE_ATTRIBUTE_COMPRESSED;
#else
		goto not_there;
#endif	
	break;
    case 'D':
	if (strEQ(name, "DIRECTORY"))
#ifdef FILE_ATTRIBUTE_DIRECTORY
		return FILE_ATTRIBUTE_DIRECTORY;
#else
		goto not_there;
#endif	
	break;
    case 'E':
	break;
    case 'F':
	break;
    case 'G':
	break;
    case 'H':
	if (strEQ(name, "HIDDEN"))
#ifdef FILE_ATTRIBUTE_HIDDEN
		return FILE_ATTRIBUTE_HIDDEN;
#else
		goto not_there;
#endif	
	break;
    case 'I':
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	break;
    case 'M':
	break;
    case 'N':
	if (strEQ(name, "NORMAL"))
#ifdef FILE_ATTRIBUTE_NORMAL
		return FILE_ATTRIBUTE_NORMAL;
#else
		goto not_there;
#endif	
	break;
    case 'O':
	if (strEQ(name, "OFFLINE"))
#ifdef FILE_ATTRIBUTE_OFFLINE
		return FILE_ATTRIBUTE_OFFLINE;
#else
		goto not_there;
#endif	
	break;
    case 'P':
	break;
    case 'Q':
	break;
    case 'R':
	if (strEQ(name, "READONLY"))
#ifdef FILE_ATTRIBUTE_READONLY
		return FILE_ATTRIBUTE_READONLY;
#else
		goto not_there;
#endif	
	break;
    case 'S':
	if (strEQ(name, "SYSTEM"))
#ifdef FILE_ATTRIBUTE_SYSTEM
		return FILE_ATTRIBUTE_SYSTEM;
#else
		goto not_there;
#endif	
	break;
    case 'T':
	if (strEQ(name, "TEMPORARY"))
#ifdef FILE_ATTRIBUTE_TEMPORARY
		return FILE_ATTRIBUTE_TEMPORARY;
#else
		goto not_there;
#endif	
	break;
    case 'U':
	break;
    case 'V':
	break;
    case 'W':
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

MODULE = Win32::File		PACKAGE = Win32::File

PROTOTYPES: ENABLE

long
constant(name)
	char *name
    CODE:
	RETVAL = constant(name);
    OUTPUT:
	RETVAL

bool
GetAttributes(filename,attribs)
	char *filename
	DWORD attribs = NO_INIT
    CODE:
        attribs = GetFileAttributesA(filename);
	RETVAL = (attribs != 0xffffffff);
    OUTPUT:
	attribs
	RETVAL

bool
SetAttributes(filename,attribs)
	char *filename
	DWORD attribs
    CODE:
        RETVAL = SetFileAttributesA(filename, attribs);
    OUTPUT:
	RETVAL


