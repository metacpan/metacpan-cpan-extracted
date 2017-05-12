/*
 * Source: http://cvs.sourceforge.net/viewcvs.py/tcl/tcl/win/tclWinFile.c?rev=1.12
 * Copyright (c) 1995-1998 Sun Microsystems, Inc.
 * RCS: @(#) $Id: tclWinFile.c,v 1.12 2001/08/23 17:37:08 vincentdarley Exp $
 */

/*

This software is copyrighted by the Regents of the University of
California, Sun Microsystems, Inc., Scriptics Corporation, and
other parties. The following terms apply to all files associated
with the software unless explicitly disclaimed in individual
files.

The authors hereby grant permission to use, copy, modify,
distribute, and license this software and its documentation for
any purpose, provided that existing copyright notices are retained
in all copies and that this notice is included verbatim in any
distributions. No written agreement, license, or royalty fee is
required for any of the authorized uses. Modifications to this
software may be copyrighted by their authors and need not follow
the licensing terms described here, provided that the new terms
are clearly indicated on the first page of each file where they
apply.

IN NO EVENT SHALL THE AUTHORS OR DISTRIBUTORS BE LIABLE TO ANY PARTY
FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
ARISING OUT OF THE USE OF THIS SOFTWARE, ITS DOCUMENTATION, OR ANY
DERIVATIVES THEREOF, EVEN IF THE AUTHORS HAVE BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

THE AUTHORS AND DISTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.  THIS SOFTWARE
IS PROVIDED ON AN "AS IS" BASIS, AND THE AUTHORS AND DISTRIBUTORS HAVE
NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
MODIFICATIONS.

RESTRICTED RIGHTS: Use, duplication or disclosure by the government
is subject to the restrictions as set forth in subparagraph (c) (1) (ii)
of the Rights in Technical Data and Computer Software Clause as DFARS
252.227-7013 and FAR 52.227-19.

*/

#include <windows.h>
#include <winioctl.h>
#include <stdio.h>

/*
 * Declarations for 'link' related information (which may or may
 * not be in the windows headers, and some of which is not very
 * well documented).
 */
#ifndef IO_REPARSE_TAG_RESERVED_ONE
#define IO_REPARSE_TAG_RESERVED_ONE 0x000000001
#endif
#ifndef IO_REPARSE_TAG_RESERVED_RANGE
#define IO_REPARSE_TAG_RESERVED_RANGE 0x000000001
#endif
#ifndef IO_REPARSE_TAG_VALID_VALUES
#define IO_REPARSE_TAG_VALID_VALUES 0x0E000FFFF
#endif
#ifndef IO_REPARSE_TAG_HSM
#define IO_REPARSE_TAG_HSM 0x0C0000004
#endif
#ifndef IO_REPARSE_TAG_NSS
#define IO_REPARSE_TAG_NSS 0x080000005
#endif
#ifndef IO_REPARSE_TAG_NSSRECOVER
#define IO_REPARSE_TAG_NSSRECOVER 0x080000006
#endif
#ifndef IO_REPARSE_TAG_SIS
#define IO_REPARSE_TAG_SIS 0x080000007
#endif
#ifndef IO_REPARSE_TAG_DFS
#define IO_REPARSE_TAG_DFS 0x080000008
#endif

#ifndef IO_REPARSE_TAG_RESERVED_ZERO
#define IO_REPARSE_TAG_RESERVED_ZERO 0x00000000
#endif
#ifndef FILE_FLAG_OPEN_REPARSE_POINT
#define FILE_FLAG_OPEN_REPARSE_POINT 0x00200000
#endif
#ifndef IO_REPARSE_TAG_MOUNT_POINT
#define IO_REPARSE_TAG_MOUNT_POINT 0xA0000003
#endif
#ifndef IsReparseTagValid
#define IsReparseTagValid(x) (!((x)&~IO_REPARSE_TAG_VALID_VALUES)&&((x)>IO_REPARSE_TAG_RESERVED_RANGE))
#endif
#ifndef IO_REPARSE_TAG_SYMBOLIC_LINK
#define IO_REPARSE_TAG_SYMBOLIC_LINK IO_REPARSE_TAG_RESERVED_ZERO
#endif
#define FILE_SPECIAL_ACCESS         (FILE_ANY_ACCESS)
#ifndef FSCTL_SET_REPARSE_POINT
#define FSCTL_SET_REPARSE_POINT     CTL_CODE(FILE_DEVICE_FILE_SYSTEM, 41, METHOD_BUFFERED, FILE_SPECIAL_ACCESS) 
#endif
#ifndef FSCTL_GET_REPARSE_POINT
#define FSCTL_GET_REPARSE_POINT     CTL_CODE(FILE_DEVICE_FILE_SYSTEM, 42, METHOD_BUFFERED, FILE_ANY_ACCESS) 
#endif
#ifndef FSCTL_DELETE_REPARSE_POINT
#define FSCTL_DELETE_REPARSE_POINT  CTL_CODE(FILE_DEVICE_FILE_SYSTEM, 43, METHOD_BUFFERED, FILE_SPECIAL_ACCESS) 
#endif

