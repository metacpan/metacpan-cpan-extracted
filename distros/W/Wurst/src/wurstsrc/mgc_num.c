/*
 * 27 May 96
 * Read and write some magic numbers in a binary file.
 * On reading, they are compared so as to allow checking for portability
 * of binary files.  This should be sufficient to detect byte swapping,
 * precision and so on
 *
 * $Id: mgc_num.c,v 1.1 2007/09/28 16:57:13 mmundry Exp $
 */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include "mgc_num.h"
#include "mprintf.h"


/* -------- Constants for this file -------------------------- */
/* How much error do we tolerate on comparing binary numbers ? */
static const float TOL= 0.01;

/* -------- Structures and enums ----------------------------- */
struct magic_num {
    float a, b, c;
};
static struct magic_num magic = { 0.1, -99, 3.0e10 };

/* ---------------- write_magic_num ---------------------------
 */
int
write_magic_num (FILE *fp)
{
    if (fwrite (&magic, sizeof (struct magic_num), 1, fp) != 1)
        return EXIT_FAILURE;
    return EXIT_SUCCESS;
}

/* ---------------- byte_reverse_4  ---------------------------
 * Given a 4 byte thingy, abcd, return dcba.
 * For convenience, we want a float as an argument, but the same
 * reasoning would apply to a 4-byte int.
 * This is a function version.  One probably wants to use the ugly
 * macro version - it uses brutal casting, so it will probably
 * work in places where this would need gruesome coercion.
 */
static float
byte_reverse_f4 (float f)
{
    char *p = (char *) &f;
    float ret;
    char *r = (char *) &ret;
    p += 3;
    *r++ = *p--;
    *r++ = *p--;
    *r++ = *p--;
    *r = *p;
    return ret;
}

/* ---------------- test_three_num ----------------------------
 * Compare our three magic numbers and return EXIT_SUCCESS
 * or FAILURE as appropriate
 */
static int
test_three_num ( struct magic_num t) {
    if ( fabs( t.a - magic.a) > TOL)
        return EXIT_FAILURE;

    if ( fabs( t.b - magic.b) > TOL)
        return EXIT_FAILURE;

    if ( fabs( t.c - magic.c) > TOL)
        return EXIT_FAILURE;

    return EXIT_SUCCESS;
}

/* ---------------- read_magic_num ----------------------------
 * Magic num can return
 *    STRAIGHT_BYTES, REVERSE_BYTES or BROKEN_BYTES
 * depending on whether the we should read binary numbers
 * directly, after byte swapping or we don't know what to do.
 */
enum byte_magic
read_magic_num (FILE *fp)
{
    const char *this_sub = "read_magic_num";
    struct magic_num t;
    if (fread (&t, sizeof (struct magic_num), 1, fp) != 1) {
        err_printf (this_sub, "Read error getting magic numbers.\n");
        return BYTE_BROKEN;
    }
    if ( test_three_num (t) == EXIT_SUCCESS)
        return BYTE_STRAIGHT;

    t.a = byte_reverse_f4 (t.a) ;
    t.b = byte_reverse_f4 (t.b) ;
    t.c = byte_reverse_f4 (t.c) ;
    if ( test_three_num (t) == EXIT_SUCCESS)
        return BYTE_REVERSE;

    err_printf (this_sub, "Error reading binary file, both as\n");
    err_printf (this_sub, " straightforward and reversed byte order\n");
    return BYTE_BROKEN;
}












