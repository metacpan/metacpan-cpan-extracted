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

static void tkb_hours_by_rule(pTHX_ tkb_hours *h, SV *list, const char *what);

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
        if (a >= TKB_SECS_PER_DAY)
            croak("%s: the span '%s' for %s starts at 24:00: start it at 00:00 the next day", what, p, key);
        if (a == b)
            croak("%s: the span '%s' for %s is empty", what, p, key);
        if (b < a)
            b += TKB_SECS_PER_DAY;
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
tkb_day_overflow(const tkb_day *d)
{
    int i, end = 0;
    for (i = 0; i < d->n; i++)
        if (d->spans[i].end > TKB_SECS_PER_DAY && d->spans[i].end - TKB_SECS_PER_DAY > end)
            end = d->spans[i].end - TKB_SECS_PER_DAY;
    return end;
}

/* An overnight span of one day must end before the next day's first span
 * begins: the two days' hours may not overlap across midnight. */
static void
tkb_overnight_clash(pTHX_ const tkb_day *prev, const tkb_day *next, const char *prev_name, const char *next_name, const char *what)
{
    int over = tkb_day_overflow(prev);
    if (over && next->n && next->spans[0].start < over)
        croak("%s: the overnight span of %s runs into the hours of %s", what, prev_name, next_name);
}

static const tkb_day *
tkb_table_day(const tkb_hours *h, int64_t day)
{
    size_t lo = 0, hi = h->n_dated;
    while (lo < hi) {
        size_t mid = lo + (hi - lo) / 2;
        if (h->dated[mid].day < day) lo = mid + 1; else hi = mid;
    }
    if (lo < h->n_dated && h->dated[lo].day == day)
        return &h->dated[lo].hours;
    return &h->week[tkb_dow_from_days(day) - 1];
}

static void
tkb_hours_check_overnight(pTHX_ tkb_hours *h, const char *what)
{
    size_t i;
    int w;
    h->has_overnight = 0;
    for (w = 0; w < 7; w++)
        if (tkb_day_overflow(&h->week[w]))
            h->has_overnight = 1;
    for (i = 0; i < h->n_dated; i++)
        if (tkb_day_overflow(&h->dated[i].hours))
            h->has_overnight = 1;
    for (i = 0; i < h->n_rules; i++)
        if (tkb_day_overflow(&h->rule_hours[i]))
            h->has_overnight = 1;
    if (!h->has_overnight)
        return;
    for (w = 0; w < 7; w++)
        tkb_overnight_clash(aTHX_ &h->week[w], &h->week[(w + 1) % 7], tkb_dow_names[w], tkb_dow_names[(w + 1) % 7], what);
    for (i = 0; i < h->n_dated; i++) {
        int64_t d = h->dated[i].day;
        SV *name = sv_2mortal(tkb_day_string(aTHX_ d));
        SV *prev = sv_2mortal(tkb_day_string(aTHX_ d - 1));
        SV *next = sv_2mortal(tkb_day_string(aTHX_ d + 1));
        tkb_overnight_clash(aTHX_ tkb_table_day(h, d - 1), &h->dated[i].hours, SvPV_nolen(prev), SvPV_nolen(name), what);
        tkb_overnight_clash(aTHX_ &h->dated[i].hours, tkb_table_day(h, d + 1), SvPV_nolen(name), SvPV_nolen(next), what);
    }
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
    h->rule_lo = 1;
    h->rule_hi = 0;
    {
        SV **pr = hv_fetchs(spec, "reckon", 0);
        if (pr && SvOK(*pr)) {
            const char *rk = SvPV_nolen(*pr);
            if (strEQ(rk, "elapsed")) h->elapsed = 1;
            else if (!strEQ(rk, "wall"))
                croak("%s: reckon is 'wall' or 'elapsed', not '%s'", what, rk);
        }
    }
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
            if (klen == 7 && memEQ(k, "by_rule", 7)) {
                tkb_hours_by_rule(aTHX_ h, val, what);
                continue;
            }
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
    tkb_hours_check_overnight(aTHX_ h, what);
    h->has = 1;
}