#define REPARSE_MOUNTPOINT_HEADER_SIZE   8
typedef struct {
    DWORD          ReparseTag;
    DWORD          ReparseDataLength;
    WORD           Dummy;
    WORD           ReparseTargetLength;
    WORD           ReparseTargetMaximumLength;
    WORD           Dummy1;
    WCHAR          ReparseTarget[MAX_PATH*3];
} WIN32_SYMLINK_REPARSE_DATA_BUFFER;

static int 
NativeReadReparse(LinkDirectory, buffer)
    CONST TCHAR* LinkDirectory;   /* The junction to read */
    WIN32_SYMLINK_REPARSE_DATA_BUFFER* buffer;  /* Pointer to buffer. Cannot be NULL */
{
    HANDLE hFile;
    DWORD returnedLength;
   
    hFile = CreateFile(LinkDirectory, GENERIC_READ, 0,
	NULL, OPEN_EXISTING, 
	FILE_FLAG_OPEN_REPARSE_POINT|FILE_FLAG_BACKUP_SEMANTICS, NULL);
    if (hFile == INVALID_HANDLE_VALUE) {
	/* Error creating directory */
	/* TclWinConvertError(GetLastError()); */
	return -1;
    }
    /* Get the link */
    if (!DeviceIoControl(hFile, FSCTL_GET_REPARSE_POINT, NULL, 
			 0, buffer,
			 sizeof(WIN32_SYMLINK_REPARSE_DATA_BUFFER), &returnedLength, NULL)) {	
	/* Error setting junction */
	/* TclWinConvertError(GetLastError()); */
	CloseHandle(hFile);
	return -1;
    }
    CloseHandle(hFile);
    
    if (!IsReparseTagValid(buffer->ReparseTag)) {
	/* Tcl_SetErrno(EINVAL); */
	return -1;
    }
    return 0;
}

#define WIN32_SYMLINK_W2AHELPER_LEN(lpw, wlen, lpa, nChars)\
        (lpa[0] = '\0', WideCharToMultiByte((IN_BYTES) ? CP_ACP : CP_UTF8, 0, \
                                                                   lpw, wlen, (LPSTR)lpa, nChars,NULL,NULL))
#define WIN32_SYMLINK_W2AHELPER(lpw, lpa, nChars) WIN32_SYMLINK_W2AHELPER_LEN(lpw, -1, lpa, nChars)

char *
tclreadlink(LinkDirectory)
    CONST TCHAR* LinkDirectory;
{
    int attr;
    WIN32_SYMLINK_REPARSE_DATA_BUFFER reparseBuffer;
    
    attr = GetFileAttributes(LinkDirectory);
    if (!(attr & FILE_ATTRIBUTE_REPARSE_POINT)) {
	/* Tcl_SetErrno(EINVAL);*/
	return NULL;
    }
    if (NativeReadReparse(LinkDirectory, &reparseBuffer)) {
        return NULL;
    }
    
    switch (reparseBuffer.ReparseTag) {
	case 0x80000000|IO_REPARSE_TAG_SYMBOLIC_LINK: 
	case IO_REPARSE_TAG_SYMBOLIC_LINK: 
	case IO_REPARSE_TAG_MOUNT_POINT: {
	    char *retval;
	    unsigned int len = reparseBuffer.ReparseTargetLength;
	    if (len < 4) return NULL;

	    New('r', retval, len + sizeof(WCHAR), char);
	    WIN32_SYMLINK_W2AHELPER(
		reparseBuffer.ReparseTarget,
		retval,
		len
	    );
	    retval += 4;
	    return retval;
	}
    }
    /*Tcl_SetErrno(EINVAL);*/
    return NULL;
}

