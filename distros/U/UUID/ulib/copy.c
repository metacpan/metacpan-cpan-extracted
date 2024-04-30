#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/copy.h"

#ifdef __cplusplus
}
#endif

void uu_copy_binary(pUCXT, const uu_t in, uu_t out) {
  /* XXX use Copy */
  U8  *cp1 = (U8*)&in;
  U8  *cp2 = out;
  UV  i;

  for (i=0; i < 16; i++)
    *cp1++ = *cp2++;
}

void uu_copy_struct(pUCXT, const struct_uu_t *in, struct_uu_t *out) {
  /* XXX use Copy */
  out->v1.time_low = in->v1.time_low;
  out->v1.time_mid = in->v1.time_mid;
  out->v1.time_high_and_version = in->v1.time_high_and_version;
  out->v1.clock_seq_and_variant = in->v1.clock_seq_and_variant;
  out->v1.node[0] = in->v1.node[0];
  out->v1.node[1] = in->v1.node[1];
  out->v1.node[2] = in->v1.node[2];
  out->v1.node[3] = in->v1.node[3];
  out->v1.node[4] = in->v1.node[4];
  out->v1.node[5] = in->v1.node[5];
}

/* ex:set ts=2 sw=2 itab=spaces: */
