#ifndef TKR_CRON_H
#define TKR_CRON_H

/* Cron expressions in Punk::Queue's grammar, read into a tkr_rule and
 * written back. Five fields, minute hour day-of-month month day-of-week:
 * `*`, ranges a-b, steps `*`/n and a-b/n (a/n is a-hi/n), lists a,b,c,
 * case-insensitive three-letter month and day names, day-of-week 0 to 7
 * with 0 and 7 both Sunday, the aliases @yearly @annually @monthly @weekly
 * @daily @midnight @hourly, and `@every <n>(s|m|h|d)`, an interval from the
 * last occurrence rather than a wall-clock grid. L, W, # and ?, and a sixth
 * or seventh field, are refused by name rather than misread.
 *
 * The rule it makes is FREQ=MINUTELY with the restricted fields as BY parts
 * (a field matching everything is left unset), TKR_F_CRON, and TKR_F_VIXIE
 * when BOTH day fields are restricted: then a day matching EITHER fires,
 * the cron reading, where an RRULE's two day parts must both match. The
 * error texts are Punk::Queue's, so the two engines say the same thing. */

static const char *const tkr_cron_months[12] = { "jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec" };
static const char *const tkr_cron_days[7] = { "sun", "mon", "tue", "wed", "thu", "fri", "sat" };

#define TKR_CRON_ALL(lo, hi) ((((UINT64_C(1) << ((hi) - (lo) + 1)) - 1)) << (lo))

static int
tkr_cron_atom(const char **pp, const char *end, const char *const *names, int nnames, int base, const char **errp)
{
    const char *p = *pp;
    if (p < end && isALPHA(*p)) {
        char buf[4];
        int i;
        if (end - p < 3) { *errp = p; return -1; }
        for (i = 0; i < 3; i++)
            buf[i] = (char)toLOWER(p[i]);
        buf[3] = 0;
        for (i = 0; i < nnames; i++)
            if (strEQ(buf, names[i])) { *pp = p + 3; return i + base; }
        *errp = p;
        return -1;
    }
    if (p < end && isDIGIT(*p)) {
        int v = 0;
        while (p < end && isDIGIT(*p) && v < 100000)
            v = v * 10 + (*p++ - '0');
        *pp = p;
        return v;
    }
    *errp = p;
    return -1;
}

static int
tkr_cron_field(const char *s, const char *end, int lo, int hi, const char *const *names, int nnames, uint64_t *mask, const char **errp)
{
    uint64_t out = 0;
    const char *p = s;
    while (p < end) {
        int a, b, step = 1, v;
        if (*p == '*') {
            p++;
            a = lo;
            b = hi;
        }
        else {
            a = tkr_cron_atom(&p, end, names, nnames, lo, errp);
            if (a < 0) return -1;
            if (p < end && *p == '-') {
                p++;
                b = tkr_cron_atom(&p, end, names, nnames, lo, errp);
                if (b < 0) return -1;
            }
            else
                b = a;
        }
        if (p < end && *p == '/') {
            p++;
            step = tkr_cron_atom(&p, end, NULL, 0, 0, errp);
            if (step <= 0) { *errp = s; return -1; }
            if (b == a) b = hi;   /* a/n means a-hi/n */
        }
        if (a < lo || a > hi || b > hi) { *errp = s; return -1; }
        if (a <= b)
            for (v = a; v <= b; v += step) out |= UINT64_C(1) << v;
        else {
            for (v = a; v <= hi; v += step) out |= UINT64_C(1) << v;   /* a wrapped range (fri-mon): both arcs */
            for (v = lo; v <= b; v += step) out |= UINT64_C(1) << v;
        }
        if (p < end && *p == ',') { p++; continue; }
        break;
    }
    if (p != end) { *errp = p; return -1; }
    *mask = out;
    return 0;
}

