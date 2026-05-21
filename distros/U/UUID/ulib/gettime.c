#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/gettime.h"

#ifdef __cplusplus
}
#endif


void (*uu_gettime_U2time)(pTHX_ UV ret[2]);

/* called at boot */
void uu_gettime_init(pUCXT) {
  SV **svp;
  require_pv("Time/HiRes.pm");
  svp = hv_fetchs(PL_modglobal, "Time::U2time", 0);
  if (!svp)         croak("Time::HiRes is required");
  if (!SvIOK(*svp)) croak("Time::U2time isn't a function pointer");
  uu_gettime_U2time = INT2PTR(void(*)(pTHX_ UV ret[2]), SvIV(*svp));
/*
  if (0) {
    UV  xx[2];
    (*uu_gettime_U2time)(aTHX_ xx);
    printf("The current seconds are: %" UVuf ".%06" UVuf "\n", xx[0], xx[1]);
    exit(0);
  }
*/
}

U64 uu_gettime_100ns64(pUCXT) {
  struct timeval  tv;
  U64             rv;
  UV              ptod[2];

  /* gettimeofday(&tv, 0); */
  (*uu_gettime_U2time)(aTHX_ ptod);
  tv.tv_sec  = (long)ptod[0];
  tv.tv_usec = (long)ptod[1];

  rv = tv.tv_sec * 10000000 + tv.tv_usec * 10;
  return rv;
}

/* ex:set ts=2 sw=2 itab=spaces: */
