/* What a territory or a locale prefers: CLDR's calendarPreferenceData by
 * territory (tk_cal_prefs, generated), a locale's territory being its own,
 * else the one its language is likely in (tk_cal_likelies, from CLDR's
 * likelySubtags), else the world, 001. Included after tk_locale_load.h. */
#ifndef TK_CAL_META_H
#define TK_CAL_META_H

static const char *
tk_cal_prefs_of(const char *territory, STRLEN len)
{
    unsigned i;
    for (i = 0; i < sizeof tk_cal_prefs / sizeof tk_cal_prefs[0]; i++)
        if (strlen(tk_cal_prefs[i].territory) == len && memEQ(tk_cal_prefs[i].territory, territory, len))
            return tk_cal_prefs[i].ids;
    return NULL;
}

static const char *
tk_cal_likely_territory(const char *code)
{
    int lo = 0, hi = (int)(sizeof tk_cal_likelies / sizeof tk_cal_likelies[0]) - 1;
    while (lo <= hi) {
        int mid = lo + (hi - lo) / 2;
        int c = strcmp(tk_cal_likelies[mid].code, code);
        if (c == 0)
            return tk_cal_likelies[mid].territory;
        if (c < 0) lo = mid + 1; else hi = mid - 1;
    }
    return NULL;
}

/* The ids a territory (two CAPITAL letters or three digits; two small
 * letters are a language) or a locale prefers, space separated, most
 * preferred first; never NULL. */
static const char *
tk_cal_preferred_ids(pTHX_ SV *where, const char *what)
{
    STRLEN len;
    const char *s, *t = NULL, *ids = NULL;
    char terr[4];
    int id;
    if (!where || !SvOK(where))
        croak("%s: a territory or a locale code is wanted", what);
    s = SvPV(where, len);
    if ((len == 2 && isUPPER(s[0]) && isUPPER(s[1])) || (len == 3 && isDIGIT(s[0]) && isDIGIT(s[1]) && isDIGIT(s[2]))) {
        STRLEN i;
        for (i = 0; i < len; i++)
            terr[i] = (char)toUPPER(s[i]);
        terr[len] = '\0';
        ids = tk_cal_prefs_of(terr, len);
    }
    else {
        id = tk_locale_find(s, len);
        if (id < 0)
            croak("%s: '%" SVf "' is neither a territory nor a locale", what, SVfARG(where));
        t = tk_locale_codes[id].parts[2];
        if (!t)
            t = tk_cal_likely_territory(tk_locale_codes[id].code);
        if (t)
            ids = tk_cal_prefs_of(t, strlen(t));
    }
    if (!ids)
        ids = tk_cal_prefs_of("001", 3);
    return ids ? ids : "gregory";
}

#endif
