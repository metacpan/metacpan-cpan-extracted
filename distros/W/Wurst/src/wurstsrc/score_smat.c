/*
 * 12 September 2001
 *
 * Score sequences according to a substitution matrix.
 * The functions here work on 
 *  * sequence sequence scores
 *  * sequence to profile scores
 *  * profile to profile scores
 *
 * $Id: score_smat.c,v 1.1 2007/09/28 16:57:10 mmundry Exp $
 */

#include <stdio.h>
#include <stdlib.h>

#include "amino_a.h"
#include "mprintf.h"
#include "read_seq_i.h"
#include "score_mat.h"
#include "score_smat.h"
#include "seq.h"
#include "seqprof.h"
#include "sub_mat.h"

/* ---------------- inner_score_2_seq -------------------------
 * We are given two sequences. Score them using the score
 * matrix from *smat.
 * We do not allocate any memory. It is up to the caller to
 * give us a matrix with enough space.
 * Note the convention that the score matrix is (m+2)(n+2) for
 * sequences of m and n.
 */
static int
inner_score_2_seq (float **scores, struct seq *s1,
                   struct seq *s2, const struct sub_mat *smat)
{
    size_t i, j;
    size_t n_rows = s1->length + 2;
    size_t n_cols = s2->length + 2;

    seq_std2thomas (s1);
    seq_std2thomas (s2);

    /* matrix is n_rows (s1), n_cols (s2) */
    for (i = 0; i < n_cols ; i++)
        scores[0][i] = 0;                   /* First row */
    for (i = 0; i < n_cols ; i++)
        scores[n_rows - 1][i] = 0;          /* Last row */
    for (i = 0; i < n_rows ; i++)
        scores [i][0] = 0;                  /* First column */
    for (i = 0; i < n_rows ; i++)
        scores [i][n_cols - 1 ] = 0;        /* Last column */

    for (i = 0; i < n_rows - 2; i++) {
        for (j = 0; j < n_cols - 2 ; j++) {
            int sc = s1->seq[i];
            int tc = s2->seq[j];
            scores [i+1][j+1] = smat->data[sc][tc];
        }
    }

    return EXIT_SUCCESS;
}


/* ---------------- score_smat  -------------------------------
 * Score two sequences using a substitution matrix.
 */
int
score_smat (struct score_mat *score_mat, struct seq *s1,
             struct seq *s2, const struct sub_mat *smat)
{
    const char *this_sub = "score_smat";
    extern const char *mismatch;

    if (( score_mat->n_rows != s1->length + 2) ||
        ( score_mat->n_cols != s2->length + 2)) {
        err_printf (this_sub, mismatch,
                    score_mat->n_rows - 2, score_mat->n_cols - 2,
                    s1->length, s2->length);
        goto bail_out;
    }
    if (inner_score_2_seq (score_mat->mat, s1, s2, smat) == EXIT_FAILURE)
        goto bail_out;

    return (EXIT_SUCCESS);
 bail_out:
    err_printf (this_sub, "Serious scoring error\n");
    return (EXIT_FAILURE);
}

/* ---------------- inner_score_prof_seq ----------------------
 * Given a profile and a sequence, score them according to a
 * substitution matrix.
 * We do not allocate any memory. It is up to the caller to
 * give us a matrix with enough space.
 * Note the convention that the score matrix is (m+2)(n+2) for
 * sequences of m and n.
 * Optimisation note: The inner loop below splits the multiplication
 * and summation into separate loops and uses a temporary array.
 * Reading the output from the intel compiler, it seems this simplifies
 * the loop structure and lets it optimise a bit more. Presumably, the
 * simpler loop structure is good for any compiler.
 */
static void
inner_score_prof_seq (float **scores, struct seqprof *sp,
                   struct seq *seq, const struct sub_mat *smat)
{
    size_t i, j;
    const size_t n_rows = sp->nres + 2;
    const size_t n_cols = seq->length + 2;

    seq_std2thomas (seq);

    /* matrix is n_rows (s1), n_cols (s2) */
    for (i = 0; i < n_cols ; i++)
        scores[0][i] = 0;                   /* First row */
    for (i = 0; i < n_cols ; i++)
        scores[n_rows - 1][i] = 0;          /* Last row */
    for (i = 0; i < n_rows ; i++)
        scores [i][0] = 0;                  /* First column */
    for (i = 0; i < n_rows ; i++)
        scores [i][n_cols - 1 ] = 0;        /* Last column */

