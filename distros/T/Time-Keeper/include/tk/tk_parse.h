#ifndef TK_PARSE_H
#define TK_PARSE_H

/* Parsing. Every form is read into a tk_fields: what the text said, and
 * nothing it did not. One function (in tk_parse_sv.h) then makes a value
 * of it, so every form shares the same checks: a date that does not exist
 * is refused, a weekday that disagrees with its date is refused, a leap
 * second must be one.
 *
 * A reader that fails sets the cursor's error and the offset it was at; a
 * parser that tries several forms keeps the error that got furthest. */

typedef struct tk_cursor {
    const char *s;
    STRLEN      len;
    STRLEN      i;
    const char *err;
    STRLEN      err_at;
} tk_cursor;

typedef struct tk_fields {
    unsigned has_year:1, has_month:1, has_day:1, has_doy:1, has_isoweek:1, has_week_sun:1,
             has_week_mon:1, has_wday:1, has_hour:1, has_minute:1, has_second:1, has_ampm:1,
             has_epoch:1, has_offset:1, has_century:1, has_y2:1, has_hour12:1, utc:1,
             hour24:1, zone_critical:1, era_bc:1;
    int64_t  year;
    int64_t  century;
    int      y2;
    unsigned month, day, doy, week, wday;   /* wday 1 Monday .. 7 Sunday */
    int64_t  week_year;
    int      hour, minute, second, pm;
    int32_t  nsec;
    tk_instant epoch;
    int32_t  offset;
    const char *zone;                        /* a zone's name from [brackets] */
    STRLEN   zone_len;
    const char *abbr;                        /* an abbreviation to be checked */
    STRLEN   abbr_len;
    int      dst_hint;                       /* 1 standard, 2 daylight, from a zone's name */
} tk_fields;

static int
tk_fail(tk_cursor *c, const char *why)
{
    if (!c->err || c->i >= c->err_at) {
        c->err = why;
        c->err_at = c->i;
    }
    return 0;
}

static int
tk_at_end(const tk_cursor *c)
{
    return c->i >= c->len;
}

static int
tk_peek(const tk_cursor *c)
{
    return c->i < c->len ? (unsigned char)c->s[c->i] : -1;
}

static int
tk_eat(tk_cursor *c, char ch)
{
    if (c->i < c->len && c->s[c->i] == ch) {
        c->i++;
        return 1;
    }
    return 0;
}

static int
tk_eat_ci(tk_cursor *c, char ch)
{
    if (c->i < c->len && toLOWER(c->s[c->i]) == toLOWER(ch)) {
        c->i++;
        return 1;
    }
    return 0;
}

static void
tk_skip_space(tk_cursor *c)
{
    while (c->i < c->len && isSPACE(c->s[c->i]))
        c->i++;
}

static STRLEN
tk_digit_run(const tk_cursor *c)
{
    STRLEN n = 0;
    while (c->i + n < c->len && isDIGIT(c->s[c->i + n]))
        n++;
    return n;
}

/* Exactly n digits. */
static int
tk_digits(tk_cursor *c, int n, int64_t *out)
{
    int64_t v = 0;
    int k;
    STRLEN start = c->i;
    for (k = 0; k < n; k++) {
        if (c->i >= c->len || !isDIGIT(c->s[c->i])) {
            c->i = start;        /* the error is where the number began */
            return tk_fail(c, n == 1 ? "a digit was wanted" : "digits were wanted");
        }
        v = v * 10 + (c->s[c->i++] - '0');
    }
    *out = v;
    return 1;
}

/* From min to max digits, as many as there are. */
static int
tk_digits_range(tk_cursor *c, int min, int max, int64_t *out)
{
    int64_t v = 0;
    int k = 0;
    while (k < max && c->i < c->len && isDIGIT(c->s[c->i])) {
        v = v * 10 + (c->s[c->i++] - '0');
        k++;
    }
    if (k < min)
        return tk_fail(c, "digits were wanted");
    *out = v;
    return 1;
}

/* A fraction after . or , : up to nine digits kept, more read and dropped. */
static int
tk_fraction(tk_cursor *c, int32_t *nsec, int *digits)
{
    int32_t v = 0;
    int k = 0;
    if (c->i >= c->len || !isDIGIT(c->s[c->i]))
        return tk_fail(c, "digits were wanted after the decimal sign");
    while (c->i < c->len && isDIGIT(c->s[c->i])) {
        if (k < 9)
            v = v * 10 + (c->s[c->i] - '0');
        k++;
        c->i++;
    }
    *digits = k < 9 ? k : 9;
    while (k++ < 9)
        v *= 10;
    *nsec = v;
    return 1;
}

