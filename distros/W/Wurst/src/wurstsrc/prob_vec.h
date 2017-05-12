/*
 * 14 June 2005
 * This defines the vector of class membership probability.
 * It lives in its own file since it must be visible to
 * different class or structure functions.
 * It can exist in more than one form. It may be a simple array,
 * or it may be compact, containing only the non-zero
 * probabilities.
 * It may be normalised so that the probabilities sum to 1.0, or
 * so that the sum of squares sums to 1.0.
 * rcsid = $Id: prob_vec.h,v 1.1 2007/09/28 16:57:05 mmundry Exp $
 */

#ifndef PROB_VEC_H
#define PROB_VEC_H

extern const char PVEC_TRUE_PROB;             /* Normalised to sum = 1.0 */
extern const char PVEC_UNIT_VEC;              /* or to unit vector size */
extern const char PVEC_CRAP;                  /* Don't know yet. */

/*
 * In the compact form cmpct_xxxx,
 * cmpct_n says how many probabilities are used at each site.
 * cmpct_ndx says indices of classes which are used.
 * cmpct_prob is a flat array of corresponding probabilities.
 * 
 * mship[a][b] is the membership of "site" a in class b.
 * It is dimensioned as mship [n_pvec][n_class].
 * The definition of a site is not so simple when it refers to more than
 * one amino acid from the original protein.
 */
  
struct prob_vec {
    unsigned short int *cmpct_n;  /* Number of stored probabilities per site */
    float *cmpct_prob;                     /* The list of probability values */
    unsigned short int *cmpct_ndx;                   /* Indices within class */
                                                         /* cmpct_n per site */
    float **mship;                  /* The expanded, simple array membership */
    size_t n_pvec;                          /* Number of probability vectors */
    size_t n_class;            /* How many classes are in the classification */
    size_t prot_len;                   /* The length of the original protein */
    size_t frag_len;         /* The length of the fragment. Typically 4 to 9 */
    char norm_type;                     /* True probability or unit vector ? */
    char *compnd;                           /*The compound information string*/
    size_t compnd_len;               /*The length of the compound information*/
};

#endif /* PROB_VEC_H */
