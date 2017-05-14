/* Copyright (c) 1997 by Fernando Trias */

#include <stdlib.h>
#include <memory.h>
#include <malloc.h>
#include <errno.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "perldef.h"

#include "hli.h"

#ifdef FRB
#include "hliutils.h"
#endif

#ifdef ADJDIV
#include "adjdiv.h"
#endif

union vsdata {  /* one data item */
      float           pf;
      double          pd;
      int             pi;
      char *          pc;
};
union vpdata {  /* pointers to data items */
      float          *pf;
      double         *pd;
      int            *pi;
      char *         *pc;
};
struct vdata {
    int           typ;
    int           numobs;
    union vpdata  val;
    int          *misary;  /* for strings */
    int          *lenary;  /*  "      "   */
    union {
      float         pf[3]; /* missing data trans. tbls */
      double        pd[3];
      int           pi[3];
      char *        pc[3];
    }             mistt;
};

int             f_status;
char            *version="2.01";

/* misc function declarations */
int             fameinit();
/*
#include "fameperl.h"
*/
#include "fame.xtra"

#include "fame.i"

/* include constants code */
#include "famecons.i"

#ifdef HAS_PROTOTYPE
int Fame_getsize(int typ)
#else
int Fame_getsize(typ)
int typ;
#endif
{
    int sz;
    if (typ >= HDAILY) { typ = HDATE; }

    switch (typ) {
    case HNUMRC:
      sz = sizeof(float);
      break;
    case HBOOLN:
      sz = sizeof(int);
      break;
    case HPRECN:
      sz = sizeof(double);
      break;
    case HUNDFT:
      sz = 0;
      break;
    case HDATE:
      sz = sizeof(int);
      break;
    case HSTRNG:
    case HNAMEL:
      sz = sizeof(char *);
      break;
    default:
      sz = 0;
    }

    return sz;
}

#ifdef HAS_PROTOTYPE
int Fame_allocate(WIN32PREFIX struct vdata *d, int typ, int numobs)
#else
int Fame_allocate(d, typ, numobs)
struct vdata *d;
int typ;
int numobs;
#endif
{
    int sz, i;

    sz = Fame_getsize(typ);
    d->typ = typ;
    if (typ != HNAMEL && typ != HSTRNG) {
      d->val.pf = (float *) malloc(numobs * sz);
    } else {
      d->val.pc = (char **) malloc(numobs * sizeof(char *));
      d->misary = (int *) malloc(numobs * sizeof(int));
      d->lenary = (int *) malloc(numobs * sizeof(int));
      for (i = 0; i < numobs; i++)
        d->val.pc[i] = (char *) malloc(200 * sizeof(char));
        d->misary[i] = HNMVAL;
        d->lenary[i] = 0;
    }
    d->numobs = numobs;
    return 1;
}

#ifdef HAS_PROTOTYPE
int Fame_free(WIN32PREFIX struct vdata *d)
#else
int Fame_free(d)
struct vdata *d;
#endif
{
    int i;

    if (d->typ != HNAMEL && d->typ != HSTRNG) {
      free(d->val.pf);
    } else {
      free(d->misary);
      free(d->lenary);
      for (i = 0; i < d->numobs; i++)
        free(d->val.pc[i]);
      free(d->val.pc);
    }
    return 1;
}

#ifdef HAS_PROTOTYPE
int Fame_readitems(struct vdata *d, int dbkey, char *series, int *range)
#else
int Fame_readitems(d, dbkey, series, range)
struct vdata *d;
int dbkey;
char *series;
int *range;
#endif
{
    int status;
    if (d->typ != HNAMEL && d->typ != HSTRNG) {
      cfmrrng(&status, dbkey, series, range, d->val.pf, HNTMIS, d->mistt.pf);
      f_status = status;
    } else {
      cfmrsts(&status, dbkey, series, range, d->val.pc, d->misary, d->lenary);
      f_status = status;
    }
    return status;
}

