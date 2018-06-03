#include <iostream>
#include <fstream>   
#include <chrono>
#include "dlib/matrix.h"
#include "omp.h"
#include <random>

using namespace dlib;
using namespace std;

#define THREADS 2

const int n_tasks          = 15;                                 
const int n_alts           = 3;                                  
const int none_option      = 0;                                  
const int n_attr           = 5;                                  
const int n_levels[n_attr] = {3,3,3,3,3};                        
const int n_betas          = 10;                                 
const int n_draws          = 32;                                 
const int n_overlap        = 2;                                  


// prior mean, covariance, and precision matrices for calculating the posterior beta's
const matrix <double, n_betas, 1>  prior_mu = {0.0};
const matrix <double, n_betas, n_betas> prior_Sigma = identity_matrix<double>(n_betas);            
const matrix <double, n_betas, n_betas> prior_tau = inv(prior_Sigma);

// design dimensions
const int n_rowsD        = n_tasks*n_alts;                       
const int n_rowsX        = n_tasks*(n_alts-1);                   
const int n_rowsXtask    = n_alts-1;                             


struct {
    matrix <double, 1,n_betas>               beta;
    matrix <double, n_betas,n_rowsX>         trX_Z;
    matrix <double, n_betas,n_betas>         Fisher;
    double                                   D_eff;
    matrix <double, n_betas,n_rowsXtask>     newTrX_Z;
    matrix <double, n_betas,n_betas>         newFisher;
    double                                   newD_eff;
} draw[n_draws];

const int n_candidates = 24;
const matrix <double, n_candidates*n_rowsXtask, 2> candidates = {
0,0,1,0,
0,0,0,1,
1,0,0,0,
1,0,1,0,
1,0,0,1,
0,1,0,0,
0,1,1,0,
0,1,0,1,
-1,0,-1,0,
-1,0,0,0,
-1,0,-1,1,
0,0,-1,0,
0,0,-1,1,
-1,1,-1,0,
-1,1,0,0,
-1,1,-1,1,
0,-1,0,-1,
0,-1,1,-1,
0,-1,0,0,
1,-1,0,-1,
1,-1,1,-1,
1,-1,0,0,
0,0,0,-1,
0,0,1,-1};


void str2beta(const string &input, matrix <double, n_betas, 1> &output)
{
	int start = 0;
	for (size_t i = 0; i < n_betas; ++i){
	   int ind = input.find(",", start);
	   output(i) = atof(input.substr(start, ind - start).c_str());
	   start = ind + 1;
	}
}



void str2design(const string &input, matrix <double, n_rowsD,n_attr> &output)
{
	int start = 0;
	for (size_t i = 0; i < n_rowsD; ++i){
	   for (size_t j = 0; j < n_attr; j++){
	      char  str[2] = { '\0','\0' };
	      str[0]=input[start];
	      output(i, j) = atof(str);
	      start += 1;
	   }
	}
}



void design2X(const matrix<double, n_rowsD, n_attr>  &design, 
                    matrix<int, n_tasks, n_attr>     &X_overlap, 
					matrix <double, n_rowsX,n_betas> &X, 
					matrix<double>                   &X_likelihood, 
					int                              n_observed, 
					matrix <int, n_attr,1>           &beg_col , 
					matrix <int, n_attr,1>           &end_col)       
{
    X_overlap=1;
    for (int i=0; i<n_attr; i++)
	  for (int t=n_observed; t< n_tasks; t++)
	    for (int j=1; j<n_alts; j++)
	      if (design(t*n_alts,i)!=design(t*n_alts+j,i)){
	      	X_overlap(t,i)=0;
	      	break;
		  }

    beg_col(0)=0; 
    end_col(0)=n_levels[0]-2; 
    for (int i = 1; i < n_attr; i++){
       beg_col(i)=beg_col(i-1) + n_levels[i]-1;
       end_col(i)=end_col(i-1) + n_levels[i]-1;
    }
     
    matrix <double, n_rowsD, n_betas>  X_dummy;
	X_dummy = 0.0;                  
    
    int attr = 0;
    int level = 2;     
    for (int j = 0; j < n_betas; j++){
       for (int i = 0; i < n_rowsD; i++){
         if (design(i,attr)==level) X_dummy(i,j)=1;
       }
       level++; 
       
       if (level>n_levels[attr]){
          attr++;
     	  level=2;
       }  
	}
    
    // FIRST choice alternative per choice task is chosen	 
  	for (int t=0; t< n_tasks; t++)    
	  for (int i=1; i<n_alts; i++) 
        for (int j=0; j<n_betas; j++)              	     
			X(t*n_rowsXtask+(i-1),j)= X_dummy(t*n_alts+i,j) - X_dummy(t*n_alts,j);
		  

    X_likelihood = rowm(X,range(0,n_observed*n_rowsXtask-1 ));
}



void calcFunc_Pairwise( const matrix<double, n_betas, 1> &b_optim,
                        const int &n_observed,  
                        const matrix<double> &X_likelihood, 
					    double &f, 
					    matrix<double> &phi )
{
    matrix<double, n_betas, 1> temp; 
    phi = 0.0;
    for (int i=0; i<n_observed; i++ )
     for (int j=0; j< n_betas; j++ )
       phi(i) += X_likelihood(i,j) * b_optim(j);
    phi = exp(phi);      
    double LL = sum(-log(1.0+phi));
    temp = b_optim-prior_mu;
    LL += -0.5 * (trans(temp)*prior_tau*temp);
    f = -LL;
}

