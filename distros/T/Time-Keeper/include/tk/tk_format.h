#ifndef TK_FORMAT_H
#define TK_FORMAT_H

/* Formatting: strftime, CLDR patterns, and the fixed forms of RFC 2822,
 * 3339, 9557 and 9110. One pass over the pattern, appending to an SV.
 *
 * strftime follows DateTime's table of conversions, with glibc's flags
 * (- _ 0 ^) and a width for numbers. CLDR patterns follow the CLDR
 * specification (Unicode TR35); where DateTime's format_cldr departs from
 * it, the specification is followed and the POD lists the differences. */

/* A character of a method name: isWORDCHAR is 5.14 and later. */
static int
tk_is_word(unsigned char ch)
{
    return (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9') || ch == '_';
}

/* Whether a string is ASCII: is_ascii_string is not in 5.10. */
static int
tk_is_ascii(const char *s)
{
    for (; *s; s++)
        if ((unsigned char)*s >= 0x80)
            return 0;
    return 1;
}

/* A string as an SV, UTF-8 where it has to be, or undef for NULL. */
static SV *
tk_newSVstr(pTHX_ const char *s)
{
    SV *sv;
    if (!s)
        return newSV(0);
    sv = newSVpv(s, 0);
    if (!tk_is_ascii(s))
        SvUTF8_on(sv);
    return sv;
}

/* Append and note when what was appended is not ASCII, so the result can
 * be flagged as characters. */
typedef struct tk_out {
    SV  *sv;
    int  utf8;
    const char *const *digits;   /* the locale's 0 to 9, or NULL for ASCII */
    const char *nums;            /* the numbering spec of the pattern being written, or NULL */
    STRLEN nums_len;
} tk_out;

static void
tk_out_cat(pTHX_ tk_out *o, const char *s, STRLEN len)
{
    STRLEN i;
    STRLEN cur = SvCUR(o->sv);
    for (i = 0; i < len && !o->utf8; i++)
        if ((unsigned char)s[i] >= 0x80)
            o->utf8 = 1;
    if (cur + len + 1 > SvLEN(o->sv))
        SvGROW(o->sv, (cur + len + 1) * 2);
    Copy(s, SvPVX(o->sv) + cur, len, char);
    SvCUR_set(o->sv, cur + len);
    SvPVX(o->sv)[cur + len] = '\0';
}

static void
tk_out_str(pTHX_ tk_out *o, const char *s)
{
    tk_out_cat(aTHX_ o, s, strlen(s));
}

/* ASCII digits written in the locale's digits, when it has its own. */
/* The text with the leap pattern round it ({0}bis), or as it is. */
static void
tk_out_leap_wrap(pTHX_ tk_out *o, const char *pattern, const char *text, STRLEN len)
{
    const char *at = pattern ? strstr(pattern, "{0}") : NULL;
    if (!at) {
        tk_out_cat(aTHX_ o, text, len);
        return;
    }
    tk_out_cat(aTHX_ o, pattern, (STRLEN)(at - pattern));
    tk_out_cat(aTHX_ o, text, len);
    tk_out_str(aTHX_ o, at + 3);
}

static void
tk_out_digits(pTHX_ tk_out *o, const char *s, STRLEN len)
{
    STRLEN i, from = 0;
    if (!o->digits) {
        tk_out_cat(aTHX_ o, s, len);
        return;
    }
    for (i = 0; i < len; i++)
        if (s[i] >= '0' && s[i] <= '9') {
            if (i > from)
                tk_out_cat(aTHX_ o, s + from, i - from);
            tk_out_str(aTHX_ o, o->digits[s[i] - '0']);
            from = i + 1;
        }
    if (len > from)
        tk_out_cat(aTHX_ o, s + from, len - from);
}

/* An integer padded to a width: pad '0', ' ' or none (0). */
static void
tk_out_num(pTHX_ tk_out *o, int64_t v, int width, char pad)
{
    char buf[48];
    char digits[32];
    int n = 0, len, neg = v < 0;
    uint64_t u = neg ? (uint64_t)0 - (uint64_t)v : (uint64_t)v;
    if (!o->digits && pad == '0' && v >= 0 && ((width == 2 && v < 100) || (width == 4 && v < 10000))) {
        /* the common case, written in place: two or four ASCII digits */
        STRLEN cur = SvCUR(o->sv);
        char *p;
        int k;
        if (cur + 5 > SvLEN(o->sv))
            SvGROW(o->sv, (cur + 5) * 2);
        p = SvPVX(o->sv) + cur;
        for (k = width - 1; k >= 0; k--, u /= 10)
            p[k] = (char)('0' + (int)(u % 10));
        SvCUR_set(o->sv, cur + width);
        p[width] = '\0';
        return;
    }
    do { digits[n++] = (char)('0' + (int)(u % 10)); u /= 10; } while (u);
    len = 0;
    if (neg && pad == '0')
        buf[len++] = '-';
    if (pad && width > n + neg)
        while (len + n + (neg && pad != '0') < width && len < 40)
            buf[len++] = pad;
    if (neg && pad != '0')
        buf[len++] = '-';
    while (n)
        buf[len++] = digits[--n];
    tk_out_digits(aTHX_ o, buf, (STRLEN)len);
}

/* UPPER CASE, for the ^ flag: ASCII letters only. */
static void
tk_out_upper_from(pTHX_ tk_out *o, STRLEN from)
{
    STRLEN i, len;
    char *p = SvPV(o->sv, len);
    for (i = from; i < len; i++)
        if (p[i] >= 'a' && p[i] <= 'z')
            p[i] -= 32;
}

/* +HHMM, or +HHMMSS when there are seconds, as DateTime gives offsets. */
static void
tk_out_offset(pTHX_ tk_out *o, int32_t off, int colon, int seconds_too)
{
    char buf[16];
    int32_t a = off < 0 ? -off : off;
    int n = sprintf(buf, colon ? "%c%02d:%02d" : "%c%02d%02d", off < 0 ? '-' : '+',
                    (int)(a / 3600), (int)(a / 60 % 60));
    if (seconds_too && a % 60)
        n += sprintf(buf + n, colon ? ":%02d" : "%02d", (int)(a % 60));
    tk_out_cat(aTHX_ o, buf, (STRLEN)n);
}

static int64_t
tk_value_epoch(const tk_value *v)
{
    return v->inst.sec + (v->inst.nsec >= TK_NSECS_PER_SEC);
}

static unsigned
tk_hour12(unsigned h)
{
    return h % 12 == 0 ? 12 : h % 12;
}

#include "tk/tk_numbering.h"

/* The nanoseconds truncated to n digits, or padded with zeros past nine. */
static void
tk_out_fraction_digits(pTHX_ tk_out *o, int32_t nsec, int n)
{
    char buf[64];
    int i;
    sprintf(buf, "%09d", (int)nsec);
    for (i = 9; i < n && i < 60; i++)
        buf[i] = '0';
    tk_out_digits(aTHX_ o, buf, (STRLEN)(n < 60 ? n : 60));
}

static void tk_format_cldr(pTHX_ tk_out *o, SV *self, tk_value *v, const tk_locale_data *loc,
                           const char *p, STRLEN len, const char *date_part, const char *time_part);

/* ---- strftime ----------------------------------------------------------- */

static void
tk_strftime(pTHX_ tk_out *o, SV *self, tk_value *v, const tk_locale_data *loc,
            const char *p, STRLEN len)
{
    const tk_civil *c = tk_value_civil(v);
    STRLEN i = 0;
    const tk_calendar *cal = tk_cal_of(v);
    int other = v->calendar != TK_CAL_GREGORY;
    tk_calfields cf;
    const tk_cal_names *cn = NULL;
    int64_t year = c->year;
    unsigned month = c->month, day = c->day, doy = c->doy;
    if (other) {
        tk_value_calfields(aTHX_ v, &cf, "Time::Keeper->strftime");
        cn = tk_cal_names_get(aTHX_ loc, v->calendar);
        year = cf.era_year;
        month = tk_cal_month_slot(cal, &cf);
        day = cf.day;
        doy = cf.doy;
    }

    while (i < len) {
        STRLEN start = i, mark;
        char flag = 0, spec;
        int width = -1, has_width = 0, alt = 0;

        while (i < len && p[i] != '%')
            i++;
        if (i > start)
            tk_out_cat(aTHX_ o, p + start, i - start);
        if (i >= len)
            break;
        start = i++;                         /* at the % */
        if (i < len && p[i] == '{') {
            STRLEN e = i + 1;
            while (e < len && tk_is_word((unsigned char)p[e]))
                e++;
            if (e < len && p[e] == '}' && e > i + 1) {
                SV *name = sv_2mortal(newSVpvn(p + i + 1, e - i - 1));
                if (self && sv_isobject(self) && gv_fetchmethod_autoload(SvSTASH(SvRV(self)), SvPV_nolen(name), 0)) {
                    dSP;
                    int count;
                    ENTER;
                    SAVETMPS;
                    PUSHMARK(SP);
                    XPUSHs(self);
                    PUTBACK;
                    count = call_method(SvPV_nolen(name), G_SCALAR);
                    SPAGAIN;
                    if (count == 1) {
                        SV *r = POPs;
                        STRLEN rl;
                        const char *rs = SvPV(r, rl);
                        if (SvUTF8(r))
                            o->utf8 = 1;
                        sv_catpvn(o->sv, rs, rl);
                    }
                    PUTBACK;
                    FREETMPS;
                    LEAVE;
                }
                else
                    tk_out_cat(aTHX_ o, p + start, e + 1 - start);
                i = e + 1;
                continue;
            }
        }
        while (i < len && (p[i] == '-' || p[i] == '_' || p[i] == '0' || p[i] == '^'))
            flag = p[i++];
        while (i < len && isDIGIT(p[i])) {
            width = (has_width ? width * 10 : 0) + (p[i++] - '0');
            has_width = 1;
            if (width > 64) width = 64;
        }
        if (i < len && (p[i] == 'E' || p[i] == 'O'))
            alt = p[i++] == 'O';
        if (i >= len) {
            tk_out_cat(aTHX_ o, p + start, len - start);
            break;
        }
        spec = p[i++];
        mark = SvCUR(o->sv);

#define TK_NUM(val, w, padc) do {                                         \
            char pc_ = (padc);                                           \
            int  w_ = has_width ? width : (w);                           \
            if (has_width && !pc_) pc_ = '0';                          \
            if (flag == '-') pc_ = 0;                                    \
            else if (flag == '_') pc_ = ' ';                             \
            else if (flag == '0') pc_ = '0';                             \
            if (alt && !loc->ascii_digits) o->digits = loc->s.digits;   \
            tk_out_num(aTHX_ o, (val), w_, pc_);                         \
            o->digits = NULL;                                            \
        } while (0)

        switch (spec) {
        case 'a': tk_out_str(aTHX_ o, loc->s.days[TK_CTX_FORMAT][TK_W_ABBR][c->dow - 1]); break;
        case 'A': tk_out_str(aTHX_ o, loc->s.days[TK_CTX_FORMAT][TK_W_WIDE][c->dow - 1]); break;
        case 'b':
        case 'h':
        case 'B': {
            int w = spec == 'B' ? TK_W_WIDE : TK_W_ABBR;
            if (other) {
                const char *name = tk_cal_month_name(cn, loc, cal, &cf, TK_CTX_FORMAT, w);
                tk_out_leap_wrap(aTHX_ o, cf.leap_month ? tk_cal_leap_pattern(cn, TK_CTX_FORMAT, w, 0) : NULL, name, strlen(name));
            }
            else
                tk_out_str(aTHX_ o, loc->s.months[TK_CTX_FORMAT][w][c->month - 1]);
            break;
        }
        case 'c': {
            const char *dt = other ? tk_cal_date_format(cn, loc, TK_LEN_MEDIUM, 1) : loc->s.datetime_formats[TK_LEN_MEDIUM];
            const char *df = other ? tk_cal_date_format(cn, loc, TK_LEN_MEDIUM, 0) : loc->s.date_formats[TK_LEN_MEDIUM];
            tk_format_cldr(aTHX_ o, self, v, loc, dt, strlen(dt), df, loc->s.time_formats[TK_LEN_MEDIUM]);
            break;
        }
        case 'x': {
            const char *df = other ? tk_cal_date_format(cn, loc, TK_LEN_MEDIUM, 0) : loc->s.date_formats[TK_LEN_MEDIUM];
            tk_format_cldr(aTHX_ o, self, v, loc, df, strlen(df), NULL, NULL);
            break;
        }
        case 'X': tk_format_cldr(aTHX_ o, self, v, loc, loc->s.time_formats[TK_LEN_MEDIUM], strlen(loc->s.time_formats[TK_LEN_MEDIUM]), NULL, NULL); break;
        case 'C': TK_NUM(year / 100, 0, 0); break;
        case 'd': TK_NUM(day, 2, '0'); break;
        case 'D': tk_strftime(aTHX_ o, self, v, loc, "%m/%d/%y", 8); break;
        case 'e': TK_NUM(day, 2, ' '); break;
        case 'F': tk_strftime(aTHX_ o, self, v, loc, "%Y-%m-%d", 8); break;
        case 'g':
        case 'G': {
            int64_t wy;
            unsigned w;
            tk_iso_week(c->year, c->month, c->day, &wy, &w);
            if (spec == 'G')
                TK_NUM(wy, 0, 0);
            else {
                char buf[24];
                int n = sprintf(buf, "%" IVdf, (IV)wy);
                tk_out_cat(aTHX_ o, n > 2 ? buf + n - 2 : buf, (STRLEN)(n > 2 ? 2 : n));
            }
            break;
        }
        case 'H': TK_NUM(c->hour, 2, '0'); break;
        case 'I': TK_NUM(tk_hour12(c->hour), 2, '0'); break;
        case 'j': TK_NUM(doy, 3, '0'); break;
        case 'k': TK_NUM(c->hour, 2, ' '); break;
        case 'l': TK_NUM(tk_hour12(c->hour), 2, ' '); break;
        case 'm': TK_NUM(month, 2, '0'); break;
        case 'M': TK_NUM(c->minute, 2, '0'); break;
        case 'n': tk_out_cat(aTHX_ o, "\n", 1); break;
        case 'N': tk_out_fraction_digits(aTHX_ o, c->nsec, has_width ? (width ? width : 9) : 9); break;
        case 'p': tk_out_str(aTHX_ o, loc->s.periods[TK_W_ABBR][c->hour >= 12]); break;
        case 'P': {
            STRLEN at = SvCUR(o->sv), k, l;
            char *s;
            tk_out_str(aTHX_ o, loc->s.periods[TK_W_ABBR][c->hour >= 12]);
            s = SvPV(o->sv, l);
            for (k = at; k < l; k++)
                if (s[k] >= 'A' && s[k] <= 'Z') s[k] += 32;
            break;
        }
        case 'r': tk_strftime(aTHX_ o, self, v, loc, "%I:%M:%S %p", 11); break;
        case 'R': tk_strftime(aTHX_ o, self, v, loc, "%H:%M", 5); break;
        case 's': TK_NUM(tk_value_epoch(v), 0, 0); break;
        case 'S': TK_NUM(c->second, 2, '0'); break;
        case 't': tk_out_cat(aTHX_ o, "\t", 1); break;
        case 'T': tk_strftime(aTHX_ o, self, v, loc, "%H:%M:%S", 8); break;
        case 'u': TK_NUM(c->dow, 0, 0); break;
        case 'U': TK_NUM(tk_week_number_sunday(c->year, c->month, c->day), 2, '0'); break;
        case 'V': {
            int64_t wy;
            unsigned w;
            tk_iso_week(c->year, c->month, c->day, &wy, &w);
            TK_NUM(w, 2, '0');
            break;
        }
        case 'w': TK_NUM(c->dow % 7, 0, 0); break;
        case 'W': TK_NUM(tk_week_number_monday(c->year, c->month, c->day), 2, '0'); break;
        case 'y': {
            int64_t a = year < 0 ? -year : year;
            TK_NUM(a % 100, 2, '0');
            break;
        }
        case 'Y':
            if (!has_width && !flag && year >= 1000 && year <= 9999)
                TK_NUM(year, 4, '0');
            else
                TK_NUM(year, 0, 0);
            break;
        case 'z': tk_out_offset(aTHX_ o, v->utoff, 0, 1); break;
        case 'Z': {
            SV *abbr = sv_2mortal(tk_zone_abbr_sv(aTHX_ v));
            if (v->zone == TK_ZONE_FLOATING)
                tk_out_str(aTHX_ o, "floating");
            else
                tk_out_cat(aTHX_ o, SvPVX(abbr), SvCUR(abbr));
            break;
        }
        case '%': tk_out_cat(aTHX_ o, "%", 1); break;
        default:
            /* a conversion it does not know is left as it was */
            tk_out_cat(aTHX_ o, p + start, i - start);
            break;
        }
#undef TK_NUM
        if (flag == '^')
            tk_out_upper_from(aTHX_ o, mark);
    }
}

