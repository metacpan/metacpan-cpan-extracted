/*============================================================================
 *
 * UTCFileTime.xs
 *
 * DESCRIPTION
 *   C and XS portions of Win32::UTCFileTime module.
 *
 * COPYRIGHT
 *   Copyright (C) 2003-2006, 2008, 2012, 2014 Steve Hay.  All rights reserved.
 *   Portions Copyright (C) 2001 Jonathan M Gilligan.  Used with permission.
 *   Portions Copyright (C) 2001 Tony M Hoyle.  Used with permission.
 *
 * LICENCE
 *   You may distribute under the terms of either the GNU General Public License
 *   or the Artistic License, as specified in the LICENCE file.
 *
 *============================================================================*/

/*============================================================================
 * C CODE SECTION
 *============================================================================*/

                                        /* For _getdrive().                   */
#ifdef __BORLANDC__
#  include <dos.h>
#else
#  include <direct.h>
#endif
#include <fcntl.h>                      /* For the O_* flags.                 */
#include <io.h>                         /* For open() and close().            */
#include <stdarg.h>                     /* For va_list/va_start()/va_end().   */
#include <stdio.h>                      /* For sprintf().                     */
#include <stdlib.h>                     /* For errno.                         */
#include <string.h>                     /* For the str*() functions.          */
#include <sys/stat.h>                   /* For struct stat and the S_* flags. */

#define WIN32_LEAN_AND_MEAN             /* To exclude unnecessary headers.    */
#include <windows.h>                    /* For the Win32 API stuff.           */

#define PERL_NO_GET_CONTEXT             /* To get interp context efficiently. */
#define PERLIO_NOT_STDIO 0              /* To allow use of PerlIO and stdio.  */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newSVpvn_flags             /* For newSVpvs_flags().              */
#include "ppport.h"

#include "const-c.inc"

#define MY_CXT_KEY "Win32::UTCFileTime::_guts" XS_VERSION

typedef struct {
    int saved_errno;
    DWORD saved_error;
    char err_str[BUFSIZ];
} my_cxt_t;

START_MY_CXT

/* Borland C++ 5.5.1 doesn't have _dev_t. */
#ifdef __BORLANDC__
typedef dev_t _dev_t;
#endif

/* Macros to save and restore the value of the standard C library errno variable
 * and the Win32 API last-error code for use when cleaning up before returning
 * failure. */
#define WIN32_UTCFILETIME_SAVE_ERRS    STMT_START { \
    MY_CXT.saved_errno = errno;                     \
    MY_CXT.saved_error = GetLastError();            \
} STMT_END
#define WIN32_UTCFILETIME_RESTORE_ERRS STMT_START { \
    errno = MY_CXT.saved_errno;                     \
    SetLastError(MY_CXT.saved_error);               \
} STMT_END

#define WIN32_UTCFILETIME_SYS_ERR_STR (strerror(errno))
#define WIN32_UTCFILETIME_WIN_ERR_STR \
    (Win32UTCFileTime_StrWinError(aTHX_ aMY_CXT_ GetLastError()))

static bool Win32UTCFileTime_IsWinNT(pTHX_ pMY_CXT);
static bool Win32UTCFileTime_FileTimeToUnixTime(pTHX_ pMY_CXT_
    const FILETIME *ft, time_t *ut);
static bool Win32UTCFileTime_UnixTimeToFileTime(pTHX_ pMY_CXT_
    const time_t ut, FILETIME *ft);
static unsigned short Win32UTCFileTime_FileAttributesToUnixMode(pTHX_ pMY_CXT_
    const DWORD fa, const char *name);
static int Win32UTCFileTime_AltStat(pTHX_ pMY_CXT_ const char *name,
    struct stat *st_buf);
static bool Win32UTCFileTime_GetUTCFileTimes(pTHX_ pMY_CXT_ const char *name,
    time_t *u_atime_t, time_t *u_mtime_t, time_t *u_ctime_t);
