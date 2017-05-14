/* Copyright (c) 1997 by Fernando Trias */

#include "EXTERN.h"
#include "perl.h"
#include "hli.h"

#include "perldef.h"

#ifdef FRB
#include "hliutils.h"
#endif

#ifdef HLILIB_INC
#include "chlilib.c"
#endif

#ifdef ADJDIV
#include "adjdiv.c"
#endif

#ifdef EXPIRE
#include <sys/types.h>
#include <sys/time.h>
#endif

void 
unsupported()
{
  croak("Unsupported HLI function call");
}

int demo_expired_date() {
#ifdef EXPIRE
  return EXPIRE;
#else
  return 0;
#endif
}

int demo_expired() {
#ifdef EXPIRE
  struct tm *tm;
  time_t clock;
  int now;
 
  clock = time(NULL);
  tm = localtime(&clock);
  now = (tm->tm_year+1900)*10000 +
        tm->tm_mon * 100 +
        tm->tm_mday;
/* printf("expire check now=%d dead=%d\n", now, EXPIRE); */
  if (now > EXPIRE) {
    return 1;
  }
  return 0;
 
#else
  return 0;
#endif
}

#ifdef HAS_PROTOTYPE
void		d_cfmini(int *status)
#else
void		d_cfmini(status)
int *status;
#endif
{
  if (demo_expired()) {
    *status = 601;
    croak("FamePERL demo has expired");
  } else {
    cfmini(status);
  }
}

void            u_cfmlsts(int *a, int b, char *c, int *d, int *e) {
  croak("&cfmlsts() not implemented");
}
void            u_cfmrdfa(int *a, int b, char *c, int d, int *e, int *f, int *g, float *h, int i, float *j) {
  croak("&cfmrdfa() not implemented");
}
void            u_cfmrrng(int *a, int b, char * v, int *d, float *e, int f, float *g) {
  croak("&cfmrrng() not implemented");
}
void            u_cfmrsts() {
  croak("&cfmrsts() not implemented");
}
void            u_cfmwrng(int *a, int b, char *c, int *d, float *e, int f, float *g) {
  croak("&cfmwrng() not implemented");
}

#ifdef HAS_PROTOTYPE
void cfmrstra(
 int *status, int dbkey, char *objnam, int *r1, int *r2,
 int *r3, char *strval, int *ismiss, int *length)
#else
void
cfmrstra(status, dbkey, objnam, r1, r2, r3, strval, ismiss, length)
  int            *status;
  int             dbkey;
  char           *objnam;
  int            *r1;
  int            *r2;
  int            *r3;
  char           *strval;
  int            *ismiss;
  int            *length;
#endif
{
  int             range[3];
  range[0] = *r1;
  range[1] = *r2;
  range[2] = *r3;
  cfmrstr(status, dbkey, objnam, range, strval, ismiss, length);
  *r1 = range[0];
  *r2 = range[1];
  *r3 = range[2];
}

#ifdef HAS_PROTOTYPE
void 
cfmsbma( int *p1, int p2, int p3, int p4, int *b1, int *b2, int *b3)
#else
void 
cfmsbma(p1, p2, p3, p4, b1, b2, b3)
  int            *p1;
  int             p2;
  int             p3;
  int             p4;
  int            *b1;
  int            *b2;
  int            *b3;
#endif
{
  int             b[3];
  b[0] = *b1;
  b[1] = *b2;
  b[2] = *b3;
  cfmsbm(p1, p2, p3, p4, b);
  *b1 = b[0];
  *b2 = b[1];
  *b3 = b[2];
}

#ifdef HAS_PROTOTYPE
void 
cfmsdma( int *p1, int p2, int p3, int p4, int *b1, int *b2, int *b3)
#else
void 
cfmsdma(p1, p2, p3, p4, b1, b2, b3)
  int            *p1;
  int             p2;
  int             p3;
  int             p4;
  int            *b1;
  int            *b2;
  int            *b3;
#endif
{
  int             b[3];
  b[0] = *b1;
  b[1] = *b2;
  b[2] = *b3;
  cfmsdm(p1, p2, p3, p4, b);
  *b1 = b[0];
  *b2 = b[1];
  *b3 = b[2];
}

#ifdef HAS_PROTOTYPE
void 
cfmsfisa( int *p1, int p2, int *p3, int *p4, int *p5, int *p6,
int *r1, int *r2, int *r3, int *p7, int p8, int p9)
#else
void 
cfmsfisa(p1, p2, p3, p4, p5, p6, r1, r2, r3, p7, p8, p9)
  int            *p1;
  int             p2;
  int            *p3;
  int            *p4;
  int            *p5;
  int            *p6;
  int            *r1;
  int            *r2;
  int            *r3;
  int            *p7;
  int             p8;
  int             p9;
#endif
{
  int             r[3];
  r[0] = *r1;
  r[1] = *r2;
  r[2] = *r3;
  cfmsfis(p1, p2, p3, p4, p5, p6, r, p7, p8, p9);
  *r1 = r[0];
  *r2 = r[1];
  *r3 = r[2];
}

#ifdef HAS_PROTOTYPE
void 
cfmsnma(int *p1, float p2, float p3, float p4,
float *b1, float *b2, float *b3) 
#else
void 
cfmsnma(p1, p2, p3, p4, b1, b2, b3)
  int            *p1;
  float           p2;
  float           p3;
  float           p4;
  float          *b1;
  float          *b2;
  float          *b3;
