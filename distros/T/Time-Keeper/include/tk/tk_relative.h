#ifndef TK_RELATIVE_H
#define TK_RELATIVE_H

/* Relative time ("3 hours ago", "yesterday") and durations in words
 * ("1 hour, 30 minutes"), from the words the locale archive carries since
 * its third version: CLDR's dateFields, units and listPatterns. */

/* The relative field's words in the width, or the nearest wider width that
 * has them, or English's. */
static const tk_relative *
tk_relative_words(pTHX_ const tk_locale_data *loc, int field, int width)
{
    int w;
    for (w = width; w >= 0; w--)
        if (loc->w.relative[field][w].future[TK_PL_OTHER])
            return &loc->w.relative[field][w];
    return &tk_locale_get(aTHX_ 0)->w.relative[field][TK_RW_LONG];
}

static const tk_unit_words *
tk_unit_words_of(pTHX_ const tk_locale_data *loc, int unit, int width)
{
    int w;
    for (w = width; w >= 0; w--)
        if (loc->w.units[unit][w].count[TK_PL_OTHER])
            return &loc->w.units[unit][w];
    return &tk_locale_get(aTHX_ 0)->w.units[unit][TK_RW_LONG];
}

/* A pattern with {0} filled by a number in the locale's digits. */
static void
tk_out_count(pTHX_ tk_out *o, const char *pat, int64_t n)
{
    const char *p = pat;
    while (*p) {
        if (p[0] == '{' && p[1] == '0' && p[2] == '}') {
            tk_out_num(aTHX_ o, n, 0, 0);
            p += 3;
            continue;
        }
        tk_out_cat(aTHX_ o, p, 1);
        p++;
    }
}

/* The plural category of a magnitude in the locale. */
#define tk_plural_of(loc, n) (tk_plural_rules[(loc)->plural](n))

/* ---- relative time ---------------------------------------------------------- */

/* How far v is from the reference, in a field, as a relative time counts:
 * for day, week, month and year by the wall-clock dates in v's zone, so
 * 23:00 yesterday is a day ago at 09:00 today; for hour, minute and second
 * by the time that passed. Positive when v is after the reference. */
static int64_t
tk_relative_count(pTHX_ tk_value *ref, tk_value *v, int field, const char *what)
{
    tk_value a, *b = v;
    tk_duration d;
    tk_value_in_zone_of(aTHX_ &a, ref, v);
    if (field <= TK_RF_DAY) {
        const tk_civil *ca = tk_value_civil(&a), *cb = tk_value_civil(b);
        int64_t days = tk_days_from_civil(cb->year, cb->month, cb->day)
                     - tk_days_from_civil(ca->year, ca->month, ca->day);
        tk_value sa, sb;
        if (field == TK_RF_DAY)
            return days;
        if (field == TK_RF_WEEK)
            return days / 7;
        tk_value_truncate(aTHX_ &sa, &a, TK_U_DAY, what);
        tk_value_truncate(aTHX_ &sb, b, TK_U_DAY, what);
        tk_value_until(aTHX_ &d, &sb, &sa, TK_U_MONTH, TK_U_MONTH, 1, TK_RM_TRUNC);
        return field == TK_RF_YEAR ? d.months / 12 : field == TK_RF_QUARTER ? d.months / 3 : d.months;
    }
    if (field == TK_RF_SECOND) {
        tk_value_until(aTHX_ &d, b, &a, TK_U_SECOND, TK_U_SECOND, 1, TK_RM_TRUNC);
        return d.seconds;
    }
    tk_value_until(aTHX_ &d, b, &a, TK_U_MINUTE, TK_U_MINUTE, 1, TK_RM_TRUNC);
    return field == TK_RF_HOUR ? d.minutes / 60 : d.minutes;
}

/* The field for unit => 'auto': the first of year, month, week, day, hour,
 * minute, second with a count that is not zero, else second. */
static int
tk_relative_auto(pTHX_ tk_value *a, tk_value *b, int64_t *count, const char *what)
{
    static const int order[] = { TK_RF_YEAR, TK_RF_MONTH, TK_RF_WEEK, TK_RF_DAY, TK_RF_HOUR, TK_RF_MINUTE, TK_RF_SECOND };
    unsigned i;
    for (i = 0; i < sizeof order / sizeof order[0]; i++) {
        *count = tk_relative_count(aTHX_ a, b, order[i], what);
        if (*count)
            return order[i];
    }
    return TK_RF_SECOND;
}

/* "in 3 days", "3 days ago", or "yesterday" when numeric_auto and the locale
 * has a word for that offset. */
