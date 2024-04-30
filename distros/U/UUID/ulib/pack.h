#ifndef UU_PACK_H
#define UU_PACK_H

#include "ulib/UUID.h"

/* pack uuid struct into uu string, big-endian */
void uu_pack0(const struct_uu_t *in, uu_t out);
void uu_pack1(const struct_uu_t *in, uu_t out);
void uu_pack3(const struct_uu_t *in, uu_t out);
void uu_pack4(const struct_uu_t *in, uu_t out);
void uu_pack5(const struct_uu_t *in, uu_t out);
void uu_pack6(const struct_uu_t *in, uu_t out);
void uu_pack7(const struct_uu_t *in, uu_t out);

#endif
/* ex:set ts=2 sw=2 itab=spaces: */
