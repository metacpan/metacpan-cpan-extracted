#ifndef TK_PLAIN_H
#define TK_PLAIN_H

/* Plain values: a date with no time of day, a year and month, and a month
 * and day. Each is a tk_value, floating, at midnight of the day it names,
 * with its kind in the struct and blessed into its own class. Nothing is
 * inherited: a Time::Keeper method given a plain value refuses it, and a
 * plain class offers only what makes sense for it. The engine is shared:
 * a plain value is projected back to its kind after any arithmetic. */

static const char *const tk_plain_class[TK_KIND_COUNT] = {
    "Time::Keeper", "Time::Keeper::Date", "Time::Keeper::Time", "Time::Keeper::YearMonth", "Time::Keeper::MonthDay"
};
static const char *const tk_plain_noun[TK_KIND_COUNT] = {
    "value", "date", "time of day", "year and month", "month and day"
};

/* Temporal's reference year for a month and day: a leap year, so 29 February is one. */
#define TK_MONTH_DAY_YEAR 1972

static HV *
tk_plain_stash(pTHX_ int kind)
{
    dMY_CXT;
    return MY_CXT.pstash[kind];
}

/* The class a constructor was called on: its own stash, or the kind's. */
static HV *
tk_plain_stash_for(pTHX_ SV *class_or_obj, int kind)
{
    if (SvROK(class_or_obj) && SvOBJECT(SvRV(class_or_obj)))
        return SvSTASH(SvRV(class_or_obj));
    if (SvPOK(class_or_obj) && strEQ(SvPV_nolen(class_or_obj), tk_plain_class[kind]))
        return tk_plain_stash(aTHX_ kind);
    return gv_stashsv(class_or_obj, GV_ADD);
}

/* The kind of a plain value, or -1 for anything else. */
static int
tk_plain_kind_of(pTHX_ SV *sv)
{
    SV *in;
    int k;
    dMY_CXT;
    if (!SvROK(sv))
        return -1;
    in = SvRV(sv);
    if (!SvOBJECT(in) || SvROK(in) || !SvPOK(in) || SvCUR(in) != sizeof(tk_value))
        return -1;
    for (k = 1; k < TK_KIND_COUNT; k++)
        if (SvSTASH(in) == MY_CXT.pstash[k])
            return k;
    for (k = 1; k < TK_KIND_COUNT; k++)
        if (sv_derived_from(sv, tk_plain_class[k]))
            return k;
    return -1;
}

/* The kind a class name or object stands for, or -1. */
static int
tk_plain_kind_of_class(pTHX_ SV *class)
{
    int k;
    for (k = 1; k < TK_KIND_COUNT; k++)
        if (sv_derived_from(class, tk_plain_class[k]))
            return k;
    return -1;
}

/* 1 when the bytes are a sound plain value of the kind. */
static int
tk_plain_sound(tk_value *v, int kind)
{
    const tk_civil *c;
    if (v->kind != kind || v->zone != TK_ZONE_FLOATING || v->utoff != 0 || v->calendar != 0
        || !tk_instant_valid(&v->inst))
        return 0;
    if (kind == TK_KIND_TIME)
        return v->inst.sec >= 0 && v->inst.sec < 86400 && v->inst.nsec < TK_NSECS_PER_SEC;
    if (v->inst.nsec != 0 || v->inst.sec % 86400 != 0)
        return 0;
    c = tk_value_civil(v);
    if (kind == TK_KIND_YEAR_MONTH && c->day != 1)
        return 0;
    if (kind == TK_KIND_MONTH_DAY && c->year != TK_MONTH_DAY_YEAR)
        return 0;
    return 1;
}

static tk_value *
tk_plain_of(pTHX_ SV *sv, int kind, const char *what)
{
    tk_value *v;
    if (tk_plain_kind_of(aTHX_ sv) != kind)
        croak("%s: not a %s", what, tk_plain_class[kind]);
    v = (tk_value *)SvPVX(SvRV(sv));
    if (!tk_plain_sound(v, kind))
        croak("%s: a damaged %s", what, tk_plain_class[kind]);
    return v;
}

