#ifndef ULIB__CHACHA_H
#define ULIB__CHACHA_H

#include "ulib/UUID.h"

void uu_chacha_srand(pUCXT);

void uu_chacha_rand16(pUCXT, U16 *out);
void uu_chacha_rand32(pUCXT, U32 *out);
void uu_chacha_rand64(pUCXT, U64 *out);
void uu_chacha_rand128(pUCXT, void *out);

#endif
/* ex:set ts=2 sw=2 itab=spaces: */
