/*
 * 21 March 2001
 * rcsid = $Id: read_seq_i.h,v 1.1 2007/09/28 16:57:04 mmundry Exp $
 */
#ifndef READ_SEQ_H
#define READ_SEQ_H


struct seq_array;
struct seq;
struct seq        *seq_copy (const struct seq *seq);
struct seq        *seq_read (const char *fname);
struct seq        *seq_get_1 (struct seq_array **ps_a, size_t n);
struct seq        *seq_from_string (const char *src);
struct seq        *seq_from_thomas (const char *src, size_t n_a);
const char        *seq_get_thomas (struct seq *seq, size_t *n);
size_t             seq_num (struct seq_array **ps_a);
size_t             seq_size (const struct seq *s);
struct seq_array **seq_read_many (const char *fname, struct seq_array ** s_a);
char              *seq_print (struct seq *seq);
char              *seq_print_many (struct seq_array **ps_a);
void               seq_ini (struct seq *s);
void               seq_trim (struct seq *s, const size_t size);
void               seq_destroy (struct seq *s);
void               seq_array_destroy (struct seq_array **ps_a);
void               seq_thomas2std (struct seq *s);
void               seq_std2thomas (struct seq *s);
const char        *seq_get_res (struct seq *s, size_t i);
int                seq_res_is_gly (struct seq *s, size_t i);

#endif  /* READ_SEQ_H */
