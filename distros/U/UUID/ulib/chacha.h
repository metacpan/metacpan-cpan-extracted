#ifndef UU_CHACHA_H
#define UU_CHACHA_H

#include "ulib/UUID.h"

void cc_srand(pUCXT, Pid_t pid);

void cc_rand16(pUCXT, U16 *out);
void cc_rand32(pUCXT, U32 *out);
void cc_rand64(pUCXT, U64 *out);
void cc_rand128(pUCXT, void *out);

#endif
/* ex:set ts=2 sw=2 itab=spaces: */