/* A plain value of the kind for the date given. The parts a kind does not
 * keep are set to what it keeps instead: the first of the month, the
 * reference year. */
static void
tk_plain_make(pTHX_ tk_value *out, int kind, int64_t y, unsigned m, unsigned d, uint16_t locale, const char *what)
{
    tk_zone_spec z;
    z.zone = TK_ZONE_FLOATING;
    z.fixed = 0;
    if (kind == TK_KIND_YEAR_MONTH)
        d = 1;
    if (kind == TK_KIND_MONTH_DAY)
        y = TK_MONTH_DAY_YEAR;
    if (y < TK_YEAR_MIN || y > TK_YEAR_MAX)
        croak("%s: the year %" IVdf " is out of range", what, (IV)y);
    if (m < 1 || m > 12)
        croak("%s: there is no month %u", what, m);
    if (d < 1 || d > tk_days_in_month(y, m)) {
        if (kind == TK_KIND_MONTH_DAY)
            croak("%s: --%02u-%02u is not a day of any year", what, m, d);
        croak("%s: %04" IVdf "-%02u has no day %u", what, (IV)y, m, d);
    }
    tk_value_from_local(aTHX_ out, &z, y, m, d, 0, 0, 0, 0, TK_GAP_DEFAULT, TK_OVERLAP_DEFAULT, what);
    out->kind = (uint8_t)kind;
    out->locale = locale;
}

/* ---- a time of day ---------------------------------------------------------- */

/* A time of day: a floating value on 1 January 1970. Second 60 is refused:
 * a leap second is an instant on one particular day. */
static void
tk_time_make(pTHX_ tk_value *out, int64_t h, int64_t mi, int64_t s, int32_t ns, uint16_t locale, const char *what)
{
    tk_zone_spec z;
    z.zone = TK_ZONE_FLOATING;
    z.fixed = 0;
    if (s == 60)
        croak("%s: a time of day has no second 60: a leap second is an instant", what);
    tk_value_from_local(aTHX_ out, &z, 1970, 1, 1, h, mi, s, ns, TK_GAP_DEFAULT, TK_OVERLAP_DEFAULT, what);
    out->kind = TK_KIND_TIME;
    out->locale = locale;
}

/* The time of day a value's wall clock shows; during a leap second, the
 * last nanosecond before it, so every value has one. */
static void
tk_time_project(pTHX_ tk_value *out, tk_value *v, const char *what)
{
    const tk_civil *c = tk_value_civil(v);
    if (c->second == 60)
        tk_time_make(aTHX_ out, 23, 59, 59, TK_NSECS_PER_SEC - 1, v->locale, what);
    else
        tk_time_make(aTHX_ out, c->hour, c->minute, c->second, c->nsec, v->locale, what);
}

/* A duration added to a time of day wraps at midnight: minutes modulo a
 * day's worth and seconds likewise before they are combined, so a duration
 * near the limit cannot overflow before the modulus. */
static void
tk_time_plus(pTHX_ tk_value *out, tk_value *v, const tk_duration *d, const char *what)
{
    const int64_t day = (int64_t)86400 * TK_NSECS_PER_SEC;
    int64_t n;
    if (d->months || d->days)
        croak("%s: a time of day has no calendar, so days and months cannot be added to it", what);
    n = ((d->minutes % 1440) * 60 + d->seconds % 86400) * TK_NSECS_PER_SEC + d->nsec;
    n += v->inst.sec * TK_NSECS_PER_SEC + v->inst.nsec;
    n %= day;
    if (n < 0)
        n += day;
    tk_time_make(aTHX_ out, n / ((int64_t)3600 * TK_NSECS_PER_SEC), n / ((int64_t)60 * TK_NSECS_PER_SEC) % 60,
                 n / TK_NSECS_PER_SEC % 60, (int32_t)(n % TK_NSECS_PER_SEC), v->locale, what);
}

/* HH:MM:SS with a fraction of exactly `digits` digits, or the fewest of 3,
 * 6 or 9 that are exact when digits is -1. */
