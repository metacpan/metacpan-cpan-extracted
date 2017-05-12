/*
 * January 9 2001
 * Score sequence / structure using a fragment based scoring scheme
 * This will be my experimental file.
 *  - precalculate all phi psi angles and store them using calc_phi_...()
 *  - convert the phi's from my structure into conv*phi
 *  - put in a check for BAD_ANGLE
 * 
 * $Id: score_fx.c,v 1.1 2007/09/28 16:57:09 mmundry Exp $
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>


#include "coord.h"
#include "coord_i.h"
#include "e_malloc.h"
#include "mprintf.h"
#include "score_mat.h"
#include "score_fx_i.h"
#include "read_seq_i.h"
#include "seq.h"
#include "fx.h"
#include "score_fx_i.h"
#include "seqprof.h"
#include "dihedral.h"            /* use Andrew's sausage routines */

/* ---------------- Constants ------------------------------
 */
static const float FX_TINY = 1.0e-12;
#ifndef M_PI
    static const float M_PI = 3.14159265358979323846;
#endif

/* ---------------- dist2   ------------------------------------
 * Return the distance squared between two atoms.
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

/* ---------------- GetClass -------------------------------
 *
 */

static int
GetClass(struct coord *s, FXParam *fx, int *class)
{
    const char *this_sub = "GetClass";
    int     *cnt, nbr;
    size_t  i, j, k;
    float   *psi;
    float   ej;
    float   dpsi;
    float   ppsi;
    const float conv = 180 / M_PI;
    const float n_cut = 0.64; /* This is 8 Angstrom squared, in nanometers */


    if (s->size <= fx->nr_inst) {
        err_printf (this_sub, "Struct siz too small(%u)\n", (unsigned)s->size);
        return EXIT_FAILURE;
    }
      /* the number of neighbours and psi-angles could probably be
         pre-calculated and put into coord->psi !!!
         just for now we don't  */

                                        /* malloc temp space */
    cnt = E_MALLOC (s->size * sizeof(cnt[0]));
    memset (cnt, 0, s->size * sizeof(cnt[0]));
    psi = E_MALLOC (s->size * sizeof(psi[0]));
    memset (psi, 0, s->size * sizeof(psi[0]));

                                        /* count number of neighbours */


    for (i = 0; i < s->size; i++) {
        for (j = i+4; j < s->size; j++) {
            float d = dist2 ( s->rp_cb[i], s->rp_cb[j]);
            if (d < n_cut) {             /* 8A cutoff CB-CB dist */
                ++cnt[i];
                ++cnt[j];
            }
        }
    }
                                        /* calc psi dihedral angle */
    for (i = 0; i < s->size-1; i++) {
        psi[i] = conv * dihedral(s->rp_n[i], s->rp_ca[i], s->rp_c[i],
                                 s->rp_n[i+1]);
    }

                                        /* run over all overlapping fragments
                                           and determine optimal class */
    for (i = 0; i < s->size - fx->nr_inst; i++) {
        float emax = -1.0e+10;
        int jmax = -1;

        float d;  /* CA-CA end-to-end distance */
        d = sqrt (dist2 (s->rp_ca[i], s->rp_ca[i+fx->nr_inst-1]));

        for (j = 0; j < fx->nr_groups; j++) {
            float tmp;
            ej = 0;
            for (k = 0; k < fx->nr_inst; k++) {
                float tmp2;
                                        /* Gaussian model for psi dihedral */
                dpsi = psi[i+k] - fx->psi[j][k];
                if (dpsi > 180)
                    dpsi -= 360;
                else if (dpsi < -180)
                    dpsi += 360;
                tmp2 = 2 * fx->dpsi[j][k] * fx->dpsi[j][k];
                ppsi = exp(-dpsi*dpsi/tmp2) / sqrt(M_PI*tmp2);

                if (ppsi > FX_TINY)
                    ej += log(ppsi);
                else
                    ej += log(FX_TINY);

                                /* discrete profile for number of neighbours */
                nbr = cnt[i+k];
                if (nbr >= 20)          /* just in case */
                    nbr = 19;
                ej += fx->pna[j][k][nbr];
            }

                                         /* because we use a non-linear scale
                                           we have to find the right bin */
            for ( k = 0; k < fx->nr_dbins; k++)
                if (fx->dbin[k] > d)
                    break;
            if (k)
                k--;

            dpsi = k - fx->pdav[j];
            tmp = 2 * fx->pdsig[j] * fx->pdsig[j];
            ppsi = exp(-dpsi*dpsi/tmp) / sqrt(M_PI*tmp);

            if (ppsi > FX_TINY)
                ej += log(ppsi);
            else
                ej += log(FX_TINY);


            if (ej > emax) {
                emax = ej;
                jmax = j;
            }
        }
        if (jmax != -1)
            class[i] = jmax;
        else {
            err_printf (this_sub, "BUGGER ALL: no class of fragment!!! \n");
            exit(EXIT_FAILURE);
        }
    }
    free(cnt);
    free(psi);
    return EXIT_SUCCESS;
}

/* ---------------- score_fx -------------------------------
 * Score a sequence and structure using a fragment based
 * scoring function.
 * The contents of the param should be whatever was returned
 * by the param reading routine.
 * Note, the matrix we get is has two extra rows and two extra
 * columns. One at the start and end.
 * You *are* allowed to assume that the matrix is zeroed.
 */

int
score_fx (struct score_mat *score_mat, struct seq *s,
          struct coord *c1, struct FXParam *fx)
{
    const char *this_sub = "score_fx";
    size_t   i;
    int      j, jlast, k, kk;
    int      aa1, classi;
    int      *class, middle, middle_plus1;
    float    ei, **scores = score_mat->mat;
    size_t   to_mall;

