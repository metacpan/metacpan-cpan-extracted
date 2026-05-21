#ifndef ULIB__PARSE_H
#define ULIB__PARSE_H

#include "ulib/UUID.h"

IV uu_parse(const char *in, struct_uu_t *out);

extern const char *uu_parse_unparse_fmt_lower;
extern const char *uu_parse_unparse_fmt_upper;

#ifdef UUID_UNPARSE_DEFAULT_UPPER
#define UU_UNPARSE_FMT_DEFAULT uu_parse_unparse_fmt_upper
#else
#define UU_UNPARSE_FMT_DEFAULT uu_parse_unparse_fmt_lower
#endif

void uu_parse_unparse_x0(const struct_uu_t *in, char *out, const char *fmt);
#define uu_parse_unparse_lower0(in, out)  uu_parse_unparse_x0((in), (out), uu_parse_unparse_fmt_lower)
#define uu_parse_unparse_upper0(in, out)  uu_parse_unparse_x0((in), (out), uu_parse_unparse_fmt_upper)
#define uu_parse_unparse_v0(in, out)      uu_parse_unparse_x0((in), (out), UU_UNPARSE_FMT_DEFAULT)

void uu_parse_unparse_x1(const struct_uu_t *in, char *out, const char *fmt);
#define uu_parse_unparse_lower1(in, out)  uu_parse_unparse_x1((in), (out), uu_parse_unparse_fmt_lower)
#define uu_parse_unparse_upper1(in, out)  uu_parse_unparse_x1((in), (out), uu_parse_unparse_fmt_upper)
#define uu_parse_unparse_v1(in, out)      uu_parse_unparse_x1((in), (out), UU_UNPARSE_FMT_DEFAULT)

void uu_parse_unparse_x3(const struct_uu_t *in, char *out, const char *fmt);
#define uu_parse_unparse_lower3(in, out)  uu_parse_unparse_x3((in), (out), uu_parse_unparse_fmt_lower)
#define uu_parse_unparse_upper3(in, out)  uu_parse_unparse_x3((in), (out), uu_parse_unparse_fmt_upper)
#define uu_parse_unparse_v3(in, out)      uu_parse_unparse_x3((in), (out), UU_UNPARSE_FMT_DEFAULT)

void uu_parse_unparse_x4(const struct_uu_t *in, char *out, const char *fmt);
#define uu_parse_unparse_lower4(in, out)  uu_parse_unparse_x4((in), (out), uu_parse_unparse_fmt_lower)
#define uu_parse_unparse_upper4(in, out)  uu_parse_unparse_x4((in), (out), uu_parse_unparse_fmt_upper)
#define uu_parse_unparse_v4(in, out)      uu_parse_unparse_x4((in), (out), UU_UNPARSE_FMT_DEFAULT)

void uu_parse_unparse_x5(const struct_uu_t *in, char *out, const char *fmt);
#define uu_parse_unparse_lower5(in, out)  uu_parse_unparse_x5((in), (out), uu_parse_unparse_fmt_lower)
#define uu_parse_unparse_upper5(in, out)  uu_parse_unparse_x5((in), (out), uu_parse_unparse_fmt_upper)
#define uu_parse_unparse_v5(in, out)      uu_parse_unparse_x5((in), (out), UU_UNPARSE_FMT_DEFAULT)

void uu_parse_unparse_x6(const struct_uu_t *in, char *out, const char *fmt);
#define uu_parse_unparse_lower6(in, out)  uu_parse_unparse_x6((in), (out), uu_parse_unparse_fmt_lower)
#define uu_parse_unparse_upper6(in, out)  uu_parse_unparse_x6((in), (out), uu_parse_unparse_fmt_upper)
#define uu_parse_unparse_v6(in, out)      uu_parse_unparse_x6((in), (out), UU_UNPARSE_FMT_DEFAULT)

void uu_parse_unparse_x7(const struct_uu_t *in, char *out, const char *fmt);
#define uu_parse_unparse_lower7(in, out)  uu_parse_unparse_x7((in), (out), uu_parse_unparse_fmt_lower)
#define uu_parse_unparse_upper7(in, out)  uu_parse_unparse_x7((in), (out), uu_parse_unparse_fmt_upper)
#define uu_parse_unparse_v7(in, out)      uu_parse_unparse_x7((in), (out), UU_UNPARSE_FMT_DEFAULT)

#endif
/* ex:set ts=2 sw=2 itab=spaces: */