static bool Win32UTCFileTime_SetUTCFileTimes(pTHX_ pMY_CXT_ const char *name,
    const time_t u_atime_t, const time_t u_mtime_t);
static char *Win32UTCFileTime_StrWinError(pTHX_ pMY_CXT_ DWORD err_num);
static void Win32UTCFileTime_SetErrStr(pTHX_ const char *value, ...);

/* Number of "clunks" (100-nanosecond intervals) in one second. */
static const ULONGLONG win32_utcfiletime_clunks_per_second = 10000000L;

/* The epoch of time_t values (00:00:00 Jan 01 1970 UTC) as a SYSTEMTIME. */
static const SYSTEMTIME win32_utcfiletime_base_st = {
    1970,    /* wYear         */
    1,       /* wMonth        */
    0,       /* wDayOfWeek    */
    1,       /* wDay          */
    0,       /* wHour         */
    0,       /* wMinute       */
    0,       /* wSecond       */
    0        /* wMilliseconds */
};

/* The epoch of time_t values (00:00:00 Jan 01 1970 UTC) as a FILETIME.  This is
 * set at boot time from the SYSTEMTIME above and is not subsequently changed,
 * so is virtually a "const" and is therefore thread-safe. */
static FILETIME win32_utcfiletime_base_ft;

/*
 * Function to determine whether the operating system platform is Windows NT (as
 * opposed to Win32s, Windows [95/98/ME] or Windows CE).
 */

static bool Win32UTCFileTime_IsWinNT(pTHX_ pMY_CXT) {
    /* These statics are set "on demand" and are not subsequently changed, so
     * are virtually "consts"s and are therefore thread-safe. */
    static bool initialized = FALSE;
    static bool is_winnt;
    OSVERSIONINFO osver;

    if (!initialized) {
        Zero(&osver, 1, OSVERSIONINFO);
        osver.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
        if (GetVersionEx(&osver)) {
            is_winnt = (osver.dwPlatformId == VER_PLATFORM_WIN32_NT);
        }
        else {
            warn("Can't determine operating system platform: %s.  Assuming the "
                 "platform is Windows NT", WIN32_UTCFILETIME_WIN_ERR_STR);
            is_winnt = TRUE;
        }
        initialized = TRUE;
    }

    return is_winnt;
}

/*
 * Function to convert a FILETIME to a time_t.  The FILETIME and the time_t are
 * both UTC-based.
 *
 * This function is based on code written by Jonathan M Gilligan.
 */

static bool Win32UTCFileTime_FileTimeToUnixTime(pTHX_ pMY_CXT_
    const FILETIME *ft, time_t *ut)
{
    ULARGE_INTEGER it;

    /* Convert the FILETIME (which is expressed as the number of clunks
     * since 00:00:00 Jan 01 1601 UTC) to a time_t value by subtracting the
     * FILETIME representation of the epoch of time_t values and then
     * converting clunks to seconds. */
    it.QuadPart  = ((ULARGE_INTEGER *)ft)->QuadPart;
    it.QuadPart -= ((ULARGE_INTEGER *)&win32_utcfiletime_base_ft)->QuadPart;
    it.QuadPart /= win32_utcfiletime_clunks_per_second;

    *ut = it.LowPart;
    return TRUE;
}

/*
 * Function to convert a time_t to a FILETIME.  The time_t and the FILETIME are
 * both UTC-based.
 *
 * This function is based on code written by Tony M Hoyle.
 */

static bool Win32UTCFileTime_UnixTimeToFileTime(pTHX_ pMY_CXT_
    const time_t ut, FILETIME *ft)
{
    ULARGE_INTEGER it;

    /* Convert the time_t value to a FILETIME (which is expressed as the
     * number of clunks since 00:00:00 Jan 01 1601 UTC) by converting
     * seconds to clunks and then adding the FILETIME representation of the
     * epoch of time_t values. */
    it.LowPart   = (DWORD)ut;
    it.HighPart  = 0;
    it.QuadPart *= win32_utcfiletime_clunks_per_second;
    it.QuadPart += ((ULARGE_INTEGER *)&win32_utcfiletime_base_ft)->QuadPart;

    *(ULARGE_INTEGER *)ft = it;
    return TRUE;
}

