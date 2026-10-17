#ifndef TK_ARITH_H
#define TK_ARITH_H

/* Arithmetic on values (K12, the owner's: it round-trips).
 *
 * plus: the months, then the days, are added to the wall-clock date and
 * the wall-clock time is kept; that wall time is then found in the zone
 * (a gap croaks unless told otherwise; an overlap takes the earlier
 * instant). Then the minutes are added as POSIX time (60 seconds each,
 * leap seconds not counted, as DateTime adds them), then the seconds and
 * nanoseconds as SI time (leap seconds counted).
 *
 * difference: $b - $a is the duration D for which $a->plus(D) is $b,
 * always. Its calendar part is the most months, then the most days, that
 * do not go past $b; the rest is clock time. It is worked out with the
 * very function plus uses, so the two cannot disagree. */

/* ---- months -------------------------------------------------------- */

static void
tk_add_months_ymd(int64_t y, unsigned m, unsigned d, int64_t months, int eom,
                  int64_t *ry, unsigned *rm, unsigned *rd)
{
    int64_t total = y * 12 + (int64_t)(m - 1) + months;
    int64_t ty = tk_floor_div(total, 12);
    unsigned tm = (unsigned)(total - ty * 12 + 1);
    unsigned last = tk_days_in_month(ty, tm);

    if (eom == TK_EOM_PRESERVE && d == tk_days_in_month(y, m))
        d = last;
    else if (eom != TK_EOM_WRAP && d > 28 && d > last)
        d = last;
    if (d <= last) {
        *ry = ty;
        *rm = tm;
        *rd = d;
        return;
    }
    /* wrap: the days past the month's end run on into the next */
    tk_civil_from_days(tk_days_from_civil(ty, tm, 1) + d - 1, ry, rm, rd);
}

/* ---- the calendar step ------------------------------------------------ */

/* out is v's wall-clock time on the date months and then days after v's,
 * found in v's zone. A TK_LOCAL_ result. */
static int
tk_value_calendar_rc(pTHX_ tk_value *out, tk_value *v, int64_t months, int64_t days,
                     int eom, int gap, int overlap)
{
    tk_civil c = *tk_value_civil(v);
    tk_zone_spec z;
    int64_t y, z0;
    unsigned m, d;
    int r;

    tk_add_months_ymd(c.year, c.month, c.day, months, eom, &y, &m, &d);
    if (y < TK_YEAR_MIN || y > TK_YEAR_MAX)
        return TK_LOCAL_RANGE;
    if (days) {
        z0 = tk_days_from_civil(y, m, d);
        if (days > tk_days_from_civil(TK_YEAR_MAX, 12, 31) - z0
            || days < tk_days_from_civil(TK_YEAR_MIN, 1, 1) - z0)
            return TK_LOCAL_RANGE;
        tk_civil_from_days(z0 + days, &y, &m, &d);
    }
    tk_value_zone(v, &z);
    r = tk_value_from_local_rc(aTHX_ out, &z, y, m, d, c.hour, c.minute, c.second, c.nsec,
                               gap, overlap);
    if (r == TK_LOCAL_OK)
        out->locale = v->locale;
    return r;
}

/* ---- the clock step ---------------------------------------------------- */

/* The instant whose elapsed SI time since 1970 is (e, n): the inverse of
 * tk_elapsed. The second after 23:59:59 on a leap day is 23:59:60. */
static void
tk_from_elapsed(int64_t e, int32_t n, tk_instant *t)
{
    int64_t s = e - tk_leaps_before(e);
    while (s + tk_leaps_before(s) > e)
        s--;
    while (s + 1 + tk_leaps_before(s + 1) <= e)
        s++;
    t->sec = s;
    t->nsec = n;
    if (e - s - tk_leaps_before(s) == 1)   /* only after a leap day's 23:59:59 */
        t->nsec += TK_NSECS_PER_SEC;
}

/* out is v moved on by minutes of POSIX time and then seconds and
 * nanoseconds of SI time. 0 when it leaves the range. */
static int
tk_value_clock_rc(pTHX_ tk_value *out, const tk_value *v, int64_t minutes,
                  int64_t seconds, int64_t nsec)
{
    tk_instant t = v->inst;
    tk_zone_spec z;

    if (minutes) {
        if (minutes > TK_DUR_LIMIT / 60 || minutes < -TK_DUR_LIMIT / 60)
            return 0;
        t.sec += minutes * 60;
        if (t.nsec >= TK_NSECS_PER_SEC && !tk_is_leap_day_end(t.sec)) {
            t.sec += 1;              /* 23:59:60 moved off its day is the next second */
            t.nsec -= TK_NSECS_PER_SEC;
        }
    }
    if (seconds || nsec) {
        int64_t e, en;
        int32_t n0;
        if (v->zone == TK_ZONE_FLOATING) {
            e = t.sec;               /* floating time has no leap seconds */
            n0 = t.nsec;
        }
        else
            tk_elapsed(&t, &e, &n0);
        e += seconds;
        en = (int64_t)n0 + nsec;
        e += tk_floor_div(en, TK_NSECS_PER_SEC);
        en = tk_floor_mod(en, TK_NSECS_PER_SEC);
        if (v->zone == TK_ZONE_FLOATING) {
            t.sec = e;
            t.nsec = (int32_t)en;
        }
        else
            tk_from_elapsed(e, (int32_t)en, &t);
    }
    if (!tk_instant_valid(&t))
        return 0;
    tk_value_zone(v, &z);
    tk_value_init(aTHX_ out, &t, &z);
    out->locale = v->locale;
    return 1;
}