#ifdef HAS_PROTOTYPE
int Fame_writeitems(struct vdata *d, int dbkey, char *series, int *range)
#else
int Fame_writeitems(d, dbkey, series, range)
struct vdata *d;
int dbkey;
char *series;
int *range;
#endif
{
    int status;
    if (d->typ != HNAMEL && d->typ != HSTRNG) {
      cfmwrng(&status, dbkey, series, range, d->val.pf, HNTMIS, d->mistt.pf);
      f_status = status;
    } else {
      int i;
      for(i=0; i<d->numobs; i++) {
        d->lenary[i] = strlen(d->val.pc[i]);
        if (memcmp(d->val.pc[i], FSTRNC, HSMLEN)==0)
          d->misary[i] = HNCVAL;
        else if (memcmp(d->val.pc[i], FSTRND, HSMLEN)==0)
          d->misary[i] = HNDVAL;
        else if (memcmp(d->val.pc[i], FSTRNA, HSMLEN)==0)
          d->misary[i] = HNAVAL;
        else
          d->misary[i] = HNMVAL;
      }
      cfmwsts(&status, dbkey, series, range, d->val.pc, d->misary, d->lenary);
      f_status = status;
    }
    return status;
}

/*
   set an item in valary = the value of sv
*/
#ifdef HAS_PROTOTYPE
int Fame_setVAL(WIN32PREFIX SV *sv, int typ, float *valary, int i)
#else
int Fame_setVAL(sv, typ, valary, i)
SV *sv;
int typ;
float *valary;
int i;
#endif
{
    float *pf;
    int *pi;
    double *pd;
    char **pc;
    char *ss;

    if (typ >= HDAILY) { typ = HDATE; }
    
    switch (typ) {
    case HNUMRC:
      pf = (float *) valary;
      break;
    case HBOOLN:
      pi = (int *) valary;
      break;
    case HPRECN:
      pd = (double *) valary;
      break;
    case HDATE:
      pi = (int *) valary;
      break;
    case HNAMEL:
    case HSTRNG:
      pc = (char **) valary;
      break;
    }

    ss = SvPV(sv, na);

    switch (typ) {
    case HNUMRC:
      if (ss[0] == 'N') {
        if (strcmp(ss, "NC") == 0)
          pf[i] = FNUMNC;
        else if (strcmp(ss, "ND") == 0)
          pf[i] = FNUMND;
        else if (strcmp(ss, "NA") == 0)
          pf[i] = FNUMNA;
        else
          pf[i] = (float) SvNV(sv);
      } else
        pf[i] = (float) SvNV(sv);
      break;
    case HBOOLN:
      if (ss[0] == 'N') {
        if (strcmp(ss, "NC") == 0)
          pi[i] = FBOONC;
        else if (strcmp(ss, "ND") == 0)
          pi[i] = FBOOND;
        else if (strcmp(ss, "NA") == 0)
          pi[i] = FBOONA;
        else
          pi[i] = (int) SvIV(sv);
      } else
        pi[i] = (int) SvIV(sv);
      break;
    case HDATE:
      if (ss[0] == 'N') {
        if (strcmp(ss, "NC") == 0)
          pi[i] = FDATNC;
        else if (strcmp(ss, "ND") == 0)
          pi[i] = FDATND;
        else if (strcmp(ss, "NA") == 0)
          pi[i] = FDATNA;
        else
          pi[i] = (int) SvIV(sv);
      } else
        pi[i] = (int) SvIV(sv);
      break;
    case HPRECN:
      if (ss[0] == 'N') {
        if (strcmp(ss, "NC") == 0)
          pd[i] = FPRCNC;
        else if (strcmp(ss, "ND") == 0)
          pd[i] = FPRCND;
        else if (strcmp(ss, "NA") == 0)
          pd[i] = FPRCNA;
        else
          pd[i] = (double) SvNV(sv);
      } else
        pd[i] = (double) SvNV(sv);
      break;
    case HNAMEL:
    case HSTRNG:
      if (ss[0] == 'N') {
        if (strcmp(ss, "NC") == 0)
          memcpy(pc[i], FSTRNC, HSMLEN);
        else if (strcmp(ss, "ND") == 0)
          memcpy(pc[i], FSTRND, HSMLEN);
        else if (strcmp(ss, "NA") == 0)
          memcpy(pc[i], FSTRNA, HSMLEN);
        else
          strcpy(pc[i], (char *) SvPV(sv, na));
      } else
        strcpy(pc[i], (char *) SvPV(sv, na));
      break;
    default:
      return 0;
    }
    return 1;
}


