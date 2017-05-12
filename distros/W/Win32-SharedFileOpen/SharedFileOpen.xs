/*============================================================================
 *
 * SharedFileOpen.xs
 *
 * DESCRIPTION
 *   C and XS portions of Win32::SharedFileOpen module.
 *
 * COPYRIGHT
 *   Copyright (C) 2001-2004, 2006, 2008, 2014 Steve Hay.  All rights reserved.
 *
 * LICENCE
 *   You may distribute under the terms of either the GNU General Public License
 *   or the Artistic License, as specified in the LICENCE file.
 *
 *============================================================================*/

/*============================================================================
 * C CODE SECTION
 *============================================================================*/

#include <fcntl.h>                      /* For the O_* and _O_* flags.        */
#include <io.h>                         /* For close() and umask().           */
#include <share.h>                      /* For the SH_DENY* flags.            */
#include <stdarg.h>                     /* For va_list/va_start()/va_end().   */
#include <stdio.h>                      /* For sprintf().                     */
#include <stdlib.h>                     /* For errno.                         */
#include <string.h>                     /* For strerror().                    */
#include <sys/stat.h>                   /* For the S_* flags.                 */

#define WIN32_LEAN_AND_MEAN             /* To exclude unnecessary headers.    */
#include <windows.h>                    /* For the Win32 API stuff.           */

#define PERL_NO_GET_CONTEXT             /* To get interp context efficiently. */
#define PERLIO_NOT_STDIO 0              /* To allow use of PerlIO and stdio.  */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* We export the O_* flags without the leading "_" with which they are initially
 * named in the Visual C++ and MinGW header files, so make sure that all the
 * names without the leading "_" exist too, *before* we pull in "const-c.inc"
 * below.  (Visual C++ 6.0 omits O_SHORT_LIVED, while MinGW/gcc-3.9 and Borland
 * C++ 5.5.1 omit this and O_RAW.) */
#if (!defined(O_RAW) && defined(_O_RAW))
#  define O_RAW _O_RAW
#endif
#if (!defined(O_SHORT_LIVED) && defined(_O_SHORT_LIVED))
#  define O_SHORT_LIVED _O_SHORT_LIVED
#endif

#include "const-c.inc"

#define MY_CXT_KEY "Win32::SharedFileOpen::_guts" XS_VERSION

typedef struct {
    int saved_errno;
    DWORD saved_error;
    char err_str[BUFSIZ];
} my_cxt_t;

START_MY_CXT

/* Macros to save and restore the value of the standard C library errno variable
 * and the Win32 API last-error code for use when cleaning up before returning
 * failure. */
#define WIN32_SHAREDFILEOPEN_SAVE_ERRS    STMT_START { \
    MY_CXT.saved_errno = errno;                        \
    MY_CXT.saved_error = GetLastError();               \
} STMT_END
#define WIN32_SHAREDFILEOPEN_RESTORE_ERRS STMT_START { \
    errno = MY_CXT.saved_errno;                        \
    SetLastError(MY_CXT.saved_error);                  \
} STMT_END

#define WIN32_SHAREDFILEOPEN_SYS_ERR_STR (strerror(errno))
#define WIN32_SHAREDFILEOPEN_WIN_ERR_STR \
    (Win32SharedFileOpen_StrWinError(aTHX_ aMY_CXT_ GetLastError()))

static bool Win32SharedFileOpen_Fsopen(pTHX_ pMY_CXT_ SV* fh, const char* file,
    const char* mode, int shflag);
static bool Win32SharedFileOpen_Sopen(pTHX_ pMY_CXT_ SV* fh, const char* file,
    int oflag, int shflag, int pmode);
static char *Win32SharedFileOpen_StrWinError(pTHX_ pMY_CXT_ DWORD err_num);
static void Win32SharedFileOpen_SetErrStr(pTHX_ const char *value, ...);

/*
 * Function to emulate the Microsoft C library function _fsopen().
 */

