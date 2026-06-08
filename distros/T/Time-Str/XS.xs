#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <limits.h>

#include "tstr_param.h"
#include "tstr_format.h"
#include "tstr_datetime.h"
#include "tstr_time2str.h"
#include "tstr_parsed.h"
#include "tstr_token_parse.h"
#include "tstr_calendar.h"
#include "tstr_time.h"
#include "tstr_regexp.h"
#include "tstr_parse.h"
#include "tstr_sv.h"
#include "tstr_carp.h"

#if IVSIZE >= 8
typedef IV I64V;
# define SvI64V(sv)         (I64V)SvIV(sv)
# define newSVi64v(i64)     newSViv((IV)i64)
# define XSRETURN_I64V(i64) XSRETURN_IV((IV)i64)
#else
typedef NV I64V;
# define SvI64V(sv)         (I64V)SvNV(sv)
# define newSVi64v(i64)     newSVnv((NV)i64)
# define XSRETURN_I64V(i64) XSRETURN_NV((NV)i64)
#endif

#ifndef XSRETURN_BOOL
#define XSRETURN_BOOL(v) STMT_START { ST(0) = boolSV(v); XSRETURN(1); } STMT_END
#endif

#if NVSIZE > 8
# define DEFAULT_PRECISION 9
#else
# define DEFAULT_PRECISION 6
#endif

#define DEFAULT_PIVOT_YEAR 1950
#define NANOS_PER_SECOND   TSTR_NANOS_PER_SECOND
#define MIN_EPOCH          INT64_C(-62135596800)
#define MAX_EPOCH          INT64_C(253402300799)
#define EPOCH_20500101     INT64_C(2524608000)

#define MY_CXT_KEY "Time::Str::_cxt" XS_VERSION

typedef struct {
  REGEXP *regexps[TSTR_FORMAT_TYPE_COUNT];
  tstr_sv_keys_t keys;
} my_cxt_t;

START_MY_CXT

#define SHARE_KEY(s) newSVpvn_share("" s "", sizeof(s) - 1, 0)

static void init_keys(pTHX_ tstr_sv_keys_t *k) {
  k->k_year          = SHARE_KEY("year");
  k->k_month         = SHARE_KEY("month");
  k->k_day           = SHARE_KEY("day");
  k->k_hour          = SHARE_KEY("hour");
  k->k_minute        = SHARE_KEY("minute");
  k->k_second        = SHARE_KEY("second");
  k->k_nanosecond    = SHARE_KEY("nanosecond");
  k->k_tz_offset     = SHARE_KEY("tz_offset");
  k->k_tz_utc        = SHARE_KEY("tz_utc");
  k->k_tz_abbrev     = SHARE_KEY("tz_abbrev");
  k->k_tz_annotation = SHARE_KEY("tz_annotation");
  k->k_fraction      = SHARE_KEY("fraction");
  k->k_day_name      = SHARE_KEY("day_name");
  k->k_meridiem      = SHARE_KEY("meridiem");
}

static void load_regexps(pTHX_ my_cxt_t *cxt) {
  HV *mapping;
  HE *entry;
  int i;

  dSP;

  ENTER;
  SAVETMPS;

  load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("Time::Str::Regexp"), NULL);

  PUSHMARK(SP);
  call_pv("Time::Str::Regexp::mapping", G_SCALAR);
  SPAGAIN;
  mapping = (HV *)SvRV(POPs);
  PUTBACK;

  for (i = 0; i < TSTR_FORMAT_TYPE_COUNT; i++)
    cxt->regexps[i] = NULL;

  hv_iterinit(mapping);
  while ((entry = hv_iternext(mapping))) {
    STRLEN klen;
    const char *key = HePV(entry, klen);
    tstr_format_t fmt = tstr_format_from_string(key, klen);
    SV *val = HeVAL(entry);
    REGEXP *rx;

    if (fmt == TSTR_FORMAT_UNKNOWN)
      croak("panic: Time::Str::Regexp::mapping() returned unknown format key '%.*s'",
            (int)klen, key);

    rx = SvRX(val);
    if (!rx)
      croak("panic: Time::Str::Regexp::mapping() value for '%.*s' is not a regexp",
            (int)klen, key);

    cxt->regexps[fmt] = ReREFCNT_inc(rx);
  }

  FREETMPS;
  LEAVE;
}

