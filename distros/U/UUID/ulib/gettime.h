#ifndef ULIB__GETTIME_H
#define ULIB__GETTIME_H

#include "ulib/UUID.h"

void uu_gettime_init(pUCXT);
U64  uu_gettime_100ns64(pUCXT);

extern void (*uu_gettime_U2time)(pTHX_ UV ret[2]);

#endif
/* ex:set ts=2 sw=2 itab=spaces: */
