#ifndef TK_CAL_HEBREW_H
#define TK_CAL_HEBREW_H

/* The Hebrew calendar by the molad arithmetic of Reingold and Dershowitz,
 * with months counted from Tishri as Temporal does: Tishri 1, Heshvan 2,
 * Kislev 3, Tevet 4, Shevat 5, then in a leap year Adar I 6 and Adar II 7,
 * else Adar 6; Nisan to Elul follow. Month codes number Adar I M05L and
 * Adar (II) M06, so Nisan is M07 in every year. Days are since 1970. */

#define TK_HEBREW_EPOCH INT64_C(-2092590)

static int tk_hebrew_leap(int64_t y) { return tk_cal_mod(7 * y + 1, 19) < 7; }
static unsigned tk_hebrew_months(int64_t y) { return tk_hebrew_leap(y) ? 13 : 12; }

/* Days from the epoch to the molad of Tishri of the year, postponed a day
 * when it would start the year on a Sunday, Wednesday or Friday. */
static int64_t
tk_hebrew_elapsed(int64_t y)
{
    int64_t months = tk_floor_div(235 * y - 234, 19);
    int64_t parts = 12084 + 13753 * months;
    int64_t day = 29 * months + tk_floor_div(parts, 25920);
    return tk_cal_mod(3 * (day + 1), 7) < 3 ? day + 1 : day;
}

/* A further day or two so no year has 356 or 382 days. */
static int
tk_hebrew_delay(int64_t y)
{
    int64_t ny0 = tk_hebrew_elapsed(y - 1), ny1 = tk_hebrew_elapsed(y), ny2 = tk_hebrew_elapsed(y + 1);
    return ny2 - ny1 == 356 ? 2 : ny1 - ny0 == 382 ? 1 : 0;
}

static int64_t tk_hebrew_new_year(int64_t y) { return TK_HEBREW_EPOCH + tk_hebrew_elapsed(y) + tk_hebrew_delay(y); }
static unsigned tk_hebrew_days_in_year(int64_t y) { return (unsigned)(tk_hebrew_new_year(y + 1) - tk_hebrew_new_year(y)); }

static unsigned
tk_hebrew_days_in_month(int64_t y, unsigned m)
{
    unsigned diy = tk_hebrew_days_in_year(y);
    if (m == 2) return diy % 10 == 5 ? 30 : 29;
    if (m == 3) return diy % 10 == 3 ? 29 : 30;
    if (tk_hebrew_leap(y)) {
        /* Adar I 30, Adar II 29, then Nisan 30 and so on by turns */
        if (m == 6) return 30;
        if (m >= 7) return (m % 2 == 0) ? 30 : 29;
    }
    return (m % 2 == 1) ? 30 : 29;
}

static int64_t
tk_hebrew_to_days(int64_t y, unsigned m, unsigned d)
{
    int64_t days = tk_hebrew_new_year(y);
    unsigned k;
    for (k = 1; k < m; k++)
        days += tk_hebrew_days_in_month(y, k);
    return days + d - 1;
}

static void
tk_hebrew_from_days(int64_t days, int64_t *y, unsigned *m, unsigned *d)
{
    int64_t left;
    unsigned n;
    *y = tk_floor_div((days - TK_HEBREW_EPOCH) * 98496, 35975351);
    while (tk_hebrew_new_year(*y + 1) <= days)
        (*y)++;
    while (tk_hebrew_new_year(*y) > days)
        (*y)--;
    left = days - tk_hebrew_new_year(*y);
    n = tk_hebrew_months(*y);
    for (*m = 1; *m < n; (*m)++) {
        unsigned len = tk_hebrew_days_in_month(*y, *m);
        if (left < (int64_t)len)
            break;
        left -= len;
    }
    *d = (unsigned)left + 1;
}

static void
tk_hebrew_month_code(int64_t y, unsigned m, unsigned *number, int *leap)
{
    *leap = 0;
    if (!tk_hebrew_leap(y) || m <= 5)
        *number = m;
    else if (m == 6) {
        *number = 5;
        *leap = 1;
    }
    else
        *number = m - 1;
}

static int
tk_hebrew_month_from_code(int64_t y, unsigned number, int leap, unsigned *m)
{
    int ly = tk_hebrew_leap(y);
    if (leap) {
        if (number != 5 || !ly)
            return 0;
        *m = 6;
        return 1;
    }
    if (number < 1 || number > 12)
        return 0;
    *m = (ly && number >= 6) ? number + 1 : number;
    return 1;
}

#endif
