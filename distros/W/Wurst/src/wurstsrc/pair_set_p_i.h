/*
 * 8 March 2002
 * rscid = $Id: pair_set_p_i.h,v 1.1 2007/09/28 16:57:10 mmundry Exp $
 */
#ifndef PAIR_SET_P_I_H
#define PAIR_SET_P_I_H

struct pair_set;
struct seq;
struct sec_s_data;
struct coord;
unsigned 
get_seq_id_simple (  struct pair_set *pair_set, struct seq *s1, struct seq *s2 );

char *
pair_set_pretty_string (struct pair_set *pair_set,
                        struct seq *s1, struct seq *s2,
                        struct sec_s_data *sec_s_data, struct coord *c2);


#endif /* PAIR_SET_P_I_H */
