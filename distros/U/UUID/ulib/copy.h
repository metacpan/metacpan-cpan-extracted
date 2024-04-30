#ifndef UU_COPY_H
#define UU_COPY_H

#include "ulib/UUID.h"

void uu_copy_binary(pUCXT, const uu_t in, uu_t out);
void uu_copy_struct(pUCXT, const struct_uu_t *in, struct_uu_t *out);

#endif
/* ex:set ts=2 sw=2 itab=spaces: */
