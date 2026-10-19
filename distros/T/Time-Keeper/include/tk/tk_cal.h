#ifndef TK_CAL_H
#define TK_CAL_H

/* The calendars: a registry of ids and, for each, the functions that turn
 * a day number (days since 1970, in the value's wall-clock date) into the
 * calendar's year, month and day and back. Months are ordinal within the
 * year, as Temporal counts them: in a Hebrew leap year Adar I is the sixth
 * month and Nisan the eighth. Years are continuous and may be zero or
 * negative; eras are a reading of the year, never the stored value.
 *
 * Thirteen calendars are arithmetic; the four that follow the moon and the
 * sun (chinese, dangi, islamic, islamic-rgsa) are read from tables of what
 * ICU computes for the years 1000 to 3000 and refuse days outside them. */

#include "tk/tk_cal_eras.h"
#include "tk/tk_cal_umalqura_data.h"
#include "tk/tk_cal_lunar_data.h"

enum {
    TK_CAL_GREGORY, TK_CAL_BUDDHIST, TK_CAL_JAPANESE, TK_CAL_ROC, TK_CAL_COPTIC,
    TK_CAL_ETHIOPIC, TK_CAL_ETHIOAA, TK_CAL_HEBREW, TK_CAL_ISLAMIC_CIVIL,
    TK_CAL_ISLAMIC_TBLA, TK_CAL_ISLAMIC_UMALQURA, TK_CAL_ISLAMIC, TK_CAL_ISLAMIC_RGSA,
    TK_CAL_PERSIAN, TK_CAL_INDIAN, TK_CAL_CHINESE, TK_CAL_DANGI, TK_CAL_COUNT
};
enum { TK_CALK_ARITHMETIC, TK_CALK_TABULAR, TK_CALK_ASTRONOMICAL };

/* Years are kept within this so no day count overflows. */
#define TK_CAL_YEAR_LIMIT INT64_C(1000000000)

typedef struct tk_calendar {
    const char   *id;
    const char   *name;
    int           kind;
    unsigned      max_months;
    const tk_era *eras;
    unsigned      n_eras;
    int64_t  (*to_days)(int64_t y, unsigned m, unsigned d);
    void     (*from_days)(int64_t days, int64_t *y, unsigned *m, unsigned *d);
    unsigned (*months_in_year)(int64_t y);
    unsigned (*days_in_month)(int64_t y, unsigned m);
    int      (*is_leap_year)(int64_t y);
    void     (*era_of)(int64_t y, int64_t days, unsigned *era, int64_t *era_year);
    int      (*year_from_era)(unsigned era, int64_t era_year, int64_t *y);
    /* the month's code number and whether it is a leap month; NULL where the number is the month */
    void     (*month_code)(int64_t y, unsigned m, unsigned *number, int *leap);
    int      (*month_from_code)(int64_t y, unsigned number, int leap, unsigned *m);
    /* the years tabled, for a calendar read from a table; 0 and 0 for no bound */
    int64_t   year_min, year_max;
} tk_calendar;

static int64_t
tk_cal_mod(int64_t a, int64_t b)
{
    int64_t r = a % b;
    return r < 0 ? r + b : r;
}

/* ---- eras shared by families -------------------------------------------- */

/* One era counting from year 1. */
static void
tk_era_single(int64_t y, int64_t days, unsigned *era, int64_t *era_year)
{
    PERL_UNUSED_VAR(days);
    *era = 0;
    *era_year = y;
}

static int
tk_era_single_year(unsigned era, int64_t era_year, int64_t *y)
{
    if (era != 0)
        return 0;
    *y = era_year;
    return 1;
}

/* An era before year 1 counting backwards (bce, broc, bh) and one from it. */
static void
tk_era_before_after(int64_t y, int64_t days, unsigned *era, int64_t *era_year)
{
    PERL_UNUSED_VAR(days);
    *era = y >= 1;
    *era_year = y >= 1 ? y : 1 - y;
}

static int
tk_era_before_after_year(unsigned era, int64_t era_year, int64_t *y)
{
    if (era > 1)
        return 0;
    *y = era ? era_year : 1 - era_year;
    return 1;
}

#include "tk/tk_cal_gregory.h"
#include "tk/tk_cal_coptic.h"
#include "tk/tk_cal_islamic.h"
#include "tk/tk_cal_hebrew.h"
#include "tk/tk_cal_persian.h"
#include "tk/tk_cal_indian.h"
#include "tk/tk_cal_chinese.h"

#define TK_CAL_ERAS(id) tk_eras_##id, (unsigned)(sizeof(tk_eras_##id) / sizeof(tk_era))

