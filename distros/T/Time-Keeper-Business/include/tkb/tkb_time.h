#ifndef TKB_TIME_H
#define TKB_TIME_H

/* Business time: wall-clock nanoseconds inside the spans. Adding walks
 * from the next open through the rest of the day, then whole plain weeks
 * at a stroke (a week with no holiday, worked weekend day or dated list
 * holds exactly the table's weekly total), then day by day, then into the
 * landing span, so an amount that ends on a close stops there. The time
 * between two moments is the same walk summed. */

#define TKB_NS_PER_SEC INT64_C(1000000000)
#define TKB_NS_PER_DAY (TKB_NS_PER_SEC * TKB_SECS_PER_DAY)

/* The business nanoseconds of a day's spans from a position on. */
static int64_t
tkb_day_remaining(const tkb_day *d, int64_t pos)
{
    int64_t total = 0;
    int i;
    for (i = 0; i < d->n; i++) {
        int64_t a = (int64_t)d->spans[i].start * TKB_NS_PER_SEC, b = (int64_t)d->spans[i].end * TKB_NS_PER_SEC;
        int64_t lo = pos > a ? pos : a;
        if (b > lo)
            total += b - lo;
    }
    return total;
}

/* The business nanoseconds of a day's spans before a position. */
static int64_t
tkb_day_elapsed(const tkb_day *d, int64_t pos)
{
    int64_t total = 0;
    int i;
    for (i = 0; i < d->n; i++) {
        int64_t a = (int64_t)d->spans[i].start * TKB_NS_PER_SEC, b = (int64_t)d->spans[i].end * TKB_NS_PER_SEC;
        int64_t hi = pos < b ? pos : b;
        if (hi > a)
            total += hi - a;
    }
    return total;
}

static size_t
tkb_dated_lower_bound(const tkb_dated *a, size_t n, int64_t day)
{
    size_t lo = 0, hi = n;
    while (lo < hi) {
        size_t mid = lo + (hi - lo) / 2;
        if (a[mid].day < day) lo = mid + 1; else hi = mid;
    }
    return lo;
}

/* Whether the seven days from a day hold exactly the table's weekly total:
 * no holiday on a weekday, no worked weekend day, no dated list. */
static int
tkb_week_is_plain(pTHX_ tkb_schedule *s, int64_t from, const char *what)
{
    tkb_ensure_span(aTHX_ s, from, from + 6, what);
    if (tkb_lower_bound(s->closed, s->n_closed, from + 7) != tkb_lower_bound(s->closed, s->n_closed, from))
        return 0;
    if (tkb_lower_bound(s->open, s->n_open, from + 7) != tkb_lower_bound(s->open, s->n_open, from))
        return 0;
    if (tkb_dated_lower_bound(s->hours.dated, s->hours.n_dated, from + 7) != tkb_dated_lower_bound(s->hours.dated, s->hours.n_dated, from))
        return 0;
    return 1;
}

/* A position forward within a day's spans by an amount known to fit. */
static int64_t
tkb_place_forward(const tkb_day *d, int64_t pos, int64_t amount)
{
    int i;
    for (i = 0; i < d->n; i++) {
        int64_t a = (int64_t)d->spans[i].start * TKB_NS_PER_SEC, b = (int64_t)d->spans[i].end * TKB_NS_PER_SEC;
        int64_t lo = pos > a ? pos : a, avail = b - lo;
        if (avail <= 0)
            continue;
        if (amount <= avail)
            return lo + amount;
        amount -= avail;
    }
    return pos;
}

static int64_t
tkb_place_backward(const tkb_day *d, int64_t pos, int64_t amount)
{
    int i;
    for (i = d->n - 1; i >= 0; i--) {
        int64_t a = (int64_t)d->spans[i].start * TKB_NS_PER_SEC, b = (int64_t)d->spans[i].end * TKB_NS_PER_SEC;
        int64_t hi = pos < b ? pos : b, avail = hi - a;
        if (avail <= 0)
            continue;
        if (amount <= avail)
            return hi - amount;
        amount -= avail;
    }
    return pos;
}

/* A moment moved by an amount of business time; zero is the next open. */
static void
tkb_add_time(pTHX_ tkb_schedule *s, int64_t *day, int32_t *secs, int32_t *nsec, int64_t amount, const char *what)
{
    const tkb_day *d;
    int64_t pos, weekly = (int64_t)s->hours.weekly_total * TKB_NS_PER_SEC;
    if (amount >= 0) {
        tkb_next_open(aTHX_ s, day, secs, nsec, what);
        if (amount == 0)
            return;
        for (;;) {
            int64_t rem;
            d = tkb_hours_on(aTHX_ s, *day, what);
            pos = (int64_t)*secs * TKB_NS_PER_SEC + *nsec;
            rem = tkb_day_remaining(d, pos);
            if (amount <= rem) {
                pos = tkb_place_forward(d, pos, amount);
                *secs = (int32_t)(pos / TKB_NS_PER_SEC);
                *nsec = (int32_t)(pos % TKB_NS_PER_SEC);
                return;
            }
            amount -= rem;
            while (weekly > 0 && amount > weekly && tkb_week_is_plain(aTHX_ s, *day + 1, what)) {
                *day += 7;
                amount -= weekly;
            }
            *day = tkb_next_day_with_hours(aTHX_ s, *day, 1, &d, what);
            *secs = d->spans[0].start;
            *nsec = 0;
        }
    }
    else {
        amount = -amount;
        for (;;) {
            int64_t el;
            d = tkb_hours_on(aTHX_ s, *day, what);
            pos = (int64_t)*secs * TKB_NS_PER_SEC + *nsec;
            el = tkb_day_elapsed(d, pos);
            if (amount <= el) {
                pos = tkb_place_backward(d, pos, amount);
                *secs = (int32_t)(pos / TKB_NS_PER_SEC);
                *nsec = (int32_t)(pos % TKB_NS_PER_SEC);
                return;
            }
            amount -= el;
            while (weekly > 0 && amount > weekly && tkb_week_is_plain(aTHX_ s, *day - 7, what)) {
                *day -= 7;
                amount -= weekly;
            }
            *day = tkb_next_day_with_hours(aTHX_ s, *day, -1, &d, what);
            *secs = d->spans[d->n - 1].end;
            *nsec = 0;
        }
    }
}

