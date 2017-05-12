#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "EM.c"

void print_unit(unsigned int x, struct UNIT * u)
{
  pos_t i;
  printf("Unit number %d, %ld possibilities\n", x, u->n);
  for(i=0; i<u->n; i++)
  {
    printf("Possibility %ld, proba %e\n", u->pos[i], u->prob[i]);
  }
}

void print_unit_h(unsigned int x, struct UNIT * u)
{
  pos_t i;
  printf("Haplotypic unit %d, %ld possibilities\n", x, u->n);
  for(i=0; i<u->n; i++)
  {
    printf("Haplotypes [%ld, %ld], proba %e\n", u->pos[2*i], u->pos[2*i+1], u->prob[i]);
  }
}

void print_unit_t(unsigned int x, struct UNIT * u)
{
  pos_t i;
  printf("Haplotypic unit %d, %ld possibilities\n", x, u->n);
  for(i=0; i<u->n; i++)
  {
    printf("Haplotypes [%ld, %ld] [%ld, %ld], proba %e\n", u->pos[8*i], u->pos[8*i+1], u->pos[8*i+2], u->pos[8*i+3], u->prob[i]);
  }
}

void print_data_short(struct DATA * d)
{
  pos_t i;
  unsigned int j;
  printf("Data set of %d units.\n", d->M);
  printf("1st set: %ld possibilities\n", d->N);
  printf("2nd set: %ld possibilities\n", d->N2);
  printf("1st set: A priori probability of each possiblity:\n");
  for(i=0; i<d->N; i++)
  {
    printf("%ld : %e\n",i,d->prob[i]);
  }
  printf("2nd set: A priori probability of each possiblity:\n");
  for(i=0; i<d->N2; i++)
  {
    printf("%ld : %e\n",i,d->prob2[i]);
  }
}

void print_data(struct DATA * d)
{
  pos_t i;
  unsigned int j;
  printf("Data set of %d units.\n", d->M);
  printf("1st set: %ld possibilities\n", d->N);
  printf("2nd set: %ld possibilities\n", d->N2);
  printf("1st set: A priori probability of each possiblity:\n");
  for(i=0; i<d->N; i++)
  {
    printf("%ld : %e\n",i,d->prob[i]);
  }
  printf("2nd set: A priori probability of each possiblity:\n");
  for(i=0; i<d->N2; i++)
  {
    printf("%ld : %e\n",i,d->prob2[i]);
  }
  printf("List of all units:\n");
  for(j=0; j<d->M; j++)
  {
    print_unit(j,d->I+j);
  }
}

void print_data_h(struct DATA * d)
{
  pos_t i;
  unsigned int j;
  printf("Data set of %d units with %ld possibilities\n", d->M, d->N);
  printf("A priori probability of each possiblity:\n");
  for(i=0; i<d->N; i++)
  {
    printf("%ld : %e\n",i,d->prob[i]);
  }
  printf("List of all units:\n");
  for(j=0; j<d->M; j++)
  {
    print_unit_h(j,d->I+j);
  }
}

void print_data_t(struct DATA * d)
{
  pos_t i;
  unsigned int j;
  printf("Data set of %d units with %ld possibilities\n", d->M, d->N);
  printf("A priori probability of each possiblity:\n");
  for(i=0; i<d->N; i++)
  {
    printf("%ld : %e\n",i,d->prob[i]);
  }
  printf("List of all units:\n");
  for(j=0; j<d->M; j++)
  {
    print_unit_t(j,d->I+j);
  }
}


MODULE = VJF::Emphase   PACKAGE = VJF::Emphase
PROTOTYPES: ENABLE

struct DATA * new_d(M)
	unsigned int M
  CODE:
	struct DATA * d = (struct DATA *) malloc(sizeof(struct DATA));
        unsigned int i;
        pos_t j;
        d->N = d->N2 = 0;
        d->M = M;
        d->I = (struct UNIT *) malloc(M*sizeof(struct UNIT));
        d->prob = d->prob2 = NULL;
        if(d->I == NULL && M != 0)
        {
           croak("Out of memory\n");
           exit(1);
        }
        for(i=0; i<M; i++)
        {
          d->I[i].n = 0;
        }
	RETVAL = d;
  OUTPUT:
	RETVAL

void extend_possibilities(d, N)
	struct DATA * d
	pos_t N
  CODE:
        pos_t j;
	if(d->N != 0)
        {
	  free(d->prob);
	}
  	d->N = N;
        d->prob  = (prob_t *) malloc(N*sizeof(prob_t));
        if(d->prob == NULL && N != 0)
        {
           croak("Out of memory\n");
           exit(1);
        }
        for(j=0; j<N; j++)
        {
          d->prob[j] = 1.0/N;
        }

