#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/util.h"

#ifdef __cplusplus
}
#endif

static NV uu_time_v1(const struct_uu1_t *in) {
  U64   sum;
  NV    rv;

  sum = ((U64)in->members.time_high_and_version & 0x0fff) << 48
    | ((U64)in->members.time_mid) << 32
    | (U64)in->members.time_low;
  sum -= 122192928000000000ULL;
  rv = (NV)sum / 10000000.0;

  return rv;
}

static NV uu_time_v4(const struct_uu4_t *in) {
  return 0.0;
}

static NV uu_time_v6(const struct_uu6_t *in) {
  U64   sum;
  NV    rv;

  sum = ((U64)in->members.time_high) << 28
    | ((U64)in->members.time_mid) << 12
    | ((U64)in->members.time_low_and_version & 0x0fff);
  sum -= 122192928000000000ULL;
  rv = (NV)sum / 10000000.0;

  return rv;
}

static NV uu_time_v7(const struct_uu7_t *in) {
  U64   sum;
  NV    rv;

  sum = ((U64)in->members.time_high) << 16
    | (U64)in->members.time_low;
  rv = (NV)sum / 1000.0;

  return rv;
}


NV uu_time(const struct_uu1_t *in) {
  int version;

  version = in->members.time_high_and_version >> 12;

  switch(version) {
    case 1: return uu_time_v1(in);
    case 4: return uu_time_v4((struct_uu4_t*)in);
    case 6: return uu_time_v6((struct_uu6_t*)in);
    case 7: return uu_time_v7((struct_uu7_t*)in);
  }
  return 0;
}

/* a.k.a. version */
UV uu_type(const struct_uu1_t *in) {
  UV  type;

  type = in->members.time_high_and_version >> 12;

  if (type <= 8)
    return type;
  return 0;
}

UV uu_variant(const struct_uu1_t *in) {
  U16 variant;

  variant = in->members.clock_seq_and_variant;

  if ((variant & 0x8000) == 0) return 0;
  if ((variant & 0x4000) == 0) return 1;
  if ((variant & 0x2000) == 0) return 2;
  return 3;
}

/* ex:set ts=2 sw=2 itab=spaces: */