void calcFunc_General( const matrix<double, n_betas, 1> &b_optim,
                       const int &n_observed,
                       const matrix<double> &X_likelihood, 
					   double &f, 
					   matrix<double> &phi,
					   matrix<double> &sumPhi)
{
    matrix<double, n_betas, 1> temp; 
    phi = 0.0;
    for (int i=0; i<n_observed; i++ )
      for (int j=0; j<n_alts-1; j++ )
        for (int k=0; k< n_betas; k++ )
          phi(i,j) += X_likelihood((i*(n_alts-1)+j),k) * b_optim(k);
    phi = exp(phi);           
    sumPhi = sum_cols(phi);   
    double LL = sum(-log(1.0+sumPhi));
    temp = b_optim-prior_mu;
    LL += -0.5 * (trans(temp)*prior_tau*temp);
    f = -LL;
}

void calcGrad_Pairwise( const matrix<double, n_betas, 1> &b_optim,
                        const int &n_observed, 
                        const matrix<double> &X_likelihood, 
					    matrix<double> &phi,
					    matrix<double, n_betas, 1> &grad)
{
    matrix<double, n_betas, 1> temp;
    matrix<double> temp1(n_observed, 1);
    matrix<double> temp2(n_betas, n_observed);
    temp = b_optim-prior_mu;
    for (int i=0; i<n_observed; i++)
      temp1(i) = 1.0 / (1.0 + phi(i));            
    for (int i=0; i<n_observed; i++ )
      for (int j=0; j< n_betas; j++ )  
        temp2(j,i) = phi(i) * X_likelihood(i,j);  
       
    grad = prior_tau*temp + temp2*temp1;          
}

void calcGrad_General( const matrix<double, n_betas, 1> &b_optim, 
                       const int &n_observed,
                       const matrix<double> &X_likelihood, 
                       matrix<double> &phi,
					   matrix<double> &sumPhi,
					   matrix<double, n_betas, 1> &grad)
{
    matrix<double, n_betas, 1> temp;
    matrix<double> temp1(n_observed, 1);
    matrix<double> temp2(n_betas, n_observed);

    temp = b_optim-prior_mu;
    for (int i=0; i<n_observed; i++)
      temp1(i) = 1.0 / (1.0 + sumPhi(i));                             
    temp2 = 0.0;
    for (int i=0; i<n_observed; i++ )
      for (int j=0; j<n_alts-1; j++ )
        for (int k=0; k< n_betas; k++ )
          temp2(k,i) += phi(i,j) * X_likelihood((i*(n_alts-1)+j),k); 
    grad = prior_tau*temp + temp2*temp1;
}

void calcHess_Pairwise( const int &n_observed,  
                   const matrix<double> &X_likelihood, 
				   matrix<double> &phi,
				   matrix<double, n_betas, n_betas> &Hess)
{
    matrix<double> Z(n_observed,n_observed);

    Z=0.0;  
    for (int i=0; i<n_observed; i++){
      double P = phi(i) / (1.0 + phi(i)); 
      double PP = 1.0 - P;
      Z(i,i) = P * PP;
    }
    Hess = prior_tau + (trans(X_likelihood)*Z)*X_likelihood;
}


void calcHess_General( const int &n_observed, 
                  const matrix<double> &X_likelihood, 
				  matrix<double> &phi,
				  matrix<double> &sumPhi,
				  matrix<double, n_betas, n_betas> &Hess)
{
    matrix<double> P(n_observed * (n_alts-1), 1);
    matrix<double> Z(n_observed * (n_alts-1), n_observed * (n_alts-1));
  
    for (int i=0; i<n_observed; i++ )
      for (int j=0; j<n_alts-1; j++ )
        P(i*(n_alts-1)+j) = phi(i,j) / (1.0+sumPhi(i));
    Z = 0.0;
    for (int i=0; i<n_observed * (n_alts-1); i++)
      Z(i,i) = P(i) * (1.0-P(i));
    if (n_alts>2){
      int end_col = n_alts-1;
      for (int row=0; row<n_observed*(n_alts-1); row++)
        if ((row+1)%(n_alts-1)==0)
          end_col += n_alts-1 ;
        else 
          for (int col=row+1; col<end_col; col++){
            Z(row,col) = -P(row)*P(col);
            Z(col,row) = Z(row,col);
          }    
    }
    Hess = prior_tau + (trans(X_likelihood)*Z)*X_likelihood;
}



