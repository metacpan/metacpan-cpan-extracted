/*
 * 12 Sep 2001
 * Define a score matrix. Only people who need to manipulate
 * elements should look here.
 * rcsid = $Id: score_mat.h,v 1.1 2007/09/28 16:57:02 mmundry Exp $
 */

#ifndef SCORE_MAT_H
#define SCORE_MAT_H

struct score_mat {
    float **mat;
    size_t n_rows, n_cols;
};

#endif /* SCORE_MAT_H */
