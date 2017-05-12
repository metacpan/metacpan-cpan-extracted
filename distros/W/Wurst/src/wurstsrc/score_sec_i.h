/*
 * 27 Feb 2002
 * $Id: score_sec_i.h,v 1.1 2007/09/28 16:57:07 mmundry Exp $
 */
#ifndef SCORE_SEC_H
#define SCORE_SEC_H

struct score_mat;
struct sec_s_data;
struct coord;
int
score_sec(struct score_mat *score_mat, struct sec_s_data *s, struct coord *c1);


#endif /* SCORE_SEC_H */
