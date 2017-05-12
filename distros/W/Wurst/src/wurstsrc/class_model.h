/*
 * $Id: class_model.h,v 1.3 2008/03/08 16:50:53 torda Exp $
 */
#ifndef CLASS_MODEL_H
#define CLASS_MODEL_H

/* ---------------- Structures -------------------------------- */
struct clssfcn {         /* structure to store a classification         */
    double ***param;     /* parameters for each class in each dimension */
    double **cov_matrix; /* (1-dim) covariance matrix of each class     */
    float *class_weight; /* relative population of each class           */
    enum {
        SINGLE_NORMAL,   /* gaussian normal distribution                */
        MULTI_NORMAL,    /* correlated gaussian normal distribution     */
        UNKNOWN          /* unknown distribution                        */
    } **classmodel;      /* which kinds of models are used              */
    size_t n_class;      /* number of classes                           */
    size_t dim;          /* dimension of feature space (input-vector)   */
    float abs_error;     /* absolut error in (input) measurement        */
};

struct clssfcn * get_clssfcn(const char *influence_report_filename,
                             const float abs_error);
void    clssfcn_destroy(struct clssfcn * c);
float * computeMembership(float *mship, const float* test_vec,
                          const struct clssfcn *cmodel);
float *
computeMembershipStrct (float *mship, const float * test_vec,
                        const struct clssfcn *cmodel);
#endif /* CLASS_MODEL_H */
