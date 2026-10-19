#ifndef TKR_RRULE_H
#define TKR_RRULE_H

/* RFC 5545 section 3.3.10: the RECUR value read into a tkr_rule and written
 * back in one canonical form. Parts may come in any order and each at most
 * once; FREQ is required; UNTIL and COUNT exclude each other; every value
 * is range checked; the RFC's rules about which parts may meet are
 * enforced; and an unknown part is an error here, not ignored as the RFC
 * allows, since a scheduler must not fire a rule it half understood. The
 * error text names the part and the value. */

#define TKR_ERR 200

static void
tkr_err(char *err, const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(err, TKR_ERR, fmt, ap);
    va_end(ap);
}

/* Equal ignoring case over len bytes: the dist's own, so the parsers need no interpreter. */
static int
tkr_ieq(const char *a, const char *b, size_t len)
{
    while (len--) {
        unsigned char x = (unsigned char)*a++, y = (unsigned char)*b++;   /* the macros read their argument twice */
        if (toLOWER(x) != toLOWER(y))
            return 0;
    }
    return 1;
}

/* A whole non-negative number, or -1. */
static long
tkr_num(const char *s, size_t len, int allow_sign, int *neg)
{
    long v = 0;
    size_t i = 0;
    *neg = 0;
    if (len && (s[0] == '+' || s[0] == '-')) {
        if (!allow_sign)
            return -1;
        *neg = s[0] == '-';
        i = 1;
    }
    if (i >= len || len - i > 9)
        return -1;
    for (; i < len; i++) {
        if (!isDIGIT(s[i]))
            return -1;
        v = v * 10 + (s[i] - '0');
    }
    return v;
}

/* MO .. SU, any case; -1 if not one. */
static int
tkr_weekday_of(const char *s, size_t len)
{
    int i;
    if (len != 2)
        return -1;
    for (i = 0; i < 7; i++)
        if (toUPPER(s[0]) == tkr_day_names[i][0] && toUPPER(s[1]) == tkr_day_names[i][1])
            return i;
    return -1;
}

/* YYYYMMDD, YYYYMMDDTHHMMSS or YYYYMMDDTHHMMSSZ. */
static int
tkr_parse_until(const char *v, size_t len, tkr_rule *r, char *err)
{
    long y, mo, d, h = 0, mi = 0, s = 0;
    int neg;
    int kind;
    if (len == 8) kind = TKR_UNTIL_DATE;
    else if (len == 15 && v[8] == 'T') kind = TKR_UNTIL_FLOATING;
    else if (len == 16 && v[8] == 'T' && v[15] == 'Z') kind = TKR_UNTIL_UTC;
    else {
        tkr_err(err, "UNTIL=%.*s is not a date (YYYYMMDD) or a date and time (YYYYMMDDTHHMMSS, with Z for UTC)", (int)len, v);
        return 0;
    }
    y = tkr_num(v, 4, 0, &neg); mo = tkr_num(v + 4, 2, 0, &neg); d = tkr_num(v + 6, 2, 0, &neg);
    if (kind != TKR_UNTIL_DATE) {
        h = tkr_num(v + 9, 2, 0, &neg); mi = tkr_num(v + 11, 2, 0, &neg); s = tkr_num(v + 13, 2, 0, &neg);
    }
    if (y < 0 || mo < 1 || mo > 12 || d < 1 || (unsigned)d > tkr_days_in_month(y, (unsigned)mo)
        || h < 0 || h > 23 || mi < 0 || mi > 59 || s < 0 || s > 60) {
        tkr_err(err, "UNTIL=%.*s is not a date that exists", (int)len, v);
        return 0;
    }
    r->until_kind = (uint8_t)kind;
    r->until_sec = tkr_days_from_civil(y, (unsigned)mo, (unsigned)d) * 86400 + h * 3600 + mi * 60 + s;
    return 1;
}

