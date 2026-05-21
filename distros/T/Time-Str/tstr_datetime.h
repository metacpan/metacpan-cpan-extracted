#ifndef TSTR_DATETIME_H
#define TSTR_DATETIME_H

#include <stdint.h>
#include "tstr_calendar.h"

typedef struct {
  int32_t year;       // 1-9999
  int32_t month;      // 1-12
  int32_t day;        // 1-31
  int32_t hour;       // 0-23
  int32_t minute;     // 0-59
  int32_t second;     // 0-60 (60 for leap second)
  int32_t nanosecond; // 0-999999999
  int32_t offset;     // UTC offset in minutes, -1439..1439
  uint32_t rdn;       // Rata Die Number (local date)
} tstr_datetime_t;

#define TSTR_SECS_PER_DAY 86400
#define TSTR_SECS_PER_HOUR 3600
#define TSTR_SECS_PER_MIN 60

static inline void tstr_datetime_from_epoch(tstr_datetime_t* dt,
                                            int64_t epoch,
                                            int32_t offset,
                                            int32_t nanosecond) {
  uint64_t local, days, sod;

  local = (uint64_t)(epoch + (int64_t)offset * TSTR_SECS_PER_MIN
                     + (int64_t)TSTR_CALENDAR_RDN_UNIX_EPOCH * TSTR_SECS_PER_DAY);

  days = local / TSTR_SECS_PER_DAY;
  sod  = local % TSTR_SECS_PER_DAY;

  dt->rdn = (uint32_t)days;
  tstr_calendar_rdn_to_ymd(dt->rdn, &dt->year, &dt->month, &dt->day);

  dt->hour = (int32_t)(sod / TSTR_SECS_PER_HOUR);
  dt->minute = (int32_t)((sod % TSTR_SECS_PER_HOUR) / TSTR_SECS_PER_MIN);
  dt->second = (int32_t)(sod % TSTR_SECS_PER_MIN);
  dt->nanosecond = nanosecond;
  dt->offset = offset;
}

#endif /* TSTR_DATETIME_H */
