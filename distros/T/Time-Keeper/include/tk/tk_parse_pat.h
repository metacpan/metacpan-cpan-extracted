#ifndef TK_PARSE_PAT_H
#define TK_PARSE_PAT_H

/* strptime and CLDR patterns, read in reverse: each conversion or field
 * reads what Phase 08 would have written for it. */

/* The digit a character is in any decimal digit set CLDR knows (Arabic,
 * Devanagari, fullwidth...), or -1. */
static int
tk_unicode_digit(UV cp)
{
    int lo = 0, hi = TK_DIGIT_ZEROS - 1, at = -1;
    while (lo <= hi) {
        int mid = lo + (hi - lo) / 2;
        if (tk_digit_zeros[mid] <= cp) {
            at = mid;
            lo = mid + 1;
        }
        else
            hi = mid - 1;
    }
    return at >= 0 && cp - tk_digit_zeros[at] < 10 ? (int)(cp - tk_digit_zeros[at]) : -1;
}

/* The bytes of a white space character here (a space, a tab, a no-break,
 * narrow no-break, thin or other fixed-width space, an ideographic space),
 * or 0. */
static STRLEN
tk_ws_at(const char *p, STRLEN left)
{
    const unsigned char *u = (const unsigned char *)p;
    if (left >= 1 && (u[0] == ' ' || u[0] == '\t'))
        return 1;
    if (left >= 2 && u[0] == 0xC2 && u[1] == 0xA0)
        return 2;
    if (left >= 3 && u[0] == 0xE2 && u[1] == 0x80 && ((u[2] >= 0x80 && u[2] <= 0x8A) || u[2] == 0xAF))
        return 3;
    if (left >= 3 && u[0] == 0xE3 && u[1] == 0x80 && u[2] == 0x80)
        return 3;
    return 0;
}

/* How much of the text the next character of a name matches, ignoring
 * ASCII case, reading a digit of another script in the name as the ASCII
 * digit the text was folded to, and white space in the name as any run of
 * white space ("p. m." with the narrow no-break space CLDR writes, or the
 * space a person types): 1 and the bytes of each it takes, or 0. */
static int
tk_name_char(const char *t, STRLEN tleft, const char *n, STRLEN nleft, STRLEN *tl, STRLEN *nl)
{
    const unsigned char *u = (const unsigned char *)n;
    STRLEN w = tk_ws_at(n, nleft);
    if (w) {
        STRLEN a = 0, b = 0, k;
        while ((k = tk_ws_at(n + b, nleft - b)))
            b += k;
        while ((k = tk_ws_at(t + a, tleft - a)))
            a += k;
        if (!a)
            return 0;
        *tl = a;
        *nl = b;
        return 1;
    }
    if (u[0] >= 0xC0) {
        STRLEN cl = u[0] >= 0xF0 ? 4 : u[0] >= 0xE0 ? 3 : 2, k;
        if (cl <= nleft) {
            UV cp = u[0] & (0x7F >> cl);
            int d;
            for (k = 1; k < cl; k++)
                cp = (cp << 6) | (u[k] & 0x3F);
            d = tk_unicode_digit(cp);
            if (d >= 0) {
                if (tleft < 1 || t[0] != (char)('0' + d))
                    return 0;
                *tl = 1;
                *nl = cl;
                return 1;
            }
        }
    }
    if (tleft < 1 || toLOWER(t[0]) != toLOWER(n[0]))
        return 0;
    *tl = *nl = 1;
    return 1;
}

/* How many bytes of the text a name takes here, or 0. */
static STRLEN
tk_name_at(const tk_cursor *c, const char *name, STRLEN nlen)
{
    STRLEN i = c->i, j = 0;
    while (j < nlen) {
        STRLEN tl, nl;
        if (!tk_name_char(c->s + i, c->len - i, name + j, nlen - j, &tl, &nl))
            return 0;
        i += tl;
        j += nl;
    }
    return i - c->i;
}

/* The longest of a set of names that starts here, ignoring ASCII case;
 * its index, or -1. */
static int
tk_match_name(tk_cursor *c, const char *const *names, int n)
{
    int k, best = -1;
    STRLEN best_len = 0;
    for (k = 0; k < n; k++) {
        STRLEN l = strlen(names[k]), took;
        if (!l)
            continue;
        took = tk_name_at(c, names[k], l);
        if (took > best_len) {
            best = k;
            best_len = took;
        }
    }
    if (best >= 0)
        c->i += best_len;
    return best;
}

/* A month or a day by any of its names in the locale, in either context;
 * 1-based, or 0. */
static unsigned
tk_match_month(tk_cursor *c, const tk_locale_data *loc)
{
    const char *all[TK_CTX_COUNT * 2 * 12];
    int ctx, w, k, n = 0, hit;
    for (ctx = 0; ctx < TK_CTX_COUNT; ctx++)
        for (w = 0; w < 2; w++)                     /* wide and abbreviated, not narrow */
            for (k = 0; k < 12; k++)
                all[n++] = loc->s.months[ctx][w][k];
    hit = tk_match_name(c, all, n);
    return hit < 0 ? 0 : (unsigned)(hit % 12) + 1;
}

/* A month's name in a calendar other than the Gregorian, in either context,
 * wide or abbreviated, or wrapped in the leap pattern ({0}bis) for a leap
 * month; the Hebrew Adar II is the leap-year name of slot 7. CLDR's slot,
 * or 0; the leap flag goes to the fields. */