/*
   set an sv = an item in valary
*/
#ifdef HAS_PROTOTYPE
int Fame_setSV(WIN32PREFIX SV *sv, int typ, float *valary, int i)
#else
int Fame_setSV(sv, typ, valary, i)
SV *sv;
int typ;
float *valary;
int i;
#endif
{
    float *pf;
    int *pi;
    double *pd;
    char **pc;
    
    if (typ >= HDAILY) { typ = HDATE; }

    switch (typ) {
    case HNUMRC:
      pf = (float *) valary;
      break;
    case HBOOLN:
      pi = (int *) valary;
      break;
    case HPRECN:
      pd = (double *) valary;
      break;
    case HDATE:
      pi = (int *) valary;
      break;
    case HNAMEL:
    case HSTRNG:
      pc = (char **) valary;
      break;
    }

    switch (typ) {
    case HNUMRC:
      if (pf[i] == FNUMNC) { sv_setpv(sv,"NC"); }
      else if (pf[i] == FNUMND) { sv_setpv(sv,"ND"); }
      else if (pf[i] == FNUMNA) { sv_setpv(sv,"NA"); }
      else { sv_setnv(sv,(double) pf[i]); }
      break;
    case HBOOLN:
      if (pi[i] == FBOONC) { sv_setpv(sv,"NC"); }
      else if (pi[i] == FBOOND) { sv_setpv(sv,"ND"); }
      else if (pi[i] == FBOONA) { sv_setpv(sv,"NA"); }
      else { sv_setiv(sv,(int) pi[i]); }
      break;
    case HDATE:
      if (pi[i] == FDATNC) { sv_setpv(sv,"NC"); }
      else if (pi[i] == FDATND) { sv_setpv(sv,"ND"); }
      else if (pi[i] == FDATNA) { sv_setpv(sv,"NA"); }
      else { sv_setiv(sv,(int) pi[i]); }
      break;
    case HPRECN:
      if (pd[i] == FPRCNC) { sv_setpv(sv,"NC"); }
      else if (pd[i] == FPRCND) { sv_setpv(sv,"ND"); }
      else if (pd[i] == FPRCNA) { sv_setpv(sv,"NA"); }
      else { sv_setnv(sv,(double) pd[i]); }
      break;
    case HNAMEL:
    case HSTRNG:
      if (memcmp(pc[i], FSTRNC, HSMLEN) == 0)
        sv_setpv(sv, "NC");
      else if (memcmp(pc[i], FSTRND, HSMLEN) == 0)
        sv_setpv(sv, "ND");
      else if (memcmp(pc[i], FSTRNA, HSMLEN) == 0)
        sv_setpv(sv, "NA");
      else
        sv_setpv(sv, pc[i]);
      break;
    default:
      return 0;
    }
    return 1;
}

XS(Fame_constant)
{
    dXSARGS;
    if (items != 2) {
        croak("Usage: Fame::HLI::constant(name,arg)");
    }
    {
        char *  name = (char *)SvPV(ST(0),na);
        int     arg = (int)SvIV(ST(1));
        double  RETVAL;
 
        RETVAL = constant(WIN32PASS name, arg);
        ST(0) = sv_newmortal();
        sv_setnv(ST(0), (double)RETVAL);
    }
    XSRETURN(1);
}


