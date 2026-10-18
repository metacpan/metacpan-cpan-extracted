#ifndef TK_DURATION_H
#define TK_DURATION_H

/* A duration, kept in DateTime's units because they do not convert into
 * one another: months (a month is not a fixed number of days), days (a day
 * is not always 24 hours), minutes (a minute is not always 60 seconds:
 * leap seconds), and seconds with nanoseconds.
 *
 * Seconds and nanoseconds share a sign and |nsec| < 1e9. They are
 * normalised on integers only: DateTime::Duration does it in floating
 * point and loses a second past about 1e7 seconds. Each unit may have its
 * own sign. A Time::Keeper::Duration is a blessed read-only string of one
 * tk_duration, as a value is of a tk_value. */

#define TK_EOM_WRAP     0
#define TK_EOM_LIMIT    1
#define TK_EOM_PRESERVE 2

/* No unit may go past this, so sums and products of a few can be checked
 * before they overflow. */
#define TK_DUR_LIMIT ((int64_t)1 << 60)

typedef struct tk_duration {
    int64_t months;
    int64_t days;
    int64_t minutes;
    int64_t seconds;
    int32_t nsec;
    uint8_t eom;
    uint8_t pad[3];
} tk_duration;

/* DateTime's default: a duration whose months are negative keeps the last
 * day of a month the last day; any other wraps. */
static uint8_t
tk_dur_default_eom(int64_t months)
{
    return months < 0 ? TK_EOM_PRESERVE : TK_EOM_WRAP;
}

static int
tk_dur_in_range(int64_t v)
{
    return v > -TK_DUR_LIMIT && v < TK_DUR_LIMIT;
}

/* Fold whole seconds out of nsec, then give the two one sign. 0 when a
 * unit is out of range. */
static int
tk_dur_normalize(tk_duration *d, int64_t nsec)
{
    int64_t q = nsec / TK_NSECS_PER_SEC;
    if (!tk_dur_in_range(d->seconds) || !tk_dur_in_range(q))
        return 0;
    d->seconds += q;
    nsec -= q * TK_NSECS_PER_SEC;
    if (d->seconds > 0 && nsec < 0) {
        d->seconds -= 1;
        nsec += TK_NSECS_PER_SEC;
    }
    else if (d->seconds < 0 && nsec > 0) {
        d->seconds += 1;
        nsec -= TK_NSECS_PER_SEC;
    }
    d->nsec = (int32_t)nsec;
    return tk_dur_in_range(d->months) && tk_dur_in_range(d->days)
        && tk_dur_in_range(d->minutes) && tk_dur_in_range(d->seconds);
}

/* d times f, eom kept; 0 when a part leaves the range. */
static int
tk_dur_multiply(const tk_duration *d, int64_t f, tk_duration *out)
{
    int64_t a = f < 0 ? -f : f;
    if (f > TK_DUR_LIMIT || f < -TK_DUR_LIMIT)
        return 0;
    if (a && (d->months > TK_DUR_LIMIT / a || d->months < -TK_DUR_LIMIT / a
              || d->days > TK_DUR_LIMIT / a || d->days < -TK_DUR_LIMIT / a
              || d->minutes > TK_DUR_LIMIT / a || d->minutes < -TK_DUR_LIMIT / a
              || d->seconds > TK_DUR_LIMIT / a || d->seconds < -TK_DUR_LIMIT / a))
        return 0;
    *out = *d;
    out->months *= f;
    out->days *= f;
    out->minutes *= f;
    out->seconds *= f;
    return tk_dur_normalize(out, (int64_t)d->nsec * f);
}

static int
tk_dur_is_zero(const tk_duration *d)
{
    return !d->months && !d->days && !d->minutes && !d->seconds && !d->nsec;
}

static int
tk_dur_has_positive(const tk_duration *d)
{
    return d->months > 0 || d->days > 0 || d->minutes > 0 || d->seconds > 0 || d->nsec > 0;
}

static int
tk_dur_has_negative(const tk_duration *d)
{
    return d->months < 0 || d->days < 0 || d->minutes < 0 || d->seconds < 0 || d->nsec < 0;
}

/* ---- named arguments ------------------------------------------------- */

enum {
    TK_D_YEARS, TK_D_MONTHS, TK_D_WEEKS, TK_D_DAYS, TK_D_HOURS, TK_D_MINUTES,
    TK_D_SECONDS, TK_D_NANOSECONDS, TK_D_EOM, TK_D_GAP, TK_D_OVERLAP, TK_D_COUNT
};

