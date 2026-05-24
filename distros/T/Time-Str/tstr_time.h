#ifndef TSTR_TIME_H
#define TSTR_TIME_H

#include <stdbool.h>
#include <stdint.h>
#include "tstr_calendar.h"

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

#endif /* TSTR_TIME_H */
