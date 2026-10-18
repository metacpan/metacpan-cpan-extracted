#ifndef TK_ABI_IMPL_H
#define TK_ABI_IMPL_H

/* The table time_keeper_abi.h declares, over the core's own functions.
 * Every entry checks what it is given and returns a code rather than
 * croaking: only loading Time::Keeper::Zone, and running out of memory,
 * croak. */

typedef char tk_abi_instant_matches[sizeof(time_keeper_instant) == sizeof(tk_instant) ? 1 : -1];

static int
tka_now(time_keeper_instant *out)
{
    dTHX;
    tk_instant t;
    if (!out)
        return TIME_KEEPER_BAD;
    tk_now_sv(aTHX_ &t);
    out->sec = t.sec;
    out->nsec = t.nsec;
    return TIME_KEEPER_OK;
}

static int
tka_instant_in(const time_keeper_instant *in, tk_instant *t)
{
    if (!in)
        return 0;
    t->sec = in->sec;
    t->nsec = in->nsec;
    return tk_instant_valid(t);
}

/* A public zone as the core's; 0 if it is not one. */
static int
tka_zone_in(pTHX_ const time_keeper_zone *zone, tk_zone_spec *z)
{
    z->fixed = 0;
    if (!zone) {
        z->zone = TK_ZONE_UTC;
        return 1;
    }
    switch (zone->kind) {
    case TIME_KEEPER_ZONE_UTC:      z->zone = TK_ZONE_UTC; return 1;
    case TIME_KEEPER_ZONE_FLOATING: z->zone = TK_ZONE_FLOATING; return 1;
    case TIME_KEEPER_ZONE_FIXED:
        if (zone->value <= -(int32_t)TK_MAX_FIXED_OFFSET - 1 || zone->value > TK_MAX_FIXED_OFFSET)
            return 0;
        z->zone = zone->value ? TK_ZONE_FIXED : TK_ZONE_UTC;
        z->fixed = zone->value;
        return 1;
    case TIME_KEEPER_ZONE_NAMED:
        if (zone->value < 0 || zone->value >= (tk_zone_abi(aTHX)->zone_count)()
            || zone->value > 0xFFFF - TK_ZONE_NAMED)
            return 0;
        z->zone = (uint16_t)(TK_ZONE_NAMED + zone->value);
        return 1;
    }
    return 0;
}

static void
tka_zone_out(const tk_value *v, time_keeper_zone *zone)
{
    if (!zone)
        return;
    if (v->zone >= TK_ZONE_NAMED) {
        zone->kind = TIME_KEEPER_ZONE_NAMED;
        zone->value = v->zone - TK_ZONE_NAMED;
    }
    else {
        zone->kind = v->zone == TK_ZONE_UTC ? TIME_KEEPER_ZONE_UTC
                   : v->zone == TK_ZONE_FLOATING ? TIME_KEEPER_ZONE_FLOATING : TIME_KEEPER_ZONE_FIXED;
        zone->value = v->zone == TK_ZONE_FIXED ? v->utoff : 0;
    }
}

/* A value from the public arguments; 0 if any is not one. */
static int
tka_value(pTHX_ const time_keeper_instant *in, const time_keeper_zone *zone, int locale, tk_value *v)
{
    tk_instant t;
    tk_zone_spec z;
    if (!tka_instant_in(in, &t) || !tka_zone_in(aTHX_ zone, &z) || locale < 0 || locale >= TK_LOCALE_COUNT)
        return 0;
    tk_value_init(aTHX_ v, &t, &z);
    v->locale = (uint16_t)locale;
    return 1;
}

static int
tka_zone_parse(pTHX_ const char *s, size_t len, time_keeper_zone *out)
{
    int32_t off;
    int id;
    if (!s || !out)
        return TIME_KEEPER_BAD;
    if (tk_ieq(s, len, "UTC") || tk_ieq(s, len, "GMT") || tk_ieq(s, len, "Z")) {
        out->kind = TIME_KEEPER_ZONE_UTC;
        out->value = 0;
        return TIME_KEEPER_OK;
    }
    if (tk_ieq(s, len, "floating")) {
        out->kind = TIME_KEEPER_ZONE_FLOATING;
        out->value = 0;
        return TIME_KEEPER_OK;
    }
    if (len && (s[0] == '+' || s[0] == '-')) {
        if (!tk_parse_offset(s, len, &off))
            return TIME_KEEPER_BAD;
        out->kind = off ? TIME_KEEPER_ZONE_FIXED : TIME_KEEPER_ZONE_UTC;
        out->value = off;
        return TIME_KEEPER_OK;
    }
    if (tk_ieq(s, len, "local")) {
        SV **tz = hv_fetchs(GvHVn(PL_envgv), "TZ", 0);
        STRLEN tzlen = 0;
        const char *tzs = NULL;
        if (tz && SvOK(*tz))
            tzs = SvPV(*tz, tzlen);
        id = (tk_zone_abi(aTHX)->local_zone)(tzs, tzlen);
    }
    else
        id = (tk_zone_abi(aTHX)->lookup)(s, len);
    if (id < 0 || id > 0xFFFF - TK_ZONE_NAMED)
        return TIME_KEEPER_BAD;
    out->kind = TIME_KEEPER_ZONE_NAMED;
    out->value = id;
    return TIME_KEEPER_OK;
}

