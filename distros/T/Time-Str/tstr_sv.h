#ifndef TSTR_SV_H
#define TSTR_SV_H

#include "tstr_format.h"
#include "tstr_parsed.h"

typedef struct {
  SV *k_year;
  SV *k_month;
  SV *k_day;
  SV *k_hour;
  SV *k_minute;
  SV *k_second;
  SV *k_nanosecond;
  SV *k_tz_offset;
  SV *k_tz_utc;
  SV *k_tz_abbrev;
  SV *k_tz_annotation;
  SV *k_fraction;
  SV *k_day_name;
  SV *k_meridiem;
} tstr_sv_keys_t;

static inline tstr_format_t tstr_sv_format(pTHX_ SV *sv) {
  const char *s;
  STRLEN len;
  tstr_format_t fmt;
  s = SvPV_const(sv, len);
  fmt = tstr_format_from_string(s, len);
  if (fmt == TSTR_FORMAT_UNKNOWN)
    croak("Parameter 'format' is unknown: '%"SVf"'", sv);
  return fmt;
}

static inline int tstr_sv_nanosecond(pTHX_ SV *sv) {
  int v = (int)SvIV(sv);
  if (v < 0 || v > 999999999)
    croak("Parameter 'nanosecond' is out of range [0, 999_999_999]");
  return v;
}

static inline int tstr_sv_precision(pTHX_ SV *sv) {
  int v = (int)SvIV(sv);
  if (v < 0 || v > 9)
    croak("Parameter 'precision' is out of range [0, 9]");
  return v;
}

static inline int tstr_sv_offset(pTHX_ SV *sv) {
  int v = (int)SvIV(sv);
  if (v < -1439 || v > 1439)
    croak("Parameter 'offset' is out of range [-1439, 1439]");
  return v;
}

static inline int tstr_sv_pivot_year(pTHX_ SV *sv) {
  int v = (int)SvIV(sv);
  if (v < 0 || v > 9899)
    croak("Parameter 'pivot_year' is out of range [0, 9899]");
  return v;
}

static inline int tstr_sv_year(pTHX_ SV *sv) {
  int v = (int)SvIV(sv);
  if (v < 1 || v > 9999)
    croak("Parameter 'year' is out of range [1, 9999]");
  return v;
}

static inline int tstr_sv_month(pTHX_ SV *sv) {
  int v = (int)SvIV(sv);
  if (v < 1 || v > 12)
    croak("Parameter 'month' is out of range [1, 12]");
  return v;
}

static inline int tstr_sv_day(pTHX_ SV *sv) {
  int v = (int)SvIV(sv);
  if (v < 1 || v > 31)
    croak("Parameter 'day' is out of range [1, 31]");
  return v;
}

static inline void tstr_sv_ymd(pTHX_ SV *sv_y, SV *sv_m, SV *sv_d,
                               int *yp, int *mp, int *dp) {
  *yp = tstr_sv_year(aTHX_ sv_y);
  *mp = tstr_sv_month(aTHX_ sv_m);
  *dp = tstr_sv_day(aTHX_ sv_d);
}

