/* EM algorithm 
 * Variants for trio families added
 */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

/*
 * Data types for possibilities and probabilities.
 * This is not OK for haplotype reconstruction,
 * where E and M step are slightly different.
 * So we need to write variants...
 */

#define pos_t  unsigned long   /* This could be changed to any INTEGER TYPE*/
			       /* the fact that it is an integer is really used. */
#define prob_t double

double ylogx(double x, double y)
{
  if(x == 0 && y != 0)
  {
    printf("ylogx error %e, %e\n", x, y);
  }
  if(x == 0)
    return 0;
  return y*log(x);
}


/* renormalize a list of n probabilities
 * such that their sum == 1 (at least, tries to...)
 * if the probas sum to 0, does nothing.
 * does not check whether some probas are < 0...
 */

void renormalize(prob_t * proba, pos_t n)
{
  prob_t sum = 0;
  pos_t i;
  for(i=0; i<n; i++)
  {
    sum += proba[i];
  }
  if(sum == 0)
  {
    return;
  }
  for(i=0; i<n; i++)
  {
    proba[i] /= sum;
  }

}

struct UNIT
{
  pos_t n;          // n possibilities for this unit
  pos_t * pos;      // table of n possibilities  (length can be n, 2n, 8n...)
  prob_t * prob;    // table of n probabilities 
};

struct DATA
{
  unsigned int M;   // M units (individuals or trios)
  struct UNIT * I;  // table of M struct UNIT;
  pos_t N;          // length of following table (eg probabilities of haplotypes)
  prob_t * prob;    // table of N probabilities
  pos_t N2;         // length of following table
  prob_t * prob2;   // other table (eg N2 = N**2 possibilities, for models without HW assumption !)
};                  

/* Set all probas below a given threshold (eg, 1e-10) to 0
 */

void cut_at_threshold(struct DATA * d, prob_t th)
{
  pos_t i;
  for(i=0; i<d->N; i++)
  {
    if(d->prob[i] < th)
    {
      d->prob[i] = 0;
    }
  }
}

void cut_at_threshold2(struct DATA * d, prob_t th)
{
  pos_t i;
  for(i=0; i<d->N2; i++)
  {
    if(d->prob2[i] < th)
    {
      d->prob2[i] = 0;
    }
  }
}

/* creates a unit of n possibilities */ 
struct UNIT new_unit(pos_t n)
{
  struct UNIT u;
  u.n    = n;
  if(n == 0)
  {
    u.pos = (pos_t *) NULL; 
    u.prob = (prob_t *) NULL;
    return u;
  }

  u.pos  = (pos_t *) malloc(n*sizeof(pos_t));
  u.prob = (prob_t *) malloc(n*sizeof(prob_t));
  if(u.prob == NULL || u.pos == NULL) // who knoes
  {
    fputs("Out of Memory\n", stderr);
    exit(1);
  }
  return u;
}
/* creates a data set */
/*struct DATA new_data(unsigned int M)
{
  struct DATA d;
  unsigned long i;
  printf("** M = %d\n", M);
  d.N = 0;
  d.M = M;
  d.I     = (struct UNIT *) malloc(M*sizeof(struct UNIT));
  d.prob  = NULL; 
  for(i=0; i<M; i++)
  {
    d.I[i] = new_unit(0);
  }
  return d;
}
*/

/* deletes a unit, or more precisely frees the memory */
void del_unit(struct UNIT * u)
{
  if(u->n == 0)
  { 
    return;
  }
  free(u->pos);
  free(u->prob);
  u->n = 0;
}

/* deletes a data set, [frees the memory] */
void del_data(struct DATA * d)
{
  unsigned long i;
  for(i=0; i<d->M; i++)
  {
    del_unit(d->I+i);
  }
  free(d->I);
  free(d->prob);
  free(d->prob2);
  d->N2 = d->N = d->M = 0;
}

