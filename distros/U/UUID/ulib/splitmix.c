#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/splitmix.h"
#include "ulib/gettime.h"

#ifdef __cplusplus
}
#endif

/* based on splitmix64
 * https://xorshift.di.unimi.it/splitmix64.c
*/

/* called from boot */
void sm_srand(pUCXT) {
  unsigned int  n;
  UV            ptod[2];

  /* gettimeofday(&tv, 0); */
  (*UCXT.myU2time)(aTHX_ (UV*)&ptod);

  /*
   * The idea is just to have a unique value here,
   * so system time and process id should be enough.
   * (Provided system time doesn't repeat!)
   *
   * Unix epoch time with usec resolution is 51 bits,
   * leaving 13 bits for pid. We'll use the lower 13
   * bits from getpid().
  */
  UCXT.sm_x = (U64)ptod[0] * 1000000
    + (U64)ptod[1]
    + ((U64)getpid() << 51);

  /* stir 8 - 39 times */
  n = 8 + ((ptod[0] ^ ptod[1]) & 0x1f);

  while (n-- > 0)
    (void)sm_rand(aUCXT);
}

U64 sm_rand(pUCXT) {
  U64 z = (UCXT.sm_x += 0x9e3779b97f4a7c15ULL);
  z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9ULL;
  z = (z ^ (z >> 27)) * 0x94d049bb133111ebULL;
  return z ^ (z >> 31);
}

/* ex:set ts=2 sw=2 itab=spaces: */
