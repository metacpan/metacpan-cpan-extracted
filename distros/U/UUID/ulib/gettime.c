#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/gettime.h"

#ifdef __cplusplus
}
#endif

U64 gt_100ns64(pUCXT) {
  struct timeval  tv;
  U64             rv;
  UV              ptod[2];

  /* gettimeofday(&tv, 0); */
  (*UCXT.myU2time)(aTHX_ (UV*)&ptod);
  tv.tv_sec  = (long)ptod[0];
  tv.tv_usec = (long)ptod[1];

  rv = tv.tv_sec * 10000000 + tv.tv_usec * 10;
  return rv;
}

/* ex:set ts=2 sw=2 itab=spaces: */