    for (i = 0; i < n_rows - 2; i++) {                 /* profile */
        const size_t i_ndx = i + 1;
        for ( j = 0; j < n_cols - 2; j++) {            /* sequence */
            float tmpscore = 0;
            const int sc = seq->seq[j];
            float *tmp1 = sp->freq_mat[i];
            float tmparr [blst_afbet_size];
            size_t k, m;
            for ( k = 0; k < blst_afbet_size; k++)
                tmparr[k]= tmp1[k] * smat->data[sc][k];
            for ( m = 0; m < blst_afbet_size; m++)
                tmpscore += tmparr[m];
            scores [i_ndx][j+1] = tmpscore;
        }
    }
}


/* ---------------- inner_score_prof_prof ----------------------
 * Score a profile/profile pair.
 */
static void
inner_score_prof_prof (float **scores, const struct seqprof *sp1,
                   const struct seqprof *sp2, const struct sub_mat *smat)
{
    size_t i, j, k;
    const size_t n_rows = sp1->nres + 2;
    const size_t n_cols = sp2->nres + 2;

    /* matrix is n_rows (s1), n_cols (s2) */
    for (i = 0; i < n_cols ; i++)
        scores[0][i] = 0;                   /* First row */
    for (i = 0; i < n_cols ; i++)
        scores[n_rows - 1][i] = 0;          /* Last row */
    for (i = 0; i < n_rows ; i++)
        scores [i][0] = 0;                  /* First column */
    for (i = 0; i < n_rows ; i++)
        scores [i][n_cols - 1 ] = 0;        /* Last column */

    for (i = 0; i < n_rows - 2; i++) {                 /* profile */
        const size_t i_ndx = i + 1;
        for ( j = 0; j < n_cols - 2; j++) {            /* other profile */
            float tmpscore = 0;
            for ( k = 0; k < blst_afbet_size; k++) {
                size_t m, n;
                const float f1 = sp1->freq_mat[i][k];
                float *ftmp2 = sp2->freq_mat[j];
                float tarray[blst_afbet_size];
                for ( m = 0; m < blst_afbet_size; m++)
                    tarray [m] = f1 * ftmp2[m] * smat->data[k][m];
                for ( n = 0; n < blst_afbet_size; n++)
                    tmpscore += tarray[n];
            }
            scores [i_ndx][j+1] = tmpscore;
        }
    }
}


/* ---------------- score_sprof -------------------------------
 * Score a sequence and a sequence profile given a
 * substitutqion matrix.
 */
int
score_sprof (struct score_mat *score_mat, struct seqprof *sp,
             struct seq *seq, const struct sub_mat *smat)
{
    const char *this_sub = "score_sprof";
    extern const char *mismatch;

    if (( score_mat->n_rows != sp->nres + 2) ||
        ( score_mat->n_cols != seq->length + 2)) {
        err_printf (this_sub, mismatch,
                    score_mat->n_rows - 2, score_mat->n_cols - 2,
                    sp->nres, seq->length);
        return (EXIT_FAILURE);
    }
    inner_score_prof_seq (score_mat->mat, sp, seq, smat);
    return EXIT_SUCCESS;
}

/* ---------------- score_prof_prof ---------------------------
 * Score an profile/profile pair given a substitution matrix.
 */
int
score_prof_prof ( struct score_mat *score_mat, struct seqprof *sp1,
             struct seqprof *sp2, const struct sub_mat *smat)
{
    const char *this_sub = "score_prof_prof";
    extern const char *mismatch;

    if (( score_mat->n_rows != sp1->nres + 2) ||
        ( score_mat->n_cols != sp2->nres + 2)) {
        err_printf (this_sub, mismatch,
                    score_mat->n_rows - 2, score_mat->n_cols - 2,
                    sp1->nres, sp2->nres);
        return (EXIT_FAILURE);
    }
    inner_score_prof_prof (score_mat->mat, sp1, sp2, smat);
    return EXIT_SUCCESS;
}