static SV *
tk_time_iso8601_sv(pTHX_ tk_value *v, int digits)
{
    char buf[32];
    const tk_civil *c = tk_value_civil(v);
    int n = sprintf(buf, "%02u:%02u:%02u", (unsigned)c->hour, (unsigned)c->minute, (unsigned)c->second);
    if (digits < 0)
        n += tk_fmt_fraction(buf + n, c->nsec);
    else if (digits > 0) {
        char f[16];
        sprintf(f, "%09d", (int)c->nsec);
        buf[n++] = '.';
        memcpy(buf + n, f, (size_t)digits);
        n += digits;
    }
    return newSVpvn(buf, (STRLEN)n);
}

/* The plain value of the kind that a value's wall clock gives. */
static void
tk_plain_project(pTHX_ tk_value *out, int kind, tk_value *v, const char *what)
{
    const tk_civil *c;
    if (kind == TK_KIND_TIME) {
        tk_time_project(aTHX_ out, v, what);
        return;
    }
    c = tk_value_civil(v);
    tk_plain_make(aTHX_ out, kind, c->year, c->month, c->day, v->locale, what);
}

/* ISO 8601: 2026-10-15, 2026-10, --10-15; years outside 0000 to 9999 as
 * tk_fmt_year writes them. */
static SV *
tk_plain_iso8601_sv(pTHX_ tk_value *v)
{
    char buf[48];
    int n;
    const tk_civil *c;
    if (v->kind == TK_KIND_TIME)
        return tk_time_iso8601_sv(aTHX_ v, -1);
    c = tk_value_civil(v);
    if (v->kind == TK_KIND_MONTH_DAY)
        n = sprintf(buf, "--%02u-%02u", (unsigned)c->month, (unsigned)c->day);
    else {
        n = tk_fmt_year(buf, c->year);
        if (v->kind == TK_KIND_YEAR_MONTH)
            n += sprintf(buf + n, "-%02u", (unsigned)c->month);
        else
            n += sprintf(buf + n, "-%02u-%02u", (unsigned)c->month, (unsigned)c->day);
    }
    return newSVpvn(buf, (STRLEN)n);
}

/* ---- pattern letters ----------------------------------------------------- */

/* What a CLDR pattern letter needs of a value, or NULL for a letter the
 * formatter will judge. */
static const char *
tk_plain_cldr_needs(char ch)
{
    if (strchr("abBhHKkmsSAjJC", ch)) return "a time of day";
    if (strchr("zZOvVXx", ch))        return "a zone";
    if (strchr("dDFgEecwWY", ch))     return "a day";
    if (strchr("GyuUrQq", ch))        return "a year";
    if (strchr("MLl", ch))            return "a month";
    return NULL;
}

static const char *
tk_plain_strftime_needs(char ch)
{
    if (ch == 'c')                     return "a date as well as a time of day";
    if (strchr("HIklMSpPNTRrX", ch))  return "a time of day";
    if (strchr("zZ", ch))              return "a zone";
    if (ch == 's')                     return "an instant";
    if (strchr("dejuwaAUWVGgFDx", ch)) return "a day";
    if (strchr("YCy", ch))             return "a year";
    if (strchr("mBbh", ch))            return "a month";
    return NULL;
}

/* The letters each kind can write. */
static const char *const tk_plain_cldr_ok[TK_KIND_COUNT] = {
    "", "GyYuUrQqMLlwWdDFgEec", "abBhHKkmsSAjJC", "GyuUrQqML", "MLd"
};
static const char *const tk_plain_strftime_ok[TK_KIND_COUNT] = {
    "", "YCymBbhdejuwaAUWVGgFDx", "HIklMSpPNTRrX", "YCymBbh", "mBbhde"
};

