#ifndef TKB_HOURS_H
#define TKB_HOURS_H

/* Business hours. The table is wall-clock spans in the schedule's zone,
 * and business time is reckoned on that clock: nine to five is eight
 * hours on the day the clocks go forward as on any other, a repeated hour
 * counts once, and a leap second is part of 23:59:59. So every question
 * is integer work over a day number and seconds of the day; the zone is
 * touched only to split an instant into the two and to put them back
 * together, where a time the clocks skipped is carried forward and a
 * repeated one is read the earlier way, as Time::Keeper's defaults go. */

#define TKB_SECS_PER_DAY 86400

static const char *const tkb_dow_names[] = { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" };
static const char *const tkb_dow_keys[]  = { "mon", "tue", "wed", "thu", "fri", "sat", "sun" };

static const tkb_day tkb_no_hours = { NULL, 0, 0 };

/* "HH:MM" or "HH:MM:SS" as seconds of the day; 24:00 allowed. */
static int
tkb_clock_of(const char *p, STRLEN len, int32_t *out)
{
    unsigned h, m, s = 0;
    if (!(len == 5 || len == 8) || p[2] != ':' || (len == 8 && p[5] != ':'))
        return 0;
    if (!tkb_two_digits(p, &h) || !tkb_two_digits(p + 3, &m) || (len == 8 && !tkb_two_digits(p + 6, &s)))
        return 0;
    if (h > 24 || m > 59 || s > 59 || (h == 24 && (m || s)))
        return 0;
    *out = (int32_t)(h * 3600 + m * 60 + s);
    return 1;
}

static int
tkb_span_cmp(const void *a, const void *b)
{
    const tkb_span *x = (const tkb_span *)a, *y = (const tkb_span *)b;
    return x->start < y->start ? -1 : x->start > y->start;
}

/* A day's spans from a list of "HH:MM-HH:MM" strings. */
static void
tkb_day_parse(pTHX_ tkb_day *d, SV *list, const char *key, const char *what)
{
    AV *av;
    SSize_t i, n;
    d->spans = NULL;
    d->n = 0;
    d->total = 0;
    if (!list || !SvROK(list) || SvTYPE(SvRV(list)) != SVt_PVAV)
        croak("%s: the hours for %s are a list of 'HH:MM-HH:MM' spans", what, key);
    av = (AV *)SvRV(list);
    n = av_len(av) + 1;
    if (n)
        Newx(d->spans, n, tkb_span);
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(av, i, 0);
        STRLEN len;
        const char *p, *dash;
        int32_t a, b;
        if (!e || !SvOK(*e) || SvROK(*e))
            croak("%s: a span of hours for %s is a string 'HH:MM-HH:MM'", what, key);
        p = SvPV(*e, len);
        dash = (const char *)memchr(p, '-', len);
        if (!dash || !tkb_clock_of(p, (STRLEN)(dash - p), &a) || !tkb_clock_of(dash + 1, len - (STRLEN)(dash - p) - 1, &b))
            croak("%s: '%s' is not a span of hours 'HH:MM-HH:MM' for %s", what, p, key);
        if (a >= b)
            croak("%s: the span '%s' for %s ends before it starts", what, p, key);
        d->spans[i].start = a;
        d->spans[i].end = b;
    }
    d->n = (int)n;
    if (n > 1)
        qsort(d->spans, (size_t)n, sizeof(tkb_span), tkb_span_cmp);
    for (i = 1; i < n; i++)
        if (d->spans[i].start < d->spans[i - 1].end)
            croak("%s: two spans of hours for %s overlap", what, key);
    for (i = 0; i < n; i++)
        d->total += d->spans[i].end - d->spans[i].start;
}

static int
tkb_dated_cmp(const void *a, const void *b)
{
    const tkb_dated *x = (const tkb_dated *)a, *y = (const tkb_dated *)b;
    return x->day < y->day ? -1 : x->day > y->day;
}