/* 
 * This step gives estimates of the probabilities
 * of the different possibilities, using the current
 * probabilities for each unit
 */

void M_step(struct DATA * data)
{
  pos_t i;
  unsigned int j, k;
  prob_t p, sum=0;

  for(i=0; i<data->N; i++) // loop on N possibilities : set to 0
  {
    data->prob[i] = 0;
  }
  for(j = 0; j<data->M; j++)
  {
    for(k = 0; k<(data->I+j)->n; k++)
    {
       data->prob[(data->I+j)->pos[k]] += (data->I+j)->prob[k];
    }
  }
  for(i=0; i<data->N; i++) // loop on N possibilities
  {
    sum += data->prob[i];
  }
  for(i=0; i<data->N; i++) // loop on N possibilities
  {
    data->prob[i] /= sum;
  }
}

/* This step uses the probabilities data->prob to
 * give probabilities for the possibilities of each unit. 
 */
void E_step(struct DATA * data)
{
  unsigned int i;
  pos_t j;
  prob_t sum;

  for(i = 0; i<data->M; i++) // loop on M units
  {
    sum = 0;
    for(j=0; j<data->I[i].n; j++) // loop on n possibilities for the current unit
    {
      sum += data->I[i].prob[j] = data->prob[data->I[i].pos[j]];
    }
    // renormalizes
    if(sum>0)
    {
      for(j=0; j<data->I[i].n; j++) // loop on n possibilities for the current unit
      {
        data->I[i].prob[j] /= sum;
      }
    }
  }
}

/* returns current pseudo likelihood value */

double Likelihood(struct DATA * data)
{
  pos_t i;
  unsigned int j,k;
  double L = 0;

  for(j = 0; j<data->M; j++)
  {
    for(k = 0; k<(data->I+j)->n; k++)
    {
       // printf("Individu %d, possibilité %d \n",j,k);
       L += ylogx( data->prob[(data->I+j)->pos[k]], (data->I+j)->prob[k]);
    }
  }
  return L;
}


/***********************************************************************************
 *
 * VARIANTS for HAPLOTYPES.
 * The big difference is that our table of probabilities is
 * the probability of haplotypes AMONG THE PARENTS 
 * and that UNITS will have n possible PAIRS of haplotypes.
 *
 * The data struct are the same except that now
 * if u is a UNIT, u.pos is a table of n PAIRS of haplotypes,
 *                 ie 2n haplotypes.
 *
 * !!! if (h1, h23) is a possibility, just list it once, don't repeat (h23,h1) !!!
 *
 ************************************************************************************/

/* creates a unit of n possibilities */ 
struct UNIT new_unit_h(pos_t n)
{
  struct UNIT u;
  u.n   = n;
  if(n == 0)
  {
    u.pos = (pos_t *) NULL; 
    u.prob = (prob_t *) NULL;
    return u;
  }

  u.pos  = (pos_t *) malloc(2*n*sizeof(pos_t));
  u.prob = (prob_t *) malloc(n*sizeof(prob_t));
  if(u.prob == NULL || u.pos == NULL) // who knoes
  {
    fputs("Out of Memory\n", stderr);
    exit(1);
  }
  return u;
}

/* 
 * This step gives estimates of the probabilities
 * of the different haplotypes, using the current
 * probabilities for each unit
 */

void M_step_h(struct DATA * data)
{
  pos_t i;
  unsigned int j,k,l;
  prob_t p, sum=0;;

  for(i=0; i<data->N; i++) // loop on N possibilities : set to 0
  {
    data->prob[i] = 0;
  }
  for(j = 0; j<data->M; j++)
  {
    for(k = 0; k<(data->I+j)->n; k++)
    {
       for(l=0; l<2; l++)
       { 
         data->prob[(data->I+j)->pos[2*k+l]] += (data->I+j)->prob[k];
       }
    }
  }
  // normalizes
  for(i=0; i<data->N; i++) // loop on N possibilities
  {
    sum += data->prob[i];
  }
  for(i=0; i<data->N; i++) // loop on N possibilities
  {
    data->prob[i] /= sum;
  }
}

