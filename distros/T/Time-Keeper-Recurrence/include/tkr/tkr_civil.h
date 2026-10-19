#ifndef TKR_CIVIL_H
#define TKR_CIVIL_H

/* Days since 1970-01-01 from a proleptic Gregorian date and back (Howard
 * Hinnant's algorithms), the weekday, the length of a month: the dist's
 * own copy, since the core keeps these out of its ABI. Weekdays are 1
 * Monday to 7 Sunday, as Time::Keeper counts them. */

static int64_t
tkr_days_from_civil(int64_t y, unsigned m, unsigned d)
{
    int64_t era, yoe, doy, doe;
    y -= m <= 2;
    era = (y >= 0 ? y : y - 399) / 400;
    yoe = y - era * 400;
    doy = (153 * (int64_t)(m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1;
    doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    return era * 146097 + doe - 719468;
}

static void
tkr_civil_from_days(int64_t z, int64_t *y, unsigned *m, unsigned *d)
{
    int64_t era, doe, yoe, doy, mp;
    z += 719468;
    era = (z >= 0 ? z : z - 146096) / 146097;
    doe = z - era * 146097;
    yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    mp = (5 * doy + 2) / 153;
    *d = (unsigned)(doy - (153 * mp + 2) / 5 + 1);
    *m = (unsigned)(mp < 10 ? mp + 3 : mp - 9);
    *y = yoe + era * 400 + (*m <= 2);
}

static int
tkr_is_leap(int64_t y)
{
    return (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;
}

static unsigned
tkr_days_in_month(int64_t y, unsigned m)
{
    static const unsigned n[13] = { 0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
    return m == 2 && tkr_is_leap(y) ? 29 : n[m];
}

/* 1 Monday .. 7 Sunday; 1970-01-01 was a Thursday. */
static unsigned
tkr_weekday(int64_t days)
{
    int64_t w = (days + 3) % 7;
    if (w < 0)
        w += 7;
    return (unsigned)w + 1;
}

#endif
