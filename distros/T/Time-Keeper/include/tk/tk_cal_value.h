#ifndef TK_CAL_VALUE_H
#define TK_CAL_VALUE_H

/* A value in a calendar: the calendar byte read, the fields of its
 * wall-clock date computed (not cached: the arithmetic calendars are a few
 * divisions), and the checks every caller shares. */

static const tk_calendar *
tk_cal_of(const tk_value *v)
{
    return &tk_calendars[v->calendar < TK_CAL_COUNT ? v->calendar : 0];
}

static const char *
tk_cal_id_list(void)
{
    static char list[400];
    if (!list[0]) {
        int k;
        for (k = 0; k < TK_CAL_COUNT; k++) {
            if (k) strcat(list, k + 1 == TK_CAL_COUNT ? " or " : ", ");
            strcat(list, tk_calendars[k].id);
        }
    }
    return list;
}

static int
tk_cal_id_from_sv(pTHX_ SV *sv, const char *what)
{
    STRLEN len;
    const char *s = SvPV(sv, len);
    int id = tk_cal_find(s, len);
    if (id < 0)
        croak("%s: '%s' is not a calendar: %s", what, s, tk_cal_id_list());
    return id;
}

/* The calendar an argument list asks for, built, or the Gregorian. */
/* A locale code's -u-ca- extension (R14i): the code before it and the
 * calendar id after it, "th-u-ca-buddhist" or "th_u_ca_buddhist"; the
 * extension ends the code. 1 when it is there. */
static int
tk_locale_split_ca(const char *s, STRLEN len, STRLEN *code_len, const char **ca, STRLEN *ca_len)
{
    STRLEN i;
    for (i = 0; i + 6 <= len; i++) {
        if ((s[i] == '-' || s[i] == '_') && (s[i + 1] == 'u' || s[i + 1] == 'U') && (s[i + 2] == '-' || s[i + 2] == '_')
            && (s[i + 3] == 'c' || s[i + 3] == 'C') && (s[i + 4] == 'a' || s[i + 4] == 'A') && (s[i + 5] == '-' || s[i + 5] == '_')) {
            *code_len = i;
            *ca = s + i + 6;
            *ca_len = len - i - 6;
            return 1;
        }
    }
    *code_len = len;
    *ca = NULL;
    *ca_len = 0;
    return 0;
}

/* The calendar a locale code's -u-ca- extension names, or -1 when it has
 * none; an id that is not known dies. */
static int
tk_cal_from_locale_sv(pTHX_ SV *sv, const char *what)
{
    STRLEN len, code_len, ca_len;
    const char *s, *ca;
    int id;
    if (!sv || !SvOK(sv))
        return -1;
    s = SvPV(sv, len);
    if (!tk_locale_split_ca(s, len, &code_len, &ca, &ca_len))
        return -1;
    id = tk_cal_find(ca, ca_len);
    if (id < 0)
        croak("%s: the locale code '%" SVf "' names a calendar that is not known", what, SVfARG(sv));
    return id;
}

static int
tk_cal_from_locale_args(pTHX_ const tk_args *a, const char *what)
{
    int id = a->v[TK_A_LOCALE] ? tk_cal_from_locale_sv(aTHX_ a->v[TK_A_LOCALE], what) : -1;
    return id < 0 ? TK_CAL_GREGORY : id;
}

/* The calendar given, else the one the locale code's extension names, else the Gregorian. */
#define tk_args_calendar(a, what) ((a)->v[TK_A_CALENDAR] ? tk_cal_arg(aTHX_ (a)->v[TK_A_CALENDAR], what) : tk_cal_from_locale_args(aTHX_ (a), what))

/* Every calendar is built; the ones read from a table have bounds. */
static void
tk_cal_check_built(pTHX_ int id, const char *what)
{
    PERL_UNUSED_VAR(id);
    PERL_UNUSED_VAR(what);
}

static void
tk_cal_croak_range(pTHX_ const tk_calendar *cal, const char *what)
{
    if (cal->year_min || cal->year_max)
        croak("%s: the %s calendar is tabled for its years %" IVdf " to %" IVdf " only", what, cal->id, (IV)cal->year_min, (IV)cal->year_max);
    croak("%s: out of range", what);
}

static int
tk_cal_arg(pTHX_ SV *sv, const char *what)
{
    int id = tk_cal_id_from_sv(aTHX_ sv, what);
    tk_cal_check_built(aTHX_ id, what);
    return id;
}

/* Days since 1970 of the value's wall-clock date; a leap second belongs to
 * the day it ends. */
static int64_t
tk_value_local_days(const tk_value *v)
{
    return tk_floor_div(v->inst.sec + v->utoff, 86400);
}

