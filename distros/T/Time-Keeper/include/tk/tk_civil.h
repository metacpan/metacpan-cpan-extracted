#ifndef TK_CIVIL_H
#define TK_CIVIL_H

/* The civil core: instants and the proleptic Gregorian calendar, on
 * integers only. No struct tm, no time_t, no C library time functions, so
 * the answers are the same on every system and past 2038 on 32-bit ones.
 *
 * Days are counted from 1970-01-01 (day 0). Years are astronomical: the
 * year before 1 is 0, and before that -1.
 *
 * days_from_civil and civil_from_days are Howard Hinnant's era-based
 * algorithms ("chrono-Compatible Low-Level Date Algorithms"): a 400-year
 * era of 146097 days, no loops and no tables. */

#define TK_YEAR_MAX   999999999
#define TK_YEAR_MIN (-999999999)

#define TK_SECS_PER_DAY  86400
#define TK_NSECS_PER_SEC 1000000000

/* Day 0 is Rata Die 719163: RD 1 is 0001-01-01. */
#define TK_RD_EPOCH_OFFSET 719163

typedef struct tk_instant {
    int64_t sec;    /* seconds since 1970-01-01T00:00:00 UTC, leap seconds excluded */
    int32_t nsec;   /* 0 .. 999,999,999, also before 1970 */
} tk_instant;

typedef struct tk_civil {
    int32_t  year;
    uint8_t  month;     /* 1 .. 12 */
    uint8_t  day;       /* 1 .. 31 */
    uint8_t  hour;
    uint8_t  minute;
    uint8_t  second;    /* 60 only for a leap second, Phase 05 */
    uint8_t  dow;       /* 1 = Monday .. 7 = Sunday */
    uint16_t doy;       /* 1 .. 366 */
    int32_t  nsec;
} tk_civil;

#include "tk_leap_data.h"
#include "tk_leap.h"

/* Division and remainder that round towards minus infinity, where C's
 * round towards zero: -1 second is day -1, second 86399. */
static int64_t
tk_floor_div(int64_t a, int64_t b)
{
    int64_t q = a / b;
    if ((a % b != 0) && ((a < 0) != (b < 0)))
        q--;
    return q;
}

static int64_t
tk_floor_mod(int64_t a, int64_t b)
{
    return a - tk_floor_div(a, b) * b;
}

static int
tk_is_leap_year(int64_t y)
{
    return (y % 4 == 0) && (y % 100 != 0 || y % 400 == 0);
}

static unsigned
tk_days_in_month(int64_t y, unsigned m)
{
    static const unsigned char dim[12] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
    if (m == 2 && tk_is_leap_year(y))
        return 29;
    return dim[m - 1];
}

static int
tk_civil_date_valid(int64_t y, int64_t m, int64_t d)
{
    if (y < TK_YEAR_MIN || y > TK_YEAR_MAX)
        return 0;
    if (m < 1 || m > 12)
        return 0;
    if (d < 1 || d > (int64_t)tk_days_in_month(y, (unsigned)m))
        return 0;
    return 1;
}

static int64_t
tk_days_from_civil(int64_t y, unsigned m, unsigned d)
{
    int64_t era, yoe, doy, doe;
    y -= m <= 2;
    era = (y >= 0 ? y : y - 399) / 400;
    yoe = y - era * 400;
    doy = (153 * (int64_t)(m > 2 ? m - 3 : m + 9) + 2) / 5 + d - 1;
    doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    return era * 146097 + doe - 719468;
}

static void
tk_civil_from_days(int64_t z, int64_t *yp, unsigned *mp, unsigned *dp)
{
    int64_t era, doe, yoe, y, doy, mm;
    z += 719468;
    era = (z >= 0 ? z : z - 146096) / 146097;
    doe = z - era * 146097;
    yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    y = yoe + era * 400;
    doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    mm = (5 * doy + 2) / 153;
    *dp = (unsigned)(doy - (153 * mm + 2) / 5 + 1);
    *mp = (unsigned)(mm < 10 ? mm + 3 : mm - 9);
    *yp = y + (*mp <= 2);
}

