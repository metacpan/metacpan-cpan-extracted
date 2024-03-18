#ifndef UU_GEN_H
#define UU_GEN_H

#include "ulib/UUID.h"

void uu_gen_init(pUCXT);
void uu_gen_setrand(pUCXT);
void uu_gen_setuniq(pUCXT);

int uu_realnode(pUCXT, struct_uu1_t *out);

void uu_v0gen(pUCXT, struct_uu1_t *out);
void uu_v1gen(pUCXT, struct_uu1_t *out);
void uu_v4gen(pUCXT, struct_uu4_t *out);
void uu_v6gen(pUCXT, struct_uu6_t *out);
void uu_v7gen(pUCXT, struct_uu7_t *out);

#endif
/* ex:set ts=2 sw=2 itab=spaces: */
