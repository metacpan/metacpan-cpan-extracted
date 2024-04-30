#ifndef UU_UNPACK_H
#define UU_UNPACK_H

#include "ulib/UUID.h"

/* unpack uu string, big-endian, to uuid struct */
void uu_unpack(const uu_t in, struct_uu_t *out);

#endif
/* ex:set ts=2 sw=2 itab=spaces: */
