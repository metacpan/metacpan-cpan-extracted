/*
 * Read up a classification based on both structure and sequence.
 * $Id: read_ac_strct.c,v 1.3 2008/04/11 11:33:30 torda Exp $
 */

#define _XOPEN_SOURCE 500
#include <errno.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <regex.h>
#include <stdlib.h>
#include <string.h>

#include "amino_a.h"
#include "classifyStructure.h"
#include "class_model.h"
#include "coord.h"
#include "coord_i.h"
#include "e_malloc.h"
#include "matrix.h"
#include "mprintf.h"
#include "prob_vec.h"
#include "prob_vec_i.h"
#include "read_ac.h"
#include "read_ac_i.h"
#include "read_ac_strct.h"
#include "read_ac_strct_i.h"
#include "read_seq_i.h"
#include "seq.h"
#include "seq_i.h"
#include "seqprof.h"
#include "yesno.h"

/* 24 MAR 2006 TS */
/* ---------------- aa_strct_size -----------------------------
 * Return the fragment length size associated with a
 * classification. This is *not* the number of classes. It will
 * typically be a number between 4 and 9.
 */
size_t
aa_strct_size (const struct aa_strct_clssfcn *clssfcn)
{
    return clssfcn->n_att;
}

/* ---------------- aa_strct_nclass ---------------------------
 * Return the number of classes in a classification.
 */
size_t
aa_strct_nclass (const struct aa_strct_clssfcn *clssfcn)
{
    return clssfcn->strct->n_class;
}

/* ---------------- aa_strct_dump -----------------------------
 * Print some information about the classification.
 */
void
aa_strct_dump (const struct aa_strct_clssfcn *clssfcn)
{
    mprintf ("The classification has %ld classes and fragment length of %ld\n",
             (long int) clssfcn->strct->n_class, (long int) clssfcn->n_att);
}

/* ---------------- aa_strct_clssfcn_destroy ------------------
 * This clean up function will be called by the perl interface.
 */
void
aa_strct_clssfcn_destroy (struct aa_strct_clssfcn * clssfcn)
{
    if (!clssfcn)
        return;
    if (clssfcn->strct)
        clssfcn_destroy (clssfcn->strct);
        if (clssfcn->log_pp)
                kill_3d_array ((void *)clssfcn->log_pp);
    free (clssfcn);
}

/* ---------------- aa_strct_clssfcn_read ---------------------
 * Given a pointer to a filename, read in the data.
 * This is an interface function, visible to the outside world.
 */
struct aa_strct_clssfcn *
aa_strct_clssfcn_read (const char *fname, const float abs_error)
{
    struct aa_clssfcn * aa_class;
    struct aa_strct_clssfcn * clssfcn;

    clssfcn = E_MALLOC (sizeof (struct aa_strct_clssfcn));
    clssfcn->log_pp = NULL;
    clssfcn->strct = NULL;
    /* Read the structure information */

    if ((clssfcn->strct = get_clssfcn (fname, abs_error)) == NULL) {
        return NULL;
    } /* TODO: allow also for sequence only classifications */

    /* Read the residue information */
    clssfcn->n_att = clssfcn->strct->dim/2;
    aa_class = ac_read (fname);
    if (aa_class) {
        clssfcn->n_att = aa_class->n_att;
        clssfcn->log_pp = (float ***)d3_array (aa_class->n_class,
                                               aa_class->n_att, MIN_AA,
                                               sizeof (float));
        memcpy (clssfcn->log_pp[0][0], aa_class->log_pp[0][0],
                aa_class->n_class * clssfcn->n_att *
                MIN_AA * sizeof (float));
        aa_clssfcn_destroy (aa_class);
    }
    return clssfcn;
}

/* ---------------- seq_strct_2_prob_vec  -----------------------
 * This calculates probabilities using combinations of
 * sequence and structure, sequence profile and structure,
 * sequence only, sequence profile only, and structure only.
 */
