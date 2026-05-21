#ifndef TSTR_CALENDAR_H
#define TSTR_CALENDAR_H

#include <stdbool.h>
#include <stdint.h>

#define TSTR_CALENDAR_RDN_MIN 1       /* 0001-01-01 */
#define TSTR_CALENDAR_RDN_MAX 3652059 /* 9999-12-31 */

#define TSTR_CALENDAR_RDN_UNIX_EPOCH 719163 // 1970-01-01

static inline bool tstr_calendar_leap_year(int y) {
  return ((y & 3) == 0 && (y % 100 != 0 || y % 400 == 0));
}

static inline int tstr_calendar_month_days(int y, int m) {
  static const int kDays[] = {0,  31, 28, 31, 30, 31, 30,
                                  31, 31, 30, 31, 30, 31};
  if (m == 2 && tstr_calendar_leap_year(y))
    return 29;
  return kDays[m];
}

static inline bool tstr_calendar_valid_ymd(int y, int m, int d) {
  return (y >= 1 && y <= 9999) 
      && (m >= 1 && m <= 12)
      && (d >= 1 && (d <= 28 || d <= tstr_calendar_month_days(y, m)));
}

static inline uint32_t tstr_calendar_ymd_to_rdn(int y, int m, int d) {
  if (m < 3)
    y--, m += 12;
  return (uint32_t)(1461 * y) / 4 - y / 100 + y / 400
    + d + ((979 * m - 2918) >> 5) - 306;
}

static inline void tstr_calendar_rdn_to_ymd(uint32_t rdn, int* yp, int* mp, int* dp) {
  uint32_t Z, H, A, B, y, C, m, d;

  Z = rdn + 306;
  H = 100 * Z - 25;
  A = H / 3652425;
  B = A - A / 4;
  y = (100 * B + H) / 36525;
  C = B + Z - (1461 * y) / 4;
  m = (535 * C + 48950) >> 14;
  d = C - ((979 * m - 2918) >> 5);

  if (m > 12)
    y++, m -= 12;

  if (yp)
    *yp = (int)y;
  if (mp)
    *mp = (int)m;
  if (dp)
    *dp = (int)d;
}

static inline int tstr_calendar_rdn_to_dow(uint32_t rdn) {
  return 1 + (rdn + 6) % 7;
}

static inline int tstr_calendar_ymd_to_dow(int y, int m, int d) {
  static const int kDayOffset[] = {0, 6, 2, 1, 4, 6, 2, 4, 0, 3, 5, 1, 3};
  if (m < 3)
    y--;
  return 1 + (y + y / 4 - y / 100 + y / 400 + kDayOffset[m] + d) % 7;
}

static inline int tstr_calendar_resolve_century(int year, int pivot_year) {
  int century = pivot_year / 100;
  int base = century * 100;
  int pivot_offset = pivot_year - base;
  int resolved = base + year;
  if (year < pivot_offset)
    resolved += 100;
  return resolved;
}

#endif /* TSTR_CALENDAR_H */
