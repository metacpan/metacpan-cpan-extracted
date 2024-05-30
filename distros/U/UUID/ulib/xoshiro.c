#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/xoshiro.h"
#include "ulib/splitmix.h"

#ifdef __cplusplus
}
#endif

/* based on xoshiro256++
 * https://prng.di.unimi.it/xoshiro256plusplus.c
*/

#define xo_rotl(x,k) (((x) << (k)) | ((x) >> (64 - (k))))

void xo_srand(pUCXT, Pid_t pid) {
  U64 n, *xo_s = UCXT.xo_s;

  (void)pid;

  xo_s[0] = sm_rand(aUCXT);
  xo_s[1] = sm_rand(aUCXT);
  xo_s[2] = sm_rand(aUCXT);
  xo_s[3] = sm_rand(aUCXT);

  /* stir 16 - 31 times */
  n = 16 + (sm_rand(aUCXT) >> 60);
  while (n-- > 0)
    (void)xo_rand(aUCXT);
}

U64 xo_rand(pUCXT) {
  U64 *xo_s = UCXT.xo_s;

  const U64 result = xo_rotl(xo_s[0] + xo_s[3], 23) + xo_s[0];

  const U64 t = xo_s[1] << 17;

  xo_s[2] ^= xo_s[0];
  xo_s[3] ^= xo_s[1];
  xo_s[1] ^= xo_s[2];
  xo_s[0] ^= xo_s[3];

  xo_s[2] ^= t;

  xo_s[3] = xo_rotl(xo_s[3], 45);

  return result;
}

/* ex:set ts=2 sw=2 itab=spaces: */
