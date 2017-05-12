/*
 * Gundolf code. Mid 2005
 * rcsid = $Id: classifyStructure.h,v 1.1 2007/09/28 16:57:05 mmundry Exp $
 */

#ifndef CLASSIFYSTRUCTURE_H
#define CLASSIFYSTRUCTURE_H

struct coord;
struct clssfcn;

float *
getFragment(const size_t residue_num, const size_t frag_len,
            struct coord *structure);

/* struct prob_vec *
struct_2_prob_vec(struct coord *structure, const struct clssfcn *cmodel);*/

#endif /* CLASSIFYSTRUCTURE_H */
