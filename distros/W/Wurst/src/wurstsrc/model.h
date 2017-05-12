/*
 * 31 October 2001
 * $rcsid = $Id: model.h,v 1.1 2007/09/28 16:57:12 mmundry Exp $
 */
#ifndef MODEL_H
#define MODEL_H

struct coord;
struct pair_set;
struct seq;
struct score_mat;
struct coord *
make_model (const struct pair_set *pair_set,
            const struct seq *seq, struct coord *coord);

int model_pdb_num (const struct coord *m, const size_t mnum);
int model_res_num (const struct coord *m, const int mnum);
#endif /* MODEL_H */