void calculatePosterior( matrix<double, n_betas, 1> &b_optim, 
                         const int &n_observed, 
                         const matrix<double> &X_likelihood, 
						 matrix <double, n_betas, n_betas> &chol_covar) 	
{          
    matrix<double, n_betas, n_betas> Hess;
    if (n_alts==2) {

      double f, f_new;
      matrix<double> phi( n_observed, 1);
      matrix<double, n_betas, 1> grad, diff, b_new;

      calcFunc_Pairwise(b_optim, n_observed, X_likelihood, f, phi);
	        
      for (int t = 0; t<100; t++){
         calcGrad_Pairwise(b_optim, n_observed, X_likelihood, phi, grad);
         calcHess_Pairwise(n_observed, X_likelihood, phi, Hess);
       
        diff = inv(Hess)*grad;
        b_new = b_optim - diff;  
        calcFunc_Pairwise(b_new, n_observed, X_likelihood, f_new, phi);

        if (f_new > f) { 
	      matrix<double, n_betas, 1> diff2;
		  diff2= diff;
          do{ 
            diff2 = 0.33 * diff2;   
            b_new = b_optim - diff2;   
            calcFunc_Pairwise(b_new, n_observed, X_likelihood, f_new, phi);
          } 
	 	  while (f_new > f);     
	    }   

        b_optim = b_new;
        f = f_new;

        if (max(abs(diff)) < 1E-6){
           calcHess_Pairwise(n_observed, X_likelihood, phi, Hess);
           break;
        }
      }
    } else { 

      double f, f_new;
      matrix<double> phi( n_observed, n_alts-1);
      matrix<double> sumPhi( n_observed, 1);
      matrix<double, n_betas, 1> grad, diff, b_new;
      
      calcFunc_General(b_optim, n_observed, X_likelihood, f, phi, sumPhi);

      for (int t = 0; t<100; t++){
         calcGrad_General(b_optim, n_observed, X_likelihood, phi, sumPhi, grad);
         calcHess_General(n_observed, X_likelihood, phi, sumPhi, Hess);
       
        diff = inv(Hess)*grad;
        b_new = b_optim - diff;  
        calcFunc_General(b_new, n_observed, X_likelihood, f_new, phi, sumPhi);
  
        if (f_new > f) { 
	      matrix<double, n_betas, 1> diff2;
		  diff2= diff;
          do{ 
            diff2 = 0.33 * diff2;   
            b_new = b_optim - diff2;   
            calcFunc_General(b_new, n_observed, X_likelihood, f_new, phi, sumPhi);
          } 
	 	  while (f_new > f);     
	    }   

        b_optim = b_new;
        f = f_new;

        if (max(abs(diff)) < 1E-6){
           calcHess_General(n_observed, X_likelihood, phi, sumPhi, Hess);
           break;
        }
      }
    } 

    chol_covar = chol(inv(Hess));
}


float rnd()
{
    thread_local static std::mt19937 mt(time(0));
    thread_local static std::uniform_real_distribution<float> std_unif(0, 1);
    return std_unif(mt);
}