/* The business time from one moment to another, negative when the second
 * is first. */
static int64_t
tkb_time_between(pTHX_ tkb_schedule *s, int64_t a_day, int64_t a_pos, int64_t b_day, int64_t b_pos, const char *what)
{
    int64_t total, d, weekly = (int64_t)s->hours.weekly_total * TKB_NS_PER_SEC;
    if (a_day > b_day || (a_day == b_day && a_pos > b_pos))
        return -tkb_time_between(aTHX_ s, b_day, b_pos, a_day, a_pos, what);
    if (a_day == b_day) {
        const tkb_day *h = tkb_hours_on(aTHX_ s, a_day, what);
        return tkb_day_elapsed(h, b_pos) - tkb_day_elapsed(h, a_pos);
    }
    total = tkb_day_remaining(tkb_hours_on(aTHX_ s, a_day, what), a_pos);
    d = a_day + 1;
    while (d < b_day) {
        if (weekly >= 0 && b_day - d >= 7 && tkb_week_is_plain(aTHX_ s, d, what)) {
            total += weekly;
            d += 7;
            continue;
        }
        total += (int64_t)tkb_hours_on(aTHX_ s, d, what)->total * TKB_NS_PER_SEC;
        d++;
    }
    total += tkb_day_elapsed(tkb_hours_on(aTHX_ s, b_day, what), b_pos);
    return total;
}

/* An amount of business time from key/value pairs or a Duration of clock
 * units: nanoseconds, with days and end_of_day for deadline. */
static void
tkb_amount(pTHX_ SV **args, I32 n, int for_deadline, int64_t *amount, int64_t *days, int *end_of_day, const char *what)
{
    I32 i;
    NV total = 0;
    int64_t exact = 0;
    int all_exact = 1;
    *amount = 0;
    *days = 0;
    *end_of_day = 0;
    if (n == 1 && !for_deadline) {
        SV *dur = args[0];
        SV *parts[5];
        static const char *const names[] = { "months", "days", "hours", "minutes", "seconds" };
        int64_t v[5], ns;
        int k;
        if (!sv_isobject(dur) || !sv_derived_from(dur, "Time::Keeper::Duration"))
            croak("%s: takes key/value pairs or a Time::Keeper::Duration", what);
        for (k = 0; k < 5; k++) {
            parts[k] = tkb_call(aTHX_ dur, names[k], NULL, 0);
            if (!tkb_sv_to_i64(aTHX_ parts[k], &v[k]))
                croak("%s: the duration's %s could not be read", what, names[k]);
        }
        if (v[0] || v[1])
            croak("%s: a business duration has no months or days: use plus_business_days", what);
        if (!tkb_sv_to_i64(aTHX_ tkb_call(aTHX_ dur, "nanoseconds", NULL, 0), &ns))
            croak("%s: the duration's nanoseconds could not be read", what);
        exact = ((v[2] * 60 + v[3]) * 60 + v[4]) * TKB_NS_PER_SEC + ns;
        if (SvTRUE(tkb_call(aTHX_ dur, "is_negative", NULL, 0)))
            exact = -exact;
        *amount = exact;
        return;
    }
    if (n % 2)
        croak("%s: needs key/value pairs", what);
    for (i = 0; i < n; i += 2) {
        STRLEN klen;
        const char *k = SvPV(args[i], klen);
        SV *val = args[i + 1];
        int64_t unit = 0;
        NV nv;
        if (strEQ(k, "hours")) unit = 3600 * TKB_NS_PER_SEC;
        else if (strEQ(k, "minutes")) unit = 60 * TKB_NS_PER_SEC;
        else if (strEQ(k, "seconds")) unit = TKB_NS_PER_SEC;
        else if (strEQ(k, "milliseconds")) unit = 1000000;
        else if (strEQ(k, "microseconds")) unit = 1000;
        else if (strEQ(k, "nanoseconds")) unit = 1;
        else if (for_deadline && strEQ(k, "days")) {
            if (!tkb_sv_to_i64(aTHX_ val, days))
                croak("%s: days is not a whole number", what);
            continue;
        }
        else if (for_deadline && strEQ(k, "end_of_day")) {
            *end_of_day = SvTRUE(val) ? 1 : 0;
            continue;
        }
        else
            croak("%s: unknown argument '%s'", what, k);
        if (!val || !SvOK(val) || SvROK(val) || !looks_like_number(val))
            croak("%s: %s is not a number", what, k);
        nv = SvNV(val);
        if (nv == (NV)(int64_t)nv && nv > -9.0e9 && nv < 9.0e9)
            exact += (int64_t)nv * unit;
        else
            all_exact = 0;
        total += nv * (NV)unit;
    }
    if (total > 9.0e18 || total < -9.0e18)
        croak("%s: the amount of business time is out of range", what);
    *amount = all_exact ? exact : (int64_t)total;
}

#endif
