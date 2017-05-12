/*
 * mid 2005
 * Gundolf Schenk code
 *
 * $Id: classifyStructure.c,v 1.1 2007/09/28 16:57:09 mmundry Exp $ 
 */

#define _XOPEN_SOURCE 500              /* Necessary under solaris for M_PI */
#include <stdio.h>
#include <math.h>

#include "bad_angle.h"
#include "classifyStructure.h"
#include "class_model.h"
#include "coord_i.h"
#include "e_malloc.h"
#include "mprintf.h"
#include "prob_vec.h"
#include "prob_vec_i.h"
#include "read_ac_strct.h"
#include "read_ac_strct_i.h"

/* ---------------- getFragment -------------------------------
 * contructs a descriptor (phi & psi angles) of the fragment of length
 * frag_len starting at residue residue_num of a given structure
 *
 * NOTE: the descriptor will have a dimension/length of 2*frag_len
 *
 * remember to free the fragment after usage!
 *
 * return value:
 * the descriptor - if all angles were defined
 * NULL           - if a bad angle was encountered
 */
float *
getFragment(const size_t residue_num, const size_t frag_len,
            struct coord *structure)
{
    size_t i = 0, j = 0;
    float *frag = E_CALLOC( 2 * frag_len, sizeof(float));

    for (i = residue_num, j = 0; i < frag_len+residue_num; i++, j+=2) {
        frag[j]   = coord_phi(structure, i, 0.0);
        frag[j+1] = coord_psi(structure, i, -M_PI/2);
        if (frag[j] < 0.0) frag[j] = BAD_ANGLE;
        if (frag[j+1] < -M_PI/2) frag[j+1] = BAD_ANGLE;
    }

    return frag;
}

/* ---------------- struct_2_prob_vec  ------------------------
 * The coordinates come in via structure, the classification via
 * cmodel. The convention for sizes is that the probability vector
 * stores the length of each fragment in amino acids. This has to be
 * kept there so the alignment routines know where to put numbers in
 * the score matrix. Privately, this function and computeMembership,
 * keep track of the number of attributes. Typically, this is a bigger
 * number (like 2 * frag_length) since each amino acid will have two
 * angles.
 *
 * NOTE: if bad angles are encountered, the probability should
 * still be calculated based on the angles that are present.
 */
/************************************************************************
replaced by strct_2_prob_vec in read_ac_strct_i.h
struct prob_vec *
struct_2_prob_vec(struct coord *structure, const struct clssfcn *cmodel)
{
    struct prob_vec *pvec;
    float *fragment = NULL;
    size_t i = 0;
    const size_t frag_len = (size_t) cmodel->dim / 2;
    const size_t c_size = coord_size(structure);
    const size_t n_pvec = c_size - frag_len + 1;
    pvec = new_pvec( frag_len, c_size, n_pvec, cmodel->n_class);

    for (i = 0; i < pvec->n_pvec; i++) {
        fragment = getFragment( i, cmodel->dim/2, structure);
        computeMembership( pvec->mship[i], fragment, cmodel );
        free_if_not_null(fragment);
    }
    pvec->norm_type = PVEC_UNIT_VEC;
    return pvec;
}
********************************************************************************/
#ifdef WANT_MAIN

void
usage(char progname[])
{
    mprintf("Usage:\n");
    mprintf("%s <influence_report> <abs_error> <structure1> <structure2>\n",
            progname);
}


int
main(int argc, char *argv[]) {
    struct coord *structure1 = NULL;
    struct coord *structure2 = NULL;
    struct clssfcn *cmodel = NULL;
    struct aa_strct_clssfcn *model = NULL;
    struct prob_vec *pvec1 = NULL;
    struct prob_vec *pvec2 = NULL;

    struct score_mat * scr_mat = NULL;
    struct pair_set * pr_set = NULL;
    struct score_mat **result_mat = NULL;

    float gap_open1 = 1e-7;
    float gap_open2 = gap_open1;
    float gap_widen1 = gap_open1 / 10;
    float gap_widen2 = gap_open2 / 10;



    if (argc != 5) {
	usage(argv[0]);
	return EXIT_FAILURE;
    }

    cmodel = get_clssfcn(argv[1], atof(argv[2]));
    model = E_MALLOC (sizeof (struct ac_strct_clssfcn));
    model->strct = cmodel;
    model->n_att = cmodel->dim/2;
    model->log_pp = NULL;

    structure1 = coord_read(argv[3]);
    mprintf("Protein1: %s\n", coord_name(structure1));

    coord_calc_phi(structure1);
    coord_calc_psi(structure1);

    pvec1 = strct_2_prob_vec(structure1, model);

    structure2 = coord_read(argv[4]);
    mprintf("Protein2: %s\n", coord_name(structure2));

    coord_calc_phi(structure2);
    coord_calc_psi(structure2);

    pvec2 = strct_2_prob_vec(structure2, model);


    scr_mat = score_mat_new(prob_vec_size(pvec1), prob_vec_size(pvec2));
    score_pvec(scr_mat, pvec1, pvec2);
/*  pr_set = score_mat_sum_full (result_mat, scr_mat, gap_open1, gap_widen1, */
/*                                  gap_open2, gap_widen2, NULL, NULL,       */
/*                                  1, NULL);                                */


    /*mprintf("Score matrix:\n%s\n",
            score_mat_string(scr_mat,
                             coord_get_seq(structure1),
                             coord_get_seq(structure2)));*/


    /*mprintf("%s\n", prob_vec_info(pvec1));*/

    return EXIT_SUCCESS;
}


#endif /* WANT_MAIN */
