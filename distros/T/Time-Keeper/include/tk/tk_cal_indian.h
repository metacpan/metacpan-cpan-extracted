#ifndef TK_CAL_INDIAN_H
#define TK_CAL_INDIAN_H

/* The Indian national calendar (Saka era), as ICU reckons it: the year
 * begins on 22 March of the Gregorian year 78 later, 21 March when that
 * Gregorian year is leap; Chaitra then has 31 days instead of 30; the next
 * five months have 31 and the last six 30. Days are since 1970. */

#define TK_INDIAN_OFFSET 78

static int tk_indian_leap(int64_t y) { return tk_is_leap_year(y + TK_INDIAN_OFFSET); }

static int64_t
tk_indian_year_start(int64_t y)
{
    int64_t gy = y + TK_INDIAN_OFFSET;
    return tk_days_from_civil(gy, 3, tk_is_leap_year(gy) ? 21 : 22);
}

static unsigned
tk_indian_days_in_month(int64_t y, unsigned m)
{
    return m == 1 ? (tk_indian_leap(y) ? 31 : 30) : m <= 6 ? 31 : 30;
}

static int64_t
tk_indian_to_days(int64_t y, unsigned m, unsigned d)
{
    int64_t days = tk_indian_year_start(y);
    unsigned k;
    for (k = 1; k < m; k++)
        days += tk_indian_days_in_month(y, k);
    return days + d - 1;
}

static void
tk_indian_from_days(int64_t days, int64_t *y, unsigned *m, unsigned *d)
{
    int64_t gy, left;
    unsigned gm, gd;
    tk_civil_from_days(days, &gy, &gm, &gd);
    *y = gy - TK_INDIAN_OFFSET;
    if (days < tk_indian_year_start(*y))
        (*y)--;
    left = days - tk_indian_year_start(*y);
    for (*m = 1; *m < 12; (*m)++) {
        unsigned len = tk_indian_days_in_month(*y, *m);
        if (left < (int64_t)len)
            break;
        left -= len;
    }
    *d = (unsigned)left + 1;
}

#endif
