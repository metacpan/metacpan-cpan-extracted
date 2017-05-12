/*
 * 27 Aug 2001
 * $Id: align.c,v 1.1 2007/09/28 16:57:06 mmundry Exp $
 */

#include <float.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "align_i.h"
#include "amino_a.h"
#include "e_malloc.h"
#include "matrix.h"
#include "mprintf.h"
#include "pair_set.h"
#include "score_mat.h"
#include "score_mat_i.h"

static const unsigned char DIAG   = 0x01;
static const unsigned char POPEN  = 0x02;
static const unsigned char PWIDEN = 0x04;
static const unsigned char QOPEN  = 0x08;
static const unsigned char QWIDEN = 0x10;
static const unsigned char TERM   = 0x20;

enum align_type {
    N_AND_W = 0,
    S_AND_W = 1
};

/* ---------------- trace_mat   -------------------------------
 * There are unused rows and columns at the start and end, so
 * out search for a starting point is from 1..n-1, not 0..n.
 * Now, we have the possibility to stop tracing when the score
 * goes below some value.
 * We begin by a pass over the score matrix.  We need two things
 * We need a starting point.
 * If we want to stop tracing when values go negative, then
 * we can also check the score values. If they go negative, put
 * a TERM marker in the direction array.
 *
 * Yukky coding note..
 * If we use #defines for QOPEN, TERM, etc... there are no problems.
 * If, however, we use const variables, then we can't use them in a
 * switch statement. This means we have to use if/else if's.
 */
static struct pair_set
trace_mat (unsigned char ** direction, float ** score_mat,
           size_t n_rows, size_t n_cols, enum align_type align_type)
{
   int **pairs;
   int *tmp;
   size_t i, j, i_off, j_off, mid;
   float max;
   size_t npair;
   struct pair_set pair_set;

   unsigned char d;
   const float threshold = 0;   /* Will be turned into a parameter later */
   const char *this_sub = "trace_mat";

   pairs = i_matrix ((n_rows + n_cols), 2);
   if ( align_type == S_AND_W ) {                    /* Smith and Waterman */
       max = score_mat[1][1];                        /* Find best value in */
       j_off = 1;                                    /* whole matrix. */
       i_off = 1;
       for (i = 1; i < n_rows - 1; i++) {
           for ( j = 1 ; j < n_cols - 1; j++) {
               if (score_mat[i][j] > max) {
                   max = score_mat[i][j];
                   j_off = j;
                   i_off = i;
               } else if (score_mat[i][j] <= threshold) {
                   direction [i][j] = TERM;
               }
           }
       }
   } else {                               /* This is Needleman and Wunsch  */
       const size_t ir = n_rows - 2; /* the i's */
       const size_t ic = n_cols - 2; /* the j's */
       max = score_mat[ir][ic];
       i_off = ir;
       j_off = ic;
       for (j = 1; j < ic; j++) {
           if (score_mat[ir][j] > max) {
               max = score_mat[ir][j];
               i_off = ir;
               j_off = j;
           }
       }
       for (i = 1; i < ir; i++) {
           if (score_mat[i][ic] > max) {
               max = score_mat[i][ic];
               i_off = i;
               j_off = ic;
           }
       }
   }

   pair_set.score = max;

   i = i_off;
   j = j_off;
   d = direction [i][j];
   npair = 0;
   while (d != TERM) {
       if ( d == DIAG ) {
           pairs [npair][0] = i;
           pairs [npair][1] = j;
           i--; j--;
       } else if (d == POPEN || d == PWIDEN ) {
           pairs [npair][0] = GAP_INDEX;
           pairs [npair][1] = j;
           j--;
       } else if (d == QOPEN || d == QWIDEN ) {
           pairs [npair][0] = i;
           pairs [npair][1] = GAP_INDEX;
           i--;
       } else {
           err_printf (this_sub, "prog bug %s %d\n", __FILE__, __LINE__);
           exit (EXIT_FAILURE);
       }
       d = direction [i][j];
       npair++;
   }

   pairs = crop_i_matrix( pairs, npair, 2 );


   mid = npair / 2;  /* We traced backwards, so now reverse order of pairs */
   tmp = E_MALLOC(n_cols * sizeof(int));
   for (i = 0, j = npair - 1; i < mid; i++, j--) {
       tmp[0] = pairs[i][0];
       tmp[1] = pairs[i][1];
       pairs [i][0] = pairs[j][0];
       pairs [i][1] = pairs[j][1];
       pairs[j][0] = tmp[0];
       pairs[j][1] = tmp[1];
   }
   free(tmp);
   pair_set.indices = pairs;
   pair_set.n = npair;
   pair_set.m = 2;                  /* In a new pair_set, we know we */
   return pair_set;                 /* have only two objects aligned */
}