static bool Win32SharedFileOpen_Fsopen(pTHX_ pMY_CXT_ SV* fh, const char* file,
    const char* mode, int shflag)
{
    bool valid;
    DWORD oflag;

    switch (*mode) {
        case 'r':
            oflag = O_RDONLY;
            break;

        case 'w':
            oflag = O_WRONLY | O_CREAT | O_TRUNC;
            break;

        case 'a':
            oflag = O_WRONLY | O_CREAT | O_APPEND;
            break;

        default:
            croak("Invalid mode '%s' for opening file '%s'", mode, file);
            return FALSE;;
    }

    valid = TRUE;
    while (*++mode && valid) {
        switch (*mode) {
            case '+':
                if (oflag & O_RDWR) {
                    valid = FALSE;
                }
                else {
                    oflag |= O_RDWR;
                    oflag &= ~(O_RDONLY | O_WRONLY);
                }
                break;

            case 'b':
                if (oflag & (O_BINARY | O_TEXT))
                    valid = FALSE;
                else
                    oflag |= O_BINARY;
                break;

            case 't':
                if (oflag & (O_BINARY | O_TEXT))
                    valid = FALSE;
                else
                    oflag |= O_TEXT;
                break;

#ifndef __BORLANDC__
            case 'D':
                if (oflag & O_TEMPORARY)
                    valid = FALSE;
                else
                    oflag |= O_TEMPORARY;
                break;

            case 'R':
                if (oflag & (O_RANDOM | O_SEQUENTIAL))
                    valid = FALSE;
                else
                    oflag |= O_RANDOM;
                break;

            case 'S':
                if (oflag & (O_RANDOM | O_SEQUENTIAL))
                    valid = FALSE;
                else
                    oflag |= O_SEQUENTIAL;
                break;

            case 'T':
                if (oflag & O_SHORT_LIVED)
                    valid = FALSE;
                else
                    oflag |= O_SHORT_LIVED;
                break;
#endif

            default:
                valid = FALSE;
                break;
        }
    }

    if (!valid) {
        croak("Invalid mode '%s' for opening file '%s'", mode, file);
        return FALSE;;
    }

    return Win32SharedFileOpen_Sopen(aTHX_ aMY_CXT_ fh, file, (int)oflag,
            shflag, S_IREAD | S_IWRITE);
}

/*
 * Function to emulate the Microsoft C library function _sopen().
 */