/*
 * Function to convert file attributes as returned by the Win32 API function
 * GetFileAttributes() into a Unix mode as stored in the st_mode field of a
 * struct stat.
 *
 * This function is based on code taken from the wnt_stat() function in CVSNT
 * (version 2.0.4) the win32_stat() function in Perl (version 5.19.10).
 */

static unsigned short Win32UTCFileTime_FileAttributesToUnixMode(pTHX_ pMY_CXT_
    const DWORD fa, const char *name)
{
    unsigned short st_mode = 0;
    unsigned short perms;
    size_t len;
    const char *p;

    if (fa & FILE_ATTRIBUTE_DIRECTORY)
        st_mode |= _S_IFDIR;
    else
        st_mode |= _S_IFREG;

    if (fa & FILE_ATTRIBUTE_READONLY)
        st_mode |= _S_IREAD;
    else
        st_mode |= _S_IREAD | _S_IWRITE;

    /* Write permission used to be turned on for directories with Borland, but
     * only until a change in 5.11.0, backported to 5.8.9 and 5.10.1. */
    if (fa & FILE_ATTRIBUTE_DIRECTORY)
#if defined(__BORLANDC__) && PERL_REVISION == 5 && \
            ((PERL_VERSION ==  8 && PERL_SUBVERSION < 9) || \
              PERL_VERSION ==  9 || \
             (PERL_VERSION == 10 && PERL_SUBVERSION < 1))
        st_mode |= _S_IEXEC | _S_IWRITE;
#else
        st_mode |= _S_IEXEC;
#endif

    len = strlen(name);
    if (len >= 4 && (*(p = name + len - 4) == '.') &&
            (!stricmp(p, ".exe") ||  !stricmp(p, ".bat") ||
             !stricmp(p, ".com") || (!stricmp(p, ".cmd") &&
                                     Win32UTCFileTime_IsWinNT(aTHX_ aMY_CXT))))
        st_mode |= _S_IEXEC;

    /* Propagate permissions to "group" and "others". */
#ifdef __BORLANDC__
    if (!(fa & FILE_ATTRIBUTE_DIRECTORY)) {
#endif
    perms = st_mode & (_S_IREAD | _S_IWRITE | _S_IEXEC);
    st_mode |= (perms >> 3) | (perms >> 6);
#ifdef __BORLANDC__
    }
#endif

    return st_mode;
}

/*
 * Function to emulate the standard C library function stat(), setting the
 * last access time, last modification time and creation time members of the
 * given "stat" structure to UTC-based time_t values, whatever filesystem the
 * file is stored in.
 *
 * This function is based on code taken from the wnt_stat() function in CVSNT
 * (version 2.0.4) and the win32_stat() function in Perl (version 5.19.10).
 */

static int Win32UTCFileTime_AltStat(pTHX_ pMY_CXT_ const char *name,
    struct stat *st_buf)
{
    int drive;
    HANDLE hndl;
    BY_HANDLE_FILE_INFORMATION bhfi;

    /* Return an error if a wildcard has been specified. */
    if (strpbrk(name, "?*")) {
        Win32UTCFileTime_SetErrStr(aTHX_ "Wildcard in filename '%s'", name);
        errno = ENOENT;
        return -1;
    }

    Zero(&bhfi, 1, BY_HANDLE_FILE_INFORMATION);

