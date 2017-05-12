/*
 * 8 March 2002.
 * Print pair_set in a prettier manner.
 * We do all output via scr_printf() which fills a buffer and
 * hands it to the interpreter.
 *
 * $Id: pair_set_p.c,v 1.2 2008/01/20 17:07:32 torda Exp $
 */

#include <ctype.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "coord.h"
#include "dbg.h"
#include "e_malloc.h"
#include "mprintf.h"
#include "pair_set.h"
#include "pair_set_p_i.h"
#include "read_seq_i.h"
#include "scratch.h"
#include "sec_s.h"
#include "sec_s_i.h"
#include "seq.h"
#include "yesno.h"

/* ---------------- Constants      -----------------------------
 */
static const char *NL = "\n";
enum { CHAR_PER_LINE = 60 }; /* Change this if you want more per
                                line of alignment output. Nothing
                                else will break. */

/* ---------------- Structures local ---------------------------
 */
struct triplet {
    unsigned length;
    unsigned aligned;
    unsigned ident;
};

/* ---------------- getmax         -----------------------------
 * Walk backwards down an array of numbers and find the largest
 * which is an interesting number (not -1);
 */
static int
getmax (int *first, int *last) {
    int *i;
    for (i = last - 1; i >= first; i--)
        if (*i != GAP_INDEX)
            return *i;
    return GAP_INDEX;
}

/* ---------------- xtrct    -----------------------------------
 * Given a number, return the ord'th digit, counting from
 * right. Given 123456, and asked for the two'th digit, return
 * 5.
 */
static int
xtrct (int num, const int ord)
{
    int tmp, i;
    tmp = num;
    for (i = 0; i < ord; i++)
        tmp /= 10;
    for (i = 0; i < ord; i++)
        tmp *= 10;
    tmp = num - tmp;
    for (i = 1; i < ord; i++)
        tmp /=10;
    return tmp;
}

/* ---------------- do_nums        -----------------------------
 * This reads our array of numbers and actually prints out the
 * digits.
 */
static void
do_nums ( int *first, int *last)
{
    unsigned ord, orders;
    int maxtop = getmax (first, last);
    if (maxtop <= 0)
        return;
    orders = (unsigned) log10 ((double) maxtop) + 1;
    for (ord = orders; ord > 0; ord--) {
        int *p;
        for ( p = first; p < last; p++) {
            int n = *p + 1;
            if ( n ) { /* if it is a gap, *p = -1, so we skip this */
                char c = ' ';
                if ( ! (n % 5))
                    c = ':';
                if ( ! (n % 10))
                    c = xtrct (n, ord) + '0';
                scr_printf ("%c", c);
            } else {
                scr_printf ("%c", ' ');
            }
        }
        scr_printf (NL);
    }
}

/* ---------------- do_strings     -----------------------------
 */
static void
do_strings ( char *sfirst, char *slast)
{
    for ( ; sfirst < slast; sfirst++)
        scr_printf ("%c", *sfirst);
    scr_printf (NL);
}

/* ---------------- do_printing    -----------------------------
 * We are given arrays of numbers to go at top and bottom,
 * along with a null terminated array of strings.
 * Print them with c_per_line on each line.
 */
static char *
do_printing (int *numtop, int *numbottom, char **strings, size_t length,
             size_t c_per_line)
{
    size_t done = 0;
    char **s;
    char *t;

    while (done < length) {
        unsigned this = c_per_line;
        if (this > length - done)
            this = length - done - 1;

        do_nums (numtop + done, numtop + done + this);
        s = strings;
        while ((t = *s++))
            do_strings (t + done, t + done + this);
        do_nums (numbottom + done, numbottom + done + this);
        scr_printf (NL);
        done += c_per_line;
    }
    return (scr_printf ("%s", ""));
}

/* ---------------- get_seq_id    ------------------------------
 * For our alignment, get out the % sequence identity.
 * Do not count gaps.
 */
static struct triplet
get_seq_id ( struct pair_set *pair_set, struct seq *s1, struct seq *s2)
{
    struct triplet result;
    unsigned length, aligned, ident;
    int **p;
    size_t i;
    p = pair_set->indices;

    if(s1->format == THOMAS) seq_thomas2std (s1);
    if(s2->format == THOMAS) seq_thomas2std (s2);

    length = aligned = ident = 0;
    for ( i = 0; i < pair_set->n; i++ ) {
        int a = p[i][0], b = p[i][1];
        length++;
        if ((a == GAP_INDEX) || (b == GAP_INDEX))
            continue;
        aligned++;
        if (tolower(s1->seq[a]) == tolower(s2->seq[b]))
            ident++;
    }
    result.length = length;
    result.ident = ident;
    result.aligned = aligned;
    if (length != pair_set->n)
        err_printf ("get_seq_id", "Silly bloody bug %s\n", __FILE__);
    return (result);
}

unsigned
get_seq_id_simple (  struct pair_set *pair_set, struct seq *s1, struct seq *s2 ){
	struct triplet result = get_seq_id(pair_set, s1, s2);
	return (result.ident);
}

/* ---------------- pair_set_pretty_string ---------------------
 * The philosophy is that we begin by assuming the worst case -
 * two essentially unaligned sequences. We then fill out long
 * strings for each sequence with either residues or gaps.
 */