static bool tstr_is_hashref(pTHX_ SV *sv) {
  SvGETMAGIC(sv);
  if (!SvROK(sv))
    return false;
  sv = SvRV(sv);
  SvGETMAGIC(sv);
  if (SvOBJECT(sv))
    return false;
  return SvTYPE(sv) == SVt_PVHV;
}

static bool tstr_fetch_method(pTHX_ SV *sv, const char *name, GV **method) {
  SvGETMAGIC(sv);
  if (!SvROK(sv))
    return false;
  sv = SvRV(sv);
  SvGETMAGIC(sv);
  if (!SvOBJECT(sv))
    return false;

  HV *stash = SvSTASH(sv);
  if ((*method = gv_fetchmethod_autoload (stash, name, 0)))
    return true;
  return false;
}

static int64_t tstr_call_offset_method(pTHX_ SV *obj, GV *method, int64_t value) {
  dSP;
  int count;
  int64_t offset;
  SV *ret;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);
  PUSHs(obj);
  mPUSHs(newSVi64v(value));

  PUTBACK;
  count = call_sv((SV *)GvCV(method), G_SCALAR);
  SPAGAIN;

  if (count != 1)
    croak("panic: method returned %d values", count);
  ret = POPs;
  offset = SvIV(ret);
  PUTBACK;

  FREETMPS;
  LEAVE;

  return offset;
}

MODULE = Time::Str  PACKAGE = Time::Str

PROTOTYPES: DISABLE

BOOT:
{
  MY_CXT_INIT;
  init_keys(aTHX_ &MY_CXT.keys);
  load_regexps(aTHX_ &MY_CXT);
}

#ifdef USE_ITHREADS

void
CLONE(...)
  CODE:
{
  MY_CXT_CLONE;
  init_keys(aTHX_ &MY_CXT.keys);
  load_regexps(aTHX_ &MY_CXT);
  PERL_UNUSED_VAR(items);
}

#endif

void
time2str(...)
  PREINIT:
    dXSTARG;
    int64_t epoch;
    int offset = INT_MAX;
    int nanosecond = -1;
    int precision = -1;
    tstr_format_t fmt = TSTR_FORMAT_RFC3339;
    tstr_datetime_t dt;
    GV *method = NULL;
    SV *timezone = NULL;
    int i;
  PPCODE:
    if (items < 1 || !(items & 1))
      croak("Usage: time2str(time [, format => 'RFC3339' ])");

    epoch = (int64_t)SvNV(ST(0));

    for (i = 1; i < items; i += 2) {
      const char *key;
      STRLEN klen;
      SV *val;

      key = SvPV_const(ST(i), klen);
      val = ST(i + 1);

      switch (tstr_param_from_string(key, klen)) {
        case TSTR_PARAM_FORMAT:
          fmt = tstr_sv_format(aTHX_ val);
          break;
        case TSTR_PARAM_OFFSET:
          offset = tstr_sv_offset(aTHX_ val);
          if (timezone)
            croak("Parameter 'offset' is mutually exclusive with 'timezone'");
          break;
        case TSTR_PARAM_PRECISION:
          precision = tstr_sv_precision(aTHX_ val);
          break;
        case TSTR_PARAM_NANOSECOND:
          nanosecond = tstr_sv_nanosecond(aTHX_ val);
          break;
        case TSTR_PARAM_TIMEZONE:
          if (!tstr_fetch_method(aTHX_ val, "offset_for_utc", &method))
            croak("Parameter 'timezone' is not an object with an 'offset_for_utc' method");
          if (offset != INT_MAX)
            croak("Parameter 'timezone' is mutually exclusive with 'offset'");
          timezone = val;
          break;
        default:
          croak("Unrecognised named parameter: '%"SVf"'", ST(i));
      }
    }

    if (epoch < MIN_EPOCH || epoch > MAX_EPOCH)
      croak("Parameter 'time' is out of range");

    if (nanosecond < 0 && SvNOK(ST(0))) {
      NV t = SvNV(ST(0));
      NV sec = Perl_floor(t);
      NV fr = t - sec;
      int scale_exp = (precision >= 0) ? precision : DEFAULT_PRECISION;
      NV scale = Perl_pow(10.0, (NV)scale_exp);

      fr = Perl_floor(fr * scale + 0.5) / scale;
      nanosecond = (int)Perl_floor(fr * NANOS_PER_SECOND + 0.5);
      epoch = (int64_t)sec;

      if (nanosecond >= NANOS_PER_SECOND) {
        nanosecond -= NANOS_PER_SECOND;
        epoch++;
      }
    }

    if (nanosecond < 0)
      nanosecond = 0;

    if (timezone)
      offset = tstr_call_offset_method(aTHX_ timezone, method, epoch) / 60;
    else if (offset == INT_MAX)
      offset = 0;

    if (offset) {
      int64_t local = epoch + (int64_t)offset * 60;
      if (local < MIN_EPOCH || local > MAX_EPOCH)
        croak("Parameter 'time' is out of range for the given offset");
    }

    if (fmt == TSTR_FORMAT_RFC5280) {
      fmt = (epoch < EPOCH_20500101) ? TSTR_FORMAT_ASN1UT : TSTR_FORMAT_ASN1GT;
      nanosecond = 0;
      offset = 0;
      precision = -1;
    }

    tstr_datetime_from_epoch(&dt, epoch, offset, nanosecond);

    (void)SvUPGRADE(TARG, SVt_PV);
    (void)SvGROW(TARG, 30);
    SvCUR_set(TARG, 0);
    SvPOK_only(TARG);

    if (!tstr_time2str(aTHX_ TARG, &dt, precision, fmt))
      croak("Parameter 'format' does not support time2str");
    PUSHTARG;