    /* Use CreateFile() and GetFileInformationByHandle(), rather than
     * FindFirstFile() like Microsoft's stat() does, for three reasons:
     * (1) CreateFile() does not require "List Folder Contents" permission on
     *     the parent directory like FindFirstFile() does;
     * (2) The BY_HANDLE_FILE_INFORMATION structure returned by
     *     GetFileInformationByHandle() contains the number of links to the
     *     file, which the WIN32_FIND_DATA structure returned by FindFirstFile()
     *     does not; and most importantly
     * (3) The file times in that structure are correct UTC times on both NTFS
     *     and FAT, whereas on FAT the file times in the WIN32_FIND_DATA
     *     structure are sometimes wrong w.r.t. DST season changes
     * Pass the FILE_FLAG_BACKUP_SEMANTICS flag to allow directory handles to be
     * obtained (provided that this is a Windows NT platform). */
    if ((hndl = CreateFile(name, 0, 0, NULL, OPEN_EXISTING,
            FILE_FLAG_BACKUP_SEMANTICS, NULL)) == INVALID_HANDLE_VALUE)
    {
        /* If this is a valid directory (presumably under a Windows 95 platform
         * on which the FILE_FLAG_BACKUP_SEMANTICS flag does not do the trick)
         * then set all the fields except st_mode to zero and return TRUE, like
         * Perl's built-in functions do in this case.  Save the Win32 API last-
         * error code from the failed CreateFile() call first in case this is
         * not a directory. */
        DWORD le = GetLastError();
        DWORD fa = GetFileAttributes(name);
        if (fa != 0xFFFFFFFF && (fa & FILE_ATTRIBUTE_DIRECTORY)) {
            Zero(st_buf, 1, struct stat);
            st_buf->st_mode =
                Win32UTCFileTime_FileAttributesToUnixMode(aTHX_ aMY_CXT_
                                                          fa, name);
            errno = 0;
            return 0;
        }
        else {
            Win32UTCFileTime_SetErrStr(aTHX_
                "Can't open file '%s' for reading: %s",
                name, Win32UTCFileTime_StrWinError(aTHX_ aMY_CXT_ le)
            );
            return -1;
        }
    }

    if (!GetFileInformationByHandle(hndl, &bhfi)) {
        Win32UTCFileTime_SetErrStr(aTHX_
            "Can't get file information for file '%s': %s",
            name, WIN32_UTCFILETIME_WIN_ERR_STR
        );
        WIN32_UTCFILETIME_SAVE_ERRS;
        CloseHandle(hndl);
        WIN32_UTCFILETIME_RESTORE_ERRS;
        return -1;
    }

    if (!CloseHandle(hndl))
        warn("Can't close file object handle '%lu' for file '%s' after "
             "reading: %s", hndl, name, WIN32_UTCFILETIME_WIN_ERR_STR);

    if (!(Win32UTCFileTime_FileTimeToUnixTime(aTHX_ aMY_CXT_
                &bhfi.ftLastAccessTime, &st_buf->st_atime) &&
            Win32UTCFileTime_FileTimeToUnixTime(aTHX_ aMY_CXT_
                &bhfi.ftLastWriteTime, &st_buf->st_mtime) &&
            Win32UTCFileTime_FileTimeToUnixTime(aTHX_ aMY_CXT_
                &bhfi.ftCreationTime, &st_buf->st_ctime)))
        return -1;

    st_buf->st_mode =
        Win32UTCFileTime_FileAttributesToUnixMode(aTHX_ aMY_CXT_
                                                  bhfi.dwFileAttributes, name);

    if (bhfi.nNumberOfLinks > SHRT_MAX) {
        warn("Overflow: Too many links (%lu) to file '%s'",
             bhfi.nNumberOfLinks, name);
        st_buf->st_nlink = SHRT_MAX;
    }
    else {
        st_buf->st_nlink = (short)bhfi.nNumberOfLinks;
    }

    st_buf->st_size = bhfi.nFileSizeLow;

    /* Get the drive from the name, or use the current drive. */
    if (strlen(name) >= 2 && isALPHA(name[0]) && name[1] == ':')
        drive = toLOWER(name[0]) - 'a' + 1;
    else
        drive = _getdrive();

    st_buf->st_dev = st_buf->st_rdev = (_dev_t)(drive - 1);

    st_buf->st_ino = st_buf->st_uid = st_buf->st_gid = 0;

    return 0;
}

