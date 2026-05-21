/*
 * time2str formatting engine.
 *
 * Conversion specifiers:
 *
 *   %a    abbreviated day name (Mon..Sun)
 *   %b    abbreviated month name (Jan..Dec)
 *   %d    zero-padded day (01-31)
 *   %e    space-padded day ( 1-31)
 *   %-d   unpadded day (1-31)
 *   %m    zero-padded month (01-12)
 *   %y    two-digit year (00-99)
 *   %Y    four-digit year (0001-9999)
 *   %H    zero-padded hour (00-23)
 *   %M    zero-padded minute (00-59)
 *   %S    zero-padded second (00-60)
 *   %F    shorthand for %Y-%m-%d
 *   %T    shorthand for %H:%M:%S
 *   %f    fractional seconds (dot + digits from nanosecond/precision)
 *   %z    basic offset: +HHMM, zero-string for zero
 *   %Z    extended offset: +HH:MM, Z for zero
 *   %:z   extended offset: +HH:MM, +00:00 for zero
 *   %%    literal percent
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdint.h>
#include <stdbool.h>
#include "tstr_time2str.h"
#include "tstr_calendar.h"

static const char* const kShortDayName[7] = {"Mon", "Tue", "Wed", "Thu",
                                             "Fri", "Sat", "Sun"};

static const char* const kShortMonthName[12] = {"Jan", "Feb", "Mar", "Apr",
                                                "May", "Jun", "Jul", "Aug",
                                                "Sep", "Oct", "Nov", "Dec"};

static const int kPow10[10] = {
    1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000};

static void write_u40P(pTHX_ SV* dsv, unsigned int v) {
  char buf[4];
  buf[3] = '0' + v % 10; v /= 10;
  buf[2] = '0' + v % 10; v /= 10;
  buf[1] = '0' + v % 10; v /= 10;
  buf[0] = '0' + v % 10;
  sv_catpvn_nomg(dsv, buf, 4);
}

static void write_u20P(pTHX_ SV* dsv, unsigned int v) {
  char buf[2];
  buf[1] = '0' + v % 10;
  buf[0] = '0' + v / 10;
  sv_catpvn_nomg(dsv, buf, 2);
}

static void write_u2SP(pTHX_ SV* dsv, unsigned int v) {
  char buf[2];
  buf[1] = '0' + v % 10;
  buf[0] = (v >= 10) ? '0' + v / 10 : ' ';
  sv_catpvn_nomg(dsv, buf, 2);
}

static void write_u2UP(pTHX_ SV* dsv, unsigned int v) {
  char buf[2];
  if (v >= 10) {
    buf[0] = '0' + v / 10;
    buf[1] = '0' + v % 10;
    sv_catpvn_nomg(dsv, buf, 2);
  } else {
    buf[0] = '0' + v;
    sv_catpvn_nomg(dsv, buf, 1);
  }
}

static void tstr_write_fraction(pTHX_ SV* dsv, int32_t nanosecond, int precision) {
  char buf[10];
  int p, j;

  if (nanosecond <= 0 && precision < 0)
    return;

  p = precision;
  if (p < 0) {
    if      ((nanosecond % 1000000) == 0) p = 3;
    else if ((nanosecond % 1000)    == 0) p = 6;
    else                                  p = 9;
  }

  if (p == 0)
    return;

  buf[0] = '.';
  for (j = 0; j < p; j++)
    buf[j + 1] = '0' + (nanosecond / kPow10[8 - j]) % 10;
  sv_catpvn_nomg(dsv, buf, p + 1);
}

static void tstr_write_offset_basic(pTHX_ SV* dsv,
                                    int32_t offset,
                                    const char* zulu,
                                    STRLEN zulu_len) {
  char buf[5];
  int sign, h, m;

  if (offset == 0 && zulu) {
    sv_catpvn_nomg(dsv, zulu, zulu_len);
    return;
  }

  if (offset < 0)
    sign = '-', offset = -offset;
  else
    sign = '+';

  h = offset / 60;
  m = offset % 60;

  buf[0] = (char)sign;
  buf[1] = '0' + h / 10;
  buf[2] = '0' + h % 10;
  buf[3] = '0' + m / 10;
  buf[4] = '0' + m % 10;
  sv_catpvn_nomg(dsv, buf, 5);
}

static void tstr_write_offset_extended_numeric(pTHX_ SV* dsv, int32_t offset) {
  char buf[6];
  int sign, h, m;

  if (offset < 0)
    sign = '-', offset = -offset;
  else
    sign = '+';

  h = offset / 60;
  m = offset % 60;

  buf[0] = (char)sign;
  buf[1] = '0' + h / 10;
  buf[2] = '0' + h % 10;
  buf[3] = ':';
  buf[4] = '0' + m / 10;
  buf[5] = '0' + m % 10;
  sv_catpvn_nomg(dsv, buf, 6);
}

static void tstr_write_offset_extended(pTHX_ SV* dsv, int32_t offset) {
  if (offset == 0)
    sv_catpvn_nomg(dsv, "Z", 1);
  else
    tstr_write_offset_extended_numeric(aTHX_ dsv, offset);
}

static void tstr_write_extended_hms(pTHX_ SV* dsv,
                                    unsigned int h,
                                    unsigned int m,
                                    unsigned int s) {
  char buf[8];
  buf[0] = '0' + h / 10;
  buf[1] = '0' + h % 10;
  buf[2] = ':';
  buf[3] = '0' + m / 10;
  buf[4] = '0' + m % 10;
  buf[5] = ':';
  buf[6] = '0' + s / 10;
  buf[7] = '0' + s % 10;
  sv_catpvn_nomg(dsv, buf, 8);
}

static void tstr_write_extended_ymd(pTHX_ SV* dsv,
                                    unsigned int y,
                                    unsigned int m,
                                    unsigned int d) {
  char buf[10];
  buf[3] = '0' + y % 10; y /= 10;
  buf[2] = '0' + y % 10; y /= 10;
  buf[1] = '0' + y % 10; y /= 10;
  buf[0] = '0' + y % 10;
  buf[4] = '-';
  buf[5] = '0' + m / 10;
  buf[6] = '0' + m % 10;
  buf[7] = '-';
  buf[8] = '0' + d / 10;
  buf[9] = '0' + d % 10;
  sv_catpvn_nomg(dsv, buf, 10);
}

typedef struct {
  const char* spec;
  const char* zulu;
  STRLEN zulu_len;
} tstr_format_info_t;

#define TSTR_FMT(s)          {s, NULL, 0}
#define TSTR_FMT_ZULU(s, zb) {s, zb, sizeof(zb) - 1}
#define TSTR_FMT_NONE        {NULL, NULL, 0}

static const tstr_format_info_t kFormatInfo[TSTR_FORMAT_TYPE_COUNT] = {
  [TSTR_FORMAT_UNKNOWN]    = TSTR_FMT_NONE,
  [TSTR_FORMAT_ANSIC]      = TSTR_FMT("%a %b %e %T %Y"),
  [TSTR_FORMAT_ASN1GT]     = TSTR_FMT_ZULU("%Y%m%d%H%M%S%f%z", "Z"),
  [TSTR_FORMAT_ASN1UT]     = TSTR_FMT_ZULU("%y%m%d%H%M%S%z", "Z"),
  [TSTR_FORMAT_CLF]        = TSTR_FMT("%d/%b/%Y:%T%f %z"),
  [TSTR_FORMAT_DATETIME]   = TSTR_FMT_NONE,
  [TSTR_FORMAT_ECMASCRIPT] = TSTR_FMT("%a %b %d %Y %T GMT%z"),
  [TSTR_FORMAT_GITDATE]    = TSTR_FMT("%a %b %-d %T %Y %z"),
  [TSTR_FORMAT_ISO8601]    = TSTR_FMT("%FT%T%f%Z"),
  [TSTR_FORMAT_ISO9075]    = TSTR_FMT("%F %T%f %:z"),
  [TSTR_FORMAT_RFC2616]    = TSTR_FMT("%a, %d %b %Y %T GMT"),
  [TSTR_FORMAT_RFC2822]    = TSTR_FMT("%a, %d %b %Y %T %z"),
  [TSTR_FORMAT_RFC2822FWS] = TSTR_FMT("%a, %d %b %Y %T %z"),
  [TSTR_FORMAT_RFC3339]    = TSTR_FMT("%FT%T%f%Z"),
  [TSTR_FORMAT_RFC3501]    = TSTR_FMT("%d-%b-%Y %T %z"),
  [TSTR_FORMAT_RFC4287]    = TSTR_FMT("%FT%T%f%Z"),
  [TSTR_FORMAT_RFC5280]    = TSTR_FMT_NONE,
  [TSTR_FORMAT_RFC5545]    = TSTR_FMT("%Y%m%dT%H%M%SZ"),
  [TSTR_FORMAT_RFC9557]    = TSTR_FMT("%FT%T%f%Z"),
  [TSTR_FORMAT_RUBYDATE]   = TSTR_FMT("%a %b %d %T %z %Y"),
  [TSTR_FORMAT_UNIXDATE]   = TSTR_FMT_ZULU("%a %b %e %T %z %Y", "UTC"),
  [TSTR_FORMAT_UNIXSTAMP]  = TSTR_FMT_ZULU("%a %b %e %T%f %z %Y", "UTC"),
  [TSTR_FORMAT_W3CDTF]     = TSTR_FMT("%FT%T%f%Z"),
};

#undef TSTR_FMT
#undef TSTR_FMT_ZULU
#undef TSTR_FMT_NONE

static void tstr_time2str_format(pTHX_ SV* dsv,
                                 const tstr_datetime_t* dt,
                                 int precision,
                                 const char* spec,
                                 const char* zulu,
                                 STRLEN zulu_len) {
  const char* s = spec;
  const char* p;
  int dow;

  while (*s) {
    p = s;
    while (*s && *s != '%')
      s++;

    if (s > p)
      sv_catpvn_nomg(dsv, p, s - p);

    if (!*s)
      break;

    s++;

    switch (*s++) {
      case 'a':
        dow = tstr_calendar_rdn_to_dow(dt->rdn);
        sv_catpvn_nomg(dsv, kShortDayName[dow - 1], 3);
        break;

      case 'b':
        sv_catpvn_nomg(dsv, kShortMonthName[dt->month - 1], 3);
        break;

      case 'd':
        write_u20P(aTHX_ dsv, dt->day);
        break;

      case 'e':
        write_u2SP(aTHX_ dsv, dt->day);
        break;

      case '-':
        if (*s == 'd') {
          s++;
          write_u2UP(aTHX_ dsv, dt->day);
        }
        break;

      case 'm':
        write_u20P(aTHX_ dsv, dt->month);
        break;

      case 'y':
        write_u20P(aTHX_ dsv, dt->year % 100);
        break;

      case 'Y':
        write_u40P(aTHX_ dsv, dt->year);
        break;

      case 'H':
        write_u20P(aTHX_ dsv, dt->hour);
        break;

      case 'M':
        write_u20P(aTHX_ dsv, dt->minute);
        break;

      case 'S':
        write_u20P(aTHX_ dsv, dt->second);
        break;

      case 'F':
        tstr_write_extended_ymd(aTHX_ dsv, dt->year, dt->month, dt->day);
        break;

      case 'T':
        tstr_write_extended_hms(aTHX_ dsv, dt->hour, dt->minute, dt->second);
        break;

      case 'f':
        tstr_write_fraction(aTHX_ dsv, dt->nanosecond, precision);
        break;

      case 'z':
        tstr_write_offset_basic(aTHX_ dsv, dt->offset, zulu, zulu_len);
        break;

      case ':':
        if (*s == 'z') {
          s++;
          tstr_write_offset_extended_numeric(aTHX_ dsv, dt->offset);
        }
        break;

      case 'Z':
        tstr_write_offset_extended(aTHX_ dsv, dt->offset);
        break;

      case '%':
        sv_catpvn_nomg(dsv, "%", 1);
        break;

      default:
        sv_catpvn_nomg(dsv, s - 2, 2);
        break;
    }
  }
}

bool tstr_time2str(pTHX_ SV* dsv,
                   const tstr_datetime_t* dt,
                   int precision,
                   tstr_format_t fmt) {
  const tstr_format_info_t* info;

  if (!tstr_format_is_known(fmt))
    return false;

  info = &kFormatInfo[fmt];
  if (!info->spec)
    return false;

  tstr_time2str_format(aTHX_ dsv, dt, precision, info->spec, info->zulu,
                       info->zulu_len);
  return true;
}