void
str2time(...)
  PREINIT:
    dMY_CXT;
    tstr_format_t fmt = TSTR_FORMAT_RFC3339;
    int pivot_year = -1;
    int precision = -1;
    GV *method;
    SV *timezone = NULL;
    HV *timezone_map = NULL;
    tstr_parsed_t parsed;
    int i;
  PPCODE:
    if (items < 1 || !(items & 1))
      croak("Usage: str2time(string [, format => 'RFC3339' ])");

    for (i = 1; i < items; i += 2) {
      const char *key;
      STRLEN klen;
      SV *val;

      key = SvPV_const(ST(i), klen);
      val = ST(i + 1);

      switch (tstr_param_from_string(key, klen)) {
        case TSTR_PARAM_FORMAT:
          fmt = tstr_sv_format(aTHX_ val);
          break;
        case TSTR_PARAM_PIVOT_YEAR:
          pivot_year = tstr_sv_pivot_year(aTHX_ val);
          break;
        case TSTR_PARAM_PRECISION:
          precision = tstr_sv_precision(aTHX_ val);
          break;
        case TSTR_PARAM_TIMEZONE:
          if (!tstr_fetch_method(aTHX_ val, "offset_for_local", &method))
            croak("Parameter 'timezone' is not an object with an 'offset_for_local' method");
          timezone = val;
          break;
        case TSTR_PARAM_TIMEZONE_MAP:
          if (!tstr_is_hashref(aTHX_ val))
            croak("Parameter 'timezone_map' is not a HASH reference");
          timezone_map = (HV *)SvRV(val);
          break;
        default:
          croak("Unrecognised named parameter: '%"SVf"'", ST(i));
      }
    }

    tstr_parse(aTHX_ ST(0), fmt, pivot_year,
               MY_CXT.regexps, &MY_CXT.keys, &parsed);

    if (parsed.flags & TSTR_PARSED_HAS_TZ_ABBREV) {
      SV **svp = NULL;
      if (timezone_map)
        svp = hv_fetch(timezone_map, parsed.tz_abbrev, (I32)parsed.tz_abbrev_len, 0);
      if (timezone_map && svp) {
        SV *obj = *svp;
        if (!tstr_fetch_method(aTHX_ obj, "offset_for_local", &method))
          tstr_croakf("timezone_map value for '%.*s' is not an object with an 'offset_for_local' method",
                      (int)parsed.tz_abbrev_len, parsed.tz_abbrev);
        timezone = obj;
      }
      else {
        tstr_croakf("Unable to convert: cannot resolve abbreviated timezone '%.*s'", 
                    (int)parsed.tz_abbrev_len, parsed.tz_abbrev);
      }
    }

    if (!(parsed.flags & TSTR_PARSED_HAS_OFFSET) && !timezone)
      tstr_croak("Unable to convert: timestamp string without a UTC designator or numeric offset");

    {
      int month = parsed.month;
      int day = parsed.day;
      int hour = parsed.hour;
      int leap_second;
      int second;
      
      if (!(parsed.flags & TSTR_PARSED_HAS_MONTH))
        month = 1;
      if (!(parsed.flags & TSTR_PARSED_HAS_DAY))
        day = 1;

      if (parsed.flags & TSTR_PARSED_HAS_MERIDIEM)
        hour = hour % 12 + parsed.meridiem;

      /* A leap second (23:59:60 UTC) cannot be represented as a POSIX
       * time, so fold it onto the preceding 23:59:59 and validate that
       * it lands on a real leap-second slot. The error messages are
       * worded to hold equally if a Time::LeapSecond table lookup is
       * used instead. */
      leap_second = (parsed.second == 60);
      second      = parsed.second - leap_second;

      uint32_t rdn = tstr_calendar_ymd_to_rdn(parsed.year, month, day);
      int64_t sod  = ((int64_t)hour * 60 + parsed.minute) * 60 + second;
      int64_t epoch = ((int64_t)rdn - TSTR_CALENDAR_RDN_UNIX_EPOCH) * 86400 + sod;

      /* A string offset is in minutes; a timezone object resolves the
       * local time and returns its UTC offset in seconds. */
      if (parsed.flags & TSTR_PARSED_HAS_OFFSET)
        epoch -= (int64_t)parsed.offset * 60;
      else
        epoch -= tstr_call_offset_method(aTHX_ timezone, method, epoch);

      if (leap_second) {
        switch (tstr_time_leap_check(epoch)) {
          case 1:
            tstr_croak("Unable to convert: a leap second must occur at 23:59:60 UTC");
            break;
          case 2:
            tstr_croak("Unable to convert: no leap second on this UTC date");
            break;
        }
      }

      if (parsed.flags & TSTR_PARSED_HAS_NANOSECOND) {
        int scale_exp = (precision >= 0) ? precision : DEFAULT_PRECISION;
        NV scale = Perl_pow(10.0, (NV)scale_exp);
        NV fraction = Perl_floor((NV)parsed.nanosecond * scale / NANOS_PER_SECOND) / scale;
        mPUSHn((NV)epoch + fraction);
      } else {
#if IVSIZE == 4
        mPUSHn((NV)epoch);
#else
        mPUSHi(epoch);
#endif
      }
    }

