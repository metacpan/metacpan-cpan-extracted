/*
 * 4 Jan 2002
 * These are silly functions, but they are for testing
 * installation.
 *
 * $Id: silly.c,v 1.2 2008/04/11 13:53:04 mmundry Exp $
 */



#include <stdio.h>

#include "scratch.h"
#include "silly.h"

/* ---------------- func_int   ---------------------------------
 */
int
func_int ()
{
    return 42;
}

/* ---------------- func_float ---------------------------------
 */
float
func_float ()
{
    return 3.125;
}

/* ---------------- func_char  ---------------------------------
 */
char *
func_char ()
{
    const char *s = "Hello from func_char";
    return (char *)s;
}

/* ---------------- funcs1_char --------------------------------
 */
char *
funcs1_char ( char *in )
{
    static int i = 0;
    char s[256];
    const char *this_sub = "funcs1_char";
    sprintf (s, "%s has been called %d times and was given %s",
             this_sub, ++i, in);
    scr_reset ();
    return (scr_printf ("%s", s));
}

/* ---------------- funcs2_char --------------------------------
 */
char *
funcs2_char ( void )
{
    static int i = 0;
    const char *this_sub = "funcs2_char";
    scr_reset ();
    scr_printf ("This is %s. I am being called %d times.\n", this_sub, ++i);
    scr_printf ("Call2 from %s", this_sub);
    return (scr_printf ("-Third-%s\n", this_sub));
}
