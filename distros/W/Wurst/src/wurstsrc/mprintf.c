/*
 * 21 March 2001
 * Wrappers for most common I/O to stdout and stderr. We use them
 * for two reasons:
 *  1. If, in the future, you want special handling of messages
 * (write to syslog, a dialog box, ...), it can be implemented
 * here.
 *  2. For code that will be meshed with a interpreter, there may
 * be special requirements. Tcl, for example, does not like it if
 * routines run around writing to stdout or stderr.
 * The overhead:
 * For most of the functions, this really is a very simple
 * wrapper with no real processing.
 * $Id: mprintf.c,v 1.2 2008/01/05 16:49:34 torda Exp $
 */

#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>

#include "mprintf.h"

/* ---------------- err_printf --------------------------------
 * This writes the first argument to stderr, then sends the rest
 * of the arguments, without change as in fprintf (stderr, stuf...).
 * The idea is that a function should print error messages like
 * err_printf (funcname,  "printf_string", printf arg list);
 */
int
err_printf (const char *fnc_name, const char *fmt, ...)
{
    int r;
    va_list ap;
    va_start (ap, fmt);
    mfprintf (stderr, "Function %s: ", fnc_name);
    r = vfprintf (stderr, fmt, ap);
    va_end (ap);
    return r;
}

/* ---------------- mprintf -----------------------------------
 * Pure wrapper for printf. Output goes to stdout unchanged.
 */
int
mprintf (const char *fmt, ...)
{
    int ret;
    va_list ap;

    va_start (ap, fmt);
    ret = vfprintf (stdout, fmt, ap);
    va_end (ap);
    return ret;
}
/* ---------------- mputchar ----------------------------------
 * Wrapper for putchar().
 */
int
mputchar ( int c)
{
        return (putchar (c));
}

/* ---------------- mfprintf  ---------------------------------
 * Wrapper for fprintf.
 */
int
mfprintf ( FILE *fp, const char *fmt, ...)
{
    int r;
    va_list ap;
    va_start (ap, fmt);

    r = vfprintf (fp, fmt, ap);
    va_end (ap);
    return r;
}

/* ---------------- mfputc ------------------------------------
 * Wrapper for fputc ().
 */
int
mfputc (int c, FILE *fp)
{
    if (fp != stdout)
        return (putc (c, fp));
    else
        return (mputchar (c));
}

/* ---------------- mputc  ------------------------------------
 * In the spirit of putc(), mputc() is defined as a macro.
 * See the mprintf.h header file.
 */


/* ---------------- mputs  ------------------------------------
 * Wrapper for puts.
 */
int mputs (const char *s)
{
    return (mprintf ("%s\n", s));
}

/* ---------------- mfputs ------------------------------------
 *
 */
int mfputs (const char *s, FILE *fp)
{
    if (fp == stdout)
        return ( mprintf ("%s", s));
    else
        return (fputs (s, fp));
}
/* ---------------- mperror -----------------------------------
 * This has the same calling interface as perror, but calls
 * err_printf() so one can treat any writes to stderr specially
 */
void
mperror (const char *s)
{
    err_printf (s, "%s\n", strerror (errno));
}