static const tk_calendar tk_calendars[TK_CAL_COUNT] = {
    { "gregory", "Gregorian", TK_CALK_ARITHMETIC, 12, TK_CAL_ERAS(gregory),
      tk_greg_to_days, tk_greg_from_days, tk_greg_months, tk_greg_days_in_month, tk_greg_leap,
      tk_era_before_after, tk_era_before_after_year, NULL, NULL },
    { "buddhist", "Buddhist", TK_CALK_ARITHMETIC, 12, TK_CAL_ERAS(buddhist),
      tk_buddhist_to_days, tk_buddhist_from_days, tk_greg_months, tk_buddhist_days_in_month, tk_buddhist_leap,
      tk_era_single, tk_era_single_year, NULL, NULL },
    { "japanese", "Japanese", TK_CALK_ARITHMETIC, 12, TK_CAL_ERAS(japanese),
      tk_greg_to_days, tk_greg_from_days, tk_greg_months, tk_greg_days_in_month, tk_greg_leap,
      tk_japanese_era_of, tk_japanese_year_from_era, NULL, NULL },
    { "roc", "Minguo", TK_CALK_ARITHMETIC, 12, TK_CAL_ERAS(roc),
      tk_roc_to_days, tk_roc_from_days, tk_greg_months, tk_roc_days_in_month, tk_roc_leap,
      tk_era_before_after, tk_era_before_after_year, NULL, NULL },
    { "coptic", "Coptic", TK_CALK_ARITHMETIC, 13, TK_CAL_ERAS(coptic),
      tk_coptic_to_days, tk_coptic_from_days, tk_coptic_months, tk_coptic_days_in_month, tk_coptic_leap,
      tk_era_before_after, tk_era_before_after_year, NULL, NULL },
    { "ethiopic", "Ethiopic", TK_CALK_ARITHMETIC, 13, TK_CAL_ERAS(ethiopic),
      tk_ethiopic_to_days, tk_ethiopic_from_days, tk_coptic_months, tk_ethiopic_days_in_month, tk_ethiopic_leap,
      tk_ethiopic_era_of, tk_ethiopic_year_from_era, NULL, NULL },
    { "ethioaa", "Ethiopic Amete Alem", TK_CALK_ARITHMETIC, 13, TK_CAL_ERAS(ethioaa),
      tk_ethioaa_to_days, tk_ethioaa_from_days, tk_coptic_months, tk_ethioaa_days_in_month, tk_ethioaa_leap,
      tk_era_single, tk_era_single_year, NULL, NULL },
    { "hebrew", "Hebrew", TK_CALK_ARITHMETIC, 13, TK_CAL_ERAS(hebrew),
      tk_hebrew_to_days, tk_hebrew_from_days, tk_hebrew_months, tk_hebrew_days_in_month, tk_hebrew_leap,
      tk_era_single, tk_era_single_year, tk_hebrew_month_code, tk_hebrew_month_from_code },
    { "islamic-civil", "Hijri (tabular, civil epoch)", TK_CALK_ARITHMETIC, 12, TK_CAL_ERAS(islamic_civil),
      tk_islamic_civil_to_days, tk_islamic_civil_from_days, tk_greg_months, tk_islamic_days_in_month, tk_islamic_leap,
      tk_era_single, tk_era_single_year, NULL, NULL },
    { "islamic-tbla", "Hijri (tabular, astronomical epoch)", TK_CALK_ARITHMETIC, 12, TK_CAL_ERAS(islamic_tbla),
      tk_islamic_tbla_to_days, tk_islamic_tbla_from_days, tk_greg_months, tk_islamic_days_in_month, tk_islamic_leap,
      tk_era_single, tk_era_single_year, NULL, NULL },
    { "islamic-umalqura", "Hijri (Umm al-Qura)", TK_CALK_TABULAR, 12, TK_CAL_ERAS(islamic_umalqura),
      tk_umalqura_to_days, tk_umalqura_from_days, tk_greg_months, tk_umalqura_days_in_month, tk_umalqura_leap,
      tk_era_single, tk_era_single_year, NULL, NULL },
    { "islamic", "Hijri", TK_CALK_ASTRONOMICAL, 12, TK_CAL_ERAS(islamic),
      tk_hijri_to_days, tk_hijri_from_days, tk_greg_months, tk_hijri_days_in_month, tk_hijri_leap,
      tk_era_single, tk_era_single_year, NULL, NULL, TK_HIJRI_FIRST_YEAR, TK_HIJRI_LAST_YEAR },
    { "islamic-rgsa", "Hijri (Saudi Arabia, sighting)", TK_CALK_ASTRONOMICAL, 12, TK_CAL_ERAS(islamic_rgsa),
      tk_hijri_to_days, tk_hijri_from_days, tk_greg_months, tk_hijri_days_in_month, tk_hijri_leap,
      tk_era_single, tk_era_single_year, NULL, NULL, TK_HIJRI_FIRST_YEAR, TK_HIJRI_LAST_YEAR },
    { "persian", "Persian", TK_CALK_ARITHMETIC, 12, TK_CAL_ERAS(persian),
      tk_persian_to_days, tk_persian_from_days, tk_greg_months, tk_persian_days_in_month, tk_persian_leap,
      tk_era_single, tk_era_single_year, NULL, NULL },
    { "indian", "Indian National", TK_CALK_ARITHMETIC, 12, TK_CAL_ERAS(indian),
      tk_indian_to_days, tk_indian_from_days, tk_greg_months, tk_indian_days_in_month, tk_indian_leap,
      tk_era_single, tk_era_single_year, NULL, NULL },
    { "chinese", "Chinese", TK_CALK_ASTRONOMICAL, 13, TK_CAL_ERAS(chinese),
      tk_chinese_to_days, tk_chinese_from_days, tk_chinese_months, tk_chinese_days_in_month, tk_chinese_leap,
      tk_lunisolar_era_of, tk_lunisolar_year_from_era, tk_chinese_month_code, tk_chinese_month_from_code,
      TK_CHINESE_FIRST_YEAR, TK_CHINESE_LAST_YEAR - 1 },
    { "dangi", "Dangi", TK_CALK_ASTRONOMICAL, 13, TK_CAL_ERAS(dangi),
      tk_dangi_to_days, tk_dangi_from_days, tk_dangi_months, tk_dangi_days_in_month, tk_dangi_leap,
      tk_lunisolar_era_of, tk_lunisolar_year_from_era, tk_dangi_month_code, tk_dangi_month_from_code,
      TK_DANGI_FIRST_YEAR, TK_DANGI_LAST_YEAR - 1 }
};