void
str2date(...)
  PREINIT:
    dMY_CXT;
    tstr_format_t fmt = TSTR_FORMAT_RFC3339;
    int pivot_year = -1;
    tstr_parsed_t parsed;
    HV *result;
    int i;
  PPCODE:
    if (items < 1 || !(items & 1))
      croak("Usage: str2date(string [, format => 'RFC3339' ])");

    for (i = 1; i < items; i += 2) {
      const char *key;
      STRLEN klen;
      SV *val;

      key = SvPV_const(ST(i), klen);
      val = ST(i + 1);

      switch (tstr_param_from_string(key, klen)) {
        case TSTR_PARAM_FORMAT:
          fmt = tstr_sv_format(aTHX_ val);
          break;
        case TSTR_PARAM_PIVOT_YEAR:
          pivot_year = tstr_sv_pivot_year(aTHX_ val);
          break;
        default:
          croak("Unrecognised named parameter: '%"SVf"'", ST(i));
      }
    }

    tstr_parse(aTHX_ ST(0), fmt, pivot_year,
               MY_CXT.regexps, &MY_CXT.keys, &parsed);

    if (GIMME_V == G_ARRAY) {
      int n;
      EXTEND(SP, tstr_parsed_field_count(&parsed) * 2);
      n = tstr_sv_parsed_to_stack(aTHX_ &parsed, &MY_CXT.keys, SP);
      SP += n;
    } else {
      HV *result = tstr_sv_parsed_to_hv(aTHX_ &parsed, &MY_CXT.keys);
      mPUSHs(newRV_noinc((SV *)result));
    }

MODULE = Time::Str  PACKAGE = Time::Str::Token

PROTOTYPES: DISABLE

