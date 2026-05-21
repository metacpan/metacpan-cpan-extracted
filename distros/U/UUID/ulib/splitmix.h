#ifndef ULIB__SPLITMIX_H
#define ULIB__SPLITMIX_H

#include "ulib/UUID.h"

void uu_splitmix_srand(pUCXT);
U64  uu_splitmix_rand(pUCXT);

#endif
/* ex:set ts=2 sw=2 itab=spaces: */
