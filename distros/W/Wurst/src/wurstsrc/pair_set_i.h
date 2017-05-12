/*
 * 25 September 2001
 * Interface to pair_set operations.
 * This does not show the internals of the structure.
 * rcsid = "$Id: pair_set_i.h,v 1.1 2007/09/28 16:57:06 mmundry Exp $"
 */

#ifndef PAIR_SET_I_H
#define PAIR_SET_I_H

struct pair_set;
struct seq_array;
struct seq;
char  *pair_set_string (struct pair_set *s, struct seq *s1, struct seq *s2);
char  *multal_string (struct pair_set *pair_set);
int    pair_set_extend (struct pair_set *s, const size_t n0, const size_t n1,
                        const int long_or_short);
int
pair_set_coverage (struct pair_set *p_s, size_t s1, size_t s2,
                   char **pcover1, char **pcover2);
int
pair_set_gap (struct pair_set *p_s, float *open_cost, float *widen_cost,
              const float open_scale, const float widen_scale);
int    pair_set_score (struct pair_set *s, float *score, float *scr_smpl);
void   pair_set_destroy (struct pair_set *s);

struct pair_set *pair_set_xchange(struct pair_set *p_s);
int    pair_set_circularpermutated( struct pair_set *p_s , size_t prot1_len , size_t prot2_len );
void   pair_set_get_alignment_indices( struct pair_set *p_s, int sequencenumber, int *start, int *stop  );
#endif
