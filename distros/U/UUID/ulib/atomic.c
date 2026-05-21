#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/atomic.h"

#ifdef __cplusplus
}
#endif

#if defined(__OpenBSD__)
# if defined(__arm__)
#  include "ulib/arch/arm/atomic.c"
# elif defined(__amd64__) || defined(__x86_64__)
#  include "ulib/arch/x86/atomic.c"
# else
#  error "unsupported architecture"
# endif
#endif

/* ex:set ts=2 sw=2 itab=spaces: */
