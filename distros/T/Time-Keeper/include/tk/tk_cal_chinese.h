#ifndef TK_CAL_CHINESE_H
#define TK_CAL_CHINESE_H

/* The Chinese and Dangi (Korean) lunisolar calendars, from tables of the
 * years 1000 to 3000 read off ICU, which computes them from the new moons
 * and the solar terms at Beijing's and Seoul's meridians. A year is named
 * by the Gregorian year it begins in (CLDR's related year); the year in the
 * sixty-year cycle is read from it, 1984 being the first of a cycle. Months
 * are ordinal, with the leap month taking the number of the month before it
 * and the letter L in its code, as Temporal has it. Days are since 1970. */

typedef struct tk_lunisolar {
    const tk_lunisolar_year *years;
    const int32_t *months_before;
    int32_t first, last;             /* the years tabled whole */
} tk_lunisolar;

static const tk_lunisolar tk_chinese_table = { tk_chinese_years, tk_chinese_months_before, TK_CHINESE_FIRST_YEAR, TK_CHINESE_LAST_YEAR - 1 };
static const tk_lunisolar tk_dangi_table = { tk_dangi_years, tk_dangi_months_before, TK_DANGI_FIRST_YEAR, TK_DANGI_LAST_YEAR - 1 };

static int tk_lunisolar_year_ok(const tk_lunisolar *t, int64_t y) { return y >= t->first && y <= t->last; }
/* The row after the last year holds its first day, so the last year's end is known. */
static int64_t tk_lunisolar_year_clamp(const tk_lunisolar *t, int64_t y) { return y < t->first ? t->first : y > t->last + 1 ? t->last + 1 : y; }

static unsigned
tk_lunisolar_days_in_month(const tk_lunisolar *t, int64_t y, unsigned m)
{
    const tk_lunisolar_year *r = &t->years[tk_lunisolar_year_clamp(t, y) - t->first];
    return (r->months >> (m - 1)) & 1 ? 30 : 29;
}

static unsigned tk_lunisolar_months(const tk_lunisolar *t, int64_t y) { return t->years[tk_lunisolar_year_clamp(t, y) - t->first].count; }
static int tk_lunisolar_leap(const tk_lunisolar *t, int64_t y) { return t->years[tk_lunisolar_year_clamp(t, y) - t->first].leap != 0; }

static int64_t
tk_lunisolar_to_days(const tk_lunisolar *t, int64_t y, unsigned m, unsigned d)
{
    const tk_lunisolar_year *r = &t->years[tk_lunisolar_year_clamp(t, y) - t->first];
    int64_t days = r->start;
    unsigned k;
    for (k = 1; k < m; k++)
        days += (r->months >> (k - 1)) & 1 ? 30 : 29;
    return days + d - 1;
}

/* The day's year: the last year whose first day is not after it. Days
 * before the first year or from the year after the last are clamped; the
 * value layer refuses them before they get here. */
static void
tk_lunisolar_from_days(const tk_lunisolar *t, int64_t days, int64_t *y, unsigned *m, unsigned *d)
{
    int lo = 0, hi = t->last - t->first;
    const tk_lunisolar_year *r;
    int64_t left;
    while (lo < hi) {
        int mid = (lo + hi + 1) / 2;
        if (t->years[mid].start <= days)
            lo = mid;
        else
            hi = mid - 1;
    }
    r = &t->years[lo];
    *y = t->first + lo;
    left = days - r->start;
    if (left < 0)
        left = 0;
    for (*m = 1; *m < r->count; (*m)++) {
        unsigned len = (r->months >> (*m - 1)) & 1 ? 30 : 29;
        if (left < (int64_t)len)
            break;
        left -= len;
    }
    *d = (unsigned)left + 1;
}

/* Months before the year, from the first year tabled; and back. */
static int64_t tk_lunisolar_months_before(const tk_lunisolar *t, int64_t y) { return t->months_before[tk_lunisolar_year_clamp(t, y) - t->first]; }

static void
tk_lunisolar_year_of_month_index(const tk_lunisolar *t, int64_t index, int64_t *y, unsigned *m)
{
    int lo = 0, hi = t->last - t->first;
    /* past the table either way: a year outside it, which the caller refuses */
    if (index >= t->months_before[hi + 1]) {
        *y = t->last + 1;
        *m = 1;
        return;
    }
    if (index < 0) {
        *y = t->first - 1;
        *m = 1;
        return;
    }
    while (lo < hi) {
        int mid = (lo + hi + 1) / 2;
        if (t->months_before[mid] <= index)
            lo = mid;
        else
            hi = mid - 1;
    }
    *y = t->first + lo;
    *m = (unsigned)(index - t->months_before[lo]) + 1;
    if (*m < 1)
        *m = 1;
    if (*m > t->years[lo].count)
        *m = t->years[lo].count;
}

static void
tk_lunisolar_month_code(const tk_lunisolar *t, int64_t y, unsigned m, unsigned *number, int *leap)
{
    unsigned L = t->years[tk_lunisolar_year_clamp(t, y) - t->first].leap;
    *leap = 0;
    if (!L || m < L)
        *number = m;
    else if (m == L) {
        *number = L - 1;
        *leap = 1;
    }
    else
        *number = m - 1;
}

static int
tk_lunisolar_month_from_code(const tk_lunisolar *t, int64_t y, unsigned number, int leap, unsigned *m)
{
    unsigned L = t->years[tk_lunisolar_year_clamp(t, y) - t->first].leap;
    if (number < 1 || number > 12)
        return 0;
    if (leap) {
        if (!L || L != number + 1)
            return 0;
        *m = L;
        return 1;
    }
    *m = (L && number >= L) ? number + 1 : number;
    return 1;
}

/* The year in the cycle of sixty, 1984 being a first. */
static int tk_lunisolar_cyclic_year(int64_t y) { return (int)tk_cal_mod(y - 1984, 60) + 1; }

/* ICU's extended year, as the era's year: the count from 2637 BCE. */
static void tk_lunisolar_era_of(int64_t y, int64_t days, unsigned *era, int64_t *era_year) { PERL_UNUSED_VAR(days); *era = 0; *era_year = y + 2637; }
static int tk_lunisolar_year_from_era(unsigned era, int64_t era_year, int64_t *y) { if (era) return 0; *y = era_year - 2637; return 1; }

#define TK_LUNISOLAR_FUNCTIONS(name, table) \
    static int64_t tk_##name##_to_days(int64_t y, unsigned m, unsigned d) { return tk_lunisolar_to_days(&table, y, m, d); } \
    static void tk_##name##_from_days(int64_t days, int64_t *y, unsigned *m, unsigned *d) { tk_lunisolar_from_days(&table, days, y, m, d); } \
    static unsigned tk_##name##_months(int64_t y) { return tk_lunisolar_months(&table, y); } \
    static unsigned tk_##name##_days_in_month(int64_t y, unsigned m) { return tk_lunisolar_days_in_month(&table, y, m); } \
    static int tk_##name##_leap(int64_t y) { return tk_lunisolar_leap(&table, y); } \
    static void tk_##name##_month_code(int64_t y, unsigned m, unsigned *number, int *leap) { tk_lunisolar_month_code(&table, y, m, number, leap); } \
    static int tk_##name##_month_from_code(int64_t y, unsigned number, int leap, unsigned *m) { return tk_lunisolar_month_from_code(&table, y, number, leap, m); }

TK_LUNISOLAR_FUNCTIONS(chinese, tk_chinese_table)
TK_LUNISOLAR_FUNCTIONS(dangi, tk_dangi_table)

#endif
