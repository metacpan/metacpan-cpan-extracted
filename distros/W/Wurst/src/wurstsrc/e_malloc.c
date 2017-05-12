/*
 * Feb 96
 * Malloc wrappers. They are put into macros, so they take
 * exactly the same arguments as the library functions, but give
 * us the file and line number on failure.
 *
 * $Id: e_malloc.c,v 1.1 2007/09/28 16:57:12 mmundry Exp $
 */

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>

#include "e_malloc.h"
#include "mprintf.h"

/* ---------------- e_malloc ----------------------------------
 * Malloc wrapper.  Prints out an error message and gives up
 * in case of allocation failure.
 * Don't call this directly, Call the E_MALLOC macro which
 * takes the same arguments as malloc().
 */

static const char *err = "out of memory, file %s, line %d getting %d bytes\n";
void *
e_malloc (size_t s, const char *f, const int l)
{
    void *p;
    const char *this_sub = "e_malloc";
    errno = 0;
    if ((p = malloc (s)) == NULL) {
        if (errno != 0)
            perror (this_sub);
        mfprintf (stderr, "%s: ", this_sub);
        mfprintf (stderr, err, f, l, s);
        exit (EXIT_FAILURE);
    }
    return p;
}
/* ---------------- e_realloc ---------------------------------
 * Realloc wrapper.  Don't call this directly, call the
 * E_REALLOC macro which take the same arguments as realloc().
 */
void *
e_realloc ( void *ptr, size_t s, const char *f, const int l)
{
    void *p;
    const char *this_sub = "e_realloc";
    if (s == 0) {
        free (ptr);
        return NULL;
    }
    if ((p = realloc (ptr, s)) == NULL) {
        perror (this_sub);
        mfprintf (stderr, "%s: ", this_sub);
        mfprintf (stderr, err, f, l, s);
        exit (EXIT_FAILURE);
    }
    return p;
}

/* ---------------- e_calloc ---------------------------------
 * Calloc wrapper.  Don't call this directly, call the
 * E_CALLOC macro which take the same arguments as calloc().
 */
void *
e_calloc ( size_t n, size_t s, const char *f, const int l)
{
    void *p;
    const char *this_sub = "e_calloc";
    errno = 0;
    if ((p = calloc (n, s)) == NULL) {
        if (errno != 0)
            perror (this_sub);
        mfprintf (stderr, "%s: ", this_sub);
        mfprintf (stderr, err, f, l, s);
        exit (EXIT_FAILURE);
    }
    return p;
}

/* ---------------- free_if_not_null --------------------------
 */
void
free_if_not_null (void *s)
{
    if (s)
        free (s);
}