static struct prob_vec *
seq_strct_2_prob_vec (struct coord *structure, const struct seq *seq,
                      const struct seqprof *sp, const size_t size,
                      const struct aa_strct_clssfcn *cmodel,
                      const enum yes_no norm)
{
    size_t i, j, compnd_len;
    struct prob_vec *pvec;
    float **aa_prob;
    struct aa_clssfcn *aa_class;
    const size_t n_pvec = size - cmodel->n_att + 1;

    if ((pvec = new_pvec (cmodel->n_att, size,n_pvec,
                          cmodel->strct->n_class))!= NULL) {
        for (i = 0; i < n_pvec; i++)                   /* Initialize mship */
            for (j = 0; j < cmodel->strct->n_class; j++)
                pvec->mship[i][j] = cmodel->strct->class_weight[j];

        if (structure) {
            float *fragment = NULL;                /* Structure membership */
            for (i = 0; i < n_pvec; i++) {         /* for every fragment...*/
                fragment = getFragment (i, cmodel->n_att, structure);
                if (computeMembershipStrct(pvec->mship[i], fragment,
                                           cmodel->strct) == NULL) {
                    prob_vec_destroy (pvec);
                    return NULL;
                }
                free_if_not_null (fragment);
                fragment = NULL;
            }
        }

        if (sp || seq) {                /* Sequence or profile membership */
            aa_prob = f_matrix (n_pvec,  cmodel->strct->n_class);
            aa_class = E_MALLOC (sizeof (struct aa_clssfcn));
            aa_class->n_class = cmodel->strct->n_class;
            aa_class->n_att = cmodel->n_att;
            aa_class->log_pp = cmodel->log_pp;
            aa_class->class_wt = cmodel->strct->class_weight;
            if (seq){
                struct seq *s = seq_copy (seq);
                if (computeMembershipAA (aa_prob, s, aa_class)
                    == EXIT_FAILURE) {
                    prob_vec_destroy (pvec);
                    return NULL;
                }
                seq_destroy (s);
            } else if (sp) {
                if (computeMembershipAAProf (aa_prob, sp, aa_class)
                    == EXIT_FAILURE) {
                    prob_vec_destroy (pvec);
                    return NULL;
                }
            }
            free (aa_class);
            for (i = 0; i < n_pvec; i++)
                for (j = 0; j < cmodel->strct->n_class; j++)
                    pvec->mship[i][j] *= aa_prob[i][j];
            kill_f_matrix (aa_prob);
        }
        if (norm == YES) {
            for (i = 0; i < n_pvec; i++){
                double sum = 0.0;
                for (j = 0; j < cmodel->strct->n_class; j++)
                    sum += pvec->mship[i][j];
                for (j = 0; j < cmodel->strct->n_class; j++)
                    pvec->mship[i][j] /= sum;
            }
            pvec->norm_type = PVEC_TRUE_PROB;
        }
    }

    if ( structure )
        compnd_len = structure->compnd_len;
    else
        compnd_len = 0;

    if(compnd_len > 0){           /* finally read compound*/
        pvec->compnd = E_MALLOC(compnd_len*sizeof(char));
        memmove(pvec->compnd, structure->compnd, compnd_len);
    }
    pvec->compnd_len = compnd_len;
    return pvec;

}

/* ---------------- strct_2_prob_vec  -------------------------
 * This calculates probabilities, but using only structure terms.
 */
struct prob_vec *
strct_2_prob_vec (struct coord *structure,
                  const struct aa_strct_clssfcn *cmodel, const int norm)
{
    const char *this_sub = "strct_2_prob_vec";

    if (!structure){
        err_printf (this_sub, "No Structure Input!\n");
        return NULL;
    }
    if (!cmodel || !cmodel->strct) {
        err_printf (this_sub, "No Classification Input!\n");
        return NULL;
    }
    return seq_strct_2_prob_vec (structure, NULL, NULL, structure->size,
                                 cmodel, norm);
}


/* ---------------- aa_strct_2_prob_vec  ----------------------
 * This calculates probabilities, using both sequence and structure
 * terms.
 */
struct prob_vec *
aa_strct_2_prob_vec (struct coord *structure,
                     const struct aa_strct_clssfcn *cmodel, const int norm)
{
    const char *this_sub = "aa_strct_2_prob_vec";
    struct prob_vec *pvec;
    struct seq *seqtmp;
    static int debug_n = 1;
    if (debug_n) {
        debug_n = 0;
        err_printf (this_sub, "%s called in new version\n", this_sub);
    }
    if (!structure) {
        err_printf (this_sub, "No Structure Input\n");
        return NULL;
    }
    if (!cmodel || !cmodel->strct || !cmodel->log_pp) {
        err_printf (this_sub, "No Classification Input\n");
        return NULL;
    }
    seqtmp = coord_get_seq (structure);
    pvec= seq_strct_2_prob_vec (structure, seqtmp, 0,
                                 structure->size, cmodel, norm);
    seq_destroy (seqtmp);
    return pvec;
}

/* ---------------- prof_aa_strct_2_prob_vec  -------------------------
 * This calculates probabilities, using both sequence profile and
 * structure terms.
 */
struct prob_vec *
prof_aa_strct_2_prob_vec (struct coord *structure,
                          const struct seqprof *sp,
                          const struct aa_strct_clssfcn *cmodel,
                          const int norm)
{
    const char *this_sub = "prof_aa_strct_2_prob_vec";
    if (!structure) {
        err_printf (this_sub, "No Structure Input\n");
        return NULL;
    }
    if (!sp) {
        err_printf (this_sub, "No Sequence Profile Input\n");
        return NULL;
    }
    if (!cmodel || !cmodel->log_pp) {
        err_printf (this_sub, "No Classification Input\n");
        return NULL;
    }
    return seq_strct_2_prob_vec (structure, 0, sp, sp->nres, cmodel, norm);
}