/*
 * Function to get the last access time, last modification time and creation
 * time of a given file.  The values are all returned as UTC-based time_t
 * values, whatever filesystem the file is stored in.
 *
 * This function is based on code written by Jonathan M Gilligan.
 */

static bool Win32UTCFileTime_GetUTCFileTimes(pTHX_ pMY_CXT_ const char *name,
    time_t *u_atime_t, time_t *u_mtime_t, time_t *u_ctime_t)
{
    HANDLE hndl;
    BY_HANDLE_FILE_INFORMATION bhfi;

    /* Use CreateFile() and GetFileInformationByHandle(), rather than
     * FindFirstFile() like Microsoft's stat() does, for the reasons listed in
     * the Win32UTCFileTime_AltStat() function above.  (Do not use the more
     * obvious GetFileTime() to avoid a problem with that caching UTC time
     * values on FAT volumes.) */
    if ((hndl = CreateFile(name, 0, 0, NULL, OPEN_EXISTING,
            FILE_FLAG_BACKUP_SEMANTICS, NULL)) == INVALID_HANDLE_VALUE)
    {
        /* This function is only ever called after a call to Perl's built-in
         * stat() or lstat() function has already succeeded on the same name, so
         * this must just be a directory under a Windows 95 platform on which
         * the FILE_FLAG_BACKUP_SEMANTICS flag does not do the trick.  Set all
         * the file times to zero and return TRUE, like Perl's built-in
         * functions do in this case. */
        *u_atime_t = 0;
        *u_mtime_t = 0;
        *u_ctime_t = 0;
        return TRUE;
    }

    if (!GetFileInformationByHandle(hndl, &bhfi)) {
        Win32UTCFileTime_SetErrStr(aTHX_
            "Can't get file information for file '%s': %s",
            name, WIN32_UTCFILETIME_WIN_ERR_STR
        );
        WIN32_UTCFILETIME_SAVE_ERRS;
        CloseHandle(hndl);
        WIN32_UTCFILETIME_RESTORE_ERRS;
        return FALSE;
    }

    if (!CloseHandle(hndl))
        warn("Can't close file object handle '%lu' for file '%s' after "
             "reading: %s", hndl, name, WIN32_UTCFILETIME_WIN_ERR_STR);

    return(Win32UTCFileTime_FileTimeToUnixTime(aTHX_ aMY_CXT_
                &bhfi.ftLastAccessTime, u_atime_t) &&
            Win32UTCFileTime_FileTimeToUnixTime(aTHX_ aMY_CXT_
                &bhfi.ftLastWriteTime, u_mtime_t) &&
            Win32UTCFileTime_FileTimeToUnixTime(aTHX_ aMY_CXT_
                &bhfi.ftCreationTime, u_ctime_t));
}

/*
 * Function to set the last access time and last modification time of a given
 * file.  The values should both be supplied as UTC-based time_t values,
 * whatever filesystem the file is stored in.
 */

