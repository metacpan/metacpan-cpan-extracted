#ifndef TKR_OBJ_H
#define TKR_OBJ_H

/* A rule object: a blessed reference to a scalar holding one tkr_rule, as a
 * Time::Keeper value holds its struct. Never read-only (a serialiser that
 * re-blesses before FREEZE cannot bless a read-only referent), never
 * changed after it is made: every method that would change one returns a
 * new one. */

static SV *
tkr_rule_new_sv(pTHX_ HV *stash, const tkr_rule *r)
{
    SV *body = newSVpvn((const char *)r, sizeof *r);
    SV *rv = newRV_noinc(body);
    sv_bless(rv, stash);
    return rv;
}

static tkr_rule *
tkr_rule_of(pTHX_ SV *sv, const char *what)
{
    if (!sv || !SvROK(sv) || !sv_derived_from(sv, "Time::Keeper::Recurrence") || !SvPOK(SvRV(sv))
        || SvCUR(SvRV(sv)) != sizeof(tkr_rule))
        croak("%s: not a Time::Keeper::Recurrence", what);
    return (tkr_rule *)SvPVX(SvRV(sv));
}

/* ---- the arguments the doors take ---------------------------------------- */

typedef struct tkr_opts {
    SV *rrule, *start, *zone, *gap, *overlap, *on, *at, *until, *count, *calendar;
} tkr_opts;

static void
tkr_opts_parse(pTHX_ SV **st, I32 n, tkr_opts *o, const char *allowed, const char *what)
{
    I32 i;
    memset(o, 0, sizeof *o);
    if (n % 2)
        croak("%s: the arguments are key and value pairs", what);
    for (i = 0; i < n; i += 2) {
        STRLEN len;
        const char *k = SvPV(st[i], len);
        SV **slot = NULL;
        char tag;
        if (strEQ(k, "rrule")) { slot = &o->rrule; tag = 'r'; }
        else if (strEQ(k, "start")) { slot = &o->start; tag = 's'; }
        else if (strEQ(k, "zone")) { slot = &o->zone; tag = 'z'; }
        else if (strEQ(k, "gap")) { slot = &o->gap; tag = 'g'; }
        else if (strEQ(k, "overlap")) { slot = &o->overlap; tag = 'o'; }
        else if (strEQ(k, "on")) { slot = &o->on; tag = 'n'; }
        else if (strEQ(k, "at")) { slot = &o->at; tag = 'a'; }
        else if (strEQ(k, "until")) { slot = &o->until; tag = 'u'; }
        else if (strEQ(k, "count")) { slot = &o->count; tag = 'c'; }
        else if (strEQ(k, "calendar")) { slot = &o->calendar; tag = 'C'; }
        else croak("%s: unknown argument '%s'", what, k);
        if (!strchr(allowed, tag))
            croak("%s: '%s' is not an argument here", what, k);
        if (*slot)
            croak("%s: '%s' is given twice", what, k);
        *slot = st[i + 1];
    }
}

/* The start: a Time::Keeper value's instant, zone and locale. */
static void
tkr_start_from_sv(pTHX_ SV *sv, tkr_rule *r, const char *what)
{
    const time_keeper_abi *T = tkr_tk(aTHX);
    if ((T->from_sv)(aTHX_ sv, &r->start, &r->zone, &r->locale) != TIME_KEEPER_OK)
        croak("%s: start is not a Time::Keeper value", what);
    r->flags |= TKR_F_HAS_START;
}

static void
tkr_zone_from_sv(pTHX_ SV *sv, tkr_rule *r, const char *what)
{
    const time_keeper_abi *T = tkr_tk(aTHX);
    STRLEN len;
    const char *s = SvPV(sv, len);
    if ((T->zone_parse)(aTHX_ s, len, &r->zone) != TIME_KEEPER_OK)
        croak("%s: '%s' is not a time zone", what, s);
}

static void
tkr_gap_overlap(pTHX_ const tkr_opts *o, tkr_rule *r, const char *what)
{
    int i;
    if (o->gap) {
        const char *s = SvPV_nolen(o->gap);
        for (i = 0; i < 4; i++)
            if (strEQ(s, tkr_gap_names[i]))
                break;
        if (i == 4)
            croak("%s: gap is forward, backward, skip or fail, not '%s'", what, s);
        r->gap = (uint8_t)i;
    }
    if (o->overlap) {
        const char *s = SvPV_nolen(o->overlap);
        for (i = 0; i < 3; i++)
            if (strEQ(s, tkr_overlap_names[i]))
                break;
        if (i == 3)
            croak("%s: overlap is earlier, later or both, not '%s'", what, s);
        r->overlap = (uint8_t)i;
    }
}

/* UNTIL's form against the start's: a zoned start takes UNTIL in UTC, a
 * floating start a floating UNTIL; a DATE suits either. */