/* 1, or 0 with err: the message after "Time::Keeper::Recurrence->cron: ". */
static int
tkr_cron_parse(const char *expr, size_t len, tkr_rule *r, char *err)
{
    const char *p = expr, *end = expr + len, *fs[5], *fe[5], *q, *at = NULL;
    uint64_t minute, hour, dom, mon, dow;
    int i;
    while (p < end && isSPACE(*p)) p++;
    while (end > p && isSPACE(end[-1])) end--;
    if (p >= end) {
        tkr_err(err, "empty cron expression");
        return 0;
    }
    for (q = p; q < end; q++)
        if (*q == 'L' || *q == 'W' || *q == '#' || *q == '?') {
            tkr_err(err, "cron token '%c' is not supported (L, W, # and ? are excluded in this release)", *q);
            return 0;
        }
    r->freq = TKR_MINUTELY;
    r->interval = 1;
    r->flags |= TKR_F_CRON;
    if (*p == '@') {
        static const struct { const char *name; const char *expr; } aliases[] = {
            { "@yearly", "0 0 1 1 *" }, { "@annually", "0 0 1 1 *" }, { "@monthly", "0 0 1 * *" }, { "@weekly", "0 0 * * 0" },
            { "@daily", "0 0 * * *" }, { "@midnight", "0 0 * * *" }, { "@hourly", "0 * * * *" },
        };
        size_t n = (size_t)(end - p);
        unsigned k;
        for (k = 0; k < sizeof aliases / sizeof *aliases; k++)
            if (n == strlen(aliases[k].name) && memEQ(p, aliases[k].name, n))
                return tkr_cron_parse(aliases[k].expr, strlen(aliases[k].expr), r, err);
        if (n > 7 && memEQ(p, "@every ", 7)) {
            IV v = 0;
            q = p + 7;
            while (q < end && isDIGIT(*q) && v < 100000000)
                v = v * 10 + (*q++ - '0');
            if (v > 0 && q + 1 == end) {
                IV mult = *q == 's' ? 1 : *q == 'm' ? 60 : *q == 'h' ? 3600 : *q == 'd' ? 86400 : 0;
                if (mult) {
                    r->flags |= TKR_F_EVERY;
                    r->every_sec = v * mult;
                    return 1;
                }
            }
            tkr_err(err, "@every wants '<n>(s|m|h|d)', not '%.*s'", (int)(end - p), p);
            return 0;
        }
        tkr_err(err, "unknown cron alias '%.*s'", (int)(end - p), p);
        return 0;
    }
    for (i = 0; i < 5; i++) {
        while (p < end && isSPACE(*p)) p++;
        if (p >= end) {
            tkr_err(err, "cron expression has %d field(s), needs 5 (minute hour day-of-month month day-of-week)", i);
            return 0;
        }
        fs[i] = p;
        while (p < end && !isSPACE(*p)) p++;
        fe[i] = p;
    }
    while (p < end && isSPACE(*p)) p++;
    if (p < end) {
        tkr_err(err, "cron expression has more than 5 fields - second and year fields are not supported");
        return 0;
    }
    if (tkr_cron_field(fs[0], fe[0], 0, 59, NULL, 0, &minute, &at)) { tkr_err(err, "bad cron minute field near '%.8s'", at); return 0; }
    if (tkr_cron_field(fs[1], fe[1], 0, 23, NULL, 0, &hour, &at)) { tkr_err(err, "bad cron hour field near '%.8s'", at); return 0; }
    if (tkr_cron_field(fs[2], fe[2], 1, 31, NULL, 0, &dom, &at)) { tkr_err(err, "bad cron day-of-month field near '%.8s'", at); return 0; }
    if (tkr_cron_field(fs[3], fe[3], 1, 12, tkr_cron_months, 12, &mon, &at)) { tkr_err(err, "bad cron month field near '%.8s'", at); return 0; }
    if (tkr_cron_field(fs[4], fe[4], 0, 7, tkr_cron_days, 7, &dow, &at)) { tkr_err(err, "bad cron day-of-week field near '%.8s'", at); return 0; }
    /* dow 7 is Sunday in half the world's crontabs: fold bit 7 into bit 0
     * AFTER the mask is built; folding per atom turned `*` into Sunday only */
    dow |= (dow >> 7) & 1;
    dow &= TKR_CRON_ALL(0, 6);
    minute &= TKR_CRON_ALL(0, 59);
    hour &= TKR_CRON_ALL(0, 23);
    dom &= TKR_CRON_ALL(1, 31);
    mon &= TKR_CRON_ALL(1, 12);
    if (!minute || !hour || !dom || !mon || !dow) {
        tkr_err(err, "a cron field matches nothing");
        return 0;
    }
    /* a field matching everything is no restriction, and is left unset */
    if (minute != TKR_CRON_ALL(0, 59)) r->by_minute = minute;
    if (hour != TKR_CRON_ALL(0, 23)) r->by_hour = (uint32_t)hour;
    if (dom != TKR_CRON_ALL(1, 31)) r->by_monthday = dom;
    if (mon != TKR_CRON_ALL(1, 12)) r->by_month = (uint16_t)mon;
    if (dow != TKR_CRON_ALL(0, 6)) {
        for (i = 0; i < 7; i++)                    /* cron 0 Sunday .. 6 Saturday to 0 Monday .. 6 Sunday */
            if (dow & (UINT64_C(1) << i))
                r->by_day_any |= (uint8_t)(1u << (i == 0 ? 6 : i - 1));
    }
    if (r->by_monthday && r->by_day_any)
        r->flags |= TKR_F_VIXIE;
    return 1;
}

/* ---- writing ------------------------------------------------------------- */

