#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/compare.h"
#include "ulib/pack.h"
#include "ulib/util.h"

#ifdef __cplusplus
}
#endif

#define UUCMP(u1,u2) if (u1 != u2) return((u1) > (u2) ? 1 : -1);

IV uu_compare_struct0(const struct_uu_t *us1, const struct_uu_t *us2) {
  UUCMP(us1->v0.low, us2->v0.low);
  UUCMP(us1->v0.high, us2->v0.high);
  return 0;
}

IV uu_compare_struct1(const struct_uu_t *us1, const struct_uu_t *us2) {
  UUCMP(us1->v1.time_low, us2->v1.time_low);
  UUCMP(us1->v1.time_mid, us2->v1.time_mid);
  UUCMP(us1->v1.time_high_and_version, us2->v1.time_high_and_version);
  UUCMP(us1->v1.clock_seq_and_variant, us2->v1.clock_seq_and_variant);
  return memcmp(us1->v1.node, us2->v1.node, 6);
}

IV uu_compare_struct3(const struct_uu_t *us1, const struct_uu_t *us2) {
  UUCMP(us1->v3.md5_high32, us2->v3.md5_high32);
  UUCMP(us1->v3.md5_high16, us2->v3.md5_high16);
  UUCMP(us1->v3.md5_mid_and_version, us2->v3.md5_mid_and_version);
  UUCMP(us1->v3.md5_low_and_variant, us2->v3.md5_low_and_variant);
  UUCMP(us1->v3.md5_low, us2->v3.md5_low);
  return 0;
}

IV uu_compare_struct4(const struct_uu_t *us1, const struct_uu_t *us2) {
  UUCMP(us1->v4.rand_a, us2->v4.rand_a);
  UUCMP(us1->v4.rand_b_and_version, us2->v4.rand_b_and_version);
  UUCMP(us1->v4.rand_c_and_variant, us2->v4.rand_c_and_variant);
  UUCMP(us1->v4.rand_d, us2->v4.rand_d);
  return 0;
}

IV uu_compare_struct5(const struct_uu_t *us1, const struct_uu_t *us2) {
  UUCMP(us1->v5.sha1_high32, us2->v5.sha1_high32);
  UUCMP(us1->v5.sha1_high16, us2->v5.sha1_high16);
  UUCMP(us1->v5.sha1_mid_and_version, us2->v5.sha1_mid_and_version);
  UUCMP(us1->v5.sha1_low_and_variant, us2->v5.sha1_low_and_variant);
  UUCMP(us1->v5.sha1_low, us2->v5.sha1_low);
  return 0;
}

IV uu_compare_struct6(const struct_uu_t *us1, const struct_uu_t *us2) {
  UUCMP(us1->v6.time_high, us2->v6.time_high);
  UUCMP(us1->v6.time_mid,  us2->v6.time_mid );
  UUCMP(us1->v6.time_low_and_version,  us2->v6.time_low_and_version );
  UUCMP(us1->v6.clock_seq_and_variant, us2->v6.clock_seq_and_variant);
  return memcmp(us1->v6.node, us2->v6.node, 6);
  return 0;
}

IV uu_compare_struct7(const struct_uu_t *us1, const struct_uu_t *us2) {
  UUCMP(us1->v7.time_high, us2->v7.time_high);
  UUCMP(us1->v7.time_low,  us2->v7.time_low );
  UUCMP(us1->v7.rand_a_and_version, us2->v7.rand_a_and_version);
  UUCMP(us1->v7.rand_b_and_variant, us2->v7.rand_b_and_variant);
  return 0;
}

IV uu_compare_binary(const uu_t uu1, const uu_t uu2) {
  IV            typ1, typ2, var1, var2;
	struct_uu_t   us1, us2;

	uu_pack_unpack(uu1, &us1);
	uu_pack_unpack(uu2, &us2);

  var1 = uu_variant(&us1);
  var2 = uu_variant(&us2);

  if (var1 != var2)
    return var1 > var2 ? 1 : -1;

  typ1 = uu_type(&us1);
  typ2 = uu_type(&us2);

  if (typ1 != typ2)
    return typ1 > typ2 ? 1 : -1;

  switch(typ1) {
    case 1: return uu_compare_struct1(&us1, &us2);
    case 3: return uu_compare_struct3(&us1, &us2);
    case 4: return uu_compare_struct4(&us1, &us2);
    case 5: return uu_compare_struct5(&us1, &us2);
    case 6: return uu_compare_struct6(&us1, &us2);
    case 7: return uu_compare_struct7(&us1, &us2);
  }

  /* handles null and unknown types */
  return uu_compare_struct0(&us1, &us2);
}


IV uu_compare_isnull_binary(const uu_t in)
{
  const U8  *cp = in;
  IV        i;

  for (i=0; i<sizeof(uu_t); i++)
    if (*cp++)
      return 0;
  return 1;
}

IV uu_compare_isnull_struct(const struct_uu_t *in) {
  if (in->v0.low)  return 0;
  if (in->v0.high) return 0;
  return 1;
}

/* ex:set ts=2 sw=2 itab=spaces: */