/* The value's fields in its calendar, from the cache in the value or, the
 * first time, computed and kept there (R14a). The value is written through a
 * const pointer as civil is: the cache is a pure function of what never
 * changes. */
static void
tk_value_calfields(pTHX_ const tk_value *v, tk_calfields *f, const char *what)
{
    tk_value *w = (tk_value *)v;
    const tk_calcache *c = &v->cal;
    if (!(v->flags & TK_F_CAL)) {
        const tk_calendar *cal = tk_cal_of(v);
        int64_t days = tk_value_local_days(v);
        tk_calfields full;
        if (!tk_cal_days_ok(cal, days))
            tk_cal_croak_range(aTHX_ cal, what);
        tk_cal_fields(cal, days, &full);
        w->cal.year = (int32_t)full.year;
        w->cal.era_year = (int32_t)full.era_year;
        w->cal.doy = (uint16_t)full.doy;
        w->cal.days_in_year = (uint16_t)full.days_in_year;
        w->cal.month = (uint8_t)full.month;
        w->cal.day = (uint8_t)full.day;
        w->cal.month_number = (uint8_t)full.month_number;
        w->cal.era = (uint8_t)full.era;
        w->cal.months_in_year = (uint8_t)full.months_in_year;
        w->cal.days_in_month = (uint8_t)full.days_in_month;
        w->cal.flags = (uint8_t)((full.leap_month ? TK_CC_LEAP_MONTH : 0) | (full.leap_year ? TK_CC_LEAP_YEAR : 0));
        w->cal.pad = 0;
        w->flags |= TK_F_CAL;
    }
    f->year = c->year;
    f->era_year = c->era_year;
    f->era = c->era;
    f->month = c->month;
    f->day = c->day;
    f->doy = c->doy;
    f->months_in_year = c->months_in_year;
    f->days_in_month = c->days_in_month;
    f->days_in_year = c->days_in_year;
    f->month_number = c->month_number;
    f->leap_month = (c->flags & TK_CC_LEAP_MONTH) != 0;
    f->leap_year = (c->flags & TK_CC_LEAP_YEAR) != 0;
}

/* A copy read in another calendar: the cached fields were the old one's. */
static void
tk_value_set_calendar(tk_value *v, int id)
{
    v->calendar = (uint8_t)id;
    v->flags &= (uint8_t)~TK_F_CAL;
}

/* What has not been built for the other calendars yet: everything that
 * steps through a calendar or writes its names. */
static void
tk_value_gregorian_only(pTHX_ const tk_value *v, const char *what)
{
    if (v->calendar != TK_CAL_GREGORY)
        croak("%s: in the %s calendar, comes in a later release", what, tk_cal_of(v)->id);
}

/* A date in a calendar, checked, as the Gregorian date of the same day. */
static void
tk_cal_to_gregorian(pTHX_ const tk_calendar *cal, int64_t y, unsigned m, unsigned d,
                    int64_t *gy, unsigned *gm, unsigned *gd, const char *what)
{
    int64_t days;
    if (!tk_cal_year_ok(cal, y))
        tk_cal_croak_range(aTHX_ cal, what);
    if (m < 1 || m > cal->months_in_year(y))
        croak("%s: the %s year %" IVdf " has %u months, not %u", what, cal->id, (IV)y, cal->months_in_year(y), m);
    if (d < 1 || d > cal->days_in_month(y, m))
        croak("%s: month %u of the %s year %" IVdf " has %u days, not %u", what, m, cal->id, (IV)y, cal->days_in_month(y, m), d);
    days = cal->to_days(y, m, d);
    tk_civil_from_days(days, gy, gm, gd);
    if (*gy < TK_YEAR_MIN || *gy > TK_YEAR_MAX)
        croak("%s: out of range", what);
}

/* The month a code names: M01 .. M13, with L for a leap month. */
static int
tk_cal_month_from_code_sv(pTHX_ const tk_calendar *cal, int64_t y, SV *sv, unsigned *m, const char *what)
{
    STRLEN len;
    const char *s = SvPV(sv, len);
    unsigned number;
    int leap = 0;
    if ((len != 3 && len != 4) || s[0] != 'M' || !isDIGIT(s[1]) || !isDIGIT(s[2]) || (len == 4 && s[3] != 'L'))
        croak("%s: a month code is M01 to M13, with L after a leap month, not '%s'", what, s);
    number = (unsigned)((s[1] - '0') * 10 + (s[2] - '0'));
    leap = len == 4;
    if (cal->month_from_code)
        return cal->month_from_code(y, number, leap, m);
    if (leap || number < 1 || number > cal->months_in_year(y))
        return 0;
    *m = number;
    return 1;
}