XS(Fame_cfmgatt)
{
  dXSARGS;
  if (items != 6)
    croak("Usage: &cfmgatt($status, $dbkey, $objnam, $atttyp, $attnam, $value)");
  else {
    int             retval = 1;
    int             status;
    int             dbkey = (int) SvIV(ST(1));
    char           *objnam = (char *) SvPV(ST(2), na);
    int             atttyp = (int) SvIV(ST(3));
    char           *attnam = (char *) SvPV(ST(4), na);
    char            value[133];

    /* value = (char *) malloc(133 * sizeof(char)); */
    (void) cfmgatt(&status, dbkey, objnam, &atttyp, attnam, value);

    if (!SvREADONLY(ST(0)))
      sv_setiv(ST(0), status);
    if (!SvREADONLY(ST(2)))
      sv_setpv(ST(2), (char *) objnam);
    if (!SvREADONLY(ST(3)))
      sv_setiv(ST(3), atttyp);
    if (!SvREADONLY(ST(4)))
      sv_setpv(ST(4), (char *) attnam);

    Fame_setSV(WIN32PASS ST(5), atttyp, (float *)value, 0);

    free(value);
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), status);
  }
  XSRETURN(1);
}


XS(Fame_cfmsatt)
{
  dXSARGS;
  if (items != 6)
    croak("Usage: &cfmgatt($status, $dbkey, $objnam, $atttyp, $attnam, $value)");
  else {
    int             retval = 1;
    int             status;
    int             dbkey = (int) SvIV(ST(1));
    char           *objnam = (char *) SvPV(ST(2), na);
    int             atttyp = (int) SvIV(ST(3));
    char           *attnam = (char *) SvPV(ST(4), na);
    char           *value;
    char            space[255];
    char           *ss;
    union vsdata    pp;

    Fame_setVAL(WIN32PASS ST(5), atttyp, (float *)&pp, 0);
    (void) cfmsatt(&status, dbkey, objnam, atttyp, attnam, (char *) &pp);

    if (!SvREADONLY(ST(0)))
      sv_setiv(ST(0), status);
    if (!SvREADONLY(ST(2)))
      sv_setpv(ST(2), objnam);
    if (!SvREADONLY(ST(4)))
      sv_setpv(ST(4), attnam);

    ST(0) = sv_newmortal();
    sv_setiv(ST(0), status);
  }
  XSRETURN(1);
}


XS(Fame_famestart)
{
  dXSARGS;
  if (items != 0)
    croak("Usage: &famestart()");
  else {
    int retval;
    cfmini(&retval);
    f_status = retval;
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), retval);
  }
  XSRETURN(1);
}


XS(Fame_famestop)
{
  dXSARGS;
  if (items != 0)
    croak("Usage: &famestop()");
  else {
    int retval;
    cfmfin(&retval);
    f_status = retval;
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), retval);
  }
  XSRETURN(1);
}


XS(Fame_fameopen)
{
  dXSARGS;
  if (items < 1 || items > 2)
    croak("Usage: $dbkey=&fameopen($name [,$mode])");
  else {
    int             retval = 1;
    char           *name = (char *) SvPV(ST(0), na);
    char            name2[1024];
    int             mode;
    int             status;

#ifdef FRB
    char           path[256];

    (void) getdbpath(name, path);
    if (path != NULL && *path != '\n')
      name = path;
    if (name[strlen(name) - 1] == '\n')
      name[strlen(name) - 1] = '\0';
#endif

    if (items == 1)
      mode = HRMODE;
    else
      mode = (int) SvIV(ST(1));
    cfmopdb(&status, &retval, name, mode);
    f_status = status;
    if (status != HSUCC) retval=-1;
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), retval);
  }
  XSRETURN(1);
}


XS(Fame_fameclose)
{
  dXSARGS;
  if (items != 1)
    croak("Usage: &fameclose($dbkey)");
  else {
    int             retval = 1;
    int             dbkey = (int) SvIV(ST(0));
    int             status;

    cfmcldb(&status, dbkey);
    f_status = status;
    if (status != HSUCC)
      retval = 0;
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), retval);
  }
  XSRETURN(1);
}