/* ---- CLDR patterns --------------------------------------------------------- */

/* CLDR's localised GMT format: GMT+5, GMT+05:30 in the long form, the
 * locale's own word and digits ("UTC+5" in French), and its word for zero
 * ("GMT"). The short form drops a leading zero of the hour, and the
 * minutes when they are zero; seconds are written when there are any. */
static void
tk_out_gmt(pTHX_ tk_out *o, const tk_locale_data *loc, int32_t off, int long_form)
{
    const char *fmt = loc->s.zone_formats[TK_ZF_GMT];
    const char *hf = loc->s.zone_formats[TK_ZF_HOUR];
    const char *semi = strchr(hf, ';'), *p, *end, *z;
    int32_t a = off < 0 ? -off : off;
    int h = (int)(a / 3600), m = (int)(a / 60 % 60), s = (int)(a % 60);
    STRLEN after_hour = 0;
    tk_out t;
    if (off == 0) {
        tk_out_str(aTHX_ o, loc->s.zone_formats[TK_ZF_GMT_ZERO]);
        return;
    }
    if (off > 0) {
        p = hf;
        end = semi ? semi : hf + strlen(hf);
    }
    else {
        p = semi ? semi + 1 : hf;
        end = p + strlen(p);
    }
    t.sv = sv_2mortal(newSVpvs(""));
    t.utf8 = 0;
    t.digits = o->digits; t.nums = o->nums; t.nums_len = o->nums_len;
    while (p < end) {
        int n = 0;
        char ch = *p;
        if (ch == 'H' || ch == 'm') {
            while (p < end && *p == ch) {
                n++;
                p++;
            }
            if (ch == 'H') {
                tk_out_num(aTHX_ &t, h, long_form ? n : 1, '0');
                after_hour = SvCUR(t.sv);
            }
            else if (!long_form && m == 0 && s == 0)
                SvCUR_set(t.sv, after_hour);
            else {
                tk_out_num(aTHX_ &t, m, 2, '0');
                if (s) {
                    tk_out_cat(aTHX_ &t, ":", 1);
                    tk_out_num(aTHX_ &t, s, 2, '0');
                }
            }
            continue;
        }
        tk_out_cat(aTHX_ &t, p, 1);
        p++;
    }
    z = strstr(fmt, "{0}");
    if (!z) {
        tk_out_cat(aTHX_ o, SvPVX(t.sv), SvCUR(t.sv));
        return;
    }
    tk_out_cat(aTHX_ o, fmt, (STRLEN)(z - fmt));
    tk_out_cat(aTHX_ o, SvPVX(t.sv), SvCUR(t.sv));
    tk_out_str(aTHX_ o, z + 3);
}