static SV *
tk_cal_month_code_sv(pTHX_ const tk_calfields *f)
{
    return newSVpvf("M%02u%s", f->month_number, f->leap_month ? "L" : "");
}

/* ---- the fields the accessors read --------------------------------------- */

/* The calendar's reading of an accessor on the ladder in xs/keeper.xs, by
 * that ladder's alias number: 0 year, 1 month, 2 day, 10 day_of_year,
 * 11 quarter, 12 day_of_quarter, 15 week_of_month, 16 is_leap_year,
 * 17 days_in_month, 22 days_in_year, 23 days_in_quarter. Quarters run over
 * ordinal months, three to a quarter, so a thirteenth month is quarter 5. */
static int
tk_cal_field_is_calendars(int ix)
{
    return ix <= 2 || ix == 10 || ix == 11 || ix == 12 || ix == 15 || ix == 16 || ix == 17 || ix == 22 || ix == 23;
}

static IV
tk_cal_field(pTHX_ const tk_value *v, int ix, int dow)
{
    tk_calfields f;
    const tk_calendar *cal = tk_cal_of(v);
    unsigned first, k, sum;
    tk_value_calfields(aTHX_ v, &f, "Time::Keeper accessor");
    switch (ix) {
    case 0:  return (IV)f.year;
    case 1:  return f.month;
    case 2:  return f.day;
    case 10: return f.doy;
    case 11: return (f.month - 1) / 3 + 1;
    case 12:
        first = ((f.month - 1) / 3) * 3 + 1;
        for (sum = 0, k = first; k < f.month; k++)
            sum += cal->days_in_month(f.year, k);
        return sum + f.day;
    case 15: return (f.day + 4 - dow + 6) / 7;
    case 16: return f.leap_year;
    case 17: return f.days_in_month;
    case 22: return f.days_in_year;
    default:
        first = ((f.month - 1) / 3) * 3 + 1;
        for (sum = 0, k = first; k < first + 3 && k <= f.months_in_year; k++)
            sum += cal->days_in_month(f.year, k);
        return sum;
    }
}

/* ---- constructing in a calendar ------------------------------------------- */

/* The year the arguments name: `year`, or `era` and `era_year`. Both is an error. */
static int64_t
tk_cal_args_year(pTHX_ const tk_calendar *cal, const tk_args *a, int have_default, int64_t dflt, const char *what)
{
    if (a->v[TK_A_ERA] || a->v[TK_A_ERA_YEAR]) {
        STRLEN len;
        const char *code;
        unsigned k;
        int64_t ey, y;
        if (a->v[TK_A_YEAR])
            croak("%s: year cannot be given with era and era_year", what);
        if (!a->v[TK_A_ERA] || !a->v[TK_A_ERA_YEAR])
            croak("%s: era and era_year go together", what);
        code = SvPV(a->v[TK_A_ERA], len);
        for (k = 0; k < cal->n_eras; k++)
            if (strlen(cal->eras[k].code) == len && memEQ(code, cal->eras[k].code, len))
                break;
        if (k == cal->n_eras)
            croak("%s: the %s calendar has no era '%s'", what, cal->id, code);
        ey = tk_args_int(aTHX_ a, TK_A_ERA_YEAR, 1, -TK_CAL_YEAR_LIMIT, TK_CAL_YEAR_LIMIT, what);
        if (!cal->year_from_era(k, ey, &y))
            croak("%s: era '%s' has no year %" IVdf, what, code, (IV)ey);
        return y;
    }
    if (!a->v[TK_A_YEAR]) {
        if (have_default)
            return dflt;
        croak("%s: year is required", what);
    }
    return tk_args_int(aTHX_ a, TK_A_YEAR, 0, -TK_CAL_YEAR_LIMIT, TK_CAL_YEAR_LIMIT, what);
}

/* The month the arguments name: `month`, or `month_code`. */
static unsigned
tk_cal_args_month(pTHX_ const tk_calendar *cal, const tk_args *a, int64_t y, int have_default, unsigned dflt, const char *what)
{
    unsigned m;
    if (a->v[TK_A_MONTH_CODE]) {
        if (a->v[TK_A_MONTH])
            croak("%s: month cannot be given with month_code", what);
        if (!tk_cal_month_from_code_sv(aTHX_ cal, y, a->v[TK_A_MONTH_CODE], &m, what))
            croak("%s: the %s year %" IVdf " has no month %s", what, cal->id, (IV)y, SvPV_nolen(a->v[TK_A_MONTH_CODE]));
        return m;
    }
    if (!a->v[TK_A_MONTH])
        return have_default ? dflt : 1;
    return (unsigned)tk_args_int(aTHX_ a, TK_A_MONTH, 1, 1, cal->max_months, what);
}