static unsigned
tk_match_cal_month(tk_cursor *c, tk_fields *f, const tk_locale_data *loc)
{
    const tk_cal_names *cn = (const tk_cal_names *)f->cal_names;
    int ctx, w, leap, best_leap = 0;
    unsigned slot, best = 0;
    STRLEN best_len = 0;
    for (leap = 0; leap < 2; leap++) {
        for (ctx = 0; ctx < TK_CTX_COUNT; ctx++) {
            for (w = 0; w < 2; w++) {
                const char *pat = leap ? tk_cal_leap_pattern(cn, ctx, w, 0) : NULL;
                const char *at = pat ? strstr(pat, "{0}") : NULL;
                STRLEN pre = at ? (STRLEN)(at - pat) : 0;
                if (leap && !at)
                    continue;
                for (slot = 1; slot <= 14; slot++) {
                    const char *name;
                    STRLEN save = c->i, took, total;
                    unsigned which = slot == 14 ? 7 : slot;
                    if (slot == 14)
                        name = leap ? NULL : cn->slot[TK_CN_MONTHS_LEAP + ctx * 3 + w];
                    else {
                        name = cn->slot[TK_CN_MONTHS + (ctx * 3 + w) * 13 + slot - 1];
                        if (!name && slot <= 12)
                            name = loc->s.months[ctx][w][slot - 1];
                    }
                    if (!name || !*name)
                        continue;
                    if (pre) {
                        took = tk_name_at(c, pat, pre);
                        if (!took)
                            continue;
                        c->i += took;
                    }
                    took = tk_name_at(c, name, strlen(name));
                    if (!took) {
                        c->i = save;
                        continue;
                    }
                    c->i += took;
                    if (leap && at[3]) {
                        took = tk_name_at(c, at + 3, strlen(at + 3));
                        if (!took) {
                            c->i = save;
                            continue;
                        }
                        c->i += took;
                    }
                    total = c->i - save;
                    c->i = save;
                    if (total > best_len) {
                        best_len = total;
                        best = which;
                        best_leap = leap;
                    }
                }
            }
        }
    }
    if (!best)
        return 0;
    c->i += best_len;
    f->leap_month_text = best_leap;
    return best;
}

static unsigned
tk_match_day(tk_cursor *c, const tk_locale_data *loc)
{
    const char *all[TK_CTX_COUNT * 3 * 7];
    static const int widths[3] = { TK_W_WIDE, TK_W_ABBR, TK_W_SHORT };
    int ctx, w, k, n = 0, hit;
    for (ctx = 0; ctx < TK_CTX_COUNT; ctx++)
        for (w = 0; w < 3; w++)
            for (k = 0; k < 7; k++)
                all[n++] = loc->s.days[ctx][widths[w]][k];
    hit = tk_match_name(c, all, n);
    return hit < 0 ? 0 : (unsigned)(hit % 7) + 1;
}

static int
tk_match_ampm(tk_cursor *c, const tk_locale_data *loc, tk_fields *f)
{
    const char *all[6];
    int w, n = 0, hit;
    for (w = 0; w < TK_W_COUNT; w++) {
        all[n++] = loc->s.periods[w][0];
        all[n++] = loc->s.periods[w][1];
    }
    hit = tk_match_name(c, all, n);
    if (hit < 0)
        return tk_fail(c, "AM or PM was wanted");
    f->has_ampm = 1;
    f->pm = hit % 2;
    return 1;
}

/* A zone abbreviation, or an offset: letters, or a sign and digits. */
static int
tk_abbr_field(tk_cursor *c, tk_fields *f)
{
    STRLEN start = c->i;
    if (tk_peek(c) == '+' || tk_peek(c) == '-')
        return tk_offset_field(c, f, 1);
    while (c->i < c->len && isALPHA(c->s[c->i]))
        c->i++;
    if (c->i == start)
        return tk_fail(c, "a zone's abbreviation was wanted");
    f->abbr = c->s + start;
    f->abbr_len = c->i - start;
    return 1;
}

/* A signed integer of up to max digits. */
static int
tk_signed(tk_cursor *c, int max, int64_t *out)
{
    int neg = 0;
    if (tk_peek(c) == '-' || tk_peek(c) == '+')
        neg = c->s[c->i++] == '-';
    if (!tk_digits_range(c, 1, max, out))
        return 0;
    if (neg)
        *out = -*out;
    return 1;
}

/* A day period by any of its names (b, B): its TK_DP_ index, or -1. */
static int
tk_match_period(tk_cursor *c, const tk_locale_data *loc)
{
    const char *all[TK_W_COUNT * TK_DP_COUNT];
    int w, k, n = 0, hit;
    for (w = 0; w < TK_W_COUNT; w++)
        for (k = 0; k < TK_DP_COUNT; k++)
            all[n++] = loc->s.periods[w][k] ? loc->s.periods[w][k] : "";
    hit = tk_match_name(c, all, n);
    return hit < 0 ? -1 : hit % TK_DP_COUNT;
}

/* Whether a minute of the day is in a day period, by the locale's rules. */
static int
tk_in_period(const tk_locale_data *loc, int period, unsigned minute)
{
    unsigned i;
    for (i = 0; i < loc->n_rules; i++) {
        const tk_period_rule *r = &loc->rules[i];
        if (r->period != period)
            continue;
        if (r->from == r->before ? minute == r->from
            : r->from < r->before ? (minute >= r->from && minute < r->before)
                                  : (minute >= r->from || minute < r->before))
            return 1;
    }
    return 0;
}

/* A 12-hour clock's hour made AM or PM by a day period: the reading the
 * period holds, noon and the afternoon being PM. */
static void
tk_period_to_ampm(const tk_locale_data *loc, tk_fields *f, int period)
{
    unsigned h = (unsigned)(f->hour % 12), m = f->has_minute ? (unsigned)f->minute : 0;
    if (period == TK_DP_AM || period == TK_DP_PM)
        f->pm = period == TK_DP_PM;
    else if (period == TK_DP_NOON)
        f->pm = 1;
    else if (period == TK_DP_MIDNIGHT)
        f->pm = 0;
    else
        f->pm = !tk_in_period(loc, period, h * 60 + m) && tk_in_period(loc, period, (h + 12) * 60 + m);
    f->has_ampm = 1;
}

/* Bidirectional marks CLDR puts around signs (U+200E, U+200F, U+061C). */
static void
tk_skip_marks(tk_cursor *c)
{
    for (;;) {
        const unsigned char *s = (const unsigned char *)c->s + c->i;
        STRLEN left = c->len - c->i;
        if (left >= 3 && s[0] == 0xE2 && s[1] == 0x80 && (s[2] == 0x8E || s[2] == 0x8F))
            c->i += 3;
        else if (left >= 2 && s[0] == 0xD8 && s[1] == 0x9C)
            c->i += 2;
        else
            return;
    }
}