void createLHS( matrix <double, n_draws, n_betas> &lhs)
{
  const int n_cols   = n_betas;
  const int n_rows   = n_draws;
  const int max_rows = n_rows*(n_rows-1)/2;
  
  matrix <int, n_draws,n_betas>    X;
  matrix <int, max_rows,n_cols>    sq_dev;
  matrix <int, max_rows,1>         sum_sq_dev;
  matrix <double, max_rows,1>      sqrt_sum_sq_dev;
  matrix <int, 2,1>                x;
  
  matrix <int, max_rows,1>         new_sq_dev;
  matrix <int, max_rows,1>         new_sum_sq_dev;  
  matrix <double, max_rows,1>      new_sqrt_sum_sq_dev;  
  
  double sum_criterion;
  double new_sum_criterion;
  double min_criterion;
  matrix <int, n_draws,n_betas>    final_X;
  matrix <double, n_draws,n_betas> LHS;
  
  for (int col=0; col<n_cols; col++)
    for (int row=0; row<n_rows; row++)
      X(row,col)= row+1;
                
  for (int t=0; t<10; t++){          
    for (int col=0; col<n_cols; col++){
      for (int i=n_draws-1; i>0; i--){  
        int j = floor(rnd()*i);
        int temp = X(j,col);
        X(j,col) = X(i,col);
        X(i,col) = temp;
    }}
    
    int r = 0;
    for (int i=0; i<n_rows; i++){
      for (int j=i+1; j<n_rows; j++){
        for (int c=0; c<n_cols; c++){
      	  int temp = X(i,c) - X(j,c); 
          sq_dev(r, c) = temp*temp;
        }
        r = r +1;
    }}
  
   sum_sq_dev = 0;
    for (r=0; r<max_rows; r++){
      for (int c=0; c<n_cols; c++){
        sum_sq_dev(r) = sum_sq_dev(r) + sq_dev(r,c);      
      }
      sqrt_sum_sq_dev(r) = 1.0/ sqrt(double( sum_sq_dev(r) ));
    }
    sum_criterion = sum(sqrt_sum_sq_dev);
  
    int nr_loops_without_swap=0;
    do{
	  nr_loops_without_swap++;    
      for (int col=0; col<n_cols; col++){
         new_sq_dev          = colm(sq_dev,col);
         new_sum_sq_dev      = sum_sq_dev;
         new_sqrt_sum_sq_dev = sqrt_sum_sq_dev;
         new_sum_criterion   = sum_criterion;
         do{
           x(0) = floor(1+ n_rows * rnd());
		   x(1) = floor(1+ n_rows * rnd());
		          
           if (x(0)>x(1)){
		     int temp=x(0);  
             x(0)=x(1);
		     x(1)=temp; 
           }
         } while (x(0)==x(1));
         
         int sigma = (x(0)-1)*n_rows -(x(0)-1)*double((x(0))/2.0);
         int i = x(0);
         for (int j=i+1; j<=n_rows; j++){
           if (j != x(1)){
             int row_nr1 = sigma + j-i;
		         row_nr1--;  
             int row_nr2;
       	     if (x(1) < j){
       	       row_nr2 = (x(1)-1)*n_rows -(x(1)-1)*(double(x(1))/2.0) + j-x(1);
       	       row_nr2--;   
	         } else {	  
       	       row_nr2 = (j-1)*n_rows -(j-1)*(double(j)/2.0)+ x(1)-j;
       	       row_nr2--;    
             } 

             int temp = new_sq_dev(row_nr1);
             new_sq_dev(row_nr1) = new_sq_dev(row_nr2);
		     new_sq_dev(row_nr2) = temp;
             new_sum_sq_dev(row_nr1) = new_sum_sq_dev(row_nr1) - sq_dev(row_nr1,col) + new_sq_dev(row_nr1);
             new_sum_sq_dev(row_nr2) = new_sum_sq_dev(row_nr2) - sq_dev(row_nr2,col) + new_sq_dev(row_nr2);
             new_sqrt_sum_sq_dev(row_nr1) = 1.0/ sqrt( new_sum_sq_dev(row_nr1) );
             new_sqrt_sum_sq_dev(row_nr2) = 1.0/ sqrt( new_sum_sq_dev(row_nr2) );
             new_sum_criterion = new_sum_criterion - sqrt_sum_sq_dev(row_nr1) + new_sqrt_sum_sq_dev(row_nr1);
             new_sum_criterion = new_sum_criterion - sqrt_sum_sq_dev(row_nr2) + new_sqrt_sum_sq_dev(row_nr2);
           }
         }
       

         int j=x(0);
         for (int i=1; i<=j-1; i++){

           int row_nr1 = (i-1)*n_rows -(i-1)*(double(i)/2.0) + j-i;
               row_nr1--;  
           int row_nr2;
       	   if (x(1) >i){
       	     row_nr2 = (i-1)*n_rows -(i-1)*(double(i)/2.0) + x(1)-i;
       	     row_nr2--;  
       	   } else {
         
       	     row_nr2 = (x(1)-1)*n_rows -(x(1)-1)*(double(x(1))/2.0) + i-x(1);
       	     row_nr2--;  
           }

           int temp = new_sq_dev(row_nr1);
           new_sq_dev(row_nr1) = new_sq_dev(row_nr2);
	       new_sq_dev(row_nr2) = temp;
           new_sum_sq_dev(row_nr1) = new_sum_sq_dev(row_nr1) - sq_dev(row_nr1,col) + new_sq_dev(row_nr1);
           new_sum_sq_dev(row_nr2) = new_sum_sq_dev(row_nr2) - sq_dev(row_nr2,col) + new_sq_dev(row_nr2);
           new_sqrt_sum_sq_dev(row_nr1) = 1.0/ sqrt(new_sum_sq_dev(row_nr1) );
           new_sqrt_sum_sq_dev(row_nr2) = 1.0/ sqrt(new_sum_sq_dev(row_nr2) );
           new_sum_criterion = new_sum_criterion - sqrt_sum_sq_dev(row_nr1) + new_sqrt_sum_sq_dev(row_nr1);
           new_sum_criterion = new_sum_criterion - sqrt_sum_sq_dev(row_nr2) + new_sqrt_sum_sq_dev(row_nr2);
         }
              
         if (new_sum_criterion < sum_criterion){
       	   nr_loops_without_swap=0;
       	
           int temp = X(x(0)-1,col);
           X(x(0)-1,col) = X(x(1)-1,col);
		   X(x(1)-1,col) = temp;
        
           set_colm(sq_dev,col) = new_sq_dev;
           sum_sq_dev           = new_sum_sq_dev;
           sqrt_sum_sq_dev      = new_sqrt_sum_sq_dev;
           sum_criterion        = new_sum_criterion;
         }
      } 
    } while (nr_loops_without_swap<200);


    if (t==0){
      min_criterion = sum_criterion;
      final_X = X;   
    } else if (sum_criterion < min_criterion) {
      min_criterion = sum_criterion; 	
      final_X = X;     	
	}
    
  }
    
    lhs = matrix_cast<double>(final_X)/n_rows - 1.0/(2.0*n_rows);
}

double RationalApproximation(double t)
{
    double c[] = {2.515517, 0.802853, 0.010328};
    double d[] = {1.432788, 0.189269, 0.001308};
    return t - ((c[2]*t + c[1])*t + c[0]) / 
               (((d[2]*t + d[1])*t + d[0])*t + 1.0);
}

double NormCDFinverse(double p)
{
    if (p < 0.5)
      return -RationalApproximation( sqrt(-2.0*log(p)) );
    else
      return RationalApproximation( sqrt(-2.0*log(1-p)) );
}


void insertDraws(const matrix<double, n_betas, n_betas> &chol_covar, const matrix<double, n_betas, 1> b_optim) 
{ 
	matrix <double, n_draws, n_betas> lhs; 
	
	std::ifstream input("lhs_" + to_string(n_draws) + "_" + to_string(n_betas) + ".txt"); 	
	if (input) {
	  // The file exists, and is open for input	
      for (int i=0; i<n_draws; i++)
        for (int j=0; j<n_betas; j++)
          input >> lhs(i,j); 	  	
	} else { 
	  createLHS(lhs); 
      for (int i=0;i<n_draws;i++)
        for (int j=0;j<n_betas;j++)
          lhs(i,j) = NormCDFinverse(lhs(i,j));
      std::ofstream output ("lhs_" + to_string(n_draws) + "_" + to_string(n_betas) + ".txt"); 
      for (int i=0; i<n_draws; i++){
        for (int j=0; j<n_betas; j++)
          output << lhs(i,j) << " ";
		output << "\n"; 
      }
      output.close();
	} 	
	
    matrix <double> betas = lhs * chol_covar;
    for (int i = 0; i < n_draws; i++ )
      for (int j = 0; j < n_betas; j++)
   	    betas(i,j) += b_optim(j);
	for (int i = 0; i < n_draws; i++ )
      draw[i].beta = rowm(betas,i);
}



