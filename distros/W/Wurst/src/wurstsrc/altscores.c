/*
 * 29 March 2005
 * Gundolf Schenk
 * $Id: altscores.c,v 1.1 2007/09/28 16:57:11 mmundry Exp $
 */

#define _XOPEN_SOURCE 500
#include <stdlib.h>

#include "altscores.h"
#include "e_malloc.h"
#include "pair_set.h"
#include "score_mat.h"



/* ---------------- pertubate_random_row_index_vec ------------------------
 * pertubates a random vector with numbers from 1 to (n_rows-1)
 * and indices from 1 to (n_rows-2)
 */
static size_t *
perturbate_vec (size_t * vec, size_t n)
{
    size_t i;
    size_t *p;
    size_t *last = vec + n;
    size_t *ndx = E_CALLOC ((n), sizeof (ndx[0]));
    size_t *ndx_beg = ndx;

    for (i = 0 ; i < n; i++)
        ndx[i] = lrand48() % n;
    
    for (p = vec; p < last; p++, ndx++) {
        size_t *dst = vec + *ndx;
        size_t tmp = *dst;
        *dst = *p;
        *p = tmp;
    }
    
    free (ndx_beg);
    
    return vec;
}

/* ---------------- create_random_row_index_vec ---------------------------
 * creates a random vector 
 */
static size_t *
create_random_row_index_vec (size_t ** random_row_index_vec,
                             size_t * vec_length,
                             const struct pair_set * pair_set)
{
    size_t i, k;
    *random_row_index_vec = E_CALLOC ((pair_set->n), sizeof (size_t));
    
    for (i = 0, k = 0; i < pair_set->n; i++) {
        if (pair_set->indices[i][0] !=GAP_INDEX 
            && pair_set->indices[i][1] !=GAP_INDEX) {
            (*random_row_index_vec)[k]=pair_set->indices[i][0];
            k++;
        }
    }
    *vec_length=k;

    *random_row_index_vec =
        perturbate_vec (*random_row_index_vec, *vec_length);
    
    return *random_row_index_vec;
}

/* ---------------- find_alt_path_score -----------------------------
 * Computes a suboptimal score given by the path ordered by
 * random_row_index_vec from left to right in score_mat of 
 * size n_rows x n_cols ignoring borders.
 */
float
find_alt_path_score (const struct score_mat * score_mat,
                     const size_t * random_row_index_vec,
                     const size_t vec_length,
                     const struct pair_set * pair_set)
{
    float score = 0;
    size_t j, k;
    
    for (j = 0, k = 0; j < pair_set->n && k < vec_length; j++) {
        if (pair_set->indices[j][0] != GAP_INDEX 
            && pair_set->indices[j][1] != GAP_INDEX) {
            score += score_mat->mat
                [random_row_index_vec[k]][pair_set->indices[j][1]];
            k++;
        }
    }
    
    return score;
}

/* ---------------- find_alt_path_score_simple ---------------------------
 * Computes a suboptimal score given by a random path 
 * from left to right in score_mat 
 * ignoring borders.
 *
 * This is with Gaps!
 */
float
find_alt_path_score_simple (const struct score_mat * score_mat,
                            const struct pair_set * pair_set)
{
    size_t * random_row_index_vec = NULL;
    size_t vec_length=0;
    float score;

    create_random_row_index_vec (&random_row_index_vec, &vec_length, pair_set);    
    score = find_alt_path_score (score_mat, random_row_index_vec, vec_length,
                                 pair_set);
    
    free(random_row_index_vec);
    return score;
}



