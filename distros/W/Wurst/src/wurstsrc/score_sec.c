/*
 * 27 Feb 2002
 * Score Sequence / structures according to secondary
 * structure information.
 *
 * $Id: score_sec.c,v 1.1 2007/09/28 16:57:06 mmundry Exp $
 */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "coord.h"
#include "coord_i.h"
#include "mprintf.h"
#include "sec_s.h"
#include "score_mat.h"
#include "score_sec_i.h"

/* ---------------- Constants ---------------------------------
 */
/* psi angle in alpha helix and beta sheet. These are literature
 * values and have to be turned into radians.
 */
#ifndef M_PI
#   define M_PI 3.14159265358979323846
#endif

static const float ALPHA_ANGLE = -47 * (M_PI / 180);
static const float BETA1_ANGLE  = 113 * (M_PI / 180); /* parallel */
static const float BETA2_ANGLE  = 135 * (M_PI / 180); /* anti parallel */


/* ---------------- penalty_sec_s -----------------------------
 * This is where we actually calculate the penalty or score for
 * matching secondary structure. We need to know the psi angle
 * from the structure, the predicted/measured secondary structure
 * and a reliability number.
 * Currently, reliability is only used to the extent that we do
 * use data unless reliability >= 8.
 * There is another fun aspect. A predicted beta structure could
 * be parallel or antiparallel. We check both and use the one that
 * is closest.
 */
static float
penalty_sec_s (const float psi, const enum sec_typ sec_typ,
               const unsigned char rely)
{
    float diff;
#   ifndef M_PI_2
        const float M_PI_2 = M_PI / 2;
#   endif    
    if (rely < 8)
        return 0.0;
    if ( sec_typ != HELIX && sec_typ != EXTEND)
        return 0.0;
    if ( sec_typ == HELIX) {
        diff = psi - ALPHA_ANGLE;
    } else {
        float d1 = fabs (psi - BETA1_ANGLE);
        float d2 = fabs (psi - BETA2_ANGLE);
        if (d1 < d2)
            diff = d1;
        else 
            diff = d2;
    }
    if ( fabs (diff) > M_PI_2)
        return 0.0;
    else
        return (cos (diff));
}

/* ---------------- score_sec   -------------------------------
 * Score a sequence and structure using secondary structure
 * information.
 * Remember, as always, our matrix is rows+2 x cols+2 big.
 *
 */

int
score_sec(struct score_mat *score_mat, struct sec_s_data *sec_s_data,
          struct coord *c)
{
    float **scores = score_mat->mat;
    struct sec_datum *datum, *dlast;
    const char *this_sub = "score_sec";
    const size_t n_rows = score_mat->n_rows;
    const size_t n_cols = c->size + 2;
    const size_t n_sec  = sec_s_data->n;
    const size_t last_sec = sec_s_data->data[n_sec - 1].resnum;

    if (last_sec > n_rows - 2) {
        const char *a = "Mismatch of matrix rows (%u)\n";
        err_printf (this_sub, a, (unsigned) n_rows - 2);
        err_printf (this_sub, "with last element of sec struct info %u ",
                    (unsigned) last_sec + 1);
        err_printf (this_sub, "file %s: %d\n", __FILE__, __LINE__);
        return EXIT_FAILURE;
    }
    /*    coord_get_psi (c); *//* Just ensures that we have valid psi angles */
    {
        size_t toclear = n_rows * n_cols * sizeof (scores[0][0]);
        memset (scores[0], 0, toclear);
    }
    datum = sec_s_data->data;
    dlast = datum + sec_s_data->n;
    for ( ; datum < dlast; datum++) {
        size_t i = datum->resnum + 1;
        enum sec_typ sec_typ  = datum->sec_typ;
        size_t j;
        for (j = 1; j < n_cols - 1; j++) {
            float cost = penalty_sec_s (c->psi[j-1], sec_typ, datum->rely);
            scores[i][j] = cost;
        }
    }
    return EXIT_SUCCESS;
}