XS(Fame_famegetinfo)
{
  dXSARGS;
  if (items != 2)
    croak("Usage: @list=&famegetinfo($dbkey,$objnam)");
  else {
    int             retval = 1;
    int             dbkey = (int) SvIV(ST(0));
    char           *objnam = (char *) SvPV(ST(1), na);
    int             p[16], i;
    char           *p1;
    char           *p2;
    int             d1, d2;

    cfmdlen(&p[0], dbkey, objnam, &d1, &d2);
    f_status = p[0];
    if (p[0] != HSUCC) {
      /* croak("Fame error: famegetinfo failed"); */
      XSRETURN_UNDEF;  /* error in reading - prob. doesn't exist */
    }

    d1++;
    d2++;
    p1 = (char *) malloc((d1+1) * sizeof(char));
    p2 = (char *) malloc((d2+1) * sizeof(char));

    for (i = 0; i < d1; i++) {
      p1[i] = ' ';
    }
    p1[d1 - 1] = '\n';
    p1[d1] = 0;

    for (i = 0; i < d2; i++) {
      p2[i] = ' ';
    }
    p2[d2 - 1] = '\n';
    p2[d2] = 0;

    cfmwhat(&p[0], dbkey, objnam, &p[1], &p[2], &p[3], &p[4], &p[5], &p[6],
      &p[7], &p[8], &p[9], &p[10], &p[11], &p[12], &p[13], &p[14], 
      &p[15], p1, p2);
    f_status = p[0];

    if (p[0] != HSUCC) {
      /* croak("Fame error: famegetinfo failed on cfmwhats"); */
      free(p1);
      free(p2);
      XSRETURN_UNDEF;  /* error in reading */
    }

    EXTEND(sp, 17);  /* extend stack by 17 entries */
    for (i = 0; i < 15; i++) {
      ST(i) = sv_newmortal();
      sv_setiv(ST(i), p[i + 1]);
    }
    ST(15) = sv_newmortal();
    sv_setpv(ST(15), p1);
    ST(16) = sv_newmortal();
    sv_setpv(ST(16), p2);
    free(p1);
    free(p2);
  }
  XSRETURN(17);
}


XS(Fame_fameread)
{
  dXSARGS;
  if (items != 6 && items != 5)
    croak("Usage: @list=&fameread($db,$onam,[$r1,r1,r3]|[$syear,$sprd,$eyear,$eprd])");
  else {
    int             retval = 1;
    int             dbkey = (int) SvIV(ST(0));
    char           *series = (char *) SvPV(ST(1), na);

    int             status;
    int             freq, typ, class;
    int             range[3];
    int             numobs = -1;
    float          *valary;
    char          **cv;
    int            *misary;
    int            *lenary;
    float          *mistt;
    int             sz;
    int             i;
    struct vdata    dat;

    freq = famegetfreq(dbkey, series);
    typ = famegettype(dbkey, series);

    class = famegetclass(dbkey, series);
    if (class==HSERIE) {
      if (items == 6) {
        int             syear = (int) SvIV(ST(2));
        int             sprd = (int) SvIV(ST(3));
        int             eyear = (int) SvIV(ST(4));
        int             eprd = (int) SvIV(ST(5));
        cfmsrng(&status, freq, &syear, &sprd, &eyear, &eprd, range, &numobs);
        f_status = status;
        if (status != HSUCC) {
          /* fprintf(stderr,"HLI(%d)",status); */
          /* croak("Fame error: Read failed to set range"); */
          XSRETURN_UNDEF;
        }
      } else {
        range[0] = (int) SvIV(ST(2));
        range[1] = (int) SvIV(ST(3));
        range[2] = (int) SvIV(ST(4));
      }
    } else if (class==HSCALA) { 
      numobs=1;
    }

    Fame_allocate(WIN32PASS &dat, typ, numobs);
    status = Fame_readitems(&dat, dbkey, series, range);

    if (status != HSUCC) {
      Fame_free(WIN32PASS &dat);
      XSRETURN_UNDEF;
    }

    EXTEND(sp, numobs);

    for (i = 0; i < numobs; i++) {
      ST(i) = sv_newmortal();
      Fame_setSV(WIN32PASS ST(i), typ, dat.val.pf, i);
    }

    Fame_free(WIN32PASS &dat);

    if (numobs > 0) { XSRETURN(numobs); } 
    else            { XSRETURN_UNDEF; }
  }
  XSRETURN_UNDEF;
}


