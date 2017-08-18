//classes.h
#ifndef CLASSES_H
#define CLASSES_H

#include "functions.h"


// See functions.h for the documentation of the functions and
// their arguments.
class nlpostClass
{
  /*
  * This object is a "function model" which can be used with the
  * optimisation routines of dlib. It is essentially a wrapper
  * to a function which computes the negative log-posterior density,
  * e.g. nlogLik + nlogPrior.
  */
private:
  matrix <double> Xmat, invS0;
  column_vector mu0;
  long n_b, n_tasks;
  double ldet;
  
public:
  // typedef ::column_vector column_vector;
  
  nlpostClass (const matrix <double>& Xmat_,
               const column_vector& mu0_,
               const matrix <double>& invS0_,
               const double& ldet_,
               const long& n_tasks_,
               const long& n_b_) {
    Xmat = Xmat_;
    mu0 = mu0_;
    invS0 = invS0_;
    ldet = ldet_;
    n_tasks = n_tasks_;
    n_b = n_b_; 
  }; 
  
  double operator() (const column_vector& x) const {
    return nlogPrior(x, mu0, invS0, ldet, n_b) +
      nlogLik(x, Xmat, n_tasks, n_b);
  }
};

class nlpost_gradClass
{
  /*
  * This object is a "function model" which can be used with the
  * optimisation routines of dlib. It is essentially a wrapper 
  * to a function which computes the gradient of nlpostClass.
  * Returns an n_b-vector.
  */
private:
  matrix <double> Xmat, invS0;
  column_vector mu0;
  long n_b, n_tasks;
  
public:
  // typedef ::column_vector column_vector;
  // typedef matrix <double> general_matrix;
  
  nlpost_gradClass (const matrix <double>& Xmat_,
                    const column_vector& mu0_,
                    const matrix <double>& invS0_,
                    const long& n_tasks_,
                    const long& n_b_) {
    Xmat = Xmat_;
    mu0 = mu0_;
    invS0 = invS0_;
    n_tasks = n_tasks_;
    n_b = n_b_; 
  }; 
  
  column_vector operator() (const column_vector& x) const {
    return nlogPrior_grad(x, mu0, invS0, n_b) + 
      nlogLik_grad(x, Xmat, n_tasks, n_b);;
  }
  // void get_derivative_and_hessian (
  //     const column_vector& x,
  //     column_vector& der,
  //     general_matrix& hess
  // ) const
  // {
  //   der = rosen_derivative(x);
  //   hess = rosen_hessian(x);
  // }
};

class nlPredClass
{
  /*
  * This object is a "function model" which can be used with the
  * optimisation routines of dlib. It is essentially a wrapper
  * to a function which computes the negative log-predictive density,
  * e.g. nlogLik + nlogPrior - logLiks.
  * Returns a double.
  */
  
private:
  matrix <double> Xmat, invS0;
  column_vector mu0, Xs;
  long n_b, n_tasks;
  double ldet;
  
public:
  // typedef ::column_vector column_vector;
  // typedef matrix <double> general_matrix;
  
  nlPredClass (const matrix <double>& Xmat_,
               const column_vector& Xs_,
               const column_vector& mu0_,
               const matrix <double>& invS0_,
               const double& ldet_,
               const long& n_tasks_,
               const long& n_b_) {
    Xmat = Xmat_;
    Xs = Xs_;
    mu0 = mu0_;
    invS0 = invS0_;
    ldet = ldet_;
    n_tasks = n_tasks_;
    n_b = n_b_; 
  }; 
  
  double operator() (const column_vector& x) const {
    double ld, nlp;
    ld = logLiks(x, Xs, n_b);
    nlp = nlogLik(x, Xmat, n_tasks, n_b) + nlogPrior(x, mu0, invS0, ldet, n_b);
    return nlp - ld;
  }
  // void get_derivative_and_hessian (
  //     const column_vector& x,
  //     column_vector& der,
  //     general_matrix& hess
  // ) const
  // {
  //   der = rosen_derivative(x);
  //   hess = rosen_hessian(x);
  // }
};

