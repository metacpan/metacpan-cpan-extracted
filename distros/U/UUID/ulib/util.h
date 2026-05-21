#ifndef ULIB__UTIL_H
#define ULIB__UTIL_H

#include "ulib/UUID.h"

void my_croak_caller(const char *pat, ...);
void uu_clear(struct_uu_t *io);
void uu_copy_binary(pUCXT, const uu_t in, uu_t out);
void uu_copy_struct(pUCXT, const struct_uu_t *in, struct_uu_t *out);
NV uu_time(const struct_uu_t *in);
UV uu_type(const struct_uu_t *in);
UV uu_variant(const struct_uu_t *in);

#endif
/* ex:set ts=2 sw=2 itab=spaces: */