/* This step uses the probabilities data->prob to
 * give probabilities for the possibilities of each unit. 
 */
void E_step_h(struct DATA * data)
{
  unsigned int i;
  pos_t j, X, Y;
  prob_t sum;
 
  for(i = 0; i<data->M; i++) // loop on M units
  {
    sum = 0;
    for(j=0; j<data->I[i].n; j++) // loop on n possibilities for the current unit
    {
      X = data->I[i].pos[2*j];    // j-th pair of haplotypes
      Y = data->I[i].pos[2*j+1];
      if( X == Y )
      {
        sum += data->I[i].prob[j] = data->prob[X]*data->prob[X];
      }
      else
      {
        sum += data->I[i].prob[j] = 2*data->prob[X]*data->prob[Y];
      }
    }
    // renormalizes
    if(sum>0)
    {
      for(j=0; j<data->I[i].n; j++) 
      {
        data->I[i].prob[j] /= sum;
      }
    }
  }
}

/* returns current pseudo likelihood value */

double Likelihood_h(struct DATA * data)
{
  pos_t i;
  unsigned int j,k,l;
  double L = 0;

  for(j = 0; j<data->M; j++)
  {
    for(k = 0; k<(data->I+j)->n; k++)
    {
       for(l=0; l<2; l++)
       { 
         L += ylogx( data->prob[(data->I+j)->pos[2*k+l]], (data->I+j)->prob[k]);
       }
    }
  }
  return L;
}

// IDEM for diplo model

void M_step_d(struct DATA * data)
{
  pos_t i,a,b;
  unsigned int j,k,l;
  prob_t p, sum=0;;

  for(i=0; i<data->N2; i++) // loop on N2 = N*N possibilities : set to 0
  {
    data->prob2[i] = 0;
  }
  for(j = 0; j<data->M; j++)
  {
    for(k = 0; k<(data->I+j)->n; k++)
    {
       a = (data->I+j)->pos[2*k];
       b = (data->I+j)->pos[2*k+1];
       data->prob2[a*data->N + b] += (data->I+j)->prob[k];
       if(a != b)
       {
         data->prob2[b*data->N + a] += (data->I+j)->prob[k];  // la table est symétrique
       }
    }
  }
  // normalizes
  for(i=0; i<data->N2; i++) 
  {
    sum += data->prob2[i];
  }
  for(i=0; i<data->N2; i++)
  {
    data->prob2[i] /= sum;
  }
}
  
// Met à jour la table des fréquences haplotypiques
// A partir des freq diplotypiques
void freqhap_d(struct DATA * data)
{
  pos_t i,a,b;
  unsigned int j,k,l;
  for(i=0; i<data->N; i++)
  {
    data->prob[i] = 0;
    for(j=0; j<data->N; j++)
    {
      data->prob[i] += data->prob2[i*data->N + j];
    }
  }
}


 
/* This step uses the probabilities data->prob2 to
 * give probabilities for the possibilities of each unit. 
 */
void E_step_d(struct DATA * data)
{
  unsigned int i;
  pos_t j, X, Y;
  prob_t sum;

  for(i = 0; i<data->M; i++) // loop on M units
  {
    sum = 0;
    for(j=0; j<data->I[i].n; j++) // loop on n possibilities for the current unit
    {
      X = data->I[i].pos[2*j];    // j-th pair of haplotypes
      Y = data->I[i].pos[2*j+1];
      sum += data->I[i].prob[j] = data->prob2[X*data->N + Y];
    }
    // renormalizes
    if(sum>0)
    {
      for(j=0; j<data->I[i].n; j++) 
      {
        data->I[i].prob[j] /= sum;
      }
    }
  }
}

/* returns current pseudo likelihood value */

