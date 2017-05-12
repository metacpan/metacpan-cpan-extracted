/* 23-1-2004
 * scor_set functions
 * $Id: scor_set.c,v 1.1 2007/09/28 16:57:06 mmundry Exp $
*/

#include <stdio.h>
#include <stdlib.h>

#include "score_mat.h"
#include "pair_set.h"

#include "scor_set.h"
#include "scor_set_i.h"
#include "e_malloc.h"
#include "mprintf.h"

/* ---------------- scor_set_fromvec --------------------------
 */
struct scor_set *
scor_set_fromvec( size_t n, double *v) {
    struct scor_set *p = NULL;
    if (n && v) {
        float *i;
        double *j,*k;
        p = E_MALLOC(sizeof(*p));
        p->n = n;
        p->scores = E_MALLOC(sizeof(p->scores[0])*n);
        for (k = v+n, j=v, i=p->scores; 
             j<k; i++, j++)
            *i = (float) *j;
    }
    return(p);
}

/* ---------------- scor_set_simpl ----------------------------
 * Given a score matrix ( of any sort ), return a vector of
 * floats for the pair score at each point in the matrix.
 */
struct scor_set *
scor_set_simpl (struct pair_set *pair_set, const struct score_mat *smat)
{
    struct scor_set *locs;
    int **p;
    float **mat = smat->mat;
    float *smpl;
    size_t msize, idx;

    p = pair_set->indices;
    smpl = E_MALLOC(sizeof(*smpl)*pair_set->n);
    msize = 0;
    for (idx = 0; idx < pair_set->n; idx++) {
        int nc, nr;
        nc = p[idx][0];
        nr = p[idx][1];
        if (nc == GAP_INDEX)
            continue;
        if (nr == GAP_INDEX)
            continue;
        smpl[msize++] = mat[nc][nr];
    }
    locs = E_MALLOC(sizeof(*locs));
    locs->scores = E_REALLOC(smpl, sizeof(*smpl)*msize);
    locs->n = msize;
    return(locs);
}

/* ---------------- scor_set_scale ----------------------------
 * Scale a local alignment score vector. This is probably only
 * useful for viewing purposes.
 */
int
scor_set_scale(struct scor_set *ss, const float scale) {
    const char *this_sub = "scor_set_scale";
    if (!ss || !scale) {
        err_printf(this_sub, "Arguments are not valid\n");
        return EXIT_FAILURE;
    } else {
        float *f, *fe;
        fe = ss->scores + ss->n;
        for (f=ss->scores; f < fe; f++)
            *f /= scale;
    }
    return EXIT_SUCCESS;
}

/* ---------------- scor_set_scale ----------------------------
 */
void 
scor_set_destroy( struct scor_set *x) {
    if (x) {
        if ((x->n != 0) && (x->scores != NULL))
            free(x->scores);
        free(x);
    }
}

