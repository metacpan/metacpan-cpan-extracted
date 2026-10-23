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

    if (v->calendar != TK_CAL_GREGORY) {
        /* months are the calendar's; the day count below is calendar blind */
        const tk_calendar *cal = tk_cal_of(v);
        tk_calfields f;
        int64_t cy;
        unsigned cm, cd;
        if (!tk_cal_days_ok(cal, tk_value_local_days(v)))
            return TK_LOCAL_RANGE;
        tk_cal_fields(cal, tk_value_local_days(v), &f);
        if (f.year + months / 12 < -TK_CAL_YEAR_LIMIT || f.year + months / 12 > TK_CAL_YEAR_LIMIT)
            return TK_LOCAL_RANGE;
        tk_cal_add_months(cal, f.year, f.month, f.day, months, eom, &cy, &cm, &cd);
        if (!tk_cal_year_ok(cal, cy) || (cal->year_min && cy == cal->year_max && !tk_cal_days_ok(cal, cal->to_days(cy, cm, cd))))
            return TK_LOCAL_RANGE;
        tk_civil_from_days(cal->to_days(cy, cm, cd), &y, &m, &d);
    }
    else
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
        out->calendar = v->calendar;
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
        out->calendar = v->calendar;
    return 1;
}

/* ---- plus ------------------------------------------------------------- */

