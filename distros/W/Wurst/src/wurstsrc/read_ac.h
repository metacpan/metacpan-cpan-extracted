/*
 * $Id: read_ac.h,v 1.1 2007/09/28 16:57:12 mmundry Exp $
 */
#ifndef READ_AC_H
#define READ_AC_H

struct aa_clssfcn {
    size_t n_class;                /* number of classes */
    size_t n_att;                  /* number of attributes per class */
    float ***log_pp;               /* log of attribute probability */
    float  *class_wt;              /* Normalised weight of each class */
};

#endif /* READ_AC_H */
