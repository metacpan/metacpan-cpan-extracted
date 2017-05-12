extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
}

#include "PMT.h"

typedef PMT Tree__M__MT;
typedef double *Key;

static double *
sv2c(SV *sv, int ndims)
{
  if (!SvROK (sv) || SvTYPE (SvRV (sv)) != SVt_PVAV)
    croak ("Tree::M: key must be array reference");

  AV *av = (AV *)SvRV (sv);

  if (av_len (av) != ndims -1)
    croak ("Tree::M: illegal key, expected %d elements, found %d",
           ndims, av_len (av) + 1);

  double *k = new double [ndims];

  for (int i = ndims; i--; )
    k[i] = SvNV (*av_fetch (av, i, 1));

  return k;
}

static SV *
c2sv(double *k, int ndims)
{
  AV *av = newAV ();

  av_extend (av, ndims);
  for (int i = ndims; i--; )
    av_store (av, i, newSVnv (k[i]));
    
  return newRV_noinc ((SV *)av);
}

static AV *searchres;

void add_result(int data, double *k, int ndims)
{
   AV *r = newAV ();

   av_push (r, c2sv (k, ndims));
   av_push (r, newSViv (data));

   av_push (searchres, newRV_noinc ((SV *)r));
}

MODULE = Tree::M		PACKAGE = Tree::M

PROTOTYPES: ENABLE

PMT *
_new(class, ndims, min = 0.0, max = 255.0, steps = 256.0, pagesize = 4096)
        int		ndims
        double		min
        double		max
        double		steps
        unsigned int	pagesize
	CODE:
        RETVAL = new PMT(ndims, min, max, steps, pagesize);
        OUTPUT:
        RETVAL

void
PMT::create(path)
	char *	path

void
PMT::open(path)
	char *	path

void
PMT::insert(k, idx = 0)
	SV *	k
        int	idx
        C_ARGS:
        sv2c(k, THIS->ndims), idx

double
PMT::distance(k1, k2)
	SV *	k1
	SV *	k2
        C_ARGS:
        sv2c(k1, THIS->ndims), sv2c(k2, THIS->ndims)

SV *
PMT::range(k, r)
	SV *	k
        double	r
        CODE:
        searchres = newAV ();
        THIS->range(sv2c(k, THIS->ndims), r);
        RETVAL = newRV_noinc ((SV *)searchres);
        OUTPUT:
        RETVAL

SV *
PMT::top(k, n)
	SV *	k
        int	n
        CODE:
        searchres = newAV ();
        THIS->top(sv2c(k, THIS->ndims), n);
        RETVAL = newRV_noinc ((SV *)searchres);
        OUTPUT:
        RETVAL

void
PMT::sync()

int
PMT::maxlevel()

void
PMT::DESTROY()