/* +HH, +HHMM, +HH:MM, +HH:MM:SS, +HHMMSS, or Z. */
static int
tk_offset_field(tk_cursor *c, tk_fields *f, int allow_z)
{
    int sign;
    int64_t h, m = 0, s = 0;
    if (allow_z && (tk_eat(c, 'Z') || tk_eat(c, 'z'))) {
        f->has_offset = 1;
        f->offset = 0;
        f->utc = 1;
        return 1;
    }
    if (tk_peek(c) != '+' && tk_peek(c) != '-' && tk_peek(c) != 0x2212)
        return tk_fail(c, "an offset was wanted");
    sign = c->s[c->i++] == '-' ? -1 : 1;
    if (!tk_digits(c, 2, &h))
        return 0;
    if (tk_eat(c, ':')) {
        if (!tk_digits(c, 2, &m))
            return 0;
        if (tk_eat(c, ':') && !tk_digits(c, 2, &s))
            return 0;
    }
    else if (tk_digit_run(c) >= 2) {
        tk_digits(c, 2, &m);
        if (tk_digit_run(c) >= 2)
            tk_digits(c, 2, &s);
    }
    if (h > 23 || m > 59 || s > 59)
        return tk_fail(c, "the offset is out of range");
    f->has_offset = 1;
    f->offset = (int32_t)(sign * (h * 3600 + m * 60 + s));
    return 1;
}

/* ---- ISO 8601 and RFC 3339 / 9557 ------------------------------------------ */

static int
tk_iso_time(tk_cursor *c, tk_fields *f)
{
    int64_t h, m = 0, s = 0;
    int32_t frac = 0;
    int fd = 0, last = 0, extended;
    if (!tk_digits(c, 2, &h))
        return 0;
    if (h > 24)
        return tk_fail(c, "the hour is past 24");
    last = 1;
    extended = tk_peek(c) == ':';
    if (extended ? tk_eat(c, ':') : tk_digit_run(c) >= 2) {
        if (!tk_digits(c, 2, &m))
            return 0;
        if (m > 59)
            return tk_fail(c, "the minute is past 59");
        last = 2;
        if (extended ? tk_eat(c, ':') : tk_digit_run(c) >= 2) {
            if (!tk_digits(c, 2, &s))
                return 0;
            if (s > 60)
                return tk_fail(c, "the second is past 60");
            last = 3;
        }
    }
    if (tk_peek(c) == '.' || tk_peek(c) == ',') {
        c->i++;
        if (!tk_fraction(c, &frac, &fd))
            return 0;
    }
    if (h > 24)
        return tk_fail(c, "the hour is past 24");
    if (m > 59)
        return tk_fail(c, "the minute is past 59");
    if (s > 60)
        return tk_fail(c, "the second is past 60");
    /* a fraction belongs to the last unit given */
    if (frac && last < 3) {
        int64_t ns = (int64_t)frac * (last == 1 ? 3600 : 60);
        s += ns / TK_NSECS_PER_SEC;
        frac = (int32_t)(ns % TK_NSECS_PER_SEC);
        if (last == 1) { m += s / 60; s %= 60; }
    }
    if (h == 24) {
        if (m || s || frac)
            return tk_fail(c, "24:00 is the only time in hour 24");
        f->hour24 = 1;
        h = 0;
    }
    f->has_hour = f->has_minute = f->has_second = 1;
    f->hour = (int)h;
    f->minute = (int)m;
    f->second = (int)s;
    f->nsec = frac;
    return 1;
}

/* [Zone/Name], [!Zone/Name], [u-ca=gregory], [!key=value] ... */
static int
tk_iso_suffix(tk_cursor *c, tk_fields *f)
{
    while (tk_eat(c, '[')) {
        int critical = tk_eat(c, '!');
        STRLEN start = c->i, eq = 0;
        while (c->i < c->len && c->s[c->i] != ']') {
            if (c->s[c->i] == '=' && !eq)
                eq = c->i;
            c->i++;
        }
        if (c->i >= c->len)
            return tk_fail(c, "a ] was wanted");
        if (eq) {
            STRLEN klen = eq - start, vlen = c->i - eq - 1;
            const char *k = c->s + start, *v = c->s + eq + 1;
            if (klen == 4 && memEQ(k, "u-ca", 4)) {
                if (!((vlen == 7 && memEQ(v, "gregory", 7)) || (vlen == 7 && memEQ(v, "iso8601", 7))))
                    return tk_fail(c, "only the Gregorian calendar is known");
            }
            else if (critical)
                return tk_fail(c, "a critical annotation that is not known");
        }
        else {
            if (f->zone)
                return tk_fail(c, "a second time zone");
            if (c->i == start)
                return tk_fail(c, "an empty time zone");
            f->zone = c->s + start;
            f->zone_len = c->i - start;
            f->zone_critical = critical;
        }
        c->i++;   /* the ] */
    }
    return 1;
}