void FullEval_Pairwise(matrix<double, n_rowsX,n_betas> &X, double &efficiency)
{
    #pragma omp parallel for schedule(static) num_threads(THREADS)
    for (int d=0; d<n_draws; d++){

     for (int t=0; t<n_tasks; t++){	
      double expV   = exp( dot(draw[d].beta, rowm(X,t)) );      
      double P      = expV / (1+expV);
      double PP     = P * (1-P);

	  for (int i=0; i<n_betas; i++){ 
	   draw[d].trX_Z(i,t) = X(t,i) * PP; 
     }}

	 draw[d].Fisher=0.0;   	 
	 for (int j=0; j<n_betas; j++){
      for (int i=0; i<n_betas; i++){
	   if (i==j) draw[d].Fisher(i,j) += 0.0000001;
       for (int t=0; t<n_tasks; t++){	
        draw[d].Fisher(i,j) += draw[d].trX_Z(i,t) * X(t,j);
	 }}}

	 draw[d].D_eff= pow( det(draw[d].Fisher) , (-1.0/n_betas ) );
	}
	
    efficiency = draw[0].D_eff;
	for (int d=1; d<n_draws; d++) {
	  efficiency += draw[d].D_eff;
    } 
	efficiency /= n_draws;
}




void FullEval_General(matrix<double, n_rowsX,n_betas> &X, double &efficiency)
{
    #pragma omp parallel for schedule(static) num_threads(THREADS)
    for (int d=0; d<n_draws; d++){

      matrix <double, n_rowsXtask,1>           expV;
      double                                   sumExpV;
      matrix <double, n_rowsXtask,1>           P;
      matrix <double, n_rowsXtask,n_rowsXtask> PP;

      for (int t=0; t<n_tasks; t++){	
       double sum = 0.0;       
       for (int tt=0; tt<n_rowsXtask; tt++){
         expV(tt) = exp( dot(draw[d].beta, rowm(X, t*n_rowsXtask + tt)) );            	
       	 sum += expV(tt);
	   }
	   sumExpV = sum + 1;

       for (int tt=0; tt<n_rowsXtask; tt++){
         P(tt)  = expV(tt) / sumExpV;
       }	

       for (int tt=0; tt<n_rowsXtask; tt++){
	     for (int col=0; col<n_rowsXtask; col++){
	       if (tt==col)
		     PP(tt,col) = P(tt)*(1-P(tt));		     
		   else {		   
		     PP(tt,col) = -P(tt)*P(col);
		     PP(col,tt) =  PP(tt,col);
	   }}}

	   int beg_rowX = t*n_rowsXtask;  
	   int end_rowX = beg_rowX + n_rowsXtask-1;  
	   for (int tt=0; tt<n_rowsXtask; tt++){
	     matrix<double,1,n_rowsXtask> rowPP=rowm(PP,tt);
	     for (int b=0; b< n_betas; b++){	
	       matrix<double,n_rowsXtask,1> colX=subm(X, range(beg_rowX,end_rowX), range(b,b));
	       draw[d].trX_Z(b, beg_rowX + tt) = dot( rowPP , colX );
	   }}}
       
	   draw[d].Fisher=0.0;   
	   for (int i=0; i<n_betas; i++){
	    for (int j=0; j<n_betas; j++){
	     if (i==j) draw[d].Fisher(i,j) += 0.0000001;
         for (int k=0; k<n_rowsX; k++){	
          draw[d].Fisher(i,j) += draw[d].trX_Z(i,k) * X(k,j);
	   }}}
	   draw[d].D_eff= pow( det(draw[d].Fisher) , (-1.0/n_betas ) );
   }
   efficiency = draw[0].D_eff;
   for (int d=1; d<n_draws; d++)
      efficiency += draw[d].D_eff;
   efficiency /= n_draws; 	
}





void PartialEval_Pairwise(matrix<double, n_rowsX,n_betas> &X, double &efficiency, int taskNr, const matrix<double,n_betas,1> &newTask )
{
    #pragma omp parallel for schedule(static) num_threads(THREADS)
    for (int d=0; d<n_draws; d++){
    
      double expV   = exp( dot(draw[d].beta, newTask) );      
      double P      = expV / (1+expV);
      double PP     = P * (1-P);

	  for (int i=0; i<n_betas; i++){ 
 	    draw[d].newTrX_Z(i,1) = newTask(i) * PP; 
      }
     
      for (int j=0; j<n_betas; j++){
       for (int i=0; i<n_betas; i++){
         draw[d].newFisher(j,i) = draw[d].Fisher(j,i) 
                                - draw[d].trX_Z(i,taskNr) * X(taskNr,j) 
                                + draw[d].newTrX_Z(i,1) * newTask(j);      
      }}

	  draw[d].newD_eff= pow( det(draw[d].newFisher) , (-1.0/n_betas ) );
    }
	
    double newEfficiency = draw[0].newD_eff;
	for (int d=1; d<n_draws; d++) {
	  newEfficiency += draw[d].newD_eff;
    } 
	newEfficiency /= n_draws;
    
   if (newEfficiency < efficiency) {
      efficiency = newEfficiency; 
      set_rowm(X,taskNr) = newTask;

      for (int d=0; d<n_draws; d++){      
        set_colm( draw[d].trX_Z,taskNr) = draw[d].newTrX_Z;        
        draw[d].Fisher                  = draw[d].newFisher;
    }}   
}