    /* It is almost impossible to be given obvious garbage by the
     * interpreter, but this is the kind of check and error exit
     * we do
     */
    if (score_mat == NULL || s == NULL || c1 == NULL || fx == NULL) {
        err_printf (this_sub, "null parameter, FIX \n");
        return (EXIT_FAILURE);
    }

    seq_std2thomas (s);          /* Force Thomas style names for amino acids */
    coord_a_2_nm (c1);     /* Force coordinates to nanometers if they were A */
    to_mall = c1->size * sizeof (class[0]);
    class = E_MALLOC (to_mall);              /* Bayes class of each fragment */
    memset (class, 0, to_mall);


    if (GetClass(c1, fx, class) == EXIT_FAILURE) {        /* get Bayes class */
        free (class);
        err_printf (this_sub, "Error on coord %s\n", coord_name(c1));
        return (EXIT_FAILURE);
    }

/*
  In the structure the first fragment_size/2 and last fragment_size/2+1
  (one extra residue is lost due to the missing psi dihedral)
  residues are ignored.
  To the sequence virtually fragment_size/2 zero-residues are pre- and
  appended, which allows that the first (real) amino acid can be aligned
  with the middle of the first fragment.
  => the score matrix is fill for elements in [m:n_str-m-1][1:n_seq],
  where m is half the size of the fragment, n_str is the size of the
  structure and n_seq the size of the sequence.
*/

    middle = fx->nr_inst / 2;
    middle_plus1 = middle + 1;

    jlast = s->length - middle_plus1;
    if ((s->length - middle_plus1) < 1)
        err_printf (this_sub, "Sequence very short !\n");

    /* Do not assume the matrix is zeroed, although recent
     * versions of code have done so.
     */

    for (j = 0; j < (int) s->length+2; j++)
        for (i = 0; i < c1->size+2; i++)
            scores[j][i] = 0;


    for (j = -middle; j < jlast; j++) {
        for (i = 0; i < c1->size - fx->nr_inst; i++) {  /* last psi missing! */
            classi = class[i];
            ei = 0;
            for (k = 0; k < (int) fx->nr_inst; k++) {
                kk = j + k;
                if ((kk >= 0) && (kk < (int) s->length)) {
                    aa1 = s->seq[j+k];
                    ei += fx->paa[classi][k][aa1];
                }
            }
            scores[j+middle_plus1][i+middle_plus1] = ei;
        }

    }
    free(class);
    coord_nm_2_a (c1);            /* Convert back to Angstrom from nanometer */
    return EXIT_SUCCESS;
}
/* ---------------- score_fx_prof --------------------------
 * This is a copy of the routine above (score_fx()), but
 * with the variation that it takes a sequence profile,
 * rather than simple sequence.
 */

int
score_fx_prof (struct score_mat *score_mat, struct seqprof *sp,
          struct coord *c1, struct FXParam *fx)
{
    const char *this_sub = "score_fx";
    size_t   i;
    int      j, jlast;
    int      *class, middle, middle_plus1;
    float    **scores = score_mat->mat;
    size_t   to_mall;
    /* It is almost impossible to be given obvious garbage by the
     * interpreter, but this is the kind of check and error exit
     * we do
     */
    if (score_mat == NULL || sp == NULL || c1 == NULL || fx == NULL) {
        err_printf (this_sub, "null parameter, FIX \n");
        return (EXIT_FAILURE);
    }

    coord_a_2_nm (c1);     /* Force coordinates to nanometers if they were A */
    to_mall = c1->size * sizeof (class[0]);
    class = E_MALLOC (to_mall);              /* Bayes class of each fragment */
    memset (class, 0, to_mall);


    if (GetClass(c1, fx, class) == EXIT_FAILURE) {        /* get Bayes class */
        free (class);
        err_printf (this_sub, "Error on coord %s\n", coord_name(c1));
        return (EXIT_FAILURE);
    }

/*
  In the structure the first fragment_size/2 and last fragment_size/2+1
  (one extra residue is lost due to the missing psi dihedral)
  residues are ignored.
  To the sequence virtually fragment_size/2 zero-residues are pre- and
  appended, which allows that the first (real) amino acid can be aligned
  with the middle of the first fragment.
  => the score matrix is fill for elements in [m:n_str-m-1][1:n_seq],
  where m is half the size of the fragment, n_str is the size of the
  structure and n_seq the size of the sequence.
*/

    middle = fx->nr_inst / 2;
    middle_plus1 = middle + 1;

    jlast = sp->seq->length - middle_plus1;
    if ((sp->seq->length - middle_plus1) < 1)
        err_printf (this_sub, "Sequence very short !\n");

    /* Do not assume the matrix is zeroed, although recent
     * versions of code have done so.
     */

    {
        size_t jj, ii;
        for (jj = 0; jj < sp->seq->length+2; jj++)
            for (ii = 0; ii < c1->size+2; ii++)
                scores[jj][ii] = 0;
    }

    for (j = -middle; j < jlast; j++) {
        for (i = 0; i < c1->size - fx->nr_inst; i++) {  /* last psi missing! */
            int k;
            int classi = class[i];
            float ei = 0;
            for (k = 0; k < (int) fx->nr_inst; k++) {
                size_t kk = j + k;
                if ((kk > 0) && (kk < sp->seq->length)) {
                    short unsigned p;
                    for (p = 0; p < blst_afbet_size; p++)
                        ei += fx->paa[classi][k][p] * sp->freq_mat[j+k][p];
                }
            }
            scores[j+middle_plus1][i+middle_plus1] = ei;
        }

    }
    free(class);
    coord_nm_2_a (c1);            /* Convert back to Angstrom from nanometer */
    return EXIT_SUCCESS;
}