void
parse_day(...)
  PREINIT:
    const char *src;
    STRLEN len;
    int value;
  PPCODE:
    if (items != 1)
      croak("Usage: parse_day(string)");
    src = SvPV_const(ST(0), len);
    if (!tstr_token_parse_day(src, len, &value))
      tstr_token_croakf("Unable to parse: day is invalid");
    mPUSHi(value);

void
parse_day_name(...)
  PREINIT:
    const char *src;
    STRLEN len;
    int value;
  PPCODE:
    if (items != 1)
      croak("Usage: parse_day_name(string)");
    src = SvPV_const(ST(0), len);
    if (!tstr_token_parse_day_name(src, len, &value))
      tstr_token_croakf("Unable to parse: day name is invalid");
    mPUSHi(value);

void
parse_month(...)
  PREINIT:
    const char *src;
    STRLEN len;
    int value;
  PPCODE:
    if (items != 1)
      croak("Usage: parse_month(string)");
    src = SvPV_const(ST(0), len);
    if (!tstr_token_parse_month(src, len, &value))
      tstr_token_croakf("Unable to parse: month is invalid");
    mPUSHi(value);

void
parse_meridiem(...)
  PREINIT:
    const char *src;
    STRLEN len;
    int value;
  PPCODE:
    if (items != 1)
      croak("Usage: parse_meridiem(string)");
    src = SvPV_const(ST(0), len);
    if (!tstr_token_parse_meridiem(src, len, &value))
      tstr_token_croakf("Unable to parse: meridiem is invalid");
    mPUSHi(value);

void
parse_tz_offset(...)
  PREINIT:
    const char *src;
    STRLEN len;
    int value;
  PPCODE:
    if (items != 1)
      croak("Usage: parse_tz_offset(string)");
    src = SvPV_const(ST(0), len);
    if (!tstr_token_parse_tz_offset(src, len, &value))
      tstr_token_croakf("Unable to parse: timezone offset is invalid");
    mPUSHi(value);


MODULE = Time::Str  PACKAGE = Time::Str::Calendar

PROTOTYPES: DISABLE

void
leap_year(...)
  PPCODE:
    if (items != 1)
      croak("Usage: leap_year(year)");
    if (tstr_calendar_leap_year((int)SvIV(ST(0))))
      XSRETURN_YES;
    XSRETURN_NO;

void
month_days(...)
  PREINIT:
    int y, m;
  PPCODE:
    if (items != 2)
      croak("Usage: month_days(year, month)");
    y = (int)SvIV(ST(0));
    m = tstr_sv_month(aTHX_ ST(1));
    mPUSHi(tstr_calendar_month_days(y, m));

void
valid_ymd(...)
  PPCODE:
    if (items != 3)
      croak("Usage: valid_ymd(year, month, day)");
    if (tstr_calendar_valid_ymd((int)SvIV(ST(0)), (int)SvIV(ST(1)), (int)SvIV(ST(2))))
      XSRETURN_YES;
    XSRETURN_NO;

void
ymd_to_rdn(...)
  PREINIT:
    int y, m, d;
  PPCODE:
    if (items != 3)
      croak("Usage: ymd_to_rdn(year, month, day)");
    tstr_sv_ymd(aTHX_ ST(0), ST(1), ST(2), &y, &m, &d);
    mPUSHi((IV)tstr_calendar_ymd_to_rdn(y, m, d));

void
ymd_to_doy(...)
  PREINIT:
    int y, m, d;
  PPCODE:
    if (items != 3)
      croak("Usage: ymd_to_doy(year, month, day)");
    tstr_sv_ymd(aTHX_ ST(0), ST(1), ST(2), &y, &m, &d);
    mPUSHi(tstr_calendar_ymd_to_doy(y, m, d));

void
yd_to_md(...)
  PREINIT:
    int y, doy, m, d;
  PPCODE:
    if (items != 2)
      croak("Usage: yd_to_md(year, day)");
    tstr_sv_yd(aTHX_ ST(0), ST(1), &y, &doy);
    tstr_calendar_yd_to_md(y, doy, &m, &d);
    EXTEND(SP, 2);
    mPUSHi(m);
    mPUSHi(d);

