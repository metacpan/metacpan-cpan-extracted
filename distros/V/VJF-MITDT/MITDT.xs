#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "toolbox.c"

/* Cree un trio de taille n */
struct TRIO new_trio(int n)
{
  struct TRIO trio;
  trio.nb_conf = n;
  trio.NT    = (entier *) malloc(2*n*sizeof(entier));
  trio.T     = (entier *) malloc(2*n*sizeof(entier));
  trio.proba = (flottant *) malloc(n*sizeof(flottant));
  if(trio.NT == NULL || trio.T == NULL || trio.proba == NULL)
  {
    fputs("Out of Memory\n", stderr);
    exit(1);
  }
  return trio;
}

void del_trio(struct TRIO * trio)
{
  if(trio->nb_conf == 0)
    return;

  trio->nb_conf = 0;
  free(trio->NT);
  free(trio->T);
  free(trio->proba);
}

struct DATA1 new_data1(entier N, entier M)
{
  struct DATA1 dat;
  dat.n_hap = N;
  dat.n_fam = M;
  dat.fam = (struct TRIO *) malloc(M*sizeof(struct TRIO));
  dat.prob_nt_hap = (flottant *) malloc(N*sizeof(flottant));
  dat.prob_t_gen  = (flottant *) malloc(N*N*sizeof(flottant));
  if(dat.fam == NULL || dat.prob_nt_hap == NULL || dat.prob_t_gen == NULL)
  {
    fputs("Out of Memory\n", stderr);
    exit(1);
  }
  return dat;
}

// LA MEME FONCTION mais sans la table prob_t_gen (pas utilisée sous H0)
struct DATA1 new_data1_H0(entier N, entier M)
{
  struct DATA1 dat;
  dat.n_hap = N;
  dat.n_fam = M;
  dat.fam = (struct TRIO *) malloc(M*sizeof(struct TRIO));
  dat.prob_nt_hap = (flottant *) malloc(N*sizeof(flottant));
  dat.prob_t_gen  = NULL;
  if(dat.fam == NULL || dat.prob_nt_hap == NULL)
  {
    fputs("Out of Memory\n", stderr);
    exit(1);
  }
  return dat;
}

void del_data1(struct DATA1 * data)
{
  int i;
  for(i=0; i< data->n_fam; i++)
  {
    del_trio(data->fam+i);
  }
  free(data->fam);
  free(data->prob_nt_hap);
  free(data->prob_t_gen);
  data->n_hap = data->n_fam = 0;
}

void print_data(struct DATA1 * data)
{
  int i, j;

  for(i=0; i< data->n_fam; i++)
  {
     printf("%d [%d]", i, data->fam[i].nb_conf);
     for(j=0; j<data->fam[i].nb_conf; j++)
     {
	printf("\t%d  ", j);
	printf("%d  ", data->fam[i].NT[2*j]);
	printf("%u  ", data->fam[i].NT[(2*j)+1]);
	printf("%u  ", data->fam[i].T[2*j]);
	printf("%u  ", data->fam[i].T[(2*j)+1]);
	printf("%f\n", data->fam[i].proba[j]);
     }
  }

}

MODULE = VJF::MITDT   PACKAGE = VJF::MITDT
PROTOTYPES: ENABLE

BOOT: 
initial();   /* initialise le RNG */

struct DATA1 * cree_data1(N, M)
	entier N
	entier M
  CODE:
  	struct DATA1 * data = (struct DATA1 *) malloc(sizeof(struct DATA1));
	*data = new_data1(N,M);
	RETVAL = data;
  OUTPUT:
  	RETVAL

struct DATA1 * cree_data1_H0(N, M) 
	entier N
	entier M
  CODE:
  	struct DATA1 * data = (struct DATA1 *) malloc(sizeof(struct DATA1));
	*data = new_data1_H0(N,M);
	RETVAL = data;
  OUTPUT:
  	RETVAL


void set_trio(data, trio, nb_conf, ...)
	struct DATA1 * data 
	unsigned int trio
       	unsigned int nb_conf
  CODE:
  	unsigned int i;
        if(data->n_fam < trio)
	{
	  croak("cree_data1: family number too high\n");
	  exit(1);
	}
        data->fam[trio] = new_trio(nb_conf);
  	items -= 3;
	if(items != 5*nb_conf)
        {
	  croak("cree_data1: bad number of parameters\n");
	}
	for(i=0; i<items/5; i++)
	{
	  data->fam[trio].NT[2*i]   = SvUV(ST(3+5*i));
	  data->fam[trio].NT[2*i+1] = SvUV(ST(3+5*i+1));
	  data->fam[trio].T[2*i]    = SvUV(ST(3+5*i+2));
	  data->fam[trio].T[2*i+1]  = SvUV(ST(3+5*i+3));
	  data->fam[trio].proba[i]  = SvNV(ST(3+5*i+4));
	}

void get_trio(data, trio, conf)
	struct DATA1 * data
	unsigned int trio
	unsigned int conf
  PPCODE:
  	if(data->n_fam < trio)
	  XSRETURN_EMPTY; 
	if(data->fam[trio].nb_conf < conf)
	  XSRETURN_EMPTY; 
	EXTEND(SP, 5);
	mXPUSHu(data->fam[trio].NT[2*conf]);
	mXPUSHu(data->fam[trio].NT[2*conf+1]);
	mXPUSHu(data->fam[trio].T[2*conf]);
	mXPUSHu(data->fam[trio].T[2*conf+1]);
	mXPUSHn(data->fam[trio].proba[conf]);


void print_data(data)
	struct DATA1 * data

void make_freq_cum(cfile)
	struct DATA1 * cfile

void make_imput(cfile, ifile)
	struct DATA1 * cfile
	struct DATA1 * ifile

void init_tab(cfile)
	struct DATA1 * cfile

void compt_geno(cfile, ifile)
	struct DATA1 * cfile
	struct DATA1 * ifile

void compt_untrans(cfile, ifile)
	struct DATA1 * cfile
	struct DATA1 * ifile

void new_param(cfile, ifile, alpha)
	struct DATA1 * cfile
	struct DATA1 * ifile
	flottant alpha

void new_posterior(cfile, ifile)
	struct DATA1 * cfile
	struct DATA1 * ifile



void init_tab_H0(cfile)
	struct DATA1 * cfile

void compt_hap_H0(cfile, ifile)
	struct DATA1 * cfile
	struct DATA1 * ifile

void new_param_H0(cfile, ifile, alpha)
	struct DATA1 * cfile
	struct DATA1 * ifile
	flottant alpha

void new_posterior_H0(cfile, ifile)
	struct DATA1 * cfile
	struct DATA1 * ifile

