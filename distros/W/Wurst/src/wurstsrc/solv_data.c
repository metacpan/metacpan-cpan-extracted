/*
 * 27 Oct 2005
 * As part of the score function rebuilding, I need to reassess
 * the solvation term.
 * This is a disposable file, just for data collection.
 * I do not want to build this into perl properly, so I do not
 * want to define a perl type. Instead, I will declare an array
 * of file types and write the data for each amino acid into its
 * own file.
 *
 * $Id: solv_data.c,v 1.1 2007/09/28 16:57:03 mmundry Exp $
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "amino_a.h"
#include "coord.h"
#include "coord_i.h"
#include "e_malloc.h"
#include "fio.h"
#include "mprintf.h"
#include "read_seq_i.h"
#include "solv_data.h"

static const float  cut = 64.0;         /* 8 Angstrom squared */
/* ---------------- int_2_name --------------------------------
 * Given the integer for an amino acid, build the corresponding
 * data file name.
 */
static char *
int_2_name ( size_t i, char *name, const size_t max_len)
{
    memset (name, 0, max_len);
    name[0] = thomas2std_char ((char)i);
    strncat (name, "_nbor.dat", max_len);
    return name;
}

/* ---------------- dist2   ------------------------------------
 * Return the distance squared between two atoms. I know this
 * does not really merit a function, but the code occurs three
 * times in a row below.
 */
static float
dist2 ( const struct RPoint a, const struct RPoint b)
{
    float x, y, z;
    x = a.x - b.x;
    y = a.y - b.y;
    z = a.z - b.z;
    return (x * x + y * y + z * z);
}

/* ---------------- add_nbor ----------------------------------
 * We want to do the same loop, looking for c alpha neighbours,
 * nitrogen neighbours, .... So put the loop in a single function.
 */
static void
add_nbor (short unsigned *nbor_all,
          const struct RPoint *rp_cb, const struct RPoint *r_nbor,
          const size_t c_len)
{
    size_t i;
    for (i = 0; i < c_len; i++) {
        int j, jmax;
        size_t k;
        jmax = i - 4;
        for (j = 0; j < jmax; j++)
            if (dist2(rp_cb[i], r_nbor[j]) < cut)
                nbor_all[i]++;
        for (k = i + 4; k < c_len; k++)
            if (dist2(rp_cb[i], r_nbor[k]) < cut)
                nbor_all[i]++;
    }
}

/* ---------------- get_nbor ----------------------------------
 * The first time we are called, we clear the files.
 * On subsequent calls, we append to each file.
 * File pointers are indexed via the amino acid name in Thomas
 * style (0 to 19). File names will be created based on the
 * conventional one letter amino acid code.
 */
int
get_nbor (struct coord *c)
{
    FILE *fpa [MAX_AA];
    FILE *fp_all;
    const char *s;
    short unsigned *nbor_b, *nbor_othr, *nbor_tot;
    size_t a, j, n, c_len, to_mall;
    const char *all_name = "all_nbor.dat";
    const char *this_sub = "get_nbor";
    static int first = 1;
    enum { NAM_LEN = 50};
    const size_t MIN_COORD = 40;

    if (first) {                           /* Executed on first call only */
        FILE *fp2;
        size_t i;
        first = 0;

        for (i = 0; i < MAX_AA; i++) {     /* Loop to create an empty file */
            FILE *fp;                      /* for each amino acid type. */
            char name[ NAM_LEN ];
            int_2_name (i, name, NAM_LEN);
            if (! (fp = mfopen (name, "w", name)))
                return EXIT_FAILURE;
            fclose (fp);
        }
        if (! (fp2 = mfopen (all_name, "w", all_name)))
            return EXIT_FAILURE;
        fclose (fp2);
    }
    c_len = coord_size (c);
    if (c_len < MIN_COORD)
        return EXIT_FAILURE;
    coord_nm_2_a (c);     /* Force angstroms as units */

    nbor_b = E_CALLOC (c_len, sizeof (nbor_b[0]));
    for (j = 0; j < c_len - 1; j++) {
        size_t k;
        for (k = j + 4; k < c_len; k++) {
            float d = dist2 (c->rp_cb[j], c->rp_cb[k]);
            if (d < cut) {
                nbor_b [j]++;
                nbor_b [k]++;
            }
        }
    }

    nbor_othr = E_MALLOC (to_mall = c_len * sizeof (nbor_othr[0]));
    memset (nbor_othr, 0, to_mall);
    /*   memcpy (nbor_othr, nbor_b, to_mall);*//* This total includes C beta */
    add_nbor (nbor_othr, c->rp_cb, c->rp_ca, c_len);
    add_nbor (nbor_othr, c->rp_cb, c->rp_n,  c_len);
    add_nbor (nbor_othr, c->rp_cb, c->rp_c,  c_len);
    add_nbor (nbor_othr, c->rp_cb, c->rp_o,  c_len);

    nbor_tot = E_MALLOC (to_mall);
    for (n = 0; n < c_len; n++)
        nbor_tot[n] = nbor_b[n] + nbor_othr[n];

    /* all of the neighour counting is finished. Now do printing counting...*/
    for (n = 0; n < MAX_AA; n++) {         /* Get the files open and ready */
        char name [NAM_LEN];               /* to be appended to */
        fpa[n] = mfopen ( int_2_name (n, name, NAM_LEN), "a", "aafile");
        if (fpa[n] == NULL)
            return EXIT_FAILURE;
    }
    if (! (fp_all = mfopen (all_name, "a", all_name)))
        return EXIT_FAILURE;
    {
        size_t s_len;
        s = seq_get_thomas (coord_get_seq (c), &s_len);
        if (s_len != c_len) {
            err_printf (this_sub, "c_len %u s_len %u bust\n", 
                        (unsigned int)c_len, (unsigned int)s_len);
            return EXIT_FAILURE;
        }
    }

    for (a = 0; a < c_len; a++) {
        mfprintf (fpa[s[a]], "%hu %hu %hu\n",
                 nbor_b[a], nbor_othr[a], nbor_tot[a]);
        mfprintf (fp_all, "%c %hu %hu %hu\n",
                 thomas2std_char (s[a]), nbor_b[a], nbor_othr[a], nbor_tot[a]);
    }

    {
        short unsigned k;
        for (k = 0; k < MAX_AA; k++)
            fclose (fpa[k]);
    }
    fclose (fp_all);
    free (nbor_b);
    free (nbor_othr);
    free (nbor_tot);
    return EXIT_SUCCESS;
}
