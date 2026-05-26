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