/* The Gregorian date that new, last_day_of_month (ix 1) and from_day_of_year
 * (ix 2) name in a calendar. */
static void
tk_cal_new_date(pTHX_ const tk_calendar *cal, const tk_args *a, int ix, int64_t *gy, unsigned *gm, unsigned *gd, const char *what)
{
    int64_t y = tk_cal_args_year(aTHX_ cal, a, 0, 0, what);
    unsigned m, d;
    if (ix == 2) {
        int64_t doy, days;
        if (!a->v[TK_A_DAY_OF_YEAR])
            croak("%s: day_of_year is required", what);
        doy = tk_args_int(aTHX_ a, TK_A_DAY_OF_YEAR, 1, 1, 400, what);
        if (doy > (int64_t)tk_cal_days_in_year(cal, y))
            croak("%s: the %s year %" IVdf " has %u days, not %" IVdf, what, cal->id, (IV)y, tk_cal_days_in_year(cal, y), (IV)doy);
        days = cal->to_days(y, 1, 1) + doy - 1;
        tk_civil_from_days(days, gy, gm, gd);
        return;
    }
    m = tk_cal_args_month(aTHX_ cal, a, y, 0, 1, what);
    if (ix == 1) {
        if (!a->v[TK_A_MONTH] && !a->v[TK_A_MONTH_CODE])
            croak("%s: month is required", what);
        if (m > cal->months_in_year(y))
            croak("%s: the %s year %" IVdf " has %u months, not %u", what, cal->id, (IV)y, cal->months_in_year(y), m);
        d = cal->days_in_month(y, m);
    }
    else
        d = (unsigned)tk_args_int(aTHX_ a, TK_A_DAY, 1, 1, 31, what);
    tk_cal_to_gregorian(aTHX_ cal, y, m, d, gy, gm, gd, what);
}

/* The Gregorian date `with` names on a value in a calendar: year (or era
 * and era_year), month (or month_code), day ('last' for the month's last),
 * day_of_year, then day_of_week within the week. `week` is ISO's and
 * Gregorian, so it is refused here. */
static void
tk_cal_with_date(pTHX_ const tk_value *v, const tk_args *a, int64_t *gy, unsigned *gm, unsigned *gd, const char *what)
{
    const tk_calendar *cal = tk_cal_of(v);
    tk_calfields f;
    int64_t y, days;
    unsigned m, d;
    tk_value_calfields(aTHX_ v, &f, what);
    if (a->v[TK_A_WEEK])
        croak("%s: week is the ISO week, which the %s calendar does not count; use day_of_year or the Gregorian value", what, cal->id);
    y = tk_cal_args_year(aTHX_ cal, a, 1, f.year, what);
    m = tk_cal_args_month(aTHX_ cal, a, y, 1, f.month, what);
    if (a->v[TK_A_DAY_OF_YEAR]) {
        int64_t doy;
        if (a->v[TK_A_MONTH] || a->v[TK_A_MONTH_CODE] || a->v[TK_A_DAY])
            croak("%s: day_of_year cannot be given with month or day", what);
        doy = tk_args_int(aTHX_ a, TK_A_DAY_OF_YEAR, 1, 1, 400, what);
        if (doy > (int64_t)tk_cal_days_in_year(cal, y))
            croak("%s: the %s year %" IVdf " has %u days, not %" IVdf, what, cal->id, (IV)y, tk_cal_days_in_year(cal, y), (IV)doy);
        days = cal->to_days(y, 1, 1) + doy - 1;
    }
    else {
        if (m > cal->months_in_year(y))
            croak("%s: the %s year %" IVdf " has %u months, not %u", what, cal->id, (IV)y, cal->months_in_year(y), m);
        if (a->v[TK_A_DAY] && SvPOK(a->v[TK_A_DAY]) && strEQ(SvPV_nolen(a->v[TK_A_DAY]), "last"))
            d = cal->days_in_month(y, m);
        else
            d = (unsigned)tk_args_int(aTHX_ a, TK_A_DAY, f.day, 1, 31, what);
        if (d > cal->days_in_month(y, m))
            croak("%s: month %u of the %s year %" IVdf " has %u days, not %u", what, m, cal->id, (IV)y, cal->days_in_month(y, m), d);
        days = cal->to_days(y, m, d);
    }
    if (a->v[TK_A_DAY_OF_WEEK]) {
        int64_t wd = tk_args_int(aTHX_ a, TK_A_DAY_OF_WEEK, 1, 1, 7, what);
        days += wd - tk_dow_from_days(days);
    }
    tk_civil_from_days(days, gy, gm, gd);
    if (*gy < TK_YEAR_MIN || *gy > TK_YEAR_MAX)
        croak("%s: out of range", what);
}

#endif