/* The croak for a TK_LOCAL_ result that is not OK. */
static void
tk_local_croak(pTHX_ int r, const tk_value *v, const char *what)
{
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

/* v's wall-clock time years on in its calendar, the month kept by its code. */
static void
tk_value_plus_years(pTHX_ tk_value *out, tk_value *v, int64_t years, int eom, int gap, int overlap, const char *what)
{
    const tk_calendar *cal = tk_cal_of(v);
    tk_calfields f;
    tk_civil c = *tk_value_civil(v);
    tk_zone_spec z;
    int64_t cy, y;
    unsigned cm, cd, m, d;
    if (years == 0) {
        *out = *v;
        return;
    }
    if (!tk_cal_days_ok(cal, tk_value_local_days(v)))
        tk_cal_croak_range(aTHX_ cal, what);
    tk_cal_fields(cal, tk_value_local_days(v), &f);
    if (years > TK_CAL_YEAR_LIMIT || years < -TK_CAL_YEAR_LIMIT || !tk_cal_year_ok(cal, f.year + years))
        tk_cal_croak_range(aTHX_ cal, what);
    tk_cal_add_years(cal, f.year, f.month, f.day, years, eom, &cy, &cm, &cd);
    tk_civil_from_days(cal->to_days(cy, cm, cd), &y, &m, &d);
    if (y < TK_YEAR_MIN || y > TK_YEAR_MAX)
        croak("%s: out of range", what);
    tk_value_zone(v, &z);
    tk_local_croak(aTHX_ tk_value_from_local_rc(aTHX_ out, &z, y, m, d, c.hour, c.minute, c.second, c.nsec, gap, overlap), v, what);
    out->locale = v->locale;
    out->calendar = v->calendar;
}

static void
tk_value_plus(pTHX_ tk_value *out, tk_value *v, const tk_duration *d,
              int gap, int overlap, const char *what)
{
    tk_value mid = *v;
    if (d->months || d->days)
        tk_local_croak(aTHX_ tk_value_calendar_rc(aTHX_ &mid, v, d->months, d->days, d->eom, gap, overlap),
                       v, what);
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

/* b - a, the duration that takes a to b (K12). calendar 1: months, then
 * days, then clock time; 2: days, then clock time; 0: clock time alone. */
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
        if (calendar == 1 && a->calendar != TK_CAL_GREGORY) {
            const tk_calendar *cal = tk_cal_of(a);
            tk_calfields fa, fb;
            tk_cal_fields(cal, tk_value_local_days(a), &fa);
            tk_cal_fields(cal, tk_value_local_days(&b), &fb);
            m = (tk_cal_months_before(cal, fb.year) + fb.month) - (tk_cal_months_before(cal, fa.year) + fa.month);
            if (m * sign < 0)
                m = 0;
        }
        else if (calendar == 1) {
            m = ((int64_t)cb->year * 12 + cb->month) - ((int64_t)ca->year * 12 + ca->month);
            if (m * sign < 0)
                m = 0;
        }
        /* the most months that do not go past b */
        for (; m != 0; m -= sign) {
            if (tk_value_calendar_rc(aTHX_ &i, a, m, 0, tk_dur_default_eom(m),
                                     TK_GAP_DEFAULT, TK_OVERLAP_DEFAULT) == TK_LOCAL_OK
                && tk_inst_cmp(&i.inst, &b.inst) * sign <= 0)
                break;
        }
        /* then the most days */
        if (a->calendar != TK_CAL_GREGORY) {
            const tk_calendar *cal = tk_cal_of(a);
            tk_calfields fa;
            tk_cal_fields(cal, tk_value_local_days(a), &fa);
            tk_cal_add_months(cal, fa.year, fa.month, fa.day, m, tk_dur_default_eom(m), &yy, &mm, &dd);
            days = tk_value_local_days(&b) - cal->to_days(yy, mm, dd);
        }
        else {
            tk_add_months_ymd(ca->year, ca->month, ca->day, m, tk_dur_default_eom(m), &yy, &mm, &dd);
            days = tk_days_from_civil(cb->year, cb->month, cb->day) - tk_days_from_civil(yy, mm, dd);
        }
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

/* ---- truncate, round and the end of a period ---------------------------- */

enum { TK_U_YEAR, TK_U_QUARTER, TK_U_MONTH, TK_U_WEEK, TK_U_DAY, TK_U_HOUR,
       TK_U_MINUTE, TK_U_SECOND, TK_U_MILLISECOND, TK_U_MICROSECOND, TK_U_NANOSECOND,
       TK_U_COUNT };

static const char *const tk_unit_names[TK_U_COUNT] = {
    "year", "quarter", "month", "week", "day", "hour", "minute", "second",
    "millisecond", "microsecond", "nanosecond"
};

#define TK_UNIT_LIST \
    "year, quarter, month, week, day, hour, minute, second, millisecond, microsecond or nanosecond"

/* A unit's name, singular or plural (durations say hours). */
static int
tk_opt_unit(pTHX_ SV *sv, const char *what)
{
    STRLEN len;
    const char *s = SvPV(sv, len);
    int i;
    if (len > 1 && s[len - 1] == 's')
        len--;
    for (i = 0; i < TK_U_COUNT; i++)
        if (strlen(tk_unit_names[i]) == len && memEQ(s, tk_unit_names[i], len))
            return i;
    croak("%s: '%s' is not " TK_UNIT_LIST, what, s);
    return 0;
}

/* The increments a unit allows: a divisor of the next unit up, below it. */
static unsigned
tk_unit_span(int unit)
{
    switch (unit) {
    case TK_U_HOUR:        return 24;
    case TK_U_MINUTE:      return 60;
    case TK_U_SECOND:      return 60;
    case TK_U_MILLISECOND: return 1000;
    case TK_U_MICROSECOND: return 1000;
    case TK_U_NANOSECOND:  return 1000;
    default:               return 1;
    }
}

static int64_t
tk_opt_increment(pTHX_ SV *sv, int unit, const char *what)
{
    unsigned span = tk_unit_span(unit);
    int64_t inc = tk_opt_int(aTHX_ sv, what, "increment", 1, span == 1 ? 1 : span - 1);
    if (span % inc)
        croak("%s: increment %" IVdf " does not divide the %u %ss of the next unit up", what, (IV)inc,
              span, tk_unit_names[unit]);
    return inc;
}

enum { TK_RM_FLOOR, TK_RM_CEIL, TK_RM_HALF_FLOOR, TK_RM_HALF_CEIL, TK_RM_HALF_EVEN, TK_RM_TRUNC,
       TK_RM_EXPAND };

/* A unit of a duration: any but a quarter. */
static int
tk_opt_dur_unit(pTHX_ SV *sv, const char *name, const char *what)
{
    int u = tk_opt_unit(aTHX_ sv, what);
    if (u == TK_U_QUARTER)
        croak("%s: %s cannot be quarters: a duration has none", what, name);
    return u;
}

static int
tk_opt_mode(pTHX_ SV *sv, const char *what)
{
    const char *s = SvPV_nolen(sv);
    if (strEQ(s, "floor"))      return TK_RM_FLOOR;
    if (strEQ(s, "ceil"))       return TK_RM_CEIL;
    if (strEQ(s, "half_floor")) return TK_RM_HALF_FLOOR;
    if (strEQ(s, "half_ceil"))  return TK_RM_HALF_CEIL;
    if (strEQ(s, "half_even"))  return TK_RM_HALF_EVEN;
    if (strEQ(s, "trunc"))      return TK_RM_TRUNC;
    if (strEQ(s, "expand"))     return TK_RM_EXPAND;
    croak("%s: mode is 'floor', 'ceil', 'half_floor', 'half_ceil', 'half_even', 'trunc' or 'expand', not '%s'", what, s);
    return 0;
}

/* Whether to go up from a bucket's start: twice_cmp is 2 * rem against the
 * bucket's full length (-1, 0, 1), rem_zero whether the value is at the
 * start, and index the bucket's number. For an instant trunc is floor and
 * expand is ceil; a duration maps them by its sign first. */
static int
tk_round_decide(int mode, int twice_cmp, int rem_zero, int64_t index)
{
    switch (mode) {
    case TK_RM_FLOOR: case TK_RM_TRUNC:  return 0;
    case TK_RM_CEIL:  case TK_RM_EXPAND: return !rem_zero;
    case TK_RM_HALF_FLOOR:               return twice_cmp > 0;
    case TK_RM_HALF_CEIL:                return twice_cmp >= 0 && !rem_zero;
    default:                             return twice_cmp > 0 || (twice_cmp == 0 && tk_floor_mod(index, 2) != 0);
    }
}

static int
tk_round_up(int mode, int64_t rem, int64_t full, int64_t index)
{
    int cmp = 2 * rem < full ? -1 : 2 * rem > full;
    return tk_round_decide(mode, cmp, rem == 0, index);
}

/* The wall-clock fields at the start of c's bucket: the smaller fields at
 * their least and the unit's own field a multiple of inc. A week begins on
 * ws, 1 Monday to 7 Sunday. */
static void
tk_period_start(const tk_civil *c, int unit, int64_t inc, int ws, int64_t *y, unsigned *m, unsigned *d,
                unsigned *h, unsigned *mi, unsigned *s, int32_t *ns)
{
    *y = c->year;
    *m = c->month;
    *d = c->day;
    *h = c->hour;
    *mi = c->minute;
    *s = c->second;
    *ns = 0;
    switch (unit) {
    case TK_U_YEAR:    *m = 1; /* fall through */
    case TK_U_MONTH:   *d = 1; *h = *mi = *s = 0; break;
    case TK_U_QUARTER: *m = (tk_quarter(c->month) - 1) * 3 + 1; *d = 1; *h = *mi = *s = 0; break;
    case TK_U_WEEK:
        tk_civil_from_days(tk_days_from_civil(c->year, c->month, c->day) - ((c->dow - ws + 7) % 7), y, m, d);
        *h = *mi = *s = 0;
        break;
    case TK_U_DAY:         *h = *mi = *s = 0; break;
    case TK_U_HOUR:        *h -= *h % inc; *mi = *s = 0; break;
    case TK_U_MINUTE:      *mi -= *mi % inc; *s = 0; break;
    case TK_U_SECOND:      *s -= *s % inc; break;
    case TK_U_MILLISECOND: *ns = c->nsec - c->nsec % (1000000 * (int32_t)inc); break;
    case TK_U_MICROSECOND: *ns = c->nsec - c->nsec % (1000 * (int32_t)inc); break;
    default:               *ns = c->nsec - c->nsec % (int32_t)inc; break;
    }
}

/* The bucket's number, from the start of the day for the clock units and
 * from the start of the calendar for the rest: half_even goes to the even
 * one. */
static int64_t
tk_bucket_index(int64_t y, unsigned m, unsigned d, unsigned h, unsigned mi, unsigned s, int32_t ns,
                int unit, int64_t inc)
{
    int64_t sod = (int64_t)h * 3600 + mi * 60 + s;
    switch (unit) {
    case TK_U_YEAR:        return y;
    case TK_U_QUARTER:     return y * 4 + tk_quarter(m) - 1;
    case TK_U_MONTH:       return y * 12 + m - 1;
    case TK_U_WEEK:        return tk_floor_div(tk_days_from_civil(y, m, d), 7);
    case TK_U_DAY:         return tk_days_from_civil(y, m, d);
    case TK_U_HOUR:        return h / inc;
    case TK_U_MINUTE:      return (sod / 60) / inc;
    case TK_U_SECOND:      return sod / inc;
    case TK_U_MILLISECOND: return (sod * 1000 + ns / 1000000) / inc;
    case TK_U_MICROSECOND: return (sod * 1000000 + ns / 1000) / inc;
    default:               return (sod * TK_NSECS_PER_SEC + ns) / inc;
    }
}

/* ---- what the arithmetic needs ---------------------------------------- */

/* The first day of v's year, quarter or month in its calendar, as days. */
static int64_t
tk_cal_period_first_day(const tk_calendar *cal, const tk_calfields *f, int unit)
{
    if (unit == TK_U_YEAR)
        return cal->to_days(f->year, 1, 1);
    if (unit == TK_U_QUARTER)
        return cal->to_days(f->year, ((f->month - 1) / 3) * 3 + 1, 1);
    return cal->to_days(f->year, f->month, 1);
}

/* The first day of the period after f's. */
static int64_t
tk_cal_period_next_day(const tk_calendar *cal, const tk_calfields *f, int unit)
{
    int64_t y;
    unsigned m, d;
    if (unit == TK_U_YEAR)
        return cal->to_days(f->year + 1, 1, 1);
    if (unit == TK_U_QUARTER) {
        unsigned next = ((f->month - 1) / 3) * 3 + 4;
        return next > f->months_in_year ? cal->to_days(f->year + 1, 1, 1) : cal->to_days(f->year, next, 1);
    }
    tk_cal_add_months(cal, f->year, f->month, 1, 1, TK_EOM_LIMIT, &y, &m, &d);
    return cal->to_days(y, m, d);
}

/* The bucket's number for half_even: years, quarters or months from the
 * calendar's own start. */
static int64_t
tk_cal_bucket_index(const tk_calendar *cal, const tk_calfields *f, int unit)
{
    if (unit == TK_U_YEAR)
        return f->year;
    if (unit == TK_U_QUARTER)
        return (tk_cal_months_before(cal, f->year) + f->month - 1) / 3;
    return tk_cal_months_before(cal, f->year) + f->month - 1;
}

/* The start of v's bucket: the latest wall time at or before v on a bucket
 * boundary. Where that wall time fell in a gap, the first moment after it;
 * where it came twice, the reading at or before v. */
static void
tk_value_bucket(pTHX_ tk_value *out, tk_value *v, int unit, int64_t inc, int ws, const char *what)
{
    tk_zone_spec z;
    int64_t y;
    unsigned m, d, h, mi, s;
    int32_t ns;

    tk_period_start(tk_value_civil(v), unit, inc, ws, &y, &m, &d, &h, &mi, &s, &ns);
    if (v->calendar != TK_CAL_GREGORY && unit <= TK_U_MONTH) {
        tk_calfields f;
        tk_cal_fields(tk_cal_of(v), tk_value_local_days(v), &f);
        tk_civil_from_days(tk_cal_period_first_day(tk_cal_of(v), &f, unit), &y, &m, &d);
    }
    tk_value_zone(v, &z);
    if (tk_value_from_local_rc(aTHX_ out, &z, y, m, d, h, mi, s, ns, TKZ_GAP_FORWARD,
                               TKZ_OVERLAP_LATER) != TK_LOCAL_OK
        || tk_inst_cmp(&out->inst, &v->inst) > 0)
        tk_value_from_local(aTHX_ out, &z, y, m, d, h, mi, s, ns, TKZ_GAP_FORWARD,
                            TKZ_OVERLAP_EARLIER, what);
    out->locale = v->locale;
        out->calendar = v->calendar;
}

static void
tk_value_truncate_ws(pTHX_ tk_value *out, tk_value *v, int unit, int ws, const char *what)
{
    tk_value_bucket(aTHX_ out, v, unit, 1, ws, what);
}

/* The start of v's unit, weeks from Monday. */
static void
tk_value_truncate(pTHX_ tk_value *out, tk_value *v, int unit, const char *what)
{
    tk_value_bucket(aTHX_ out, v, unit, 1, 1, what);
}

/* The first moment of the bucket after lo's, lo being a value at the start
 * of its bucket. For the calendar units and for hours in increments it is
 * the wall-clock start of the next bucket found in the zone, so a midnight
 * the clocks skipped gives the first moment that did happen; for the other
 * clock units it is the bucket's length of clock time on. 0 when it leaves
 * the range. */
static int
tk_value_bucket_next(pTHX_ tk_value *hi, tk_value *lo, int unit, int64_t inc, int ws)
{
    tk_zone_spec z;
    int64_t y;
    unsigned m, d, h, mi, s;
    int32_t ns;

    switch (unit) {
    case TK_U_HOUR:        if (inc == 1) return tk_value_clock_rc(aTHX_ hi, lo, 60, 0, 0); break;
    case TK_U_MINUTE:      return tk_value_clock_rc(aTHX_ hi, lo, inc, 0, 0);
    case TK_U_SECOND:      return tk_value_clock_rc(aTHX_ hi, lo, 0, inc, 0);
    case TK_U_MILLISECOND: return tk_value_clock_rc(aTHX_ hi, lo, 0, 0, inc * 1000000);
    case TK_U_MICROSECOND: return tk_value_clock_rc(aTHX_ hi, lo, 0, 0, inc * 1000);
    case TK_U_NANOSECOND:  return tk_value_clock_rc(aTHX_ hi, lo, 0, 0, inc);
    default:               break;
    }
    tk_period_start(tk_value_civil(lo), unit, inc, ws, &y, &m, &d, &h, &mi, &s, &ns);
    if (lo->calendar != TK_CAL_GREGORY && unit <= TK_U_MONTH) {
        tk_calfields f;
        if (!tk_cal_days_ok(tk_cal_of(lo), tk_value_local_days(lo)))
            return 0;
        tk_cal_fields(tk_cal_of(lo), tk_value_local_days(lo), &f);
        if (f.year >= TK_CAL_YEAR_LIMIT || !tk_cal_year_ok(tk_cal_of(lo), f.year + 1))
            return 0;
        tk_civil_from_days(tk_cal_period_next_day(tk_cal_of(lo), &f, unit), &y, &m, &d);
    }
    else switch (unit) {
    case TK_U_YEAR:    y += 1; break;
    case TK_U_QUARTER: m += 3; if (m > 12) { m -= 12; y += 1; } break;
    case TK_U_MONTH:   m += 1; if (m > 12) { m = 1; y += 1; } break;
    case TK_U_WEEK:    tk_civil_from_days(tk_days_from_civil(y, m, d) + 7, &y, &m, &d); break;
    case TK_U_HOUR:
        h += (unsigned)inc;
        if (h < 24)
            break;
        h = 0;
        /* fall through */
    default:           tk_civil_from_days(tk_days_from_civil(y, m, d) + 1, &y, &m, &d); break;
    }
    if (y < TK_YEAR_MIN || y > TK_YEAR_MAX)
        return 0;
    tk_value_zone(lo, &z);
    if (tk_value_from_local_rc(aTHX_ hi, &z, y, m, d, h, 0, 0, 0, TKZ_GAP_FORWARD,
                               TKZ_OVERLAP_EARLIER) != TK_LOCAL_OK)
        return 0;
    hi->locale = lo->locale;
    hi->calendar = lo->calendar;
    return 1;
}

static int
tk_value_next_period(pTHX_ tk_value *hi, tk_value *lo, int unit)
{
    return tk_value_bucket_next(aTHX_ hi, lo, unit, 1, 1);
}

/* The start of v's bucket or of the next, as the mode says: the nearer by
 * elapsed time for the half modes, the later when they are as near
 * (half_ceil, the default), the even bucket (half_even). */
static void
tk_value_round(pTHX_ tk_value *out, tk_value *v, int unit, int64_t inc, int mode, int ws, const char *what)
{
    tk_value lo, hi;
    int64_t s1, s2, rem, full;
    int32_t n1, n2;

    tk_value_bucket(aTHX_ &lo, v, unit, inc, ws, what);
    tk_value_minus_exact(v, &lo, &s1, &n1);
    if (!tk_value_bucket_next(aTHX_ &hi, &lo, unit, inc, ws) || (s1 == 0 && n1 == 0)) {
        *out = lo;
        return;
    }
    tk_value_minus_exact(&hi, v, &s2, &n2);
    /* rem and full in nanoseconds would overflow for a year: compare in
     * seconds with the nanoseconds as the tie-breaker */
    if (s1 != s2 || n1 != n2) {
        int nearer_hi = s2 < s1 || (s2 == s1 && n2 < n1);
        switch (mode) {
        case TK_RM_FLOOR: case TK_RM_TRUNC:  break;
        case TK_RM_CEIL:  case TK_RM_EXPAND: lo = hi; break;
        default:                             if (nearer_hi) lo = hi; break;
        }
        *out = lo;
        return;
    }
    /* as near: the mode decides */
    rem = full = 1;
    {
        const tk_civil *c = tk_value_civil(&lo);
        int64_t index;
        if (lo.calendar != TK_CAL_GREGORY && unit <= TK_U_MONTH) {
            tk_calfields f;
            tk_cal_fields(tk_cal_of(&lo), tk_value_local_days(&lo), &f);
            index = tk_cal_bucket_index(tk_cal_of(&lo), &f, unit);
        }
        else
            index = tk_bucket_index(c->year, c->month, c->day, c->hour, c->minute, c->second,
                                    c->nsec, unit, inc);
        if (tk_round_up(mode, rem, 2 * full, index))
            lo = hi;
    }
    *out = lo;
}

/* The last nanosecond of v's unit: the instant before the next unit's
 * first moment. On a day that ends in a leap second it is 23:59:60.999999999.
 * The last unit of all has no next: it ends where the range does. */
static void
tk_value_end_of(pTHX_ tk_value *out, tk_value *v, int unit, int ws, const char *what)
{
    tk_value lo, hi;

    tk_value_truncate_ws(aTHX_ &lo, v, unit, ws, what);
    if (!tk_value_bucket_next(aTHX_ &hi, &lo, unit, 1, ws)) {
        tk_zone_spec z;
        tk_instant t;
        t.sec = tk_sec_max();
        t.nsec = TK_NSECS_PER_SEC - 1;
        tk_value_zone(v, &z);
        tk_value_init(aTHX_ out, &t, &z);
        out->locale = v->locale;
        out->calendar = v->calendar;
        return;
    }
    if (!tk_value_clock_rc(aTHX_ out, &hi, 0, 0, -1))
        croak("%s: out of range", what);
}

/* ---- rounding a duration ------------------------------------------------- */

/* The clock part of d rounded to inc units, as a duration of seconds, or
 * of minutes when d had minutes alone and the unit is a minute or more.
 * 0 when the result leaves the range. */
static int
tk_dur_round(tk_duration *out, const tk_duration *d, int unit, int64_t inc, int mode)
{
    int64_t secs = d->minutes * 60 + d->seconds, ns = d->nsec, lo_secs, lo_ns, rem, full, index;
    int minutes_only = d->seconds == 0 && d->nsec == 0 && (unit == TK_U_HOUR || unit == TK_U_MINUTE);

    if (ns < 0) {
        secs -= 1;
        ns += TK_NSECS_PER_SEC;
    }
    if (unit <= TK_U_SECOND) {
        int64_t lsec = inc * (unit == TK_U_HOUR ? 3600 : unit == TK_U_MINUTE ? 60 : 1);
        int64_t r = tk_floor_mod(secs, lsec);
        lo_secs = secs - r;
        lo_ns = 0;
        rem = r * TK_NSECS_PER_SEC + ns;
        full = lsec * TK_NSECS_PER_SEC;
        index = tk_floor_div(lo_secs, lsec);
        if (tk_round_up(mode, rem, full, index))
            lo_secs += lsec;
    }
    else {
        int64_t lns = inc * (unit == TK_U_MILLISECOND ? 1000000 : unit == TK_U_MICROSECOND ? 1000 : 1);
        int64_t per_sec = TK_NSECS_PER_SEC / lns;
        lo_secs = secs;
        lo_ns = ns - ns % lns;
        rem = ns % lns;
        full = lns;
        index = tk_floor_mod(secs, 2) * (per_sec % 2) + (lo_ns / lns) % 2;
        if (tk_round_up(mode, rem, full, index))
            lo_ns += lns;
    }
    Zero(out, 1, tk_duration);
    out->eom = d->eom;
    if (minutes_only) {
        out->minutes = lo_secs / 60;
        return tk_dur_in_range(out->minutes);
    }
    out->seconds = lo_secs;
    return tk_dur_normalize(out, lo_ns);
}

/* ---- until: the difference in the units asked for ------------------------ */

/* b - a with the parts the largest unit allows: months and days (years are
 * months), days alone (weeks are days), minutes and seconds, or seconds alone
 * as elapsed SI time. */
static void
tk_value_until_raw(pTHX_ tk_duration *d, tk_value *b, tk_value *a, int largest)
{
    if (largest == TK_U_YEAR && a->calendar != TK_CAL_GREGORY)
        croak("Time::Keeper->until: largest => 'years' in the %s calendar comes in a later release; largest => 'months' counts its months", tk_cal_of(a)->id);
    if (largest <= TK_U_MONTH)
        tk_value_difference(aTHX_ d, b, a, 1);
    else if (largest <= TK_U_DAY)
        tk_value_difference(aTHX_ d, b, a, 2);
    else if (largest <= TK_U_MINUTE)
        tk_value_difference(aTHX_ d, b, a, 0);
    else {
        tk_value bb;
        int64_t s;
        int32_t n;
        tk_value_in_zone_of(aTHX_ &bb, b, a);
        tk_value_minus_exact(&bb, a, &s, &n);
        Zero(d, 1, tk_duration);
        d->seconds = s;
        d->nsec = n;
        d->eom = TK_EOM_WRAP;
    }
}

/* a moved on by d with a gap taken forward: a rounding candidate. 0 when it
 * leaves the range. */
static int
tk_value_plus_rc(pTHX_ tk_value *out, tk_value *a, const tk_duration *d)
{
    tk_value mid = *a;
    if (d->months || d->days) {
        if (tk_value_calendar_rc(aTHX_ &mid, a, d->months, d->days, d->eom, TKZ_GAP_FORWARD,
                                 TK_OVERLAP_DEFAULT) != TK_LOCAL_OK)
            return 0;
    }
    if (d->minutes || d->seconds || d->nsec)
        return tk_value_clock_rc(aTHX_ out, &mid, d->minutes, d->seconds, d->nsec);
    *out = mid;
    return 1;
}

static int
tk_dur_sign(const tk_duration *d)
{
    return (d->months < 0 || d->days < 0 || d->minutes < 0 || d->seconds < 0 || d->nsec < 0) ? -1 : 1;
}

/* The parts below the unit dropped and the unit's own part a multiple of
 * inc, towards zero. */
static void
tk_dur_floor_at(tk_duration *d, int unit, int64_t inc)
{
    switch (unit) {
    case TK_U_YEAR:        d->months -= d->months % 12; /* fall through */
    case TK_U_MONTH:       d->days = 0; d->minutes = d->seconds = 0; d->nsec = 0; break;
    case TK_U_WEEK:        d->days -= d->days % 7; /* fall through */
    case TK_U_DAY:         d->minutes = d->seconds = 0; d->nsec = 0; break;
    case TK_U_HOUR:        d->minutes -= d->minutes % (60 * inc); d->seconds = 0; d->nsec = 0; break;
    case TK_U_MINUTE:      d->minutes -= d->minutes % inc; d->seconds = 0; d->nsec = 0; break;
    case TK_U_SECOND:      d->seconds -= d->seconds % inc; d->nsec = 0; break;
    case TK_U_MILLISECOND: d->nsec -= d->nsec % (1000000 * (int32_t)inc); break;
    case TK_U_MICROSECOND: d->nsec -= d->nsec % (1000 * (int32_t)inc); break;
    default:               d->nsec -= d->nsec % (int32_t)inc; break;
    }
}

/* One bucket of the unit on, in the duration's direction. */
static int
tk_dur_bucket_up(tk_duration *d, int unit, int64_t inc, int sign)
{
    int64_t ns = d->nsec;
    switch (unit) {
    case TK_U_YEAR:        d->months += 12 * sign; break;
    case TK_U_MONTH:       d->months += sign; break;
    case TK_U_WEEK:        d->days += 7 * sign; break;
    case TK_U_DAY:         d->days += sign; break;
    case TK_U_HOUR:        d->minutes += 60 * inc * sign; break;
    case TK_U_MINUTE:      d->minutes += inc * sign; break;
    case TK_U_SECOND:      d->seconds += inc * sign; break;
    case TK_U_MILLISECOND: ns += 1000000 * inc * sign; break;
    case TK_U_MICROSECOND: ns += 1000 * inc * sign; break;
    default:               ns += inc * sign; break;
    }
    return tk_dur_normalize(d, ns);
}

/* The parity of the bucket's number, counted in the unit from the start. */
static int64_t
tk_dur_bucket_parity(const tk_duration *d, int unit, int64_t inc)
{
    int64_t mo = d->months < 0 ? -d->months : d->months;
    int64_t dy = d->days < 0 ? -d->days : d->days;
    int64_t mi = d->minutes < 0 ? -d->minutes : d->minutes;
    int64_t se = d->seconds < 0 ? -d->seconds : d->seconds;
    int64_t ns = d->nsec < 0 ? -d->nsec : d->nsec;
    switch (unit) {
    case TK_U_YEAR:        return (mo / 12) % 2;
    case TK_U_MONTH:       return mo % 2;
    case TK_U_WEEK:        return (dy / 7) % 2;
    case TK_U_DAY:         return dy % 2;
    case TK_U_HOUR:        return (mi / (60 * inc)) % 2;
    case TK_U_MINUTE:      return (mi / inc) % 2;
    case TK_U_SECOND:      return ((mi % 2) * ((60 / inc) % 2) + (se / inc) % 2) % 2;
    case TK_U_MILLISECOND: return ((se % 2) * ((1000 / inc) % 2) + ((ns / 1000000) / inc) % 2) % 2;
    case TK_U_MICROSECOND: return ((se % 2) * ((1000000 / inc) % 2) + ((ns / 1000) / inc) % 2) % 2;
    default:               return ((se % 2) * ((TK_NSECS_PER_SEC / inc) % 2) + (ns / inc) % 2) % 2;
    }
}

/* A mode in terms of the magnitude: floor of a negative duration is away
 * from zero, trunc towards it. */
static int
tk_mode_toward(int mode, int sign)
{
    if (sign > 0)
        return mode == TK_RM_TRUNC ? TK_RM_FLOOR : mode == TK_RM_EXPAND ? TK_RM_CEIL : mode;
    switch (mode) {
    case TK_RM_FLOOR: case TK_RM_EXPAND: return TK_RM_CEIL;
    case TK_RM_CEIL:  case TK_RM_TRUNC:  return TK_RM_FLOOR;
    case TK_RM_HALF_FLOOR:               return TK_RM_HALF_CEIL;
    case TK_RM_HALF_CEIL:                return TK_RM_HALF_FLOOR;
    default:                             return mode;
    }
}

static void
tk_abs_pair(int64_t *s, int32_t *n)
{
    if (*s < 0 || (*s == 0 && *n < 0)) {
        *s = -*s;
        *n = -*n;
    }
}

/* 2 * (rs, rn) against (fs, fn): -1, 0 or 1. */
static int
tk_pair_twice_cmp(int64_t rs, int32_t rn, int64_t fs, int32_t fn)
{
    int64_t ts = 2 * rs + (2 * (int64_t)rn) / TK_NSECS_PER_SEC;
    int32_t tn = (int32_t)((2 * (int64_t)rn) % TK_NSECS_PER_SEC);
    if (ts != fs)
        return ts < fs ? -1 : 1;
    return tn < fn ? -1 : tn > fn;
}

/* b - a with the parts the largest unit allows, rounded at the smallest:
 * the parts below it dropped and the unit's part to a multiple of inc, the
 * mode choosing between the bucket's start and the next. The two are
 * measured as instants from a, so a day is as long as it was, and a clock
 * part that rounds up into the unit above is balanced again. */
static void
tk_value_until(pTHX_ tk_duration *d, tk_value *b, tk_value *a, int largest, int smallest,
               int64_t inc, int mode)
{
    tk_duration lo_d, hi_d;
    tk_value lo, hi, bb;
    int sign, up;
    int64_t rs, fs;
    int32_t rn, fn;

    tk_value_until_raw(aTHX_ d, b, a, largest);
    if (smallest == TK_U_NANOSECOND && inc == 1)
        return;
    sign = tk_dur_sign(d);
    lo_d = *d;
    tk_dur_floor_at(&lo_d, smallest, inc);
    hi_d = lo_d;
    if (!tk_dur_bucket_up(&hi_d, smallest, inc, sign)
        || !tk_value_plus_rc(aTHX_ &lo, a, &lo_d) || !tk_value_plus_rc(aTHX_ &hi, a, &hi_d)) {
        *d = lo_d;
        return;
    }
    tk_value_in_zone_of(aTHX_ &bb, b, a);
    tk_value_minus_exact(&bb, &lo, &rs, &rn);
    tk_value_minus_exact(&hi, &lo, &fs, &fn);
    tk_abs_pair(&rs, &rn);
    tk_abs_pair(&fs, &fn);
    if (rs == 0 && rn == 0) {
        *d = lo_d;
        return;
    }
    up = tk_round_decide(tk_mode_toward(mode, sign), tk_pair_twice_cmp(rs, rn, fs, fn), 0,
                         tk_dur_bucket_parity(&lo_d, smallest, inc));
    if (!up)
        *d = lo_d;
    else if (smallest <= TK_U_DAY)
        *d = hi_d;
    else
        tk_value_until_raw(aTHX_ d, &hi, a, largest);
}

/* The whole units of d in the unit, from the parts: the count that until
 * with largest and smallest both the unit leaves. */
static int64_t
tk_dur_count(const tk_duration *d, int unit)
{
    switch (unit) {
    case TK_U_YEAR:  return d->months / 12;
    case TK_U_MONTH: return d->months;
    case TK_U_WEEK:  return d->days / 7;
    default:         return d->days;
    }
}

/* secs as a number of the clock unit. A sub-second unit multiplies by
 * its exact count per second: dividing by an inexact 1e-3 leaves 1.5 s
 * at 1499.99999999999997 ms where x87 keeps the extra precision. */
static double
tk_secs_in_unit(double secs, int unit)
{
    switch (unit) {
    case TK_U_WEEK:        return secs / 604800.0;
    case TK_U_DAY:         return secs / 86400.0;
    case TK_U_HOUR:        return secs / 3600.0;
    case TK_U_MINUTE:      return secs / 60.0;
    case TK_U_SECOND:      return secs;
    case TK_U_MILLISECOND: return secs * 1e3;
    case TK_U_MICROSECOND: return secs * 1e6;
    default:               return secs * 1e9;
    }
}

/* d as a number of the unit, measured from rel: whole units by until, and
 * the fraction of the next by elapsed time. For a clock unit, the elapsed
 * time in it. 0 when the arithmetic leaves the range. */
static int
tk_dur_total_from(pTHX_ double *total, const tk_duration *d, int unit, tk_value *rel)
{
    tk_value end, lo, hi;
    tk_duration n, up;
    int64_t es, fs;
    int32_t en, fn;

    if (!tk_value_plus_rc(aTHX_ &end, rel, d))
        return 0;
    if (unit >= TK_U_HOUR) {
        tk_value_minus_exact(&end, rel, &es, &en);
        *total = tk_secs_in_unit((double)es + (double)en / TK_NSECS_PER_SEC, unit);
        return 1;
    }
    tk_value_until(aTHX_ &n, &end, rel, unit, unit, 1, TK_RM_TRUNC);
    up = n;
    if (!tk_value_plus_rc(aTHX_ &lo, rel, &n))
        return 0;
    if (!tk_dur_bucket_up(&up, unit, 1, tk_inst_cmp(&end.inst, &rel->inst) < 0 ? -1 : 1)
        || !tk_value_plus_rc(aTHX_ &hi, rel, &up))
        return 0;
    tk_value_minus_exact(&end, &lo, &es, &en);
    tk_value_minus_exact(&hi, &lo, &fs, &fn);
    *total = (double)tk_dur_count(&n, unit)
           + ((double)es + (double)en / TK_NSECS_PER_SEC) / ((double)fs + (double)fn / TK_NSECS_PER_SEC);
    return 1;
}

/* ---- weekdays ------------------------------------------------------------- */

static const char *const tk_dow_names[8] = {
    "", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
};

static const char *const tk_ordinal_names[6] = {
    "", "first", "second", "third", "fourth", "fifth"
};

/* v's wall-clock time on the next (direction 1) or previous (-1) day of
 * the week dow; v's own day counts when or_same and it is that day. */
static void
tk_value_adjust_dow(pTHX_ tk_value *out, tk_value *v, int dow, int direction, int or_same,
                    int gap, int overlap, const char *what)
{
    const tk_civil *c = tk_value_civil(v);
    int64_t delta = direction > 0 ? (dow - c->dow + 7) % 7 : -((c->dow - dow + 7) % 7);

    if (!delta && !or_same)
        delta = 7 * direction;
    tk_local_croak(aTHX_ tk_value_calendar_rc(aTHX_ out, v, 0, delta, TK_EOM_WRAP, gap, overlap),
                   v, what);
}

/* v's wall-clock time on the nth day of the week dow in v's month, n 1 to
 * 5, or on the last when n is -1. */
static void
tk_value_nth_in_month(pTHX_ tk_value *out, tk_value *v, int dow, int n, int gap, int overlap,
                      const char *what)
{
    const tk_civil *c = tk_value_civil(v);
    int64_t here = tk_days_from_civil(c->year, c->month, c->day);
    int64_t first = tk_days_from_civil(c->year, c->month, 1);
    unsigned len = tk_days_in_month(c->year, c->month);
    int64_t target, year_shown = c->year;
    unsigned month_shown = c->month;

    if (v->calendar != TK_CAL_GREGORY) {
        tk_calfields f;
        tk_cal_fields(tk_cal_of(v), here, &f);
        first = tk_cal_of(v)->to_days(f.year, f.month, 1);
        len = f.days_in_month;
        year_shown = f.year;
        month_shown = f.month;
    }

    if (n > 0) {
        target = first + (dow - (int)tk_dow_from_days(first) + 7) % 7 + (int64_t)(n - 1) * 7;
        if (target - first >= (int64_t)len)
            croak("%s: %04" IVdf "-%02u has no %s %s", what, (IV)year_shown, month_shown,
                  tk_ordinal_names[n], tk_dow_names[dow]);
    }
    else {
        int64_t last = first + len - 1;
        target = last - ((int)tk_dow_from_days(last) - dow + 7) % 7;
    }
    tk_local_croak(aTHX_ tk_value_calendar_rc(aTHX_ out, v, 0, target - here, TK_EOM_WRAP, gap, overlap),
                   v, what);
}

#endif
