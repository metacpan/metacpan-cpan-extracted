/*
 * 1 March 2002
 * $Id: score_mat_i.h,v 1.1 2007/09/28 16:57:05 mmundry Exp $
 */
#ifndef SCORE_MAT_I_H
#define SCORE_MAT_I_H

struct score_mat;
struct seq;
struct pair_set;

void score_mat_info (const struct score_mat *score_mat, float *min, float *max,
                    float *av, float *std_dev);
struct score_mat *score_mat_new (size_t n_rows, size_t n_cols);
void              score_mat_destroy (struct score_mat *s);

struct score_mat *
score_mat_add ( struct score_mat *mat1, struct score_mat *mat2,
                float scale, float shift);

struct score_mat *score_mat_scale (struct score_mat *mat1, const float scale);
struct score_mat *score_mat_shift (struct score_mat *mat1, const float shift);
char *score_mat_string (struct score_mat *smat, struct seq *s1, struct seq *s2);
struct score_mat *score_mat_read (const char *fname);
int score_mat_write (const struct score_mat *smat, const char *fname);
void score_mat_diag_wipe( struct pair_set *p_s,  struct score_mat *smat);
struct score_mat *score_mat_double_matrix (const struct score_mat *smat);

int score_mat_write_gnuplot ( const struct score_mat *smat, const char *fname,
                             const char *protA, const char *protB );

#endif /* SCORE_MAT_I_H */
