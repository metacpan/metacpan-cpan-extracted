#ifndef UU_CLOCK_H
#define UU_CLOCK_H

#include "ulib/UUID.h"

/* Assume that the gettimeofday() has microsecond granularity */
#define MAX_ADJUSTMENT 10

void uu_clock_init(pUCXT);
void uu_init_statepath(pUCXT, const char *path);
IV   uu_clock(pUCXT, U64 *clock_reg, U16 *ret_clock_seq);

#endif
/* ex:set ts=2 sw=2 itab=spaces: */