/* ---------------- add_bias      -----------------------------
 * Add bias to a score matrix. Return the total amount of bias
 * added in.
 */
static float
add_bias (const struct pair_set *bias_set,
          float **sum_mat, const struct score_mat *smat)
{
    typedef int **i_p;
    const i_p p = bias_set->indices;
    float min, max, av, std_dev;
    float add_on, bias;
    size_t i;
    score_mat_info (smat, &min, &max, &av, &std_dev);
    add_on = max * 10;
    bias = 0.0;

    for ( i = 0; i < bias_set->n; i++) {
        int nc, nr;
        nc = p[i][0];
        nr = p[i][1];
        if (nc == GAP_INDEX)
            continue;
        if (nr == GAP_INDEX)
            continue;

        sum_mat[nc + 1][nr + 1] += add_on;
        bias += add_on;
    }

    return bias;
}

/* ---------------- fill_ones     -----------------------------
 * Allocate and fill an array with ones.
 */
static float *
fill_ones (size_t n)
{
    float *array = E_MALLOC (n * sizeof (array[0]));
    float *f = array;
    float *flast = f + n;
    for ( ; f < flast ; f++)
        *f = 1;
    return array;
}

/* ---------------- smpl_score   ------------------------------
 * We have done a full scoring of a matrix, a summation and
 * tracing back. Now, given a pair_set and alignment, get the
 * total score of the aligned positions. This means the score,
 * without the gap penalties.
 */
static void
smpl_score (struct pair_set *pair_set, const struct score_mat *smat)
{
    int **p;
    size_t i;
    float **mat = smat->mat;
    float smpl = 0.0;
    p = pair_set->indices;

    for (i=0; i < pair_set->n; i++){
        int nc, nr;
        nc = p[i][0];
        nr = p[i][1];
        if (nc == GAP_INDEX)
            continue;
        if (nr == GAP_INDEX)
            continue;
        smpl += mat[nc][nr];
    }
    pair_set->smpl_score = smpl;
}

/* ---------------- score_mat_sum_full ------------------------
 * Tot up the matrix, Gotoh method.
 * A different approach to old code, or even Gotoh's description.
 * The p[] vector is straightforward and follows Gotoh's version.
 * The q[][] matrix is like the text in Gotoh's paper, but there
 * is a trick. At the cost of a bit of memory, we can save an
 * initialisation step. Since our matrices are usually very small,
 * it is worth spending memory, thus, q is a matrix and not the
 * vector we could use. The loop structure below is also simple.
 *
 * Gap penalties:
 * Note that we allow for two different gap_open and gap_widen
 * penalties.
 *
 * It is not really feasible to decouple the matrix summation
 * from the traceback. Gotoh suggests a second N^2 walk
 * through the summed matrix. In this implementation, we store
 * the direction used to reach each cell in direction[][] and
 * this matrix has to be passed to the traceback routine.
 *
 * Finally, we have a trick before we return. The MN matrix is
 * actually (M+2)(N+2), so the pair_set we return has to be
 * corrected at the end.
 *
 * Nifty feature..
 * There is yet another argument. If bias_set is non-NULL, it
 * will be used as a set of pairs which should be forced into the
 * alignment.
 * We do this by going to the summation matrix and whacking in
 * big positive numbers.
 */