/* Literal text of a CLDR string, ignoring case, up to stop (or its end). */
static int
tk_eat_text(tk_cursor *c, const char *s, const char *stop)
{
    STRLEN l = stop ? (STRLEN)(stop - s) : strlen(s), took;
    if (!l)
        return 1;
    took = tk_name_at(c, s, l);
    c->i += took;
    return took > 0;
}

static int tk_eat_text_nomarks(tk_cursor *c, const char *s, const char *stop);

/* The localised GMT format (O, OOOO, ZZZZ): the locale's "GMT+5", "UTC+2",
 * its word for zero, and plain GMT or UTC in any locale. */
static int
tk_parse_gmt(tk_cursor *c, tk_fields *f, const tk_locale_data *loc)
{
    const char *fmt = loc->s.zone_formats[TK_ZF_GMT];
    const char *at = strstr(fmt, "{0}");
    STRLEN save = c->i;
    int matched = 0;
    if (at && tk_eat_text_nomarks(c, fmt, at))
        matched = 1;
    else if (tk_eat_text(c, "GMT", NULL) || tk_eat_text(c, "UTC", NULL))
        matched = 2;
    if (matched) {
        STRLEN before = c->i;
        int sign = 0;
        tk_skip_marks(c);
        {
            /* a space before the sign, as hr's hour format writes its
               negative half (" -HH:mm"): "GMT -4" */
            STRLEN sp = c->i;
            while (c->i < c->len && (c->s[c->i] == ' '
                   || (c->i + 2 <= c->len && (unsigned char)c->s[c->i] == 0xC2 && (unsigned char)c->s[c->i + 1] == 0xA0)
                   || (c->i + 3 <= c->len && (unsigned char)c->s[c->i] == 0xE2 && (unsigned char)c->s[c->i + 1] == 0x80
                       && (unsigned char)c->s[c->i + 2] == 0xAF)))
                c->i += c->s[c->i] == ' ' ? 1 : (unsigned char)c->s[c->i] == 0xC2 ? 2 : 3;
            if (!(tk_peek(c) == '+' || tk_peek(c) == '-'
                  || (c->i + 3 <= c->len && (unsigned char)c->s[c->i] == 0xE2
                      && (((unsigned char)c->s[c->i + 1] == 0x88 && (unsigned char)c->s[c->i + 2] == 0x92)
                          || ((unsigned char)c->s[c->i + 1] == 0x80 && (unsigned char)c->s[c->i + 2] == 0x93)))))
                c->i = sp;
        }
        if (tk_peek(c) == '+' || tk_peek(c) == '-')
            sign = c->s[c->i++] == '-' ? -1 : 1;
        else if (c->i + 3 <= c->len && (unsigned char)c->s[c->i] == 0xE2
                 && (((unsigned char)c->s[c->i + 1] == 0x88 && (unsigned char)c->s[c->i + 2] == 0x92)
                     || ((unsigned char)c->s[c->i + 1] == 0x80 && (unsigned char)c->s[c->i + 2] == 0x93))) {
            sign = -1;                                  /* U+2212 MINUS SIGN, or eu's U+2013 EN DASH */
            c->i += 3;
        }
        if (sign) {
            int64_t h, mi = 0, s = 0;
            /* hours and minutes run together with no colon, "+530" (am's
               HHmm): three digits are one for the hour, four are two */
            STRLEN run = tk_digit_run(c);
            if (run == 3 || run == 4) {
                if (!tk_digits(c, (int)run - 2, &h) || !tk_digits(c, 2, &mi)) {
                    c->i = save;
                    return 0;
                }
            }
            else if (!tk_digits_range(c, 1, 2, &h)
                || ((tk_eat(c, ':') || tk_eat(c, '.'))
                    ? !tk_digits(c, 2, &mi) || (tk_eat(c, ':') && !tk_digits(c, 2, &s))
                    : tk_digit_run(c) >= 2 && !tk_digits(c, 2, &mi))) {
                c->i = save;
                return 0;
            }
            if (matched == 1 && !tk_eat_text_nomarks(c, at + 3, NULL)) {
                tk_fail(c, "the text does not match the zone's format");
                c->i = save;
                return 0;
            }
            f->has_offset = 1;
            f->offset = (int32_t)(sign * (h * 3600 + mi * 60 + s));
            return 1;
        }
        c->i = before;
        if (matched == 1 && !tk_eat_text_nomarks(c, at + 3, NULL)) {
            c->i = save;
            matched = 0;
        }
        else {
            f->has_offset = 1;
            f->offset = 0;
            f->utc = 1;
            return 1;
        }
    }
    c->i = save;
    if (tk_eat_text(c, loc->s.zone_formats[TK_ZF_GMT_ZERO], NULL)) {
        f->has_offset = 1;
        f->offset = 0;
        f->utc = 1;
        return 1;
    }
    return tk_fail(c, "GMT and an offset were wanted");
}

/* Literal text of a CLDR string with its bidirectional marks left out,
 * after any marks in the text; up to stop, or its end. */
static int
tk_eat_text_nomarks(tk_cursor *c, const char *s, const char *stop)
{
    char buf[128];
    STRLEN l = stop ? (STRLEN)(stop - s) : strlen(s), i = 0, n = 0, save = c->i;
    while (i < l && n < sizeof buf - 1) {
        const unsigned char *u = (const unsigned char *)s + i;
        if (i + 3 <= l && u[0] == 0xE2 && u[1] == 0x80 && (u[2] == 0x8E || u[2] == 0x8F))
            i += 3;
        else if (i + 2 <= l && u[0] == 0xD8 && u[1] == 0x9C)
            i += 2;
        else
            buf[n++] = s[i++];
    }
    buf[n] = '\0';
    tk_skip_marks(c);
    if (!n)
        return 1;
    if (tk_eat_text(c, buf, NULL)) {
        tk_skip_marks(c);
        return 1;
    }
    c->i = save;
    return 0;
}

/* The generic location format (VVVV, and v's fallback): the locale's
 * "{0} Time" around a country's name or a city's; or a city alone (VVV).
 * 0 if none matched. */