static int
tk_parse_iso(tk_cursor *c, tk_fields *f)
{
    int64_t y, a, b;
    STRLEN run;
    int sign = 0;

    if (tk_peek(c) == '+' || tk_peek(c) == '-') {
        sign = c->s[c->i++] == '-' ? -1 : 1;
        run = tk_digit_run(c);
        if (run < 4 || run > 9)
            return tk_fail(c, "an expanded year has a sign and 4 to 9 digits");
        tk_digits(c, (int)run, &y);
        y *= sign;
        if (y == 0 && sign < 0)
            return tk_fail(c, "the year -0 is not a year");
        if (tk_peek(c) != '-' && !tk_at_end(c) && tk_peek(c) != 'T')
            return tk_fail(c, "an expanded year needs the extended form");
    }
    else if (!tk_digits(c, 4, &y))
        return 0;
    f->has_year = 1;
    f->year = y;

    if (tk_eat(c, '-')) {
        if (tk_eat(c, 'W')) {
            if (!tk_digits(c, 2, &a))
                return 0;
            f->has_isoweek = 1;
            f->week_year = y;
            f->week = (unsigned)a;
            f->has_year = 0;
            if (tk_eat(c, '-')) {
                if (!tk_digits(c, 1, &b))
                    return 0;
                f->has_wday = 1;
                f->wday = (unsigned)b;
            }
        }
        else {
            run = tk_digit_run(c);
            if (run == 3) {
                tk_digits(c, 3, &a);
                f->has_doy = 1;
                f->doy = (unsigned)a;
            }
            else {
                if (!tk_digits(c, 2, &a))
                    return 0;
                f->has_month = 1;
                f->month = (unsigned)a;
                if (tk_eat(c, '-')) {
                    if (!tk_digits(c, 2, &b))
                        return 0;
                    f->has_day = 1;
                    f->day = (unsigned)b;
                }
            }
        }
    }
    else if (tk_eat(c, 'W')) {
        if (!tk_digits(c, 2, &a))
            return 0;
        f->has_isoweek = 1;
        f->week_year = y;
        f->week = (unsigned)a;
        f->has_year = 0;
        if (tk_digit_run(c) >= 1) {
            tk_digits(c, 1, &b);
            f->has_wday = 1;
            f->wday = (unsigned)b;
        }
    }
    else {
        run = tk_digit_run(c);
        if (run == 4) {
            tk_digits(c, 2, &a);
            tk_digits(c, 2, &b);
            f->has_month = f->has_day = 1;
            f->month = (unsigned)a;
            f->day = (unsigned)b;
        }
        else if (run == 3) {
            tk_digits(c, 3, &a);
            f->has_doy = 1;
            f->doy = (unsigned)a;
        }
        else if (run != 0)
            return tk_fail(c, "a date in the basic form has 8 digits, or 7 with the day of the year");
    }

    if (tk_peek(c) == 'T' || tk_peek(c) == 't'
        || (tk_peek(c) == ' ' && c->i + 1 < c->len && isDIGIT(c->s[c->i + 1]))) {
        c->i++;
        if (!tk_iso_time(c, f))
            return 0;
        if (tk_peek(c) == 'Z' || tk_peek(c) == 'z' || tk_peek(c) == '+' || tk_peek(c) == '-')
            if (!tk_offset_field(c, f, 1))
                return 0;
    }
    if (!tk_iso_suffix(c, f))
        return 0;
    if (!tk_at_end(c))
        return tk_fail(c, "text was left over");
    return 1;
}

/* ---- the mail and HTTP forms -------------------------------------------------- */

static const char *const tk_en_day_names[7] = {
    "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"
};
static const char *const tk_en_month_names[12] = {
    "jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"
};

/* Folding white space and comments, as RFC 5322's CFWS. */
static void
tk_skip_cfws(tk_cursor *c)
{
    for (;;) {
        tk_skip_space(c);
        if (tk_peek(c) == '(') {
            int depth = 0;
            while (c->i < c->len) {
                char ch = c->s[c->i++];
                if (ch == '\\' && c->i < c->len) { c->i++; continue; }
                if (ch == '(') depth++;
                else if (ch == ')' && --depth == 0) break;
            }
            continue;
        }
        break;
    }
}

