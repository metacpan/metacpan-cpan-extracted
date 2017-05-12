/*
 * 15 Feb 2005
 * This is the function interface for probability vectors.
 * The structure is defined in prob_vec.h.
 * One may only include this file after <stdlib.h>.
 * rcsid = $Id: prob_vec_i.h,v 1.1 2007/09/28 16:57:12 mmundry Exp $
 */
#ifndef PROB_VEC_I_H
#define PROB_VEC_I_H

struct prob_vec;
struct prob_vec  *
new_pvec (const size_t frag_len, const size_t prot_len,
          const size_t n_pvec, const size_t n_class);
void              prob_vec_unit_vec (struct prob_vec *p_v);
int               prob_vec_expand (struct prob_vec *p_vec);
void              prob_vec_destroy (struct prob_vec *p_vec);
char             *prob_vec_info (struct prob_vec *pvec);
size_t            prob_vec_size(const struct prob_vec *pvec);
size_t            prob_vec_length(const struct prob_vec *pvec);
int               prob_vec_write (struct prob_vec *p_v, const char *fname);
struct prob_vec  *prob_vec_read (const char *fname);
struct prob_vec  *prob_vec_copy (const struct prob_vec *p_vec);
struct prob_vec  *prob_vec_duplicate (const struct prob_vec *p_vec, size_t k);
#endif /* PROB_VEC_I_H */
