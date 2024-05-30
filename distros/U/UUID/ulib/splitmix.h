#ifndef UU_SPLITMIX_H
#define UU_SPLITMIX_H

#include "ulib/UUID.h"

void sm_srand(pUCXT, Pid_t pid);
U64  sm_rand(pUCXT);

#endif
/* ex:set ts=2 sw=2 itab=spaces: */