static bool Win32SharedFileOpen_Sopen(pTHX_ pMY_CXT_ SV* fh, const char* file,
    int oflag, int shflag, int pmode)
{
    DWORD fa;
    char mode[4];
    int modechars = 0;
    int type;
    DWORD fs;
    SECURITY_ATTRIBUTES sa;
    DWORD fc;
    int umaskval;
    DWORD ffa;
    HANDLE hndl;
    int flag;
    int fd;
    PerlIO *pio_fp;
    IO* io;

    switch (oflag & (O_RDONLY | O_WRONLY | O_RDWR)) {
        case O_RDONLY:
            fa = GENERIC_READ;
            mode[modechars++] = 'r';
            mode[modechars++] = '\0';
            type = IoTYPE_RDONLY;
            break;

        case O_WRONLY:
            fa = GENERIC_WRITE;
            mode[modechars++] = oflag & O_APPEND ? 'a' : 'w';
            mode[modechars++] = '\0';
            type = oflag & O_APPEND ? IoTYPE_APPEND : IoTYPE_WRONLY;
            break;

        case O_RDWR:
            fa = GENERIC_READ | GENERIC_WRITE;
            mode[modechars++] = oflag & O_CREAT ?
                               (oflag & O_APPEND ? 'a' : 'w') : 'r';
            mode[modechars++] = '+';
            mode[modechars++] = '\0';
            type = IoTYPE_RDWR;
            break;

        default:
            croak("Invalid oflag '%d' for opening file '%s'", oflag, file);
            return FALSE;
    }

    switch (shflag) {
        case SH_DENYRW:
            fs = 0;
            break;

        case SH_DENYWR:
            fs = FILE_SHARE_READ;
            break;

        case SH_DENYRD:
            fs = FILE_SHARE_WRITE;
            break;

        case SH_DENYNO:
            fs = FILE_SHARE_READ | FILE_SHARE_WRITE;
            break;

        default:
            croak("Invalid shflag '%d' for opening file '%s'", shflag, file);
            return FALSE;
    }

    sa.nLength = sizeof(sa);
    sa.lpSecurityDescriptor = NULL;

    if (oflag & O_NOINHERIT) {
        sa.bInheritHandle = FALSE;
    }
    else {
        sa.bInheritHandle = TRUE;
    }

    switch (oflag & (O_CREAT | O_EXCL | O_TRUNC)) {
        case 0:
        case O_EXCL:
            fc = OPEN_EXISTING;
            break;

        case O_CREAT:
            fc = OPEN_ALWAYS;
            break;

        case O_CREAT | O_EXCL:
        case O_CREAT | O_TRUNC | O_EXCL:
            fc = CREATE_NEW;
            break;

        case O_TRUNC:
        case O_TRUNC | O_EXCL:
            fc = TRUNCATE_EXISTING;
            break;

        case O_CREAT | O_TRUNC:
            fc = CREATE_ALWAYS;
            break;

        default:
            croak("Invalid oflag '%d' for opening file '%s'", oflag, file);
            return FALSE;
    }

    umaskval = umask(0);
    umask(umaskval);
    if ((oflag & O_CREAT) && !((pmode & ~umaskval) & S_IWRITE))
        ffa = FILE_ATTRIBUTE_READONLY;
    else
        ffa = FILE_ATTRIBUTE_NORMAL;

#ifndef __BORLANDC__
    if (oflag & O_SHORT_LIVED)
        ffa |= FILE_ATTRIBUTE_TEMPORARY;

    if (oflag & O_TEMPORARY) {
        fa |= DELETE;
        fs |= FILE_SHARE_DELETE;
        ffa |= FILE_FLAG_DELETE_ON_CLOSE;
    }

    if (oflag & O_SEQUENTIAL)
        ffa |= FILE_FLAG_SEQUENTIAL_SCAN;
    else if (oflag & O_RANDOM)
        ffa |= FILE_FLAG_RANDOM_ACCESS;
#endif

    if ((hndl = CreateFile(file, fa, fs, &sa, fc, ffa, NULL)) ==
            INVALID_HANDLE_VALUE)
    {
        Win32SharedFileOpen_SetErrStr(aTHX_
            "Can't open C file object handle for file '%s': %s", file,
            WIN32_SHAREDFILEOPEN_WIN_ERR_STR
        );
        return FALSE;
    }

    flag = oflag & O_APPEND ? O_APPEND : 0;
    if (oflag & O_BINARY) {
        flag |= O_BINARY;
        mode[modechars - 1] = 'b';
        mode[modechars++] = '\0';
    }
    else if (oflag & O_TEXT) {
        flag |= O_TEXT;
        mode[modechars - 1] = 't';
        mode[modechars++] = '\0';
    }

    if ((fd = win32_open_osfhandle((intptr_t)hndl, flag)) == -1) {
        Win32SharedFileOpen_SetErrStr(aTHX_
            "Can't get C file descriptor for C file objet handle for file "
            "'%s': %s", file, WIN32_SHAREDFILEOPEN_SYS_ERR_STR
        );
        WIN32_SHAREDFILEOPEN_SAVE_ERRS;
        CloseHandle(hndl);
        WIN32_SHAREDFILEOPEN_RESTORE_ERRS;
        return FALSE;
    }

    if ((pio_fp = PerlIO_fdopen(fd, mode)) == (PerlIO *)NULL) {
        Win32SharedFileOpen_SetErrStr(aTHX_
            "Can't get PerlIO file stream for C file descriptor for file "
            "'%s': %s", file, WIN32_SHAREDFILEOPEN_SYS_ERR_STR
        );
        WIN32_SHAREDFILEOPEN_SAVE_ERRS;
        close(fd);
        WIN32_SHAREDFILEOPEN_RESTORE_ERRS;
        return FALSE;
    }

    /* Dereference the Perl filehandle (or indirect filehandle) passed to us to
     * get the glob referred to, then get the IO member of that glob, adding a
     * new one if necessary. */
    io = GvIOn((GV *)SvRV(fh));

    /* Store the type in the glob's IO member. */
    IoTYPE(io) = type;

    /* Store the PerlIO file stream in the glob's IO member. */
    switch (type) {
        case IoTYPE_RDONLY:
            /* Store the PerlIO file stream as the input stream. */
            IoIFP(io) = pio_fp;
            break;

        case IoTYPE_WRONLY:
        case IoTYPE_APPEND:
            /* Store the PerlIO file stream as the output stream.  Apparently,
             * it must be stored as the input stream as well.  I do not know
             * why. */
            IoIFP(io) = pio_fp;
            IoOFP(io) = pio_fp;
            break;

        case IoTYPE_RDWR:
            /* Store the PerlIO file stream as both the input stream and the
             * output stream. */
            IoIFP(io) = pio_fp;
            IoOFP(io) = pio_fp;
            break;

        default:
            PerlIO_close(pio_fp);
            croak("Unknown IoTYPE '%d'", type);
            break;
    }

    return TRUE;
}

