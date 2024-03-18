#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/gen.h"
#include "ulib/chacha.h"
#include "ulib/clock.h"
#include "ulib/node.h"

#ifdef __cplusplus
}
#endif


/* randomize uu_node */
static void uu_gen_randomize(pUCXT) {
  cc_rand32(aUCXT, (U32*)&UCXT.gen_node[0]);
  cc_rand16(aUCXT, (U16*)&UCXT.gen_node[4]);
  UCXT.gen_node[0] |= 0x01; /* set mcast */
}

/* call at boot */
void uu_gen_init(pUCXT) {
  UCXT.gen_epoch = (((U64) 0x01B21DD2) << 32) | 0x13814000; /* unused */
  UCXT.gen_use_unique = 0;
  UCXT.gen_has_real_node = 0;
  UCXT.gen_node[0] = 0;;
  UCXT.gen_node[1] = 0;;
  UCXT.gen_node[2] = 0;;
  UCXT.gen_node[3] = 0;;
  UCXT.gen_node[4] = 0;;
  UCXT.gen_node[5] = 0;;
  UCXT.gen_real_node[0] = 0;
  UCXT.gen_real_node[1] = 0;
  UCXT.gen_real_node[2] = 0;
  UCXT.gen_real_node[3] = 0;
  UCXT.gen_real_node[4] = 0;
  UCXT.gen_real_node[5] = 0;

  /* get the real node or randomize it */
  if (uu_get_node_id(aUCXT, (U8*)&UCXT.gen_node) == 1) {
    UCXT.gen_has_real_node = 1;
    UCXT.gen_real_node[0] = UCXT.gen_node[0];
    UCXT.gen_real_node[1] = UCXT.gen_node[1];
    UCXT.gen_real_node[2] = UCXT.gen_node[2];
    UCXT.gen_real_node[3] = UCXT.gen_node[3];
    UCXT.gen_real_node[4] = UCXT.gen_node[4];
    UCXT.gen_real_node[5] = UCXT.gen_node[5];
  }
  else {
    UCXT.gen_has_real_node = 0;
    uu_gen_randomize(aUCXT);
  }
}

void uu_gen_setrand(pUCXT) {
  UCXT.gen_use_unique = 0;
  uu_gen_randomize(aUCXT);
}

void uu_gen_setuniq(pUCXT) {
  UCXT.gen_use_unique = 1;
}

/* returns 1 if has real node, or 0 */
int uu_realnode(pUCXT, struct_uu1_t *out) {
  uu_v0gen(aUCXT, out);
  out->members.node[0] = UCXT.gen_real_node[0];
  out->members.node[1] = UCXT.gen_real_node[1];
  out->members.node[2] = UCXT.gen_real_node[2];
  out->members.node[3] = UCXT.gen_real_node[3];
  out->members.node[4] = UCXT.gen_real_node[4];
  out->members.node[5] = UCXT.gen_real_node[5];
  return UCXT.gen_has_real_node;
}


void uu_v0gen(pUCXT, struct_uu1_t *out) {
  out->members.time_low = 0;
  out->members.time_mid = 0;
  out->members.time_high_and_version = 0;
  out->members.clock_seq_and_variant = 0;
  out->members.node[0] = 0;
  out->members.node[1] = 0;
  out->members.node[2] = 0;
  out->members.node[3] = 0;
  out->members.node[4] = 0;
  out->members.node[5] = 0;
}

void uu_v1gen(pUCXT, struct_uu1_t *out) {
  U64   clock_reg;
  U16   clock_seq;

  uu_clock(aUCXT, &clock_reg, &clock_seq);
  clock_reg += (((U64)0x01b21dd2) << 32) + 0x13814000;

  out->members.time_low              = (U32)clock_reg;
  out->members.time_mid              = (U16)(clock_reg >> 32 & 0xffff);
  out->members.time_high_and_version = (U16)(clock_reg >> 48 & 0x0fff | 0x1000);
  out->members.clock_seq_and_variant = clock_seq & 0x3fff | 0x8000;

  if (UCXT.gen_use_unique) uu_gen_randomize(aUCXT);
  out->members.node[0] = UCXT.gen_node[0];
  out->members.node[1] = UCXT.gen_node[1];
  out->members.node[2] = UCXT.gen_node[2];
  out->members.node[3] = UCXT.gen_node[3];
  out->members.node[4] = UCXT.gen_node[4];
  out->members.node[5] = UCXT.gen_node[5];
}

void uu_v4gen(pUCXT, struct_uu4_t *out) {
  U64 *cp = (U64*)out;

  cc_rand64(aUCXT, cp++);
  cc_rand64(aUCXT, cp);
  out->members.rand_b_and_version = out->members.rand_b_and_version & 0xffff0fff | 0x00004000;
  out->members.rand_c_and_variant = out->members.rand_c_and_variant & 0x3fffffff | 0x80000000;
}

void uu_v6gen(pUCXT, struct_uu6_t *out) {
  U64   clock_reg;
  U16   clock_seq;

  uu_clock(aUCXT, &clock_reg, &clock_seq);
  clock_reg += (((U64)0x01b21dd2) << 32) + 0x13814000;

  out->members.time_high             = (U32)(clock_reg >> 28);
  out->members.time_mid              = (U16)(clock_reg >> 12);
  out->members.time_low_and_version  = (U16)clock_reg & 0x0fff | 0x6000;
  out->members.clock_seq_and_variant = clock_seq & 0x3fff | 0x8000;

  /* use the same node as v1 */
  if (UCXT.gen_use_unique) uu_gen_randomize(aUCXT);
  out->members.node[0] = UCXT.gen_node[0];
  out->members.node[1] = UCXT.gen_node[1];
  out->members.node[2] = UCXT.gen_node[2];
  out->members.node[3] = UCXT.gen_node[3];
  out->members.node[4] = UCXT.gen_node[4];
  out->members.node[5] = UCXT.gen_node[5];
}

void uu_v7gen(pUCXT, struct_uu7_t *out) {
  U64   clock_reg;
  U16   clock_seq;

  uu_clock(aUCXT, &clock_reg, &clock_seq);
  clock_reg /= 10000;

  cc_rand16(aUCXT, &out->members.rand_a_and_version);
  cc_rand64(aUCXT, &out->members.rand_b_and_variant);
  out->members.time_high             = (U32)(clock_reg >> 16);
  out->members.time_low              = (U16)(clock_reg & 0xffff);
  out->members.rand_a_and_version = out->members.rand_a_and_version & 0x0fff | 0x7000;
  out->members.rand_b_and_variant = out->members.rand_b_and_variant
    & 0x3fffffffffffffffULL
    | 0x8000000000000000ULL;
}

/* ex:set ts=2 sw=2 itab=spaces: */
