/*
 * 22 March 2001
 * Lower level file handling functions. They may go beyond the
 * ANSI standard, but they must be posix.
 * $Id: fio.c,v 1.1 2007/09/28 16:57:04 mmundry Exp $
 */

#define _XOPEN_SOURCE 600 /* necessary to get posix_fadvise() */
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>

#include "fio.h"
#include "mprintf.h"

/* ---------------- mfopen  -----------------------------------
 * Wrapper around fopen. Last arg is a string, typically the
 * name of the calling function which will be printed out at the
 * start of error messages.
 */
FILE *
mfopen (const char *fname, const char *mode, const char *s)
{
    FILE *fp;
    if ((fp = fopen (fname, mode)) == NULL) {
        int e = errno;
        err_printf (s, "Open fail on %s\n", fname);
        errno = e;
        mperror (s);
    }
    return fp;
}

/* ---------------- file_no_cache -----------------------------
 * When we read sequentially from a huge series of structure
 * files, the OS tries to cache them all, although we will not
 * reuse them in the near future.
 * This is not harmless. When running in the background, wurst
 * tends to fill the cache with this data, wipe out files that a
 * user really does want to work with.
 * This is a wrapper around the posix routine which should be
 * called on all files like this (structures, profiles, ...).
 * The routine may not be provided everywhere, so put any
 * portability checks in here.
 * To be sure, maybe I should also call the function
 * with POSIX_FADV_DONTNEED.
 * Return
 *  0 if all went well
 *  errno if something broke.
 */
int
file_no_cache (FILE *fp)
{
#   ifdef POSIX_FADV_SEQUENTIAL
        int fnum, r, s;
        struct stat statbuf;
        const off_t offset = 0;
        const size_t len = 0;
        const char *this_sub = "file_no_cache";
        int e = 0; 
        if ((fnum = fileno (fp)) == -1) {
            mperror (this_sub);
            return ( -1 );
        }
        if (fstat ( fnum, &statbuf) == -1) {
            mperror (this_sub);
            return ( -1 );
        }

        if ( S_ISFIFO (statbuf.st_mode))         /* If this is a pipe,*/
            return 0;                            /* then just return  */

        if ((r = posix_fadvise (fnum, offset, len, POSIX_FADV_SEQUENTIAL))) {
            e = errno;
            err_printf (this_sub, "POSIX_FADV_SEQUENTIAL probably broken.\n");
        }
        if ((s = posix_fadvise (fnum, offset, len, POSIX_FADV_NOREUSE))) {
            e = errno;
            err_printf (this_sub, "POSIX_FADV_NOREUSE probably broken.\n");
        }
        if (r != 0 || s!= 0)
            return e;
#   endif   /* POSIX_FADV_SEQUENTIAL */
        return 0;
}

/* ---------------- file_clear_cache --------------------------
 * Before closing, we can tell the OS we don't need any cached
 * data.
 */
int
file_clear_cache (FILE *fp)
{
#   ifdef POSIX_FADV_DONTNEED
        int fnum, r;
        const off_t offset = 0;
        const size_t len = 0;

        if ((fnum = fileno (fp)) == -1)
            return errno;
        r = posix_fadvise (fnum, offset, len, POSIX_FADV_DONTNEED);

        if (r != 0)
            return errno;
        return 0;
#   else
        return 0;
#   endif   /* POSIX_FADV_DONTNEED */
}
