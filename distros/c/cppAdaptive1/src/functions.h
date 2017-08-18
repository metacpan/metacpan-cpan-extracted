//functions.h
#ifndef FUNCTIONS_H
#define FUNCTIONS_H

#include "dlib/optimization.h"
#include "dlib/matrix.h"
#include "dlib/numeric_constants.h"
#include <iostream>
#include <random>
#include <math.h>
#include <algorithm>

using namespace std;
using namespace dlib;

// ----------------------------------------------------------------------------------
typedef matrix<double,0,1> column_vector;
// ----------------------------------------------------------------------------------

double plogis (const double& x) {
  
  /* 
  * the cumulative distribution function of the
  * standard logistic distribution. Needed below and
  * defined here for convenience.
  */
  
  return 1.0/(1.0+exp(-x));
  
}

double nlogLik (const column_vector& x,
                const matrix <double>& X,
                const long& n_tasks,
                const long& n_b)
				
{
  /*
  * Function for computing the negative log-likelihood 
  * for binary choice tasks. The args are as follows:
  * - x: the vector of parameters;
  * - X: the matrix of observed choice tasks. The rows
  * of X must be the non chosen alternative minus
  * the non chosen alternative.
  * - n_tasks: the number of observed choice tasks;
  * - n_b: the number of parameters, e.g the length of x.
  */
  double ans = -1.0 * sum(log(1.0 + exp(X*x)));
  return -1.0 * ans;
}

double logLiks (const column_vector& x,
                const column_vector& Xs,
                const long& n_b){
  /*
  * Fucntion for computing the log-likelihood 
  * for a future binary choice task. The args are:
  * - x: the vector of parameters;
  * - Xs: vector of the future choice task;
  * - n_b: the number of parameters, e.g the length of x.
  */
  return  -1.0 * log(1 + exp(trans(Xs)*x));
}

double loglog_pk (const column_vector& x,
                  const column_vector& Xs,
                  const long& n_b,
                  const double& k){
  /*
  * computes the logarithm of the log-likelihood. The args
  * are the same as before. k is a postive value. See below.
  * Note that since the log of log-likelihood is not always 
  * finite (the log-likelihood is real), we add a big k 
  * constant before applying the log. The reason for this is 
  * that now log(k + log-lik) can be expanded and the Laplace 
  * approximation can be applied. Note also that k is arbitrary
  * since after the Laplace approximation we subtract out k and
  * obtain the approximated integral free of k. This strategy 
  * was also adopted by Tierney and Kadane (1986, JASA) when 
  * approximating posterior moments of non positive functions.
  */
  
  double xtb;
  xtb = trans(Xs)*x;
  
  return log(k + -1.0*log(1.0 + exp(xtb)));
}


double nlogPrior(const column_vector& x,
                 const column_vector& mu0,
                 const matrix <double>& invS0,
                 const double& ldet,
                 const long& n_b)
{
  /*
  * computes the negative log-prior. The prior is a 
  * multivariate normal distribution with mean vector 
  * mu0 and concentration matrix invS0. Notice that x
  * and mu0 must have the same dimension, e.g. n_b times
  * 1 and invS0 must be positive definite n_b times n_b
  * matrix.
  */
  double logans = 0.0;
  
  // ldet = log(det(invS0));
  
  logans = -0.5*n_b * log(2*pi) + 0.5*ldet - 0.5*trans(x-mu0)*invS0*(x-mu0);
  
  return -1.0 * logans;
}

column_vector 
  nlogLik_grad (const column_vector& x, 
                const matrix <double>& X,
                const long& n_tasks,
                const long& n_b){
    /*
    * computes the gradient of the negative log-likelihood, 
    * e.g. the first derivative of nlogLik.
    * Returns an n_b-vector.
    */
    double xtb;
    long i;
    column_vector ans(n_b);
    set_all_elements(ans,0.0);
    
    for(i=0; i<n_tasks; i++){
      xtb = rowm(X,i)*x;
      ans += plogis(xtb)*trans(rowm(X,i));
    }
    
    return ans;
  }

const column_vector 
  nlogPrior_grad(const column_vector& x,
                 const column_vector& mu0,
                 const matrix <double>& invS0,
                 const long& n_b){
    /*
    * computes the gradient of the negative log-prior
    * density, e.g. the first derivative of nlogLik.
    * Returns an n_b-vector.
    */
    return invS0*(x-mu0);
  }