/* The hours table from the spec's hours and zone. */
static void
tkb_hours_parse(pTHX_ tkb_schedule *s, HV *spec, const char *what)
{
    tkb_hours *h = &s->hours;
    SV **ph = hv_fetchs(spec, "hours", 0), **pz = hv_fetchs(spec, "zone", 0);
    SV *hours = ph && SvOK(*ph) ? *ph : NULL;
    tkb_day def;
    int has_def = 0, given[7] = { 0, 0, 0, 0, 0, 0, 0 };
    int i;
    Zero(h, 1, tkb_hours);
    h->zone.kind = TIME_KEEPER_ZONE_FLOATING;
    if (pz && SvOK(*pz)) {
        STRLEN len;
        const char *z = SvPV(*pz, len);
        if (SvROK(*pz) || TKB(zone_parse)(aTHX_ z, len, &h->zone) != TIME_KEEPER_OK)
            croak("%s: unknown zone '%s'", what, z);
        if (h->zone.kind == TIME_KEEPER_ZONE_FLOATING)
            croak("%s: a schedule's zone cannot be floating", what);
        h->has_zone = 1;
    }
    if (!hours)
        return;
    if (!h->has_zone)
        croak("%s: business hours need a zone", what);
    def.spans = NULL;
    def.n = 0;
    def.total = 0;
    if (SvROK(hours) && SvTYPE(SvRV(hours)) == SVt_PVAV) {
        tkb_day_parse(aTHX_ &def, hours, "every day", what);
        has_def = 1;
    }
    else if (SvROK(hours) && SvTYPE(SvRV(hours)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(hours);
        HE *he;
        hv_iterinit(hv);
        while ((he = hv_iternext(hv))) {
            SV *key = hv_iterkeysv(he);
            SV *val = hv_iterval(hv, he);
            STRLEN klen;
            const char *k = SvPV(key, klen);
            int dow = 0;
            if (klen == 7 && memEQ(k, "default", 7)) {
                tkb_day_parse(aTHX_ &def, val, "default", what);
                has_def = 1;
                continue;
            }
            if (klen == 1 && k[0] >= '1' && k[0] <= '7')
                dow = k[0] - '0';
            else if (klen == 3) {
                for (i = 0; i < 7; i++)
                    if (ibcmp(k, tkb_dow_keys[i], 3) == 0)
                        dow = i + 1;
            }
            if (dow) {
                tkb_day_parse(aTHX_ &h->week[dow - 1], val, tkb_dow_names[dow - 1], what);
                if (h->week[dow - 1].n == 0)
                    croak("%s: the hours for %s are empty: leave the key out, or make it a weekend day", what, tkb_dow_names[dow - 1]);
                given[dow - 1] = 1;
                continue;
            }
            if (klen == 10 && k[4] == '-' && k[7] == '-') {
                int64_t day = tkb_day_from_sv(aTHX_ key, what);
                Renew(h->dated, h->n_dated + 1, tkb_dated);
                h->dated[h->n_dated].day = day;
                tkb_day_parse(aTHX_ &h->dated[h->n_dated].hours, val, k, what);
                h->n_dated++;
                continue;
            }
            croak("%s: unknown hours key '%s': a weekday 1 to 7 or mon to sun, 'default', or a date", what, k);
        }
    }
    else
        croak("%s: hours are a list of 'HH:MM-HH:MM' spans, or a hash of weekday, 'default' or date keys to such lists", what);
    for (i = 0; i < 7; i++) {
        if (given[i])
            continue;
        if (has_def)
            tkb_day_copy(&h->week[i], &def);
        else if (!(s->weekend & TKB_WEEKEND_BIT(i + 1)))
            croak("%s: the hours for %s are not given and there is no default", what, tkb_dow_names[i]);
    }
    tkb_day_free(&def);
    if (h->n_dated > 1) {
        size_t j;
        qsort(h->dated, h->n_dated, sizeof(tkb_dated), tkb_dated_cmp);
        for (j = 1; j < h->n_dated; j++)
            if (h->dated[j].day == h->dated[j - 1].day)
                croak("%s: the hours for one date are given twice", what);
    }
    for (i = 0; i < 7; i++)
        if (!(s->weekend & TKB_WEEKEND_BIT(i + 1)))
            h->weekly_total += h->week[i].total;
    h->has = 1;
}

static void
tkb_need_hours(pTHX_ const tkb_schedule *s, const char *what)
{
    if (!s->hours.has)
        croak("%s: this schedule has no hours", what);
}

/* A day's spans: none when the day is closed. */
static const tkb_day *
tkb_hours_on(pTHX_ tkb_schedule *s, int64_t day, const char *what)
{
    size_t lo = 0, hi = s->hours.n_dated;
    tkb_ensure(aTHX_ s, day, what);
    if (tkb_is_closed(s, day))
        return &tkb_no_hours;
    while (lo < hi) {
        size_t mid = lo + (hi - lo) / 2;
        if (s->hours.dated[mid].day < day) lo = mid + 1; else hi = mid;
    }
    if (lo < s->hours.n_dated && s->hours.dated[lo].day == day)
        return &s->hours.dated[lo].hours;
    return &s->hours.week[tkb_dow_from_days(day) - 1];
}

/* An instant on the schedule's wall clock: the day, the seconds of it and
 * the nanoseconds. The value must be an instant. */
static void
tkb_split(pTHX_ const tkb_schedule *s, const tkb_val *v, int64_t *day, int32_t *secs, int32_t *nsec, const char *what)
{
    time_keeper_civil c;
    if (v->kind != TKB_KIND_KEEPER)
        croak("%s: a date has no clock", what);
    if (v->zone.kind == TIME_KEEPER_ZONE_FLOATING)
        croak("%s: a floating time has no zone to read business hours in", what);
    if (TKB(civil)(aTHX_ &v->inst, &s->hours.zone, &c) != TIME_KEEPER_OK)
        croak("%s: the value's wall clock could not be read", what);
    *day = tkb_days_from_civil(c.year, (unsigned)c.month, (unsigned)c.day);
    if (c.second == 60) {
        *secs = TKB_SECS_PER_DAY - 1;
        *nsec = 999999999;
    }
    else {
        *secs = c.hour * 3600 + c.minute * 60 + c.second;
        *nsec = c.nanosecond;
    }
}

/* The schedule's wall clock back as a value: in the caller's zone, locale,
 * calendar and class for a Time::Keeper, in the schedule's zone for a
 * date. */
static SV *
tkb_join(pTHX_ const tkb_schedule *s, int64_t day, int32_t secs, int32_t nsec, const tkb_val *caller, const char *what)
{
    time_keeper_civil c;
    time_keeper_instant t;
    int64_t y;
    unsigned m, d;
    SV *out;
    int rc;
    if (secs >= TKB_SECS_PER_DAY) {
        day += secs / TKB_SECS_PER_DAY;
        secs %= TKB_SECS_PER_DAY;
    }
    Zero(&c, 1, time_keeper_civil);
    tkb_civil_from_days(day, &y, &m, &d);
    c.year = y;
    c.month = (int)m;
    c.day = (int)d;
    c.hour = secs / 3600;
    c.minute = (secs / 60) % 60;
    c.second = secs % 60;
    c.nanosecond = nsec;
    rc = TKB(from_civil)(aTHX_ &c, &s->hours.zone, TIME_KEEPER_GAP_FORWARD, TIME_KEEPER_OVERLAP_EARLIER, &t);
    if (rc == TIME_KEEPER_RANGE)
        croak("%s: the result is outside the years Time::Keeper holds", what);
    if (rc != TIME_KEEPER_OK)
        croak("%s: the result could not be made (code %d)", what, rc);
    if (caller->kind == TKB_KIND_KEEPER) {
        out = TKB(new_sv_cal)(aTHX_ &t, &caller->zone, caller->locale, caller->calendar);
        if (!out)
            croak("%s: the result could not be made", what);
        if (SvSTASH(SvRV(caller->sv)) != SvSTASH(SvRV(out)))
            sv_bless(out, SvSTASH(SvRV(caller->sv)));
    }
    else {
        int locale = 0;
        if (caller->locale_sv && SvOK(caller->locale_sv)) {
            STRLEN len;
            const char *code = SvPV(caller->locale_sv, len);
            locale = TKB(locale_find)(code, len);
            if (locale < 0)
                locale = 0;
        }
        out = TKB(new_sv_cal)(aTHX_ &t, &s->hours.zone, locale, 0);
        if (!out)
            croak("%s: the result could not be made", what);
    }
    return out;
}

/* The span a second of the day falls in, or -1. */
static int
tkb_span_at(const tkb_day *d, int32_t secs)
{
    int i;
    for (i = 0; i < d->n; i++)
        if (d->spans[i].start <= secs && secs < d->spans[i].end)
            return i;
    return -1;
}

static void
tkb_no_hours_near(pTHX_ int64_t day, const char *what)
{
    SV *str = sv_2mortal(tkb_day_string(aTHX_ day));
    croak("%s: no business hours within a year of %" SVf, what, SVfARG(str));
}

/* The next day with any hours, strictly after (dir 1) or before (dir -1). */
static int64_t
tkb_next_day_with_hours(pTHX_ tkb_schedule *s, int64_t day, int dir, const tkb_day **out, const char *what)
{
    int i;
    int64_t d = day;
    tkb_ensure_span(aTHX_ s, day, day + dir * TKB_WALK_LIMIT, what);
    for (i = 0; i < TKB_WALK_LIMIT; i++) {
        d += dir;
        *out = tkb_hours_on(aTHX_ s, d, what);
        if ((*out)->n)
            return d;
    }
    tkb_no_hours_near(aTHX_ day, what);
    return 0;
}

/* The first moment at or after (day, secs) that is open: the moment
 * itself when it is. */
static void
tkb_next_open(pTHX_ tkb_schedule *s, int64_t *day, int32_t *secs, int32_t *nsec, const char *what)
{
    const tkb_day *d = tkb_hours_on(aTHX_ s, *day, what);
    int i;
    if (tkb_span_at(d, *secs) >= 0)
        return;
    for (i = 0; i < d->n; i++)
        if (d->spans[i].start > *secs) {
            *secs = d->spans[i].start;
            *nsec = 0;
            return;
        }
    *day = tkb_next_day_with_hours(aTHX_ s, *day, 1, &d, what);
    *secs = d->spans[0].start;
    *nsec = 0;
}

/* The close of the span the moment is in, or of the span the next open
 * begins. */
static void
tkb_next_close(pTHX_ tkb_schedule *s, int64_t *day, int32_t *secs, int32_t *nsec, const char *what)
{
    const tkb_day *d;
    int i;
    tkb_next_open(aTHX_ s, day, secs, nsec, what);
    d = tkb_hours_on(aTHX_ s, *day, what);
    i = tkb_span_at(d, *secs);
    *secs = d->spans[i].end;
    *nsec = 0;
}

/* The last close at or before the moment. */
static void
tkb_previous_close(pTHX_ tkb_schedule *s, int64_t *day, int32_t *secs, int32_t *nsec, const char *what)
{
    const tkb_day *d = tkb_hours_on(aTHX_ s, *day, what);
    int i;
    for (i = d->n - 1; i >= 0; i--)
        if (d->spans[i].end <= *secs) {
            *secs = d->spans[i].end;
            *nsec = 0;
            return;
        }
    *day = tkb_next_day_with_hours(aTHX_ s, *day, -1, &d, what);
    *secs = d->spans[d->n - 1].end;
    *nsec = 0;
}

/* The open of the span the moment is in, else the last open before it. */
static void
tkb_previous_open(pTHX_ tkb_schedule *s, int64_t *day, int32_t *secs, int32_t *nsec, const char *what)
{
    const tkb_day *d = tkb_hours_on(aTHX_ s, *day, what);
    int i;
    for (i = d->n - 1; i >= 0; i--)
        if (d->spans[i].start <= *secs) {
            *secs = d->spans[i].start;
            *nsec = 0;
            return;
        }
    *day = tkb_next_day_with_hours(aTHX_ s, *day, -1, &d, what);
    *secs = d->spans[d->n - 1].start;
    *nsec = 0;
}

#endif
