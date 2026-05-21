#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/chacha.h"
#include "ulib/clock.h"
#include "ulib/gen.h"
#include "ulib/hash.h"
#include "ulib/node.h"

#ifdef __cplusplus
}
#endif


/* randomize uu_node */
static void uu_gen_randomize(pUCXT) {
  uu_chacha_rand32(aUCXT, (U32*)&SMEM->gen_node[0]);
  uu_chacha_rand16(aUCXT, (U16*)&SMEM->gen_node[4]);
  SMEM->gen_node[0] |= 0x01; /* set mcast */
}

/* call at boot */
void uu_gen_init(pUCXT) {
  SMEM->gen_epoch = (((U64) 0x01B21DD2) << 32) | 0x13814000; /* unused */
  SMEM->gen_use_unique = 0;
  SMEM->gen_has_real_node = 0;
  SMEM->gen_node[0] = 0;;
  SMEM->gen_node[1] = 0;;
  SMEM->gen_node[2] = 0;;
  SMEM->gen_node[3] = 0;;
  SMEM->gen_node[4] = 0;;
  SMEM->gen_node[5] = 0;;
  SMEM->gen_real_node[0] = 0;
  SMEM->gen_real_node[1] = 0;
  SMEM->gen_real_node[2] = 0;
  SMEM->gen_real_node[3] = 0;
  SMEM->gen_real_node[4] = 0;
  SMEM->gen_real_node[5] = 0;

  /* get the real node or randomize it */
  if (uu_node_getid(aUCXT, (U8*)&SMEM->gen_node) == 1) {
    SMEM->gen_has_real_node = 1;
    SMEM->gen_real_node[0] = SMEM->gen_node[0];
    SMEM->gen_real_node[1] = SMEM->gen_node[1];
    SMEM->gen_real_node[2] = SMEM->gen_node[2];
    SMEM->gen_real_node[3] = SMEM->gen_node[3];
    SMEM->gen_real_node[4] = SMEM->gen_node[4];
    SMEM->gen_real_node[5] = SMEM->gen_node[5];
  }
  else {
    SMEM->gen_has_real_node = 0;
    uu_gen_randomize(aUCXT);
  }
}

void uu_gen_setrand(pUCXT) {
  SMEM->gen_use_unique = 0;
  uu_gen_randomize(aUCXT);
}

void uu_gen_setuniq(pUCXT) {
  SMEM->gen_use_unique = 1;
}

/* returns 1 if has real node, or 0 */
int uu_gen_realnode(pUCXT, struct_uu_t *out) {
  uu_gen_v0(aUCXT, out, NULL);
  out->v1.node[0] = SMEM->gen_real_node[0];
  out->v1.node[1] = SMEM->gen_real_node[1];
  out->v1.node[2] = SMEM->gen_real_node[2];
  out->v1.node[3] = SMEM->gen_real_node[3];
  out->v1.node[4] = SMEM->gen_real_node[4];
  out->v1.node[5] = SMEM->gen_real_node[5];
  return SMEM->gen_has_real_node;
}


void uu_gen_v0(pUCXT, struct_uu_t *out, char *dptr) {
  out->v0.low  = 0;
  out->v0.high = 0;
}

void uu_gen_v1(pUCXT, struct_uu_t *out, char *dptr) {
  U64   clock_reg;
  U16   clock_seq;

  uu_clock(aUCXT, &clock_reg, &clock_seq);
  clock_reg += (((U64)0x01b21dd2) << 32) + 0x13814000;

  out->v1.time_low              = (U32)clock_reg;
  out->v1.time_mid              = (U16)(clock_reg >> 32 & 0xffff);
  out->v1.time_high_and_version = (U16)((clock_reg >> 48 & 0x0fff) | 0x1000);
  out->v1.clock_seq_and_variant = (clock_seq & 0x3fff) | 0x8000;

  if (SMEM->gen_use_unique) uu_gen_randomize(aUCXT);
  out->v1.node[0] = SMEM->gen_node[0];
  out->v1.node[1] = SMEM->gen_node[1];
  out->v1.node[2] = SMEM->gen_node[2];
  out->v1.node[3] = SMEM->gen_node[3];
  out->v1.node[4] = SMEM->gen_node[4];
  out->v1.node[5] = SMEM->gen_node[5];
}

void uu_gen_v3(pUCXT, struct_uu_t *out, char *dptr) {
  /* out points to a v1 uuid to use as namespace. */
  /* out also points to output buffer for v3 uuid. */
  /* dptr points to string to use as name. */
  uu_hash_md5(aUCXT, out, dptr);
}

void uu_gen_v4(pUCXT, struct_uu_t *out, char *dptr) {
  U64 *cp = (U64*)out;

  uu_chacha_rand64(aUCXT, cp++);
  uu_chacha_rand64(aUCXT, cp);
  out->v4.rand_b_and_version = (out->v4.rand_b_and_version & 0xffff0fff) | 0x00004000;
  out->v4.rand_c_and_variant = (out->v4.rand_c_and_variant & 0x3fffffff) | 0x80000000;
}

void uu_gen_v5(pUCXT, struct_uu_t *out, char *dptr) {
  /* out points to a v1 uuid to use as namespace. */
  /* out also points to output buffer for v5 uuid. */
  /* dptr points to string to use as name. */
  uu_hash_sha1(aUCXT, out, dptr);
}

void uu_gen_v6(pUCXT, struct_uu_t *out, char *dptr) {
  U64   clock_reg;
  U16   clock_seq;

  uu_clock(aUCXT, &clock_reg, &clock_seq);
  clock_reg += (((U64)0x01b21dd2) << 32) + 0x13814000;

  out->v6.time_high             = (U32)(clock_reg >> 28);
  out->v6.time_mid              = (U16)(clock_reg >> 12);
  out->v6.time_low_and_version  = (U16)(clock_reg & 0x0fff) | 0x6000;
  out->v6.clock_seq_and_variant = (clock_seq & 0x3fff) | 0x8000;

  /* use the same node as v1 */
  if (SMEM->gen_use_unique) uu_gen_randomize(aUCXT);
  out->v6.node[0] = SMEM->gen_node[0];
  out->v6.node[1] = SMEM->gen_node[1];
  out->v6.node[2] = SMEM->gen_node[2];
  out->v6.node[3] = SMEM->gen_node[3];
  out->v6.node[4] = SMEM->gen_node[4];
  out->v6.node[5] = SMEM->gen_node[5];
}

void uu_gen_v7(pUCXT, struct_uu_t *out, char *dptr) {
  U64   clock_reg;
  U16   clock_seq;

  uu_clock(aUCXT, &clock_reg, &clock_seq);
  clock_reg /= 10000;

  uu_chacha_rand16(aUCXT, &out->v7.rand_a_and_version);
  uu_chacha_rand64(aUCXT, &out->v7.rand_b_and_variant);
  out->v7.time_high             = (U32)(clock_reg >> 16);
  out->v7.time_low              = (U16)(clock_reg & 0xffff);
  out->v7.rand_a_and_version = (out->v7.rand_a_and_version & 0x0fff) | 0x7000;
  out->v7.rand_b_and_variant = (out->v7.rand_b_and_variant & 0x3fffffffffffffffULL) | 0x8000000000000000ULL;
}

/* ex:set ts=2 sw=2 itab=spaces: */