/* by_rule: a list of [rule, spans] pairs, a rule or a rule's data. */
static void
tkb_hours_by_rule(pTHX_ tkb_hours *h, SV *list, const char *what)
{
    AV *av;
    SSize_t i, n;
    SV *cls = sv_2mortal(newSVpvs("Time::Keeper::Business::Rule"));
    if (!list || !SvROK(list) || SvTYPE(SvRV(list)) != SVt_PVAV || sv_isobject(list))
        croak("%s: by_rule is a list of [rule, spans] pairs", what);
    av = (AV *)SvRV(list);
    n = av_len(av) + 1;
    Newxz(h->rule_svs, n ? n : 1, SV *);
    Newxz(h->rule_hours, n ? n : 1, tkb_day);
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(av, i, 0);
        AV *pair;
        SV **rule, **spans, *r;
        if (!e || !SvROK(*e) || SvTYPE(SvRV(*e)) != SVt_PVAV || av_len((AV *)SvRV(*e)) != 1)
            croak("%s: by_rule is a list of [rule, spans] pairs", what);
        pair = (AV *)SvRV(*e);
        rule = av_fetch(pair, 0, 0);
        spans = av_fetch(pair, 1, 0);
        if (rule && tkb_rule_magic(aTHX_ *rule))
            r = *rule;
        else if (rule && SvROK(*rule) && SvTYPE(SvRV(*rule)) == SVt_PVHV && !sv_isobject(*rule))
            r = tkb_rule_from_spec(aTHX_ cls, *rule, what, 0);
        else
            croak("%s: by_rule's first of a pair is a rule, or a rule as data", what);
        h->rule_svs[i] = newSVsv(r);
        h->n_rules = (size_t)i + 1;
        tkb_day_parse(aTHX_ &h->rule_hours[i], spans ? *spans : NULL, "a rule's days", what);
    }
}

/* The days the rules give, for the year of a day, materialised a year at a
 * time and kept sorted; a day two rules give takes the first listed. */
static void
tkb_rule_hours_year(pTHX_ tkb_hours *h, int64_t year)
{
    size_t r;
    for (r = 0; r < h->n_rules; r++) {
        const tkb_rule_year *ry = tkb_rule_holidays_of(aTHX_ tkb_rule_of(aTHX_ h->rule_svs[r], "by_rule"), year);
        size_t k;
        for (k = 0; k < ry->n; k++) {
            int64_t d = ry->days[k];
            size_t at = tkb_lower_bound(h->rule_days, h->n_rule_days, d);
            if (at < h->n_rule_days && h->rule_days[at] == d)
                continue;
            Renew(h->rule_days, h->n_rule_days + 1, int64_t);
            Renew(h->rule_idx, h->n_rule_days + 1, int);
            Move(h->rule_days + at, h->rule_days + at + 1, h->n_rule_days - at, int64_t);
            Move(h->rule_idx + at, h->rule_idx + at + 1, h->n_rule_days - at, int);
            h->rule_days[at] = d;
            h->rule_idx[at] = (int)r;
            h->n_rule_days++;
            if (h->has_overnight) {
                SV *name = sv_2mortal(tkb_day_string(aTHX_ d));
                tkb_overnight_clash(aTHX_ tkb_table_day(h, d - 1), &h->rule_hours[r], "the day before", SvPV_nolen(name), "Time::Keeper::Business by_rule");
                tkb_overnight_clash(aTHX_ &h->rule_hours[r], tkb_table_day(h, d + 1), SvPV_nolen(name), "the day after", "Time::Keeper::Business by_rule");
            }
        }
    }
}

static void
tkb_rule_hours_ensure(pTHX_ tkb_hours *h, int64_t day, const char *what)
{
    int64_t y, lo, hi;
    unsigned m, d;
    if (!h->n_rules)
        return;
    tkb_civil_from_days(day, &y, &m, &d);
    if (h->rule_lo <= h->rule_hi && y >= h->rule_lo && y <= h->rule_hi)
        return;
    lo = h->rule_lo > h->rule_hi ? y : (y < h->rule_lo ? y : h->rule_lo);
    hi = h->rule_lo > h->rule_hi ? y : (y > h->rule_hi ? y : h->rule_hi);
    if (hi - lo + 1 > 1000)
        croak("%s: the rules for hours were asked for %" IVdf " years; list the dates instead", what, (IV)(hi - lo + 1));
    {
        int64_t k;
        for (k = lo; k <= hi; k++)
            if (h->rule_lo > h->rule_hi || k < h->rule_lo || k > h->rule_hi)
                tkb_rule_hours_year(aTHX_ h, k);
    }
    h->rule_lo = lo;
    h->rule_hi = hi;
}

/* An instant from a wall clock in a zone: the day and the seconds of it,
 * a time the clocks skipped carried forward, a repeated one the earlier. */