static const char *const tk_dur_arg_names[TK_D_COUNT] = {
    "years", "months", "weeks", "days", "hours", "minutes",
    "seconds", "nanoseconds", "end_of_month", "gap", "overlap"
};

#define TK_D(bit) (1u << (bit))
#define TK_D_UNITS (TK_D(TK_D_YEARS) | TK_D(TK_D_MONTHS) | TK_D(TK_D_WEEKS) | TK_D(TK_D_DAYS) \
                    | TK_D(TK_D_HOURS) | TK_D(TK_D_MINUTES) | TK_D(TK_D_SECONDS) \
                    | TK_D(TK_D_NANOSECONDS) | TK_D(TK_D_EOM))

typedef struct tk_dur_args {
    SV *v[TK_D_COUNT];
} tk_dur_args;

static void
tk_dur_args_parse(pTHX_ SV **st, I32 n, unsigned allowed, tk_dur_args *a, const char *what)
{
    I32 i;
    Zero(a, 1, tk_dur_args);
    if (n % 2)
        croak("%s: arguments come in name => value pairs", what);
    for (i = 0; i < n; i += 2) {
        STRLEN len;
        const char *k = SvPV(st[i], len);
        int j, found = -1;
        for (j = 0; j < TK_D_COUNT; j++)
            if (strlen(tk_dur_arg_names[j]) == len && memEQ(k, tk_dur_arg_names[j], len)) {
                found = j;
                break;
            }
        if (found < 0 || !(allowed & TK_D(found)))
            croak("%s: unknown argument '%s'", what, k);
        if (a->v[found])
            croak("%s: %s given twice", what, k);
        a->v[found] = st[i + 1];
    }
}

static int
tk_opt_eom(pTHX_ SV *sv, const char *what)
{
    const char *s = SvPV_nolen(sv);
    if (strEQ(s, "wrap"))     return TK_EOM_WRAP;
    if (strEQ(s, "limit"))    return TK_EOM_LIMIT;
    if (strEQ(s, "preserve")) return TK_EOM_PRESERVE;
    croak("%s: end_of_month is 'wrap', 'limit' or 'preserve', not '%s'", what, s);
    return 0;
}

static const char *
tk_eom_name(int eom)
{
    return eom == TK_EOM_LIMIT ? "limit" : eom == TK_EOM_PRESERVE ? "preserve" : "wrap";
}

static int64_t
tk_dur_int(pTHX_ const tk_dur_args *a, int which, const char *what)
{
    int64_t v;
    if (!a->v[which])
        return 0;
    if (!tk_sv_to_i64(aTHX_ a->v[which], &v))
        croak("%s: %s is not an integer", what, tk_dur_arg_names[which]);
    if (!tk_dur_in_range(v))
        croak("%s: %s is out of range", what, tk_dur_arg_names[which]);
    return v;
}

/* A duration from the unit arguments; DateTime's units, folded as DateTime
 * folds them: years into months, weeks into days, hours into minutes. */
static void
tk_dur_from_args(pTHX_ const tk_dur_args *a, tk_duration *d, const char *what)
{
    int64_t years = tk_dur_int(aTHX_ a, TK_D_YEARS, what);
    int64_t weeks = tk_dur_int(aTHX_ a, TK_D_WEEKS, what);
    int64_t hours = tk_dur_int(aTHX_ a, TK_D_HOURS, what);
    if (years > TK_DUR_LIMIT / 12 || years < -TK_DUR_LIMIT / 12
        || weeks > TK_DUR_LIMIT / 7 || weeks < -TK_DUR_LIMIT / 7
        || hours > TK_DUR_LIMIT / 60 || hours < -TK_DUR_LIMIT / 60)
        croak("%s: out of range", what);
    Zero(d, 1, tk_duration);
    d->months = years * 12 + tk_dur_int(aTHX_ a, TK_D_MONTHS, what);
    d->days = weeks * 7 + tk_dur_int(aTHX_ a, TK_D_DAYS, what);
    d->minutes = hours * 60 + tk_dur_int(aTHX_ a, TK_D_MINUTES, what);
    d->seconds = tk_dur_int(aTHX_ a, TK_D_SECONDS, what);
    if (!tk_dur_normalize(d, tk_dur_int(aTHX_ a, TK_D_NANOSECONDS, what)))
        croak("%s: out of range", what);
    d->eom = a->v[TK_D_EOM] ? (uint8_t)tk_opt_eom(aTHX_ a->v[TK_D_EOM], what)
                            : tk_dur_default_eom(d->months);
}

#endif