double Likelihood_d(struct DATA * data)
{
  pos_t i, a, b;
  unsigned int j,k,l;
  double L = 0;

  for(j = 0; j<data->M; j++)
  {
    for(k = 0; k<(data->I+j)->n; k++)
    {
       a = (data->I+j)->pos[2*k];
       b = (data->I+j)->pos[2*k+1];
       L += ylogx(data->prob2[a*data->N + b], (data->I+j)->prob[k]);
    }
  }
  return L;
}

/***********************************************************************************
 *
 * VARIANTS for TRIO [HAPLOTYPES].
 * This time, the table of probabilities is again the probability of each haplotype, 
 * and UNITS are n possible 8-UPLES of haplotypes 
 * father1, father2, mother1 and 2, offspring1 and 2, internalcontrol1 and 2
 * The data struct are the same except that now
 * if u is a UNIT, u.pos is a table of n 8 UPLES of haplotypes 
 *                 --> length = 8n 
 *
 * Sous H0 on n'utilise que les 4 premiers haplotypes.
 * -->On prévoit d'utiliser les 4 derniers (sous H1) sans avoir à créer une
 *  structure différente.
 ************************************************************************************/

/* creates a unit of n possibilities */ 
struct UNIT new_unit_t(pos_t n)
{
  struct UNIT u;
  u.n   = n;
  if(n == 0)
  {
    u.pos  = (pos_t *) NULL; 
    u.prob = (prob_t *) NULL;
    return u;
  }

  u.pos  = (pos_t *) malloc(8*n*sizeof(pos_t));
  u.prob = (prob_t *) malloc(n*sizeof(prob_t));
  if(u.prob == NULL || u.pos == NULL ) // who knoes
  {
    fputs("Out of Memory\n", stderr);
    exit(1);
  }
  return u;
}

/* 
 * This step gives estimates of the probabilities
 * of the different haplotypes, using the current
 * probabilities for each unit
 *
 * Toujours sous H0 : on ne prend en compte que les parents
 */

void M_step_t(struct DATA * data)
{
  pos_t i;
  unsigned int j,k,l;
  prob_t p, sum=0;;

  for(i=0; i<data->N; i++) // loop on N possibilities : set to 0
  {
    data->prob[i] = 0;
  }
  for(j = 0; j<data->M; j++)
  {
    for(k = 0; k<(data->I+j)->n; k++)
    {
       for(l=0; l<4; l++)
       { 
         data->prob[(data->I+j)->pos[8*k+l]] += (data->I+j)->prob[k];
       }
    }
  }
  // normalizes
  for(i=0; i<data->N; i++) // loop on N possibilities
  {
    sum += data->prob[i];
  }
  for(i=0; i<data->N; i++) // loop on N possibilities
  {
    data->prob[i] /= sum;
  }
}


/*
 * returns the current value of the (pseudo) likelihood
 * (toujours sous H0)
 */
double Likelihood_t(struct DATA * data)
{
  pos_t i;
  unsigned int j,k,l;
  double L = 0;

  for(j = 0; j<data->M; j++)
  {
    for(k = 0; k<(data->I+j)->n; k++)
    {
       for(l=0; l<4; l++)
       { 
         L += ylogx( data->prob[(data->I+j)->pos[8*k+l]], (data->I+j)->prob[k]);
       }
    }
  }
  return L;
}

/* This step uses the probabilities data->prob to
 * give probabilities for the possibilities of each unit. 
 * Toujours sous H0 !!
 */
void E_step_t(struct DATA * data)
{
  unsigned int i;
  pos_t j, k, X, Y, Z, T, d;
  prob_t p, sum;

  for(i = 0; i<data->M; i++) // loop on M units
  {
    sum = 0;
    for(j=0; j<data->I[i].n; j++) // loop on n possibilities for the current unit
    {
      p = 1;
      for(k=0; k<4; k++)
      {
	p *= data->prob[data->I[i].pos[8*j+k]];
      }
      sum += data->I[i].prob[j] = p;
    }
    // renormalizes
    if(sum>0)
    {
      for(j=0; j<data->I[i].n; j++) 
      {
        data->I[i].prob[j] /= sum;
      }
    }
  }
}