class nlPred_gradClass
{
  /*
  * This object is a "function model" which can be used with the
  * optimisation routines of dlib. It is essentially a wrapper
  * to a function which computes the gradient of the negative 
  * log-predictive density, e.g. the derivative of nlPredClass.
  * Returns an n_b-vector.
  */
  
private:
  matrix <double> Xmat, invS0;
  column_vector mu0, Xs;
  long n_b, n_tasks;
  
public:
  // typedef ::column_vector column_vector;
  // typedef matrix <double> general_matrix;
  
  nlPred_gradClass (const matrix <double>& Xmat_,
                    const column_vector& Xs_,
                    const column_vector& mu0_,
                    const matrix <double>& invS0_,
                    const long& n_tasks_,
                    const long& n_b_) {
    Xmat = Xmat_;
    Xs = Xs_;
    mu0 = mu0_;
    invS0 = invS0_;
    n_tasks = n_tasks_;
    n_b = n_b_; 
  };
  
  column_vector operator() (const column_vector& x) const {
    column_vector ld(n_b), nlp(n_b);
    ld = logLiks_grad(x, Xs, n_b);
    nlp = nlogLik_grad(x, Xmat, n_tasks, n_b) + nlogPrior_grad(x, mu0, invS0, n_b);
    return nlp - ld;
  }
};

class nlPredpClass
{
  /*
  * This object is a "function model" which can be used with the
  * optimisation routines of dlib. It is essentially a wrapper
  * to a function which computes the negative logarithm of the 
  * log-predictive density, e.g. nlogLik + nlogPrior - loglog_pk.
  * Returns a double
  */
  
private:
  matrix <double> Xmat, invS0;
  column_vector mu0, Xs;
  long n_b, n_tasks;
  double k, ldet;
  
public:
  // typedef ::column_vector column_vector;
  // typedef matrix <double> general_matrix;
  
  nlPredpClass (const matrix <double>& Xmat_,
                const column_vector& Xs_,
                const column_vector& mu0_,
                const matrix <double>& invS0_,
                const double& ldet_,
                const long& n_tasks_,
                const long& n_b_,
                const double& k_) {
    Xmat = Xmat_;
    Xs = Xs_;
    mu0 = mu0_;
    invS0 = invS0_;
    ldet = ldet_;
    n_tasks = n_tasks_;
    n_b = n_b_; 
    k = k_;
  }; 
  
  double operator() (const column_vector& x) const {
    double ld, nlp;
    ld = loglog_pk(x, Xs, n_b, k);
    nlp = nlogLik(x, Xmat, n_tasks, n_b) + nlogPrior(x, mu0, invS0, ldet, n_b);
    return nlp - ld;
  }
  // void get_derivative_and_hessian (
  //     const column_vector& x,
  //     column_vector& der,
  //     general_matrix& hess
  // ) const
  // {
  //   der = rosen_derivative(x);
  //   hess = rosen_hessian(x);
  // }
};

class nlPredp_gradClass
{
  /*
  * This object is a "function model" which can be used with the
  * optimisation routines of dlib. It is essentially a wrapper
  * to a function which computes the gradient of the negative 
  * log-predictive density, e.g. the derivative of nlPredpClass.
  * Returns an n_b-vector.
  */
  
private:
  matrix <double> Xmat, invS0;
  column_vector mu0, Xs;
  long n_b, n_tasks;
  double k;
  
public:
  // typedef ::column_vector column_vector;
  // typedef matrix <double> general_matrix;
  
  nlPredp_gradClass (const matrix <double>& Xmat_,
                     const column_vector& Xs_,
                     const column_vector& mu0_,
                     const matrix <double>& invS0_,
                     const long& n_tasks_,
                     const long& n_b_,
                     const double& k_) {
    Xmat = Xmat_;
    Xs = Xs_;
    mu0 = mu0_;
    invS0 = invS0_;
    n_tasks = n_tasks_;
    n_b = n_b_; 
    k = k_;
  }; 
  
  column_vector operator() (const column_vector& x) const {
    column_vector ld(n_b), nlp(n_b);
    ld = loglog_pk_grad(x, Xs, n_b, k);
    nlp = nlogLik_grad(x, Xmat, n_tasks, n_b) + nlogPrior_grad(x, mu0, invS0, n_b);
    return nlp - ld;
  }
};


#endif
