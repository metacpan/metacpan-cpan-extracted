/*
 * 31 Oct 2001
 * Build a model from an alignment.
 * This is in its own file since it has reasonable ground to know
 * about coordinates, pair_sets and sequences.
 * $Id: model.c,v 1.1 2007/09/28 16:57:13 mmundry Exp $
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "coord.h"
#include "coord_i.h"
#include "e_malloc.h"
#include "matrix.h"
#include "model.h"
#include "mprintf.h"
#include "pair_set.h"
#include "read_seq_i.h"
#include "seq.h"
#include "score_mat.h"

/* ---------------- make_model --------------------------------
 * We have a sequence, a set of coordinates and an alignment
 * (pair_set).  What we will do is build a fresh coord structure
 * then fill it in. This allocates memory, so it is up to the
 * caller (probably interpreter, to clear up.
 */

struct coord *
make_model (const struct pair_set *pair_set,
            const struct seq *seq, struct coord *coord)
{
    int **pair;
    struct coord *dst;
    size_t i, max, idx;
    const char *this_sub = "make_model";

    /* First, count the number of proper, non-gap aligned sites */
    max = 0;
    pair = pair_set->indices;
    for (i = 0; i < pair_set->n; i++)
        if ((pair[i][0] != GAP_INDEX) && (pair[i][1] != GAP_INDEX))
            max++;

    /* Allocate space for coordinates, then the sequence */
    if (max == 0) {
        err_printf (this_sub, "Returning empty model\n");
        return NULL;
    }

    dst = coord_template (coord, max);/* Allocates the actual coord struct */
    dst->seq = seq_copy (seq);        /* Not only copies, but allocates space*/

    i = 0;
    for ( idx = 0; idx < pair_set->n; idx++) {
        if ((pair[idx][0] != GAP_INDEX) && (pair[idx][1] != GAP_INDEX)) {
            size_t ndx_a = pair[idx][0];  /* sequence index */
            size_t ndx = pair[idx][1];    /* structure index */
            dst->rp_ca[i] = coord->rp_ca[ndx];
            dst->rp_cb[i] = coord->rp_cb[ndx];
            dst->rp_n[i]  = coord->rp_n[ndx];
            dst->rp_c[i]  = coord->rp_c[ndx];
            dst->rp_o[i]  = coord->rp_o[ndx];

            dst->icode[i] = ' ';
            if (coord->psi)
                dst->psi[i] = coord->psi[ndx];
            if (coord->sec_typ)
                dst->sec_typ[i] = coord->sec_typ[ndx];

            dst->orig[i] = ndx_a + 1;  /* Model gets number from sequence */
            dst->seq->seq[i] = seq->seq[ndx_a];
            i++;
        }
    }
    seq_trim (dst->seq, i);
    if (max != i) {
        err_printf (this_sub, "Suspicious number %s %d\n", __FILE__, __LINE__);
        coord_trim (dst, i);
    }
    return dst;
}

/*-------------------- model_pdb_num --------------------
 * Return the sequence number that res. coordinate x refers to.
 */
int
model_pdb_num (const struct coord *m, const size_t mnum)
{
    if ((m==NULL) || (mnum >= m->size))
        return (-99999); /* take no chances */
    return (m->orig[mnum]);
}

/* --------------------model_res_num ---------------------
 * Given a sequence residue number, return the residue
 * index of that entry in the coord object.
 * -1 indicates that the number doesn't exist
 */
int
model_res_num ( const struct coord *m, const int mnum)
{
    short *rn,*re;
    int rnum;
    rn = m->orig;
    re = rn + m->size;
    rnum = 0;
    while (rn<re) {
        if (*rn == mnum)
            return rnum;
        rnum++;
        rn++;
    }
    return(-1);
}