/* The id, or an alias, case blind; -1 when unknown. */
static int
tk_cal_find(const char *s, STRLEN len)
{
    static const struct { const char *alias; int id; } aliases[] = {
        { "iso8601", TK_CAL_GREGORY }, { "gregorian", TK_CAL_GREGORY },
        { "ethiopic-amete-alem", TK_CAL_ETHIOAA }, { "islamicc", TK_CAL_ISLAMIC_CIVIL }
    };
    char buf[32];
    STRLEN i;
    int k;
    if (len == 0 || len >= sizeof buf)
        return -1;
    for (i = 0; i < len; i++)
        buf[i] = (char)toLOWER(s[i]);
    buf[len] = '\0';
    for (k = 0; k < TK_CAL_COUNT; k++)
        if (strEQ(buf, tk_calendars[k].id))
            return k;
    for (i = 0; i < sizeof aliases / sizeof aliases[0]; i++)
        if (strEQ(buf, aliases[i].alias))
            return aliases[i].id;
    return -1;
}

/* ---- the fields of a day in a calendar ---------------------------------- */

typedef struct tk_calfields {
    int64_t  year;              /* the calendar's continuous year */
    int64_t  era_year;          /* the year within the era */
    unsigned era;               /* an index into the calendar's eras */
    unsigned month;             /* ordinal, 1 .. months_in_year */
    unsigned day;
    unsigned doy;               /* 1 .. days_in_year */
    unsigned months_in_year;
    unsigned days_in_month;
    unsigned days_in_year;
    unsigned month_number;      /* the number in the month code; 5 for both M05 and M05L */
    int      leap_month;
    int      leap_year;
} tk_calfields;

static unsigned
tk_cal_days_in_year(const tk_calendar *cal, int64_t y)
{
    return (unsigned)(cal->to_days(y + 1, 1, 1) - cal->to_days(y, 1, 1));
}

static void
tk_cal_fields(const tk_calendar *cal, int64_t days, tk_calfields *f)
{
    cal->from_days(days, &f->year, &f->month, &f->day);
    f->doy = (unsigned)(days - cal->to_days(f->year, 1, 1) + 1);
    f->months_in_year = cal->months_in_year(f->year);
    f->days_in_month = cal->days_in_month(f->year, f->month);
    f->days_in_year = tk_cal_days_in_year(cal, f->year);
    f->leap_year = cal->is_leap_year(f->year);
    cal->era_of(f->year, days, &f->era, &f->era_year);
    if (cal->month_code)
        cal->month_code(f->year, f->month, &f->month_number, &f->leap_month);
    else {
        f->month_number = f->month;
        f->leap_month = 0;
    }
}

/* ---- months and years as arithmetic ------------------------------------ */

/* Months elapsed before the year: an absolute index of months, so that adding
 * months is adding to it. Every calendar here has a fixed count a year but
 * the Hebrew, whose 19-year cycle has 235. */
