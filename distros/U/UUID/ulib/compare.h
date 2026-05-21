#ifndef ULIB__COMPARE_H
#define ULIB__COMPARE_H

#include "ulib/UUID.h"

IV uu_compare_struct0(const struct_uu_t *us1, const struct_uu_t *us2);
IV uu_compare_struct1(const struct_uu_t *us1, const struct_uu_t *us2);
IV uu_compare_struct3(const struct_uu_t *us1, const struct_uu_t *us2);
IV uu_compare_struct4(const struct_uu_t *us1, const struct_uu_t *us2);
IV uu_compare_struct5(const struct_uu_t *us1, const struct_uu_t *us2);
IV uu_compare_struct6(const struct_uu_t *us1, const struct_uu_t *us2);
IV uu_compare_struct7(const struct_uu_t *us1, const struct_uu_t *us2);
IV uu_compare_binary(const uu_t uu1, const uu_t uu2);

IV uu_compare_isnull_binary(const uu_t in);
IV uu_compare_isnull_struct(const struct_uu_t *in);

#endif
/* ex:set ts=2 sw=2 itab=spaces: */