/* ---------------- aa_2_prob_vec  -----------------------------
 * This calculates probabilities, but using only sequence terms.
 * Will return NULL on failure.
 */
struct prob_vec *
aa_2_prob_vec (const struct seq *seq, const struct aa_strct_clssfcn *cmodel,
                const int norm)
{
    const char *this_sub = "aa_2_prob_vec";
    if (!seq) {
        err_printf (this_sub, "No Sequence Input\n");
        return NULL;
    }
    if (!cmodel || !cmodel->log_pp) {
        err_printf (this_sub, "No Classification Input\n");
        return NULL;
    }
    return seq_strct_2_prob_vec (0, seq, 0, seq->length, cmodel, norm);
}

/* ---------------- prof_aa_2_prob_vec  ------------------------
 * This is like aa_2_prob_vec, but it takes a sequence profile
 * and calculates probabilities based only on the sequence terms.
 * Return NULL on failure.
 */
struct prob_vec *
prof_aa_2_prob_vec (const struct seqprof *sp,
                    const struct aa_strct_clssfcn *cmodel, const int norm)
{
    const char *this_sub = "prof_aa_2_prob_vec";

    if (!sp) {
        err_printf (this_sub, "No Sequence Input\n");
        return NULL;
    }
    if (!cmodel) {
        err_printf (this_sub, "No Classification Input\n");
        return NULL;
    }
    return seq_strct_2_prob_vec (0, 0, sp, sp->nres, cmodel, norm);
}

#ifdef want_strct_2_duplicated_prob_vec
/* ---------------- seq_strct_2_duplicated_prob_vec  -----------------------
 * Duplicate the pvec while structure estimation and
 * also duplicate the sequence,
 * each n-times.
 * return:
 *             struct prob_vec *pvec
 * Notice: not used, but who knows if it will became useful one day !
 * (Martin May, 2007)
 */
struct prob_vec *
strct_2_duplicated_prob_vec (struct coord *structure, const struct seq *seq,
                      const struct seqprof *sp, const size_t size,
                      const struct aa_strct_clssfcn *cmodel, const size_t n_duplications)
{
    size_t i, j;
    float *fragment;
    struct prob_vec *pvec;
    float **aa_prob;
    struct aa_clssfcn *aa_class;
    const size_t n_pvec = size - cmodel->n_att + 1;

    if ((pvec = new_pvec (cmodel->n_att, n_duplications * size , n_duplications * n_pvec,
                          cmodel->strct->n_class))!= NULL) {
        for (i = 0; i < (n_duplications * n_pvec); i++)          /* Initialize mship */
            for (j = 0; j < cmodel->strct->n_class; j++)
                pvec->mship[i][j] = cmodel->strct->class_weight[j];

        if (structure) {                           /* Structure membership */
            for (i = 0; i < n_pvec; i++){           /* for every fragment...*/
                /* twice for every fragment on position  i as on i + size */
                fragment = getFragment (i , cmodel->n_att, structure);
                for (j = 0; j < n_duplications; j++){
                    if (computeMembershipStrct(pvec->mship[ i + j * n_pvec], fragment,
                                               cmodel->strct) == NULL) {
                        prob_vec_destroy (pvec);
                        return NULL;
                    }
                }
                free_if_not_null (fragment);
            }
        }

        if (sp || seq) {                /* Sequence or profile membership */
            aa_prob = f_matrix (n_duplications * n_pvec,  cmodel->strct->n_class);
            aa_class = E_MALLOC (sizeof (struct aa_clssfcn));
            aa_class->n_class = cmodel->strct->n_class;
            aa_class->n_att = cmodel->n_att;
            aa_class->log_pp = cmodel->log_pp;
            aa_class->class_wt = cmodel->strct->class_weight;
            if (seq){
                struct seq *s = seq_duplicate ( seq , n_duplications );
                if (computeMembershipAA (aa_prob, s, aa_class)
                    == EXIT_FAILURE) {
                    prob_vec_destroy (pvec);
                    return NULL;
                }
                seq_destroy (s);
            } else if (sp) {
                if (computeMembershipAAProf (aa_prob, sp, aa_class)
                    == EXIT_FAILURE) {
                    prob_vec_destroy (pvec);
                    return NULL;
                }
            }
            free (aa_class);
            for (i = 0; i < n_duplications * n_pvec; i++)
                for (j = 0; j < cmodel->strct->n_class; j++)
                    pvec->mship[i][j] *= aa_prob[i][j];
            kill_f_matrix (aa_prob);
        }

        for (i = 0; i < (n_duplications * n_pvec); i++){
            double sum = 0.0;
            for (j = 0; j < cmodel->strct->n_class; j++)
                sum += pvec->mship[i][j];
            for (j = 0; j < cmodel->strct->n_class; j++)
                pvec->mship[i][j] /= sum;
        }
        pvec->norm_type = PVEC_TRUE_PROB;
    }
    return pvec;
}
#endif /* want_strct_2_duplicated_prob_vec */
