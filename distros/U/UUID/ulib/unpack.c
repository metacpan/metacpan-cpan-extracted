#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/unpack.h"

#ifdef __cplusplus
}
#endif

void uu_unpack(const uu_t in, struct_uu1_t *out) {
  const U8  *ptr = in;
  U32       tmp;

  tmp = *ptr++;
  tmp = (tmp << 8) | *ptr++;
  tmp = (tmp << 8) | *ptr++;
  tmp = (tmp << 8) | *ptr++;
  out->members.time_low = tmp;

  tmp = *ptr++;
  tmp = (tmp << 8) | *ptr++;
  out->members.time_mid = (U16)tmp;

  tmp = *ptr++;
  tmp = (tmp << 8) | *ptr++;
  out->members.time_high_and_version = (U16)tmp;

  tmp = *ptr++;
  tmp = (tmp << 8) | *ptr++;
  out->members.clock_seq_and_variant = (U16)tmp;

  out->members.node[0] = *ptr++;
  out->members.node[1] = *ptr++;
  out->members.node[2] = *ptr++;
  out->members.node[3] = *ptr++;
  out->members.node[4] = *ptr++;
  out->members.node[5] = *ptr;
}

/* ex:set ts=2 sw=2 itab=spaces: */