void set_N(d, N)
	struct DATA * d
	pos_t N
  CODE:
	if(d->N != 0)
        {
	  free(d->prob);
	}
        d->prob = NULL;
  	d->N = N;

void extend_possibilities2(d, N2) 
	struct DATA * d
	pos_t N2
  CODE:
        pos_t j;
	if(d->N2 != 0)
        {
	  free(d->prob2);
	}
  	d->N2 = N2;
        d->prob2 = (prob_t *) malloc(N2*sizeof(prob_t));
        if(d->prob2 == NULL && N2 != 0)
        {
           croak("Out of memory\n");
           exit(1);
        }
        for(j=0; j<N2; j++)
        {
          d->prob2[j] = 1.0/N2;
        }

void set_probas(d, ...)
        struct DATA * d
   CODE:
        unsigned long i;
        items -= 1;
        if(items != d->N) 
        {
          warn("set_probas: unmatching length");
          return;
        }
        for(i = 0; i<items; i++)
       	{
          d->prob[i] = (prob_t) SvNV(ST(i+1));
        }

void set_probas2(d, ...)
        struct DATA * d
   CODE:
        unsigned long i;
        items -= 1;
        if(items != d->N2) 
        {
          warn("set_probas: unmatching length");
          return;
        }
        for(i = 0; i<items; i++)
       	{
          d->prob2[i] = (prob_t) SvNV(ST(i+1));
        }

void set_unit(d, i, ...)
	struct DATA * d
        unsigned long i
  CODE:
        unsigned long j;
        pos_t X;
        if(i >= d->M)
        {
          warn("set unit: overflow");
          return;
        }
        items -= 2;
        del_unit(d->I+i);
        d->I[i] = new_unit(items);
        for(j = 0; j < items; j++)
	{
	  d->I[i].pos[j] = (pos_t) SvUV(ST(j+2));
	  d->I[i].prob[j] = 1.0/items;
        }

void set_unit_h(d, i, ...)
	struct DATA * d
        unsigned long i
  CODE:
        unsigned long j;
        pos_t X;
        if(i >= d->M)
        {
          warn("set unit: overflow");
          return;
        }
        items -= 2;
        if(2*(items/2) != items)
        {
          warn("set_unit_h: list has uneven length.\n");
          return;
        }
        del_unit(d->I+i);
        d->I[i] = new_unit_h(items/2);
        for(j = 0; j < items; j++)
	{
	  d->I[i].pos[j] = (pos_t) SvUV(ST(j+2));
	  d->I[i].prob[j/2] = 2.0/items;
        }


void set_unit_t(d, i, ...)
	struct DATA * d
        unsigned long i
  CODE:
        unsigned long j;
        pos_t X;
        if(i >= d->M)
        {
          warn("set unit: overflow");
          return;
        }
        items -= 2;
        if(items%8 != 0)
        {
          warn("set_unit_h: list has length !=0 mod 8.\n");
          return;
        }
        del_unit(d->I+i);
        d->I[i] = new_unit_t(items/8);
        for(j = 0; j < items/8; j++)
	{
	  d->I[i].pos[8*j]   = (pos_t) SvUV(ST(2+8*j));
	  d->I[i].pos[8*j+1] = (pos_t) SvUV(ST(2+8*j+1));
	  d->I[i].pos[8*j+2] = (pos_t) SvUV(ST(2+8*j+2));
	  d->I[i].pos[8*j+3] = (pos_t) SvUV(ST(2+8*j+3));
	  d->I[i].pos[8*j+4] = (pos_t) SvUV(ST(2+8*j+4));
	  d->I[i].pos[8*j+5] = (pos_t) SvUV(ST(2+8*j+5));
	  d->I[i].pos[8*j+6] = (pos_t) SvUV(ST(2+8*j+6));
	  d->I[i].pos[8*j+7] = (pos_t) SvUV(ST(2+8*j+7));
	  d->I[i].prob[j] = 8.0/items;
        }

pos_t nbpos_unit(d,i)
	struct DATA * d
	unsigned long i
  CODE:
        if(i < d->M)
        {
	  RETVAL = d->I[i].n;
	}
	else
	{
	  RETVAL = 0;
	}
  OUTPUT:
  	RETVAL

