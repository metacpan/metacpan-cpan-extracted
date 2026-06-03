#ifndef TSTR_TIME_H
#define TSTR_TIME_H

#include <stdbool.h>
#include <stdint.h>
#include "tstr_calendar.h"

#define TSTR_TIME_EPOCH_MIN   INT64_C(-62135596800)
#define TSTR_TIME_EPOCH_MAX   INT64_C(253402300799)

static inline bool tstr_time_valid_hms(int h, int m, int s) {
  return (h >= 0 && h <= 23)
      && (m >= 0 && m <= 59)
      && (s >= 0 && s <= 59);
}

static inline bool tstr_time_valid_hms60(int h, int m, int s) {
  return (h >= 0 && h <= 23) 
      && (m >= 0 && m <= 59) 
      && (s >= 0 && s <= 60);
}

// Validates that a folded leap-second epoch (the 23:59:59 that a
// 23:59:60 leap second folds onto) lands on a real leap-second slot:
// exactly 23:59:60 UTC on June 30 or December 31, year >= 1972. The
// check is table-free: every such date is accepted, whether or not a
// leap second was actually inserted. Returns 0 on success, 1 if the
// instant is not 23:59:60 UTC, or 2 if the UTC date is not valid.
static inline int tstr_time_leap_check(int64_t epoch) {
  int64_t days = epoch / 86400;
  int64_t sod  = epoch - days * 86400;
  if (sod < 0) {
    sod += 86400;
    days--;
  }
  if (sod != 86399)
    return 1;
  int y, m, d;
  tstr_calendar_rdn_to_ymd((uint32_t)(days + TSTR_CALENDAR_RDN_UNIX_EPOCH),
                           &y, &m, &d);
  if (!(y >= 1972 && ((m == 6 && d == 30) || (m == 12 && d == 31))))
    return 2;
  return 0;
}

static inline int64_t tstr_time_timegm(int y,
                                       int m,
                                       int d,
                                       int H,
                                       int M,
                                       int S) {
  uint32_t rdn = tstr_calendar_ymd_to_rdn(y, m, d);
  int64_t sod = (int64_t)H * 3600 + (int64_t)M * 60 + S;
  return ((int64_t)rdn - TSTR_CALENDAR_RDN_UNIX_EPOCH) * 86400 + sod;
}

static inline void tstr_time_gmtime(int64_t epoch,
                                    int* yp,
                                    int* mp,
                                    int* dp,
                                    int* Hp,
                                    int* Mp,
                                    int* Sp,
                                    int* wdayp,
                                    int* ydayp) {
  int y, m, d;
  int64_t days = epoch / 86400;
  int sod = (int)(epoch - days * 86400);
  if (sod < 0) {
    sod += 86400;
    days--;
  }
  uint32_t rdn = (uint32_t)(days + TSTR_CALENDAR_RDN_UNIX_EPOCH);
  tstr_calendar_rdn_to_ymd(rdn, &y, &m, &d);
  if (yp)
    *yp = y;
  if (mp)
    *mp = m;
  if (dp)
    *dp = d;
  if (Hp)
    *Hp = sod / 3600;
  if (Mp)
    *Mp = (sod % 3600) / 60;
  if (Sp)
    *Sp = sod % 60;
  if (wdayp)
    *wdayp = tstr_calendar_rdn_to_dow(rdn) % 7;
  if (ydayp)
    *ydayp = tstr_calendar_ymd_to_doy(y, m, d) - 1;
}

#endif /* TSTR_TIME_H */
