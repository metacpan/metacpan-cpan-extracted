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

/* A value in a calendar; 0 if any argument is not one. */
static int
tka_value_cal(pTHX_ const time_keeper_instant *in, const time_keeper_zone *zone, int locale, int calendar, tk_value *v)
{
    if (calendar < 0 || calendar >= TK_CAL_COUNT || !tka_value(aTHX_ in, zone, locale, v))
        return 0;
    v->calendar = (uint8_t)calendar;
    return 1;
}

static size_t
tka_pattern(pTHX_ int cldr, char *buf, size_t len, const char *p, size_t plen,
            const time_keeper_instant *in, const time_keeper_zone *zone, int locale, int calendar)
{
    tk_value v;
    tk_out o;
    size_t n;
    if (!p || !tka_value_cal(aTHX_ in, zone, locale, calendar, &v))
        return tka_copy_out(buf, len, "", 0);
    ENTER;
    SAVETMPS;
    o.sv = sv_2mortal(newSVpvs(""));
    o.utf8 = 0;
    o.digits = NULL; o.nums = NULL; o.nums_len = 0;
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
    return tka_pattern(aTHX_ 0, buf, len, p, plen, in, zone, locale, TK_CAL_GREGORY);
}

static size_t
tka_format(pTHX_ char *buf, size_t len, const char *p, size_t plen,
           const time_keeper_instant *in, const time_keeper_zone *zone, int locale)
{
    return tka_pattern(aTHX_ 1, buf, len, p, plen, in, zone, locale, TK_CAL_GREGORY);
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

/* ---- version 2: calendars ---------------------------------------------- */

static int
tka_calendar_find(const char *id, size_t len)
{
    if (!id)
        return -1;
    return tk_cal_find(id, len);
}

static int
tka_calendar_id(int calendar, const char **out)
{
    if (!out || calendar < 0 || calendar >= TK_CAL_COUNT)
        return TIME_KEEPER_BAD;
    *out = tk_calendars[calendar].id;
    return TIME_KEEPER_OK;
}

static int
tka_cal_fields(pTHX_ const time_keeper_instant *in, const time_keeper_zone *zone, int calendar, time_keeper_calfields *out)
{
    tk_value v;
    const tk_civil *c;
    const tk_calendar *cal;
    tk_calfields f;
    int64_t days;
    if (!out || !tka_value_cal(aTHX_ in, zone, 0, calendar, &v))
        return TIME_KEEPER_BAD;
    cal = tk_cal_of(&v);
    days = tk_value_local_days(&v);
    if (!tk_cal_days_ok(cal, days))
        return TIME_KEEPER_RANGE;
    tk_cal_fields(cal, days, &f);
    c = tk_value_civil(&v);
    out->calendar = calendar;
    out->year = f.year;
    out->era_year = f.era_year;
    out->era = (int)f.era;
    out->month = (int)f.month;
    out->day = (int)f.day;
    out->month_number = (int)f.month_number;
    out->leap_month = f.leap_month;
    out->leap_year = f.leap_year;
    out->months_in_year = (int)f.months_in_year;
    out->days_in_month = (int)f.days_in_month;
    out->days_in_year = (int)f.days_in_year;
    out->day_of_year = (int)f.doy;
    out->hour = c->hour;
    out->minute = c->minute;
    out->second = c->second;
    out->nanosecond = c->nsec;
    out->offset = v.utoff;
    out->is_dst = (v.flags & TK_F_DST) ? 1 : 0;
    return TIME_KEEPER_OK;
}

static int
tka_cal_from_fields(pTHX_ const time_keeper_calfields *in, const time_keeper_zone *zone, int gap, int overlap,
                    time_keeper_instant *out)
{
    tk_zone_spec z;
    tk_value v;
    const tk_calendar *cal;
    int64_t days, gy;
    unsigned gm, gd;
    int r;
    if (!in || !out || !tka_zone_in(aTHX_ zone, &z) || in->calendar < 0 || in->calendar >= TK_CAL_COUNT)
        return TIME_KEEPER_BAD;
    cal = &tk_calendars[in->calendar];
    if (in->year < -TK_CAL_YEAR_LIMIT || in->year > TK_CAL_YEAR_LIMIT || !tk_cal_year_ok(cal, in->year))
        return TIME_KEEPER_RANGE;
    if (in->month < 1 || (unsigned)in->month > cal->months_in_year(in->year)
        || in->day < 1 || (unsigned)in->day > cal->days_in_month(in->year, (unsigned)in->month)
        || in->hour < 0 || in->hour > 23 || in->minute < 0 || in->minute > 59 || in->second < 0 || in->second > 60
        || in->nanosecond < 0 || in->nanosecond >= TK_NSECS_PER_SEC
        || gap < TIME_KEEPER_GAP_FAIL || gap > TIME_KEEPER_GAP_BACKWARD
        || (overlap != TIME_KEEPER_OVERLAP_LATER && overlap != TIME_KEEPER_OVERLAP_EARLIER))
        return TIME_KEEPER_BAD;
    days = cal->to_days(in->year, (unsigned)in->month, (unsigned)in->day);
    if (!tk_cal_days_ok(cal, days))
        return TIME_KEEPER_RANGE;
    tk_civil_from_days(days, &gy, &gm, &gd);
    if (gy < TK_YEAR_MIN || gy > TK_YEAR_MAX)
        return TIME_KEEPER_RANGE;
    r = tk_value_from_local_rc(aTHX_ &v, &z, gy, gm, gd, in->hour, in->minute, in->second, in->nanosecond, gap, overlap);
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

static size_t
tka_format_cal(pTHX_ char *buf, size_t len, const char *p, size_t plen,
               const time_keeper_instant *in, const time_keeper_zone *zone, int locale, int calendar)
{
    return tka_pattern(aTHX_ 1, buf, len, p, plen, in, zone, locale, calendar);
}

static size_t
tka_strftime_cal(pTHX_ char *buf, size_t len, const char *p, size_t plen,
                 const time_keeper_instant *in, const time_keeper_zone *zone, int locale, int calendar)
{
    return tka_pattern(aTHX_ 0, buf, len, p, plen, in, zone, locale, calendar);
}

static SV *
tka_new_sv_cal(pTHX_ const time_keeper_instant *in, const time_keeper_zone *zone, int locale, int calendar)
{
    dMY_CXT;
    tk_value v;
    if (!tka_value_cal(aTHX_ in, zone, locale, calendar, &v))
        return NULL;
    return tk_value_new_sv(aTHX_ MY_CXT.stash, &v);
}

static int
tka_from_sv_cal(pTHX_ SV *sv, time_keeper_instant *out, time_keeper_zone *zone, int *locale, int *calendar)
{
    int r = tka_from_sv(aTHX_ sv, out, zone, locale);
    if (r == TIME_KEEPER_OK && calendar)
        *calendar = tk_value_of(aTHX_ sv, "Time::Keeper ABI from_sv_cal")->calendar;
    return r;
}

/* ---- version 3: arithmetic, CLDR parsing, durations --------------------- */

#define TKA_WHAT "Time::Keeper ABI"

/* fn run under an eval through the private XSUB Time::Keeper::_abi_guard,
 * $@ left as it was. 1 when fn returned; 0 when it croaked, its message in
 * err without the name in front or the "at ... line" after. Used where the
 * core's own croaking code is the only statement of a result or a reason, so
 * the table and the methods cannot disagree. */
typedef struct tka_guarded {
    void (*fn)(pTHX_ void *);
    void *arg;
} tka_guarded;

static void
tka_err(char *err, size_t errlen, const char *msg, size_t mlen)
{
    if (!err || !errlen)
        return;
    if (mlen >= errlen)
        mlen = errlen - 1;
    Copy(msg, err, mlen, char);
    err[mlen] = '\0';
}

static int
tka_guard(pTHX_ void (*fn)(pTHX_ void *), void *arg, char *err, size_t errlen)
{
    dSP;
    tka_guarded g;
    CV *cv = get_cv("Time::Keeper::_abi_guard", 0);
    int ok;
    if (!cv) {
        tka_err(err, errlen, "Time::Keeper is not loaded", 26);
        return 0;
    }
    g.fn = fn;
    g.arg = arg;
    ENTER;
    SAVETMPS;
    save_scalar(PL_errgv);
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVuv(PTR2UV(&g))));
    PUTBACK;
    call_sv((SV *)cv, G_EVAL | G_DISCARD);
    SPAGAIN;
    ok = !SvTRUE(ERRSV);
    if (!ok) {
        STRLEN len;
        const char *m = SvPV(ERRSV, len), *end = m + len, *at;
        size_t wl = sizeof(TKA_WHAT ": ") - 1;
        if (len >= wl && memEQ(m, TKA_WHAT ": ", wl))
            m += wl;
        while (end > m && (end[-1] == '\n' || end[-1] == '.'))
            end--;
        for (at = end - 4; at > m; at--)
            if (memEQ(at, " at ", 4)) {
                const char *ln = at + 4;
                while (ln < end && !(ln + 6 <= end && memEQ(ln, " line ", 6)))
                    ln++;
                if (ln < end) {
                    end = at;
                    break;
                }
            }
        tka_err(err, errlen, m, (size_t)(end - m));
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return ok;
}

static int
tka_point_in(pTHX_ const time_keeper_point *p, tk_value *v)
{
    return p && tka_value_cal(aTHX_ &p->inst, &p->zone, p->locale, p->calendar, v);
}

static void
tka_point_out(const tk_value *v, time_keeper_point *out)
{
    out->inst.sec = v->inst.sec;
    out->inst.nsec = v->inst.nsec;
    tka_zone_out(v, &out->zone);
    out->locale = v->locale;
    out->calendar = v->calendar;
}

static int
tka_local_code(int r)
{
    switch (r) {
    case TK_LOCAL_OK:      return TIME_KEEPER_OK;
    case TK_LOCAL_IN_GAP:  return TIME_KEEPER_GAP;
    case TK_LOCAL_NO_LEAP: return TIME_KEEPER_NOLEAP;
    default:               return TIME_KEEPER_RANGE;
    }
}

static int
tka_gap_overlap_ok(int gap, int overlap)
{
    return gap >= TIME_KEEPER_GAP_FAIL && gap <= TIME_KEEPER_GAP_BACKWARD
        && (overlap == TIME_KEEPER_OVERLAP_LATER || overlap == TIME_KEEPER_OVERLAP_EARLIER);
}

/* A duration from the public parts, as Duration->new makes one; years kept
 * apart in *years when the calendar adds them by month code. 0 when a part
 * is out of range. */
static int
tka_parts_in(const time_keeper_parts *p, int calendar, tk_duration *d, int64_t *years)
{
    int64_t y;
    if (!p || p->end_of_month < TIME_KEEPER_EOM_DEFAULT || p->end_of_month > TIME_KEEPER_EOM_PRESERVE)
        return 0;
    if (p->years > TK_DUR_LIMIT / 12 || p->years < -TK_DUR_LIMIT / 12
        || p->weeks > TK_DUR_LIMIT / 7 || p->weeks < -TK_DUR_LIMIT / 7
        || p->hours > TK_DUR_LIMIT / 60 || p->hours < -TK_DUR_LIMIT / 60
        || !tk_dur_in_range(p->months) || !tk_dur_in_range(p->days)
        || !tk_dur_in_range(p->minutes) || !tk_dur_in_range(p->seconds))
        return 0;
    Zero(d, 1, tk_duration);
    y = calendar == TK_CAL_GREGORY ? 0 : p->years;
    d->months = (calendar == TK_CAL_GREGORY ? p->years * 12 : 0) + p->months;
    d->days = p->weeks * 7 + p->days;
    d->minutes = p->hours * 60 + p->minutes;
    d->seconds = p->seconds;
    if (!tk_dur_in_range(d->months) || !tk_dur_in_range(d->days) || !tk_dur_in_range(d->minutes)
        || !tk_dur_normalize(d, p->nanoseconds))
        return 0;
    switch (p->end_of_month) {
    case TIME_KEEPER_EOM_WRAP:     d->eom = TK_EOM_WRAP; break;
    case TIME_KEEPER_EOM_LIMIT:    d->eom = TK_EOM_LIMIT; break;
    case TIME_KEEPER_EOM_PRESERVE: d->eom = TK_EOM_PRESERVE; break;
    default:                       d->eom = tk_dur_default_eom(d->months); break;
    }
    if (years)
        *years = y;
    return 1;
}

/* plus ---------------------------------------------------------------------- */

typedef struct tka_plus_arg {
    tk_value *v;
    tk_duration d;
    int64_t years;
    int years_eom, gap, overlap;
    tk_value out;
} tka_plus_arg;

static void
tka_plus_croaking(pTHX_ void *p)
{
    tka_plus_arg *a = (tka_plus_arg *)p;
    tk_value mid = *a->v;
    if (a->years)
        tk_value_plus_years(aTHX_ &mid, a->v, a->years, a->years_eom, a->gap, a->overlap, TKA_WHAT);
    tk_value_plus(aTHX_ &a->out, &mid, &a->d, a->gap, a->overlap, TKA_WHAT);
}

static int
tka_plus(pTHX_ const time_keeper_point *in, const time_keeper_parts *parts, int gap, int overlap,
         time_keeper_point *out, char *err, size_t errlen)
{
    tka_plus_arg a;
    tk_value v, mid;
    int code = TIME_KEEPER_RANGE;
    if (!out || !tka_point_in(aTHX_ in, &v) || !tka_gap_overlap_ok(gap, overlap)
        || !tka_parts_in(parts, v.calendar, &a.d, &a.years)) {
        tka_err(err, errlen, "an argument is not one", 22);
        return TIME_KEEPER_BAD;
    }
    if (!a.years) {
        int r = TK_LOCAL_OK;
        mid = v;
        if (a.d.months || a.d.days)
            r = tk_value_calendar_rc(aTHX_ &mid, &v, a.d.months, a.d.days, a.d.eom, gap, overlap);
        if (r == TK_LOCAL_OK) {
            tk_value res = mid;
            if (!(a.d.minutes || a.d.seconds || a.d.nsec)
                || tk_value_clock_rc(aTHX_ &res, &mid, a.d.minutes, a.d.seconds, a.d.nsec)) {
                tka_point_out(&res, out);
                return TIME_KEEPER_OK;
            }
        }
        else
            code = tka_local_code(r);
    }
    a.v = &v;
    a.years_eom = parts->end_of_month == TIME_KEEPER_EOM_DEFAULT ? tk_dur_default_eom(a.years) : a.d.eom;
    a.gap = gap;
    a.overlap = overlap;
    if (tka_guard(aTHX_ tka_plus_croaking, &a, err, errlen)) {
        tka_point_out(&a.out, out);
        return TIME_KEEPER_OK;
    }
    return code;
}

/* truncate and end_of -------------------------------------------------------- */

/* tk_value_bucket with an increment of one, returning its result instead of
 * croaking on the last resort. */
static int
tka_bucket_rc(pTHX_ tk_value *out, tk_value *v, int unit, int ws)
{
    tk_zone_spec z;
    int64_t y;
    unsigned m, d, h, mi, s;
    int32_t ns;
    int r;

    tk_period_start(tk_value_civil(v), unit, 1, ws, &y, &m, &d, &h, &mi, &s, &ns);
    if (v->calendar != TK_CAL_GREGORY && unit <= TK_U_MONTH) {
        tk_calfields f;
        tk_cal_fields(tk_cal_of(v), tk_value_local_days(v), &f);
        tk_civil_from_days(tk_cal_period_first_day(tk_cal_of(v), &f, unit), &y, &m, &d);
    }
    tk_value_zone(v, &z);
    r = tk_value_from_local_rc(aTHX_ out, &z, y, m, d, h, mi, s, ns, TKZ_GAP_FORWARD, TKZ_OVERLAP_LATER);
    if (r != TK_LOCAL_OK || tk_inst_cmp(&out->inst, &v->inst) > 0)
        r = tk_value_from_local_rc(aTHX_ out, &z, y, m, d, h, mi, s, ns, TKZ_GAP_FORWARD, TKZ_OVERLAP_EARLIER);
    out->locale = v->locale;
    out->calendar = v->calendar;
    return r;
}

typedef struct tka_trunc_arg {
    tk_value *v;
    int unit, ws, end;
    tk_value out;
} tka_trunc_arg;

static void
tka_trunc_croaking(pTHX_ void *p)
{
    tka_trunc_arg *a = (tka_trunc_arg *)p;
    if (a->end)
        tk_value_end_of(aTHX_ &a->out, a->v, a->unit, a->ws, TKA_WHAT);
    else
        tk_value_truncate_ws(aTHX_ &a->out, a->v, a->unit, a->ws, TKA_WHAT);
}

static int
tka_trunc(pTHX_ int end, const time_keeper_point *in, int unit, int week_start, time_keeper_point *out,
          char *err, size_t errlen)
{
    tka_trunc_arg a;
    tk_value v, lo, hi, res;
    int r;
    if (!out || !tka_point_in(aTHX_ in, &v) || unit < TIME_KEEPER_UNIT_YEAR || unit > TIME_KEEPER_UNIT_NANOSECOND
        || week_start < TIME_KEEPER_WEEK_LOCALE || week_start > 7) {
        tka_err(err, errlen, "an argument is not one", 22);
        return TIME_KEEPER_BAD;
    }
    a.ws = week_start == TIME_KEEPER_WEEK_LOCALE ? tk_locale_of(&v)->first_day : week_start;
    r = tka_bucket_rc(aTHX_ &lo, &v, unit, a.ws);
    if (r == TK_LOCAL_OK) {
        if (!end) {
            tka_point_out(&lo, out);
            return TIME_KEEPER_OK;
        }
        if (!tk_value_bucket_next(aTHX_ &hi, &lo, unit, 1, a.ws)) {
            tk_zone_spec z;
            tk_instant t;
            t.sec = tk_sec_max();
            t.nsec = TK_NSECS_PER_SEC - 1;
            tk_value_zone(&v, &z);
            tk_value_init(aTHX_ &res, &t, &z);
            res.locale = v.locale;
            res.calendar = v.calendar;
            tka_point_out(&res, out);
            return TIME_KEEPER_OK;
        }
        if (tk_value_clock_rc(aTHX_ &res, &hi, 0, 0, -1)) {
            tka_point_out(&res, out);
            return TIME_KEEPER_OK;
        }
    }
    a.v = &v;
    a.unit = unit;
    a.end = end;
    if (tka_guard(aTHX_ tka_trunc_croaking, &a, err, errlen)) {
        tka_point_out(&a.out, out);
        return TIME_KEEPER_OK;
    }
    return TIME_KEEPER_RANGE;
}

static int
tka_truncate(pTHX_ const time_keeper_point *in, int unit, int week_start, time_keeper_point *out, char *err, size_t errlen)
{
    return tka_trunc(aTHX_ 0, in, unit, week_start, out, err, errlen);
}

static int
tka_end_of(pTHX_ const time_keeper_point *in, int unit, int week_start, time_keeper_point *out, char *err, size_t errlen)
{
    return tka_trunc(aTHX_ 1, in, unit, week_start, out, err, errlen);
}

/* the weekday adjusters ------------------------------------------------------ */

typedef struct tka_dow_arg {
    tk_value *v;
    int dow, direction, or_same, n, gap, overlap, nth;
    tk_value out;
} tka_dow_arg;

static void
tka_dow_croaking(pTHX_ void *p)
{
    tka_dow_arg *a = (tka_dow_arg *)p;
    if (a->nth)
        tk_value_nth_in_month(aTHX_ &a->out, a->v, a->dow, a->n, a->gap, a->overlap, TKA_WHAT);
    else
        tk_value_adjust_dow(aTHX_ &a->out, a->v, a->dow, a->direction, a->or_same, a->gap, a->overlap, TKA_WHAT);
}

static int
tka_dow_guarded(pTHX_ tka_dow_arg *a, time_keeper_point *out, int code, char *err, size_t errlen)
{
    if (tka_guard(aTHX_ tka_dow_croaking, a, err, errlen)) {
        tka_point_out(&a->out, out);
        return TIME_KEEPER_OK;
    }
    return code;
}

static int
tka_adjust_dow(pTHX_ const time_keeper_point *in, int dow, int direction, int or_same, int gap, int overlap,
               time_keeper_point *out, char *err, size_t errlen)
{
    tka_dow_arg a;
    tk_value v, res;
    const tk_civil *c;
    int64_t delta;
    int r;
    if (!out || !tka_point_in(aTHX_ in, &v) || dow < 1 || dow > 7 || (direction != 1 && direction != -1)
        || !tka_gap_overlap_ok(gap, overlap)) {
        tka_err(err, errlen, "an argument is not one", 22);
        return TIME_KEEPER_BAD;
    }
    c = tk_value_civil(&v);
    delta = direction > 0 ? (dow - c->dow + 7) % 7 : -((c->dow - dow + 7) % 7);
    if (!delta && !or_same)
        delta = 7 * direction;
    r = tk_value_calendar_rc(aTHX_ &res, &v, 0, delta, TK_EOM_WRAP, gap, overlap);
    if (r == TK_LOCAL_OK) {
        tka_point_out(&res, out);
        return TIME_KEEPER_OK;
    }
    a.v = &v; a.dow = dow; a.direction = direction; a.or_same = or_same; a.gap = gap; a.overlap = overlap; a.nth = 0;
    return tka_dow_guarded(aTHX_ &a, out, tka_local_code(r), err, errlen);
}

static int
tka_nth_in_month(pTHX_ const time_keeper_point *in, int dow, int n, int gap, int overlap,
                 time_keeper_point *out, char *err, size_t errlen)
{
    tka_dow_arg a;
    tk_value v, res;
    const tk_civil *c;
    int64_t here, first, target;
    unsigned len;
    int r;
    if (!out || !tka_point_in(aTHX_ in, &v) || dow < 1 || dow > 7 || !(n == -1 || (n >= 1 && n <= 5))
        || !tka_gap_overlap_ok(gap, overlap)) {
        tka_err(err, errlen, "an argument is not one", 22);
        return TIME_KEEPER_BAD;
    }
    c = tk_value_civil(&v);
    here = tk_days_from_civil(c->year, c->month, c->day);
    first = tk_days_from_civil(c->year, c->month, 1);
    len = tk_days_in_month(c->year, c->month);
    if (v.calendar != TK_CAL_GREGORY) {
        tk_calfields f;
        tk_cal_fields(tk_cal_of(&v), here, &f);
        first = tk_cal_of(&v)->to_days(f.year, f.month, 1);
        len = f.days_in_month;
    }
    a.v = &v; a.dow = dow; a.n = n; a.gap = gap; a.overlap = overlap; a.nth = 1;
    if (n > 0) {
        target = first + (dow - (int)tk_dow_from_days(first) + 7) % 7 + (int64_t)(n - 1) * 7;
        if (target - first >= (int64_t)len)
            return tka_dow_guarded(aTHX_ &a, out, TIME_KEEPER_RANGE, err, errlen);
    }
    else {
        int64_t last = first + len - 1;
        target = last - ((int)tk_dow_from_days(last) - dow + 7) % 7;
    }
    r = tk_value_calendar_rc(aTHX_ &res, &v, 0, target - here, TK_EOM_WRAP, gap, overlap);
    if (r == TK_LOCAL_OK) {
        tka_point_out(&res, out);
        return TIME_KEEPER_OK;
    }
    return tka_dow_guarded(aTHX_ &a, out, tka_local_code(r), err, errlen);
}

/* with_time ---------------------------------------------------------------- */

typedef struct tka_with_arg {
    tk_value *v;
    int hour, minute, second, gap, overlap;
    int32_t nsec;
    tk_value out;
} tka_with_arg;

static void
tka_with_croaking(pTHX_ void *p)
{
    tka_with_arg *a = (tka_with_arg *)p;
    const tk_civil *c = tk_value_civil(a->v);
    tk_zone_spec z;
    tk_value_zone(a->v, &z);
    tk_value_from_local(aTHX_ &a->out, &z, c->year, c->month, c->day, a->hour, a->minute, a->second, a->nsec,
                        a->gap, a->overlap, TKA_WHAT);
}

static int
tka_with_time(pTHX_ const time_keeper_point *in, int hour, int minute, int second, int32_t nsec, int gap, int overlap,
              time_keeper_point *out, char *err, size_t errlen)
{
    tka_with_arg a;
    tk_value v, res;
    const tk_civil *c;
    tk_zone_spec z;
    int r;
    if (!out || !tka_point_in(aTHX_ in, &v) || hour < 0 || hour > 23 || minute < 0 || minute > 59 || second < 0
        || second > 60 || nsec < 0 || nsec >= TK_NSECS_PER_SEC || !tka_gap_overlap_ok(gap, overlap)) {
        tka_err(err, errlen, "an argument is not one", 22);
        return TIME_KEEPER_BAD;
    }
    c = tk_value_civil(&v);
    tk_value_zone(&v, &z);
    r = tk_value_from_local_rc(aTHX_ &res, &z, c->year, c->month, c->day, hour, minute, second, nsec, gap, overlap);
    if (r == TK_LOCAL_OK) {
        res.locale = v.locale;
        res.calendar = v.calendar;
        tka_point_out(&res, out);
        return TIME_KEEPER_OK;
    }
    a.v = &v; a.hour = hour; a.minute = minute; a.second = second; a.nsec = nsec; a.gap = gap; a.overlap = overlap;
    if (tka_guard(aTHX_ tka_with_croaking, &a, err, errlen)) {
        a.out.locale = v.locale;
        a.out.calendar = v.calendar;
        tka_point_out(&a.out, out);
        return TIME_KEEPER_OK;
    }
    return tka_local_code(r);
}

/* parse_cldr ---------------------------------------------------------------- */

typedef struct tka_parse_arg {
    SV *text, *pat, *zone;
    int kind, cal, gap, overlap;
    uint16_t lid;
    tk_value out;
} tka_parse_arg;

/* What the methods do once the text has matched: the value parse_cldr makes,
 * or the date or time of day the plain classes' parse_cldr makes. */
static void
tka_parse_croaking(pTHX_ void *p)
{
    tka_parse_arg *a = (tka_parse_arg *)p;
    tk_cursor c;
    tk_fields f;
    STRLEN len, plen;
    const char *s, *pp;
    SV *scan;
    if (a->kind != TIME_KEEPER_KIND_VALUE) {
        tk_plain_parse(aTHX_ &a->out, a->kind == TIME_KEEPER_KIND_DATE ? TK_KIND_DATE : TK_KIND_TIME, 2,
                       a->text, a->pat, a->lid, TKA_WHAT);
        return;
    }
    scan = tk_ascii_digits(aTHX_ a->text);
    s = SvPV(scan, len);
    pp = SvPV(a->pat, plen);
    tk_cursor_init(&c, s, len);
    Zero(&f, 1, tk_fields);
    if (a->cal != TK_CAL_GREGORY) {
        f.calendar = a->cal + 1;
        f.cal_names = tk_cal_names_get(aTHX_ tk_locale_get(aTHX_ a->lid), a->cal);
    }
    if (!(tk_parse_cldr(&c, &f, tk_locale_get(aTHX_ a->lid), pp, plen) && (tk_at_end(&c) || tk_fail(&c, "text was left over"))))
        tk_parse_croak(aTHX_ TKA_WHAT, a->text, scan, &c);
    if (a->cal != TK_CAL_GREGORY)
        tk_cal_fields_resolve(aTHX_ &f, a->cal, TKA_WHAT, SvPV_nolen(a->text));
    tk_fields_to_value(aTHX_ &a->out, &f, a->zone, a->gap, a->overlap, TKA_WHAT, SvPV_nolen(a->text));
    a->out.locale = a->lid;
    a->out.calendar = (uint8_t)a->cal;
}

/* A public zone as the name the methods' zone => takes. */
static SV *
tka_zone_sv(pTHX_ const time_keeper_zone *zone)
{
    if (!zone)
        return NULL;
    switch (zone->kind) {
    case TIME_KEEPER_ZONE_UTC:      return sv_2mortal(newSVpvs("UTC"));
    case TIME_KEEPER_ZONE_FLOATING: return sv_2mortal(newSVpvs("floating"));
    case TIME_KEEPER_ZONE_FIXED: {
        int32_t o = zone->value, a = o < 0 ? -o : o;
        return sv_2mortal(newSVpvf("%c%02d:%02d:%02d", o < 0 ? '-' : '+', (int)(a / 3600), (int)(a / 60 % 60), (int)(a % 60)));
    }
    default:
        return sv_2mortal(newSVpv((tk_zone_abi(aTHX)->name)(zone->value), 0));
    }
}

static int
tka_parse_cldr(pTHX_ const char *text, size_t len, const char *pattern, size_t plen, int kind,
               const time_keeper_zone *zone, int locale, int calendar, int gap, int overlap,
               time_keeper_point *out, time_keeper_civil *clock, char *err, size_t errlen)
{
    tka_parse_arg a;
    tk_cursor c;
    tk_fields f;
    tk_zone_spec zs;
    SV *scan;
    STRLEN slen;
    const char *s;
    int ok;
    if (!text || !pattern || !out || kind < TIME_KEEPER_KIND_VALUE || kind > TIME_KEEPER_KIND_TIME
        || locale < 0 || locale >= TK_LOCALE_COUNT || calendar < 0 || calendar >= TK_CAL_COUNT
        || (kind != TIME_KEEPER_KIND_VALUE && calendar != TK_CAL_GREGORY)
        || (zone && !tka_zone_in(aTHX_ zone, &zs)) || !tka_gap_overlap_ok(gap, overlap)) {
        tka_err(err, errlen, "an argument is not one", 22);
        return TIME_KEEPER_BAD;
    }
    ENTER;
    SAVETMPS;
    a.text = sv_2mortal(newSVpvn(text, len));
    SvUTF8_on(a.text);
    a.pat = sv_2mortal(newSVpvn(pattern, plen));
    SvUTF8_on(a.pat);
    /* the match alone, which most texts a caller tries fail, without Perl */
    scan = tk_ascii_digits(aTHX_ a.text);
    s = SvPV(scan, slen);
    tk_cursor_init(&c, s, slen);
    Zero(&f, 1, tk_fields);
    if (calendar != TK_CAL_GREGORY) {
        f.calendar = calendar + 1;
        f.cal_names = tk_cal_names_get(aTHX_ tk_locale_get(aTHX_ (uint16_t)locale), calendar);
    }
    ok = tk_parse_cldr(&c, &f, tk_locale_get(aTHX_ (uint16_t)locale), pattern, plen) && (tk_at_end(&c) || tk_fail(&c, "text was left over"));
    if (!ok) {
        if (err && errlen) {
            STRLEN at = c.err_at > slen ? slen : c.err_at, chars;
            while (at > 0 && at < slen && UTF8_IS_CONTINUATION((U8)s[at]))
                at--;
            chars = (STRLEN)utf8_length((const U8 *)s, (const U8 *)s + at);
            /* cut short to errlen at a character's start, as the table
               promises; my_snprintf panics instead */
            {
            SV *m = sv_2mortal(newSVpvf("cannot parse '%.*s' at offset %lu: %s", (int)len, text, (unsigned long)chars,
                                        c.err ? c.err : "it is not a date and time"));
            STRLEN ml;
            const char *mb = SvPV_const(m, ml);
            if (ml >= errlen) {
                ml = errlen - 1;
                while (ml > 0 && UTF8_IS_CONTINUATION((U8)mb[ml]))
                    ml--;
            }
            Copy(mb, err, ml, char);
            err[ml] = '\0';
            }
        }
        FREETMPS;
        LEAVE;
        return TIME_KEEPER_PARSE;
    }
    a.kind = kind;
    a.cal = calendar;
    a.lid = (uint16_t)locale;
    a.gap = gap;
    a.overlap = overlap;
    a.zone = tka_zone_sv(aTHX_ zone);
    ok = tka_guard(aTHX_ tka_parse_croaking, &a, err, errlen);
    FREETMPS;
    LEAVE;
    if (!ok)
        return TIME_KEEPER_BAD;
    tka_point_out(&a.out, out);
    if (clock) {
        const tk_civil *cv = tk_value_civil(&a.out);
        clock->year = cv->year;
        clock->month = (int)cv->month;
        clock->day = (int)cv->day;
        clock->hour = (int)cv->hour;
        clock->minute = (int)cv->minute;
        clock->second = (int)cv->second;
        clock->nanosecond = cv->nsec;
        clock->day_of_week = (int)cv->dow;
        clock->day_of_year = 0;
        clock->offset = a.out.utoff;
        clock->is_dst = 0;
    }
    return TIME_KEEPER_OK;
}

/* durations and locales ------------------------------------------------------ */

static SV *
tka_new_duration_sv(pTHX_ const time_keeper_parts *parts)
{
    dMY_CXT;
    tk_duration d;
    time_keeper_parts p;
    if (!parts)
        return NULL;
    p = *parts;
    if (!tka_parts_in(&p, TK_CAL_GREGORY, &d, NULL))
        return NULL;
    return tk_dur_new_sv(aTHX_ MY_CXT.dstash, &d);
}

static int
tka_duration_from_sv(pTHX_ SV *sv, time_keeper_parts *out)
{
    const tk_duration *d;
    if (!sv || !out || !tk_is_dur(aTHX_ sv))
        return TIME_KEEPER_BAD;
    d = tk_dur_of(aTHX_ sv, TKA_WHAT);
    Zero(out, 1, time_keeper_parts);
    out->months = d->months;
    out->days = d->days;
    out->minutes = d->minutes;
    out->seconds = d->seconds;
    out->nanoseconds = d->nsec;
    out->end_of_month = d->eom == TK_EOM_LIMIT ? TIME_KEEPER_EOM_LIMIT
                      : d->eom == TK_EOM_PRESERVE ? TIME_KEEPER_EOM_PRESERVE : TIME_KEEPER_EOM_WRAP;
    return TIME_KEEPER_OK;
}

static int
tka_locale_code(int locale, const char **out)
{
    if (!out || locale < 0 || locale >= TK_LOCALE_COUNT)
        return TIME_KEEPER_BAD;
    *out = tk_locale_codes[locale].code;
    return TIME_KEEPER_OK;
}

/* A plain date's kind, day and locale: a Date, a YearMonth (its first day)
 * or a MonthDay (its day in 1972). */
static int
tka_date_from_sv(pTHX_ SV *sv, int *kind, int64_t *epoch_days, int *locale)
{
    const tk_value *v;
    int k;
    if (!sv)
        return TIME_KEEPER_BAD;
    k = tk_plain_kind_of(aTHX_ sv);
    if (k != TK_KIND_DATE && k != TK_KIND_YEAR_MONTH && k != TK_KIND_MONTH_DAY)
        return TIME_KEEPER_BAD;
    v = (const tk_value *)SvPVX(SvRV(sv));
    if (!tk_plain_sound((tk_value *)v, k))
        return TIME_KEEPER_BAD;
    if (kind)
        *kind = k;
    if (epoch_days)
        *epoch_days = v->inst.sec / TK_SECS_PER_DAY;
    if (locale)
        *locale = v->locale;
    return TIME_KEEPER_OK;
}

static SV *
tka_new_date_sv(pTHX_ int kind, int64_t epoch_days, int locale, HV *stash)
{
    tk_value v;
    int64_t y;
    unsigned m, d;
    if (kind != TK_KIND_DATE && kind != TK_KIND_YEAR_MONTH && kind != TK_KIND_MONTH_DAY)
        return NULL;
    if (locale < 0 || locale >= TK_LOCALE_COUNT)
        return NULL;
    if (epoch_days < tk_days_from_civil(TK_YEAR_MIN, 1, 1) || epoch_days > tk_days_from_civil(TK_YEAR_MAX, 12, 31))
        return NULL;
    tk_civil_from_days(epoch_days, &y, &m, &d);
    tk_plain_make(aTHX_ &v, kind, y, m, d, (uint16_t)locale, TKA_WHAT " new_date_sv");
    return tk_value_new_sv(aTHX_ stash ? stash : tk_plain_stash(aTHX_ kind), &v);
}

typedef struct tka_weekend_arg {
    int locale;
    const tk_locale_data *d;
} tka_weekend_arg;

static void
tka_weekend_loading(pTHX_ void *p)
{
    tka_weekend_arg *a = (tka_weekend_arg *)p;
    a->d = tk_locale_get(aTHX_ (unsigned)a->locale);
}

static int
tka_locale_weekend(pTHX_ int locale, int *start, int *end, char *err, size_t errlen)
{
    tka_weekend_arg a;
    if (locale < 0 || locale >= TK_LOCALE_COUNT) {
        tka_err(err, errlen, "an argument is not one", 22);
        return TIME_KEEPER_BAD;
    }
    a.locale = locale;
    a.d = NULL;
    if (!tka_guard(aTHX_ tka_weekend_loading, &a, err, errlen) || !a.d)
        return TIME_KEEPER_BAD;
    if (start)
        *start = a.d->weekend_start;
    if (end)
        *end = a.d->weekend_end;
    return TIME_KEEPER_OK;
}

static int
tka_next_change(pTHX_ const time_keeper_instant *in, const time_keeper_zone *zone, time_keeper_instant *at,
                int32_t *before, int32_t *after)
{
    tk_zone_spec z;
    tk_instant t;
    const tkz_abi *a;
    int id;
    int32_t off;
    if (!in || !at || in->nsec < 0 || in->nsec >= TK_NSECS_PER_SEC || !tka_zone_in(aTHX_ zone, &z))
        return TIME_KEEPER_BAD;
    t.sec = in->sec;
    t.nsec = in->nsec;
    if (!tk_instant_valid(&t))
        return TIME_KEEPER_BAD;
    if (z.zone < TK_ZONE_NAMED)
        return TIME_KEEPER_RANGE;
    a = tk_zone_abi(aTHX);
    id = z.zone - TK_ZONE_NAMED;
    t.sec = (a->next_change)(id, in->sec);
    t.nsec = 0;
    if (t.sec == TKZ_NO_CHANGE || !tk_instant_valid(&t))
        return TIME_KEEPER_RANGE;
    at->sec = t.sec;
    at->nsec = 0;
    if (before) {
        off = 0;
        (a->offset_at)(id, t.sec - 1, &off, NULL, NULL);
        *before = off;
    }
    if (after) {
        off = 0;
        (a->offset_at)(id, t.sec, &off, NULL, NULL);
        *after = off;
    }
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
    tka_tai_minus_utc,
    tka_calendar_find,
    tka_calendar_id,
    tka_cal_fields,
    tka_cal_from_fields,
    tka_format_cal,
    tka_strftime_cal,
    tka_new_sv_cal,
    tka_from_sv_cal,
    tka_plus,
    tka_truncate,
    tka_end_of,
    tka_adjust_dow,
    tka_nth_in_month,
    tka_with_time,
    tka_parse_cldr,
    tka_new_duration_sv,
    tka_duration_from_sv,
    tka_locale_code,
    tka_date_from_sv,
    tka_new_date_sv,
    tka_locale_weekend,
    tka_next_change
};

#endif