/* {0} of a CLDR pattern filled with one string, and {1} with another. */
static void
tk_out_fill(pTHX_ tk_out *o, const char *fmt, const char *zero, const char *one)
{
    const char *p = fmt;
    while (*p) {
        if (p[0] == '{' && (p[1] == '0' || p[1] == '1') && p[2] == '}') {
            tk_out_str(aTHX_ o, p[1] == '0' ? zero : (one ? one : ""));
            p += 3;
            continue;
        }
        tk_out_cat(aTHX_ o, p, 1);
        p++;
    }
}

/* ---- zone names ----------------------------------------------------------- */

/* A value's zone as CLDR names it (an index into tk_cldr_zones), or -1 for
 * an offset or floating time. */
static int
tk_cldr_zone_of(pTHX_ const tk_value *v)
{
    const char *names[2];
    int k;
    if (v->zone == TK_ZONE_UTC)
        names[0] = names[1] = "Etc/UTC";
    else if (v->zone >= TK_ZONE_NAMED) {
        const tkz_abi *t = tk_zone_abi(aTHX);
        names[0] = (t->name)(v->zone - TK_ZONE_NAMED);
        names[1] = (t->canonical_name)(v->zone - TK_ZONE_NAMED);
    }
    else
        return -1;
    for (k = 0; k < 2; k++) {
        int lo = 0, hi = TK_IANA_ZONES - 1;
        if (!names[k])
            continue;
        while (lo <= hi) {
            int mid = lo + (hi - lo) / 2;
            int c = strcmp(tk_iana_zones[mid].key, names[k]);
            if (c == 0)
                return tk_iana_zones[mid].id;
            if (c < 0) lo = mid + 1; else hi = mid - 1;
        }
    }
    return -1;
}