static int64_t
tk_cal_months_before(const tk_calendar *cal, int64_t y)
{
    if (cal == &tk_calendars[TK_CAL_HEBREW])
        return tk_floor_div(235 * y - 234, 19);
    if (cal == &tk_calendars[TK_CAL_CHINESE])
        return tk_lunisolar_months_before(&tk_chinese_table, y);
    if (cal == &tk_calendars[TK_CAL_DANGI])
        return tk_lunisolar_months_before(&tk_dangi_table, y);
    return (int64_t)cal->max_months * y;
}

/* 1 when the year is within what the calendar can give. */
static int
tk_cal_year_ok(const tk_calendar *cal, int64_t y)
{
    if (cal->year_min || cal->year_max)
        return y >= cal->year_min && y <= cal->year_max;
    return y >= -TK_CAL_YEAR_LIMIT && y <= TK_CAL_YEAR_LIMIT;
}

/* 1 when the day is within what the calendar can give. */
static int
tk_cal_days_ok(const tk_calendar *cal, int64_t days)
{
    if (!(cal->year_min || cal->year_max))
        return 1;
    return days >= cal->to_days(cal->year_min, 1, 1) && days < cal->to_days(cal->year_max + 1, 1, 1);
}

/* The year an absolute month index falls in, and the month within it. */
static void
tk_cal_year_of_month_index(const tk_calendar *cal, int64_t index, int64_t *y, unsigned *m)
{
    if (cal == &tk_calendars[TK_CAL_CHINESE]) {
        tk_lunisolar_year_of_month_index(&tk_chinese_table, index, y, m);
        return;
    }
    if (cal == &tk_calendars[TK_CAL_DANGI]) {
        tk_lunisolar_year_of_month_index(&tk_dangi_table, index, y, m);
        return;
    }
    if (cal == &tk_calendars[TK_CAL_HEBREW]) {
        *y = tk_floor_div(19 * index + 234, 235);
        while (tk_cal_months_before(cal, *y + 1) <= index)
            (*y)++;
        while (tk_cal_months_before(cal, *y) > index)
            (*y)--;
    }
    else
        *y = tk_floor_div(index, cal->max_months);
    *m = (unsigned)(index - tk_cal_months_before(cal, *y)) + 1;
}

/* The day a short month leaves: kept (wrap, on into the next month), cut to
 * the month's last (limit), or, when it was its month's last, the last again
 * (preserve). */
static void
tk_cal_settle_day(const tk_calendar *cal, int64_t y, unsigned m, unsigned d, int was_last, int eom,
                  int64_t *ry, unsigned *rm, unsigned *rd)
{
    unsigned last = cal->days_in_month(y, m);
    if (eom == TK_EOM_PRESERVE && was_last)
        d = last;
    else if (eom != TK_EOM_WRAP && d > last)
        d = last;
    if (d <= last) {
        *ry = y;
        *rm = m;
        *rd = d;
        return;
    }
    cal->from_days(cal->to_days(y, m, 1) + d - 1, ry, rm, rd);
}

/* The date months on, counting the calendar's ordinal months. */
static void
tk_cal_add_months(const tk_calendar *cal, int64_t y, unsigned m, unsigned d, int64_t months, int eom,
                  int64_t *ry, unsigned *rm, unsigned *rd)
{
    int64_t ty;
    unsigned tm;
    tk_cal_year_of_month_index(cal, tk_cal_months_before(cal, y) + (m - 1) + months, &ty, &tm);
    tk_cal_settle_day(cal, ty, tm, d, d == cal->days_in_month(y, m), eom, ry, rm, rd);
}

/* The date years on, keeping the month by its code. A leap month moved to a
 * year without one keeps its number without the L (a Chinese leap sixth
 * month becomes the sixth); the Hebrew Adar I, which comes before Adar,
 * lands in Adar, as ICU and Temporal have it. */
static void
tk_cal_add_years(const tk_calendar *cal, int64_t y, unsigned m, unsigned d, int64_t years, int eom,
                 int64_t *ry, unsigned *rm, unsigned *rd)
{
    int64_t ty = y + years;
    unsigned tm = m;
    if (cal->month_code) {
        unsigned number;
        int leap;
        cal->month_code(y, m, &number, &leap);
        if (!cal->month_from_code(ty, number, leap, &tm)
            && !cal->month_from_code(ty, cal == &tk_calendars[TK_CAL_HEBREW] ? number + 1 : number, 0, &tm))
            tm = cal->months_in_year(ty);
    }
    else if (tm > cal->months_in_year(ty))
        tm = cal->months_in_year(ty);
    tk_cal_settle_day(cal, ty, tm, d, d == cal->days_in_month(y, m), eom, ry, rm, rd);
}

/* The Gregorian year the calendar's year begins in: CLDR's related year. */
static int64_t
tk_cal_related_year(const tk_calendar *cal, int64_t y)
{
    int64_t gy;
    unsigned gm, gd;
    tk_civil_from_days(cal->to_days(y, 1, 1), &gy, &gm, &gd);
    return gy;
}

#endif
