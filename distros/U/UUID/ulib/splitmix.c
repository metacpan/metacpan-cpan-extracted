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

void sm_srand(pUCXT, Pid_t pid) {
  unsigned int  n;
  UV            ptod[2];

  /*
   * The idea is to just have a unique value here,
   * so system time and process id should be enough.
   * (Provided system time doesn't repeat!)
   *
   * But, since Unix epoch time with usec resolution
   * is 51 bits, that only leaves 13 bits for pid.
   *
   * So, lets initially seed with TOD, mix, add the PID,
   * then mix again.
  */

  /* gettimeofday(&tv, 0); */
  (*UCXT.myU2time)(aTHX_ (UV*)&ptod);
  UCXT.sm_x = (U64)ptod[0] * 1000000
    + (U64)ptod[1];

  /* stir 16 - 31 times, pid-based */
  n = 16 + (pid & 0x0f);
  while (n-- > 0)
    (void)sm_rand(aUCXT);

  UCXT.sm_x ^= (U64)pid;

  /* stir 16 - 31 times, time-based */
  n = 16 + ((ptod[0] ^ ptod[1]) & 0x0f);
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
