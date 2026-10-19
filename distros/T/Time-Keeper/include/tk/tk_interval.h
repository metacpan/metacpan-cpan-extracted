#ifndef TK_INTERVAL_H
#define TK_INTERVAL_H

/* Intervals ("Oct 15 – 17, 2026"), as Unicode Technical Standard 35 forms
 * them from the locale's intervalFormats (archive version 3): the greatest
 * field that differs chooses the pattern, whose second half begins at the
 * first field that repeats. */

/* The flexible period of the day (B) a time falls in, or -1. */
static int
tk_b_period(const tk_locale_data *loc, const tk_civil *c)
{
    unsigned minute = c->hour * 60 + c->minute, i;
    for (i = 0; i < loc->n_rules; i++) {
        const tk_period_rule *r = &loc->rules[i];
        if (r->from == r->before)
            continue;
        if (r->from < r->before ? (minute >= r->from && minute < r->before)
                                : (minute >= r->from || minute < r->before))
            return r->period;
    }
    return -1;
}

/* The pattern of a skeleton, or NULL. */
static const char *
tk_skeleton_pattern(const tk_locale_data *loc, const char *skel)
{
    int lo = 0, hi = (int)loc->n_skeletons - 1;
    while (lo <= hi) {
        int mid = lo + (hi - lo) / 2;
        int c = strcmp(loc->skeletons[mid].key, skel);
        if (c == 0)
            return loc->skeletons[mid].value;
        if (c < 0) lo = mid + 1; else hi = mid - 1;
    }
    return NULL;
}

/* The interval format of a skeleton for the greatest differing field, or
 * NULL; *any set when the skeleton has interval formats at all. */
static const char *
tk_interval_pattern(const tk_locale_data *loc, const char *skel, char letter, int *any)
{
    unsigned k;
    const char *found = NULL;
    *any = 0;
    for (k = 0; k < loc->n_intervals; k++) {
        if (strNE(loc->intervals[k].skeleton, skel))
            continue;
        *any = 1;
        if (loc->intervals[k].letter == letter)
            found = loc->intervals[k].pattern;
    }
    return found;
}

/* Where the second half of an interval pattern begins: the first field
 * whose letter has been seen already, outside quotes. len when none. */
static STRLEN
tk_interval_split(const char *p, STRLEN len)
{
    uint64_t seen = 0;
    STRLEN i = 0;
    while (i < len) {
        if (p[i] == '\'') {
            i++;
            while (i < len && !(p[i] == '\'' && !(i + 1 < len && p[i + 1] == '\'')))
                i += (p[i] == '\'' ? 2 : 1);
            i++;
            continue;
        }
        if (isALPHA(p[i])) {
            char ch = p[i];
            STRLEN start = i;
            uint64_t bit = (uint64_t)1 << (isUPPER(ch) ? ch - 'A' : ch - 'a' + 26);
            while (i < len && p[i] == ch)
                i++;
            if (seen & bit)
                return start;
            seen |= bit;
            continue;
        }
        i++;
    }
    return len;
}

/* The letter of the greatest field in which a and b differ, as the skeleton
 * shows it: 'G', 'y', 'M', 'd', 'B' or 'a', 'h' or 'H', 'm'; 0 when the two
 * agree in every field the skeleton shows; '!' when they differ in a field
 * the skeleton does not show while it shows finer ones. */
static char
tk_interval_greatest(const tk_locale_data *loc, const tk_civil *ca, const tk_civil *cb, const char *skel)
{
    int has[7], smallest = -1, f;
    int twelve = strchr(skel, 'h') || strchr(skel, 'K');
    int period_b = strchr(skel, 'B') != NULL;
    int differs[7];
    static const char letters[7] = { 'G', 'y', 'M', 'd', 'a', 'h', 'm' };

    has[0] = strchr(skel, 'G') != NULL;
    has[1] = strchr(skel, 'y') || strchr(skel, 'u') || strchr(skel, 'U') || strchr(skel, 'r');
    has[2] = strchr(skel, 'M') || strchr(skel, 'L');
    has[3] = strchr(skel, 'd') != NULL;
    has[4] = period_b || (twelve && (strchr(skel, 'a') || strchr(skel, 'b') || twelve));
    has[5] = strchr(skel, 'h') || strchr(skel, 'H') || strchr(skel, 'k') || strchr(skel, 'K');
    has[6] = strchr(skel, 'm') != NULL;
    for (f = 0; f < 7; f++)
        if (has[f])
            smallest = f;

    differs[0] = (ca->year <= 0) != (cb->year <= 0);
    differs[1] = ca->year != cb->year;
    differs[2] = ca->month != cb->month;
    differs[3] = ca->day != cb->day;
    differs[4] = period_b ? tk_b_period(loc, ca) != tk_b_period(loc, cb) : (ca->hour >= 12) != (cb->hour >= 12);
    differs[5] = ca->hour != cb->hour;
    differs[6] = ca->minute != cb->minute;
    if (!has[4])
        differs[4] = 0;
    for (f = 0; f < 7; f++) {
        if (!differs[f])
            continue;
        if (has[f]) {
            if (f == 4) return period_b ? 'B' : 'a';
            if (f == 5) return twelve ? 'h' : 'H';
            return letters[f];
        }
        return smallest > f ? '!' : 0;
    }
    return 0;
}

