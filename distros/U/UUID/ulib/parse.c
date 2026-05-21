#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/parse.h"

#ifdef __cplusplus
}
#endif

IV uu_parse(const char *in, struct_uu_t *out) {
  int         i;
  const char  *cp;
  char        buf[3];

  if (strlen(in) != 36)
    return -1;
  for (i=0, cp = in; i <= 36; i++,cp++) {
    if ((i == 8) || (i == 13) || (i == 18) || (i == 23)) {
      if (*cp == '-')
        continue;
      return -1;
    }
    if (i == 36 && *cp == 0)
      continue;
    if (!isxdigit((int)*cp))
      return -1;
  }
  out->v1.time_low              = strtoul(in, NULL, 16);
  out->v1.time_mid              = (U16)strtoul(in+9, NULL, 16);
  out->v1.time_high_and_version = (U16)strtoul(in+14, NULL, 16);
  out->v1.clock_seq_and_variant = (U16)strtoul(in+19, NULL, 16);
  cp = in+24;
  buf[2] = 0;
  for (i=0; i < 6; i++) {
    buf[0] = *cp++;
    buf[1] = *cp++;
    out->v1.node[i] = (U8)strtoul(buf, NULL, 16);
  }

  return 0;
}


const char *uu_parse_unparse_fmt_lower = "0123456789abcdef";
const char *uu_parse_unparse_fmt_upper = "0123456789ABCDEF";

/* convert U64 to hex chars. */
static void uu_u64_2hex(const U64 in, char *out, const int len, const char *fmt) {
  U64 n = in;
  int i = len;

  do {
    out[--i] = fmt[n % 16];
    n >>= 4;
  } while (n > 0);

  while (i > 0)
    out[--i] = '0';
}

void uu_parse_unparse_x0(const struct_uu_t *in, char *out, const char *fmt) {
  char *dst = out;

  uu_u64_2hex(in->v1.time_low,              dst, 8, fmt); dst += 8; *dst++ = '-';
  uu_u64_2hex(in->v1.time_mid,              dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->v1.time_high_and_version, dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->v1.clock_seq_and_variant, dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->v1.node[0],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->v1.node[1],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->v1.node[2],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->v1.node[3],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->v1.node[4],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->v1.node[5],               dst, 2, fmt); dst += 2;
  *dst = 0;
}

void uu_parse_unparse_x1(const struct_uu_t *in, char *out, const char *fmt) {
  char *dst = out;

  uu_u64_2hex(in->v1.time_low,              dst, 8, fmt); dst += 8; *dst++ = '-';
  uu_u64_2hex(in->v1.time_mid,              dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->v1.time_high_and_version, dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->v1.clock_seq_and_variant, dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->v1.node[0],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->v1.node[1],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->v1.node[2],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->v1.node[3],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->v1.node[4],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->v1.node[5],               dst, 2, fmt); dst += 2;
  *dst = 0;
}

void uu_parse_unparse_x3(const struct_uu_t *in, char *out, const char *fmt) {
  char *dst = out;

  uu_u64_2hex(in->v1.time_low,              dst, 8, fmt); dst += 8; *dst++ = '-';
  uu_u64_2hex(in->v1.time_mid,              dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->v1.time_high_and_version, dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->v1.clock_seq_and_variant, dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->v1.node[0],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->v1.node[1],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->v1.node[2],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->v1.node[3],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->v1.node[4],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->v1.node[5],               dst, 2, fmt); dst += 2;
  *dst = 0;
}

void uu_parse_unparse_x4(const struct_uu_t *in, char *out, const char *fmt) {
  char *dst = out;

  uu_u64_2hex(in->v4.rand_a,                      dst, 8, fmt); dst += 8; *dst++ = '-';
  uu_u64_2hex(in->v4.rand_b_and_version >> 16,    dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->v4.rand_b_and_version & 0xffff, dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->v4.rand_c_and_variant >> 16,    dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->v4.rand_c_and_variant & 0xffff, dst, 4, fmt); dst += 4;
  uu_u64_2hex(in->v4.rand_d,                      dst, 8, fmt); dst += 8;
  *dst = 0;
}

void uu_parse_unparse_x5(const struct_uu_t *in, char *out, const char *fmt) {
  char *dst = out;

  uu_u64_2hex(in->v1.time_low,              dst, 8, fmt); dst += 8; *dst++ = '-';
  uu_u64_2hex(in->v1.time_mid,              dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->v1.time_high_and_version, dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->v1.clock_seq_and_variant, dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->v1.node[0],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->v1.node[1],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->v1.node[2],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->v1.node[3],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->v1.node[4],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->v1.node[5],               dst, 2, fmt); dst += 2;
  *dst = 0;
}

void uu_parse_unparse_x6(const struct_uu_t *in, char *out, const char *fmt) {
  char *dst = out;

  uu_u64_2hex(in->v6.time_high,             dst, 8, fmt); dst += 8; *dst++ = '-';
  uu_u64_2hex(in->v6.time_mid,              dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->v6.time_low_and_version,  dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->v6.clock_seq_and_variant, dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->v6.node[0],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->v6.node[1],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->v6.node[2],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->v6.node[3],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->v6.node[4],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->v6.node[5],               dst, 2, fmt); dst += 2;
  *dst = 0;
}

void uu_parse_unparse_x7(const struct_uu_t *in, char *out, const char *fmt) {
  char *dst = out;

  uu_u64_2hex(in->v7.time_high,                              dst,  8, fmt); dst +=  8; *dst++ = '-';
  uu_u64_2hex(in->v7.time_low,                               dst,  4, fmt); dst +=  4; *dst++ = '-';
  uu_u64_2hex(in->v7.rand_a_and_version,                     dst,  4, fmt); dst +=  4; *dst++ = '-';
  uu_u64_2hex(in->v7.rand_b_and_variant >> 48,               dst,  4, fmt); dst +=  4; *dst++ = '-';
  uu_u64_2hex(in->v7.rand_b_and_variant & 0xffffffffffffULL, dst, 12, fmt); dst += 12;
  *dst = 0;
}

/* ex:set ts=2 sw=2 itab=spaces: */
