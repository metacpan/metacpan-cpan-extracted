/*
 * 24 March 2001
 * This contains prototypes which the interpreter must know about.
 * It does *not* describe the sub_mat structure. It must not be
 * dependent on knowing the sub_mat structure.
 * rcsid = $Id: read_mat.h,v 1.1 2007/09/28 16:57:11 mmundry Exp $
 */
#ifndef READ_MAT_H
#define READ_MAT_H

struct sub_mat;
struct sub_mat *sub_mat_read (const char *fname);
void            sub_mat_destroy (struct sub_mat *s);
char           *sub_mat_string (const struct sub_mat * smat);
struct sub_mat *sub_mat_shift (struct sub_mat *s, float bottom);
void            sub_mat_scale (struct sub_mat *s, float bottom, float top);
float           sub_mat_get_by_i (struct sub_mat *s,
                                  const int ndx1, const int ndx2);
float           sub_mat_get_by_c (struct sub_mat *s,
                                  const char ndx1, const char ndx2);
int             sub_mat_set_by_i (struct sub_mat *s,
                                const int ndx1, const int ndx2, const float f);
int             sub_mat_set_by_c (struct sub_mat *s,
                              const char ndx1, const char ndx2, const float f);

#endif  /* READ_MAT_H */
