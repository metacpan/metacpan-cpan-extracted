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

IV uu_isnull_struct(const struct_uu1_t *in) {
  if (in->members.time_low)              return 0;
  if (in->members.time_mid)              return 0;
  if (in->members.time_high_and_version) return 0;
  if (in->members.clock_seq_and_variant) return 0;
  if (in->members.node[0])               return 0;
  if (in->members.node[1])               return 0;
  if (in->members.node[2])               return 0;
  if (in->members.node[3])               return 0;
  if (in->members.node[4])               return 0;
  if (in->members.node[5])               return 0;
  return 1;
}

/* ex:set ts=2 sw=2 itab=spaces: */
