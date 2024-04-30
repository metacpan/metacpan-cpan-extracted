#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/compare.h"
#include "ulib/unpack.h"
#include "ulib/util.h"

#ifdef __cplusplus
}
#endif

#define UUCMP(u1,u2) if (u1 != u2) return((u1) > (u2) ? 1 : -1);

IV uu_cmp_struct1(const struct_uu_t *us1, const struct_uu_t *us2) {
  UUCMP(us1->v1.time_low, us2->v1.time_low);
  UUCMP(us1->v1.time_mid, us2->v1.time_mid);
  UUCMP(us1->v1.time_high_and_version, us2->v1.time_high_and_version);
  UUCMP(us1->v1.clock_seq_and_variant, us2->v1.clock_seq_and_variant);
  return memcmp(us1->v1.node, us2->v1.node, 6);
}

/* XXX missing v3 */

IV uu_cmp_struct4(const struct_uu_t *us1, const struct_uu_t *us2) {
  UUCMP(us1->v4.rand_a, us2->v4.rand_a);
  UUCMP(us1->v4.rand_b_and_version, us2->v4.rand_b_and_version);
  UUCMP(us1->v4.rand_c_and_variant, us2->v4.rand_c_and_variant);
  UUCMP(us1->v4.rand_d, us2->v4.rand_d);
  return 0;
}

/* XXX missing v5 */

IV uu_cmp_struct6(const struct_uu_t *us1, const struct_uu_t *us2) {
  UUCMP(us1->v6.time_high, us2->v6.time_high);
  UUCMP(us1->v6.time_mid,  us2->v6.time_mid );
  UUCMP(us1->v6.time_low_and_version,  us2->v6.time_low_and_version );
  UUCMP(us1->v6.clock_seq_and_variant, us2->v6.clock_seq_and_variant);
  return memcmp(us1->v6.node, us2->v6.node, 6);
  return 0;
}

IV uu_cmp_struct7(const struct_uu_t *us1, const struct_uu_t *us2) {
  UUCMP(us1->v7.time_high, us2->v7.time_high);
  UUCMP(us1->v7.time_low,  us2->v7.time_low );
  UUCMP(us1->v7.rand_a_and_version, us2->v7.rand_a_and_version);
  UUCMP(us1->v7.rand_b_and_variant, us2->v7.rand_b_and_variant);
  return 0;
}

IV uu_cmp_binary(const uu_t uu1, const uu_t uu2) {
  IV            typ1, typ2, var1, var2;
	struct_uu_t   us1, us2;

	uu_unpack(uu1, &us1);
	uu_unpack(uu2, &us2);

  var1 = uu_variant(&us1);
  var2 = uu_variant(&us2);

  if (var1 != var2)
    return var1 > var2 ? 1 : -1;

  typ1 = uu_type(&us1);
  typ2 = uu_type(&us2);

  if (typ1 != typ2)
    return typ1 > typ2 ? 1 : -1;

  switch(typ1) {
    case 1: return uu_cmp_struct1(&us1, &us2);
    case 4: return uu_cmp_struct4(&us1, &us2);
    case 6: return uu_cmp_struct6(&us1, &us2);
    case 7: return uu_cmp_struct7(&us1, &us2);
  }

  //return uu_cmp_struct(&us1, &us2);
  return 0;
}

/* ex:set ts=2 sw=2 itab=spaces: */