static void
tkr_check_until_form(pTHX_ const tkr_rule *r, const char *what)
{
    if (r->until_kind == TKR_UNTIL_FLOATING && r->zone.kind != TIME_KEEPER_ZONE_FLOATING)
        croak("%s: UNTIL must be in UTC (end in Z) when the start has a zone", what);
    if (r->until_kind == TKR_UNTIL_UTC && r->zone.kind == TIME_KEEPER_ZONE_FLOATING)
        croak("%s: UNTIL must be floating (no Z) when the start is", what);
}

/* calendar => a Time::Keeper calendar id: the rule walks in it (RSCALE). */
static void
tkr_calendar_opt(pTHX_ SV *sv, tkr_rule *r, const char *what)
{
    STRLEN len;
    const char *s = SvPV(sv, len);
    int c = (tkr_tk(aTHX)->calendar_find)(s, len);
    if (c < 0 || c > 255)
        croak("%s: calendar => '%s' names no calendar Time::Keeper knows", what, s);
    if (r->n_weekno)
        croak("%s: BYWEEKNO cannot be given with a calendar: no calendar here numbers weeks but the Gregorian", what);
    r->calendar = (uint8_t)c;
    r->flags |= TKR_F_RSCALE;
}

/* The named door: n units, on, at. */
static void
tkr_every_build(pTHX_ IV n, const char *unit, const tkr_opts *o, tkr_rule *r, const char *what)
{
    static const struct { const char *name; int freq; } units[] = {
        { "seconds", TKR_SECONDLY }, { "second", TKR_SECONDLY }, { "minutes", TKR_MINUTELY }, { "minute", TKR_MINUTELY },
        { "hours", TKR_HOURLY }, { "hour", TKR_HOURLY }, { "days", TKR_DAILY }, { "day", TKR_DAILY },
        { "weeks", TKR_WEEKLY }, { "week", TKR_WEEKLY }, { "months", TKR_MONTHLY }, { "month", TKR_MONTHLY },
        { "years", TKR_YEARLY }, { "year", TKR_YEARLY },
    };
    unsigned k;
    for (k = 0; k < sizeof units / sizeof *units; k++)
        if (strEQ(unit, units[k].name))
            break;
    if (k == sizeof units / sizeof *units)
        croak("%s: the unit is seconds, minutes, hours, days, weeks, months or years, not '%s'", what, unit);
    if (n < 1 || n > 0x7fffffff)
        croak("%s: every how many? %" IVdf " is not a count above zero", what, n);
    r->freq = (uint8_t)units[k].freq;
    r->interval = (uint32_t)n;
    if (o->on) {
        AV *list = NULL;
        I32 i, top;
        if (SvROK(o->on) && SvTYPE(SvRV(o->on)) == SVt_PVAV)
            list = (AV *)SvRV(o->on);
        top = list ? av_len(list) : 0;
        for (i = 0; i <= top; i++) {
            SV **e = list ? av_fetch(list, i, 0) : NULL;
            SV *item = list ? (e ? *e : &PL_sv_undef) : o->on;
            STRLEN len;
            const char *s = SvPV(item, len), *p = s, *end = s + len;
            int ord = 0, oneg = 0, w = -1, num;
            long v;
            if (looks_like_number(item)) {
                v = SvIV(item);
                if (v == 0 || v > 31 || v < -31)
                    croak("%s: on => %ld is not a day of the month, 1 to 31 or -1 to -31", what, v);
                if (r->freq != TKR_MONTHLY && r->freq != TKR_YEARLY)
                    croak("%s: on => a day of the month needs months or years", what);
                r->by_monthday |= UINT64_C(1) << (v < 0 ? 32 - v : v);
                continue;
            }
            while (p < end && isSPACE(*p)) p++;
            if (end - p >= 4 && tkr_ieq(p, "last", 4)) { ord = 1; oneg = 1; p += 4; }
            else if (p < end && isDIGIT(*p)) {
                while (p < end && isDIGIT(*p)) ord = ord * 10 + (*p++ - '0');
                if (end - p >= 2 && (tkr_ieq(p, "st", 2) || tkr_ieq(p, "nd", 2) || tkr_ieq(p, "rd", 2) || tkr_ieq(p, "th", 2)))
                    p += 2;
            }
            else if (p < end && *p == '-') {
                p++;
                while (p < end && isDIGIT(*p)) ord = ord * 10 + (*p++ - '0');
                oneg = 1;
            }
            while (p < end && isSPACE(*p)) p++;
            if (end - p >= 3) {
                for (num = 0; num < 7; num++)
                    if (tkr_ieq(p, tkr_cron_days[num], 3)) { w = num == 0 ? 6 : num - 1; break; }
            }
            if (w < 0 || (ord && (ord < 1 || ord > 53)) || (ord && r->freq != TKR_MONTHLY && r->freq != TKR_YEARLY))
                croak("%s: on => '%s' is not a weekday, with 1st to 5th or last before it for months or years", what, s);
            if (!ord) r->by_day_any |= (uint8_t)(1u << w);
            else if (oneg) r->by_day_neg[w] |= UINT64_C(1) << ord;
            else r->by_day_pos[w] |= UINT64_C(1) << ord;
        }
    }
    if (o->at) {
        STRLEN len;
        const char *s = SvPV(o->at, len);
        int h = -1, m = -1, sec = 0, got;
        got = len >= 5 && isDIGIT(s[0]) && isDIGIT(s[1]) && s[2] == ':' && isDIGIT(s[3]) && isDIGIT(s[4]);
        if (got) {
            h = (s[0] - '0') * 10 + (s[1] - '0');
            m = (s[3] - '0') * 10 + (s[4] - '0');
            if (len == 8 && s[5] == ':' && isDIGIT(s[6]) && isDIGIT(s[7])) sec = (s[6] - '0') * 10 + (s[7] - '0');
            else if (len != 5) got = 0;
        }
        if (!got || h > 23 || m > 59 || sec > 59)
            croak("%s: at => '%s' is not a time of day, HH:MM or HH:MM:SS", what, s);
        r->by_hour = 1u << h;
        r->by_minute = UINT64_C(1) << m;
        r->by_second = UINT64_C(1) << sec;
    }
    if (o->count) {
        IV c = SvIV(o->count);
        if (c < 1)
            croak("%s: count => %" IVdf " is not a count above zero", what, c);
        r->count = c;
    }
    if (o->until) {
        const time_keeper_abi *T = tkr_tk(aTHX);
        time_keeper_instant u;
        time_keeper_zone z;
        if ((T->from_sv)(aTHX_ o->until, &u, &z, NULL) != TIME_KEEPER_OK)
            croak("%s: until is not a Time::Keeper value", what);
        r->until_kind = z.kind == TIME_KEEPER_ZONE_FLOATING ? TKR_UNTIL_FLOATING : TKR_UNTIL_UTC;
        r->until_sec = u.sec;
        if (r->count)
            croak("%s: until and count cannot both be given", what);
    }
}

