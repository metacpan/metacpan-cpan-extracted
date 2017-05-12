/*
 * 24 March 2001
 * Read a substitution matrix and so some simple manipulations
 * like reading and setting elements.
 *
 * $Id: read_mat.c,v 1.1 2007/09/28 16:57:07 mmundry Exp $
 */

#include <ctype.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "amino_a.h"
#include "e_malloc.h"
#include "fio.h"
#include "read_mat.h"
#include "scratch.h"
#include "sub_mat.h"
#include "mprintf.h"
#include "str.h"

/* Philosophy...
 * Originally, substitution matrices were very fixed objects.
 * You should not have much cause to play with them. As of June
 * 2003, we introduce functions for manipulating elements.
 * To the outside world, these are symmetric objects, indexed
 * like matrix [a][w] for the Ala / Trp element.
 * Internally, we use our compacted amino acid names.
 * At the perl level, elements can be accessed either by numbers,
 * or by character names.
 */

static const mat_t INVALID = INT_MAX;
static const char  BAD_AA  = SCHAR_MAX;

/* ---------------- add_to_mat --------------------------------
 */
static int
add_to_mat (struct sub_mat *smat, const char aanames [MAX_AA],
            char *buf, int check)
{
    int n_aa = 0;
    int i;
    char *next = NULL;
    const char *this_sub = "add_to_mat";

    while ( isspace ( (int) *buf))
        buf++;
    if (*buf == '*')
        return EXIT_SUCCESS;
    if (aa_invalid (*buf)) {
        return EXIT_FAILURE;
    }
    std2thomas (buf, 1);
    if (aanames[check] != *buf) {
        char x = thomas2std_char (aanames[check]);
        thomas2std (buf, 1);
        err_printf (this_sub, "Found \"%c\", expecting \"%c\"\n",
                    *buf, x);
        err_printf (this_sub, "Line includes \"%s\"\n", buf);
        return EXIT_FAILURE;
    }
    next = ++buf;
    i = aanames [check];
    while (*buf) {
        double f;
        char j;
        buf = next;
        while ( isspace ( (int) *buf))
            buf++;
        if ( !*buf)                      /* Line could be short */
            break;
        f = strtod (buf, &next);
        j = aanames [n_aa++];
        if (j == BAD_AA)
            continue;
        smat->data[i][(int)j] = (mat_t) f;
    }
    if (n_aa < MIN_AA) {
        err_printf (this_sub, "Only found %d residues on line %d\n",
                    n_aa, check);
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}


/* ---------------- sub_mat_string ----------------------------
 */
char *
sub_mat_string (const struct sub_mat * smat)
{
    char *ret;
    int i, j;
    const char *cfmt = " %4c";
    const char *ffmt = " %4.1f";
    scr_reset();
    scr_printf ("Substitution matrix from file %s\n", smat->fname);
    if (smat -> comment)
        scr_printf ("File began with comment:\n%s\n", smat->comment);
    scr_printf (cfmt, ' ');
    for (i = 0; i < MAX_AA; i++)
        scr_printf (cfmt, thomas2std_char (i));

    scr_printf ("\n");
    for (i = 0; i < MAX_AA; i++) {
        scr_printf (cfmt, thomas2std_char (i));
        for ( j = 0; j < MAX_AA; j++) {
            mat_t x = smat->data [i] [j];
            if (x == INVALID)
                scr_printf (cfmt, '?');
            else
                scr_printf (ffmt, x);
            }
        ret = scr_printf ("\n");
    }
    return (ret);
}


/* ---------------- get_aa_names ------------------------------
 * Our input line looks like,
   A  R  N  B  D  C  Q  Z  E  G  H  I  L  K  M  F  P  S  T  W  Y  V  X  *
 * so fill out the array of amino acid names. Do not bother saving the
 * "*" entry.
 */
static int
get_aa_names (char aanames [], char *buf, const char crap)
{
    int n = 0;
    for ( ; *buf ; buf++) {
        if (isspace ((int)*buf))
            continue;

        if (aa_invalid( *buf))
            aanames [n] = crap;
        else
            aanames [n] = std2thomas_char (buf[0]);

        n++;
    }
    return EXIT_SUCCESS;
}



/* ---------------- sub_mat_copy ------------------------------
 * Make a copy of a substitution matrix. Not obviously a useful
 * thing to do, but we can overwrite the contents and manipulate
 * it.
 */
static struct sub_mat *
sub_mat_copy (const struct sub_mat *src)
{
    struct sub_mat* dst;
    int i, j;
    dst = E_MALLOC (sizeof (*dst));
    dst ->fname   = NULL;
    dst ->comment = NULL;
    dst ->fname = save_str (src->fname);
    for (i = 0; i < MAX_AA; i++)
        for (j = 0; j < MAX_AA; j++)
            dst->data[i][j] = src->data[i][j];
    return dst;
}

/* ---------------- sub_mat_read ------------------------------
 */
struct sub_mat *
sub_mat_read (const char *fname)
{
#   ifndef BUFSIZ
#       error please define BUFSIZ to around 1024
#   endif
    fpos_t pos;
    struct sub_mat *smat = NULL;
    FILE *fp;
    char buf [BUFSIZ];
    char aanames [ MAX_AA + 3];
    const char *this_sub = "read_mat";
    const char comment = '#';
    if ((fp = mfopen (fname, "r", this_sub)) == NULL)
        return NULL;

    /* Portably initialise the fpos_t structure
     * because =0 is insufficient
     */
    if (fgetpos(fp, &pos)) {
        mperror (this_sub);
        goto broken;
    }


    smat = E_MALLOC ( sizeof (*smat));
    smat -> fname   = NULL;
    smat -> comment = NULL;
    smat->fname = save_str (fname);

    while (fgets (buf, BUFSIZ, fp) != NULL) {
        if ( buf[0] != comment) {
            if (fsetpos (fp, &pos)) {
                mperror (this_sub);
                goto broken;
            }
            break;
        }
        smat->comment = save_str_append (smat->comment, buf);
        if (fgetpos(fp, &pos)) {
            mperror (this_sub);
            goto broken;
        }
    }

    if (fgets (buf, BUFSIZ, fp) == NULL)
        goto broken;
    memset (aanames, BAD_AA, MAX_AA);
    if (get_aa_names (aanames, buf, BAD_AA) == EXIT_FAILURE)
        goto broken;
    {
        int n, m;
        for (n = 0; n < MAX_AA; n++)
            for ( m = 0; m < MAX_AA; m++)
                smat->data[n][m] = (mat_t) INVALID;
    }
    {
        int n = 0;
        for ( ;fgets(buf, BUFSIZ, fp) != NULL; n++) {
            if (aanames [n] == BAD_AA)
                continue;
            if (add_to_mat (smat, aanames, buf, n) == EXIT_FAILURE)
                err_printf (this_sub, "Ignoring matrix line\n");
        }
    }

    fclose (fp);
    return smat;
 broken:
    fclose (fp);
    free_if_not_null (smat->comment);
    free_if_not_null (smat->fname);
    free_if_not_null (smat);
    return NULL;
}

/* ---------------- sub_mat_shift  ----------------------------
 * Walk up and down the substitution matrix, get the minimum
 * value. Add / substract a constant so as to make the lowest
 * element equal to bottom.
 */
struct sub_mat *
sub_mat_shift (struct sub_mat *s, mat_t bottom)
{
    struct sub_mat *dst;
    unsigned i, j;
    mat_t shift;
    mat_t min = s->data[0][0];

    dst = sub_mat_copy (s);
    for (i = 0; i < MAX_AA; i++)
        for (j = 0; j < MAX_AA; j++)
            if (dst->data[i][j] != INVALID)
                if (dst->data[i][j] < min)
                    min = dst->data[i][j];
    shift = bottom - min;
    for (i = 0; i < MAX_AA; i++)
        for (j = 0; j < MAX_AA; j++)
            if (dst->data[i][j] != INVALID)
                dst->data[i][j] += shift;
    return dst;
}

/* ---------------- sub_mat_scale  ----------------------------
 * Take a substitution matrix and scale from min to max.
 */
void
sub_mat_scale (struct sub_mat *s, mat_t bottom, mat_t top)
{
    unsigned i, j;
    float scale, shift, want_range;
    mat_t min, max, mat_range;

    min = max = s->data[0][0];

    for (i = 0; i < MAX_AA; i++) {
        for (j = 0; j < MAX_AA; j++) {
            if (s->data[i][j] != INVALID) {
                if (s->data[i][j] < min)
                    min = s->data[i][j];
                if (s->data[i][j] > max)
                    max = s->data[i][j];
            }
        }
    }
    mat_range = max - min;
    want_range = top - bottom;
    scale = want_range / mat_range;
    min *= scale;                    /* This will be the new, lowest entry */
    shift = bottom - min;
    for (i = 0; i < MAX_AA; i++) {
        for (j = 0; j < MAX_AA; j++) {
            if (s->data[i][j] != INVALID) {
                s->data[i][j] *= scale;
                s->data[i][j] += shift;
            }
        }
    }
}

/* ---------------- sub_mat_get_by_i --------------------------
 * Return the value of a substitution matrix element given by a
 * pair of integer indices.
 */
float
sub_mat_get_by_i (struct sub_mat *s, const int ndx1, const int ndx2)
{
    static const char *this_sub = "sub_mat_get_by_i";
    if (s == NULL) {
        err_printf (this_sub, "Given null pointer for sub matrix\n");
        return 0.0;
    }
    return s->data[ndx1][ndx2];
}

/* ---------------- sub_mat_set_by_i --------------------------
 * Return the value of a substitution matrix element given by a
 * pair of integer indices.
 */
int
sub_mat_set_by_i (struct sub_mat *s, const int ndx1,
                  const int ndx2, const float f)
{
    static const char *this_sub = "sub_mat_set_by_i";
    if (s == NULL) {
        err_printf (this_sub, "Given null pointer for sub matrix\n");
        return 0;}

    if (ndx1 >= MAX_AA || ndx2 >= MAX_AA) {
        err_printf (this_sub, "index %d or %d is too big\n", ndx1, ndx2);
        return EXIT_FAILURE;
    }
    s->data[ndx1][ndx2] = f;
    s->data[ndx2][ndx1] = f;
    return EXIT_SUCCESS;
}
 
static const char *inval = "Either %c or %c is an invalid amino acid\n";

/* ---------------- sub_mat_get_by_c --------------------------
 * Return the value of a substitution matrix element given by a
 * pair of character indices.
 */
float
sub_mat_get_by_c (struct sub_mat *s, const char ndx1, const char ndx2)
{
    static const char *this_sub = "sub_mat_get_by_c";
    if (s == NULL) {
        err_printf (this_sub, "Given null pointer for sub matrix\n");
        return 0.0;
    }
    if (aa_invalid ( ndx1) || aa_invalid (ndx2)) {
        err_printf (this_sub, inval, ndx1, ndx2);
        return -99999.;
    }
    return s->data[std2thomas_char (ndx1)][std2thomas_char (ndx2)];
}

/* ---------------- sub_mat_get_by_c --------------------------
 * Return the value of a substitution matrix element given by a
 * pair of character indices.
 * Unlike the "get" routine, we can return success/failure
 */
int
sub_mat_set_by_c (struct sub_mat *s, const char ndx1, const char ndx2, float f)
{
    static const char *this_sub = "sub_mat_set_by_c";
    if (s == NULL) {
        err_printf (this_sub, "Given null pointer for sub matrix\n");
        return 0;}
    if (aa_invalid ( ndx1) || aa_invalid (ndx2)) {
        err_printf (this_sub, inval, ndx1, ndx2);
        return EXIT_FAILURE;
    }
    s->data[std2thomas_char (ndx1)][std2thomas_char (ndx2)] = f;
    s->data[std2thomas_char (ndx2)][std2thomas_char (ndx1)] = f;
    return EXIT_SUCCESS;
}


/* ---------------- sub_mat_destroy ---------------------------
 */
void
sub_mat_destroy (struct sub_mat *s)
{
    free_if_not_null (s->comment);
    free (s->fname);
    free (s);
}
