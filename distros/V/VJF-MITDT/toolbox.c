#include <gsl/gsl_rng.h>
#include <gsl/gsl_randist.h>
#include <gsl/gsl_cdf.h>
#include "mi-tdt2.h"

/* randtool !!!! */

gsl_rng *A, *r;

uint get_devrandom(){
  uint res;
  FILE *devrand=fopen("/dev/random", "r");

  if(devrand==NULL){
    fputs("Can't open /dev/random/.\n", stderr);
    return 0;
  }
  fread(&res, sizeof(res), 1, devrand);
  fclose(devrand);
  return res;
}

void initial(){

  uint seed;
 
  A=gsl_rng_alloc(gsl_rng_mt19937);
  r=gsl_rng_alloc(gsl_rng_mt19937);
  seed=get_devrandom();
//  printf("seed : %u\n", seed);
  gsl_rng_set(A, seed);
  seed=get_devrandom();
  gsl_rng_set(r, seed);
  return;
}

void free_gsl_var(){
  gsl_rng_free (r);
  gsl_rng_free (A);
  return;
}

/***********************************************************************************/
/************Cette fonction calcule les frequence cumulee a partir des *************/
/***********************frequences de chaque configuration**************************/
/***********************************************************************************/
void make_freq_cum(struct DATA1 * cfile)
{
  entier i, j;
  
  for(i=0; i<cfile->n_fam; i++){
    for(j=1; j<((cfile->fam[i]).nb_conf); j++){
      (cfile->fam[i]).proba[j]+=(cfile->fam[i]).proba[j-1];
    }
  }
  return;
}


/***********************************************************************************/
/*******Cette fonction complete la structure fam_imput a partir de fam**************/
/***********************************************************************************/

void make_imput(struct DATA1 * cfile, struct DATA1 * ifile)
{
  entier i, j;
  flottant alea;
  
  for(i=0; i<cfile->n_fam; i++){
    j=0;
    alea=gsl_rng_uniform(A); 
    while(alea > ((cfile->fam[i]).proba[j]))
      j++;
   
    (ifile->fam[i]).NT[0]=(cfile->fam[i]).NT[(j*2)];
    (ifile->fam[i]).NT[1]=(cfile->fam[i]).NT[(j*2)+1];
    (ifile->fam[i]).T[0]=(cfile->fam[i]).T[(j*2)];
    (ifile->fam[i]).T[1]=(cfile->fam[i]).T[(j*2)+1];
  }
  return;
}

/***********************************************************************************/
/*****************Initialisation des vecteur prob_nt_hap et prob_t_gen**************/
/***********************************************************************************/
void init_tab(struct DATA1 * cfile)
{
  memset( (void *) cfile->prob_t_gen,  0, (cfile->n_hap)*(cfile->n_hap)*sizeof(flottant) );
  memset( (void *) cfile->prob_nt_hap, 0, (cfile->n_hap)*sizeof(flottant) );
  return;
}

/***********************************************************************************/
/*********************cette fonction compte les génotypes***************************/
/***********************************************************************************/
void compt_geno(struct DATA1 * cfile, struct DATA1 * ifile)
{
  entier i;
  entier h0, h1;
  for(i=0; i<cfile->n_fam; i++) 
    {
      h0 = (ifile->fam[i]).T[0];
      h1 = (ifile->fam[i]).T[1];
      if(h0 >= cfile->n_hap || h1 >= cfile->n_hap )
      {
        printf("Serious problem with hap numbers in compt_geno [%u] [%u]\n", h0,h1);
        exit(1); 
      }
      cfile->prob_t_gen[h0*(cfile->n_hap)+h1]++;
      if(h0 != h1)    // je me suis permis d'ajouter cette condition [rv]
	cfile->prob_t_gen[h1*(cfile->n_hap)+h0]++;
    }
  return;
}

/***********************************************************************************/
/*********************cette fonction compte les haplotypes NT **********************/
/***********************************************************************************/
void compt_untrans(struct DATA1 * cfile, struct DATA1 * ifile)
{
  entier i;
  entier h0, h1;
  
  for(i=0; i<cfile->n_fam; i++){
    h0=(ifile->fam[i]).NT[0];
    h1=(ifile->fam[i]).NT[1];
    cfile->prob_nt_hap[h0]++;
    cfile->prob_nt_hap[h1]++;
  }
  
  return;
}

/***********************************************************************************/
/****Cette fonction fait tourner la fonction r_gamma sur chaque case des tableaux***/
/*****************mat_geno et untrans auxquels on a ajoute alpha********************/
/***********************************************************************************/
void new_param(struct DATA1 * cfile, struct DATA1 * ifile, flottant alpha)
{
  entier i;
  
  for(i=0; i<(cfile->n_hap); i++)
    {
      cfile->prob_nt_hap[i]=gsl_ran_gamma(r,cfile->prob_nt_hap[i]+alpha,1.0);
    }
  
  for(i=0; i<(cfile->n_hap)*(cfile->n_hap); i++)
    {
       cfile->prob_t_gen[i]=gsl_ran_gamma(r,cfile->prob_t_gen[i]+alpha,1.0);
    }
  return;
}