/* ---- plus ------------------------------------------------------------- */

static void
tk_value_plus(pTHX_ tk_value *out, tk_value *v, const tk_duration *d,
              int gap, int overlap, const char *what)
{
    tk_value mid = *v;
    if (d->months || d->days) {
        int r = tk_value_calendar_rc(aTHX_ &mid, v, d->months, d->days, d->eom, gap, overlap);
        if (r == TK_LOCAL_IN_GAP) {
            croak("%s: the result's wall-clock time did not happen in %s: the clocks went forward over it"
                  " (gap => 'forward' or 'backward' takes it anyway)",
                  what, (tk_zone_abi(aTHX)->name)(v->zone - TK_ZONE_NAMED));
        }
        if (r == TK_LOCAL_NO_LEAP)
            croak("%s: the result is a 23:59:60 on a day with no leap second", what);
        if (r != TK_LOCAL_OK)
            croak("%s: out of range", what);
    }
    if (d->minutes || d->seconds || d->nsec) {
        if (!tk_value_clock_rc(aTHX_ out, &mid, d->minutes, d->seconds, d->nsec))
            croak("%s: out of range", what);
    }
    else
        *out = mid;
}

/* ---- differences -------------------------------------------------------- */

static int
tk_inst_cmp(const tk_instant *x, const tk_instant *y)
{
    if (x->sec != y->sec)
        return x->sec < y->sec ? -1 : 1;
    return x->nsec < y->nsec ? -1 : x->nsec > y->nsec;
}

/* b - a as SI seconds and nanoseconds with one sign; in floating time as
 * POSIX seconds, since floating time has no leap seconds. */
static void
tk_value_minus_exact(const tk_value *b, const tk_value *a, int64_t *sec, int32_t *nsec)
{
    if (a->zone == TK_ZONE_FLOATING) {
        int64_t n = (int64_t)b->inst.nsec - a->inst.nsec;
        *sec = b->inst.sec - a->inst.sec + tk_floor_div(n, TK_NSECS_PER_SEC);
        *nsec = (int32_t)tk_floor_mod(n, TK_NSECS_PER_SEC);
    }
    else
        tk_minus_absolute(&b->inst, &a->inst, sec, nsec);
    if (*sec < 0 && *nsec > 0) {
        *sec += 1;
        *nsec -= TK_NSECS_PER_SEC;
    }
}

/* b's instant in a's zone, as a value; to or from floating time it is the
 * wall-clock time that is kept, as in_zone keeps it. */
static void
tk_value_in_zone_of(pTHX_ tk_value *out, tk_value *b, const tk_value *a)
{
    tk_zone_spec z;
    tk_value_zone(a, &z);
    if (a->zone == TK_ZONE_FLOATING || b->zone == TK_ZONE_FLOATING) {
        const tk_civil *c = tk_value_civil(b);
        tk_value_from_local(aTHX_ out, &z, c->year, c->month, c->day, c->hour, c->minute,
                            c->second, c->nsec, TKZ_GAP_FORWARD, TK_OVERLAP_DEFAULT,
                            "Time::Keeper difference");
    }
    else
        tk_value_init(aTHX_ out, &b->inst, &z);
}

/* The clock part from i to b: minutes of POSIX time, then SI seconds. */
static void
tk_clock_part(pTHX_ tk_value *i, const tk_value *b, int sign, tk_duration *d)
{
    tk_value x;
    int64_t s;
    int32_t n;
    int64_t minutes = (b->inst.sec - i->inst.sec) / 60;
    for (;;) {
        if (!minutes)
            x = *i;
        else if (!tk_value_clock_rc(aTHX_ &x, i, minutes, 0, 0)) {
            minutes -= sign;
            continue;
        }
        tk_value_minus_exact(b, &x, &s, &n);
        if ((sign > 0 && (s < 0 || n < 0)) || (sign < 0 && (s > 0 || n > 0))) {
            minutes -= sign;
            continue;
        }
        break;
    }
    d->minutes = minutes;
    d->seconds = s;
    d->nsec = n;
}

/* b - a, the duration that takes a to b (K12). With calendar off, only
 * clock time: minutes and seconds. */