static inline HV * tstr_sv_parsed_to_hv(pTHX_ const tstr_parsed_t *p,
                                        tstr_sv_keys_t *k) {
  HV *hv = newHV();
  int hour;

  hv_store_ent(hv, k->k_year, newSViv(p->year), 0);
  if (p->flags & TSTR_PARSED_HAS_MONTH)
    hv_store_ent(hv, k->k_month, newSViv(p->month), 0);
  if (p->flags & TSTR_PARSED_HAS_DAY)
    hv_store_ent(hv, k->k_day, newSViv(p->day), 0);

  if (p->flags & TSTR_PARSED_HAS_TIME) {
    hour = p->hour;
    if (p->flags & TSTR_PARSED_HAS_MERIDIEM)
      hour = p->hour % 12 + p->meridiem;
    hv_store_ent(hv, k->k_hour, newSViv(hour), 0);
    if (p->flags & TSTR_PARSED_HAS_MINUTE)
      hv_store_ent(hv, k->k_minute, newSViv(p->minute), 0);
    if (p->flags & TSTR_PARSED_HAS_SECOND)
      hv_store_ent(hv, k->k_second, newSViv(p->second), 0);
    if (p->flags & TSTR_PARSED_HAS_NANOSECOND)
      hv_store_ent(hv, k->k_nanosecond, newSViv(p->nanosecond), 0);
    if (p->flags & TSTR_PARSED_HAS_OFFSET)
      hv_store_ent(hv, k->k_tz_offset, newSViv(p->offset), 0);
  }

  if (p->flags & TSTR_PARSED_HAS_TZ_UTC)
    hv_store_ent(hv, k->k_tz_utc,
      newSVpvn(p->tz_utc, p->tz_utc_len), 0);
  if (p->flags & TSTR_PARSED_HAS_TZ_ABBREV)
    hv_store_ent(hv, k->k_tz_abbrev,
      newSVpvn(p->tz_abbrev, p->tz_abbrev_len), 0);
  if (p->flags & TSTR_PARSED_HAS_TZ_ANNOTATION)
    hv_store_ent(hv, k->k_tz_annotation,
      newSVpvn(p->tz_annotation, p->tz_annotation_len), 0);

  return hv;
}

static inline int tstr_sv_parsed_to_stack(pTHX_ const tstr_parsed_t* p,
                                          tstr_sv_keys_t* k,
                                          SV** sp) {
  int hour;
  SV** start = sp;

  *++sp = k->k_year;
  *++sp = sv_2mortal(newSViv(p->year));
  if (p->flags & TSTR_PARSED_HAS_MONTH) {
    *++sp = k->k_month;
    *++sp = sv_2mortal(newSViv(p->month));
  }
  if (p->flags & TSTR_PARSED_HAS_DAY) {
    *++sp = k->k_day;
    *++sp = sv_2mortal(newSViv(p->day));
  }

  if (p->flags & TSTR_PARSED_HAS_TIME) {
    hour = p->hour;
    if (p->flags & TSTR_PARSED_HAS_MERIDIEM)
      hour = p->hour % 12 + p->meridiem;
    *++sp = k->k_hour;
    *++sp = sv_2mortal(newSViv(hour));
    if (p->flags & TSTR_PARSED_HAS_MINUTE) {
      *++sp = k->k_minute;
      *++sp = sv_2mortal(newSViv(p->minute));
    }
    if (p->flags & TSTR_PARSED_HAS_SECOND) {
      *++sp = k->k_second;
      *++sp = sv_2mortal(newSViv(p->second));
    }
    if (p->flags & TSTR_PARSED_HAS_NANOSECOND) {
      *++sp = k->k_nanosecond;
      *++sp = sv_2mortal(newSViv(p->nanosecond));
    }
    if (p->flags & TSTR_PARSED_HAS_OFFSET) {
      *++sp = k->k_tz_offset;
      *++sp = sv_2mortal(newSViv(p->offset));
    }
  }

  if (p->flags & TSTR_PARSED_HAS_TZ_UTC) {
    *++sp = k->k_tz_utc;
    *++sp = sv_2mortal(newSVpvn(p->tz_utc, p->tz_utc_len));
  }
  if (p->flags & TSTR_PARSED_HAS_TZ_ABBREV) {
    *++sp = k->k_tz_abbrev;
    *++sp = sv_2mortal(newSVpvn(p->tz_abbrev, p->tz_abbrev_len));
  }
  if (p->flags & TSTR_PARSED_HAS_TZ_ANNOTATION) {
    *++sp = k->k_tz_annotation;
    *++sp = sv_2mortal(newSVpvn(p->tz_annotation, p->tz_annotation_len));
  }

  return (int)(sp - start);
}

#endif /* TSTR_SV_H */