static void
tk_plain_check_cldr(pTHX_ int kind, const char *p, STRLEN len, const char *what)
{
    STRLEN i;
    int quoted = 0;
    for (i = 0; i < len; i++) {
        char ch = p[i];
        const char *needs;
        if (ch == '\'') {
            if (i + 1 < len && p[i + 1] == '\'') { i++; continue; }
            quoted = !quoted;
            continue;
        }
        if (quoted || !isALPHA(ch))
            continue;
        needs = tk_plain_cldr_needs(ch);
        if (needs && !strchr(tk_plain_cldr_ok[kind], ch))
            croak("%s: the pattern letter '%c' needs %s, and a %s has none", what, ch, needs, tk_plain_noun[kind]);
    }
}

static void
tk_plain_check_strftime(pTHX_ int kind, const char *p, STRLEN len, const char *what)
{
    STRLEN i;
    for (i = 0; i < len; i++) {
        char ch;
        const char *needs;
        if (p[i] != '%')
            continue;
        i++;
        while (i < len && strchr("-_0^#", p[i]))
            i++;
        while (i < len && isDIGIT(p[i]))
            i++;
        if (i < len && (p[i] == 'E' || p[i] == 'O'))
            i++;
        if (i >= len)
            break;
        ch = p[i];
        if (ch == '{') {
            while (i < len && p[i] != '}')
                i++;
            continue;
        }
        needs = tk_plain_strftime_needs(ch);
        if (needs && !strchr(tk_plain_strftime_ok[kind], ch))
            croak("%s: %%%c needs %s, and a %s has none", what, ch, needs, tk_plain_noun[kind]);
    }
}

/* A pattern formatted, as format and strftime do, after the letter check
 * when `check` is set; the locale's own date formats need none. */
static SV *
tk_plain_format_sv(pTHX_ SV *self, tk_value *v, int cldr, int check, const char *p, STRLEN len, const char *what)
{
    tk_out o;
    if (check && cldr)
        tk_plain_check_cldr(aTHX_ v->kind, p, len, what);
    else if (check)
        tk_plain_check_strftime(aTHX_ v->kind, p, len, what);
    o.sv = newSV(len * 2 + 40);
    sv_setpvs(o.sv, "");
    o.utf8 = 0;
    o.digits = NULL;
    if (cldr)
        tk_format_cldr(aTHX_ &o, self, v, tk_locale_of(v), p, len, NULL, NULL);
    else
        tk_strftime(aTHX_ &o, self, v, tk_locale_of(v), p, len);
    if (o.utf8)
        SvUTF8_on(o.sv);
    return o.sv;
}

/* ---- arithmetic ----------------------------------------------------------- */

/* What plus and minus take on a plain value: calendar units, as a duration
 * or by name, and end_of_month; no clock units, no gap or overlap. 1 when
 * end_of_month was given, so minus keeps it. */
static int
tk_plain_plus_args(pTHX_ SV **st, I32 n, int kind, tk_duration *d, const char *what)
{
    tk_dur_args a;
    int eom_given;
    if (n >= 1 && tk_is_dur(aTHX_ st[0])) {
        if (n > 1)
            croak("%s: a duration takes no other arguments", what);
        *d = *tk_dur_of(aTHX_ st[0], what);
        eom_given = 1;
    }
    else {
        tk_dur_args_parse(aTHX_ st, n, TK_D_UNITS | TK_D(TK_D_EOM), &a, what);
        tk_dur_from_args(aTHX_ &a, d, what);
        eom_given = a.v[TK_D_EOM] != NULL;
    }
    PERL_UNUSED_VAR(kind);
    return eom_given;
}

/* A duration added to a plain value of the kind: a time of day wraps, a
 * date and a year and month take only the units they have, a month and
 * day takes none. */
static void
tk_plain_add(pTHX_ tk_value *out, int kind, tk_value *v, const tk_duration *d, const char *what)
{
    if (kind == TK_KIND_MONTH_DAY)
        croak("%s: a month and day takes no arithmetic", what);
    if (kind == TK_KIND_TIME) {
        tk_time_plus(aTHX_ out, v, d, what);
        return;
    }
    if (d->minutes || d->seconds || d->nsec)
        croak("%s: a %s has no clock, so hours, minutes and seconds cannot be added to it", what, tk_plain_noun[kind]);
    if (kind == TK_KIND_YEAR_MONTH && d->days)
        croak("%s: a year and month has no day, so days and weeks cannot be added to it", what);
    tk_value_plus(aTHX_ out, v, d, TK_GAP_DEFAULT, TK_OVERLAP_DEFAULT, what);
    tk_plain_project(aTHX_ out, kind, out, what);
}