void
rdn_to_ymd(...)
  PREINIT:
    IV rdn;
    int y, m, d;
  PPCODE:
    if (items != 1)
      croak("Usage: rdn_to_ymd(rdn)");
    rdn = SvIV(ST(0));
    if (rdn < TSTR_CALENDAR_RDN_MIN || rdn > TSTR_CALENDAR_RDN_MAX)
      croak("Parameter 'rdn' is out of range");
    tstr_calendar_rdn_to_ymd((uint32_t)rdn, &y, &m, &d);
    EXTEND(SP, 3);
    mPUSHi(y);
    mPUSHi(m);
    mPUSHi(d);

void
rdn_to_dow(...)
  PREINIT:
    IV rdn;
  PPCODE:
    if (items != 1)
      croak("Usage: rdn_to_dow(rdn)");
    rdn = SvIV(ST(0));
    if (rdn < TSTR_CALENDAR_RDN_MIN || rdn > TSTR_CALENDAR_RDN_MAX)
      croak("Parameter 'rdn' is out of range");
    mPUSHi(tstr_calendar_rdn_to_dow((uint32_t)rdn));

void
ymd_to_dow(...)
  PREINIT:
    int y, m, d;
  PPCODE:
    if (items != 3)
      croak("Usage: ymd_to_dow(year, month, day)");
    tstr_sv_ymd(aTHX_ ST(0), ST(1), ST(2), &y, &m, &d);
    mPUSHi(tstr_calendar_ymd_to_dow(y, m, d));

void
nth_dow_in_month(...)
  PREINIT:
    int y, m, ord, dow, day;
  PPCODE:
    if (items != 4)
      croak("Usage: nth_dow_in_month(year, month, ord, dow)");
    y   = (int)SvIV(ST(0));
    m   = (int)SvIV(ST(1));
    ord = (int)SvIV(ST(2));
    dow = (int)SvIV(ST(3));
    if (y < 1 || y > 9999)
      croak("Parameter 'year' is out of range [1, 9999]");
    if (m < 1 || m > 12)
      croak("Parameter 'month' is out of range [1, 12]");
    if (ord < -4 || ord > 4 || ord == 0)
      croak("Parameter 'ord' is out of range [-4, -1] or [1, 4]");
    if (dow < 1 || dow > 7)
      croak("Parameter 'dow' is out of range [1, 7]");
    mPUSHi(tstr_calendar_nth_dow_in_month(y, m, ord, dow));

void
resolve_century(...)
  PREINIT:
    int year, pivot_year;
  PPCODE:
    if (items != 2)
      croak("Usage: resolve_century(year, pivot_year)");
    year = (int)SvIV(ST(0));
    if (year < 0 || year > 99)
      croak("Parameter 'year' is out of range [0, 99]");
    pivot_year = tstr_sv_pivot_year(aTHX_ ST(1));
    mPUSHi(tstr_calendar_resolve_century(year, pivot_year));

MODULE = Time::Str  PACKAGE = Time::Str::Time

PROTOTYPES: DISABLE

void
valid_hms(...)
  PPCODE:
    if (items != 3)
      croak("Usage: valid_hms(hour, minute, second)");
    if (tstr_time_valid_hms((int)SvIV(ST(0)), (int)SvIV(ST(1)), (int)SvIV(ST(2))))
      XSRETURN_YES;
    XSRETURN_NO;

void
valid_hms60(...)
  PPCODE:
    if (items != 3)
      croak("Usage: valid_hms60(hour, minute, second)");
    if (tstr_time_valid_hms60((int)SvIV(ST(0)), (int)SvIV(ST(1)), (int)SvIV(ST(2))))
      XSRETURN_YES;
    XSRETURN_NO;

void
timegm_modern(...)
  PREINIT:
    int y, m, d, H, M, S;
  PPCODE:
    if (items != 6)
      croak("Usage: timegm_modern(sec, min, hour, mday, mon, year)");
    S = (int)SvIV(ST(0));
    M = (int)SvIV(ST(1));
    H = (int)SvIV(ST(2));
    d = (int)SvIV(ST(3));
    m = (int)SvIV(ST(4));
    y = (int)SvIV(ST(5));
    if (y < 1 || y > 9999)
      croak("Parameter 'year' is out of range [1, 9999]");
    if (m < 1 || m > 12)
      croak("Parameter 'month' is out of range [1, 12]");
    if (d < 1 || d > tstr_calendar_month_days(y, m))
      croak("Parameter 'day' is out of range");
    if (H < 0 || H > 23)
      croak("Parameter 'hour' is out of range [0, 23]");
    if (M < 0 || M > 59)
      croak("Parameter 'minute' is out of range [0, 59]");
    if (S < 0 || S > 59)
      croak("Parameter 'second' is out of range [0, 59]");