/* 1 = Monday .. 7 = Sunday. Day 0, 1970-01-01, was a Thursday. */
static unsigned
tk_dow_from_days(int64_t z)
{
    return (unsigned)(tk_floor_mod(z + 3, 7) + 1);
}

static unsigned
tk_doy_from_civil(int64_t y, unsigned m, unsigned d)
{
    return (unsigned)(tk_days_from_civil(y, m, d) - tk_days_from_civil(y, 1, 1) + 1);
}

static unsigned
tk_quarter(unsigned m)
{
    return (m - 1) / 3 + 1;
}

static unsigned
tk_day_of_quarter(int64_t y, unsigned m, unsigned d)
{
    unsigned first = (tk_quarter(m) - 1) * 3 + 1;
    return (unsigned)(tk_days_from_civil(y, m, d) - tk_days_from_civil(y, first, 1) + 1);
}

/* ISO 8601: weeks start on Monday, and week 1 is the one holding the
 * year's first Thursday. The week year is the year of that week's
 * Thursday, which is not always the calendar year. */
static void
tk_iso_week(int64_t y, unsigned m, unsigned d, int64_t *wyp, unsigned *wp)
{
    int64_t z = tk_days_from_civil(y, m, d);
    int64_t thu = z - (int64_t)tk_dow_from_days(z) + 4;
    int64_t ty;
    unsigned tm, td;
    tk_civil_from_days(thu, &ty, &tm, &td);
    *wyp = ty;
    *wp = (unsigned)((thu - tk_days_from_civil(ty, 1, 1)) / 7 + 1);
}

/* strftime's %U (weeks start on Sunday) and %W (on Monday): days before
 * the year's first such day are in week 0. */
static unsigned
tk_week_number_sunday(int64_t y, unsigned m, unsigned d)
{
    int64_t z = tk_days_from_civil(y, m, d);
    unsigned yday = tk_doy_from_civil(y, m, d) - 1;
    unsigned wday = tk_dow_from_days(z) % 7;   /* 0 = Sunday */
    return (yday + 7 - wday) / 7;
}

static unsigned
tk_week_number_monday(int64_t y, unsigned m, unsigned d)
{
    int64_t z = tk_days_from_civil(y, m, d);
    unsigned yday = tk_doy_from_civil(y, m, d) - 1;
    unsigned wday = tk_dow_from_days(z) - 1;   /* 0 = Monday */
    return (yday + 7 - wday) / 7;
}

/* The instant's range: the first moment of TK_YEAR_MIN to the last
 * nanosecond of TK_YEAR_MAX. */
static int64_t
tk_sec_min(void)
{
    return tk_days_from_civil(TK_YEAR_MIN, 1, 1) * TK_SECS_PER_DAY;
}

static int64_t
tk_sec_max(void)
{
    return tk_days_from_civil(TK_YEAR_MAX, 12, 31) * TK_SECS_PER_DAY + TK_SECS_PER_DAY - 1;
}

/* A leap second's nanoseconds run past a whole second (tk_leap.h): only
 * on the last second of a leap day. */
static int
tk_instant_valid(const tk_instant *t)
{
    if (t->sec < tk_sec_min() || t->sec > tk_sec_max() || t->nsec < 0)
        return 0;
    if (t->nsec < TK_NSECS_PER_SEC)
        return 1;
    return t->nsec < 2 * TK_NSECS_PER_SEC && tk_is_leap_day_end(t->sec);
}

