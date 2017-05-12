/*
 * 30 Oct 2001
 * Interface to pdb writing routines.
 * rcsid = $Id: pdbout_i.h,v 1.1 2007/09/28 16:57:09 mmundry Exp $
 */
#ifndef PDBOUT_I_H
#define PDBOUT_I_H

struct coord;
struct seq;
struct scor_set;

int coord_2_pdb (const char *fname, struct coord *c, struct seq *seq);
int coord_2_cptn (const char *fname, struct coord *c, struct seq *seq);
int coord_2_spdb (const char *fname, struct coord *c, struct seq *seq, struct scor_set *scr);
#endif /* PDBOUT_I_H */
