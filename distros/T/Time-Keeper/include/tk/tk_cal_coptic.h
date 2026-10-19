#ifndef TK_CAL_COPTIC_H
#define TK_CAL_COPTIC_H

/* Coptic and Ethiopic: twelve months of thirty days and a thirteenth of
 * five, six when the year leaves a remainder of 3 by 4. The Coptic epoch is
 * 29 August 284 (Julian), the Ethiopic 29 August 8; Amete Alem counts the
 * Ethiopic year from 5500 years earlier. Days are since 1970. */

#define TK_COPTIC_EPOCH   INT64_C(-615558)
#define TK_ETHIOPIC_EPOCH INT64_C(-716367)
#define TK_ETHIOAA_OFFSET 5500

static int64_t
tk_alexandrian_to_days(int64_t epoch, int64_t y, unsigned m, unsigned d)
{
    return epoch - 1 + 365 * (y - 1) + tk_floor_div(y, 4) + 30 * (int64_t)(m - 1) + d;
}

static void
tk_alexandrian_from_days(int64_t epoch, int64_t days, int64_t *y, unsigned *m, unsigned *d)
{
    *y = tk_floor_div(4 * (days - epoch) + 1463, 1461);
    *m = (unsigned)tk_floor_div(days - tk_alexandrian_to_days(epoch, *y, 1, 1), 30) + 1;
    *d = (unsigned)(days - tk_alexandrian_to_days(epoch, *y, *m, 1) + 1);
}

static int tk_alexandrian_leap(int64_t y) { return tk_cal_mod(y, 4) == 3; }
static unsigned tk_alexandrian_days_in_month(int64_t y, unsigned m) { return m < 13 ? 30 : tk_alexandrian_leap(y) ? 6 : 5; }
static unsigned tk_coptic_months(int64_t y) { PERL_UNUSED_VAR(y); return 13; }

static int64_t tk_coptic_to_days(int64_t y, unsigned m, unsigned d) { return tk_alexandrian_to_days(TK_COPTIC_EPOCH, y, m, d); }
static void tk_coptic_from_days(int64_t days, int64_t *y, unsigned *m, unsigned *d) { tk_alexandrian_from_days(TK_COPTIC_EPOCH, days, y, m, d); }
static unsigned tk_coptic_days_in_month(int64_t y, unsigned m) { return tk_alexandrian_days_in_month(y, m); }
static int tk_coptic_leap(int64_t y) { return tk_alexandrian_leap(y); }

static int64_t tk_ethiopic_to_days(int64_t y, unsigned m, unsigned d) { return tk_alexandrian_to_days(TK_ETHIOPIC_EPOCH, y, m, d); }
static void tk_ethiopic_from_days(int64_t days, int64_t *y, unsigned *m, unsigned *d) { tk_alexandrian_from_days(TK_ETHIOPIC_EPOCH, days, y, m, d); }
static unsigned tk_ethiopic_days_in_month(int64_t y, unsigned m) { return tk_alexandrian_days_in_month(y, m); }
static int tk_ethiopic_leap(int64_t y) { return tk_alexandrian_leap(y); }

/* Before the Incarnation the Ethiopic year is counted in Amete Alem. */
static void
tk_ethiopic_era_of(int64_t y, int64_t days, unsigned *era, int64_t *era_year)
{
    PERL_UNUSED_VAR(days);
    *era = y >= 1;
    *era_year = y >= 1 ? y : y + TK_ETHIOAA_OFFSET;
}

static int
tk_ethiopic_year_from_era(unsigned era, int64_t era_year, int64_t *y)
{
    if (era > 1)
        return 0;
    *y = era ? era_year : era_year - TK_ETHIOAA_OFFSET;
    return 1;
}

static int64_t tk_ethioaa_to_days(int64_t y, unsigned m, unsigned d) { return tk_alexandrian_to_days(TK_ETHIOPIC_EPOCH, y - TK_ETHIOAA_OFFSET, m, d); }
static void tk_ethioaa_from_days(int64_t days, int64_t *y, unsigned *m, unsigned *d) { tk_alexandrian_from_days(TK_ETHIOPIC_EPOCH, days, y, m, d); *y += TK_ETHIOAA_OFFSET; }
static unsigned tk_ethioaa_days_in_month(int64_t y, unsigned m) { return tk_alexandrian_days_in_month(y - TK_ETHIOAA_OFFSET, m); }
static int tk_ethioaa_leap(int64_t y) { return tk_alexandrian_leap(y - TK_ETHIOAA_OFFSET); }

#endif
