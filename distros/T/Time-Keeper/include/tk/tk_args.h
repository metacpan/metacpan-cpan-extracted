#ifndef TK_ARGS_H
#define TK_ARGS_H

/* Named arguments, as the constructors and `with` take them. Each method
 * says which keys it allows; any other key, or a key given twice, croaks
 * by name. */

enum {
    TK_A_YEAR, TK_A_MONTH, TK_A_DAY, TK_A_HOUR, TK_A_MINUTE, TK_A_SECOND,
    TK_A_NANOSECOND, TK_A_ZONE, TK_A_GAP, TK_A_OVERLAP, TK_A_DAY_OF_YEAR,
    TK_A_WEEK, TK_A_LOCALE, TK_A_DAY_OF_WEEK, TK_A_OR_SAME, TK_A_N, TK_A_TO,
    TK_A_INCREMENT, TK_A_MODE, TK_A_LARGEST, TK_A_SMALLEST, TK_A_RELATIVE_TO, TK_A_UNIT,
    TK_A_STYLE, TK_A_NUMERIC, TK_A_UNITS, TK_A_SKELETON, TK_A_WEEK_START, TK_A_BY, TK_A_STEP, TK_A_INCLUSIVE,
    TK_A_END_OF_MONTH, TK_A_COUNT
};

static const char *const tk_arg_names[TK_A_COUNT] = {
    "year", "month", "day", "hour", "minute", "second",
    "nanosecond", "zone", "gap", "overlap", "day_of_year", "week", "locale",
    "day_of_week", "or_same", "n", "to", "increment", "mode", "largest", "smallest",
    "relative_to", "unit", "style", "numeric", "units", "skeleton", "week_start", "by", "step", "inclusive", "end_of_month"
};

#define TK_A(bit) (1u << (bit))
#define TK_A_TIME (TK_A(TK_A_HOUR) | TK_A(TK_A_MINUTE) | TK_A(TK_A_SECOND) | TK_A(TK_A_NANOSECOND))
#define TK_A_RESOLVE (TK_A(TK_A_ZONE) | TK_A(TK_A_GAP) | TK_A(TK_A_OVERLAP))

/* The locale asked for, or English. */
#define tk_args_locale(a, what) ((a)->v[TK_A_LOCALE] ? tk_locale_id_from_sv(aTHX_ (a)->v[TK_A_LOCALE], what) : 0)

typedef struct tk_args {
    SV *v[TK_A_COUNT];
} tk_args;

static void
tk_args_parse(pTHX_ SV **st, I32 n, unsigned allowed, tk_args *a, const char *what)
{
    I32 i;
    Zero(a, 1, tk_args);
    if (n % 2)
        croak("%s: arguments come in name => value pairs", what);
    for (i = 0; i < n; i += 2) {
        STRLEN len;
        const char *k = SvPV(st[i], len);
        int j, found = -1;
        for (j = 0; j < TK_A_COUNT; j++)
            if (strlen(tk_arg_names[j]) == len && memEQ(k, tk_arg_names[j], len)) {
                found = j;
                break;
            }
        if (found < 0 || !(allowed & TK_A(found)))
            croak("%s: unknown argument '%s'", what, k);
        if (a->v[found])
            croak("%s: %s given twice", what, k);
        a->v[found] = st[i + 1];
    }
}

static int64_t
tk_args_int(pTHX_ const tk_args *a, int which, int64_t dflt, int64_t lo, int64_t hi, const char *what)
{
    if (!a->v[which])
        return dflt;
    return tk_opt_int(aTHX_ a->v[which], what, tk_arg_names[which], lo, hi);
}

/* The time of day from the arguments; second may be 60 (a leap second). */
static void
tk_args_time(pTHX_ const tk_args *a, int64_t *h, int64_t *mi, int64_t *s, int32_t *ns, const char *what)
{
    *h  = tk_args_int(aTHX_ a, TK_A_HOUR, 0, 0, 23, what);
    *mi = tk_args_int(aTHX_ a, TK_A_MINUTE, 0, 0, 59, what);
    *s  = tk_args_int(aTHX_ a, TK_A_SECOND, 0, 0, 60, what);
    *ns = (int32_t)tk_args_int(aTHX_ a, TK_A_NANOSECOND, 0, 0, TK_NSECS_PER_SEC - 1, what);
}

static void
tk_args_gap_overlap(pTHX_ const tk_args *a, int *gap, int *overlap, const char *what)
{
    *gap = a->v[TK_A_GAP] ? tk_opt_gap(aTHX_ a->v[TK_A_GAP], what) : TK_GAP_DEFAULT;
    *overlap = a->v[TK_A_OVERLAP] ? tk_opt_overlap(aTHX_ a->v[TK_A_OVERLAP], what) : TK_OVERLAP_DEFAULT;
}

static void
tk_args_resolve(pTHX_ const tk_args *a, tk_zone_spec *z, int *gap, int *overlap, const char *what)
{
    tk_zone_spec_from_sv(aTHX_ a->v[TK_A_ZONE], z, what);
    tk_args_gap_overlap(aTHX_ a, gap, overlap, what);
}

/* The date new and its three aliases make: ix 0 new (year, month, day),
 * 1 last_day_of_month (year, month), 2 from_day_of_year, 3 from_iso_week
 * (year, week, day of the week). The year was read already. */
