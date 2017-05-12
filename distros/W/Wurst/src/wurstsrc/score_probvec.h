/*
 * 14 June 2005
 * rcsid = $Id: score_probvec.h,v 1.1 2007/09/28 16:57:12 mmundry Exp $
 */

#ifndef SCORE_PROBVEC_H
#define SCORE_PROBVEC_H

struct score_mat;
struct prob_vec;
int
score_pvec (struct score_mat *score_mat,
            struct prob_vec *p_v1, struct prob_vec *p_v2);

#endif /* SCORE_PROBVEC_H */
