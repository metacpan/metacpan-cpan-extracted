#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/splitmix.h"
#include "ulib/gettime.h"
#include "ulib/sysrand.h"

#ifdef __cplusplus
}
#endif

/* based on splitmix64
 * https://xorshift.di.unimi.it/splitmix64.c
*/

void uu_splitmix_srand(pUCXT) {
  unsigned int  n;
  UV            ptod[2];
  U64           sysrand;

  /* gettimeofday(&tv, 0); */
  (*uu_gettime_U2time)(aTHX_ ptod);
  SMEM->sm_x = (U64)ptod[0] * 1000000
    + (U64)ptod[1];

  /* stir 16 - 31 times, time-based */
  n = 16 + ((ptod[0] ^ ptod[1]) & 0x0f);
  while (n-- > 0)
    (void)uu_splitmix_rand(aUCXT);

  uu_sysrand_bytes(&sysrand, 8);
  SMEM->sm_x ^= sysrand;

  /* stir 16 - 31 times, rand-based */
  n = 16 + (sysrand & 0x0f);
  while (n-- > 0)
    (void)uu_splitmix_rand(aUCXT);
}

U64 uu_splitmix_rand(pUCXT) {
  U64 z = (SMEM->sm_x += 0x9e3779b97f4a7c15ULL);
  z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9ULL;
  z = (z ^ (z >> 27)) * 0x94d049bb133111ebULL;
  return z ^ (z >> 31);
}

/* ex:set ts=2 sw=2 itab=spaces: */