static const tk_zone_names *
tk_names_find(const tk_zone_names *list, unsigned n, unsigned id)
{
    int lo = 0, hi = (int)n - 1;
    while (lo <= hi) {
        int mid = lo + (hi - lo) / 2;
        if (list[mid].id == id)
            return &list[mid];
        if (list[mid].id < id) lo = mid + 1; else hi = mid - 1;
    }
    return NULL;
}

/* The metazone a CLDR zone is in at an instant, or -1. */
static int
tk_metazone_at(int cz, int64_t utc)
{
    unsigned i;
    const tk_cldr_zone *z = &tk_cldr_zones[cz];
    for (i = 0; i < z->mz_count; i++) {
        const tk_mz_period *p = &tk_mz_periods[z->mz_first + i];
        if (p->from <= utc && utc < p->to)
            return p->mz;
    }
    return -1;
}

/* A zone's or its metazone's name of one kind (TK_ZN_), or NULL. */
static const char *
tk_zone_kind_name(const tk_locale_data *loc, int cz, int64_t utc, int kind)
{
    const tk_zone_names *n = tk_names_find(loc->zones, loc->n_zones, (unsigned)cz);
    int mz;
    if (n && n->s[kind])
        return n->s[kind];
    mz = tk_metazone_at(cz, utc);
    if (mz >= 0 && (n = tk_names_find(loc->metazones, loc->n_metazones, (unsigned)mz)) && n->s[kind])
        return n->s[kind];
    return NULL;
}

/* The exemplar city: the locale's, or the last part of the name with _ as
 * spaces. */
static void
tk_out_city(pTHX_ tk_out *o, const tk_locale_data *loc, int cz)
{
    const tk_zone_names *n = tk_names_find(loc->zones, loc->n_zones, (unsigned)cz);
    const char *name, *last;
    if (n && n->s[TK_ZN_CITY]) {
        tk_out_str(aTHX_ o, n->s[TK_ZN_CITY]);
        return;
    }
    name = tk_cldr_zones[cz].name;
    last = strrchr(name, '/');
    for (last = last ? last + 1 : name; *last; last++)
        tk_out_cat(aTHX_ o, *last == '_' ? " " : last, 1);
}

/* The generic location format, VVVV: "France Time" for a country with one
 * zone, "Los Angeles Time" for one of several. 0 if it cannot be made. */