static void
tk_args_ymd(pTHX_ const tk_args *a, int ix, int64_t *yp, unsigned *m, unsigned *d, const char *what)
{
    int64_t yy, y = *yp;
    *m = 1;
    *d = 1;
    switch (ix) {
    case 0:
        *m = (unsigned)tk_args_int(aTHX_ a, TK_A_MONTH, 1, 1, 12, what);
        *d = (unsigned)tk_args_int(aTHX_ a, TK_A_DAY, 1, 1, 31, what);
        if (*d > tk_days_in_month(y, *m))
            croak("%s: %04" IVdf "-%02u has no day %u", what, (IV)y, *m, *d);
        break;
    case 1:
        if (!a->v[TK_A_MONTH])
            croak("%s: month is required", what);
        *m = (unsigned)tk_args_int(aTHX_ a, TK_A_MONTH, 1, 1, 12, what);
        *d = tk_days_in_month(y, *m);
        break;
    case 2: {
        int64_t doy;
        if (!a->v[TK_A_DAY_OF_YEAR])
            croak("%s: day_of_year is required", what);
        doy = tk_args_int(aTHX_ a, TK_A_DAY_OF_YEAR, 1, 1, 366, what);
        if (doy == 366 && !tk_is_leap_year(y))
            croak("%s: %" IVdf " has no day 366", what, (IV)y);
        tk_civil_from_days(tk_days_from_civil(y, 1, 1) + doy - 1, &yy, m, d);
        *yp = yy;
        break;
    }
    default: {
        int64_t wk, wd, wy, monday;
        unsigned last;
        if (!a->v[TK_A_WEEK])
            croak("%s: week is required", what);
        wk = tk_args_int(aTHX_ a, TK_A_WEEK, 1, 1, 53, what);
        wd = tk_args_int(aTHX_ a, TK_A_DAY, 1, 1, 7, what);
        tk_iso_week(y, 12, 28, &wy, &last);
        if (wk > last)
            croak("%s: %" IVdf " has %u ISO weeks, not %" IVdf, what, (IV)y, last, (IV)wk);
        monday = tk_days_from_civil(y, 1, 4);
        monday -= tk_dow_from_days(monday) - 1;
        tk_civil_from_days(monday + (wk - 1) * 7 + wd - 1, &yy, m, d);
        *yp = yy;
        break;
    }
    }
}

/* The date `with` makes from a value's civil date and the arguments:
 * year, month, day (or 'last'), day_of_year or week (keeping the day of
 * the week), then day_of_week within the ISO week. */
static void
tk_args_with_date(pTHX_ const tk_args *a, const tk_civil *c, int64_t *y, unsigned *m, unsigned *d, const char *what)
{
    int64_t dd;
    *y = tk_args_int(aTHX_ a, TK_A_YEAR, c->year, TK_YEAR_MIN, TK_YEAR_MAX, what);
    *m = (unsigned)tk_args_int(aTHX_ a, TK_A_MONTH, c->month, 1, 12, what);
    if (a->v[TK_A_DAY] && SvPOK(a->v[TK_A_DAY]) && strEQ(SvPV_nolen(a->v[TK_A_DAY]), "last"))
        dd = tk_days_in_month(*y, *m);
    else
        dd = tk_args_int(aTHX_ a, TK_A_DAY, c->day, 1, 31, what);
    *d = (unsigned)dd;
    if (a->v[TK_A_DAY_OF_YEAR] || a->v[TK_A_WEEK]) {
        int64_t yy;
        if (a->v[TK_A_MONTH] || a->v[TK_A_DAY] || (a->v[TK_A_DAY_OF_YEAR] && a->v[TK_A_WEEK]))
            croak("%s: day_of_year or week cannot be given with month, day or each other", what);
        if (a->v[TK_A_DAY_OF_YEAR]) {
            int64_t doy = tk_args_int(aTHX_ a, TK_A_DAY_OF_YEAR, 1, 1, 366, what);
            if (doy == 366 && !tk_is_leap_year(*y))
                croak("%s: %" IVdf " has no day 366", what, (IV)*y);
            tk_civil_from_days(tk_days_from_civil(*y, 1, 1) + doy - 1, &yy, m, d);
        }
        else {
            int64_t wk = tk_args_int(aTHX_ a, TK_A_WEEK, 1, 1, 53, what), wy, monday;
            unsigned last;
            tk_iso_week(*y, 12, 28, &wy, &last);
            if (wk > last)
                croak("%s: %" IVdf " has %u ISO weeks, not %" IVdf, what, (IV)*y, last, (IV)wk);
            monday = tk_days_from_civil(*y, 1, 4);
            monday -= tk_dow_from_days(monday) - 1;
            tk_civil_from_days(monday + (wk - 1) * 7 + c->dow - 1, &yy, m, d);
        }
        *y = yy;
    }
    else if (dd > (int64_t)tk_days_in_month(*y, *m))
        croak("%s: %04" IVdf "-%02u has no day %" IVdf, what, (IV)*y, *m, (IV)dd);
    if (a->v[TK_A_DAY_OF_WEEK]) {
        int64_t wd = tk_args_int(aTHX_ a, TK_A_DAY_OF_WEEK, 1, 1, 7, what);
        int64_t zz = tk_days_from_civil(*y, *m, *d), yy;
        tk_civil_from_days(zz + wd - tk_dow_from_days(zz), &yy, m, d);
        *y = yy;
    }
}

#endif
