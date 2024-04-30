#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/isnull.h"

#ifdef __cplusplus
}
#endif

IV uu_isnull_binary(const uu_t in)
{
  const U8  *cp = in;
  IV        i;

  for (i=0; i<sizeof(uu_t); i++)
    if (*cp++)
      return 0;
  return 1;
}

IV uu_isnull_struct(const struct_uu_t *in) {
  if (in->v0.low)  return 0;
  if (in->v0.high) return 0;
  return 1;
}

/* ex:set ts=2 sw=2 itab=spaces: */