void partialEval_General(matrix<double, n_rowsX,n_betas> &X, double &efficiency, int taskNr, const matrix<double,n_rowsXtask,n_betas> &newTask )
{
    #pragma omp parallel for schedule(static) num_threads(THREADS)
    for (int d=0; d<n_draws; d++){

      matrix <double, n_rowsXtask,1>           expV;
      double                                   sumExpV;
      matrix <double, n_rowsXtask,1>           P;
      matrix <double, n_rowsXtask,n_rowsXtask> PP;

      double sum = 0.0;       
      for (int tt=0; tt<n_rowsXtask; tt++){
        expV(tt) = exp( dot(draw[d].beta, rowm(newTask, tt)) );            	
        sum += expV(tt);
	  }
	   
	   sumExpV = sum + 1;
       for (int tt=0; tt<n_rowsXtask; tt++){
         P(tt)  = expV(tt) / sumExpV;
       }
           
       for (int tt=0; tt<n_rowsXtask; tt++){
	     for (int col=0; col<n_rowsXtask; col++){
	       if (tt==col)
		     PP(tt,col) = P(tt)*(1-P(tt));		     
		   else {		   
		     PP(tt,col) = -P(tt)*P(col);
		     PP(col,tt) =  PP(tt,col);
	   }}}

	   for (int tt=0; tt<n_rowsXtask; tt++){
	     matrix<double,1,n_rowsXtask> rowPP=rowm(PP,tt);
	     for (int b=0; b< n_betas; b++){
	       draw[d].newTrX_Z(b, tt) = dot( rowPP , colm(newTask,b) );
	   }}

      draw[d].newFisher=draw[d].Fisher;
      for (int j=0; j<n_betas; j++){
       for (int i=0; i<n_betas; i++){
         for (int tt=0; tt<n_rowsXtask; tt++){
		  int row = taskNr*n_rowsXtask + tt;	
          draw[d].newFisher(j,i) =   draw[d].newFisher(j,i) 
		                           - draw[d].trX_Z(i,row) * X(row,j)
								   + draw[d].newTrX_Z(i,tt)*newTask(tt,j);
	   }}}

	   draw[d].newD_eff= pow( det(draw[d].newFisher) , (-1.0/n_betas ) );
   }
	
   double newEfficiency = draw[0].newD_eff;
   for (int d=1; d<n_draws; d++) {
      newEfficiency += draw[d].newD_eff;
   } 
   newEfficiency /= n_draws; 	
   
   if (newEfficiency < efficiency) {
      efficiency = newEfficiency;  
      
      int beg_row = taskNr*n_rowsXtask;	
      int end_row = taskNr*n_rowsXtask + n_rowsXtask-1;
      set_rowm(X,range(beg_row,end_row)) = newTask;

      for (int d=0; d<n_draws; d++){      
        set_colm( draw[d].trX_Z,range(beg_row,end_row)) = draw[d].newTrX_Z;        
        draw[d].Fisher                                  = draw[d].newFisher;
   }}     
}




