/*
 * 9 Jan 2002
 * This gives us a scratch area for passing strings back to
 * the interpreter. We have a static pointer to a malloc'd
 * area.
 * It grows and shrinks on every call, but the overhead is not
 * so terrible. There are two interfaces.
 * 1. copy a string to the area
 * 2. append a string
 *
 * $Id: scratch.c,v 1.1 2007/09/28 16:57:11 mmundry Exp $
 */



#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "e_malloc.h"
#include "scratch.h"

/* ---------------- Static variables ---------------------------
 */
static char *scratch = NULL;
static size_t n;            /* Holds size, including null terminator */

#ifdef  I_really_want_copy_to_scratch
/* ---------------- copy_to_scratch ----------------------------
 * This is for experimenting with returning strings to the
 * interpreter.
 * Save the string we are passed and return a pointer to the
 * area containing the string.
 */
static char *
copy_to_scratch (const char *s)
{
    size_t size;
    n = strlen (s) + 1;
    size = n * sizeof (s[0]);
    scratch = E_REALLOC (scratch, size);
    return (memcpy (scratch, s, size));
}
#endif  /* I_really_want_copy_to_scratch */

/* ---------------- append_to_scratch --------------------------
 * Append to the existing scratch area.
 */
static char *
append_to_scratch (const char *s)
{
    char *start;
    size_t new = strlen(s);
    scratch = E_REALLOC (scratch, (n + new) * sizeof (s[0]));
    start = scratch + n - 1;            /* Points to null terminator */
    memcpy (start, s, new + 1);
    n = n + new;
    return scratch;
}

/* ---------------- scr_reset   --------------------------------
 * Free up the scratch area with just a zero length string.
 * This function can be left "void", since the only failure can
 * be from E_MALLOC(), but then we die anyway.
 */
void
scr_reset ( void )
{
    scratch = E_REALLOC (scratch, 1 * sizeof (char));
    n = 1;
    scratch[0] = '\0';
}

/* ---------------- scr_printf  --------------------------------
 * Try to printf() into a local buffer, growing the buffer as 
 * necessary. When we are finished, copy the buffer to our
 * scratch and free the local buffer.
 * Basically, we have no idea how big the input will be. We
 * just keep trying to double the size until it seems to work.
 */
char *
scr_printf (const char *fmt, ...)
{
    char *ret,     /* This is what we will return */
         *s;       /* Our temporary buffer */
#   ifdef __STDC__
#       ifdef vsnprintf   /* If it is already a macro, do not protottype it */
/*          do nothing */
#       else
            extern int vsnprintf(char *, size_t , const char *,  va_list ap);
#       endif 
#   endif
    size_t transfer = 0;
    size_t size = 1;


#   undef debug_me_till_i_bleed
#   ifdef debug_me_till_i_bleed
    va_list (ap);
    va_start (ap, fmt);
    vfprintf (stderr, fmt, ap);
    va_end (ap);
    return "";
#   endif /* debug_me_till_i_bleed */
    s = E_MALLOC (size * sizeof (s[0]));

    while (transfer >= size - 1) {
        va_list ap;
        va_start (ap, fmt);
        size *= 2;
        s = E_REALLOC (s, size * sizeof (s[0]));
        transfer = vsnprintf (s, size, fmt, ap);
        va_end (ap);
    }
    ret = append_to_scratch (s);
    free (s);
    return (ret);
}

/* ---------------- free_scratch--------------------------------
 */
void
free_scratch (void)
{
    if (scratch)
        free (scratch);
}