/********************************
 * Et maintenant sous un modèle du genre H1 (modèle de Pascal...)
 * reconstruction haplotypique sans supposer HW chez les cas... !!
 */

void M_step_thd(struct DATA * data)
{
  pos_t i, f1, f2, c1, c2;
  unsigned int j,k,l;
  prob_t p, sum=0;;

  for(i=0; i<data->N; i++) // loop on N possibilities : set to 0
  {
    data->prob[i] = 0;
  }
  for(i=0; i<data->N2; i++) // loop on N2 possibilities : set to 0
  {
    data->prob2[i] = 0;
  }

  for(j = 0; j<data->M; j++)
  {
    for(k = 0; k<(data->I+j)->n; k++)
    { 
      f1 = (data->I+j)->pos[8*k+4];
      f2 = (data->I+j)->pos[8*k+5];
      c1 = (data->I+j)->pos[8*k+6];
      c2 = (data->I+j)->pos[8*k+7];
      data->prob[c1] += (data->I+j)->prob[k];
      data->prob[c2] += (data->I+j)->prob[k];
      data->prob2[f1*data->N + f2] += (data->I+j)->prob[k];
      if(f1 != f2) 
	data->prob2[f2*data->N + f1] += (data->I+j)->prob[k];
    }
  }
  // normalizes
  for(i=0; i<data->N; i++) // loop on N possibilities
  {
    sum += data->prob[i];
  }
  for(i=0; i<data->N; i++) // loop on N possibilities
  {
    data->prob[i] /= sum;
  }

  sum = 0;
  for(i=0; i<data->N2; i++) // loop on N possibilities
  {
    sum += data->prob2[i];
  }
  for(i=0; i<data->N2; i++) // loop on N possibilities
  {
    data->prob2[i] /= sum;
  }
}


/*
 * returns the current value of the (pseudo) likelihood
 * (toujours sous H0)
 */
double Likelihood_thd(struct DATA * data)
{
  pos_t i, f1, f2, c1, c2;
  unsigned int j,k,l;
  double L = 0;

  for(j = 0; j<data->M; j++)
  {
    for(k = 0; k<(data->I+j)->n; k++)
    {
      f1 = (data->I+j)->pos[8*k+4];
      f2 = (data->I+j)->pos[8*k+5];
      c1 = (data->I+j)->pos[8*k+6];
      c2 = (data->I+j)->pos[8*k+7];
      L += ylogx(data->prob[c1],(data->I+j)->prob[k]);
      L += ylogx(data->prob[c2],(data->I+j)->prob[k]);
      L += ylogx(data->prob2[f1*data->N + f2],(data->I+j)->prob[k]);
    }
  }
  return L;
}

/* This step uses the probabilities data->prob to
 * give probabilities for the possibilities of each unit. 
 * Toujours sous H0 !!
 */
void E_step_thd(struct DATA * data)
{
  unsigned int i;
  pos_t f1, f2, c1, c2, j, k, X, Y, Z, T, d;
  prob_t p, sum;

  for(i = 0; i<data->M; i++) // loop on M units
  {
    sum = 0;
    for(j=0; j<data->I[i].n; j++) // loop on n possibilities for the current unit
    {
      f1 = (data->I+i)->pos[8*j+4];
      f2 = (data->I+i)->pos[8*j+5];
      c1 = (data->I+i)->pos[8*j+6];
      c2 = (data->I+i)->pos[8*j+7];
      p  = data->prob[c1] * data->prob[c2] * data->prob2[f1*data->N + f2] ;
      sum += data->I[i].prob[j] = p;
    }
    // renormalizes
    if(sum>0)
    {
      for(j=0; j<data->I[i].n; j++) 
      {
        data->I[i].prob[j] /= sum;
      }
    }
  }
}