/*
 * Function to get a message string for the given Win32 API last-error code.
 * Returns a pointer to a buffer containing the string.
 * Note that the buffer is a (thread-safe) static, so subsequent calls to this
 * function from a given thread will overwrite the string.
 *
 * This function is based on the win32_str_os_error() function in Perl (version
 * 5.19.10).
 */

static char *Win32SharedFileOpen_StrWinError(pTHX_ pMY_CXT_ DWORD err_num) {
    DWORD len;

    len = FormatMessage(
        FORMAT_MESSAGE_IGNORE_INSERTS | FORMAT_MESSAGE_FROM_SYSTEM, NULL,
        err_num, 0, MY_CXT.err_str, sizeof(MY_CXT.err_str), NULL
    );

    if (len > 0) {
        /* Remove the trailing newline (and any other whitespace).  Note that
         * the len returned by FormatMessage() does not include the NUL
         * terminator, so decrement len by one immediately. */
        do {
            --len;
        } while (len > 0 && isSPACE(MY_CXT.err_str[len]));

        /* Increment len by one unless the last character is a period, and then
         * add a NUL terminator, so that any trailing period is also removed. */
        if (MY_CXT.err_str[len] != '.')
            ++len;

        MY_CXT.err_str[len] = '\0';
    }
    else {
        sprintf(MY_CXT.err_str, "Unknown error #0x%lX", err_num);
    }

    return MY_CXT.err_str;
}

/*
 * Function to set the Perl module's $ErrStr variable to the given value.
 */

static void Win32SharedFileOpen_SetErrStr(pTHX_ const char *value, ...) {
    va_list args;

    /* Get the Perl module's $ErrStr variable and set an appropriate value in
     * it. */
    va_start(args, value);
    sv_vsetpvf(get_sv("Win32::SharedFileOpen::ErrStr", TRUE), value, &args);
    va_end(args);
}

/*============================================================================*/

MODULE = Win32::SharedFileOpen PACKAGE = Win32::SharedFileOpen     

#===============================================================================
# XS CODE SECTION
#===============================================================================

PROTOTYPES:   ENABLE
VERSIONCHECK: ENABLE

INCLUDE: const-xs.inc

BOOT:
{
    MY_CXT_INIT;
}

void
CLONE(...)
    PPCODE:
    {
        MY_CXT_CLONE;
    }

# Private function to expose the Win32SharedFileOpen_Fsopen() function above.

void
_fsopen(fh, file, mode, shflag)
    PROTOTYPE: *$$$

    INPUT:
        SV         *fh;
        const char *file;
        const char *mode;
        int        shflag;

    PPCODE:
    {
        dMY_CXT;

        if (Win32SharedFileOpen_Fsopen(aTHX_ aMY_CXT_
                fh, file, mode, shflag)) {
            XSRETURN_YES;
        }
        else {
            XSRETURN_EMPTY;
        }

    }

# Private function to expose the Win32SharedFileOpen_Sopen() function above.

void
_sopen(fh, file, oflag, shflag, ...)
    PROTOTYPE: *$$$;$

    INPUT:
        SV         *fh;
        const char *file;
        int        oflag;
        int        shflag;

    PPCODE:
    {
        dMY_CXT;
        int pmode;

        pmode = (items > 4 ? SvIV(ST(4)) : 0);

        if (Win32SharedFileOpen_Sopen(aTHX_ aMY_CXT_
                fh, file, oflag, shflag, pmode)) {
            XSRETURN_YES;
        }
        else {
            XSRETURN_EMPTY;
        }
    }

#===============================================================================