static int
tk_out_zone_location(pTHX_ tk_out *o, const tk_locale_data *loc, int cz)
{
    const tk_cldr_zone *z;
    const char *fmt = loc->s.zone_formats[TK_ZF_REGION], *at;
    if (cz < 0)
        return 0;
    z = &tk_cldr_zones[cz];
    at = strstr(fmt, "{0}");
    if (!at)
        return 0;
    tk_out_cat(aTHX_ o, fmt, (STRLEN)(at - fmt));
    if (z->only && z->territory >= 0) {
        int lo = 0, hi = (int)loc->n_territories - 1;
        const char *name = NULL;
        while (lo <= hi) {
            int mid = lo + (hi - lo) / 2;
            if (loc->territories[mid].id == (uint16_t)z->territory) {
                name = loc->territories[mid].name;
                break;
            }
            if (loc->territories[mid].id < (uint16_t)z->territory) lo = mid + 1; else hi = mid - 1;
        }
        if (name)
            tk_out_str(aTHX_ o, name);
        else
            tk_out_city(aTHX_ o, loc, cz);
    }
    else
        tk_out_city(aTHX_ o, loc, cz);
    tk_out_str(aTHX_ o, at + 3);
    return 1;
}

/* Whether a value's zone keeps daylight time within six months either
 * side of it: a generic name falls back to the standard one when not. */
static int
tk_zone_dst_near(pTHX_ const tk_value *v)
{
    const tkz_abi *t;
    int k, dst;
    if (v->flags & TK_F_DST)
        return 1;
    if (v->zone < TK_ZONE_NAMED)
        return 0;
    t = tk_zone_abi(aTHX);
    for (k = -1; k <= 1; k += 2) {
        dst = 0;
        (t->offset_at)(v->zone - TK_ZONE_NAMED, v->inst.sec + k * (int64_t)184 * 86400, NULL, &dst, NULL);
        if (dst)
            return 1;
    }
    return 0;
}

/* z, zzzz, v, vvvv, V to VVVV, and O, OOOO, ZZZZ, as CLDR's "Using Time
 * Zone Names" has them, each falling back as it says: a specific name to
 * the localised GMT format, a generic name to the standard one where the
 * zone keeps no daylight time near, then to the location format, then to
 * GMT. Floating time has no zone to name. */
static void
tk_out_zone_name(pTHX_ tk_out *o, tk_value *v, const tk_locale_data *loc, char ch, int n)
{
    int cz, dst = (v->flags & TK_F_DST) != 0;
    const char *s = NULL;
    const char *const *digits = o->digits;
    if (v->zone == TK_ZONE_FLOATING) {
        tk_out_str(aTHX_ o, "floating");
        return;
    }
    cz = tk_cldr_zone_of(aTHX_ v);
    switch (ch) {
    case 'z':
        if (cz >= 0)
            s = tk_zone_kind_name(loc, cz, v->inst.sec,
                                  (n >= 4 ? TK_ZN_LONG_STANDARD : TK_ZN_SHORT_STANDARD) + dst);
        if (s)
            tk_out_str(aTHX_ o, s);
        else
            tk_out_gmt(aTHX_ o, loc, v->utoff, n >= 4);
        return;
    case 'v':
        if (cz >= 0) {
            s = tk_zone_kind_name(loc, cz, v->inst.sec, n >= 4 ? TK_ZN_LONG_GENERIC : TK_ZN_SHORT_GENERIC);
            if (!s && !tk_zone_dst_near(aTHX_ v))
                s = tk_zone_kind_name(loc, cz, v->inst.sec, n >= 4 ? TK_ZN_LONG_STANDARD : TK_ZN_SHORT_STANDARD);
        }
        if (s)
            tk_out_str(aTHX_ o, s);
        else if (!tk_out_zone_location(aTHX_ o, loc, cz))
            tk_out_gmt(aTHX_ o, loc, v->utoff, 0);
        return;
    case 'V':
        if (n == 1) {
            tk_out_str(aTHX_ o, cz >= 0 ? tk_cldr_zones[cz].bcp47 : "unk");
            return;
        }
        if (n == 2 || cz < 0) {
            SV *name = sv_2mortal(tk_zone_name_sv(aTHX_ v));
            o->digits = NULL;
            tk_out_cat(aTHX_ o, SvPVX(name), SvCUR(name));
            o->digits = digits;
            return;
        }
        if (n == 3)
            tk_out_city(aTHX_ o, loc, cz);
        else if (!tk_out_zone_location(aTHX_ o, loc, cz))
            tk_out_gmt(aTHX_ o, loc, v->utoff, 1);
        return;
    default:
        tk_out_gmt(aTHX_ o, loc, v->utoff, n >= 4);
        return;
    }
}

/* ---- day periods and weeks -------------------------------------------- */

/* b: noon or midnight exactly, else am or pm. B: the locale's period of
 * the day ("in the morning"), else am or pm. */
static void
tk_out_period(pTHX_ tk_out *o, const tk_locale_data *loc, const tk_civil *c, char ch, int n)
{
    int w = n == 4 ? TK_W_WIDE : n == 5 ? TK_W_NARROW : TK_W_ABBR;
    unsigned minute = c->hour * 60 + c->minute, i;
    int exact = c->second == 0 && c->nsec == 0, period = -1;
    for (i = 0; i < loc->n_rules; i++) {
        const tk_period_rule *r = &loc->rules[i];
        if (r->from == r->before) {
            if (exact && r->from == minute && loc->s.periods[w][r->period]) {
                period = r->period;
                break;
            }
        }
        else if (ch == 'B' && period < 0
                 && (r->from < r->before ? (minute >= r->from && minute < r->before)
                                         : (minute >= r->from || minute < r->before)))
            period = r->period;
    }
    if (period >= 0 && !(ch == 'b' && period != TK_DP_NOON && period != TK_DP_MIDNIGHT)
        && loc->s.periods[w][period])
        tk_out_str(aTHX_ o, loc->s.periods[w][period]);
    else
        tk_out_str(aTHX_ o, loc->s.periods[w][c->hour >= 12]);
}

/* The start of week 1 of a year, as the locale counts weeks: the week
 * holding at least min_days of January. */
static int64_t
tk_locale_week1(const tk_locale_data *loc, int64_t y)
{
    int64_t jan1 = tk_days_from_civil(y, 1, 1);
    int back = (int)((tk_dow_from_days(jan1) + 7 - loc->first_day) % 7);
    return jan1 - back + (7 - back < loc->min_days ? 7 : 0);
}