/* One part. */
static int
tkr_rrule_part(const char *name, size_t nlen, const char *val, size_t vlen, tkr_rule *r, uint32_t *seen, const int *rscale, char *err)
{
    char key[16];
    size_t i;
    const char *p = val, *end = val + vlen;
    int bit;
    if (nlen == 0 || nlen >= sizeof key) {
        tkr_err(err, "'%.*s' is not an RRULE part", (int)(nlen < 40 ? nlen : 40), name);
        return 0;
    }
    for (i = 0; i < nlen; i++)
        key[i] = (char)toUPPER(name[i]);
    key[nlen] = '\0';
    {
        static const char *const parts[] = { "FREQ", "UNTIL", "COUNT", "INTERVAL", "BYSECOND", "BYMINUTE", "BYHOUR",
                                             "BYDAY", "BYMONTHDAY", "BYYEARDAY", "BYWEEKNO", "BYMONTH", "BYSETPOS", "WKST",
                                             "RSCALE", "SKIP" };
        for (bit = 0; bit < 16; bit++)
            if (strEQ(key, parts[bit]))
                break;
        if (bit == 16) {
            tkr_err(err, "'%s' is not an RRULE part", key);
            return 0;
        }
        if (*seen & (1u << bit)) {
            tkr_err(err, "%s is given twice", key);
            return 0;
        }
        *seen |= 1u << bit;
    }
    if (vlen == 0) {
        tkr_err(err, "%s has no value", key);
        return 0;
    }
    if (bit == 0) {              /* FREQ */
        int f;
        for (f = 0; f < 7; f++)
            if (vlen == strlen(tkr_freq_names[f]) && tkr_ieq(val, tkr_freq_names[f], vlen))
                break;
        if (f == 7) {
            tkr_err(err, "FREQ=%.*s is not one of SECONDLY, MINUTELY, HOURLY, DAILY, WEEKLY, MONTHLY, YEARLY", (int)vlen, val);
            return 0;
        }
        r->freq = (uint8_t)f;
        return 1;
    }
    if (bit == 1)                /* UNTIL */
        return tkr_parse_until(val, vlen, r, err);
    if (bit == 2 || bit == 3) {  /* COUNT, INTERVAL */
        int neg;
        long v = tkr_num(val, vlen, 0, &neg);
        if (v < 1) {
            tkr_err(err, "%s=%.*s is not a whole number above zero", key, (int)vlen, val);
            return 0;
        }
        if (bit == 2) r->count = v; else r->interval = (uint32_t)v;
        return 1;
    }
    if (bit == 14) {             /* RSCALE: a calendar Time::Keeper knows */
        int c = tkr_tk_table ? (tkr_tk_table->calendar_find)(val, vlen) : -1;
        if (c < 0 || c > 255) {
            tkr_err(err, "RSCALE=%.*s names no calendar Time::Keeper knows", (int)(vlen < 40 ? vlen : 40), val);
            return 0;
        }
        r->calendar = (uint8_t)c;
        r->flags |= TKR_F_RSCALE;
        return 1;
    }
    if (bit == 15) {             /* SKIP */
        int s;
        for (s = 0; s < 3; s++)
            if (vlen == strlen(tkr_skip_upper[s]) && tkr_ieq(val, tkr_skip_upper[s], vlen))
                break;
        if (s == 3) {
            tkr_err(err, "SKIP=%.*s is not one of OMIT, BACKWARD, FORWARD", (int)(vlen < 40 ? vlen : 40), val);
            return 0;
        }
        r->skip = (uint8_t)s;
        return 1;
    }
    if (bit == 13) {             /* WKST */
        int w = tkr_weekday_of(val, vlen);
        if (w < 0) {
            tkr_err(err, "WKST=%.*s is not a weekday MO to SU", (int)vlen, val);
            return 0;
        }
        r->wkst = (uint8_t)w;
        return 1;
    }
    /* the lists */
    while (p < end) {
        const char *e = p;
        size_t len;
        int neg;
        long v;
        while (e < end && *e != ',')
            e++;
        len = (size_t)(e - p);
        if (len == 0) {
            tkr_err(err, "%s has an empty value", key);
            return 0;
        }
        if (bit == 7) {          /* BYDAY: an optional [+-]ordinal, then MO .. SU */
            size_t k = 0;
            int ord = 0, oneg = 0, ndig = 0, w;
            if (p[0] == '+' || p[0] == '-') {
                oneg = p[0] == '-';
                k = 1;
            }
            while (k < len && isDIGIT(p[k]) && ndig < 3) {
                ord = ord * 10 + (p[k] - '0');
                k++;
                ndig++;
            }
            w = tkr_weekday_of(p + k, len - k);
            if (w < 0 || (k > 0 && (ndig == 0 || ord < 1 || ord > 53))) {
                tkr_err(err, "BYDAY=%.*s is not a weekday, with an ordinal 1 to 53 or -1 to -53 before it", (int)len, p);
                return 0;
            }
            if (k == 0) r->by_day_any |= (uint8_t)(1u << w);
            else if (oneg) r->by_day_neg[w] |= UINT64_C(1) << ord;
            else r->by_day_pos[w] |= UINT64_C(1) << ord;
        }
        else {
            int lo, hi, signed_ok, leap = 0;
            if (bit == 11 && len > 1 && (p[len - 1] == 'L' || p[len - 1] == 'l')) {
                if (!*rscale) {
                    tkr_err(err, "BYMONTH=%.*s: a leap month needs RSCALE", (int)len, p);
                    return 0;
                }
                leap = 1;
                len--;
            }
            switch (bit) {
            case 4:  lo = 0; hi = 60; signed_ok = 0; break;   /* BYSECOND */
            case 5:  lo = 0; hi = 59; signed_ok = 0; break;   /* BYMINUTE */
            case 6:  lo = 0; hi = 23; signed_ok = 0; break;   /* BYHOUR */
            case 8:  lo = 1; hi = 31; signed_ok = 1; break;   /* BYMONTHDAY */
            case 9:  lo = 1; hi = *rscale ? 385 : 366; signed_ok = 1; break;  /* BYYEARDAY: a Hebrew leap year has up to 385 days */
            case 10: lo = 1; hi = 53; signed_ok = 1; break;   /* BYWEEKNO */
            case 11: lo = 1; hi = *rscale ? 13 : 12; signed_ok = 0; break;   /* BYMONTH: thirteen months in some calendars */
            default: lo = 1; hi = 366; signed_ok = 1; break;  /* BYSETPOS */
            }
            v = tkr_num(p, len, signed_ok, &neg);
            if (v < lo || v > hi) {
                if (signed_ok)
                    tkr_err(err, "%s=%.*s is out of range %d to %d, or -%d to -%d", key, (int)len, p, lo, hi, lo, hi);
                else
                    tkr_err(err, "%s=%.*s is out of range %d to %d", key, (int)(len + leap), p, lo, hi);
                return 0;
            }
            switch (bit) {
            case 4:  r->by_second |= UINT64_C(1) << v; break;
            case 5:  r->by_minute |= UINT64_C(1) << v; break;
            case 6:  r->by_hour |= 1u << v; break;
            case 8:  r->by_monthday |= UINT64_C(1) << (neg ? 32 + v : v); break;
            case 11:
                if (leap) r->by_month_leap |= (uint16_t)(1u << v);
                else r->by_month |= (uint16_t)(1u << v);
                break;
            case 9:
                if (!tkr_list_add(r->by_yearday, &r->n_yearday, neg ? -(int)v : (int)v)) { tkr_err(err, "BYYEARDAY has more than %d values", TKR_MAX_LIST); return 0; }
                break;
            case 10:
                if (!tkr_list8_add(r->by_weekno, &r->n_weekno, neg ? -(int)v : (int)v)) { tkr_err(err, "BYWEEKNO has more than %d values", TKR_MAX_LIST); return 0; }
                break;
            default:
                if (!tkr_list_add(r->by_setpos, &r->n_setpos, neg ? -(int)v : (int)v)) { tkr_err(err, "BYSETPOS has more than %d values", TKR_MAX_LIST); return 0; }
                break;
            }
        }
        p = e < end ? e + 1 : e;
        if (e < end && e + 1 == end) {
            tkr_err(err, "%s ends with a comma", key);
            return 0;
        }
    }
    return 1;
}

