/*
 * 13 June 2005
 * Interface for reading autoclass sequence classification.
 * rcsid = $Id: read_ac_i.h,v 1.1 2007/09/28 16:57:08 mmundry Exp $
 */
#ifndef READ_AC_I_H
#define READ_AC_I_H

struct aa_clssfcn;
struct prob_vec;
struct seq;
struct seqprof;

struct aa_clssfcn * 
ac_read (const char *fname);

void                
aa_clssfcn_destroy (struct aa_clssfcn *aa_clssfcn);

size_t              
ac_size (const struct aa_clssfcn *aa_clssfcn);

size_t              
ac_nclass (const struct aa_clssfcn *aa_clssfcn);

void                
ac_dump (const struct aa_clssfcn *aa_clssfcn);

int
computeMembershipAAProf (float **mship, const struct seqprof *sp,
                         const struct aa_clssfcn *aa_clssfcn); 
int
computeMembershipAA (float **mship, struct seq *seq,
                     const struct aa_clssfcn *aa_clssfcn); 
struct prob_vec *   
seq_2_prob_vec (struct seq *seq, const struct aa_clssfcn *aa_clssfcn);

#endif /* READ_AC_I_H */