#if IVSIZE >= 8
    mPUSHi((IV)tstr_time_timegm(y, m, d, H, M, S));
#else
    mPUSHn((NV)tstr_time_timegm(y, m, d, H, M, S));
#endif

void
gmtime_modern(...)
  PREINIT:
    int y, m, d, H, M, S, wday, yday;
    int64_t epoch;
  PPCODE:
    if (items != 1)
      croak("Usage: gmtime_modern(time)");
#if IVSIZE >= 8
    epoch = (int64_t)SvIV(ST(0));
#else
    epoch = (int64_t)SvNV(ST(0));
#endif
    if (epoch < TSTR_TIME_EPOCH_MIN || epoch > TSTR_TIME_EPOCH_MAX)
      croak("Parameter 'time' is out of range");
    tstr_time_gmtime(epoch, &y, &m, &d, &H, &M, &S, &wday, &yday);
    EXTEND(SP, 9);
    mPUSHi(S);
    mPUSHi(M);
    mPUSHi(H);
    mPUSHi(d);
    mPUSHi(m);
    mPUSHi(y);
    mPUSHi(wday);
    mPUSHi(yday);
    mPUSHi(0);

void
gmtime_year(...)
  PREINIT:
    int y;
    int64_t epoch;
  PPCODE:
    if (items != 1)
      croak("Usage: gmtime_modern(time)");
#if IVSIZE >= 8
    epoch = (int64_t)SvIV(ST(0));
#else
    epoch = (int64_t)SvNV(ST(0));
#endif
    if (epoch < TSTR_TIME_EPOCH_MIN || epoch > TSTR_TIME_EPOCH_MAX)
      croak("Parameter 'time' is out of range");
    tstr_time_gmtime(epoch, &y, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
    EXTEND(SP, 1);
    mPUSHi(y);

void
timegm_posix(...)
  PREINIT:
    int y, m, d, H, M, S;
  PPCODE:
    if (items != 6)
      croak("Usage: timegm_posix(sec, min, hour, mday, mon, year)");
    S = (int)SvIV(ST(0));
    M = (int)SvIV(ST(1));
    H = (int)SvIV(ST(2));
    d = (int)SvIV(ST(3));
    m = (int)SvIV(ST(4));
    y = (int)SvIV(ST(5));
    if (y < -1899 || y > 8099)
      croak("Parameter 'year' is out of range [-1899, 8099]");
    y += 1900;
    if (m < 0 || m > 11)
      croak("Parameter 'month' is out of range [0, 11]");
    m += 1;
    if (d < 1 || d > tstr_calendar_month_days(y, m))
      croak("Parameter 'day' is out of range");
    if (H < 0 || H > 23)
      croak("Parameter 'hour' is out of range [0, 23]");
    if (M < 0 || M > 59)
      croak("Parameter 'minute' is out of range [0, 59]");
    if (S < 0 || S > 59)
      croak("Parameter 'second' is out of range [0, 59]");
#if IVSIZE >= 8
    mPUSHi((IV)tstr_time_timegm(y, m, d, H, M, S));
#else
    mPUSHn((NV)tstr_time_timegm(y, m, d, H, M, S));
#endif

MODULE = Time::Str  PACKAGE = Time::Str::Util

PROTOTYPES: DISABLE

void
binary_search(...)
  PREINIT:
    AV *av;
    IV len, lo, hi, mid, hi_orig;
    I64V value;
    bool found = false;
  PPCODE:
    if (items < 2 || items > 4)
      croak("Usage: binary_search(array, value [, lo [, hi]])");
    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVAV)
      croak("Parameter 'array' must be an array reference");
    av = (AV *)SvRV(ST(0));
    value = SvI64V(ST(1));
    len = av_len(av) + 1;
    {
      lo  = (items >= 3) ? SvIV(ST(2)) : 0;
      hi  = (items >= 4) ? SvIV(ST(3)) : len;
      if (lo < 0 || lo > len)
        croak("Parameter 'lo' is out of range [0, %" IVdf "]", len);
      if (hi < 0 || hi > len)
        croak("Parameter 'hi' is out of range [0, %" IVdf "]", len);
      if (lo > hi)
        croak("Parameter 'lo' must not exceed 'hi'");
    }
    hi_orig = hi;
    while (lo < hi) {
      mid = (lo + hi) >> 1;
      {
        SV **elem = av_fetch(av, mid, 0);
        if (elem && SvI64V(*elem) < value)
          lo = mid + 1;
        else
          hi = mid;
      }
    }
    if (lo != hi_orig) {
      SV **elem = av_fetch(av, lo, 0);
      found = elem && !(value < SvI64V(*elem));
    }
    XSRETURN_BOOL(found);

