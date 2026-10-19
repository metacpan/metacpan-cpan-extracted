#ifndef TK_CAL_ISLAMIC_H
#define TK_CAL_ISLAMIC_H

/* The tabular Hijri calendars: months of 30 and 29 by turns, a 30-day
 * twelfth month in the eleven leap years of each thirty, from an epoch of
 * 19 July 622 (civil) or the day before (astronomical). Umm al-Qura follows
 * Saudi Arabia's table from 1300 AH to 1600 AH and the civil arithmetic
 * outside it, as ICU does. Days are since 1970. */

#define TK_ISLAMIC_CIVIL_EPOCH INT64_C(-492148)
#define TK_ISLAMIC_TBLA_EPOCH  INT64_C(-492149)

static int tk_islamic_leap(int64_t y) { return tk_cal_mod(14 + 11 * y, 30) < 11; }

static unsigned
tk_islamic_days_in_month(int64_t y, unsigned m)
{
    return (m % 2 == 1 || (m == 12 && tk_islamic_leap(y))) ? 30 : 29;
}

static int64_t
tk_islamic_to_days_from(int64_t epoch, int64_t y, unsigned m, unsigned d)
{
    return epoch - 1 + 354 * (y - 1) + tk_floor_div(3 + 11 * y, 30) + 29 * (int64_t)(m - 1) + m / 2 + d;
}

static void
tk_islamic_from_days_from(int64_t epoch, int64_t days, int64_t *y, unsigned *m, unsigned *d)
{
    int64_t prior;
    *y = tk_floor_div(30 * (days - epoch) + 10646, 10631);
    prior = days - tk_islamic_to_days_from(epoch, *y, 1, 1);
    *m = (unsigned)tk_floor_div(11 * prior + 330, 325);
    *d = (unsigned)(days - tk_islamic_to_days_from(epoch, *y, *m, 1) + 1);
}

static int64_t tk_islamic_civil_to_days(int64_t y, unsigned m, unsigned d) { return tk_islamic_to_days_from(TK_ISLAMIC_CIVIL_EPOCH, y, m, d); }
static void tk_islamic_civil_from_days(int64_t days, int64_t *y, unsigned *m, unsigned *d) { tk_islamic_from_days_from(TK_ISLAMIC_CIVIL_EPOCH, days, y, m, d); }
static int64_t tk_islamic_tbla_to_days(int64_t y, unsigned m, unsigned d) { return tk_islamic_to_days_from(TK_ISLAMIC_TBLA_EPOCH, y, m, d); }
static void tk_islamic_tbla_from_days(int64_t days, int64_t *y, unsigned *m, unsigned *d) { tk_islamic_from_days_from(TK_ISLAMIC_TBLA_EPOCH, days, y, m, d); }

/* Umm al-Qura */
static int tk_umalqura_tabled(int64_t y) { return y >= TK_UMALQURA_FIRST_YEAR && y <= TK_UMALQURA_LAST_YEAR; }

static unsigned
tk_umalqura_days_in_month(int64_t y, unsigned m)
{
    if (!tk_umalqura_tabled(y))
        return tk_islamic_days_in_month(y, m);
    return (tk_umalqura_months[y - TK_UMALQURA_FIRST_YEAR] >> (m - 1)) & 1 ? 30 : 29;
}

static int64_t
tk_umalqura_to_days(int64_t y, unsigned m, unsigned d)
{
    int64_t days;
    unsigned k;
    if (!tk_umalqura_tabled(y))
        return tk_islamic_civil_to_days(y, m, d);
    days = tk_umalqura_year_start[y - TK_UMALQURA_FIRST_YEAR];
    for (k = 1; k < m; k++)
        days += tk_umalqura_days_in_month(y, k);
    return days + d - 1;
}