static int
tk_match_zone_location(tk_cursor *c, tk_fields *f, const tk_locale_data *loc, int with_format)
{
    const char *fmt = loc->s.zone_formats[TK_ZF_REGION];
    const char *at = with_format ? strstr(fmt, "{0}") : NULL;
    STRLEN start = c->i, from, best = 0;
    int best_zone = -1;
    unsigned i;
    if (with_format && (!at || !tk_eat_text_nomarks(c, fmt, at)))
        return 0;
    from = c->i;
    for (i = 0; i < loc->n_territories; i++) {
        STRLEN l = tk_name_at(c, loc->territories[i].name, strlen(loc->territories[i].name));
        if (l > best) {
            unsigned z;
            for (z = 0; z < TK_CLDR_ZONES; z++)
                if (tk_cldr_zones[z].territory == (int16_t)loc->territories[i].id && tk_cldr_zones[z].only) {
                    best = l;
                    best_zone = (int)z;
                    break;
                }
        }
    }
    for (i = 0; i < loc->n_zones; i++)
        if (loc->zones[i].s[TK_ZN_CITY]) {
            STRLEN l = tk_name_at(c, loc->zones[i].s[TK_ZN_CITY], strlen(loc->zones[i].s[TK_ZN_CITY]));
            if (l > best) {
                best = l;
                best_zone = loc->zones[i].id;
            }
        }
    for (i = 0; i < TK_CLDR_ZONES; i++) {
        char city[64];
        const char *name = tk_cldr_zones[i].name, *last = strrchr(name, '/');
        STRLEN k = 0, l;
        if (tk_names_find(loc->zones, loc->n_zones, i) && tk_names_find(loc->zones, loc->n_zones, i)->s[TK_ZN_CITY])
            continue;
        for (last = last ? last + 1 : name; *last && k < sizeof city - 1; last++)
            city[k++] = *last == '_' ? ' ' : *last;
        city[k] = '\0';
        l = tk_name_at(c, city, k);
        if (l > best) {
            best = l;
            best_zone = (int)i;
        }
    }
    if (best_zone < 0) {
        c->i = start;
        return 0;
    }
    c->i = from + best;
    if (with_format && at[3] && !tk_eat_text_nomarks(c, at + 3, NULL)) {
        c->i = start;
        return 0;
    }
    f->zone = tk_cldr_zones[best_zone].iana;
    f->zone_len = strlen(f->zone);
    return 1;
}

/* A zone by one of its names in the locale (z, zzzz, v, vvvv): a zone's
 * own name, or a metazone's, which names its golden zone. A specific name
 * also says standard or daylight time. 0 if none matched. */
static int
tk_match_zone_name(tk_cursor *c, tk_fields *f, const tk_locale_data *loc, int generic, int is_long)
{
    STRLEN best = 0, start = c->i;
    int best_zone = -1, best_kind = -1, pass, k;
    int kinds[3], nk = 0;
    int base = is_long ? TK_ZN_LONG_GENERIC : TK_ZN_SHORT_GENERIC;
    if (generic) {
        kinds[nk++] = base;
        kinds[nk++] = base + 1;
    }
    else {
        kinds[nk++] = base + 1;
        kinds[nk++] = base + 2;
    }
    for (pass = 0; pass < 2; pass++) {
        const tk_zone_names *list = pass ? loc->metazones : loc->zones;
        unsigned n = pass ? loc->n_metazones : loc->n_zones, i;
        for (i = 0; i < n; i++)
            for (k = 0; k < nk; k++) {
                const char *s = list[i].s[kinds[k]];
                STRLEN l;
                if (!s)
                    continue;
                c->i = start;
                l = tk_name_at(c, s, strlen(s));
                if (l > best) {
                    int z = pass ? tk_metazone_golden[list[i].id] : (int)list[i].id;
                    if (z < 0)
                        continue;
                    best = l;
                    best_zone = z;
                    best_kind = kinds[k];
                }
            }
    }
    c->i = start;
    if (best_zone < 0)
        return 0;
    c->i += best;
    f->zone = tk_cldr_zones[best_zone].iana;
    f->zone_len = strlen(f->zone);
    if (!generic)
        f->dst_hint = best_kind == base + 2 ? 2 : 1;
    return 1;
}

static int tk_parse_cldr(tk_cursor *c, tk_fields *f, const tk_locale_data *loc,
                         const char *p, STRLEN plen);

/* ---- strptime -------------------------------------------------------------- */

