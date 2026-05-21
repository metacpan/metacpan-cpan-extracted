#ifndef ULIB__GEN_H
#define ULIB__GEN_H

#include "ulib/UUID.h"

void uu_gen_init(pUCXT);
void uu_gen_setrand(pUCXT);
void uu_gen_setuniq(pUCXT);

int uu_gen_realnode(pUCXT, struct_uu_t *out);

void uu_gen_v0(pUCXT, struct_uu_t *out, char *dptr);
void uu_gen_v1(pUCXT, struct_uu_t *out, char *dptr);
void uu_gen_v3(pUCXT, struct_uu_t *out, char *dptr);
void uu_gen_v4(pUCXT, struct_uu_t *out, char *dptr);
void uu_gen_v5(pUCXT, struct_uu_t *out, char *dptr);
void uu_gen_v6(pUCXT, struct_uu_t *out, char *dptr);
void uu_gen_v7(pUCXT, struct_uu_t *out, char *dptr);

#endif
/* ex:set ts=2 sw=2 itab=spaces: */