/* The interval from a to b in the skeleton: one date where they agree in
 * every field the skeleton shows; the locale's interval pattern for the
 * greatest field that differs, its first half for a and its second for b;
 * the fallback round both where there is no pattern for the difference. */
static void
tk_format_interval(pTHX_ tk_out *o, SV *asv, tk_value *a, SV *bsv, tk_value *b, const tk_locale_data *loc,
                   const char *skel, const char *what)
{
    const char *single = tk_skeleton_pattern(loc, skel), *pat;
    int any;
    char g;

    pat = tk_interval_pattern(loc, skel, 0, &any);
    if (!any)
        croak("%s: the locale %s has no interval formats for the skeleton '%s'", what, loc->id, skel);
    if (!single)
        croak("%s: the locale %s has no format for the skeleton '%s'", what, loc->id, skel);
    g = tk_interval_greatest(loc, tk_value_civil(a), tk_value_civil(b), skel);
    if (!g) {
        tk_format_cldr(aTHX_ o, asv, a, loc, single, strlen(single), NULL, NULL);
        return;
    }
    pat = g == '!' ? NULL : tk_interval_pattern(loc, skel, g, &any);
    if (pat) {
        STRLEN len = strlen(pat), at = tk_interval_split(pat, len);
        tk_format_cldr(aTHX_ o, asv, a, loc, pat, at, NULL, NULL);
        tk_format_cldr(aTHX_ o, bsv, b, loc, pat + at, len - at, NULL, NULL);
        return;
    }
    /* The two differ in a field the skeleton does not show, or in one it
     * has no pattern for. As ECMAScript's formatRange does, each end is
     * written with the skeleton widened to the fields that differ: a date
     * skeleton gains the year (yMMMd for MMMd), a time skeleton gains the
     * numeric date (yMd) in the locale's date-time pattern; then the widened
     * skeleton's own interval pattern, else both round the fallback. */
    {
        const tk_civil *ca = tk_value_civil(a), *cb = tk_value_civil(b);
        int has_date = strchr(skel, 'y') || strchr(skel, 'M') || strchr(skel, 'd') || strchr(skel, 'E') || strchr(skel, 'G');
        char wide[32];
        const char *wpat = NULL, *date_pat = NULL;
        const char *fb = loc->w.interval_fallback ? loc->w.interval_fallback : "{0} – {1}";
        tk_out ta, tb;

        if (has_date) {
            /* the year in front when it differs and is missing */
            int need_y = (ca->year != cb->year) && !strchr(skel, 'y');
            if (need_y && strlen(skel) < 30) {
                wide[0] = 'y';
                strcpy(wide + 1, skel);
                wpat = tk_skeleton_pattern(loc, wide);
                if (wpat) {
                    char wg = tk_interval_greatest(loc, ca, cb, wide);
                    const char *ip = wg && wg != '!' ? tk_interval_pattern(loc, wide, wg, &any) : NULL;
                    if (ip) {
                        STRLEN len = strlen(ip), at = tk_interval_split(ip, len);
                        tk_format_cldr(aTHX_ o, asv, a, loc, ip, at, NULL, NULL);
                        tk_format_cldr(aTHX_ o, bsv, b, loc, ip + at, len - at, NULL, NULL);
                        return;
                    }
                }
            }
            if (!wpat)
                wpat = single;
        }
        else {
            date_pat = tk_skeleton_pattern(loc, "yMd");
            wpat = single;
        }
        ta.sv = sv_2mortal(newSVpvs(""));
        ta.utf8 = 0;
        ta.digits = NULL; ta.nums = NULL; ta.nums_len = 0;
        tb.sv = sv_2mortal(newSVpvs(""));
        tb.utf8 = 0;
        tb.digits = NULL; tb.nums = NULL; tb.nums_len = 0;
        if (date_pat) {
            const char *dt = loc->s.datetime_formats[TK_LEN_MEDIUM];
            tk_format_cldr(aTHX_ &ta, asv, a, loc, dt, strlen(dt), date_pat, wpat);
            tk_format_cldr(aTHX_ &tb, bsv, b, loc, dt, strlen(dt), date_pat, wpat);
        }
        else {
            tk_format_cldr(aTHX_ &ta, asv, a, loc, wpat, strlen(wpat), NULL, NULL);
            tk_format_cldr(aTHX_ &tb, bsv, b, loc, wpat, strlen(wpat), NULL, NULL);
        }
        if (ta.utf8 || tb.utf8)
            o->utf8 = 1;
        tk_out_fill(aTHX_ o, fb, SvPVX(ta.sv), SvPVX(tb.sv));
    }
}

#endif