static bool Win32UTCFileTime_SetUTCFileTimes(pTHX_ pMY_CXT_ const char *name,
    const time_t u_atime_t, const time_t u_mtime_t)
{
    int fd;
    bool ret = FALSE;
    HANDLE hndl;
    FILETIME u_atime_ft;
    FILETIME u_mtime_ft;

    /* Try opening the file normally first, like Microsoft's utime(), and hence
     * Perl's win32_utime(), does.  Note that this will fail (with errno EACCES)
     * if name specifies a directory or a read-only file. */
    if ((fd = open(name, O_RDWR | O_BINARY)) < 0) {
        /* If name is a directory then open() will fail.  However, CreateFile()
         * can open directory handles (provided that this is a Windows NT
         * platform and the FILE_FLAG_BACKUP_SEMANTICS flag is passed to allow
         * directory handles to be obtained), so try that instead like Perl's
         * win32_utime() does in case that was the cause of the failure.  This
         * will (and should) still fail on read-only files. */
        if ((hndl = CreateFile(name, GENERIC_READ | GENERIC_WRITE,
                FILE_SHARE_READ | FILE_SHARE_DELETE, NULL, OPEN_EXISTING,
                FILE_FLAG_BACKUP_SEMANTICS, NULL)) == INVALID_HANDLE_VALUE)
        {
            Win32UTCFileTime_SetErrStr(aTHX_
                "Can't open file '%s' for updating: %s",
                name, WIN32_UTCFILETIME_WIN_ERR_STR
            );
            return FALSE;
        }
    }
    else if ((hndl = (HANDLE)win32_get_osfhandle(fd)) == INVALID_HANDLE_VALUE) {
        Win32UTCFileTime_SetErrStr(aTHX_
            "Can't get file object handle after opening file '%s' for "
            "updating as file descriptor '%d': %s",
            name, WIN32_UTCFILETIME_SYS_ERR_STR
        );
        WIN32_UTCFILETIME_SAVE_ERRS;
        close(fd);
        WIN32_UTCFILETIME_RESTORE_ERRS;
        return FALSE;
    }

    /* Use NULL for the creation time passed to SetFileTime() like Microsoft's
     * utime() does.  This simply means that the information is not changed.
     * There is no need to retrieve the existing value first in order to reset
     * it like Perl's win32_utime() does. */

    if (Win32UTCFileTime_UnixTimeToFileTime(aTHX_ aMY_CXT_
            u_atime_t, &u_atime_ft) &&
        Win32UTCFileTime_UnixTimeToFileTime(aTHX_ aMY_CXT_
            u_mtime_t, &u_mtime_ft))
    {
        if (!SetFileTime(hndl, NULL, &u_atime_ft, &u_mtime_ft)) {
            Win32UTCFileTime_SetErrStr(aTHX_
                "Can't set file times for file '%s': %s",
                name, WIN32_UTCFILETIME_WIN_ERR_STR
            );
            ret = FALSE;
        }
        else {
            ret = TRUE;
        }
    }
    else {
        ret = FALSE;
    }

    /* Close the file descriptor if it is open.  This closes the underlying file
     * object handle as well, so there is no need to call CloseHandle() too.
     * Otherwise we only have a file object handle open, so just close that
     * directly. */
    if (fd >= 0) {
        if (close(fd) < 0)
            warn("Can't close file descriptor '%d' for file '%s' after "
                 "updating: %s", fd, name, WIN32_UTCFILETIME_SYS_ERR_STR);
    }
    else {
        if (!CloseHandle(hndl))
            warn("Can't close file object handle '%lu' for file '%s' after "
                 "updating: %s", hndl, name, WIN32_UTCFILETIME_WIN_ERR_STR);
    }

    return ret;
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

static char *Win32UTCFileTime_StrWinError(pTHX_ pMY_CXT_ DWORD err_num) {
    DWORD len;

    len = FormatMessage(
        FORMAT_MESSAGE_IGNORE_INSERTS | FORMAT_MESSAGE_FROM_SYSTEM, NULL,
        err_num, 0, MY_CXT.err_str, sizeof MY_CXT.err_str, NULL
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

static void Win32UTCFileTime_SetErrStr(pTHX_ const char *value, ...) {
    va_list args;

    /* Get the Perl module's $ErrStr variable and set an appropriate value in
     * it. */
    va_start(args, value);
    sv_vsetpvf(get_sv("Win32::UTCFileTime::ErrStr", TRUE), value, &args);
    va_end(args);
}

/*============================================================================*/

MODULE = Win32::UTCFileTime PACKAGE = Win32::UTCFileTime        

#===============================================================================
# XS CODE SECTION
#===============================================================================

PROTOTYPES:   ENABLE
VERSIONCHECK: ENABLE

INCLUDE: const-xs.inc

BOOT:
{
    MY_CXT_INIT;

    /* Get the epoch of time_t values as a FILETIME.  This calculation only
     * needs to be done once, and is required by all four functions (stat(),
     * lstat(), alt_stat() and utime()), so we might as well do it here. */
    if (!SystemTimeToFileTime(&win32_utcfiletime_base_st,
            &win32_utcfiletime_base_ft))
        croak("Can't convert base SYSTEMTIME to FILETIME: %s",
              WIN32_UTCFILETIME_WIN_ERR_STR);
}

void
CLONE(...)
    PPCODE:
    {
        MY_CXT_CLONE;
    }

# Private function to expose the Win32UTCFileTime_AltStat() function above.
# This function is based on code taken from the pp_stat() function in Perl
# (version 5.19.10).

void
_alt_stat(file)
    PROTOTYPE: $

    INPUT:
        const char *file

    PPCODE:
    {
        dMY_CXT;
        U32 gimme = GIMME_V;
        struct stat st_buf;

        if (Win32UTCFileTime_AltStat(aTHX_ aMY_CXT_ file, &st_buf) == 0) {
            if (gimme == G_SCALAR) {
                XSRETURN_YES;
            }
            else if (gimme == G_ARRAY) {
                EXTEND(SP, 13);

                mPUSHi((IV)st_buf.st_dev);

                /* ST_INO_SIZE (4) <= IVSIZE (4 or 8) and ST_INO_SIGN == 1 */
                mPUSHu((UV)st_buf.st_ino);

                mPUSHu((UV)st_buf.st_mode);
                mPUSHu((UV)st_buf.st_nlink);

                /* Uid_t_size (4) <= IVSIZE (4 or 8) and Uid_t_sign == -1 */
                mPUSHi((IV)st_buf.st_uid);

                /* Gid_t_size (4) <= IVSIZE (4 or 8) and Gid_t_sign == -1 */
                mPUSHi((IV)st_buf.st_gid);

                /* USE_STAT_RDEV is defined */
                mPUSHi((IV)st_buf.st_rdev);

                /* Off_t_size (4 or 8) <= IVSIZE (4 or 8) */
                mPUSHi((IV)st_buf.st_size);

                /* BIG_TIME not defined */
                mPUSHi((IV)st_buf.st_atime);
                mPUSHi((IV)st_buf.st_mtime);
                mPUSHi((IV)st_buf.st_ctime);
                
                /* USE_STAT_BLOCKS is not defined */
                PUSHs(newSVpvs_flags("", SVs_TEMP));
                PUSHs(newSVpvs_flags("", SVs_TEMP));

                XSRETURN(13);
            }
            else {
                XSRETURN_EMPTY;
            }
        }
        else {
            XSRETURN_EMPTY;
        }
    }

# Private function to expose the Win32UTCFileTime_GetUTCFileTimes() function
# above.

void
_get_utc_file_times(file)
    PROTOTYPE: $

    INPUT:
        const char *file;

    PPCODE:
    {
        dMY_CXT;
        time_t atime;
        time_t mtime;
        time_t ctime;

        if (Win32UTCFileTime_GetUTCFileTimes(aTHX_ aMY_CXT_
                file, &atime, &mtime, &ctime))
        {
            EXTEND(SP, 3);

            /* BIG_TIME not defined */
            mPUSHi((IV)atime);
            mPUSHi((IV)mtime);
            mPUSHi((IV)ctime);

            XSRETURN(3);
        }
        else {
            XSRETURN_EMPTY;
        }
    }

# Private function to expose the Win32UTCFileTime_SetUTCFileTimes() function
# above.

void
_set_utc_file_times(file, atime, mtime)
    PROTOTYPE: $$$

    INPUT:
        const char *file;
        const time_t atime;
        const time_t mtime;

    PPCODE:
    {
        dMY_CXT;

        if (Win32UTCFileTime_SetUTCFileTimes(aTHX_ aMY_CXT_
                file, atime, mtime)) {
            XSRETURN_YES;
        }
        else {
            XSRETURN_EMPTY;
        }
    }

# Private function to expose the Win32 API function SetErrorMode().

UINT
_set_error_mode(umode)
    PROTOTYPE: $

    INPUT:
        const UINT umode;

    CODE:
        RETVAL = SetErrorMode(umode);

    OUTPUT:
        RETVAL

#===============================================================================