void get_unit(IN struct DATA * d,IN unsigned long i,IN pos_t n,OUTLIST pos_t a, OUTLIST prob_t p)
  PROTOTYPE:$$$
  CODE:
        if(i < d->M || n < d->I[i].n)
        {
	  a = d->I[i].pos[n];
	  p = d->I[i].prob[n];
	}
	else
        {
	  a = 0;
	  p = 0;
	}


void get_unit_h(IN struct DATA * d,IN unsigned long i,IN pos_t n,OUTLIST pos_t a1, OUTLIST pos_t a2, OUTLIST prob_t p)
  PROTOTYPE:$$$
  CODE:
        if(i < d->M || n < d->I[i].n)
        {
	  a1 = d->I[i].pos[2*n];
	  a2 = d->I[i].pos[2*n + 1];
	  p  = d->I[i].prob[n];
	}
	else
        {
	  a1 = a2 = 0;
	  p = 0;
	}


void get_unit_t(IN struct DATA * d,IN unsigned long i,IN pos_t n,OUTLIST pos_t a1, OUTLIST pos_t a2, OUTLIST pos_t a3, OUTLIST pos_t a4, OUTLIST pos_t a5, OUTLIST pos_t a6, OUTLIST pos_t a7, OUTLIST pos_t a8, OUTLIST prob_t p)
  PROTOTYPE:$$$
  CODE:
        if(i < d->M || n < d->I[i].n)
        {
	  a1 = d->I[i].pos[8*n];
	  a2 = d->I[i].pos[8*n + 1];
	  a3 = d->I[i].pos[8*n + 2];
	  a4 = d->I[i].pos[8*n + 3];
	  a5 = d->I[i].pos[8*n + 4];
	  a6 = d->I[i].pos[8*n + 5];
	  a7 = d->I[i].pos[8*n + 6];
	  a8 = d->I[i].pos[8*n + 7];
	  p  = d->I[i].prob[n];
	}
	else
        {
	  a1 = a2 = a3 = a4 = a5 = a6 = a7 = a8 = 0;
	  p = 0;
	}

void get_proba_unit_t(IN struct DATA * d,IN unsigned long i,IN pos_t n, OUTLIST prob_t p)
  PROTOTYPE:$$$
  CODE:
        if(i < d->M || n < d->I[i].n)
        {
	  p  = d->I[i].prob[n];
	}
	else
        {
	  p = 0;
	}


void get_prob(d)
	struct DATA * d
  PPCODE:
        pos_t i;
        if(d->N == 0)
        {
	  XSRETURN_EMPTY;
	}
  	EXTEND(SP,d->N);
	for(i=0; i<d->N; i++)
	{
	  mXPUSHn(d->prob[i]);
	}

void get_prob2(d)
	struct DATA * d
  PPCODE:
        pos_t i;
        if(d->N2 == 0)
        {
	  XSRETURN_EMPTY;
	}
  	EXTEND(SP,d->N2);
	for(i=0; i<d->N2; i++)
	{
	  mXPUSHn(d->prob2[i]);
	}

void get_marginal2(d)
	struct DATA * d
  PPCODE:
        pos_t i,a,b;
        unsigned int j,k,l;
	prob_t p;
        if(d->N2 == 0)
        {
	  XSRETURN_EMPTY;
	}
  	EXTEND(SP,d->N);
        for(i=0; i<d->N; i++)
        { 
	  p = 0;
	  for(j=0; j<d->N; j++)  
	    p += d->prob2[i*d->N + j]; 
	  mXPUSHn(p);
	}



void print_data_short(d)
	struct DATA * d;

void print_data(d)
	struct DATA * d;

void print_data_h(d)
	struct DATA * d;

void print_data_t(d)
	struct DATA * d;

void del_data(d)
	struct DATA * d;

void E_step(d)
        struct DATA * d;

void M_step(d)
        struct DATA * d;

void E_step_h(d)
        struct DATA * d;

void M_step_h(d)
        struct DATA * d;

void E_step_d(d)
        struct DATA * d;

void M_step_d(d)
        struct DATA * d;

void freqhap_d(d)
        struct DATA * d;

void E_step_t(d)
        struct DATA * d;

void M_step_t(d)
        struct DATA * d;

void E_step_thd(d)
        struct DATA * d;

void M_step_thd(d)
        struct DATA * d;

void cut_at_threshold(d, th)
        struct DATA * d;
	prob_t th;

void cut_at_threshold2(d, th)
        struct DATA * d;
	prob_t th;

double Likelihood(d)
	struct DATA * d;

double Likelihood_h(d)
	struct DATA * d;

double Likelihood_d(d)
	struct DATA * d;

double Likelihood_t(d)
	struct DATA * d;

double Likelihood_thd(d)
	struct DATA * d;
