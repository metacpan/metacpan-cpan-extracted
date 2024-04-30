#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/pack.h"

#ifdef __cplusplus
}
#endif

void uu_pack0(const struct_uu_t *in, uu_t out) {
  uu_pack1(in, out);
}

void uu_pack1(const struct_uu_t *in, uu_t out) {
  U32 tmp;

  tmp = in->v1.time_low;
  out[3] = (U8)tmp; tmp >>= 8;
  out[2] = (U8)tmp; tmp >>= 8;
  out[1] = (U8)tmp; tmp >>= 8;
  out[0] = (U8)tmp;

  tmp = in->v1.time_mid;
  out[5] = (U8)tmp; tmp >>= 8;
  out[4] = (U8)tmp;

  tmp = in->v1.time_high_and_version;
  out[7] = (U8)tmp; tmp >>= 8;
  out[6] = (U8)tmp;

  tmp = in->v1.clock_seq_and_variant;
  out[9] = (U8)tmp; tmp >>= 8;
  out[8] = (U8)tmp;

  memcpy(out+10, in->v1.node, 6);
}

void uu_pack3(const struct_uu_t *in, uu_t out) {
  U32 tmp;

  tmp = in->v1.time_low;
  out[3] = (U8)tmp; tmp >>= 8;
  out[2] = (U8)tmp; tmp >>= 8;
  out[1] = (U8)tmp; tmp >>= 8;
  out[0] = (U8)tmp;

  tmp = in->v1.time_mid;
  out[5] = (U8)tmp; tmp >>= 8;
  out[4] = (U8)tmp;

  tmp = in->v1.time_high_and_version;
  out[7] = (U8)tmp; tmp >>= 8;
  out[6] = (U8)tmp;

  tmp = in->v1.clock_seq_and_variant;
  out[9] = (U8)tmp; tmp >>= 8;
  out[8] = (U8)tmp;

  memcpy(out+10, in->v1.node, 6);
}

void uu_pack4(const struct_uu_t *in, uu_t out) {
  U32 tmp;

  tmp = in->v4.rand_a;
  out[ 3] = (U8)tmp; tmp >>= 8;
  out[ 2] = (U8)tmp; tmp >>= 8;
  out[ 1] = (U8)tmp; tmp >>= 8;
  out[ 0] = (U8)tmp;

  tmp = in->v4.rand_b_and_version;
  out[ 7] = (U8)tmp; tmp >>= 8;
  out[ 6] = (U8)tmp; tmp >>= 8;
  out[ 5] = (U8)tmp; tmp >>= 8;
  out[ 4] = (U8)tmp;

  tmp = in->v4.rand_c_and_variant;
  out[11] = (U8)tmp; tmp >>= 8;
  out[10] = (U8)tmp; tmp >>= 8;
  out[ 9] = (U8)tmp; tmp >>= 8;
  out[ 8] = (U8)tmp;

  tmp = in->v4.rand_d;
  out[15] = (U8)tmp; tmp >>= 8;
  out[14] = (U8)tmp; tmp >>= 8;
  out[13] = (U8)tmp; tmp >>= 8;
  out[12] = (U8)tmp;
}

void uu_pack5(const struct_uu_t *in, uu_t out) {
  U32 tmp;

  tmp = in->v1.time_low;
  out[3] = (U8)tmp; tmp >>= 8;
  out[2] = (U8)tmp; tmp >>= 8;
  out[1] = (U8)tmp; tmp >>= 8;
  out[0] = (U8)tmp;

  tmp = in->v1.time_mid;
  out[5] = (U8)tmp; tmp >>= 8;
  out[4] = (U8)tmp;

  tmp = in->v1.time_high_and_version;
  out[7] = (U8)tmp; tmp >>= 8;
  out[6] = (U8)tmp;

  tmp = in->v1.clock_seq_and_variant;
  out[9] = (U8)tmp; tmp >>= 8;
  out[8] = (U8)tmp;

  memcpy(out+10, in->v1.node, 6);
}

void uu_pack6(const struct_uu_t *in, uu_t out) {
  U32 tmp;

  tmp = in->v6.time_high;
  out[3] = (U8)tmp; tmp >>= 8;
  out[2] = (U8)tmp; tmp >>= 8;
  out[1] = (U8)tmp; tmp >>= 8;
  out[0] = (U8)tmp;

  tmp = in->v6.time_mid;
  out[5] = (U8)tmp; tmp >>= 8;
  out[4] = (U8)tmp;

  tmp = in->v6.time_low_and_version;
  out[7] = (U8)tmp; tmp >>= 8;
  out[6] = (U8)tmp;

  tmp = in->v6.clock_seq_and_variant;
  out[9] = (U8)tmp; tmp >>= 8;
  out[8] = (U8)tmp;

  memcpy(out+10, in->v6.node, 6);
}

void uu_pack7(const struct_uu_t *in, uu_t out) {
  U64 tmp;

  tmp = in->v7.time_high;
  out[3] = (U8)tmp; tmp >>= 8;
  out[2] = (U8)tmp; tmp >>= 8;
  out[1] = (U8)tmp; tmp >>= 8;
  out[0] = (U8)tmp;

  tmp = in->v7.time_low;
  out[5] = (U8)tmp; tmp >>= 8;
  out[4] = (U8)tmp;

  tmp = in->v7.rand_a_and_version;
  out[7] = (U8)tmp; tmp >>= 8;
  out[6] = (U8)tmp;

  tmp = in->v7.rand_b_and_variant;
  out[15] = (U8)tmp; tmp >>= 8;
  out[14] = (U8)tmp; tmp >>= 8;
  out[13] = (U8)tmp; tmp >>= 8;
  out[12] = (U8)tmp; tmp >>= 8;
  out[11] = (U8)tmp; tmp >>= 8;
  out[10] = (U8)tmp; tmp >>= 8;
  out[ 9] = (U8)tmp; tmp >>= 8;
  out[ 8] = (U8)tmp;
}

/* ex:set ts=2 sw=2 itab=spaces: */
