#ifndef TK_FREEZE_H
#define TK_FREEZE_H

/* A value frozen as text and read back. tk_freeze_sv writes the instant and
 * the zone; these add the locale, which needs the locale table. */

/* A frozen value read back: "tk1 sec nsec zone[ locale]". */
static void
tk_thaw_value(pTHX_ SV *frozen, tk_value *v, const char *what)
{
    const char *s, *p, *lsep;
    STRLEN len;
    tk_instant t;
    tk_zone_spec z;
    SV *num, *zone;
    uint16_t lid = 0;
    int cal = TK_CAL_GREGORY;
    long ns;

    s = SvPV(frozen, len);
    if (len < 4 || memNE(s, "tk1 ", 4))
        croak("%s: not a frozen Time::Keeper value", what);
    p = strchr(s + 4, ' ');
    if (!p)
        croak("%s: not a frozen Time::Keeper value", what);
    num = sv_2mortal(newSVpvn(s + 4, p - (s + 4)));
    if (!tk_sv_to_i64(aTHX_ num, &t.sec))
        croak("%s: not a frozen Time::Keeper value", what);
    ns = strtol(p + 1, (char **)&p, 10);
    if (*p != ' ' || ns < 0 || ns >= 2L * TK_NSECS_PER_SEC)
        croak("%s: not a frozen Time::Keeper value", what);
    t.nsec = (int32_t)ns;
    lsep = strchr(p + 1, ' ');
    zone = sv_2mortal(newSVpvn(p + 1, (lsep ? lsep : s + len) - (p + 1)));
    if (lsep) {
        const char *csep = strchr(lsep + 1, ' ');
        lid = tk_locale_id_from_sv(aTHX_ sv_2mortal(newSVpvn(lsep + 1, (csep ? csep : s + len) - (lsep + 1))), what);
        if (csep) {
            cal = tk_cal_find(csep + 1, len - (csep + 1 - s));
            if (cal < 0)
                croak("%s: not a frozen Time::Keeper value: unknown calendar", what);
            tk_cal_check_built(aTHX_ cal, what);
        }
    }
    tk_zone_spec_from_sv(aTHX_ zone, &z, what);
    if (!tk_instant_valid(&t))
        croak("%s: out of range", what);
    tk_value_init(aTHX_ v, &t, &z);
    v->locale = lid;
    v->calendar = (uint8_t)cal;
}

/* The frozen value with its locale: what STORABLE_freeze and FREEZE give. */
static SV *
tk_freeze_full_sv(pTHX_ const tk_value *v)
{
    SV *out = tk_freeze_sv(aTHX_ v);
    if (v->calendar)
        sv_catpvf(out, " %s %s", tk_locale_codes[v->locale < TK_LOCALE_COUNT ? v->locale : 0].code, tk_cal_of(v)->id);
    else if (v->locale && v->locale < TK_LOCALE_COUNT)
        sv_catpvf(out, " %s", tk_locale_codes[v->locale].code);
    return out;
}


#endif
