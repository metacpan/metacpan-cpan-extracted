#ifndef TK_CAL_PERSIAN_H
#define TK_CAL_PERSIAN_H

/* The Persian (Solar Hijri) calendar by ICU's 33-year arithmetic: six
 * months of 31 days, five of 30, a last of 29 or 30, a leap year when
 * (25 y + 11) mod 33 < 8, from an epoch of 21 March 622 (ICU's, a day
 * before Reingold and Dershowitz's). Not the
 * astronomical equinox and not Birashk's cycle: ICU's numbers are what
 * CLDR's data is built for. Days are since 1970. */

#include "tk/tk_cal_persian_data.h"

#define TK_PERSIAN_EPOCH INT64_C(-492268)

/* ICU moves the leap year one later in 78 years of the 33-year rule's
 * reckoning between 1502 and 2987 AP; the engine follows it. */
static int
tk_persian_moved_has(int64_t y)
{
    int lo = 0, hi = TK_PERSIAN_MOVED_COUNT - 1;
    if (y < tk_persian_moved[0] || y > tk_persian_moved[hi])
        return 0;
    while (lo <= hi) {
        int mid = (lo + hi) / 2;
        if (tk_persian_moved[mid] == y) return 1;
        if (tk_persian_moved[mid] < y) lo = mid + 1; else hi = mid - 1;
    }
    return 0;
}

static int tk_persian_leap(int64_t y) { return (tk_cal_mod(25 * y + 11, 33) < 8) ^ tk_persian_moved_has(y) ^ tk_persian_moved_has(y - 1); }

static unsigned
tk_persian_days_in_month(int64_t y, unsigned m)
{
    return m <= 6 ? 31 : m <= 11 ? 30 : tk_persian_leap(y) ? 30 : 29;
}

/* The day before 1 Farvardin. */
static int64_t
tk_persian_year_start(int64_t y)
{
    return TK_PERSIAN_EPOCH - 1 + 365 * (y - 1) + tk_floor_div(8 * y + 21, 33) - tk_persian_moved_has(y - 1);
}

static int64_t
tk_persian_to_days(int64_t y, unsigned m, unsigned d)
{
    return tk_persian_year_start(y) + (m <= 7 ? 31 * (int64_t)(m - 1) : 186 + 30 * (int64_t)(m - 7)) + d;
}

static void
tk_persian_from_days(int64_t days, int64_t *y, unsigned *m, unsigned *d)
{
    int64_t doy;
    *y = 1 + tk_floor_div(33 * (days - TK_PERSIAN_EPOCH) + 3, 12053);
    doy = days - tk_persian_year_start(*y) - 1;
    while (doy < 0) {
        (*y)--;
        doy = days - tk_persian_year_start(*y) - 1;
    }
    while (doy >= (int64_t)(tk_persian_leap(*y) ? 366 : 365)) {
        (*y)++;
        doy = days - tk_persian_year_start(*y) - 1;
    }
    *m = doy < 186 ? (unsigned)(doy / 31) + 1 : (unsigned)((doy - 186) / 30) + 7;
    *d = (unsigned)(days - tk_persian_to_days(*y, *m, 1) + 1);
}

#endif
