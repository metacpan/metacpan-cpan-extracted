#ifndef ULIB__ATOMIC_H
#define ULIB__ATOMIC_H

#include "ulib/UUID.h"

#if defined(__arm__)
# include "ulib/arch/arm/atomic.h"
#else
# include "ulib/arch/x86/atomic.h"
#endif

#endif
/* ex:set ts=2 sw=2 itab=spaces: */