static int
tka_civil(pTHX_ const time_keeper_instant *in, const time_keeper_zone *zone, time_keeper_civil *out)
{
    tk_value v;
    const tk_civil *c;
    if (!out || !tka_value(aTHX_ in, zone, 0, &v))
        return TIME_KEEPER_BAD;
    c = tk_value_civil(&v);
    out->year = c->year;
    out->month = c->month;
    out->day = c->day;
    out->hour = c->hour;
    out->minute = c->minute;
    out->second = c->second;
    out->nanosecond = c->nsec;
    out->day_of_week = c->dow;
    out->day_of_year = c->doy;
    out->offset = v.utoff;
    out->is_dst = (v.flags & TK_F_DST) ? 1 : 0;
    return TIME_KEEPER_OK;
}

static int
tka_from_civil(pTHX_ const time_keeper_civil *in, const time_keeper_zone *zone, int gap, int overlap,
               time_keeper_instant *out)
{
    tk_zone_spec z;
    tk_value v;
    int r;
    if (!in || !out || !tka_zone_in(aTHX_ zone, &z))
        return TIME_KEEPER_BAD;
    if (in->year < TK_YEAR_MIN || in->year > TK_YEAR_MAX)
        return TIME_KEEPER_RANGE;
    if (in->month < 1 || in->month > 12 || in->day < 1 || in->day > (int)tk_days_in_month(in->year, (unsigned)in->month)
        || in->hour < 0 || in->hour > 23 || in->minute < 0 || in->minute > 59 || in->second < 0 || in->second > 60
        || in->nanosecond < 0 || in->nanosecond >= TK_NSECS_PER_SEC
        || gap < TIME_KEEPER_GAP_FAIL || gap > TIME_KEEPER_GAP_BACKWARD
        || (overlap != TIME_KEEPER_OVERLAP_LATER && overlap != TIME_KEEPER_OVERLAP_EARLIER))
        return TIME_KEEPER_BAD;
    r = tk_value_from_local_rc(aTHX_ &v, &z, in->year, (unsigned)in->month, (unsigned)in->day,
                               in->hour, in->minute, in->second, in->nanosecond, gap, overlap);
    switch (r) {
    case TK_LOCAL_OK:
        out->sec = v.inst.sec;
        out->nsec = v.inst.nsec;
        return TIME_KEEPER_OK;
    case TK_LOCAL_IN_GAP:  return TIME_KEEPER_GAP;
    case TK_LOCAL_NO_LEAP: return TIME_KEEPER_NOLEAP;
    default:               return TIME_KEEPER_RANGE;
    }
}

/* What was written into an SV, into the caller's buffer, as snprintf. */
static size_t
tka_copy_out(char *buf, size_t len, const char *s, size_t n)
{
    if (buf && len) {
        size_t k = n < len ? n : len - 1;
        memcpy(buf, s, k);
        buf[k] = '\0';
    }
    return n;
}

static size_t
tka_pattern(pTHX_ int cldr, char *buf, size_t len, const char *p, size_t plen,
            const time_keeper_instant *in, const time_keeper_zone *zone, int locale)
{
    tk_value v;
    tk_out o;
    size_t n;
    if (!p || !tka_value(aTHX_ in, zone, locale, &v))
        return tka_copy_out(buf, len, "", 0);
    ENTER;
    SAVETMPS;
    o.sv = sv_2mortal(newSVpvs(""));
    o.utf8 = 0;
    o.digits = NULL;
    if (cldr)
        tk_format_cldr(aTHX_ &o, NULL, &v, tk_locale_get(aTHX_ v.locale), p, plen, NULL, NULL);
    else
        tk_strftime(aTHX_ &o, NULL, &v, tk_locale_get(aTHX_ v.locale), p, plen);
    n = tka_copy_out(buf, len, SvPVX(o.sv), SvCUR(o.sv));
    FREETMPS;
    LEAVE;
    return n;
}