static int
tk_word_ci(tk_cursor *c, const char *w)
{
    STRLEN n = strlen(w), k;
    if (c->i + n > c->len)
        return 0;
    for (k = 0; k < n; k++)
        if (toLOWER(c->s[c->i + k]) != w[k])
            return 0;
    c->i += n;
    return 1;
}

/* An English day name, short or long; 1 Monday .. 7 Sunday, or 0. */
static unsigned
tk_en_day(tk_cursor *c)
{
    int d;
    for (d = 0; d < 7; d++) {
        if (tk_word_ci(c, tk_en_day_names[d]))
            return (unsigned)d + 1;
    }
    for (d = 0; d < 7; d++) {
        char ab[4];
        memcpy(ab, tk_en_day_names[d], 3);
        ab[3] = '\0';
        if (tk_word_ci(c, ab))
            return (unsigned)d + 1;
    }
    return 0;
}

static unsigned
tk_en_month(tk_cursor *c)
{
    int m;
    for (m = 0; m < 12; m++)
        if (tk_word_ci(c, tk_en_month_names[m]))
            return (unsigned)m + 1;
    return 0;
}

static int
tk_hms(tk_cursor *c, tk_fields *f, int seconds_optional)
{
    int64_t h, m, s = 0;
    if (!tk_digits(c, 2, &h) || !tk_eat(c, ':') || !tk_digits(c, 2, &m))
        return tk_fail(c, "a time HH:MM was wanted");
    if (tk_eat(c, ':')) {
        if (!tk_digits(c, 2, &s))
            return 0;
    }
    else if (!seconds_optional)
        return tk_fail(c, "the seconds were wanted");
    if (h > 23 || m > 59 || s > 60)
        return tk_fail(c, "the time is out of range");
    f->has_hour = f->has_minute = f->has_second = 1;
    f->hour = (int)h;
    f->minute = (int)m;
    f->second = (int)s;
    return 1;
}

/* RFC 5322's zones, with the obsolete names it still reads. */
static int
tk_mail_zone(tk_cursor *c, tk_fields *f)
{
    static const struct { const char *name; int hours; } names[] = {
        { "ut", 0 }, { "gmt", 0 }, { "est", -5 }, { "edt", -4 }, { "cst", -6 },
        { "cdt", -5 }, { "mst", -7 }, { "mdt", -6 }, { "pst", -8 }, { "pdt", -7 }
    };
    int k;
    if (tk_peek(c) == '+' || tk_peek(c) == '-') {
        int sign = c->s[c->i++] == '-' ? -1 : 1;
        int64_t hh, mm;
        if (!tk_digits(c, 2, &hh) || !tk_digits(c, 2, &mm))
            return 0;
        if (mm > 59)
            return tk_fail(c, "the offset's minutes are past 59");
        f->has_offset = 1;
        f->offset = (int32_t)(sign * (hh * 3600 + mm * 60));
        return 1;
    }
    for (k = 0; k < 10; k++) {
        STRLEN at = c->i;
        if (tk_word_ci(c, names[k].name) && !(tk_peek(c) >= 0 && isALPHA(tk_peek(c)))) {
            f->has_offset = 1;
            f->offset = names[k].hours * 3600;
            f->utc = names[k].hours == 0;
            return 1;
        }
        c->i = at;
    }
    /* a military letter: RFC 5322 says to take it as -0000, UTC with no local time */
    if (tk_peek(c) >= 0 && isALPHA(tk_peek(c)) && toLOWER(tk_peek(c)) != 'j'
        && !(c->i + 1 < c->len && isALPHA(c->s[c->i + 1]))) {
        c->i++;
        f->has_offset = 1;
        f->offset = 0;
        f->utc = 1;
        return 1;
    }
    return tk_fail(c, "a zone was wanted");
}

static int64_t
tk_obsolete_year(int64_t y, STRLEN digits)
{
    if (digits == 2)
        return y < 50 ? 2000 + y : 1900 + y;
    if (digits == 3)
        return 1900 + y;
    return y;
}

/* RFC 5322: [day ,] d mon yyyy hh:mm[:ss] zone. RFC 850: Sunday, 06-Nov-94
 * 08:49:37 GMT. asctime: Sun Nov  6 08:49:37 1994. */
