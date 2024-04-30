#ifndef UU_GEN_H
#define UU_GEN_H

#include "ulib/UUID.h"

void uu_gen_init(pUCXT);
void uu_gen_setrand(pUCXT);
void uu_gen_setuniq(pUCXT);

int uu_realnode(pUCXT, struct_uu_t *out);

void uu_v0gen(pUCXT, struct_uu_t *out, char *dptr);
void uu_v1gen(pUCXT, struct_uu_t *out, char *dptr);
void uu_v3gen(pUCXT, struct_uu_t *out, char *dptr);
void uu_v4gen(pUCXT, struct_uu_t *out, char *dptr);
void uu_v5gen(pUCXT, struct_uu_t *out, char *dptr);
void uu_v6gen(pUCXT, struct_uu_t *out, char *dptr);
void uu_v7gen(pUCXT, struct_uu_t *out, char *dptr);

#endif
/* ex:set ts=2 sw=2 itab=spaces: */