#endif
{
  float           b[3];
  b[0] = *b1;
  b[1] = *b2;
  b[2] = *b3;
  cfmsnm(p1, p2, p3, p4, b);
  *b1 = b[0];
  *b2 = b[1];
  *b3 = b[2];
}

#ifdef HAS_PROTOTYPE
void 
cfmspma(int *p1, double p2, double p3, double p4,
double *b1, double *b2, double *b3)
#else
void 
cfmspma(p1, p2, p3, p4, b1, b2, b3)
  int            *p1;
  double          p2;
  double          p3;
  double          p4;
  double         *b1;
  double         *b2;
  double         *b3;
#endif
{
  double          b[3];
  b[0] = *b1;
  b[1] = *b2;
  b[2] = *b3;
  cfmspm(p1, p2, p3, p4, b);
  *b1 = b[0];
  *b2 = b[1];
  *b3 = b[2];
}

#ifdef HAS_PROTOTYPE
void 
cfmsrnga(
 int *p1, int p2, int *p3, int *p4, int *p5, int *p6,
 int *r1, int *r2, int *r3, int *p7)
#else
void 
cfmsrnga(p1, p2, p3, p4, p5, p6, r1, r2, r3, p7)
  int            *p1;
  int             p2;
  int            *p3;
  int            *p4;
  int            *p5;
  int            *p6;
  int            *r1;
  int            *r2;
  int            *r3;
  int            *p7;
#endif
{
  int             r[3];
  r[0] = *r1;
  r[1] = *r2;
  r[2] = *r3;
  cfmsrng(p1, p2, p3, p4, p5, p6, r, p7);
  *r1 = r[0];
  *r2 = r[1];
  *r3 = r[2];
}

#ifdef HAS_PROTOTYPE
void 
cfmwrnga(
 int *p1, int p2, char *p3, int *r1, int *r2, int *r3,
 float *p4, int p5, float *p6)
#else
void 
cfmwrnga(p1, p2, p3, r1, r2, r3, p4, p5, p6)
  int            *p1;
  int             p2;
  char           *p3;
  int            *r1;
  int            *r2;
  int            *r3;
  float          *p4;
  int             p5;
  float          *p6;
#endif
{
  int             r[3];
  r[0] = *r1;
  r[1] = *r2;
  r[2] = *r3;
  cfmwrng(p1, p2, p3, r, p4, p5, p6);
  *r1 = r[0];
  *r2 = r[1];
  *r3 = r[2];
}

#ifdef HAS_PROTOTYPE
void 
cfmwstra(
 int *p1, int p2, char *p3, int *r1, int *r2, int *r3,
 char *p4, int p5, int p6)
#else
void 
cfmwstra(p1, p2, p3, r1, r2, r3, p4, p5, p6)
  int            *p1;
  int             p2;
  char           *p3;
  int            *r1;
  int            *r2;
  int            *r3;
  char           *p4;
  int             p5;
  int             p6;
#endif
{
  int             r[3];
  r[0] = *r1;
  r[1] = *r2;
  r[2] = *r3;
  cfmwstr(p1, p2, p3, r, p4, p5, p6);
  *r1 = r[0];
  *r2 = r[1];
  *r3 = r[2];
}

#ifdef HAS_PROTOTYPE
int 
famegettype(int dbkey, char *objnam)
#else
int 
famegettype(dbkey, objnam)
  int             dbkey;
  char           *objnam;
#endif
{
  int             typ;
  int             status;
  int             c, f, b, o, fy, fp, ly, lp, cy, cm, cd, xmy, mm,
                  md;
  char            desc[100], doc[100];

  cfmwhat(&status, dbkey, objnam, &c, &typ, &f, &b, &o, &fy,
    &fp, &ly, &lp, &cy, &cm, &cd, &xmy, &mm, &md, desc, doc);
  return typ;
}

#ifdef HAS_PROTOTYPE
int 
famegetfreq(int dbkey, char *objnam)
#else
int 
famegetfreq(dbkey, objnam)
  int             dbkey;
  char           *objnam;
#endif
{
  int             freq;
  int             status;
  int             c, t, b, o, fy, fp, ly, lp, cy, cm, cd, xmy, mm,
                  md;
  char            desc[100], doc[100];

  cfmwhat(&status, dbkey, objnam, &c, &t, &freq, &b, &o, &fy,
    &fp, &ly, &lp, &cy, &cm, &cd, &xmy, &mm, &md, desc, doc);
  return freq;
}

#ifdef HAS_PROTOTYPE
int 
famegetclass(int dbkey, char *objnam)
#else
int 
famegetclass(dbkey, objnam)
  int             dbkey;
  char           *objnam;
#endif
{
  int             freq;
  int             status;
  int             c, t, b, o, fy, fp, ly, lp, cy, cm, cd, xmy, mm,
                  md;
  char            desc[100], doc[100];

  cfmwhat(&status, dbkey, objnam, &c, &t, &freq, &b, &o, &fy,
    &fp, &ly, &lp, &cy, &cm, &cd, &xmy, &mm, &md, desc, doc);
  return c;
}