/* ---- freezing ------------------------------------------------------------- */

static SV *
tk_plain_freeze_sv(pTHX_ const tk_value *v)
{
    SV *out = newSVpvf("tkp1 %d %" IVdf " %d", (int)v->kind, (IV)v->inst.sec, (int)v->inst.nsec);
    if (v->locale && v->locale < TK_LOCALE_COUNT)
        sv_catpvf(out, " %s", tk_locale_codes[v->locale].code);
    return out;
}

static void
tk_plain_thaw(pTHX_ SV *frozen, int kind, tk_value *v, const char *what)
{
    const char *s, *p, *q;
    STRLEN len;
    tk_instant t;
    tk_zone_spec z;
    long k, ns;
    SV *num;
    uint16_t lid = 0;

    s = SvPV(frozen, len);
    if (len < 5 || memNE(s, "tkp1 ", 5))
        croak("%s: not a frozen %s", what, tk_plain_class[kind]);
    k = strtol(s + 5, (char **)&p, 10);
    if (*p != ' ' || k != kind)
        croak("%s: not a frozen %s", what, tk_plain_class[kind]);
    q = strchr(p + 1, ' ');
    if (!q)
        croak("%s: not a frozen %s", what, tk_plain_class[kind]);
    num = sv_2mortal(newSVpvn(p + 1, q - (p + 1)));
    if (!tk_sv_to_i64(aTHX_ num, &t.sec))
        croak("%s: not a frozen %s", what, tk_plain_class[kind]);
    ns = strtol(q + 1, (char **)&p, 10);
    if ((*p != ' ' && *p != '\0') || ns < 0 || ns >= TK_NSECS_PER_SEC)
        croak("%s: not a frozen %s", what, tk_plain_class[kind]);
    t.nsec = (int32_t)ns;
    if (*p == ' ')
        lid = tk_locale_id_from_sv(aTHX_ sv_2mortal(newSVpvn(p + 1, len - (p + 1 - s))), what);
    z.zone = TK_ZONE_FLOATING;
    z.fixed = 0;
    if (!tk_instant_valid(&t))
        croak("%s: out of range", what);
    tk_value_init(aTHX_ v, &t, &z);
    v->kind = (uint8_t)kind;
    v->locale = lid;
    if (!tk_plain_sound(v, kind))
        croak("%s: not a frozen %s", what, tk_plain_class[kind]);
}

/* ---- parsing -------------------------------------------------------------- */

/* --MM-DD, --MMDD or MM-DD. */
static int
tk_plain_parse_md(const char *s, STRLEN len, unsigned *m, unsigned *d)
{
    STRLEN i = 0;
    if (len >= 2 && s[0] == '-' && s[1] == '-')
        i = 2;
    if (len - i < 4 || !isDIGIT(s[i]) || !isDIGIT(s[i + 1]))
        return 0;
    *m = (unsigned)((s[i] - '0') * 10 + (s[i + 1] - '0'));
    i += 2;
    if (s[i] == '-')
        i++;
    if (len - i != 2 || !isDIGIT(s[i]) || !isDIGIT(s[i + 1]))
        return 0;
    *d = (unsigned)((s[i] - '0') * 10 + (s[i + 1] - '0'));
    return 1;
}

/* parse (mode 0), strptime (1) and parse_cldr (2) for a plain kind: the
 * core's parser, then the fields a kind keeps. Under parse the text may
 * say nothing the kind cannot hold; under a pattern, the pattern says what
 * the text holds and the kind says what is kept. */