static int
tk_strptime_part(tk_cursor *c, tk_fields *f, const tk_locale_data *loc, const char *p, STRLEN plen)
{
    STRLEN k = 0;
    while (k < plen) {
        char spec;
        int64_t v;
        if (isSPACE(p[k])) {                       /* white space matches any, or none */
            while (k < plen && isSPACE(p[k])) k++;
            tk_skip_space(c);
            continue;
        }
        if (p[k] != '%') {
            if (c->i >= c->len || c->s[c->i] != p[k])
                return tk_fail(c, "the text does not match the pattern");
            c->i++;
            k++;
            continue;
        }
        k++;
        while (k < plen && (p[k] == '-' || p[k] == '_' || p[k] == '0' || p[k] == '^'))
            k++;                                   /* flags change nothing when reading */
        {
            int width = 0, has_width = 0;
            while (k < plen && isDIGIT(p[k])) {
                width = width * 10 + (p[k++] - '0');
                has_width = 1;
            }
            if (k >= plen)
                return tk_fail(c, "the pattern ends in a %");
            spec = p[k++];
            if (spec != '%' && spec != 'n' && spec != 't' && spec != 'Z' && spec != 'z'
                && spec != 'p' && spec != 'P' && spec != 'a' && spec != 'A' && spec != 'b'
                && spec != 'B' && spec != 'h')
                tk_skip_space(c);                  /* as C's strptime, numbers may have spaces before */
            switch (spec) {
            case 'a': case 'A': {
                unsigned d = tk_match_day(c, loc);
                if (!d) return tk_fail(c, "a day's name was wanted");
                f->has_wday = 1; f->wday = d;
                break;
            }
            case 'b': case 'B': case 'h': {
                unsigned m = f->calendar ? tk_match_cal_month(c, f, loc) : tk_match_month(c, loc);
                if (!m) return tk_fail(c, "a month's name was wanted");
                f->has_month = 1; f->month = m; f->month_slot = f->calendar != 0;
                break;
            }
            case 'C': if (!tk_signed(c, 2, &v)) return 0; f->has_century = 1; f->century = v; break;
            case 'd': case 'e': if (!tk_digits_range(c, 1, 2, &v)) return 0; f->has_day = 1; f->day = (unsigned)v; break;
            case 'D': if (!tk_strptime_part(c, f, loc, "%m/%d/%y", 8)) return 0; break;
            case 'F': if (!tk_strptime_part(c, f, loc, "%Y-%m-%d", 8)) return 0; break;
            case 'g': if (!tk_digits_range(c, 1, 2, &v)) return 0; f->has_isoweek = 1; f->week_year = v < 69 ? 2000 + v : 1900 + v; break;
            case 'G': if (!tk_signed(c, 4, &v)) return 0; f->has_isoweek = 1; f->week_year = v; break;
            case 'H': case 'k': if (!tk_digits_range(c, 1, 2, &v)) return 0; f->has_hour = 1; f->hour = (int)v; break;
            case 'I': case 'l': if (!tk_digits_range(c, 1, 2, &v)) return 0; f->has_hour = 1; f->has_hour12 = 1; f->hour = (int)v; break;
            case 'j': if (!tk_digits_range(c, 1, 3, &v)) return 0; f->has_doy = 1; f->doy = (unsigned)v; break;
            case 'm': if (!tk_digits_range(c, 1, 2, &v)) return 0; f->has_month = 1; f->month = (unsigned)v; break;
            case 'M': if (!tk_digits_range(c, 1, 2, &v)) return 0; f->has_minute = 1; f->minute = (int)v; break;
            case 'n': case 't': tk_skip_space(c); break;
            case 'N': {
                int32_t ns = 0;
                int fd = 0, n = has_width ? width : 9;
                STRLEN avail = tk_digit_run(c);
                if (avail < (STRLEN)(n < 1 ? 1 : n))
                    return tk_fail(c, "digits of a fraction were wanted");
                {
                    tk_cursor sub = *c;
                    sub.len = c->i + (STRLEN)n;
                    if (!tk_fraction(&sub, &ns, &fd)) return 0;
                    c->i = sub.i;
                }
                f->nsec = ns;
                break;
            }
            case 'p': case 'P': if (!tk_match_ampm(c, loc, f)) return 0; break;
            case 'r': if (!tk_strptime_part(c, f, loc, "%I:%M:%S %p", 11)) return 0; break;
            case 'R': if (!tk_strptime_part(c, f, loc, "%H:%M", 5)) return 0; break;
            case 's': {
                if (!tk_signed(c, 18, &v)) return 0;
                f->has_epoch = 1;
                f->epoch.sec = v;
                f->epoch.nsec = 0;
                break;
            }
            case 'S': if (!tk_digits_range(c, 1, 2, &v)) return 0; f->has_second = 1; f->second = (int)v; break;
            case 'T': if (!tk_strptime_part(c, f, loc, "%H:%M:%S", 8)) return 0; break;
            case 'u': if (!tk_digits(c, 1, &v)) return 0; f->has_wday = 1; f->wday = (unsigned)v; break;
            case 'w': if (!tk_digits(c, 1, &v)) return 0; f->has_wday = 1; f->wday = v == 0 ? 7 : (unsigned)v; break;
            case 'U': if (!tk_digits_range(c, 1, 2, &v)) return 0; f->has_week_sun = 1; f->week = (unsigned)v; break;
            case 'W': if (!tk_digits_range(c, 1, 2, &v)) return 0; f->has_week_mon = 1; f->week = (unsigned)v; break;
            case 'V': if (!tk_digits_range(c, 1, 2, &v)) return 0; f->has_isoweek = 1; f->week = (unsigned)v; break;
            case 'y': if (!tk_digits_range(c, 1, 2, &v)) return 0; f->has_y2 = 1; f->y2 = (int)v; break;
            case 'Y': if (!tk_signed(c, 4, &v)) return 0; f->has_year = 1; f->year = v; break;
            case 'z': if (!tk_offset_field(c, f, 1)) return 0; break;
            case 'Z': if (!tk_abbr_field(c, f)) return 0; break;
            case 'c':
                if (!tk_parse_cldr(c, f, loc, loc->s.date_formats[TK_LEN_MEDIUM], strlen(loc->s.date_formats[TK_LEN_MEDIUM])))
                    return 0;
                if (!tk_eat(c, ',')) return tk_fail(c, "a , was wanted");
                tk_skip_space(c);
                if (!tk_parse_cldr(c, f, loc, loc->s.time_formats[TK_LEN_MEDIUM], strlen(loc->s.time_formats[TK_LEN_MEDIUM])))
                    return 0;
                break;
            case 'x': if (!tk_parse_cldr(c, f, loc, loc->s.date_formats[TK_LEN_MEDIUM], strlen(loc->s.date_formats[TK_LEN_MEDIUM]))) return 0; break;
            case 'X': if (!tk_parse_cldr(c, f, loc, loc->s.time_formats[TK_LEN_MEDIUM], strlen(loc->s.time_formats[TK_LEN_MEDIUM]))) return 0; break;
            case '%': if (!tk_eat(c, '%')) return tk_fail(c, "a % was wanted"); break;
            default:
                return tk_fail(c, "the pattern has a conversion that cannot be read");
            }
        }
    }
    return 1;
}

/* The whole text, read by the whole pattern. */
static int
tk_strptime(tk_cursor *c, tk_fields *f, const tk_locale_data *loc, const char *p, STRLEN plen)
{
    if (!tk_strptime_part(c, f, loc, p, plen))
        return 0;
    if (!tk_at_end(c))
        return tk_fail(c, "text was left over");
    return 1;
}

/* ---- CLDR patterns ------------------------------------------------------------ */