void
lower_bound(...)
  PREINIT:
    AV *av;
    IV lo, hi, mid;
    I64V value;
  PPCODE:
    if (items < 2 || items > 4)
      croak("Usage: lower_bound(array, value [, lo [, hi]])");
    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVAV)
      croak("Parameter 'array' must be an array reference");
    av = (AV *)SvRV(ST(0));
    value = SvI64V(ST(1));
    {
      IV len = av_len(av) + 1;
      lo = (items >= 3) ? SvIV(ST(2)) : 0;
      hi = (items >= 4) ? SvIV(ST(3)) : len;
      if (lo < 0 || lo > len)
        croak("Parameter 'lo' is out of range [0, %" IVdf "]", len);
      if (hi < 0 || hi > len)
        croak("Parameter 'hi' is out of range [0, %" IVdf "]", len);
      if (lo > hi)
        croak("Parameter 'lo' must not exceed 'hi'");
    }
    while (lo < hi) {
      mid = (lo + hi) >> 1;
      {
        SV **elem = av_fetch(av, mid, 0);
        if (elem && SvI64V(*elem) < value)
          lo = mid + 1;
        else
          hi = mid;
      }
    }
    mPUSHi(lo);

void
range_bounds(...)
  PREINIT:
    AV *av;
    IV lo, hi, mid, len;
    I64V min_value, max_value;
  PPCODE:
    if (items != 3)
      croak("Usage: range_bounds(array, min_value, max_value)");
    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVAV)
      croak("Parameter 'array' must be an array reference");
    av = (AV *)SvRV(ST(0));
    min_value = SvI64V(ST(1));
    max_value = SvI64V(ST(2));
    if (min_value > max_value)
      croak("Parameter 'min_value' must not exceed 'max_value'");
    len = av_len(av) + 1;
    // lower_bound for min_value
    lo = 0;
    hi = len;
    while (lo < hi) {
      mid = (lo + hi) >> 1;
      {
        SV **elem = av_fetch(av, mid, 0);
        if (elem && SvI64V(*elem) < min_value)
          lo = mid + 1;
        else
          hi = mid;
      }
    }
    // linear scan for upper bound
    hi = lo;
    while (hi < len) {
      SV **elem = av_fetch(av, hi, 0);
      if (elem && SvI64V(*elem) <= max_value)
        hi++;
      else
        break;
    }
    EXTEND(SP, 2);
    mPUSHi(lo);
    mPUSHi(hi);

void
upper_bound(...)
  PREINIT:
    AV *av;
    IV lo, hi, mid;
    I64V value;
  PPCODE:
    if (items < 2 || items > 4)
      croak("Usage: upper_bound(array, value [, lo [, hi ]])");
    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVAV)
      croak("Parameter 'array' must be an array reference");
    av = (AV *)SvRV(ST(0));
    value = SvI64V(ST(1));
    {
      IV len = av_len(av) + 1;
      lo = (items >= 3) ? SvIV(ST(2)) : 0;
      hi = (items >= 4) ? SvIV(ST(3)) : len;
      if (lo < 0 || lo > len)
        croak("Parameter 'lo' is out of range [0, %" IVdf "]", len);
      if (hi < 0 || hi > len)
        croak("Parameter 'hi' is out of range [0, %" IVdf "]", len);
      if (lo > hi)
        croak("Parameter 'lo' must not exceed 'hi'");
    }
    while (lo < hi) {
      mid = (lo + hi) >> 1;
      {
        SV **elem = av_fetch(av, mid, 0);
        if (elem && value < SvI64V(*elem))
          hi = mid;
        else
          lo = mid + 1;
      }
    }
    mPUSHi(lo);