/***********************************************************************************/
/******Après avoir normalise les tableaux mat_geno et untrans, on actualise les ****/
/****************probabilites a posteriori de chaque configuration******************/
/***********************************************************************************/
void new_posterior(struct DATA1 * cfile, struct DATA1 * ifile)
{
  entier i, j, h0, h1, g0, g1;
  flottant sum=0;
  
  for(i=0; i<cfile->n_hap; i++)
    {
      for(j=0; j<=i; j++)
	sum+=cfile->prob_t_gen[i*(cfile->n_hap)+j];
    }
  
  for(i=0; i<cfile->n_hap; i++){
    for(j=0; j<=i; j++){
      cfile->prob_t_gen[i*(cfile->n_hap)+j]/=sum;
      cfile->prob_t_gen[j*(cfile->n_hap)+i]=cfile->prob_t_gen[i*(cfile->n_hap)+j];
    }
  }
  
  sum=0;
  for(i=0; i<cfile->n_hap; i++)
    sum+=cfile->prob_nt_hap[i];
  for(i=0; i<cfile->n_hap; i++)
    cfile->prob_nt_hap[i]/=sum;

  sum=0;
  for(i=0; i<cfile->n_fam ;i++) 
  {
    for(j=0;j<(cfile->fam[i]).nb_conf;j++)
    {  
      g0 = (cfile->fam[i]).T[2*j];
      g1 = (cfile->fam[i]).T[2*j+1];

      (cfile->fam[i]).proba[j]=cfile->prob_t_gen[g0*(cfile->n_hap)+g1];
    
      h0 = (cfile->fam[i]).NT[2*j];
      h1 = (cfile->fam[i]).NT[2*j+1];

      (cfile->fam[i]).proba[j]*=cfile->prob_nt_hap[h0];
      (cfile->fam[i]).proba[j]*=cfile->prob_nt_hap[h1];
 
      sum+=(cfile->fam[i]).proba[j];
    }
    
    for(j=0;j<(cfile->fam[i]).nb_conf;j++)
      {
	(cfile->fam[i]).proba[j]/=sum;
      }
    sum=0;
  }
  return;
}



// LES MEMES FONCTIONS ADAPATÉES A LA RECONSTRUCTION SOUS H0
// La table prob_t_gen[] n'est plus utilisée ;
// on ne considère que des fréquences haplotypiques, les mêmes 
// pour T et NT. On les stocke dans prob_nt_hap[]

/***********************************************************************************/
/*****************Initialisation des vecteur prob_nt_hap et prob_t_gen**************/
/***********************************************************************************/
void init_tab_H0(struct DATA1 * cfile)
{
  memset( (void *) cfile->prob_nt_hap, 0, (cfile->n_hap)*sizeof(flottant) );
  return;
}

/***********************************************************************************/
/********************** cette fonction compte les haplotypes ***********************/
/***********************************************************************************/
void compt_hap_H0(struct DATA1 * cfile, struct DATA1 * ifile)
{
  entier i;
  entier h0, h1;
  
  for(i=0; i<cfile->n_fam; i++)
  {
    h0=(ifile->fam[i]).NT[0];
    h1=(ifile->fam[i]).NT[1];
    cfile->prob_nt_hap[h0]++;
    cfile->prob_nt_hap[h1]++;

    h0=(ifile->fam[i]).T[0];
    h1=(ifile->fam[i]).T[1];
    cfile->prob_nt_hap[h0]++;
    cfile->prob_nt_hap[h1]++;
  }
  return;
}

/***********************************************************************************/
/****Cette fonction fait tourner la fonction r_gamma sur chaque case des tableaux***/
/*****************mat_geno et untrans auxquels on a ajoute alpha********************/
/***********************************************************************************/
void new_param_H0(struct DATA1 * cfile, struct DATA1 * ifile, flottant alpha)
{
  entier i;
  for(i=0; i<(cfile->n_hap); i++)
    {
      cfile->prob_nt_hap[i]=gsl_ran_gamma(r,cfile->prob_nt_hap[i]+alpha,1.0);
    }
  return;
}

/***********************************************************************************/
/******Après avoir normalise les tableaux mat_geno et untrans, on actualise les ****/
/****************probabilites a posteriori de chaque configuration******************/
/***********************************************************************************/
void new_posterior_H0(struct DATA1 * cfile, struct DATA1 * ifile)
{
  entier i, j, h0, h1, g0, g1;
  flottant sum=0;
  
  for(i=0; i<cfile->n_hap; i++)
    sum+=cfile->prob_nt_hap[i];
  for(i=0; i<cfile->n_hap; i++)
    cfile->prob_nt_hap[i]/=sum;

  sum=0;
  for(i=0; i<cfile->n_fam ;i++) 
  {
    for(j=0;j<(cfile->fam[i]).nb_conf;j++)
    {  
      (cfile->fam[i]).proba[j] = 1;

      g0 = (cfile->fam[i]).T[2*j];
      g1 = (cfile->fam[i]).T[2*j+1];

      (cfile->fam[i]).proba[j]*=cfile->prob_nt_hap[g0];
      (cfile->fam[i]).proba[j]*=cfile->prob_nt_hap[g1];
    
      h0 = (cfile->fam[i]).NT[2*j];
      h1 = (cfile->fam[i]).NT[2*j+1];

      (cfile->fam[i]).proba[j]*=cfile->prob_nt_hap[h0];
      (cfile->fam[i]).proba[j]*=cfile->prob_nt_hap[h1];
 
      sum+=(cfile->fam[i]).proba[j];
    }
    
    for(j=0;j<(cfile->fam[i]).nb_conf;j++)
      {
	(cfile->fam[i]).proba[j]/=sum;
      }
    sum=0;
  }
  return;
}