column_vector logLiks_grad (const column_vector& x, 
                            const column_vector& Xs,
                            const long& n_b){
  /*
  * computes the gradient of logLiks.
  * Returns an n_b-vector.
  */
  
  double xtb;
  xtb = trans(Xs)*x;
  return -1.0*plogis(xtb)*Xs;
}

column_vector loglog_pk_grad (const column_vector& x,
                              const column_vector& Xs,
                              const long& n_b,
                              const double& k){
  /*
  * computes the gradient of loglog_pk.
  * Returns an n_b-vector.
  */
  
  double xtb;
  xtb = trans(Xs)*x;
  
  return -1.0*Xs*plogis(xtb)/(-1.0*log(1.0 + exp(xtb)) + k);
  
}

matrix <double> logLiks_hess (const column_vector& x, 
                              const column_vector& Xs,
                              const long& n_b)
{
  /*
  * computes the Hessian matrix of the negative
  * log-likelihood, e.g. the second derivative of
  * nlogLik.
  * Returns an n_b times n_b matrix.
  */
  double xtb;
  xtb = trans(Xs)*x;
  
  return -1.0*plogis(xtb)*Xs*trans(Xs)/(1.0+exp(xtb));;
}

matrix <double>
  loglog_pk_hess(const column_vector& x,
                 const column_vector& Xs,
                 const long& n_b,
                 const double& k){
    /*
    * computes the Hessian matrix of the loglog_pk,
    * Returns an n_b times n_b matrix.
    */
    
    matrix <double> ans(n_b, n_b);
    double xtb;
    xtb = trans(Xs)*x;
    
    ans = Xs*trans(Xs);
    ans *= -1.0*plogis(xtb)*(k + exp(xtb) - log(1+exp(xtb)));
    ans /= (1+exp(xtb))*pow(k - log(1 + exp(xtb)), 2.0);
    
    return ans;
  }

matrix <double> nlogPost_hess (const column_vector& x,
                               const matrix <double>& X,
                               const matrix <double>& invS0,
                               const long& n_tasks,
                               const long& n_b){
  /*
  * computes the Hessian matrix of the negative 
  * log-posterior, e.g. the second derivative of
  * nlogLik + nlogPrior.
  * Returns an n_b times n_b matrix.
  */
  double xtb;
  // const int nb = n_b;
  matrix <double> ans(n_b, n_b);
  set_all_elements(ans, 0.0);
  
  for(long i=0; i<n_tasks; i++){
    xtb = rowm(X,i)*x;
    ans += plogis(xtb)*trans(rowm(X,i))*rowm(X,i)/(1.0 + exp(xtb));
  }
  
  return ans + invS0;
}

matrix <double> nlogPred_hess (const column_vector& x,
                               const matrix <double>& X,
                               const column_vector& Xs,
                               const matrix <double>& invS0,
                               const long& n_tasks,
                               const long& n_b){
  /*
  * computes the Hessian matrix of the negative 
  * log-predictive posterior density, e.g. the second derivative of
  * nlogLik + nlogPrior -logLiks
  * Returns an n_b times n_b matrix.
  */
  
  return nlogPost_hess(x, X, invS0, n_tasks, n_b) - logLiks_hess(x, Xs, n_b);
}

matrix <double> nlogPredp_hess (const column_vector& x,
                                const matrix <double>& X,
                                const column_vector& Xs,
                                const matrix <double>& invS0,
                                const long& n_tasks,
                                const long& n_b,
                                const double& k){
  /*
  * computes the Hessian matrix of the negative 
  * logarithm of log-predictive posterior density, e.g. the second derivative of
  * nlogLik + nlogPrior -loglog_pk
  * Returns an n_b times n_b matrix.
  */
  
  return nlogPost_hess(x, X, invS0, n_tasks, n_b) - loglog_pk_hess(x, Xs, n_b, k);
}


column_vector rmvnorm(const column_vector& mu,
                      const matrix <double>& cholS,
                      const long& p)
{
  /* 
  * Multivariate normal random variates Y = mu + AX
  * X is iid standard normal with mean vector mu and 
  * the matrix A a "square root" of the covariance matrix
  * S, e.g. it is such that AA^T = S. 
  * The function generates a single draw which is,
  * a p-dimensional vector. 
  */
  
  // set a "random" seed
  //unsigned seed = std::chrono::system_clock::now().time_since_epoch().count();
  
  column_vector z(p);
  z = gaussian_randm(p, 1, time(0));
  
  return mu + cholS*z;
}

#endif
