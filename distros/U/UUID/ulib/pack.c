#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/pack.h"

#ifdef __cplusplus
}
#endif

void uu_pack0(const struct_uu1_t *in, uu_t out) {
  uu_pack1(in, out);
}

void uu_pack1(const struct_uu1_t *in, uu_t out) {
  U32 tmp;
  //U8  *out = ptr;

  tmp = in->members.time_low;
  out[3] = (U8)tmp; tmp >>= 8;
  out[2] = (U8)tmp; tmp >>= 8;
  out[1] = (U8)tmp; tmp >>= 8;
  out[0] = (U8)tmp;

  tmp = in->members.time_mid;
  out[5] = (U8)tmp; tmp >>= 8;
  out[4] = (U8)tmp;

  tmp = in->members.time_high_and_version;
  out[7] = (U8)tmp; tmp >>= 8;
  out[6] = (U8)tmp;

  tmp = in->members.clock_seq_and_variant;
  out[9] = (U8)tmp; tmp >>= 8;
  out[8] = (U8)tmp;

  memcpy(out+10, in->members.node, 6);
}

void uu_pack4(const struct_uu4_t *in, uu_t out) {
  U32 tmp;

  tmp = in->members.rand_a;
  out[ 3] = (U8)tmp; tmp >>= 8;
  out[ 2] = (U8)tmp; tmp >>= 8;
  out[ 1] = (U8)tmp; tmp >>= 8;
  out[ 0] = (U8)tmp;

  tmp = in->members.rand_b_and_version;
  out[ 7] = (U8)tmp; tmp >>= 8;
  out[ 6] = (U8)tmp; tmp >>= 8;
  out[ 5] = (U8)tmp; tmp >>= 8;
  out[ 4] = (U8)tmp;

  tmp = in->members.rand_c_and_variant;
  out[11] = (U8)tmp; tmp >>= 8;
  out[10] = (U8)tmp; tmp >>= 8;
  out[ 9] = (U8)tmp; tmp >>= 8;
  out[ 8] = (U8)tmp;

  tmp = in->members.rand_d;
  out[15] = (U8)tmp; tmp >>= 8;
  out[14] = (U8)tmp; tmp >>= 8;
  out[13] = (U8)tmp; tmp >>= 8;
  out[12] = (U8)tmp;
}

void uu_pack6(const struct_uu6_t *in, uu_t out) {
  U32 tmp;

  tmp = in->members.time_high;
  out[3] = (U8)tmp; tmp >>= 8;
  out[2] = (U8)tmp; tmp >>= 8;
  out[1] = (U8)tmp; tmp >>= 8;
  out[0] = (U8)tmp;

  tmp = in->members.time_mid;
  out[5] = (U8)tmp; tmp >>= 8;
  out[4] = (U8)tmp;

  tmp = in->members.time_low_and_version;
  out[7] = (U8)tmp; tmp >>= 8;
  out[6] = (U8)tmp;

  tmp = in->members.clock_seq_and_variant;
  out[9] = (U8)tmp; tmp >>= 8;
  out[8] = (U8)tmp;

  memcpy(out+10, in->members.node, 6);
}

void uu_pack7(const struct_uu7_t *in, uu_t out) {
  U64 tmp;

  tmp = in->members.time_high;
  out[3] = (U8)tmp; tmp >>= 8;
  out[2] = (U8)tmp; tmp >>= 8;
  out[1] = (U8)tmp; tmp >>= 8;
  out[0] = (U8)tmp;

  tmp = in->members.time_low;
  out[5] = (U8)tmp; tmp >>= 8;
  out[4] = (U8)tmp;

  tmp = in->members.rand_a_and_version;
  out[7] = (U8)tmp; tmp >>= 8;
  out[6] = (U8)tmp;

  tmp = in->members.rand_b_and_variant;
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