static void
tk_out_relative(pTHX_ tk_out *o, const tk_locale_data *loc, int field, int width, int64_t count, int numeric_auto)
{
    const tk_relative *r = tk_relative_words(aTHX_ loc, field, width);
    const char *const *pats;
    const char *pat;
    int64_t mag;
    int cat;

    if (numeric_auto && count >= -2 && count <= 2 && r->at[count + 2]) {
        tk_out_str(aTHX_ o, r->at[count + 2]);
        return;
    }
    pats = count < 0 ? r->past : r->future;
    mag = count < 0 ? -count : count;
    cat = tk_plural_of(loc, mag);
    pat = pats[cat] ? pats[cat] : pats[TK_PL_OTHER];
    if (!pat) {
        const tk_relative *en = &tk_locale_get(aTHX_ 0)->w.relative[field][TK_RW_LONG];
        pats = count < 0 ? en->past : en->future;
        pat = pats[TK_PL_OTHER];
    }
    tk_out_count(aTHX_ o, pat, mag);
}

/* ---- durations in words ------------------------------------------------------ */

/* A list joined as CLDR joins one: the two pattern for two, else start,
 * middle and end from the last pair back. */
static void
tk_out_list(pTHX_ tk_out *o, const tk_locale_data *loc, int type, SV **items, int n)
{
    const char *const *lp = loc->w.lists[type];
    SV *acc;
    int i;
    if (n == 1) {
        tk_out_cat(aTHX_ o, SvPVX(items[0]), SvCUR(items[0]));
        return;
    }
    if (n == 2) {
        tk_out_fill(aTHX_ o, lp[TK_LS_TWO] ? lp[TK_LS_TWO] : "{0}, {1}", SvPVX(items[0]), SvPVX(items[1]));
        return;
    }
    {
        tk_out t;
        t.sv = sv_2mortal(newSVpvs(""));
        t.utf8 = 0;
        t.digits = NULL; t.nums = NULL; t.nums_len = 0;
        tk_out_fill(aTHX_ &t, lp[TK_LS_END] ? lp[TK_LS_END] : "{0}, {1}", SvPVX(items[n - 2]), SvPVX(items[n - 1]));
        acc = t.sv;
        for (i = n - 3; i >= 0; i--) {
            tk_out u;
            u.sv = sv_2mortal(newSVpvs(""));
            u.utf8 = 0;
            u.digits = NULL; u.nums = NULL; u.nums_len = 0;
            tk_out_fill(aTHX_ &u, lp[i == 0 ? TK_LS_START : TK_LS_MIDDLE] ? lp[i == 0 ? TK_LS_START : TK_LS_MIDDLE] : "{0}, {1}",
                        SvPVX(items[i]), SvPVX(acc));
            acc = u.sv;
        }
        tk_out_cat(aTHX_ o, SvPVX(acc), SvCUR(acc));
    }
}

/* The ten parts of a duration in words, unsigned, each unit folding into
 * the next smaller allowed one of its group (years and months; weeks and
 * days; hours down to nanoseconds); what lies below the smallest allowed
 * unit of a group is dropped. 0 and *missing set when a group has a value
 * but no allowed unit. */
static int
tk_dur_parts(const tk_duration *d, unsigned allowed, int64_t parts[TK_DU_COUNT], const char **missing)
{
    int64_t months = d->months < 0 ? -d->months : d->months;
    int64_t days = d->days < 0 ? -d->days : d->days;
    int64_t minutes = d->minutes < 0 ? -d->minutes : d->minutes;
    int64_t seconds = d->seconds < 0 ? -d->seconds : d->seconds;
    int64_t nsec = d->nsec < 0 ? -d->nsec : d->nsec;
    int64_t secs = minutes * 60 + seconds;
    int u;
    for (u = 0; u < TK_DU_COUNT; u++)
        parts[u] = 0;
    if (allowed & (1u << TK_DU_YEAR)) { parts[TK_DU_YEAR] = months / 12; months %= 12; }
    if (allowed & (1u << TK_DU_MONTH)) { parts[TK_DU_MONTH] = months; months = 0; }
    if (months && !(allowed & ((1u << TK_DU_YEAR) | (1u << TK_DU_MONTH)))) { *missing = "months"; return 0; }
    if (allowed & (1u << TK_DU_WEEK)) { parts[TK_DU_WEEK] = days / 7; days %= 7; }
    if (allowed & (1u << TK_DU_DAY)) { parts[TK_DU_DAY] = days; days = 0; }
    if (days && !(allowed & ((1u << TK_DU_WEEK) | (1u << TK_DU_DAY)))) { *missing = "days"; return 0; }
    if (allowed & (1u << TK_DU_HOUR)) { parts[TK_DU_HOUR] = secs / 3600; secs %= 3600; }
    if (allowed & (1u << TK_DU_MINUTE)) { parts[TK_DU_MINUTE] = secs / 60; secs %= 60; }
    if (allowed & (1u << TK_DU_SECOND)) { parts[TK_DU_SECOND] = secs; secs = 0; }
    else nsec += secs * TK_NSECS_PER_SEC;       /* only reached with seconds below 60 */
    if (allowed & (1u << TK_DU_MILLISECOND)) { parts[TK_DU_MILLISECOND] = nsec / 1000000; nsec %= 1000000; }
    if (allowed & (1u << TK_DU_MICROSECOND)) { parts[TK_DU_MICROSECOND] = nsec / 1000; nsec %= 1000; }
    if (allowed & (1u << TK_DU_NANOSECOND)) { parts[TK_DU_NANOSECOND] = nsec; nsec = 0; }
    if ((secs || nsec) && !(allowed & 0x3f0)) { *missing = "clock time"; return 0; }
    return 1;
}