/* The locale's week of the year, and the year it belongs to. */
static void
tk_locale_week(const tk_locale_data *loc, const tk_civil *c, int64_t *wy, unsigned *wk)
{
    int64_t z = tk_days_from_civil(c->year, c->month, c->day);
    int64_t start = tk_locale_week1(loc, c->year);
    if (z < start) {
        *wy = c->year - 1;
        start = tk_locale_week1(loc, c->year - 1);
    }
    else if (z >= tk_locale_week1(loc, c->year + 1)) {
        *wy = c->year + 1;
        start = tk_locale_week1(loc, c->year + 1);
    }
    else
        *wy = c->year;
    *wk = (unsigned)((z - start) / 7 + 1);
}

/* The locale's week of the month: 0 for days before its first week. */
static unsigned
tk_locale_week_of_month(const tk_locale_data *loc, const tk_civil *c)
{
    int64_t first = tk_days_from_civil(c->year, c->month, 1);
    int back = (int)((tk_dow_from_days(first) + 7 - loc->first_day) % 7);
    return (unsigned)((c->day - 1 + back) / 7 + (7 - back >= loc->min_days ? 1 : 0));
}

/* ISO 8601 offsets for X and x: count 1 +HH[MM], 2 +HHMM, 3 +HH:MM, 4 +HHMM[SS],
 * 5 +HH:MM[:SS]; X writes Z for zero. */
static void
tk_out_iso_offset(pTHX_ tk_out *o, int32_t off, int count, int z_for_zero)
{
    char buf[24];
    int32_t a = off < 0 ? -off : off;
    int n, h = (int)(a / 3600), m = (int)(a / 60 % 60), s = (int)(a % 60);
    char sign = off < 0 ? '-' : '+';
    if (off == 0 && z_for_zero) {
        tk_out_cat(aTHX_ o, "Z", 1);
        return;
    }
    switch (count) {
    case 1:  n = m ? sprintf(buf, "%c%02d%02d", sign, h, m) : sprintf(buf, "%c%02d", sign, h); break;
    case 2:  n = sprintf(buf, "%c%02d%02d", sign, h, m); break;
    case 3:  n = sprintf(buf, "%c%02d:%02d", sign, h, m); break;
    case 4:  n = s ? sprintf(buf, "%c%02d%02d%02d", sign, h, m, s) : sprintf(buf, "%c%02d%02d", sign, h, m); break;
    default: n = s ? sprintf(buf, "%c%02d:%02d:%02d", sign, h, m, s) : sprintf(buf, "%c%02d:%02d", sign, h, m); break;
    }
    tk_out_cat(aTHX_ o, buf, (STRLEN)n);
}