/* A number in one of the systems CLDR attaches to some calendars' patterns,
 * where digits were wanted: the days of a lunar month (hanidays, 初六),
 * Chinese numerals as digits (hanidec, 二〇二六), lower-case Roman numerals
 * (romanlow), the first year of a Japanese era (元), and Hebrew numerals (hebr: ד׳, תשפ״ז, ה׳תשפ״ז), a
 * year written without its thousands being in the sixth millennium, as the
 * writer leaves them out. The patterns handed out carry no numbering, so
 * the reader takes these wherever a day, a month or a year is wanted. */
static int
tk_alt_number(tk_cursor *c, int is_year, int64_t *v)
{
    static const int hebr[27] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 20, 30, 40, 40, 50, 50, 60, 70, 80, 80, 90, 90, 100, 200, 300, 400 };
    const unsigned char *u = (const unsigned char *)c->s;
    STRLEN i = c->i, best = 0;
    int k, bi = -1;
    for (k = 1; k <= 30; k++) {
        STRLEN took = tk_name_at(c, tk_hanidays[k], strlen(tk_hanidays[k]));
        if (took > best) {
            best = took;
            bi = k;
        }
    }
    if (bi > 0) {
        c->i += best;
        *v = bi;
        return 1;
    }
    {
        int64_t n = 0;
        int got = 0;
        while (c->i + 3 <= c->len) {
            int d = -1;
            for (k = 0; k < 10; k++)
                if (memEQ(c->s + c->i, tk_hanidec_digits[k], 3))
                    d = k;
            if (d < 0)
                break;
            n = n * 10 + d;
            c->i += 3;
            got++;
        }
        if (got) {
            *v = n;
            return 1;
        }
    }
    {
        /* romanlow, CLDR's lower-case Roman numerals (haw's months: x, iii) */
        static const char ro[] = "ivxlcdm";
        static const int rv[] = { 1, 5, 10, 50, 100, 500, 1000 };
        int64_t n = 0;
        int prev = 0, got = 0;
        STRLEN j = c->i;
        while (j < c->len && strchr(ro, c->s[j]) && c->s[j]) {
            int val = rv[strchr(ro, c->s[j]) - ro];
            n += val;
            if (prev && val > prev)
                n -= 2 * prev;
            prev = val;
            j++;
            got++;
        }
        if (got && (j == c->len || !isALPHA(c->s[j]))) {
            c->i = j;
            *v = n;
            return 1;
        }
    }
    if (i + 3 <= c->len && memEQ(c->s + i, "\345\205\203", 3)) {
        c->i += 3;
        *v = 1;
        return 1;
    }
    {
        int64_t sum = 0, thousands = 0;
        int letters = 0;
        while (i + 2 <= c->len && u[i] == 0xD7) {
            if (u[i + 1] >= 0x90 && u[i + 1] <= 0xAA) {
                sum += hebr[u[i + 1] - 0x90];
                letters++;
                i += 2;
            }
            else if (u[i + 1] == 0xB3 || u[i + 1] == 0xB4) {
                /* a geresh after a group with letters after it: thousands */
                i += 2;
                if (u[i - 1] == 0xB3 && i + 2 <= c->len && u[i] == 0xD7 && u[i + 1] >= 0x90 && u[i + 1] <= 0xAA) {
                    thousands = sum;
                    sum = 0;
                }
            }
            else
                break;
        }
        if (letters) {
            c->i = i;
            *v = thousands * 1000 + sum;
            if (is_year && !thousands && *v < 1000)
                *v += 5000;
            return 1;
        }
    }
    return 0;
}

/* A run of digits for a field of n letters: exactly n when the next part
 * of the pattern is another field with no text between, else 1 to max. */
static int
tk_cldr_digits(tk_cursor *c, int n, int adjacent, int max, int64_t *v)
{
    if (adjacent || n > 2)
        return tk_digits(c, n < max ? (n > 1 ? n : 1) : max, v) ? 1 : 0;
    return tk_digits_range(c, n, max, v);
}