static int64_t
tkb_wall_instant(pTHX_ const time_keeper_zone *zone, int64_t day, int32_t secs, const char *what)
{
    time_keeper_civil c;
    time_keeper_instant t;
    int64_t y;
    unsigned m, d;
    if (secs >= TKB_SECS_PER_DAY) { day += secs / TKB_SECS_PER_DAY; secs %= TKB_SECS_PER_DAY; }
    Zero(&c, 1, time_keeper_civil);
    tkb_civil_from_days(day, &y, &m, &d);
    c.year = y; c.month = (int)m; c.day = (int)d;
    c.hour = secs / 3600; c.minute = (secs / 60) % 60; c.second = secs % 60;
    if (TKB(from_civil)(aTHX_ &c, zone, TIME_KEEPER_GAP_FORWARD, TIME_KEEPER_OVERLAP_EARLIER, &t) != TIME_KEEPER_OK)
        croak("%s: a time could not be made in a joined schedule's zone", what);
    return t.sec;
}

static const tkb_day *tkb_hours_on(pTHX_ tkb_schedule *s, int64_t day, const char *what);

/* A part's spans that fall in [t0, t1), as instants, appended to a buffer
 * of int64 pairs. */
static void
tkb_part_intervals(pTHX_ tkb_schedule *p, int64_t t0, int64_t t1, SV *out, const char *what)
{
    time_keeper_instant a, b;
    time_keeper_civil c;
    int64_t d0, d1, d;
    a.sec = t0; a.nsec = 0;
    b.sec = t1 - 1; b.nsec = 0;
    if (TKB(civil)(aTHX_ &a, &p->hours.zone, &c) != TIME_KEEPER_OK)
        croak("%s: a joined schedule's day could not be read", what);
    d0 = tkb_days_from_civil(c.year, (unsigned)c.month, (unsigned)c.day);
    if (TKB(civil)(aTHX_ &b, &p->hours.zone, &c) != TIME_KEEPER_OK)
        croak("%s: a joined schedule's day could not be read", what);
    d1 = tkb_days_from_civil(c.year, (unsigned)c.month, (unsigned)c.day);
    for (d = d0 - 1; d <= d1; d++) {
        const tkb_day *h = tkb_hours_on(aTHX_ p, d, what);
        int i;
        for (i = 0; i < h->n; i++) {
            int64_t x = tkb_wall_instant(aTHX_ &p->hours.zone, d, h->spans[i].start, what);
            int64_t y = tkb_wall_instant(aTHX_ &p->hours.zone, d, h->spans[i].end, what);
            if (x < t0) x = t0;
            if (y > t1) y = t1;
            if (y > x) {
                sv_catpvn(out, (const char *)&x, sizeof x);
                sv_catpvn(out, (const char *)&y, sizeof y);
            }
        }
    }
}

/* A joined schedule's spans on one of its days, on the first part's clock:
 * both parts' spans as instants, intersected, united, or one side's. */