void optimizeDesign_General( matrix<double, n_rowsX,n_betas>  &X,
                             matrix<int, n_tasks, n_attr>     &X_overlap,
                             const int                         n_observed, 
							 const matrix<int, n_attr,1>      &beg_col , 
							 const matrix<int, n_attr,1>      &end_col)
{   
   int rand_attr1, rand_attr2;
   int beg_row, end_row, c_beg_row, cc_beg_row, c_end_row, cc_end_row;
   int required_overlap, selected_overlap, total_overlap;
   double efficiency, old_efficiency;
   matrix <double> newTask(n_rowsXtask,n_betas);
    
   std::random_device rnd;
   std::mt19937 generator(rnd()); 
   std::uniform_int_distribution<int> first_rand_int(0,n_attr-1);
   std::uniform_int_distribution<int> second_rand_int(0,n_attr-2);
   std::chrono::time_point<std::chrono::system_clock> startTime;
   std::chrono::duration<double> diffTime;
   typedef std::chrono::system_clock Time;
   
   FullEval_General(X, efficiency);
   startTime = Time::now();
   do{ 
 
     for(int t=n_observed; t<n_tasks; t++){

       rand_attr1 = first_rand_int(generator);
       rand_attr2 = second_rand_int(generator);
       if (rand_attr1==rand_attr2) rand_attr2++;

       selected_overlap = X_overlap(t,rand_attr1) + X_overlap(t,rand_attr2);	   	  
       total_overlap = 0;
 	   for (int i=0; i<n_attr; i++)
         total_overlap += X_overlap(t,i);  
 	   required_overlap = n_overlap - (total_overlap - selected_overlap);

 	   if (required_overlap == 0){

	       beg_row = t*n_rowsXtask;	
           end_row = beg_row + n_rowsXtask-1;    
           newTask = rowm(X,range(beg_row,end_row));

		   for (int c=0; c<n_candidates; c++){
		     c_beg_row = c*n_rowsXtask;
		     c_end_row = c_beg_row + n_rowsXtask-1; 	
             set_colm(newTask, range( beg_col(rand_attr1),end_col(rand_attr1) )) = rowm(candidates,range(c_beg_row, c_end_row)); 

			 for (int cc=0; cc<n_candidates; cc++){
		       cc_beg_row = cc*n_rowsXtask;
		       cc_end_row = cc_beg_row + n_rowsXtask-1;
		       set_colm(newTask, range( beg_col(rand_attr2),end_col(rand_attr2) )) = rowm(candidates,range(cc_beg_row, cc_end_row));

 	  	       partialEval_General(X, efficiency, t, newTask );
 	       }}
 	       	      
	   } else if (required_overlap == 1){

	       beg_row = t*n_rowsXtask;	
           end_row = beg_row + n_rowsXtask-1;    
           newTask = rowm(X,range(beg_row,end_row));
           old_efficiency = efficiency;

           set_colm(newTask, range( beg_col(rand_attr1),end_col(rand_attr1) )) = 0;   
		   for (int c=0; c<n_candidates; c++){
		     c_beg_row = c*n_rowsXtask;
		     c_end_row = c_beg_row + n_rowsXtask-1;
		     set_colm(newTask, range( beg_col(rand_attr2),end_col(rand_attr2) )) = rowm(candidates,range(c_beg_row, c_end_row));

 	  	     partialEval_General(X, efficiency, t, newTask );
 	       }	

		   if (efficiency < old_efficiency){
		     X_overlap(t,rand_attr1) = 1;   
		     X_overlap(t,rand_attr2) = 0;   
		   	 old_efficiency = efficiency;
	       }

           set_colm(newTask, range( beg_col(rand_attr2),end_col(rand_attr2) )) = 0;
		   for (int c=0; c<n_candidates; c++){
		     c_beg_row = c*n_rowsXtask;
		     c_end_row = c_beg_row + n_rowsXtask-1;
		     set_colm(newTask, range( beg_col(rand_attr1),end_col(rand_attr1) )) = rowm(candidates,range(c_beg_row, c_end_row));

 	  	     partialEval_General(X, efficiency, t, newTask );
 	       } 			 

		   if (efficiency < old_efficiency){
		     X_overlap(t,rand_attr1) = 0;
		     X_overlap(t,rand_attr2) = 1;		     
	       } 

	   } else if (required_overlap >= 2 && selected_overlap==2){
           // do nothing
       } else if (required_overlap >= 2 && selected_overlap<2){

           int beg_row = t*n_rowsXtask;	
           int end_row = t*n_rowsXtask + n_rowsXtask-1;        
           set_subm(X,range(beg_row,end_row), range( beg_col(rand_attr1),end_col(rand_attr1) )) = 0; 	    
 	       set_subm(X,range(beg_row,end_row), range( beg_col(rand_attr2),end_col(rand_attr2) )) = 0; 
	       X_overlap(t,rand_attr1) = 1;   
	       X_overlap(t,rand_attr2) = 1;   	 
 	       FullEval_General(X, efficiency);
     }}
	
     diffTime = Time::now() - startTime;
    
   } while (diffTime.count()<2);
	 
} 

void sortDesign_General(matrix<double, n_rowsX,n_betas>  &X, const int n_observed) 
{
   double efficiency, new_efficiency; 

      #pragma omp parallel for schedule(static) num_threads(THREADS)
      for (int d=0; d<n_draws; d++){	

	     draw[d].Fisher=0.0;   
	     for (int i=0; i<n_betas; i++){
	       for (int j=0; j<n_betas; j++){
	         if (i==j) draw[d].Fisher(i,j) += 0.0000001;
             for (int k=0; k<(n_observed+1)*n_rowsXtask; k++){	
               draw[d].Fisher(i,j) += draw[d].trX_Z(i,k) * X(k,j);
	    }}}
	    draw[d].D_eff= pow( det(draw[d].Fisher) , (-1.0/n_betas ) );
      }

      efficiency = draw[0].D_eff;
      for (int d=1; d<n_draws; d++) 
         efficiency += draw[d].D_eff;
      efficiency /= n_draws; 	

      #pragma omp parallel for schedule(static) num_threads(THREADS)
      for (int d=0; d<n_draws; d++){	
	     for (int i=0; i<n_betas; i++){
	       for (int j=0; j<n_betas; j++){
             for (int k=n_observed*n_rowsXtask; k<(n_observed+1)*n_rowsXtask; k++){	
               draw[d].Fisher(j,i) -= draw[d].trX_Z(i,k) * X(k,j);
      }}}}
	
	  for (int n= n_observed+1; n<n_tasks;  n++){

        #pragma omp parallel for schedule(static) num_threads(THREADS)
        for (int d=0; d<n_draws; d++){	
	       draw[d].newFisher=draw[d].Fisher;
	       for (int i=0; i<n_betas; i++){
	         for (int j=0; j<n_betas; j++){
               for (int k=n*n_rowsXtask; k<(n+1)*n_rowsXtask; k++){
                 draw[d].newFisher(j,i) += draw[d].trX_Z(i,k) * X(k,j);
					       			    
	       }}}
	       draw[d].newD_eff= pow( det(draw[d].newFisher) , (-1.0/n_betas ) );
	    }

        new_efficiency = draw[0].newD_eff;
        for (int d=1; d<n_draws; d++) 
           new_efficiency += draw[d].newD_eff;
        new_efficiency /= n_draws; 
	  		
  	    if (new_efficiency < efficiency){
  	  	  int beg_row1 = n_observed * n_rowsXtask;	
          int end_row1 = beg_row1 + n_rowsXtask -1;
  	      int beg_row2 = n * n_rowsXtask;
  	      int end_row2 = beg_row2 + n_rowsXtask -1; 
  	      matrix <double> copyTask = rowm(X,range(beg_row1,end_row1));
  	      set_rowm(X,range(beg_row1,end_row1)) = rowm(X,range(beg_row2,end_row2));
          set_rowm(X,range(beg_row2,end_row2)) = copyTask; 
	    } 	  
      } 	  
}




