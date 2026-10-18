#ifndef TK_RANGE_H
#define TK_RANGE_H

/* The values from a start to an end by a step. Each is the start plus the
 * step times n, never the last value plus the step, so a step of a month
 * from the 31st lands where plus puts it and does not drift. One state
 * serves range, which gives a list, and iterate, which gives a code ref
 * holding the state in its magic. */

#define TK_RANGE_MAX 10000000

typedef struct tk_iter {
    tk_value start, end;
    tk_duration by;
    int64_t n;
    int dir, inclusive, gap, overlap, done;
    HV *stash;
} tk_iter;

static void
tk_dur_of_unit(int unit, tk_duration *d)
{
    Zero(d, 1, tk_duration);
    switch (unit) {
    case TK_U_YEAR:        d->months = 12; break;
    case TK_U_QUARTER:     d->months = 3; break;
    case TK_U_MONTH:       d->months = 1; break;
    case TK_U_WEEK:        d->days = 7; break;
    case TK_U_DAY:         d->days = 1; break;
    case TK_U_HOUR:        d->minutes = 60; break;
    case TK_U_MINUTE:      d->minutes = 1; break;
    case TK_U_SECOND:      d->seconds = 1; break;
    case TK_U_MILLISECOND: d->nsec = 1000000; break;
    case TK_U_MICROSECOND: d->nsec = 1000; break;
    default:               d->nsec = 1; break;
    }
    d->eom = tk_dur_default_eom(d->months);
}

/* -1, 0 or 1; 2 when the parts disagree in sign. */
static int
tk_dur_direction(const tk_duration *d)
{
    int neg = d->months < 0 || d->days < 0 || d->minutes < 0 || d->seconds < 0 || d->nsec < 0;
    int pos = d->months > 0 || d->days > 0 || d->minutes > 0 || d->seconds > 0 || d->nsec > 0;
    return neg && pos ? 2 : neg ? -1 : pos;
}

/* At least this many seconds per step: a month counts as 28 days. */
static double
tk_dur_least_seconds(const tk_duration *d)
{
    double s = (double)d->months * 28 * 86400 + (double)d->days * 86400
             + (double)d->minutes * 60 + (double)d->seconds + d->nsec / 1e9;
    return s < 0 ? -s : s;
}

static void
tk_range_init(pTHX_ tk_iter *it, SV *self, SV *end, SV **st, I32 n, const char *what)
{
    tk_args a;
    tk_duration one;
    int64_t step;
    int dir, c;
    Zero(it, 1, tk_iter);
    it->start = *tk_value_rw(self, what);
    it->end = *tk_value_rw(end, what);
    it->stash = SvSTASH(SvRV(self));
    tk_args_parse(aTHX_ st, n, TK_A(TK_A_BY) | TK_A(TK_A_STEP) | TK_A(TK_A_INCLUSIVE)
                  | TK_A(TK_A_END_OF_MONTH) | TK_A(TK_A_GAP) | TK_A(TK_A_OVERLAP), &a, what);
    if (!a.v[TK_A_BY])
        croak("%s: by is required", what);
    if (tk_is_dur(aTHX_ a.v[TK_A_BY]))
        one = *tk_dur_of(aTHX_ a.v[TK_A_BY], what);
    else
        tk_dur_of_unit(tk_opt_unit(aTHX_ a.v[TK_A_BY], what), &one);
    if (a.v[TK_A_END_OF_MONTH])
        one.eom = (uint8_t)tk_opt_eom(aTHX_ a.v[TK_A_END_OF_MONTH], what);
    step = tk_args_int(aTHX_ &a, TK_A_STEP, 1, 1, TK_DUR_LIMIT - 1, what);
    if (!tk_dur_multiply(&one, step, &it->by))
        croak("%s: the step is out of range", what);
    it->inclusive = a.v[TK_A_INCLUSIVE] ? SvTRUE(a.v[TK_A_INCLUSIVE]) : 1;
    tk_args_gap_overlap(aTHX_ &a, &it->gap, &it->overlap, what);
    dir = tk_dur_direction(&it->by);
    if (dir == 2)
        croak("%s: the step has parts of both signs", what);
    if (dir == 0)
        croak("%s: the step is zero", what);
    it->dir = dir;
    c = tk_value_cmp(&it->start, &it->end);
    if (c * dir > 0)
        croak("%s: the step does not move toward the end", what);
}

/* About how many values the range holds, from the shortest the step can
 * be; never fewer than the truth. */
static double
tk_range_estimate(const tk_iter *it)
{
    double span = (double)(it->end.inst.sec - it->start.inst.sec)
                + (it->end.inst.nsec - it->start.inst.nsec) / 1e9;
    if (it->start.zone == TK_ZONE_FLOATING || it->end.zone == TK_ZONE_FLOATING)
        span += (double)it->end.utoff - it->start.utoff;
    if (span < 0)
        span = -span;
    return span / tk_dur_least_seconds(&it->by) + 1;
}

static int
tk_range_next(pTHX_ tk_iter *it, tk_value *out, const char *what)
{
    tk_duration d;
    int c;
    if (it->done)
        return 0;
    if (!tk_dur_multiply(&it->by, it->n, &d))
        croak("%s: out of range", what);
    tk_value_plus(aTHX_ out, &it->start, &d, it->gap, it->overlap, what);
    c = tk_value_cmp(out, &it->end) * it->dir;
    if (c > 0 || (c == 0 && !it->inclusive)) {
        it->done = 1;
        return 0;
    }
    it->n++;
    return 1;
}

/* The state of an iterator lives in ext magic on its code ref. */
static MGVTBL tk_iter_vtbl = { 0 };

static tk_iter *
tk_iter_of(pTHX_ CV *cv, const char *what)
{
    MAGIC *mg;
    for (mg = SvMAGIC((SV *)cv); mg; mg = mg->mg_moremagic)
        if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &tk_iter_vtbl)
            return (tk_iter *)SvPVX(mg->mg_obj);
    croak("%s: not an iterator", what);
    return NULL;
}

#endif