static void
tk_civil_from_instant(const tk_instant *t, tk_civil *c)
{
    int64_t z = tk_floor_div(t->sec, TK_SECS_PER_DAY);
    int64_t s = t->sec - z * TK_SECS_PER_DAY;
    int64_t y;
    unsigned m, d;
    tk_civil_from_days(z, &y, &m, &d);
    c->year   = (int32_t)y;
    c->month  = (uint8_t)m;
    c->day    = (uint8_t)d;
    c->hour   = (uint8_t)(s / 3600);
    c->minute = (uint8_t)(s / 60 % 60);
    c->second = (uint8_t)(s % 60);
    c->dow    = (uint8_t)tk_dow_from_days(z);
    c->doy    = (uint16_t)tk_doy_from_civil(y, m, d);
    c->nsec   = t->nsec;
    if (t->nsec >= TK_NSECS_PER_SEC) {
        c->second = 60;
        c->nsec -= TK_NSECS_PER_SEC;
    }
}

/* The fields are taken as checked. Hours, minutes and seconds past their
 * usual ends simply carry, which later phases rely on, except second 60,
 * which is a leap second: the second 59 with a second more of nanoseconds
 * (tk_leap.h). Whether that names a real leap second is tk_instant_valid's
 * to say, once any offset has been taken off. */
static void
tk_instant_from_civil(int64_t y, unsigned m, unsigned d,
                      int64_t hour, int64_t minute, int64_t second, int32_t nsec,
                      tk_instant *t)
{
    if (second == 60) {
        second = 59;
        nsec += TK_NSECS_PER_SEC;
    }
    t->sec = tk_days_from_civil(y, m, d) * TK_SECS_PER_DAY
           + hour * 3600 + minute * 60 + second;
    t->nsec = nsec;
}

/* Rata Die, as DateTime keeps it: day 1 is 0001-01-01, and the seconds
 * and nanoseconds into that day. */
static void
tk_rd_values(const tk_instant *t, int64_t *rd_days, int64_t *rd_secs, int32_t *rd_nsecs)
{
    int64_t z = tk_floor_div(t->sec, TK_SECS_PER_DAY);
    *rd_days = z + TK_RD_EPOCH_OFFSET;
    *rd_secs = t->sec - z * TK_SECS_PER_DAY;
    *rd_nsecs = t->nsec;
    if (*rd_nsecs >= TK_NSECS_PER_SEC) {   /* 23:59:60 is second 86400 of its day */
        *rd_secs += 1;
        *rd_nsecs -= TK_NSECS_PER_SEC;
    }
}

/* Julian Day as a whole day count and the fraction of a day since the
 * Julian Day began (noon UTC), so a caller can keep all the precision a
 * double would lose. JD 2440587.5 is 1970-01-01T00:00:00. */
/* The UTC day of an instant and the fraction of it gone. A day that ended
 * with a leap second is 86,401 seconds long, and its fraction runs from 0
 * to 1 over all of them, as DateTime counts it: 23:59:60 is not past the
 * end of the day. */
static void
tk_day_fraction(const tk_instant *t, int64_t *day, double *frac)
{
    int64_t z = tk_floor_div(t->sec, TK_SECS_PER_DAY);
    int64_t into = t->sec - z * TK_SECS_PER_DAY;
    int64_t len = tk_is_leap_day_end(z * TK_SECS_PER_DAY + TK_SECS_PER_DAY - 1)
                ? TK_SECS_PER_DAY + 1 : TK_SECS_PER_DAY;
    *day = z;
    *frac = ((double)into + (double)t->nsec / TK_NSECS_PER_SEC) / (double)len;
}

static void
tk_julian_day(const tk_instant *t, int64_t *jd_int, double *jd_frac)
{
    int64_t z;
    double f;
    tk_day_fraction(t, &z, &f);
    *jd_int = z + 2440587;
    *jd_frac = f + 0.5;
    if (*jd_frac >= 1.0) {
        *jd_int += 1;
        *jd_frac -= 1.0;
    }
}

/* Modified Julian Day: whole days since 1858-11-17T00:00:00, and the
 * fraction of the day. */
static void
tk_mjd(const tk_instant *t, int64_t *mjd_int, double *mjd_frac)
{
    int64_t z;
    tk_day_fraction(t, &z, mjd_frac);
    *mjd_int = z + 40587;
}

#endif
