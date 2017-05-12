/* "$Id: lsqf.h,v 1.2 2008/01/18 13:51:20 margraf Exp $" */
#ifndef LSQF_H 
#define LSQF_H

int get_rmsd(struct pair_set *pairset, struct coord *r1,
    struct coord *r2, float *rmsd_ptr, int *count);

int
coord_rmsd (struct pair_set *pairset, struct coord *coord1, struct coord *coord2,
	    int sub_flag, float *rmsd, struct coord **c1_new, struct coord **c2_new);
#endif