char *
pair_set_pretty_string (struct pair_set *pair_set,
                        struct seq *s1, struct seq *s2,
                        struct sec_s_data *sec_s_data, struct coord *c2)
{
    char **strings;
    char *res;
    char *seq1, *seq2;
    char *sec_s1 = NULL,
         *sec_s2 = NULL;
    char *tmpsec1, *tmpsec2;
    int *numtop, *numbottom;
    size_t i, length, idx;
    enum yes_no do_sec = NO;
    const char *empty = " - Empty Alignment -";
    const char *this_sub = "pair_set_pretty_string";

    tmpsec1 = tmpsec2 =          /* not needed, but removes compiler warning */
    sec_s1 = sec_s2 = NULL;
    scr_reset();
    if (pair_set->n == 0)
        return (scr_printf ("%s", empty));
    length = (pair_set->n + 1);

    if (sec_s_data && c2)    /* Decide whether or not to print sec structure */
        do_sec = YES;

    if (do_sec) {
        if (s2->length != c2->size) {
            err_printf (this_sub, "Arguments broken. mismatch\n");
            err_printf (this_sub, "size of sequence != coord\n");
            err_printf (this_sub, "%u != %u\n", (unsigned) s2->length,
                        (unsigned) c2->size);
            return ((char *) "");
        }
    }

    seq1 = E_MALLOC ( length * sizeof (seq1[0]));
    seq2 = E_MALLOC ( length * sizeof (seq1[0]));
    numtop = E_MALLOC ( length * sizeof (numtop[0]));
    numbottom = E_MALLOC (length * sizeof (numbottom[0]));
    memset (seq1, '-', length);
    memset (seq2, '-', length);
    for (i = 0; i < length; i++) {
        numtop[i] = GAP_INDEX;
        numbottom[i] = GAP_INDEX;
    }
    seq1[length -1] = '\0';
    seq2[length -1] = '\0';

    if (do_sec) {
        struct sec_datum *d, *dlast;
        char *t1, *t2, *t1last, *t2last;
        int *p;
        size_t tomall;
        char nosec = ' ';
        tmpsec1 = E_MALLOC (tomall = s1->length * sizeof (tmpsec1[0]));
        memset (tmpsec1, ' ', tomall);
        tmpsec2 = E_MALLOC (tomall = s2->length * sizeof (tmpsec2[0]));
        memset (tmpsec2, ' ', tomall);

        t1last = tmpsec1 + s1->length;
        for ( t1 = tmpsec1; t1 < t1last; t1++)
            *t1 = nosec;
        t2last = tmpsec2 + s2->length;
        for ( t2 = tmpsec2; t2 < t2last; t2++)
            *t2 = nosec;

        d = sec_s_data->data;
        dlast = d + sec_s_data->n;
        for ( ;d < dlast; d++)
            if (d->sec_typ != NO_SEC)
                tmpsec1[d->resnum] = ss2char (d->sec_typ);
        for ( t2 = tmpsec2, p = c2->sec_typ; t2 < t2last; p++, t2++)
            if (*p != NO_SEC)
                *t2 = ss2char (*p);
    }

    if(s1->format == THOMAS) seq_thomas2std (s1);
    if(s2->format == THOMAS) seq_thomas2std (s2);

    { /* This fills out the basic sequence strings and lists of seq numbers */
        int **p;
        char *t1 = seq1,
             *t2 = seq2;
        int *nt  = numtop,
            *nb  = numbottom;
        p = pair_set->indices;
        for ( idx = 0; idx < pair_set->n; idx++, t1++, t2++, nt++, nb++) {
            int a = p[idx][0], b = p[idx][1];
            if (a != GAP_INDEX) {
                *t1 = s1->seq[a];
                *nt = a;
            }
            if (b != GAP_INDEX) {
                *t2 = s2->seq[b];
                *nb = b;
            }
        }
    }
    if (do_sec) {
        int **p;
        char *t1 = sec_s1 = E_MALLOC ( length * sizeof (sec_s1[0])),
             *t2 = sec_s2 = E_MALLOC ( length * sizeof (sec_s2[0]));
        memset (t1, ' ', length * sizeof (sec_s1 [0]));
        memset (t2, ' ', length * sizeof (sec_s2 [0]));
        p = pair_set->indices;
        for (idx = 0 ; idx < pair_set->n; idx++, t1++, t2++) {
            int a = p[idx][0], b = p[idx][1];
            if (a != GAP_INDEX)
                *t1 = tmpsec1[a];
            if (b != GAP_INDEX)
                *t2 = tmpsec2[b];
        }
        free (tmpsec1);
        free (tmpsec2);
    }
    strings = E_MALLOC (5 * sizeof (strings[0]));
    strings [0] = seq1;
    strings [1] = seq2;
    strings [2] = NULL;
    if (do_sec) {
        strings [2] = sec_s1;
        strings [3] = sec_s2;
        strings [4] = NULL;
    }

    scr_reset();
    {
        float f;
        struct triplet r = get_seq_id (pair_set, s1, s2);
        f = ((float) r.ident / (float) r.aligned) * 100;
        scr_printf ("Seq ID %.3g %% (%u / %u) in %u total including gaps\n",
                    f, r.ident, r.aligned, r.length);
    }
    res = do_printing (numtop, numbottom, strings, length, CHAR_PER_LINE);
    free (strings);
    free_if_not_null(sec_s1);
    free_if_not_null(sec_s2);
    free (numtop);
    free (numbottom);
    free (seq1);
    free (seq2);
    return res;
}
