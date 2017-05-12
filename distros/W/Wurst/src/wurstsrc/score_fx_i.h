/*
 * 10 Jan 2002
 * Public interface to the score_fx score function.
 * $Id: score_fx_i.h,v 1.1 2007/09/28 16:57:10 mmundry Exp $
 */

#ifndef SCORE_FX_I_H
#define SCORE_FX_I_H

struct score_mat;
struct seq;
struct coord;
struct FXParam;
struct seqprof;
int
score_fx (struct score_mat *score_mat, struct seq *s,
             struct coord *c1, struct FXParam *param);
int
score_fx_prof (struct score_mat *score_mat, struct seqprof *sp,
               struct coord *c1, struct FXParam *fx);

#endif /* SCORE_FX_I_H */
