#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "tstr_sv.h"
#include "tstr_parsed.h"
#include "tstr_token_parse.h"
#include "tstr_parse_result.h"

static bool fetch_cap_pv(pTHX_ REGEXP *rx, SV *namesv,
                         const char **sp, STRLEN *lenp) {
  SV *val = reg_named_buff_fetch(rx, namesv, 0);
  if (val && SvOK(val)) {
    sv_2mortal(val);
    *sp = SvPV_const(val, *lenp);
    return true;
  }
  if (val)
    SvREFCNT_dec(val);
  return false;
}

tstr_parse_result_t tstr_regexp_extract(pTHX_ REGEXP *rx, tstr_parsed_t *p,
                                        tstr_sv_keys_t *keys) {
  const char *s;
  STRLEN len;
  int v;

#define CAP_PV(field) fetch_cap_pv(aTHX_ rx, keys->k_##field, &s, &len)

  (void)tstr_parsed_init(p);

  if (!CAP_PV(year))
    croak("panic: regexp matched but no 'year' capture");
  if (!tstr_token_parse_year(s, len, &v))
    return TSTR_PARSE_ERR_YEAR;
  if (len == 2)
    tstr_parsed_set_year2(p, v);
  else
    tstr_parsed_set_year4(p, v);

  if (CAP_PV(month)) {
    if (!tstr_token_parse_month(s, len, &v))
      return TSTR_PARSE_ERR_MONTH;
    tstr_parsed_set_month(p, v);
  } else {
    p->month = 1;
  }

  if (CAP_PV(day)) {
    if (!tstr_token_parse_day(s, len, &v))
      return TSTR_PARSE_ERR_DAY;
    tstr_parsed_set_day(p, v);
  } else {
    p->day = 1;
  }

  if (CAP_PV(day_name)) {
    if (!tstr_token_parse_day_name(s, len, &v))
      return TSTR_PARSE_ERR_DAY_NAME;
    tstr_parsed_set_day_name(p, v);
  }

  if (CAP_PV(hour)) {
    if (!tstr_token_parse_hour(s, len, &v))
      return TSTR_PARSE_ERR_HOUR;
    tstr_parsed_set_hour(p, v);

    if (CAP_PV(meridiem)) {
      if (!tstr_token_parse_meridiem(s, len, &v))
        return TSTR_PARSE_ERR_MERIDIEM;
      tstr_parsed_set_meridiem(p, v);
    }

    if (CAP_PV(minute)) {
      if (!tstr_token_parse_minute(s, len, &v))
        return TSTR_PARSE_ERR_MINUTE;
      tstr_parsed_set_minute(p, v);
    }

    if (CAP_PV(second)) {
      if (!tstr_token_parse_second(s, len, &v))
        return TSTR_PARSE_ERR_SECOND;
      tstr_parsed_set_second(p, v);
    }

    if (CAP_PV(fraction)) {
      if (!tstr_token_parse_fraction(s, len, &v))
        return TSTR_PARSE_ERR_FRACTION;
      tstr_parsed_set_fraction(p, v);
    }

    if (CAP_PV(tz_offset)) {
      if (!tstr_token_parse_tz_offset(s, len, &v))
        return TSTR_PARSE_ERR_OFFSET;
      tstr_parsed_set_offset(p, v);
    }

    if (CAP_PV(tz_utc))
      tstr_parsed_set_tz_utc(p, s, len);

    if (CAP_PV(tz_abbrev))
      tstr_parsed_set_tz_abbrev(p, s, len);

    if (CAP_PV(tz_annotation))
      tstr_parsed_set_tz_annotation(p, s, len);
  }

#undef CAP_PV

  return TSTR_PARSE_OK;
}