/* The whole value. 1, or 0 with err filled. The start's form (zoned or
 * floating) is checked against UNTIL's by the caller, which has the start. */
static int
tkr_rrule_parse(const char *s, size_t len, tkr_rule *r, char *err)
{
    const char *p = s, *end = s + len;
    uint32_t seen = 0;
    int rscale = 0;
    while (p < end && isSPACE(*p)) p++;
    while (end > p && isSPACE(end[-1])) end--;
    if (end - p >= 6 && tkr_ieq(p, "RRULE:", 6))
        p += 6;
    if (p >= end) {
        tkr_err(err, "the rule is empty");
        return 0;
    }
    {
        /* RSCALE widens BYMONTH and BYYEARDAY wherever it stands */
        const char *q = p;
        while (q < end) {
            const char *e = q;
            while (e < end && *e != ';') e++;
            if (e - q > 7 && tkr_ieq(q, "RSCALE=", 7))
                rscale = 1;
            q = e < end ? e + 1 : e;
        }
    }
    while (p < end) {
        const char *e = p, *eq;
        while (e < end && *e != ';')
            e++;
        for (eq = p; eq < e && *eq != '='; eq++) ;
        if (eq == e) {
            tkr_err(err, "'%.*s' is not NAME=VALUE", (int)(e - p), p);
            return 0;
        }
        if (!tkr_rrule_part(p, (size_t)(eq - p), eq + 1, (size_t)(e - eq - 1), r, &seen, &rscale, err))
            return 0;
        p = e < end ? e + 1 : e;
    }
    if (!(seen & 1)) {
        tkr_err(err, "FREQ is wanted");
        return 0;
    }
    if (r->count && r->until_kind != TKR_UNTIL_NONE) {
        tkr_err(err, "UNTIL and COUNT cannot both be given");
        return 0;
    }
    if (tkr_has_by_day_ordinal(r) && r->freq != TKR_MONTHLY && r->freq != TKR_YEARLY) {
        tkr_err(err, "an ordinal in BYDAY needs FREQ=MONTHLY or FREQ=YEARLY");
        return 0;
    }
    if (tkr_has_by_day_ordinal(r) && r->freq == TKR_YEARLY && r->n_weekno) {
        tkr_err(err, "an ordinal in BYDAY cannot be given with BYWEEKNO");
        return 0;
    }
    if (r->n_weekno && r->freq != TKR_YEARLY) {
        tkr_err(err, "BYWEEKNO needs FREQ=YEARLY");
        return 0;
    }
    if (r->n_yearday && (r->freq == TKR_DAILY || r->freq == TKR_WEEKLY || r->freq == TKR_MONTHLY)) {
        tkr_err(err, "BYYEARDAY cannot be given with FREQ=DAILY, WEEKLY or MONTHLY");
        return 0;
    }
    if (r->by_monthday && r->freq == TKR_WEEKLY) {
        tkr_err(err, "BYMONTHDAY cannot be given with FREQ=WEEKLY");
        return 0;
    }
    if ((seen & (1u << 15)) && !(r->flags & TKR_F_RSCALE)) {
        tkr_err(err, "SKIP needs RSCALE");
        return 0;
    }
    if (r->n_weekno && (r->flags & TKR_F_RSCALE)) {
        tkr_err(err, "BYWEEKNO cannot be given with RSCALE: no calendar here numbers weeks but the Gregorian");
        return 0;
    }
    if (r->n_setpos && !tkr_has_any_by(r)) {
        tkr_err(err, "BYSETPOS needs another BY part to choose from");
        return 0;
    }
    return 1;
}

