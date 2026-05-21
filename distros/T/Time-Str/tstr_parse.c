#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "tstr_parsed.h"
#include "tstr_format.h"
#include "tstr_calendar.h"
#include "tstr_sv.h"
#include "tstr_regexp.h"
#include "tstr_cparse.h"
#include "tstr_parse_result.h"
#include "tstr_carp.h"

#define DEFAULT_PIVOT_YEAR 1950

static inline bool valid_hms(int h, int m, int s) {
  return h >= 0 && h <= 23
      && m >= 0 && m <= 59
      && s >= 0 && (s <= 59 || (s == 60 && h == 23 && m == 59));
}

static tstr_parse_result_t validate_parsed(const tstr_parsed_t *p) {
  int m = (p->flags & TSTR_PARSED_HAS_MONTH) ? p->month : 1;
  int d = (p->flags & TSTR_PARSED_HAS_DAY)   ? p->day   : 1;

  if (!tstr_calendar_valid_ymd(p->year, m, d))
    return TSTR_PARSE_ERR_DATE_RANGE;

  if ((p->flags & TSTR_PARSED_HAS_DAY_NAME) &&
      tstr_calendar_ymd_to_dow(p->year, p->month, p->day) != p->day_name)
    return TSTR_PARSE_ERR_DAY_NAME_MISMATCH;

  if (p->flags & TSTR_PARSED_HAS_MERIDIEM) {
    if (p->hour < 1 || p->hour > 12)
      return TSTR_PARSE_ERR_HOUR_RANGE;
  }

  if (p->flags & TSTR_PARSED_HAS_TIME) {
    int h = p->hour;
    if (p->flags & TSTR_PARSED_HAS_MERIDIEM)
      h = p->hour % 12 + p->meridiem;
    if (!valid_hms(h, p->minute, p->second))
      return TSTR_PARSE_ERR_TIME_RANGE;
  }

  return TSTR_PARSE_OK;
}

void tstr_parse(pTHX_ SV *input, tstr_format_t fmt, int pivot_year,
                REGEXP **regexps, tstr_sv_keys_t *keys, tstr_parsed_t *p) {
  char *s;
  STRLEN slen;
  tstr_parse_result_t rc;

  s = SvPV(input, slen);

  rc = tstr_cparse_dispatch(s, slen, fmt, p);

  if (rc == TSTR_PARSE_NOMATCH)
    tstr_croakf("Unable to parse: string does not match the %s format",
                tstr_format_name(fmt));

  if (rc == TSTR_PARSE_NOPARSER) {
    REGEXP *rx = regexps[fmt];

    if (!rx)
      croak("panic: no regexp for format '%s'", tstr_format_name(fmt));

    if (!pregexec(rx, s, s + slen, s, 0, input, 1))
      tstr_croakf("Unable to parse: string does not match the %s format",
                  tstr_format_name(fmt));

    rc = tstr_regexp_extract(aTHX_ rx, p, keys);
  }

  if (rc != TSTR_PARSE_OK)
    tstr_croakf("Unable to parse: %s", tstr_parse_error_message(rc));

  if (p->flags & TSTR_PARSED_HAS_YEAR2)
    p->year = tstr_calendar_resolve_century(
      p->year, pivot_year >= 0 ? pivot_year : DEFAULT_PIVOT_YEAR);

  if (fmt == TSTR_FORMAT_RFC2616 && !(p->flags & TSTR_PARSED_HAS_TZ_UTC))
    tstr_parsed_set_tz_utc(p, "GMT", 3);

  rc = validate_parsed(p);
  if (rc != TSTR_PARSE_OK)
    tstr_croakf("Unable to parse: %s", tstr_parse_error_message(rc));
}
