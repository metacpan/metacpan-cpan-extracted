//KLP.h
#ifndef KLP_H
#define KLP_H

#include "classes.h"

// this function computes the KLP for a future choice task
// The arguments are: 
// - Xmat: the matrix of observed choice task;
// - futureX: the vector of a future choice task;
// - invS0: the prior concentration matrix;
// - ldet: the log-determinant of invS0;
// - mu0: the prior mean;
// - n_tasks: the number of observed choice tasks;
// - n_b: the number of parameters;
// postLa: the posterior normalising constant as approxiamted
//        by the Laplace approximation.

double KLP(const matrix <double>& Xmat, 
           const column_vector& futureX,
           const matrix <double>& invS0,
           const double& ldet,
           const column_vector& mu0,
           const long& n_tasks,
           const long& n_b,
           const double& postLa){
  
  // initialize some objects
  column_vector starting_point1 = mu0,
    starting_point2 = mu0,
    starting_pointp1 = mu0,
    starting_pointp2 = mu0;
  double predLA1,
  predpLA1,
  predpLA2;
  const double k = 1000.0;
  
  // computation for the first choice
  nlPredClass nlPred1(Xmat, futureX, mu0, invS0, ldet, n_tasks, n_b);
  nlPred_gradClass nlPred_grad1(Xmat, futureX, mu0, invS0, n_tasks, n_b);
  
  // find the min of the neg log-predictive
  find_min(bfgs_search_strategy(),
           objective_delta_stop_strategy(1e-13),
           nlPred1,
           nlPred_grad1, 
           starting_point1,
           -100);
  predLA1 = exp(0.5*n_b*log(2*pi) - nlPred1(starting_point1) - 
  0.5*log(det(nlogPred_hess(starting_point1,
                            Xmat,
                            futureX,
                            invS0,
                            n_tasks,
                            n_b))) - postLa);
  
  nlPredpClass nlPredp1(Xmat, futureX, mu0, invS0, ldet, n_tasks, n_b, k);
  nlPredp_gradClass nlPredp_grad1(Xmat, futureX, mu0, invS0, n_tasks, n_b, k);
  
  // find the min of the neg log log-predictive
  find_min(bfgs_search_strategy(),
           objective_delta_stop_strategy(1e-13),
           nlPredp1,
           nlPredp_grad1,
           starting_pointp1,
           -100);
  
  predpLA1 = exp(0.5*n_b*log(2*pi) - nlPredp1(starting_pointp1) - 
  0.5*log(det(nlogPredp_hess(starting_pointp1,
                             Xmat,
                             futureX,
                             invS0,
                             n_tasks,
                             n_b,
                             k))) - postLa)-k;
  
  // computation for the second choice
  // nlPredClass nlPred2(Xmat, -1.0*futureX, mu0, invS0, ldet, n_tasks, n_b);
  // nlPred_gradClass nlPred_grad2(Xmat, -1.0*futureX, mu0, invS0, n_tasks, n_b);
  // 
  // // find the min of the neg log-predictive
  // find_min(bfgs_search_strategy(),
  //          objective_delta_stop_strategy(1e-13),
  //          nlPred2,
  //          nlPred_grad2,
  //          starting_point2,
  //          -100);
  // // 
  // predLA2 = exp(0.5*n_b*log(2*pi) - nlPred2(starting_point2) -
  // 0.5*log(det(nlogPred_hess(starting_point2,
  //                           Xmat,
  //                           -1.0*futureX,
  //                           invS0,
  //                           n_tasks,
  //                           n_b))) - postLa);

  nlPredpClass nlPredp2(Xmat, -1.0*futureX, mu0, invS0, ldet,  n_tasks, n_b, k);
  nlPredp_gradClass nlPredp_grad2(Xmat, -1.0*futureX, mu0, invS0, n_tasks, n_b, k);
  
  // find the min of the neg log log-predictive
  find_min(bfgs_search_strategy(),
           objective_delta_stop_strategy(1e-13),
           nlPredp2,
           nlPredp_grad2,
           starting_pointp2,
           -100);
  
  predpLA2 = exp(0.5*n_b*log(2*pi) - nlPredp2(starting_pointp2) - 
  0.5*log(det(nlogPredp_hess(starting_pointp2,
                             Xmat,
                             -1.0*futureX,
                             invS0,
                             n_tasks,
                             n_b,
                             k))) - postLa)-k;
  
  return predLA1*(log(predLA1) - predpLA1) + (1.0-predLA1)*(log(1.0-predLA1) - predpLA2);
}

#endif
