#ifndef UU_COMPARE_H
#define UU_COMPARE_H

#include "ulib/UUID.h"

IV uu_cmp_struct1(const struct_uu1_t *us1, const struct_uu1_t *us2);
IV uu_cmp_struct4(const struct_uu4_t *us1, const struct_uu4_t *us2);
IV uu_cmp_struct6(const struct_uu6_t *us1, const struct_uu6_t *us2);
IV uu_cmp_struct7(const struct_uu7_t *us1, const struct_uu7_t *us2);
IV uu_cmp_binary(const uu_t uu1, const uu_t uu2);

#endif
/* ex:set ts=2 sw=2 itab=spaces: */
