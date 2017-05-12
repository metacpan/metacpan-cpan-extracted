/*
 * 28 june 2005
 * This is to let us print alignments in a form for something
 * like chimera.
 * We will take a "pair_set" and filename.
 *
 * $Id: pair_set_chim.c,v 1.1 2007/09/28 16:57:10 mmundry Exp $
 */

#define _XOPEN_SOURCE 500 /* This is probably a requirement for some of */
#include <ctype.h>        /* the posix functions. Here, we want snprintf() */
#include <stdio.h>
#include <stdlib.h>


#include "coord.h"
#include "mprintf.h"
#include "pair_set.h"
#include "pair_set_chim.h"
#include "scratch.h"
#include "str.h"


/* ---------------- add_res   ----------------------------------
 * Given the index of the residue (in our structure), build a
 * string which the details in midas format.
 */
static char *
add_res (char *s, const int a, const struct coord *c)
{
    enum {SIZE = 128};
    const char *atoms = "@ca";
    char scratch[SIZE];

    snprintf (scratch, SIZE, ":%d", c->orig[a]);
    s = save_str_append (s, scratch);
    if (c->icode[a] != ' ') {
        char t[2];
        t[0] = c->icode[a]; t[1] = '\0';
        s = save_str_append (s, t);
    }
#   ifdef want_chain_id
        if (isalpha (c->chain)) {
            snprintf (scratch, SIZE, ".%c", c->chain);
            s = save_str_append (s, scratch);
        }
#   endif /* want_chain_id */
    s = save_str_append (s, atoms);
    return s;
}

/* ---------------- pair_set_chimera  --------------------------
 * Given an alignment, write pairs of atoms to a file in a format
 * that chimera can read.
 * We return a char * to space which is allocated by the
 * scr_printf() routines.
 */
char *
pair_set_chimera (struct pair_set *pair_set,
                  const struct coord *c1, const struct coord *c2)
{
    const char *this_sub = "pair_set_chimera";
    int **p;
    char *s1 = NULL;
    char *s2 = NULL;
    char *ret;
    size_t i;
    if (pair_set->n == 0) {
        err_printf (this_sub, "empty pair set\n");
        return NULL;
    }
    s1 = save_str ("#0");
    s2 = save_str ("#1");
    p = pair_set->indices;
    for ( i = 0; i < pair_set->n; i++) {
        int a = p[i][0], b = p[i][1];
        if (( a != GAP_INDEX) && ( b != GAP_INDEX)) {
            s1 = add_res (s1, a, c1);
            s2 = add_res (s2, b, c2);
        }
    }
    scr_reset();
    ret = scr_printf ("match %s %s", s1, s2);
    free (s1);
    free (s2);
    return (ret);
}
