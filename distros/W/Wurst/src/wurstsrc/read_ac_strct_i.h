/*
 * $Id: read_ac_strct_i.h,v 1.1 2007/09/28 16:57:03 mmundry Exp $
 */

#ifndef READ_AC_STRCT_I_H
#define READ_AC_STRCT_I_H

struct aa_strct_clssfcn;
struct prob_vec;
struct seqprof;
struct seq;

void
aa_strct_clssfcn_destroy (struct aa_strct_clssfcn * clssfcn);

void
aa_strct_dump (const struct aa_strct_clssfcn *clssfcn);

size_t
aa_strct_size (const struct aa_strct_clssfcn *clssfcn);

size_t
aa_strct_nclass ( const struct aa_strct_clssfcn *clssfcn);

struct aa_strct_clssfcn *
aa_strct_clssfcn_read (const char *fname, const float abs_error);

struct prob_vec *
strct_2_prob_vec (struct coord *structure,
                  const struct aa_strct_clssfcn *cmodel, const int norm);
struct prob_vec *
aa_strct_2_prob_vec (struct coord *structure, 
                     const struct aa_strct_clssfcn *cmodel, const int norm);

struct prob_vec *
prof_aa_strct_2_prob_vec (struct coord *structure,
                          const struct seqprof *sp,
                          const struct aa_strct_clssfcn *cmodel, const int norm);
struct prob_vec *
aa_2_prob_vec (const struct seq *seq, const struct aa_strct_clssfcn *cmodel,
               const int norm);

struct prob_vec *
prof_aa_2_prob_vec (const struct seqprof *sp,
                    const struct aa_strct_clssfcn *cmodel, const int norm);

struct prob_vec *
strct_2_duplicated_prob_vec (struct coord *structure, const struct seq *seq,
                      const struct seqprof *sp, const size_t size,
                      const struct aa_strct_clssfcn *cmodel, const size_t n_duplications);
#endif
