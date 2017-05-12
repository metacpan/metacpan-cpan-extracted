/* 16 Nov 2005
 * Fill a score matrix with random numbers.
 * We pass in the mean and standard deviation as parameters.
 * The numbers are gaussian distributed, although it is not clear
 * why this is useful. A uniform distribution should also be OK.
 *
 * $Id: score_rand.c,v 1.1 2007/09/28 16:57:08 mmundry Exp $
 */

#include <stdlib.h>

#include "rand.h"
#include "score_mat.h"
#include "score_rand.h"




/* ---------------- score_rand  -------------------------------
 * Score two sequences using a gaussian distributed random numbers.
 */
void
score_rand (struct score_mat *score_mat, const float mean, const float std_dev)
{
    const size_t n_rows = score_mat->n_rows;
    const size_t n_cols = score_mat->n_cols;
    float **scores = score_mat->mat;
    size_t i, j;

    /* matrix is n_rows (s1), n_cols (s2) */
    for (i = 0; i < n_cols ; i++)
        scores[0][i] = 0;                   /* First row */
    for (i = 0; i < n_cols ; i++)
        scores[n_rows - 1][i] = 0;          /* Last row */
    for (i = 0; i < n_rows ; i++)
        scores [i][0] = 0;                  /* First column */
    for (i = 0; i < n_rows ; i++)
        scores [i][n_cols - 1 ] = 0;        /* Last column */

    for (i = 1; i < n_rows - 1; i++) {
        for (j = 1; j < n_cols - 1 ; j++) {
            scores [i][j] = g_rand (mean, std_dev);
        }
    }
}