static void
tk_cldr_field(pTHX_ tk_out *o, SV *self, tk_value *v, const tk_locale_data *loc,
              char ch, int n)
{
    const tk_civil *c = tk_value_civil(v);
    int era = c->year > 0;
    unsigned local_dow = (unsigned)((c->dow + 7 - loc->first_day) % 7 + 1);
    int64_t wy;
    unsigned wk;
    int ctx;
    /* in another calendar the date letters read its fields and names */
    const tk_calendar *cal = tk_cal_of(v);
    int other = v->calendar != TK_CAL_GREGORY;
    int lunisolar = v->calendar == TK_CAL_CHINESE || v->calendar == TK_CAL_DANGI;
    tk_calfields cf;
    const tk_cal_names *cn = NULL;
    int w = n == 4 ? TK_W_WIDE : n == 5 ? TK_W_NARROW : TK_W_ABBR;
    PERL_UNUSED_VAR(self);
    if (other) {
        tk_value_calfields(aTHX_ v, &cf, "Time::Keeper->format");
        cn = tk_cal_names_get(aTHX_ loc, v->calendar);
    }

    switch (ch) {
    case 'G':
        if (other)
            tk_out_str(aTHX_ o, tk_cal_era_name(cn, cal, cf.era, w));
        else
            tk_out_str(aTHX_ o, loc->s.eras[w][era]);
        break;
    case 'U':
        if (lunisolar) {
            tk_out_str(aTHX_ o, tk_cal_cyclic_name(cn, tk_lunisolar_cyclic_year(cf.year), n == 4 ? TK_W_WIDE : n == 5 ? TK_W_NARROW : TK_W_ABBR));
            break;
        }
        /* fall through: a calendar with no cycle writes the year */
    case 'y':
        if (other) {
            int64_t yy = lunisolar ? tk_lunisolar_cyclic_year(cf.year) : cf.era_year;
            if (n == 2)
                tk_out_field_num(aTHX_ o, ch, (yy < 0 ? -yy : yy) % 100, 2);
            else
                tk_out_field_num(aTHX_ o, ch, yy, n);
            break;
        }
        if (n == 2) {
            int64_t a = c->year < 0 ? -(int64_t)c->year : c->year;
            tk_out_field_num(aTHX_ o, ch, a % 100, 2);
        }
        else
            tk_out_field_num(aTHX_ o, ch, c->year, n);
        break;
    case 'u':
        tk_out_field_num(aTHX_ o, ch, other ? (lunisolar ? cf.era_year : cf.year) : c->year, n);
        break;
    case 'r':
        tk_out_field_num(aTHX_ o, ch, other ? tk_cal_related_year(cal, cf.year) : c->year, n);
        break;
    case 'Y':
        if (other) {
            /* the calendar's year: CLDR's gl patterns write Y for it, and the
               ISO week year is the Gregorian's */
            int64_t yy = lunisolar ? tk_lunisolar_cyclic_year(cf.year) : cf.era_year;
            if (n == 2)
                tk_out_field_num(aTHX_ o, ch, (yy < 0 ? -yy : yy) % 100, 2);
            else
                tk_out_field_num(aTHX_ o, ch, yy, n);
            break;
        }
        tk_locale_week(loc, c, &wy, &wk);
        if (n == 2)
            tk_out_field_num(aTHX_ o, ch, (wy < 0 ? -wy : wy) % 100, 2);
        else
            tk_out_field_num(aTHX_ o, ch, wy, n);
        break;
    case 'Q':
    case 'q':
        ctx = ch == 'Q' ? TK_CTX_FORMAT : TK_CTX_STANDALONE;
        if (other) {
            unsigned q = (cf.month - 1) / 3 + 1;
            if (n <= 2 || q > 4)
                tk_out_field_num(aTHX_ o, ch, q, n <= 2 ? n : 1);
            else
                tk_out_str(aTHX_ o, loc->s.quarters[ctx][n == 3 ? TK_W_ABBR : n == 4 ? TK_W_WIDE : TK_W_NARROW][q - 1]);
            break;
        }
        if (n <= 2)
            tk_out_field_num(aTHX_ o, ch, tk_quarter(c->month), n);
        else
            tk_out_str(aTHX_ o, loc->s.quarters[ctx][n == 3 ? TK_W_ABBR : n == 4 ? TK_W_WIDE : TK_W_NARROW][tk_quarter(c->month) - 1]);
        break;
    case 'M':
    case 'L':
        ctx = ch == 'M' ? TK_CTX_FORMAT : TK_CTX_STANDALONE;
        if (other) {
            int mw = n == 3 ? TK_W_ABBR : n == 4 ? TK_W_WIDE : TK_W_NARROW;
            const char *leap = cf.leap_month ? tk_cal_leap_pattern(cn, ctx, mw, n <= 2) : NULL;
            if (n <= 2) {
                STRLEN at = SvCUR(o->sv);
                tk_out_field_num(aTHX_ o, ch, tk_cal_month_numeric(cal, &cf), n);
                if (leap) {
                    SV *num = sv_2mortal(newSVpvn(SvPVX(o->sv) + at, SvCUR(o->sv) - at));
                    SvCUR_set(o->sv, at);
                    tk_out_leap_wrap(aTHX_ o, leap, SvPVX(num), SvCUR(num));
                }
            }
            else {
                const char *name = tk_cal_month_name(cn, loc, cal, &cf, ctx, mw);
                tk_out_leap_wrap(aTHX_ o, leap, name, strlen(name));
            }
            break;
        }
        if (n <= 2)
            tk_out_field_num(aTHX_ o, ch, c->month, n);
        else
            tk_out_str(aTHX_ o, loc->s.months[ctx][n == 3 ? TK_W_ABBR : n == 4 ? TK_W_WIDE : TK_W_NARROW][c->month - 1]);
        break;
    case 'w':
        tk_locale_week(loc, c, &wy, &wk);
        tk_out_field_num(aTHX_ o, ch, wk, n);
        break;
    case 'W':
        tk_out_field_num(aTHX_ o, ch, tk_locale_week_of_month(loc, c), n);
        break;
    case 'd':
        tk_out_field_num(aTHX_ o, ch, other ? cf.day : c->day, n);
        break;
    case 'D':
        tk_out_field_num(aTHX_ o, ch, other ? cf.doy : c->doy, n);
        break;
    case 'F':
        tk_out_field_num(aTHX_ o, ch, ((other ? cf.day : c->day) + 6) / 7, n);
        break;
    case 'g':
        /* CLDR's modified Julian day counts local days, from local midnight */
        tk_out_field_num(aTHX_ o, ch, tk_days_from_civil(c->year, c->month, c->day) + 40587, n);
        break;
    case 'E':
        tk_out_str(aTHX_ o, loc->s.days[TK_CTX_FORMAT][n == 4 ? TK_W_WIDE : n == 5 ? TK_W_NARROW : n == 6 ? TK_W_SHORT : TK_W_ABBR][c->dow - 1]);
        break;
    case 'e':
    case 'c':
        ctx = ch == 'e' ? TK_CTX_FORMAT : TK_CTX_STANDALONE;
        if (n <= 2)
            tk_out_field_num(aTHX_ o, ch, local_dow, n);
        else
            tk_out_str(aTHX_ o, loc->s.days[ctx][n == 3 ? TK_W_ABBR : n == 4 ? TK_W_WIDE : n == 5 ? TK_W_NARROW : TK_W_SHORT][c->dow - 1]);
        break;
    case 'a':
        tk_out_str(aTHX_ o, loc->s.periods[n == 4 ? TK_W_WIDE : n == 5 ? TK_W_NARROW : TK_W_ABBR][c->hour >= 12]);
        break;
    case 'b':
    case 'B':
        tk_out_period(aTHX_ o, loc, c, ch, n);
        break;
    case 'h': tk_out_field_num(aTHX_ o, ch, tk_hour12(c->hour), n); break;
    case 'H': tk_out_field_num(aTHX_ o, ch, c->hour, n); break;
    case 'K': tk_out_field_num(aTHX_ o, ch, c->hour % 12, n); break;
    case 'k': tk_out_field_num(aTHX_ o, ch, c->hour == 0 ? 24 : c->hour, n); break;
    case 'j': tk_out_field_num(aTHX_ o, ch, loc->hour_cycle_24 ? c->hour : tk_hour12(c->hour), n); break;
    case 'm': tk_out_field_num(aTHX_ o, ch, c->minute, n); break;
    case 's': tk_out_field_num(aTHX_ o, ch, c->second, n); break;
    case 'S': tk_out_fraction_digits(aTHX_ o, c->nsec, n); break;
    case 'A': {
        int64_t ms = ((int64_t)c->hour * 3600 + c->minute * 60 + c->second) * 1000 + c->nsec / 1000000;
        tk_out_field_num(aTHX_ o, ch, ms, n);
        break;
    }
    case 'z':
    case 'v':
    case 'V':
    case 'O':
        tk_out_zone_name(aTHX_ o, v, loc, ch, n);
        break;
    case 'Z':
        if (n <= 3)
            tk_out_offset(aTHX_ o, v->utoff, 0, 1);
        else if (n == 4)
            tk_out_gmt(aTHX_ o, loc, v->utoff, 1);
        else
            tk_out_iso_offset(aTHX_ o, v->utoff, 5, 1);
        break;
    case 'X':
    case 'x':
        tk_out_iso_offset(aTHX_ o, v->utoff, n, ch == 'X');
        break;
    default: {
        /* a letter CLDR does not define, or this does not know, as written */
        int k;
        for (k = 0; k < n; k++)
            tk_out_cat(aTHX_ o, &ch, 1);
        break;
    }
    }
}