/* ---- writing ------------------------------------------------------------- */

static void
tkr_cat(pTHX_ SV *out, const char *s)
{
    sv_catpv(out, s);
}

static void
tkr_cat_list_mask64(pTHX_ SV *out, const char *name, uint64_t mask, int lo, int hi)
{
    int v, first = 1;
    if (!mask)
        return;
    sv_catpvf(out, ";%s=", name);
    for (v = lo; v <= hi; v++)
        if (mask & (UINT64_C(1) << v)) {
            sv_catpvf(out, first ? "%d" : ",%d", v);
            first = 0;
        }
}

static void
tkr_cat_list16(pTHX_ SV *out, const char *name, const int16_t *list, unsigned n)
{
    unsigned i;
    if (!n)
        return;
    sv_catpvf(out, ";%s=", name);
    for (i = 0; i < n; i++)
        sv_catpvf(out, i ? ",%d" : "%d", (int)list[i]);
}

/* The canonical text: the RFC's order of parts, values ascending, no
 * INTERVAL=1, no WKST=MO. */
static void
tkr_rrule_write(pTHX_ const tkr_rule *r, SV *out)
{
    int w, i;
    sv_setpvs(out, "");
    if (r->flags & TKR_F_RSCALE) {
        const char *id = NULL;
        if (r->calendar == 0 || (tkr_tk(aTHX)->calendar_id)(r->calendar, &id) != TIME_KEEPER_OK || !id)
            id = "gregorian";
        tkr_cat(aTHX_ out, "RSCALE=");
        for (; *id; id++)
            sv_catpvf(out, "%c", toUPPER(*id));
        tkr_cat(aTHX_ out, ";");
    }
    sv_catpvf(out, "FREQ=%s", tkr_freq_names[r->freq]);
    if (r->until_kind != TKR_UNTIL_NONE) {
        int64_t days = r->until_sec >= 0 ? r->until_sec / 86400 : -((-r->until_sec + 86399) / 86400);
        int64_t rem = r->until_sec - days * 86400, y;
        unsigned m, d;
        tkr_civil_from_days(days, &y, &m, &d);
        sv_catpvf(out, ";UNTIL=%04" IVdf "%02u%02u", (IV)y, m, d);
        if (r->until_kind != TKR_UNTIL_DATE)
            sv_catpvf(out, "T%02d%02d%02d%s", (int)(rem / 3600), (int)(rem % 3600 / 60), (int)(rem % 60),
                      r->until_kind == TKR_UNTIL_UTC ? "Z" : "");
    }
    if (r->count)
        sv_catpvf(out, ";COUNT=%" IVdf, (IV)r->count);
    if (r->interval != 1)
        sv_catpvf(out, ";INTERVAL=%u", (unsigned)r->interval);
    tkr_cat_list_mask64(aTHX_ out, "BYSECOND", r->by_second, 0, 60);
    tkr_cat_list_mask64(aTHX_ out, "BYMINUTE", r->by_minute, 0, 59);
    tkr_cat_list_mask64(aTHX_ out, "BYHOUR", r->by_hour, 0, 23);
    if (tkr_has_by_day(r)) {
        int first = 1;
        tkr_cat(aTHX_ out, ";BYDAY=");
        for (w = 0; w < 7; w++) {
            if (r->by_day_any & (1u << w)) {
                sv_catpvf(out, first ? "%s" : ",%s", tkr_day_names[w]);
                first = 0;
            }
            for (i = 1; i <= 53; i++)
                if (r->by_day_pos[w] & (UINT64_C(1) << i)) {
                    sv_catpvf(out, first ? "%d%s" : ",%d%s", i, tkr_day_names[w]);
                    first = 0;
                }
            for (i = 1; i <= 53; i++)
                if (r->by_day_neg[w] & (UINT64_C(1) << i)) {
                    sv_catpvf(out, first ? "-%d%s" : ",-%d%s", i, tkr_day_names[w]);
                    first = 0;
                }
        }
    }
    if (r->by_monthday) {
        int first = 1;
        tkr_cat(aTHX_ out, ";BYMONTHDAY=");
        for (i = 1; i <= 31; i++)
            if (r->by_monthday & (UINT64_C(1) << i)) {
                sv_catpvf(out, first ? "%d" : ",%d", i);
                first = 0;
            }
        for (i = 1; i <= 31; i++)
            if (r->by_monthday & (UINT64_C(1) << (32 + i))) {
                sv_catpvf(out, first ? "-%d" : ",-%d", i);
                first = 0;
            }
    }
    tkr_cat_list16(aTHX_ out, "BYYEARDAY", r->by_yearday, r->n_yearday);
    if (r->n_weekno) {
        tkr_cat(aTHX_ out, ";BYWEEKNO=");
        for (i = 0; i < r->n_weekno; i++)
            sv_catpvf(out, i ? ",%d" : "%d", (int)r->by_weekno[i]);
    }
    if (r->by_month || r->by_month_leap) {
        int first = 1;
        tkr_cat(aTHX_ out, ";BYMONTH=");
        for (i = 1; i <= 13; i++) {
            if (r->by_month & (1u << i)) { sv_catpvf(out, first ? "%d" : ",%d", i); first = 0; }
            if (r->by_month_leap & (1u << i)) { sv_catpvf(out, first ? "%dL" : ",%dL", i); first = 0; }
        }
    }
    tkr_cat_list16(aTHX_ out, "BYSETPOS", r->by_setpos, r->n_setpos);
    if (r->wkst != 0)
        sv_catpvf(out, ";WKST=%s", tkr_day_names[r->wkst]);
    if ((r->flags & TKR_F_RSCALE) && r->skip != TKR_SKIP_OMIT)
        sv_catpvf(out, ";SKIP=%s", tkr_skip_upper[r->skip]);
}

#endif