static void
tk_umalqura_from_days(int64_t days, int64_t *y, unsigned *m, unsigned *d)
{
    unsigned lo, hi;
    int64_t left;
    if (days < tk_umalqura_year_start[0] || days >= tk_umalqura_year_start[TK_UMALQURA_LAST_YEAR - TK_UMALQURA_FIRST_YEAR + 1]) {
        tk_islamic_civil_from_days(days, y, m, d);
        return;
    }
    lo = 0;
    hi = TK_UMALQURA_LAST_YEAR - TK_UMALQURA_FIRST_YEAR;
    while (lo < hi) {
        unsigned mid = (lo + hi + 1) / 2;
        if (tk_umalqura_year_start[mid] <= days)
            lo = mid;
        else
            hi = mid - 1;
    }
    *y = TK_UMALQURA_FIRST_YEAR + lo;
    left = days - tk_umalqura_year_start[lo];
    for (*m = 1; *m < 12; (*m)++) {
        unsigned len = tk_umalqura_days_in_month(*y, *m);
        if (left < (int64_t)len)
            break;
        left -= len;
    }
    *d = (unsigned)left + 1;
}

/* The astronomical Hijri (and islamic-rgsa, which ICU computes the same
 * way) from a table of the years ICU gives for Gregorian 1000 to 3000. */
static int tk_hijri_tabled(int64_t y) { return y >= TK_HIJRI_FIRST_YEAR && y <= TK_HIJRI_LAST_YEAR; }
static int64_t tk_hijri_clamp(int64_t y) { return y < TK_HIJRI_FIRST_YEAR ? TK_HIJRI_FIRST_YEAR : y > TK_HIJRI_LAST_YEAR + 1 ? TK_HIJRI_LAST_YEAR + 1 : y; }

static unsigned
tk_hijri_days_in_month(int64_t y, unsigned m)
{
    int64_t i = tk_hijri_clamp(y) - TK_HIJRI_FIRST_YEAR;
    if (i > TK_HIJRI_LAST_YEAR - TK_HIJRI_FIRST_YEAR)
        i = TK_HIJRI_LAST_YEAR - TK_HIJRI_FIRST_YEAR;
    return (tk_hijri_months[i] >> (m - 1)) & 1 ? 30 : 29;
}

static int64_t
tk_hijri_to_days(int64_t y, unsigned m, unsigned d)
{
    int64_t days = tk_hijri_year_start[tk_hijri_clamp(y) - TK_HIJRI_FIRST_YEAR];
    unsigned k;
    for (k = 1; k < m; k++)
        days += tk_hijri_days_in_month(y, k);
    return days + d - 1;
}

static void
tk_hijri_from_days(int64_t days, int64_t *y, unsigned *m, unsigned *d)
{
    unsigned lo = 0, hi = TK_HIJRI_LAST_YEAR - TK_HIJRI_FIRST_YEAR;
    int64_t left;
    while (lo < hi) {
        unsigned mid = (lo + hi + 1) / 2;
        if (tk_hijri_year_start[mid] <= days)
            lo = mid;
        else
            hi = mid - 1;
    }
    *y = TK_HIJRI_FIRST_YEAR + lo;
    left = days - tk_hijri_year_start[lo];
    if (left < 0)
        left = 0;
    for (*m = 1; *m < 12; (*m)++) {
        unsigned len = tk_hijri_days_in_month(*y, *m);
        if (left < (int64_t)len)
            break;
        left -= len;
    }
    *d = (unsigned)left + 1;
}

static int
tk_hijri_leap(int64_t y)
{
    int64_t i = tk_hijri_clamp(y) - TK_HIJRI_FIRST_YEAR;
    return tk_hijri_year_start[i + 1] - tk_hijri_year_start[i] == 355;
}

static int
tk_umalqura_leap(int64_t y)
{
    if (!tk_umalqura_tabled(y))
        return tk_islamic_leap(y);
    return tk_umalqura_year_start[y - TK_UMALQURA_FIRST_YEAR + 1] - tk_umalqura_year_start[y - TK_UMALQURA_FIRST_YEAR] == 355;
}

#endif