/* The name of the rule's zone, as Time::Keeper would write it. */
static SV *
tkr_zone_name_sv(pTHX_ const tkr_rule *r)
{
    switch (r->zone.kind) {
    case TIME_KEEPER_ZONE_UTC:      return newSVpvs("UTC");
    case TIME_KEEPER_ZONE_FLOATING: return newSVpvs("floating");
    case TIME_KEEPER_ZONE_FIXED: {
        int32_t v = r->zone.value, a = v < 0 ? -v : v;
        return a % 60 ? newSVpvf("%c%02d:%02d:%02d", v < 0 ? '-' : '+', a / 3600, a % 3600 / 60, a % 60)
                      : newSVpvf("%c%02d:%02d", v < 0 ? '-' : '+', a / 3600, a % 3600 / 60);
    }
    default: {
        const char *n = (tkr_tkz(aTHX)->name)(r->zone.value);
        return newSVpv(n ? n : "?", 0);
    }
    }
}

/* UNTIL as a Time::Keeper value in the rule's zone: a UTC instant, a
 * floating wall time, or the last second of a DATE in the zone. */
static SV *
tkr_until_sv(pTHX_ const tkr_rule *r, const char *what)
{
    const time_keeper_abi *T = tkr_tk(aTHX);
    time_keeper_instant u;
    time_keeper_zone fl;
    SV *sv;
    u.nsec = 0;
    switch (r->until_kind) {
    case TKR_UNTIL_UTC:
        u.sec = r->until_sec;
        sv = (T->new_sv)(aTHX_ &u, &r->zone, r->locale);
        break;
    case TKR_UNTIL_FLOATING:
        u.sec = r->until_sec;
        fl.kind = TIME_KEEPER_ZONE_FLOATING;
        fl.value = 0;
        sv = (T->new_sv)(aTHX_ &u, &fl, r->locale);
        break;
    case TKR_UNTIL_DATE: {
        time_keeper_civil c;
        int64_t y;
        unsigned m, d;
        memset(&c, 0, sizeof c);
        tkr_civil_from_days(r->until_sec / 86400, &y, &m, &d);
        c.year = y; c.month = (int)m; c.day = (int)d; c.hour = 23; c.minute = 59; c.second = 59;
        if ((T->from_civil)(aTHX_ &c, &r->zone, TIME_KEEPER_GAP_FORWARD, TIME_KEEPER_OVERLAP_EARLIER, &u) != TIME_KEEPER_OK)
            croak("%s: UNTIL is outside the years Time::Keeper holds", what);
        sv = (T->new_sv)(aTHX_ &u, &r->zone, r->locale);
        break;
    }
    default:
        return &PL_sv_undef;
    }
    if (!sv)
        croak("%s: UNTIL is outside the years Time::Keeper holds", what);
    return sv;
}

#endif