/* A CLDR pattern. In a date-time pattern {1} is the date part and {0} the
 * time part, themselves patterns. */
static void
tk_format_cldr(pTHX_ tk_out *o, SV *self, tk_value *v, const tk_locale_data *loc,
               const char *p, STRLEN len, const char *date_part, const char *time_part)
{
    STRLEN i = 0;
    const char *const *saved = o->digits;
    const char *saved_nums = o->nums;
    STRLEN saved_nums_len = o->nums_len;
    /* a numbering spec in front of the pattern holds for the pattern */
    {
        const char *spec;
        STRLEN spec_len;
        if (tk_nums_prefix(&p, &len, &spec, &spec_len)) {
            o->nums = spec;
            o->nums_len = spec_len;
        }
    }
    o->digits = loc->ascii_digits ? NULL : loc->s.digits;
    while (i < len) {
        char ch = p[i];
        if (ch == '\'') {
            if (i + 1 < len && p[i + 1] == '\'') {   /* '' is a quote */
                tk_out_cat(aTHX_ o, "'", 1);
                i += 2;
                continue;
            }
            i++;
            while (i < len) {
                if (p[i] == '\'') {
                    if (i + 1 < len && p[i + 1] == '\'') {
                        tk_out_cat(aTHX_ o, "'", 1);
                        i += 2;
                        continue;
                    }
                    i++;
                    break;
                }
                tk_out_cat(aTHX_ o, p + i, 1);
                i++;
            }
            continue;
        }
        if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')) {
            int n = 0;
            while (i < len && p[i] == ch) {
                n++;
                i++;
            }
            tk_cldr_field(aTHX_ o, self, v, loc, ch, n);
            continue;
        }
        if (ch == '{' && i + 2 < len && p[i + 2] == '}' && (p[i + 1] == '0' || p[i + 1] == '1')
            && (p[i + 1] == '0' ? time_part : date_part)) {
            const char *part = p[i + 1] == '0' ? time_part : date_part;
            tk_format_cldr(aTHX_ o, self, v, loc, part, strlen(part), NULL, NULL);
            i += 3;
            continue;
        }
        tk_out_cat(aTHX_ o, p + i, 1);
        i++;
    }
    o->digits = saved;
    o->nums = saved_nums;
    o->nums_len = saved_nums_len;
}

/* ---- the fixed forms -------------------------------------------------- */

static const char *const tk_en_days3[7] = { "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" };
static const char *const tk_en_months3[12] = {
    "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
};

/* RFC 5322's date-time (RFC 2822's, which it replaced): English names, a
 * four-digit year, +HHMM. */
static void
tk_rfc2822(pTHX_ tk_out *o, tk_value *v, int http)
{
    char buf[64];
    int n;
    tk_value u;
    const tk_civil *c;
    if (http) {
        tk_zone_spec z;
        z.zone = TK_ZONE_UTC;
        z.fixed = 0;
        tk_value_init(aTHX_ &u, &v->inst, &z);
        v = &u;
    }
    c = tk_value_civil(v);
    n = sprintf(buf, "%s, %02u %s %04d %02u:%02u:%02u ", tk_en_days3[c->dow - 1], (unsigned)c->day,
                tk_en_months3[c->month - 1], (int)c->year, (unsigned)c->hour, (unsigned)c->minute,
                (unsigned)c->second);
    tk_out_cat(aTHX_ o, buf, (STRLEN)n);
    if (http)
        tk_out_cat(aTHX_ o, "GMT", 3);
    else
        tk_out_offset(aTHX_ o, v->utoff - v->utoff % 60, 0, 0);
}

/* The date and time with a fraction of exactly `digits` digits (0 to 9),
 * or the fewest of 3, 6 or 9 that are exact when digits is -1, in ISO
 * 8601's form 0 extended (2026-10-15T09:00:00), 1 basic (20261015T090000),
 * 2 week (2026-W42-4T09:00:00) or 3 ordinal (2026-288T09:00:00). */
static void
tk_out_datetime_form(pTHX_ tk_out *o, tk_value *v, int digits, int form)
{
    char buf[64];
    const tk_civil *c = tk_value_civil(v);
    int n;
    if (form == 2) {
        int64_t wy;
        unsigned w;
        tk_iso_week(c->year, c->month, c->day, &wy, &w);
        n = tk_fmt_year(buf, wy);
        n += sprintf(buf + n, "-W%02u-%uT%02u:%02u:%02u", w, (unsigned)c->dow,
                     (unsigned)c->hour, (unsigned)c->minute, (unsigned)c->second);
    }
    else {
        n = tk_fmt_year(buf, c->year);
        if (form == 3)
            n += sprintf(buf + n, "-%03uT%02u:%02u:%02u", (unsigned)c->doy,
                         (unsigned)c->hour, (unsigned)c->minute, (unsigned)c->second);
        else
            n += sprintf(buf + n, form == 1 ? "%02u%02uT%02u%02u%02u" : "-%02u-%02uT%02u:%02u:%02u",
                         (unsigned)c->month, (unsigned)c->day,
                         (unsigned)c->hour, (unsigned)c->minute, (unsigned)c->second);
    }
    if (digits < 0)
        n += tk_fmt_fraction(buf + n, c->nsec);
    else if (digits > 0) {
        char f[16];
        sprintf(f, "%09d", (int)c->nsec);
        buf[n++] = '.';
        memcpy(buf + n, f, (size_t)digits);
        n += digits;
    }
    tk_out_cat(aTHX_ o, buf, (STRLEN)n);
}

static void
tk_out_datetime(pTHX_ tk_out *o, tk_value *v, int digits)
{
    tk_out_datetime_form(aTHX_ o, v, digits, 0);
}

#endif
