#ifndef ULIB__PACK_H
#define ULIB__PACK_H

#include "ulib/UUID.h"

/* pack uuid struct into uu string, big-endian */
void uu_pack_v0(const struct_uu_t *in, uu_t out);
void uu_pack_v1(const struct_uu_t *in, uu_t out);
void uu_pack_v3(const struct_uu_t *in, uu_t out);
void uu_pack_v4(const struct_uu_t *in, uu_t out);
void uu_pack_v5(const struct_uu_t *in, uu_t out);
void uu_pack_v6(const struct_uu_t *in, uu_t out);
void uu_pack_v7(const struct_uu_t *in, uu_t out);

/* unpack uu string, big-endian, to uuid struct */
void uu_pack_unpack(const uu_t in, struct_uu_t *out);

#endif
/* ex:set ts=2 sw=2 itab=spaces: */