XS(Fame_famereadn)
{
  dXSARGS;
  if (items != 10)
    croak("Usage: @list=&famereadn($dbkey,$objnam,$num,$r1,$r2,$r3,$tmiss,$m1,$m2,$m3)");
  else {
    int             retval = 1;
    int             dbkey = (int) SvIV(ST(0));
    char           *series = (char *) SvPV(ST(1), na);
    int             numobs = (int) SvIV(ST(2));
    int             tmiss = (int) SvIV(ST(6));

    int             i;
    int             sz;
    int            *misary;
    int            *lenary;

    int             status;
    int             typ;
    int             syear;
    int             sprd;
    struct vdata    dat;

    int             range[3];

    range[0] = (int) SvIV(ST(3));
    range[1] = (int) SvIV(ST(4));
    range[2] = (int) SvIV(ST(5));

    typ = famegettype(dbkey, series);

    Fame_setVAL(WIN32PASS ST(7), typ, dat.mistt.pf, 0);
    Fame_setVAL(WIN32PASS ST(8), typ, dat.mistt.pf, 1);
    Fame_setVAL(WIN32PASS ST(9), typ, dat.mistt.pf, 2);

    Fame_allocate(WIN32PASS &dat, typ, numobs);
    status = Fame_readitems(&dat, dbkey, series, range);

    if (status != HSUCC) {
      Fame_free(WIN32PASS &dat);
      XSRETURN_UNDEF;
    }

    EXTEND(sp, numobs);

    for (i = 0; i < numobs; i++) {
      ST(i) = sv_newmortal();
      Fame_setSV(WIN32PASS ST(i), typ, dat.val.pf, i);
    }

    Fame_free(WIN32PASS &dat);

    if (numobs > 0) { XSRETURN(numobs); }
    else            { XSRETURN_UNDEF; }
  }
  XSRETURN_UNDEF;
}


XS(Fame_famewrite)
{
  dXSARGS;
  if (items <= 4)
    croak("Usage: &famewrite($dbkey,$objnam,$year,$prd,@list)");
  else {
    int             retval = 1;
    int             dbkey = (int) SvIV(ST(0));
    char           *series = (char *) SvPV(ST(1), na);
    int             year = (int) SvIV(ST(2));
    int             prd = (int) SvIV(ST(3));
    int             eyear = -1;
    int             eprd = -1;

    int             status;
    int             freq;
    int             range[3];
    int             numobs;
    struct vdata    dat;
    float          *mistt;
    int             typ;
    int             sz;
    char           *ss;
    int             i;

    numobs = items - 4;

    freq = famegetfreq(dbkey, series);
    if (f_status != HSUCC) {
      /* croak("Fame error: unsupported data type"); */
      ST(0)=sv_newmortal();
      sv_setiv(ST(0), f_status);
      XSRETURN(1);
    }
    typ = famegettype(dbkey, series);
    cfmsrng(&status, freq, &year, &prd, &eyear, &eprd, range, &numobs);
    f_status = status;

    Fame_allocate(WIN32PASS &dat, typ, numobs);

    for (i = 0; i < numobs; i++) {
      Fame_setVAL(WIN32PASS ST(i+4), typ, dat.val.pf, i);
    }

    f_status = Fame_writeitems(&dat, dbkey, series, range);

    Fame_free(WIN32PASS &dat);

    ST(0)=sv_newmortal();
    sv_setiv(ST(0), status);
  }
  XSRETURN(1);
}

#ifdef ADJDIV