static void
tk_value_difference(pTHX_ tk_duration *d, tk_value *bin, tk_value *a, int calendar)
{
    tk_value b, i;
    const tk_civil *ca, *cb;
    int sign;
    int64_t m = 0, days = 0;

    tk_value_in_zone_of(aTHX_ &b, bin, a);
    Zero(d, 1, tk_duration);
    sign = tk_inst_cmp(&b.inst, &a->inst) >= 0 ? 1 : -1;
    i = *a;

    if (calendar) {
        int64_t yy;
        unsigned mm, dd;
        ca = tk_value_civil(a);
        cb = tk_value_civil(&b);
        m = ((int64_t)cb->year * 12 + cb->month) - ((int64_t)ca->year * 12 + ca->month);
        if (m * sign < 0)
            m = 0;
        /* the most months that do not go past b */
        for (; m != 0; m -= sign) {
            if (tk_value_calendar_rc(aTHX_ &i, a, m, 0, tk_dur_default_eom(m),
                                     TK_GAP_DEFAULT, TK_OVERLAP_DEFAULT) == TK_LOCAL_OK
                && tk_inst_cmp(&i.inst, &b.inst) * sign <= 0)
                break;
        }
        /* then the most days */
        tk_add_months_ymd(ca->year, ca->month, ca->day, m, tk_dur_default_eom(m), &yy, &mm, &dd);
        days = tk_days_from_civil(cb->year, cb->month, cb->day) - tk_days_from_civil(yy, mm, dd);
        if (days * sign < 0)
            days = 0;
        for (; days != 0; days -= sign) {
            if (tk_value_calendar_rc(aTHX_ &i, a, m, days, tk_dur_default_eom(m),
                                     TK_GAP_DEFAULT, TK_OVERLAP_DEFAULT) == TK_LOCAL_OK
                && tk_inst_cmp(&i.inst, &b.inst) * sign <= 0)
                break;
        }
        /* plus does no calendar step for a duration without one, so the
         * clock part must then start from a itself */
        if (m == 0 && days == 0)
            i = *a;
        else if (days == 0)
            tk_value_calendar_rc(aTHX_ &i, a, m, 0, tk_dur_default_eom(m),
                                 TK_GAP_DEFAULT, TK_OVERLAP_DEFAULT);
    }
    tk_clock_part(aTHX_ &i, &b, sign, d);
    d->months = m;
    d->days = days;
    d->eom = tk_dur_default_eom(m);
}

/* ---- truncate and round ------------------------------------------------- */

enum { TK_U_YEAR, TK_U_QUARTER, TK_U_MONTH, TK_U_WEEK, TK_U_DAY, TK_U_HOUR,
       TK_U_MINUTE, TK_U_SECOND, TK_U_COUNT };

static const char *const tk_unit_names[TK_U_COUNT] = {
    "year", "quarter", "month", "week", "day", "hour", "minute", "second"
};

static int
tk_opt_unit(pTHX_ SV *sv, const char *what)
{
    const char *s = SvPV_nolen(sv);
    int i;
    for (i = 0; i < TK_U_COUNT; i++)
        if (strEQ(s, tk_unit_names[i]))
            return i;
    croak("%s: '%s' is not year, quarter, month, week, day, hour, minute or second", what, s);
    return 0;
}

/* The start of v's unit: the latest wall time at or before v with the
 * smaller fields at their least. Where that wall time fell in a gap, the
 * first moment after it; where it came twice, the reading at or before v. */
static void
tk_value_truncate(pTHX_ tk_value *out, tk_value *v, int unit, const char *what)
{
    tk_civil c = *tk_value_civil(v);
    tk_zone_spec z;
    int64_t y = c.year, day;
    unsigned m = c.month, d = c.day, h = c.hour, mi = c.minute, s = c.second;

    switch (unit) {
    case TK_U_YEAR:    m = 1; /* fall through */
    case TK_U_MONTH:   d = 1; h = mi = s = 0; break;
    case TK_U_QUARTER: m = (tk_quarter(m) - 1) * 3 + 1; d = 1; h = mi = s = 0; break;
    case TK_U_WEEK: {
        int64_t yy;
        day = tk_days_from_civil(y, m, d) - (c.dow - 1);
        tk_civil_from_days(day, &yy, &m, &d);
        y = yy;
        h = mi = s = 0;
        break;
    }
    case TK_U_DAY:     h = mi = s = 0; break;
    case TK_U_HOUR:    mi = s = 0; break;
    case TK_U_MINUTE:  s = 0; break;
    default:           break;
    }
    tk_value_zone(v, &z);
    if (tk_value_from_local_rc(aTHX_ out, &z, y, m, d, h, mi, s, 0, TKZ_GAP_FORWARD,
                               TKZ_OVERLAP_LATER) != TK_LOCAL_OK
        || tk_inst_cmp(&out->inst, &v->inst) > 0)
        tk_value_from_local(aTHX_ out, &z, y, m, d, h, mi, s, 0, TKZ_GAP_FORWARD,
                            TKZ_OVERLAP_EARLIER, what);
    out->locale = v->locale;
}

#endif