static void
tk_plain_parse(pTHX_ tk_value *out, int kind, int mode, SV *text, SV *pat_sv, uint16_t lid, const char *what)
{
    tk_cursor c;
    tk_fields f;
    tk_value v;
    SV *t, *scan, *fl;
    STRLEN len, plen = 0;
    const char *s, *p = NULL;
    int ok;

    if (!SvOK(text))
        croak("%s: no text", what);
    t = tk_utf8_text(aTHX_ text);
    if (mode) {
        SV *pat = tk_utf8_text(aTHX_ pat_sv);
        p = SvPV(pat, plen);
    }
    if (mode == 0 && kind == TK_KIND_TIME) {
        tk_cursor tc;
        tk_fields tf;
        s = SvPV(t, len);
        tk_cursor_init(&tc, s, len);
        Zero(&tf, 1, tk_fields);
        if (tk_peek(&tc) == 'T')
            tc.i++;
        if (!tk_iso_time(&tc, &tf))
            tk_parse_croak(aTHX_ what, t, t, &tc);
        if (!tk_at_end(&tc)) {
            char ch = tk_peek(&tc);
            if (ch == 'Z' || ch == '+' || ch == '-' || ch == '[')
                croak("%s: '%s' names an offset or a zone, and a time of day has none", what, s);
            tk_fail(&tc, "text was left over");
            tk_parse_croak(aTHX_ what, t, t, &tc);
        }
        if (tf.hour24)
            croak("%s: '%s': 24:00 is the end of a day, not a time of day", what, s);
        tk_time_make(aTHX_ out, tf.hour, tf.minute, tf.second, tf.nsec, lid, what);
        return;
    }
    if (mode == 0 && kind == TK_KIND_MONTH_DAY) {
        unsigned m, d;
        s = SvPV(t, len);
        if (!tk_plain_parse_md(s, len, &m, &d))
            croak("%s: cannot parse '%s' as --MM-DD", what, s);
        tk_plain_make(aTHX_ out, kind, TK_MONTH_DAY_YEAR, m, d, lid, what);
        return;
    }
    scan = mode ? tk_ascii_digits(aTHX_ t) : t;
    s = SvPV(scan, len);
    tk_cursor_init(&c, s, len);
    Zero(&f, 1, tk_fields);
    if (mode == 0)
        ok = tk_parse_any(&c, &f);
    else if (mode == 1)
        ok = tk_strptime(&c, &f, tk_locale_get(aTHX_ lid), p, plen);
    else
        ok = tk_parse_cldr(&c, &f, tk_locale_get(aTHX_ lid), p, plen) && (tk_at_end(&c) || tk_fail(&c, "text was left over"));
    if (!ok)
        tk_parse_croak(aTHX_ what, t, scan, &c);
    if (mode == 0) {
        if (f.has_hour || f.has_minute || f.has_second || f.has_ampm)
            croak("%s: '%s' has a time of day, and a %s has none", what, SvPV_nolen(t), tk_plain_noun[kind]);
        if (f.has_offset || f.utc || f.zone || f.abbr)
            croak("%s: '%s' names a zone or an offset, and a %s has none", what, SvPV_nolen(t), tk_plain_noun[kind]);
        if (f.has_epoch)
            croak("%s: '%s' is an instant, and a %s is not one", what, SvPV_nolen(t), tk_plain_noun[kind]);
        if (kind == TK_KIND_YEAR_MONTH) {
            if (f.has_day || f.has_doy || f.has_isoweek || f.has_wday)
                croak("%s: '%s' has a day, and a year and month has none", what, SvPV_nolen(t));
            if (!f.has_month)
                croak("%s: '%s' has no month", what, SvPV_nolen(t));
        }
    }
    if (kind == TK_KIND_MONTH_DAY) {
        f.year = TK_MONTH_DAY_YEAR;
        f.has_year = 1;
        f.has_century = f.has_y2 = f.era_bc = 0;
    }
    else if (kind == TK_KIND_YEAR_MONTH && f.has_day)
        f.day = 1;
    fl = sv_2mortal(newSVpvs("floating"));
    tk_fields_to_value(aTHX_ &v, &f, fl, TK_GAP_DEFAULT, TK_OVERLAP_DEFAULT, what, SvPV_nolen(t));
    v.locale = lid;
    tk_plain_project(aTHX_ out, kind, &v, what);
}

#endif
