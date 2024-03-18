#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/copy.h"

#ifdef __cplusplus
}
#endif

void uu_copy_binary(pUCXT, const uu_t in, uu_t out) {
  U8  *cp1 = (U8*)&in;
  U8  *cp2 = out;
  UV  i;

  for (i=0; i < 16; i++)
    *cp1++ = *cp2++;
}

void uu_copy_struct(pUCXT, const struct_uu1_t *in, struct_uu1_t *out) {
  out->members.time_low = in->members.time_low;
  out->members.time_mid = in->members.time_mid;
  out->members.time_high_and_version = in->members.time_high_and_version;
  out->members.clock_seq_and_variant = in->members.clock_seq_and_variant;
  out->members.node[0] = in->members.node[0];
  out->members.node[1] = in->members.node[1];
  out->members.node[2] = in->members.node[2];
  out->members.node[3] = in->members.node[3];
  out->members.node[4] = in->members.node[4];
  out->members.node[5] = in->members.node[5];
}

/* ex:set ts=2 sw=2 itab=spaces: */
