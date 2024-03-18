#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/unparse.h"

#ifdef __cplusplus
}
#endif

static const char *fmt_lower = "0123456789abcdef";
static const char *fmt_upper = "0123456789ABCDEF";

#ifdef UUID_UNPARSE_DEFAULT_UPPER
#define FMT_DEFAULT fmt_upper
#else
#define FMT_DEFAULT fmt_lower
#endif

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

static void uu_unparse_x0(const struct_uu1_t *in, char *out, const char *fmt) {
  char *dst = out;

  uu_u64_2hex(in->members.time_low,              dst, 8, fmt); dst += 8; *dst++ = '-';
  uu_u64_2hex(in->members.time_mid,              dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->members.time_high_and_version, dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->members.clock_seq_and_variant, dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->members.node[0],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->members.node[1],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->members.node[2],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->members.node[3],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->members.node[4],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->members.node[5],               dst, 2, fmt); dst += 2;
  *dst = 0;
}

void uu_unparse_lower0(const struct_uu1_t *in, char *out) {
  uu_unparse_x0(in, out,  fmt_lower);
}

void uu_unparse_upper0(const struct_uu1_t *in, char *out) {
  uu_unparse_x0(in, out, fmt_upper);
}

void uu_unparse0(const struct_uu1_t *in, char *out) {
  uu_unparse_x0(in, out, FMT_DEFAULT);
}

static void uu_unparse_x1(const struct_uu1_t *in, char *out, const char *fmt) {
  char *dst = out;

  uu_u64_2hex(in->members.time_low,              dst, 8, fmt); dst += 8; *dst++ = '-';
  uu_u64_2hex(in->members.time_mid,              dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->members.time_high_and_version, dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->members.clock_seq_and_variant, dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->members.node[0],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->members.node[1],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->members.node[2],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->members.node[3],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->members.node[4],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->members.node[5],               dst, 2, fmt); dst += 2;
  *dst = 0;
}

void uu_unparse_lower1(const struct_uu1_t *in, char *out) {
  uu_unparse_x1(in, out,  fmt_lower);
}

void uu_unparse_upper1(const struct_uu1_t *in, char *out) {
  uu_unparse_x1(in, out, fmt_upper);
}

void uu_unparse1(const struct_uu1_t *in, char *out) {
  uu_unparse_x1(in, out, FMT_DEFAULT);
}

static void uu_unparse_x4(const struct_uu4_t *in, char *out, const char *fmt) {
  char *dst = out;

  uu_u64_2hex(in->members.rand_a,                      dst, 8, fmt); dst += 8; *dst++ = '-';
  uu_u64_2hex(in->members.rand_b_and_version >> 16,    dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->members.rand_b_and_version & 0xffff, dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->members.rand_c_and_variant >> 16,    dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->members.rand_c_and_variant & 0xffff, dst, 4, fmt); dst += 4;
  uu_u64_2hex(in->members.rand_d,                      dst, 8, fmt); dst += 8;
  *dst = 0;
}

void uu_unparse_lower4(const struct_uu4_t *in, char *out) {
  uu_unparse_x4(in, out,  fmt_lower);
}

void uu_unparse_upper4(const struct_uu4_t *in, char *out) {
  uu_unparse_x4(in, out, fmt_upper);
}

void uu_unparse4(const struct_uu4_t *in, char *out) {
  uu_unparse_x4(in, out, FMT_DEFAULT);
}

static void uu_unparse_x6(const struct_uu6_t *in, char *out, const char *fmt) {
  char *dst = out;

  uu_u64_2hex(in->members.time_high,             dst, 8, fmt); dst += 8; *dst++ = '-';
  uu_u64_2hex(in->members.time_mid,              dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->members.time_low_and_version,  dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->members.clock_seq_and_variant, dst, 4, fmt); dst += 4; *dst++ = '-';
  uu_u64_2hex(in->members.node[0],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->members.node[1],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->members.node[2],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->members.node[3],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->members.node[4],               dst, 2, fmt); dst += 2;
  uu_u64_2hex(in->members.node[5],               dst, 2, fmt); dst += 2;
  *dst = 0;
}

void uu_unparse_lower6(const struct_uu6_t *in, char *out) {
  uu_unparse_x6(in, out,  fmt_lower);
}

void uu_unparse_upper6(const struct_uu6_t *in, char *out) {
  uu_unparse_x6(in, out, fmt_upper);
}

void uu_unparse6(const struct_uu6_t *in, char *out) {
  uu_unparse_x6(in, out, FMT_DEFAULT);
}

static void uu_unparse_x7(const struct_uu7_t *in, char *out, const char *fmt) {
  char *dst = out;

  uu_u64_2hex(in->members.time_high,                              dst,  8, fmt); dst +=  8; *dst++ = '-';
  uu_u64_2hex(in->members.time_low,                               dst,  4, fmt); dst +=  4; *dst++ = '-';
  uu_u64_2hex(in->members.rand_a_and_version,                     dst,  4, fmt); dst +=  4; *dst++ = '-';
  uu_u64_2hex(in->members.rand_b_and_variant >> 48,               dst,  4, fmt); dst +=  4; *dst++ = '-';
  uu_u64_2hex(in->members.rand_b_and_variant & 0xffffffffffffULL, dst, 12, fmt); dst += 12;
  *dst = 0;
}

void uu_unparse_lower7(const struct_uu7_t *in, char *out) {
  uu_unparse_x7(in, out,  fmt_lower);
}

void uu_unparse_upper7(const struct_uu7_t *in, char *out) {
  uu_unparse_x7(in, out, fmt_upper);
}

void uu_unparse7(const struct_uu7_t *in, char *out) {
  uu_unparse_x7(in, out, FMT_DEFAULT);
}

/* ex:set ts=2 sw=2 itab=spaces: */
