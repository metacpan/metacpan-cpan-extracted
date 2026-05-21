#ifndef ULIB__HASH_H
#define ULIB__HASH_H

#include "ulib/UUID.h"

void uu_hash_md5(pUCXT, struct_uu_t *out, char *name);
void uu_hash_sha1(pUCXT, struct_uu_t *out, char *name);

#endif
/* ex:set ts=2 sw=2 itab=spaces: */