struct pair_set *
score_mat_sum_full (struct score_mat **rmat, struct score_mat *smat,
                    float p_open, float p_widen, float q_open, float q_widen,
                    float *col_mult_orig, float *row_mult_orig,
                    const int algn_type, const struct pair_set *bias_set)
{
    size_t n_rows = smat->n_rows;
    size_t n_cols = smat->n_cols;

    float *p = E_MALLOC (sizeof p[0] * n_cols);
    float **q = f_matrix (n_rows, n_cols);
    float **sum_mat = copy_f_matrix (smat->mat, n_rows, n_cols);
    float *col_mult, *row_mult;
    float bias;

    unsigned char **direction = uc_matrix (n_rows, n_cols);
    unsigned char *dp, *dlast;
    struct pair_set *ret_set, pair_set;
    size_t i, j;
    int no_fancy_shit = 0;
    const enum align_type align_type = algn_type;
    const char *less     = "Both gap open and widen should be positive.\n";
    const char *wid      = "Gap widen should be less than open.\n";
    const char *gap_err  = "Problem %s. They are %f %f %f %f\n";
    const char *this_sub = "sum_score_mat";


    row_mult = col_mult = NULL;

    if ((algn_type != N_AND_W) && (algn_type != S_AND_W)) {
        err_printf (this_sub, "alignment type must be $N_AND_W or $S_AND_W. It was %d. open: %f, widen: %f\n", algn_type, p_open, p_widen);
        free (p);
        kill_f_matrix (q);
        kill_f_matrix (sum_mat);
        return NULL;
    }

    if (p_open < 0 || p_widen < 0 || q_open < 0 || q_widen < 0)
        err_printf (this_sub, gap_err, less, p_open, p_widen, q_open, q_widen);
    if ((p_widen > p_open) || (q_widen > q_open))
        err_printf (this_sub, gap_err, wid, p_open, p_widen, q_open, q_widen);

    if (bias_set)
        bias = add_bias (bias_set, sum_mat, smat);
    else
        bias = 0.;

    p_open  = - p_open;
    p_widen = - p_widen;
    q_open  = - q_open;
    q_widen = - q_widen;

    for ( i = 0; i< n_rows; i++)
        for ( j = 0; j < n_cols; j++)
            q[i][j] = -FLT_MAX;
    for (i = 0; i < n_rows; i++)
        q[i][1] = sum_mat[i][0];

    for (i = 0; i < n_cols; i++)
        p[i] = sum_mat[0][i];

    dlast = direction[0] + n_cols;             /* Direction will hold the */
    for (dp = direction[0]; dp < dlast; dp++)  /* route taken to each cell. */
        *dp = TERM;                            /* TERM is a terminator used */
    dlast  = direction[0] + n_rows * n_cols;   /* in the traceback routines */
    for (dp = direction[0]; dp < dlast; dp += n_cols)
        *dp = TERM;

    for (i = 1; i < n_rows; i++)
        direction[i][n_cols - 1] = DIAG;
    for (i = 1; i < n_cols; i++)
        direction[n_rows - 1][i] = DIAG;


    if (row_mult_orig || col_mult_orig) {
        size_t tmp;
        no_fancy_shit = 0;  /* we are going to do fancy shit */
        row_mult = fill_ones (n_rows);
        col_mult = fill_ones (n_cols);
        if ( col_mult_orig) {
            tmp = (n_cols - 2) * sizeof (col_mult[0]);
            memcpy (col_mult + 1, col_mult_orig, tmp);
        } else {
            tmp = (n_rows - 2) * sizeof (row_mult[0]);
            memcpy (row_mult + 1, row_mult_orig, tmp);
        }
    } else {
        no_fancy_shit = 1;
    }

/*     if (first) {
 *         first = 0;
 *         if (no_fancy_shit)
 *             mprintf ("No fancy_shit (site spec gaps)\n");
 *         else
 *             mprintf ("Doing fancy gaps (site spec gaps)\n");
 *     } */


    if ( no_fancy_shit) {
        for (i = 1; i < n_rows; i++) {
            for (j = 1; j < n_cols; j++) {
                float t, po, pw, qo, qw, p_or_q;
                unsigned char d, pway, qway;
                po = sum_mat[i ][j - 1] + p_open;                /* Open or */
                pw = p[j - 1] + p_widen;                         /* widen ? */
                p[j] = po > pw ? (pway = POPEN, po) : (pway = PWIDEN, pw);
                qo = sum_mat[i - 1][j] + q_open;           /* Same question */
                qw = q[i - 1][j] + q_widen;              /* for q direction */
                q[i][j] = qo > qw ? (qway = QOPEN, qo) : (qway = QWIDEN, qw);
                if (p[j] > q[i][j]) {              /* d will hold direction */
                    d = pway; p_or_q = p[j];         /* while p_or_q is the */
                } else {                             /* candidate value for */
                    d = qway; p_or_q = q[i][j];         /* summation matrix */
                }
                t = sum_mat[i-1][j-1] + sum_mat[i][j];        /* Score from */
                if (t > p_or_q) {                               /* diagonal */
                    sum_mat[i][j] = t;
                    direction[i][j] = DIAG;
                } else {
                    sum_mat[i][j] = p_or_q;
                    direction[i][j] = d;
                }
            }
        }
    } else {
        for (i = 1; i < n_rows; i++) {
            const float q_mul = row_mult[i];
            for (j = 1; j < n_cols; j++) {
                float t, po, pw, qo, qw, p_or_q;
                float c_mult = col_mult[j];
                unsigned char d, pway, qway;
                po = sum_mat[i ][j - 1] + p_open * c_mult;
                pw = p[j - 1] + p_widen * c_mult;
                p[j] = po > pw ? (pway = POPEN, po) : (pway = PWIDEN, pw);
                qo = sum_mat[i - 1][j] + q_open * q_mul;
                qw = q[i - 1][j] + q_widen * q_mul;
                q[i][j] = qo > qw ? (qway = QOPEN, qo) : (qway = QWIDEN, qw);
                if (p[j] > q[i][j]) {
                    d = pway; p_or_q = p[j];
                } else {
                    d = qway; p_or_q = q[i][j];
                }
                t = sum_mat[i-1][j-1] + sum_mat[i][j];
                if (t > p_or_q) {
                    sum_mat[i][j] = t;
                    direction[i][j] = DIAG;
                } else {
                    sum_mat[i][j] = p_or_q;
                    direction[i][j] = d;
                }
            }
        }
    }


    free_if_not_null (col_mult);
    free_if_not_null (row_mult);


    free (p);
    kill_f_matrix (q);

    pair_set = trace_mat (direction, sum_mat, n_rows, n_cols, align_type);

    smpl_score (&pair_set, smat);

    if (bias_set)                      /* We introduced a bias score, now */
        pair_set.score      -= bias;   /* we have to correct for damage */

    kill_uc_matrix (direction);

    {
        struct score_mat *ret_mat;

        ret_mat = E_MALLOC (sizeof (*ret_mat));
        ret_mat->mat = sum_mat;
        ret_mat->n_rows = n_rows;
        ret_mat->n_cols = n_cols;

        *rmat = ret_mat;
    }

    {
        size_t m;
        int **pairs = pair_set.indices;
        for (m = 0; m < pair_set.n; m++) {
            if (pairs[m][0] != GAP_INDEX)
                pairs[m][0]--;
            if (pairs[m][1] != GAP_INDEX)
                pairs[m][1]--;
        }
    }

    ret_set = E_MALLOC (sizeof (pair_set));
    *ret_set = pair_set;
    ret_set->m = 2;
    return (ret_set);
}