static size_t
tka_strftime(pTHX_ char *buf, size_t len, const char *p, size_t plen,
             const time_keeper_instant *in, const time_keeper_zone *zone, int locale)
{
    return tka_pattern(aTHX_ 0, buf, len, p, plen, in, zone, locale);
}

static size_t
tka_format(pTHX_ char *buf, size_t len, const char *p, size_t plen,
           const time_keeper_instant *in, const time_keeper_zone *zone, int locale)
{
    return tka_pattern(aTHX_ 1, buf, len, p, plen, in, zone, locale);
}

static size_t
tka_iso8601(pTHX_ char *buf, size_t len, const time_keeper_instant *in, const time_keeper_zone *zone)
{
    tk_value v;
    char out[64];
    int n;
    if (!tka_value(aTHX_ in, zone, 0, &v))
        return tka_copy_out(buf, len, "", 0);
    n = tk_iso8601(&v, out);
    return tka_copy_out(buf, len, out, (size_t)n);
}

static size_t
tka_http_date(char *buf, size_t len, const time_keeper_instant *in)
{
    static const char *const days[7] = { "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" };
    static const char *const months[12] = {
        "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    };
    tk_instant t;
    tk_civil c;
    char out[40];
    int n;
    if (!tka_instant_in(in, &t))
        return tka_copy_out(buf, len, "", 0);
    tk_civil_from_instant(&t, &c);
    if (c.year < 0 || c.year > 9999)
        return tka_copy_out(buf, len, "", 0);
    n = sprintf(out, "%s, %02u %s %04d %02u:%02u:%02u GMT", days[c.dow - 1], (unsigned)c.day,
                months[c.month - 1], (int)c.year, (unsigned)c.hour, (unsigned)c.minute, (unsigned)c.second);
    return tka_copy_out(buf, len, out, (size_t)n);
}

/* parse croaks for some errors (a day the month lacks, a zone that is not
 * there), so it runs under G_EVAL through try_parse, which is not hot. */
static int
tka_parse(pTHX_ const char *s, size_t len, time_keeper_instant *out, time_keeper_zone *zone)
{
    int count, rc = TIME_KEEPER_PARSE;
    if (!s || !out)
        return TIME_KEEPER_BAD;
    {
        dSP;
        ENTER;
        SAVETMPS;
        save_scalar(PL_errgv);
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("Time::Keeper")));
        XPUSHs(sv_2mortal(newSVpvn(s, len)));
        PUTBACK;
        count = call_method("try_parse", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (count == 1) {
            SV *r = POPs;
            if (tk_is_value(aTHX_ r)) {
                const tk_value *v = tk_value_of(aTHX_ r, "Time::Keeper ABI parse");
                out->sec = v->inst.sec;
                out->nsec = v->inst.nsec;
                tka_zone_out(v, zone);
                rc = TIME_KEEPER_OK;
            }
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    return rc;
}

static int
tka_locale_find(const char *code, size_t len)
{
    if (!code)
        return -1;
    return tk_locale_find(code, len);
}

static SV *
tka_new_sv(pTHX_ const time_keeper_instant *in, const time_keeper_zone *zone, int locale)
{
    dMY_CXT;
    tk_value v;
    if (!tka_value(aTHX_ in, zone, locale, &v))
        return NULL;
    return tk_value_new_sv(aTHX_ MY_CXT.stash, &v);
}

static int
tka_from_sv(pTHX_ SV *sv, time_keeper_instant *out, time_keeper_zone *zone, int *locale)
{
    const tk_value *v;
    if (!sv || !tk_is_value(aTHX_ sv))
        return TIME_KEEPER_BAD;
    v = tk_value_of(aTHX_ sv, "Time::Keeper ABI from_sv");
    if (out) {
        out->sec = v->inst.sec;
        out->nsec = v->inst.nsec;
    }
    tka_zone_out(v, zone);
    if (locale)
        *locale = v->locale;
    return TIME_KEEPER_OK;
}

static int
tka_tai_minus_utc(const time_keeper_instant *in, int *out)
{
    tk_instant t;
    int off;
    if (!out || !tka_instant_in(in, &t))
        return TIME_KEEPER_BAD;
    if (!tk_tai_minus_utc(&t, &off))
        return TIME_KEEPER_RANGE;
    *out = off;
    return TIME_KEEPER_OK;
}

static const time_keeper_abi TK_ABI = {
    TIME_KEEPER_ABI_VERSION,
    tka_now,
    tka_zone_parse,
    tka_civil,
    tka_from_civil,
    tka_strftime,
    tka_format,
    tka_iso8601,
    tka_http_date,
    tka_parse,
    tka_locale_find,
    tka_new_sv,
    tka_from_sv,
    tka_tai_minus_utc
};

#endif