/* A mask as a cron field: * when it is everything, else runs a-b and lone
 * values, comma separated, ascending. */
static void
tkr_cron_field_write(pTHX_ SV *out, uint64_t mask, int lo, int hi)
{
    int v, first = 1;
    if (!mask || mask == TKR_CRON_ALL(lo, hi)) {
        sv_catpvs(out, "*");
        return;
    }
    for (v = lo; v <= hi; v++) {
        int e;
        if (!(mask & (UINT64_C(1) << v)))
            continue;
        e = v;
        while (e + 1 <= hi && (mask & (UINT64_C(1) << (e + 1))))
            e++;
        if (e > v + 1) sv_catpvf(out, first ? "%d-%d" : ",%d-%d", v, e);
        else if (e == v + 1) sv_catpvf(out, first ? "%d,%d" : ",%d,%d", v, e);
        else sv_catpvf(out, first ? "%d" : ",%d", v);
        first = 0;
        v = e;
    }
}

/* 1 with the expression in out, or 0 with err saying why the rule has no
 * cron spelling. A rule is a cron when it steps minutes (or days with its
 * hour and minute given, or hours with its minute given), has no seconds,
 * ordinals, year days, week numbers, set positions, UNTIL or COUNT, and
 * either one restricted day field or the cron reading of both. */
static int
tkr_cron_write(pTHX_ const tkr_rule *r, SV *out, char *err)
{
    uint64_t dow = 0;
    int i;
    if (r->flags & TKR_F_RSCALE) {
        tkr_err(err, "a rule in a calendar (RSCALE) has no cron spelling");
        return 0;
    }
    if (r->flags & TKR_F_EVERY) {
        int64_t s = r->every_sec;
        if (s % 86400 == 0) sv_setpvf(out, "@every %" IVdf "d", (IV)(s / 86400));
        else if (s % 3600 == 0) sv_setpvf(out, "@every %" IVdf "h", (IV)(s / 3600));
        else if (s % 60 == 0) sv_setpvf(out, "@every %" IVdf "m", (IV)(s / 60));
        else sv_setpvf(out, "@every %" IVdf "s", (IV)s);
        return 1;
    }
    if (r->freq == TKR_DAILY && !(r->by_hour && r->by_minute)) { tkr_err(err, "a daily rule is a cron only with BYHOUR and BYMINUTE given"); return 0; }
    if (r->freq == TKR_HOURLY && !r->by_minute) { tkr_err(err, "an hourly rule is a cron only with BYMINUTE given"); return 0; }
    if (r->freq != TKR_MINUTELY && r->freq != TKR_HOURLY && r->freq != TKR_DAILY) { tkr_err(err, "a cron steps minutes, hours or days, not %s", tkr_freq_lower[r->freq]); return 0; }
    if (r->interval != 1) { tkr_err(err, "a cron has no INTERVAL"); return 0; }
    if (r->by_second) { tkr_err(err, "a cron has no seconds"); return 0; }
    if (tkr_has_by_day_ordinal(r)) { tkr_err(err, "a cron has no ordinal weekdays (the nth Friday)"); return 0; }
    if (r->n_yearday || r->n_weekno || r->n_setpos) { tkr_err(err, "a cron has no BYYEARDAY, BYWEEKNO or BYSETPOS"); return 0; }
    if (r->count || r->until_kind != TKR_UNTIL_NONE) { tkr_err(err, "a cron has no end: no COUNT or UNTIL"); return 0; }
    if (r->by_monthday & ~TKR_CRON_ALL(1, 31)) { tkr_err(err, "a cron has no days counted from the end of the month"); return 0; }
    if (r->by_monthday && r->by_day_any && !(r->flags & TKR_F_VIXIE)) {
        tkr_err(err, "this rule has no cron spelling: cron reads both day fields as either, not both");
        return 0;
    }
    sv_setpvs(out, "");
    tkr_cron_field_write(aTHX_ out, r->by_minute, 0, 59);
    sv_catpvs(out, " ");
    tkr_cron_field_write(aTHX_ out, r->by_hour, 0, 23);
    sv_catpvs(out, " ");
    tkr_cron_field_write(aTHX_ out, r->by_monthday, 1, 31);
    sv_catpvs(out, " ");
    tkr_cron_field_write(aTHX_ out, r->by_month, 1, 12);
    sv_catpvs(out, " ");
    for (i = 0; i < 7; i++)                        /* 0 Monday .. 6 Sunday back to cron's 0 Sunday .. 6 Saturday */
        if (r->by_day_any & (1u << i))
            dow |= UINT64_C(1) << (i == 6 ? 0 : i + 1);
    tkr_cron_field_write(aTHX_ out, dow, 0, 6);
    return 1;
}

#endif