XS(Fame_famecalladj) 
{
  dXSARGS;
  if (items < 7)
    croak("Usage: ($stat,@series) = &famecalladj($call,$ticker,$prc_key,$div_key,$start,$end,$po_flag)");
  else {
    int             retval = 1;
    char           *call = (char *) SvPV(ST(0), na);
    char           *ticker = (char *) SvPV(ST(1), na);
    int             prc_key = (int) SvIV(ST(2));
    int             div_key = (int) SvIV(ST(3));
    int             start = (int) SvIV(ST(4));
    int             end = (int) SvIV(ST(5));
    int             po_flag = (int) SvIV(ST(6));
    int             typ;
    int             numobs;
    int             i;
    struct vdata    dat;
    
    numobs = end-start+1;

    if (strcmp(call, "adjdiv")==0) {
      typ = HNUMRC;
      Fame_allocate(WIN32PASS &dat, typ, numobs);
      retval = adjdiv(ticker, prc_key, div_key, start, end, po_flag, dat.val.pf);
    }
    else if (strcmp(call, "rtnser")==0) {
      typ = HNUMRC;
      Fame_allocate(WIN32PASS &dat, typ, numobs);
      retval = rtnser(ticker, prc_key, div_key, start, end, po_flag, dat.val.pf);
    }
    else if (strcmp(call, "totret")==0) {
      typ = HPRECN;
      Fame_allocate(WIN32PASS &dat, typ, numobs);
      retval = totret(ticker, prc_key, div_key, start, end, po_flag, dat.val.pd);
    }
    else if (strcmp(call, "acp")==0) {
      typ = HNUMRC;
      Fame_allocate(WIN32PASS &dat, typ, numobs);
      retval = acp(ticker, prc_key, div_key, start, end, po_flag, dat.val.pf);
    }
    else {
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), -10);
      Fame_free(WIN32PASS &dat);
      XSRETURN(1);
    }

    EXTEND(sp, numobs + 1);

    ST(0) = sv_newmortal();
    sv_setiv(ST(0), retval);

    for (i = 0; i < numobs; i++) {
      ST(i+1) = sv_newmortal();
    Fame_setSV(WIN32PASS ST(i+1), typ, dat.val.pf, i);
    }

    Fame_free(WIN32PASS &dat);

    XSRETURN(numobs+1);
  }
  XSRETURN_UNDEF;
}

#endif


XS(boot_Fame__HLI)
{
  dXSARGS;
  char           *fn = __FILE__;
  int status;

#include "fameinit.i"

  /* set up constants for the autoloader */
  newXS("Fame::HLI::constant", Fame_constant, fn);

  /* register BEGIN, but it won't call it for some reason, so
     added cfmini below */
  /* newXS("Fame::HLI::BEGIN", Fame_famestart, fn); */
  /* it will, however, call END when terminating */
  /* newXS("Fame::HLI::END", Fame_famestop, fn); */

  newXS("Fame::HLI::famestart", Fame_famestart, fn);
  newXS("Fame::HLI::famestop", Fame_famestop, fn);
  newXS("Fame::HLI::cfmgatt", Fame_cfmgatt, fn);
  newXS("Fame::HLI::cfmsatt", Fame_cfmsatt, fn);
  newXS("Fame::HLI::fameopen", Fame_fameopen, fn);
  newXS("Fame::HLI::fameclose", Fame_fameclose, fn);
  newXS("Fame::HLI::fameread", Fame_fameread, fn);
  newXS("Fame::HLI::famereadn", Fame_famereadn, fn);
  newXS("Fame::HLI::famewrite", Fame_famewrite, fn);
  newXS("Fame::HLI::famegetinfo", Fame_famegetinfo, fn);
#ifdef ADJDIV
  newXS("Fame::HLI::famecalladj", Fame_famecalladj, fn);
#endif

  cfmini(&status);
  if (status != HSUCC) {
    fprintf(stderr, "Fame CHLI not initialized [%d]!\n", status);
    if (getenv("FAME")==NULL) {
      fprintf(stderr, "Please set your FAME environment variable\n");
    }
    errno=status;
    ST(0) = &sv_no;
  } else {
    ST(0) = &sv_yes;
  }
  XSRETURN(1);
}