static int
tk_parse_mail(tk_cursor *c, tk_fields *f)
{
    unsigned wd = 0, mon;
    int64_t d, y;
    STRLEN run;

    tk_skip_cfws(c);
    if (tk_peek(c) >= 0 && isALPHA(tk_peek(c))) {
        if (!(wd = tk_en_day(c)))
            return tk_fail(c, "a day of the week was wanted");
        f->has_wday = 1;
        f->wday = wd;
        tk_skip_cfws(c);
        if (!tk_eat(c, ',')) {
            /* asctime: Sun Nov  6 08:49:37 1994 */
            tk_skip_space(c);
            if (!(mon = tk_en_month(c)))
                return tk_fail(c, "a , or a month was wanted");
            tk_skip_space(c);
            if (!tk_digits_range(c, 1, 2, &d))
                return 0;
            tk_skip_space(c);
            if (!tk_hms(c, f, 0))
                return 0;
            tk_skip_space(c);
            if (!tk_digits(c, 4, &y))
                return 0;
            tk_skip_space(c);
            if (!tk_at_end(c))
                return tk_fail(c, "text was left over");
            f->has_year = f->has_month = f->has_day = 1;
            f->year = y;
            f->month = mon;
            f->day = (unsigned)d;
            f->has_offset = 1;
            f->offset = 0;
            f->utc = 1;
            return 1;
        }
        tk_skip_cfws(c);
    }
    if (!tk_digits_range(c, 1, 2, &d))
        return 0;
    if (tk_eat(c, '-')) {
        /* RFC 850: 06-Nov-94 */
        if (!(mon = tk_en_month(c)) || !tk_eat(c, '-'))
            return tk_fail(c, "a month and a - were wanted");
        run = tk_digit_run(c);
        if (run != 2 && run != 4)
            return tk_fail(c, "a year was wanted");
        tk_digits(c, (int)run, &y);
        y = tk_obsolete_year(y, run);
    }
    else {
        tk_skip_cfws(c);
        if (!(mon = tk_en_month(c)))
            return tk_fail(c, "a month was wanted");
        tk_skip_cfws(c);
        run = tk_digit_run(c);
        if (run < 2 || run > 9)
            return tk_fail(c, "a year was wanted");
        tk_digits(c, (int)run, &y);
        y = tk_obsolete_year(y, run);
    }
    f->has_year = f->has_month = f->has_day = 1;
    f->year = y;
    f->month = mon;
    f->day = (unsigned)d;
    tk_skip_cfws(c);
    if (!tk_hms(c, f, 1))
        return 0;
    tk_skip_cfws(c);
    if (!tk_mail_zone(c, f))
        return 0;
    tk_skip_cfws(c);
    if (!tk_at_end(c))
        return tk_fail(c, "text was left over");
    return 1;
}

/* @1760000000 or @-12.5: an epoch, as GNU date reads one. */
static int
tk_parse_epoch_text(tk_cursor *c, tk_fields *f)
{
    STRLEN start;
    int neg = 0, fd = 0;
    int64_t whole = 0;
    int32_t frac = 0;
    if (!tk_eat(c, '@'))
        return tk_fail(c, "an @ was wanted");
    if (tk_peek(c) == '-' || tk_peek(c) == '+')
        neg = c->s[c->i++] == '-';
    start = c->i;
    if (tk_digit_run(c) > 18)
        return tk_fail(c, "the epoch is out of range");
    if (!tk_digits_range(c, 1, 18, &whole))
        return 0;
    PERL_UNUSED_VAR(start);
    if (tk_eat(c, '.') && !tk_fraction(c, &frac, &fd))
        return 0;
    if (!tk_at_end(c))
        return tk_fail(c, "text was left over");
    f->has_epoch = 1;
    f->epoch.sec = neg ? -whole : whole;
    f->epoch.nsec = frac;
    if (neg && frac) {
        f->epoch.sec -= 1;
        f->epoch.nsec = TK_NSECS_PER_SEC - frac;
    }
    return 1;
}

/* Any of the forms: an epoch, ISO 8601 (and RFC 3339 and 9557), or the mail
 * and HTTP forms. The error kept is the one that got furthest. */
static int
tk_parse_any(tk_cursor *c, tk_fields *f)
{
    tk_cursor a = *c, b = *c;
    tk_fields fa, fb;
    if (tk_peek(c) == '@')
        return tk_parse_epoch_text(c, f);
    Zero(&fa, 1, tk_fields);
    Zero(&fb, 1, tk_fields);
    if (tk_parse_iso(&a, &fa)) {
        *f = fa;
        *c = a;
        return 1;
    }
    if (tk_parse_mail(&b, &fb)) {
        *f = fb;
        *c = b;
        return 1;
    }
    if (b.err_at > a.err_at) {
        c->err = b.err;
        c->err_at = b.err_at;
    }
    else {
        c->err = a.err;
        c->err_at = a.err_at;
    }
    return 0;
}

#endif