/* The duration in words: each part that is not zero in the unit's pattern
 * for its plural category, the largest `largest` of them, joined as a list
 * of the style; the smallest allowed unit with 0 when every part is zero. */
static void
tk_out_duration_words(pTHX_ tk_out *o, const tk_locale_data *loc, const tk_duration *d, int width, int list_type,
                      unsigned allowed, int largest, const char *what)
{
    int64_t parts[TK_DU_COUNT];
    const char *missing = NULL;
    SV *items[TK_DU_COUNT];
    int n = 0, u, smallest = -1;

    if (!tk_dur_parts(d, allowed, parts, &missing))
        croak("%s: a duration of %s cannot be written in the units given", what, missing);
    for (u = 0; u < TK_DU_COUNT; u++) {
        tk_out t;
        const tk_unit_words *w;
        int cat;
        if (allowed & (1u << u))
            smallest = u;
        if (!parts[u] || n >= largest)
            continue;
        w = tk_unit_words_of(aTHX_ loc, u, width);
        cat = tk_plural_of(loc, parts[u]);
        t.sv = sv_2mortal(newSVpvs(""));
        t.utf8 = 0;
        t.digits = o->digits; t.nums = o->nums; t.nums_len = o->nums_len;
        tk_out_count(aTHX_ &t, w->count[cat] ? w->count[cat] : w->count[TK_PL_OTHER], parts[u]);
        if (t.utf8) o->utf8 = 1;
        items[n++] = t.sv;
    }
    if (!n) {
        /* nothing: 0 seconds, or 0 of the smallest unit given */
        int zu = allowed == (1u << TK_DU_COUNT) - 1 || smallest < 0 ? TK_DU_SECOND : smallest;
        const tk_unit_words *w = tk_unit_words_of(aTHX_ loc, zu, width);
        tk_out_count(aTHX_ o, w->count[tk_plural_of(loc, 0)] ? w->count[tk_plural_of(loc, 0)] : w->count[TK_PL_OTHER], 0);
        return;
    }
    tk_out_list(aTHX_ o, loc, list_type, items, n);
}

/* The duration as digits, h:mm:ss in the locale's pattern. */
static void
tk_out_duration_digital(pTHX_ tk_out *o, const tk_locale_data *loc, const tk_duration *d, const char *what)
{
    const char *pat = loc->w.digital[1] ? loc->w.digital[1] : "h:mm:ss";
    int64_t minutes = d->minutes < 0 ? -d->minutes : d->minutes;
    int64_t seconds = d->seconds < 0 ? -d->seconds : d->seconds;
    int64_t secs = minutes * 60 + seconds;
    const char *p;
    if (d->months || d->days)
        croak("%s: a duration with months or days has no fixed length to write as digits", what);
    for (p = pat; *p; ) {
        if (*p == 'h' || *p == 'H') {
            int w = 0;
            while (*p == 'h' || *p == 'H') { p++; w++; }
            tk_out_num(aTHX_ o, secs / 3600, w, '0');
        }
        else if (*p == 'm') {
            int w = 0;
            while (*p == 'm') { p++; w++; }
            tk_out_num(aTHX_ o, secs / 60 % 60, w, '0');
        }
        else if (*p == 's') {
            int w = 0;
            while (*p == 's') { p++; w++; }
            tk_out_num(aTHX_ o, secs % 60, w, '0');
        }
        else {
            tk_out_cat(aTHX_ o, p, 1);
            p++;
        }
    }
}

#endif
