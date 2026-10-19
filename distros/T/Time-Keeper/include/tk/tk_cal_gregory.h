#ifndef TK_CAL_GREGORY_H
#define TK_CAL_GREGORY_H

/* The Gregorian family: gregory, buddhist (the year plus 543), japanese
 * (the Gregorian year under the emperors' eras) and roc (the year less
 * 1911). One proleptic Gregorian arithmetic under four year numberings. */

static int64_t tk_greg_to_days(int64_t y, unsigned m, unsigned d) { return tk_days_from_civil(y, m, d); }
static void tk_greg_from_days(int64_t days, int64_t *y, unsigned *m, unsigned *d) { tk_civil_from_days(days, y, m, d); }
static unsigned tk_greg_months(int64_t y) { PERL_UNUSED_VAR(y); return 12; }
static unsigned tk_greg_days_in_month(int64_t y, unsigned m) { return tk_days_in_month(y, m); }
static int tk_greg_leap(int64_t y) { return tk_is_leap_year(y); }

#define TK_BUDDHIST_OFFSET 543
static int64_t tk_buddhist_to_days(int64_t y, unsigned m, unsigned d) { return tk_days_from_civil(y - TK_BUDDHIST_OFFSET, m, d); }
static void tk_buddhist_from_days(int64_t days, int64_t *y, unsigned *m, unsigned *d) { tk_civil_from_days(days, y, m, d); *y += TK_BUDDHIST_OFFSET; }
static unsigned tk_buddhist_days_in_month(int64_t y, unsigned m) { return tk_days_in_month(y - TK_BUDDHIST_OFFSET, m); }
static int tk_buddhist_leap(int64_t y) { return tk_is_leap_year(y - TK_BUDDHIST_OFFSET); }

#define TK_ROC_OFFSET 1911
static int64_t tk_roc_to_days(int64_t y, unsigned m, unsigned d) { return tk_days_from_civil(y + TK_ROC_OFFSET, m, d); }
static void tk_roc_from_days(int64_t days, int64_t *y, unsigned *m, unsigned *d) { tk_civil_from_days(days, y, m, d); *y -= TK_ROC_OFFSET; }
static unsigned tk_roc_days_in_month(int64_t y, unsigned m) { return tk_days_in_month(y + TK_ROC_OFFSET, m); }
static int tk_roc_leap(int64_t y) { return tk_is_leap_year(y + TK_ROC_OFFSET); }

/* The Japanese era is the last whose first day is not after the day; the
 * year within it counts from the Gregorian year of that first day. A day
 * before the first era (Taika, 645) is in it with a year of 0 or less, as
 * ICU reads it. */
static unsigned
tk_japanese_era_index(int64_t days)
{
    unsigned lo = 0, hi = (unsigned)(sizeof tk_eras_japanese / sizeof(tk_era)) - 1;
    while (lo < hi) {
        unsigned mid = (lo + hi + 1) / 2;
        if (tk_eras_japanese[mid].start <= days)
            lo = mid;
        else
            hi = mid - 1;
    }
    return lo;
}

static int64_t
tk_japanese_era_start_year(unsigned era)
{
    int64_t y;
    unsigned m, d;
    tk_civil_from_days(tk_eras_japanese[era].start, &y, &m, &d);
    return y;
}

static void
tk_japanese_era_of(int64_t y, int64_t days, unsigned *era, int64_t *era_year)
{
    *era = tk_japanese_era_index(days);
    *era_year = y - tk_japanese_era_start_year(*era) + 1;
}

static int
tk_japanese_year_from_era(unsigned era, int64_t era_year, int64_t *y)
{
    if (era >= sizeof tk_eras_japanese / sizeof(tk_era))
        return 0;
    *y = tk_japanese_era_start_year(era) + era_year - 1;
    return 1;
}

#endif