static void
tkb_join_day(pTHX_ tkb_schedule *s, int64_t day, tkb_day *out, const char *what)
{
    tkb_schedule *a = tkb_schedule_of(aTHX_ s->join_a, what), *b = tkb_schedule_of(aTHX_ s->join_b, what);
    int64_t t0 = tkb_wall_instant(aTHX_ &s->hours.zone, day, 0, what);
    int64_t t1 = tkb_wall_instant(aTHX_ &s->hours.zone, day + 1, 0, what);
    SV *ia = sv_2mortal(newSVpvs("")), *ib = sv_2mortal(newSVpvs("")), *res = sv_2mortal(newSVpvs(""));
    const int64_t *pa, *pb;
    size_t na, nb, i = 0, j = 0, n, k;
    if (s->join_hours != 4)
        tkb_part_intervals(aTHX_ a, t0, t1, ia, what);
    if (s->join_hours != 3)
        tkb_part_intervals(aTHX_ b, t0, t1, ib, what);
    pa = (const int64_t *)SvPVX(ia); na = SvCUR(ia) / (2 * sizeof(int64_t));
    pb = (const int64_t *)SvPVX(ib); nb = SvCUR(ib) / (2 * sizeof(int64_t));
    if (s->join_hours == 1) {
        while (i < na && j < nb) {
            int64_t lo = pa[2 * i] > pb[2 * j] ? pa[2 * i] : pb[2 * j];
            int64_t hi = pa[2 * i + 1] < pb[2 * j + 1] ? pa[2 * i + 1] : pb[2 * j + 1];
            if (hi > lo) { sv_catpvn(res, (const char *)&lo, sizeof lo); sv_catpvn(res, (const char *)&hi, sizeof hi); }
            if (pa[2 * i + 1] < pb[2 * j + 1]) i++; else j++;
        }
    }
    else {
        int64_t cur_lo = 0, cur_hi = 0;
        int open = 0;
        while (i < na || j < nb) {
            const int64_t *next;
            if (j >= nb || (i < na && pa[2 * i] <= pb[2 * j])) next = pa + 2 * i++; else next = pb + 2 * j++;
            if (open && next[0] <= cur_hi) { if (next[1] > cur_hi) cur_hi = next[1]; continue; }
            if (open) { sv_catpvn(res, (const char *)&cur_lo, sizeof cur_lo); sv_catpvn(res, (const char *)&cur_hi, sizeof cur_hi); }
            cur_lo = next[0]; cur_hi = next[1]; open = 1;
        }
        if (open) { sv_catpvn(res, (const char *)&cur_lo, sizeof cur_lo); sv_catpvn(res, (const char *)&cur_hi, sizeof cur_hi); }
    }
    n = SvCUR(res) / (2 * sizeof(int64_t));
    out->spans = NULL;
    out->n = 0;
    out->total = 0;
    if (n)
        Newx(out->spans, n, tkb_span);
    for (k = 0; k < n; k++) {
        const int64_t *iv = (const int64_t *)SvPVX(res) + 2 * k;
        int32_t sec[2];
        int e;
        for (e = 0; e < 2; e++) {
            time_keeper_instant t;
            time_keeper_civil c;
            if (iv[e] >= t1) { sec[e] = TKB_SECS_PER_DAY; continue; }
            t.sec = iv[e]; t.nsec = 0;
            if (TKB(civil)(aTHX_ &t, &s->hours.zone, &c) != TIME_KEEPER_OK)
                croak("%s: a joined schedule's time could not be read", what);
            sec[e] = c.hour * 3600 + c.minute * 60 + (c.second > 59 ? 59 : c.second);
        }
        if (sec[1] <= sec[0])
            continue;
        out->spans[out->n].start = sec[0];
        out->spans[out->n].end = sec[1];
        out->total += sec[1] - sec[0];
        out->n++;
    }
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
    if (s->join_hours) {
        tkb_jslot *slot;
        if (!s->jcache)
            Newxz(s->jcache, TKB_JCACHE, tkb_jslot);
        slot = &s->jcache[tkb_floor_mod(day, TKB_JCACHE)];
        if (slot->valid && slot->day == day)
            return &slot->hours;
        if (slot->valid)
            tkb_day_free(&slot->hours);
        slot->valid = 0;
        tkb_join_day(aTHX_ s, day, &slot->hours, what);
        slot->day = day;
        slot->valid = 1;
        return &slot->hours;
    }
    if (s->hours.n_rules) {
        size_t at;
        tkb_rule_hours_ensure(aTHX_ &s->hours, day, what);
        at = tkb_lower_bound(s->hours.rule_days, s->hours.n_rule_days, day);
        if (at < s->hours.n_rule_days && s->hours.rule_days[at] == day)
            return &s->hours.rule_hours[s->hours.rule_idx[at]];
    }
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
        out = TKB(new_sv_cal)(aTHX_ &t, &s->hours.zone, tkb_val_locale_id(aTHX_ caller), 0);
        if (!out)
            croak("%s: the result could not be made", what);
    }
    return out;
}

/* A moment in the small hours that falls in the previous day's overnight
 * span belongs to that day: (day, secs) becomes (day - 1, secs + 86400), so
 * the arithmetic reads the span whole on the day it starts. */
static void
tkb_canon(pTHX_ tkb_schedule *s, int64_t *day, int32_t *secs, const char *what)
{
    const tkb_day *p;
    int i;
    if (!s->hours.has_overnight || *secs >= TKB_SECS_PER_DAY)
        return;
    p = tkb_hours_on(aTHX_ s, *day - 1, what);
    for (i = 0; i < p->n; i++)
        if (p->spans[i].end > TKB_SECS_PER_DAY && *secs + TKB_SECS_PER_DAY < p->spans[i].end) {
            *day -= 1;
            *secs += TKB_SECS_PER_DAY;
            return;
        }
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
