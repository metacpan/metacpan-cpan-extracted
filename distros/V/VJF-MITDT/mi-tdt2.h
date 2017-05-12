#define entier unsigned long   /* This could be changed to any INTEGER TYPE
                                * the fact that it is an integer is really used. */
#define flottant double

struct TRIO
{
  unsigned int nb_conf;
  entier * NT;       /* vecteur des haplotypes non transmis:
			longueur 2*nb_conf */
  entier * T;        /* vecteur des genotypes transmis:
			longueur 2*nb_conf */
  flottant * proba;  /* vecteur des probabilités des conf:
			longueur nb_conf */ 
};

struct DATA1
{
  unsigned int n_hap;
  unsigned int n_fam;
  struct TRIO * fam;     /* table de longueur n_fam; */
  flottant * prob_nt_hap;  /* table de longueur n_hap */
  flottant * prob_t_gen;   /* table de longueur n_hap**2 */
};

void make_freq_cum(struct DATA1 * cfile);
void make_imput(struct DATA1 * cfile, struct DATA1 * ifile);
void init_tab(struct DATA1 * cfile);
void compt_geno(struct DATA1 * cfile, struct DATA1 * ifile);
void compt_untrans(struct DATA1 * cfile, struct DATA1 * ifile);
void new_param(struct DATA1 * cfile, struct DATA1 * ifile, flottant alpha);
void new_posterior(struct DATA1 * cfile, struct DATA1 * ifile);void init_tab(struct DATA1 * cfile);

void init_tab_H0(struct DATA1 * cfile);
void compt_hap_H0(struct DATA1 * cfile, struct DATA1 * ifile);
void new_param_H0(struct DATA1 * cfile, struct DATA1 * ifile, flottant alpha);
void new_posterior_H0(struct DATA1 * cfile, struct DATA1 * ifile);