void X2design( const matrix<double> &X, 
               matrix<double, n_rowsD, n_attr> &design, 
			   const matrix<int, n_attr,1> &beg_col , 
			   const matrix<int, n_attr,1> &end_col, 
			   const int n_observed)
{
   bool has_value[n_alts];
   bool requires_random_level, has_minus_one;
   int row1_design, row2_design, row_X, xValue;
   
   for (int t=n_observed; t<n_tasks; t++){ 
     row1_design = t*n_alts;
       
	 for (int i = 0; i<n_attr; i++){	
       for (int j=0; j<n_alts; j++)
	     has_value[j] = false;
	   requires_random_level=true;
       for (int n=1; n<=n_rowsXtask; n++){
         row2_design = row1_design + n; 
         row_X = t*n_rowsXtask + n-1;
		         
	 	 xValue = n_levels[i];
	     
		   has_minus_one=false;  
	       for (int j=end_col(i); j>= beg_col(i); j--){
	         if (X(row_X,j)==1) {	   
			   has_value[n]=true; 
	           requires_random_level=false;
	           design(row2_design,i)=xValue;
             } 
	         else if (X(row_X,j)==-1){
	           has_value[0]=true; 
			   has_minus_one=true;	
	           requires_random_level=false;
	           design(row1_design,i)=xValue;
	         }	 
	         xValue--; 
	       }
	       if (has_minus_one && has_value[n]==false){
	       	 has_value[n]=true;
	       	 design(row2_design,i)=1;
		   }
	       
       }
    
	   if (requires_random_level){
          int rand_int = floor(1 + n_levels[i] * rnd());
		  for (int n=0; n<n_alts; n++)
            design(row1_design+n,i) = rand_int; 
	     
	   } else {
	      if (has_value[0] == false)
	        design(row1_design,i)=1; 	
		  for (int n=1; n<=n_rowsXtask; n++){
		  	if (has_value[n] == false)
               design(row1_design+n,i) = design(row1_design,i);	
          }
			        
   }}}    
}



void beta2str(const matrix <double, n_betas, 1> &b_optim, string &output)
{
	string output2;
		for (int n=0; n<n_betas; n++){
                std::ostringstream strs;
				strs << b_optim(n);
				output2 += strs.str();
				if (n != n_betas - 1)
					output2 += ",";
	    }
	output=output2;
}



void design2str(const matrix <double, n_rowsD,n_attr> &design, const int n_observed, string &output)
{
        string output2;
		for (int row=n_observed*n_alts; row<n_rowsD; row++) 
		   for (int col= 0; col< n_attr; col++){
		 		std::ostringstream strs;
				strs << design(row, col);
				output2 += strs.str();
		   }
        output=output2;
}






void cppAdaptive(const string &obsVector, string &futVector, string &betaVector, const int n_observed)
{
  matrix <double, n_betas, 1>                b_optim;                                        
  matrix <double, n_rowsD, n_attr>           design;                                         
  matrix <int   , n_tasks, n_attr>           X_overlap;                                     
  matrix <double, n_rowsX,n_betas>           X;                                              
  matrix <double>                            X_likelihood(n_observed*n_rowsXtask , n_betas); 
  matrix <double, n_betas, n_betas>          chol_covar;                                    
    
  matrix <int, n_attr,1>                     beg_col;                                       
  matrix <int, n_attr,1>                     end_col;      
  double postLa;

  // process inputs 
  str2beta(betaVector, b_optim);                                                             
  str2design( (obsVector + futVector), design);                                              
  design2X(design, X_overlap, X, X_likelihood, n_observed, beg_col, end_col);                
  calculatePosterior(b_optim, n_observed, X_likelihood, chol_covar);
  insertDraws(chol_covar, b_optim); 

  // optimize all future tasks for 2 seconds 
  optimizeDesign_General(X, X_overlap, n_observed, beg_col, end_col); 

  // determine task with highest sequential efficiency
  if (n_tasks -n_observed >1){
    sortDesign_General(X,n_observed);  
  }
        
  // return sorted strings
  X2design(X, design, beg_col, end_col, n_observed);  
  design2str(design, n_observed, futVector);  
  beta2str(b_optim, betaVector);
}




int main()
{
  // THIS IS AN EXAMPLE DRIVER PROGRAM FOR CPPADAPTIVE 
  	
  // input 
  string obsVector  = "313312221112123223322132223313312131221123212113221111213232";
  string futVector  = "323133332131332223321221232122221331123313333213311113231233333322133312331123322211232222212312131221133121232212232111233332223221131132112121332212123211313111211"; 
  string betaVector = "-0.26425,0.648666,-0.0565359,-0.373203,-0.107654,0.228433,-0.339707,0.663967,0.0600106,0.0828479";
  int n_observed = 4;
  
  cppAdaptive(obsVector, futVector, betaVector, n_observed);

  cout << "betaVector: \n" << betaVector << endl;
  cout << "futVector: \n" << futVector << endl;

  return 0;
}
