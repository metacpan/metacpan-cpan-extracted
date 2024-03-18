#ifndef UU_UTIL_H
#define UU_UTIL_H

#include "ulib/UUID.h"

NV uu_time(const struct_uu1_t *in);
UV uu_type(const struct_uu1_t *in);
UV uu_variant(const struct_uu1_t *in);

#endif
/* ex:set ts=2 sw=2 itab=spaces: */