static int
tk_parse_cldr(tk_cursor *c, tk_fields *f, const tk_locale_data *loc, const char *p, STRLEN plen)
{
    STRLEN k = 0;
    int period = -1;
    while (k < plen) {
        char ch = p[k];
        if (ch == '\'') {
            if (k + 1 < plen && p[k + 1] == '\'') {
                if (!tk_eat(c, '\'')) return tk_fail(c, "a ' was wanted");
                k += 2;
                continue;
            }
            k++;
            while (k < plen) {
                if (p[k] == '\'') {
                    if (k + 1 < plen && p[k + 1] == '\'') {
                        if (!tk_eat(c, '\'')) return tk_fail(c, "a ' was wanted");
                        k += 2;
                        continue;
                    }
                    k++;
                    break;
                }
                if (!tk_eat_ci(c, p[k]))
                    return tk_fail(c, "the text does not match the pattern");
                k++;
            }
            continue;
        }
        if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')) {
            int n = 0, adjacent;
            int64_t v;
            while (k < plen && p[k] == ch) { n++; k++; }
            /* a numeric field met by another with nothing between reads its
               own width; one met by a name ("d" then "EEEE", "25星期三")
               reads all its digits */
            adjacent = 0;
            if (k < plen && ((p[k] >= 'a' && p[k] <= 'z') || (p[k] >= 'A' && p[k] <= 'Z'))) {
                STRLEN r = 1;
                while (k + r < plen && p[k + r] == p[k])
                    r++;
                adjacent = strchr("yuYrdDHhKkmsSwWeQq", p[k]) || ((p[k] == 'M' || p[k] == 'L') && r <= 2) || (p[k] == 'c' && r <= 2);
            }
            switch (ch) {
            case 'G': {
                const char *all[6];
                int w, m = 0, hit;
                if (f->calendar) {
                    const tk_calendar *cal = &tk_calendars[f->calendar - 1];
                    const tk_cal_names *cn = (const tk_cal_names *)f->cal_names;
                    const char *names[3 * 237];
                    unsigned k;
                    for (w = 0; w < TK_W_COUNT; w++)
                        for (k = 0; k < cal->n_eras; k++)
                            names[w * cal->n_eras + k] = tk_cal_era_name(cn, cal, k, w);
                    hit = tk_match_name(c, names, (int)(3 * cal->n_eras));
                    if (hit < 0) return tk_fail(c, "an era was wanted");
                    f->has_era = 1;
                    f->era_index = (unsigned)hit % cal->n_eras;
                    break;
                }
                for (w = 0; w < TK_W_COUNT; w++) { all[m++] = loc->s.eras[w][0]; all[m++] = loc->s.eras[w][1]; }
                hit = tk_match_name(c, all, m);
                if (hit < 0) return tk_fail(c, "an era was wanted");
                f->era_bc = hit % 2 == 0;   /* applied to the year when the value is made */
                break;
            }
            case 'r':
                if (!tk_signed(c, 9, &v)) return 0;
                f->has_related = 1;
                f->related = v;
                break;
            case 'U':
                if (f->calendar && (f->calendar - 1 == TK_CAL_CHINESE || f->calendar - 1 == TK_CAL_DANGI)) {
                    const tk_cal_names *cn = (const tk_cal_names *)f->cal_names;
                    const char *names[180];
                    int w, k, hit;
                    for (w = 0; w < 3; w++)
                        for (k = 1; k <= 60; k++)
                            names[w * 60 + k - 1] = tk_cal_cyclic_name(cn, k, w);
                    hit = tk_match_name(c, names, 180);
                    if (hit < 0) return tk_fail(c, "a cyclic year's name was wanted");
                    f->has_cyclic = 1;
                    f->cyclic = (unsigned)(hit % 60) + 1;
                    break;
                }
                /* fall through: a year */
            case 'y': case 'u':
                if (f->calendar)
                    f->year_kind = ch == 'u' ? 2 : 1;
                if (f->calendar && tk_alt_number(c, 1, &v)) {
                    f->has_year = 1; f->year = v;
                }
                else if (n == 2) {
                    if (!tk_digits(c, 2, &v)) return 0;
                    f->has_y2 = 1; f->y2 = (int)v;
                }
                else if (adjacent) {
                    /* another field follows with nothing between: exactly n digits */
                    if (!tk_digits(c, n > 1 ? n : 4, &v)) return 0;
                    f->has_year = 1; f->year = v;
                }
                else {
                    if (!tk_signed(c, n > 9 ? n : 9, &v)) return 0;
                    f->has_year = 1; f->year = v;
                }
                break;
            case 'Y':
                if (f->calendar) {
                    /* the calendar's year, as the writer writes it */
                    f->year_kind = 1;
                    if (n == 2) {
                        if (!tk_digits(c, 2, &v)) return 0;
                        f->has_y2 = 1; f->y2 = (int)v;
                    }
                    else {
                        if (!tk_signed(c, 9, &v)) return 0;
                        f->has_year = 1; f->year = v;
                    }
                    break;
                }
                if (!tk_signed(c, 9, &v)) return 0;
                if (n == 2) v = v < 69 ? 2000 + v : 1900 + v;
                f->has_isoweek = 1; f->week_year = v;
                break;
            case 'Q': case 'q':
                if (n <= 2) { if (!tk_cldr_digits(c, n, adjacent, 1, &v)) return 0; }
                else {
                    const char *all[TK_CTX_COUNT * 2 * 4];
                    int cx, w, q, m = 0, hit;
                    for (cx = 0; cx < TK_CTX_COUNT; cx++) for (w = 0; w < 2; w++) for (q = 0; q < 4; q++)
                        all[m++] = loc->s.quarters[cx][w][q];
                    hit = tk_match_name(c, all, m);
                    if (hit < 0) return tk_fail(c, "a quarter was wanted");
                }
                break;   /* a quarter alone fixes no date: read and passed over */
            case 'M': case 'L':
                if (f->calendar && n <= 2) {
                    /* a slot number, perhaps wrapped in the numeric leap pattern ({0}bis) */
                    const tk_cal_names *cn = (const tk_cal_names *)f->cal_names;
                    const char *pat = tk_cal_leap_pattern(cn, TK_CTX_FORMAT, TK_W_ABBR, 1);
                    const char *at = pat ? strstr(pat, "{0}") : NULL;
                    STRLEN save = c->i;
                    int leap = 0;
                    if (at) {
                        STRLEN pre = (STRLEN)(at - pat), took = pre ? tk_name_at(c, pat, pre) : 0;
                        if (!pre || took) {
                            c->i += took;
                            if (tk_cldr_digits(c, n, adjacent, 2, &v)) {
                                STRLEN sl = at[3] ? tk_name_at(c, at + 3, strlen(at + 3)) : 0;
                                if (!at[3] || sl) {
                                    c->i += sl;
                                    leap = 1;
                                }
                            }
                        }
                        if (!leap) {
                            c->i = save;
                            c->err = NULL;
                        }
                    }
                    if (!leap && !tk_cldr_digits(c, n, adjacent, 2, &v)) {
                        if (!tk_alt_number(c, 0, &v)) return 0;
                        c->err = NULL;
                    }
                    f->has_month = 1; f->month = (unsigned)v; f->leap_month_text = leap; f->month_slot = 0;
                }
                else if (f->calendar) {
                    unsigned m = tk_match_cal_month(c, f, loc);
                    if (!m) return tk_fail(c, "a month's name was wanted");
                    f->has_month = 1; f->month = m; f->month_slot = 1;
                }
                else if (n <= 2) {
                    if (!tk_cldr_digits(c, n, adjacent, 2, &v)) return 0;
                    f->has_month = 1; f->month = (unsigned)v;
                }
                else {
                    unsigned m = tk_match_month(c, loc);
                    if (!m) return tk_fail(c, "a month's name was wanted");
                    f->has_month = 1; f->month = m;
                }
                break;
            case 'w': if (!tk_cldr_digits(c, n, adjacent, 2, &v)) return 0; f->has_isoweek = 1; f->week = (unsigned)v; break;
            case 'd':
                if (!tk_cldr_digits(c, n, adjacent, 2, &v)) {
                    if (!tk_alt_number(c, 0, &v)) return 0;
                    c->err = NULL;
                }
                f->has_day = 1; f->day = (unsigned)v; break;
            case 'D': if (!tk_cldr_digits(c, n, adjacent, 3, &v)) return 0; f->has_doy = 1; f->doy = (unsigned)v; break;
            case 'E':
                {
                    unsigned d = tk_match_day(c, loc);
                    if (!d) return tk_fail(c, "a day's name was wanted");
                    f->has_wday = 1; f->wday = d;
                }
                break;
            case 'e': case 'c':
                if (n <= 2) {
                    if (!tk_cldr_digits(c, n, adjacent, 1, &v)) return 0;
                    f->has_wday = 1;
                    f->wday = (unsigned)((v - 1 + loc->first_day - 1) % 7 + 1);
                }
                else {
                    unsigned d = tk_match_day(c, loc);
                    if (!d) return tk_fail(c, "a day's name was wanted");
                    f->has_wday = 1; f->wday = d;
                }
                break;
            case 'a': if (!tk_match_ampm(c, loc, f)) return 0; break;
            case 'b': case 'B':
                if ((period = tk_match_period(c, loc)) < 0) return tk_fail(c, "a period of the day was wanted");
                break;
            case 'h': case 'K':
                if (!tk_cldr_digits(c, n, adjacent, 2, &v)) return 0;
                f->has_hour = 1; f->has_hour12 = 1; f->hour = (int)(ch == 'K' && v == 0 ? 12 : v);
                break;
            case 'H': case 'k':
                if (!tk_cldr_digits(c, n, adjacent, 2, &v)) return 0;
                f->has_hour = 1; f->hour = (int)(ch == 'k' && v == 24 ? 0 : v);
                break;
            case 'j':
                if (!tk_cldr_digits(c, n, adjacent, 2, &v)) return 0;
                f->has_hour = 1; f->hour = (int)v;
                if (!loc->hour_cycle_24) f->has_hour12 = 1;
                break;
            case 'm': if (!tk_cldr_digits(c, n, adjacent, 2, &v)) return 0; f->has_minute = 1; f->minute = (int)v; break;
            case 's': if (!tk_cldr_digits(c, n, adjacent, 2, &v)) return 0; f->has_second = 1; f->second = (int)v; break;
            case 'S': {
                tk_cursor sub = *c;
                int32_t ns;
                int fd;
                if (tk_digit_run(c) < (STRLEN)n) return tk_fail(c, "digits of a fraction were wanted");
                sub.len = c->i + (STRLEN)n;
                if (!tk_fraction(&sub, &ns, &fd)) return 0;
                c->i = sub.i;
                f->nsec = ns;
                break;
            }
            case 'z': case 'v': case 'V':
                if (ch != 'V') {
                    /* the longer of a name and the GMT format; the name on a tie */
                    STRLEN st = c->i, g_end = 0;
                    tk_fields saved = *f, gf = *f;
                    if (tk_parse_gmt(c, &gf, loc))
                        g_end = c->i;
                    c->i = st;
                    if (tk_match_zone_name(c, f, loc, ch == 'v', n >= 4) && c->i >= g_end)
                        break;
                    *f = saved;
                    c->i = st;
                    if (ch == 'v' && tk_match_zone_location(c, f, loc, 1) && c->i >= g_end)
                        break;
                    *f = saved;
                    if (g_end) {
                        *f = gf;
                        c->i = g_end;
                        break;
                    }
                    c->i = st;
                }
                if (ch == 'z' && n < 4 && (tk_peek(c) == '+' || tk_peek(c) == '-'))
                    return tk_offset_field(c, f, 1);
                if (ch == 'V' && n >= 3 && tk_match_zone_location(c, f, loc, n == 4))
                    break;
                if (ch == 'V' && n == 4 && tk_parse_gmt(c, f, loc))
                    break;
                if (n >= 4 || ch == 'V') {
                    STRLEN start = c->i;
                    while (c->i < c->len && (tk_is_word((unsigned char)c->s[c->i]) || c->s[c->i] == '/'
                                             || c->s[c->i] == '-' || c->s[c->i] == '+'))
                        c->i++;
                    if (c->i == start) return tk_fail(c, "a zone's name was wanted");
                    f->zone = c->s + start; f->zone_len = c->i - start;
                }
                else if (!tk_abbr_field(c, f))
                    return 0;
                break;
            case 'Z': case 'X': case 'x': case 'O':
                if (ch == 'O' || (ch == 'Z' && n == 4)) {
                    if (!tk_parse_gmt(c, f, loc)) return 0;
                }
                else if (!tk_offset_field(c, f, ch != 'x'))
                    return 0;
                break;
            default:
                return tk_fail(c, "the pattern has a field that cannot be read");
            }
            continue;
        }
        {
            /* white space, and CLDR's narrow no-break space (U+202F) and
             * no-break space (U+00A0), matches any of them, or none */
            STRLEN skip = 0;
            if (isSPACE(ch)) skip = 1;
            else if ((unsigned char)ch == 0xE2 && k + 2 < plen && (unsigned char)p[k + 1] == 0x80
                     && (unsigned char)p[k + 2] == 0xAF) skip = 3;
            else if ((unsigned char)ch == 0xC2 && k + 1 < plen && (unsigned char)p[k + 1] == 0xA0) skip = 2;
            if (skip) {
                k += skip;
                while (c->i < c->len) {
                    if (isSPACE(c->s[c->i])) c->i++;
                    else if ((unsigned char)c->s[c->i] == 0xE2 && c->i + 2 < c->len
                             && (unsigned char)c->s[c->i + 1] == 0x80 && (unsigned char)c->s[c->i + 2] == 0xAF) c->i += 3;
                    else if ((unsigned char)c->s[c->i] == 0xC2 && c->i + 1 < c->len
                             && (unsigned char)c->s[c->i + 1] == 0xA0) c->i += 2;
                    else break;
                }
                continue;
            }
        }
        /* a full stop after a name that ends in one ("d. MMM. y" with ksh's
           "Okt."): the writer writes one, as ICU does */
        if (ch == '.' && c->i > 0 && c->s[c->i - 1] == '.' && (c->i >= c->len || c->s[c->i] != '.')) {
            k++;
            continue;
        }
        if (!tk_eat_ci(c, ch))
            return tk_fail(c, "the text does not match the pattern");
        k++;
    }
    if (period >= 0 && f->has_hour12 && !f->has_ampm)
        tk_period_to_ampm(loc, f, period);
    return 1;
}

#endif
