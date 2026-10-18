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
    if (lsep)
        lid = tk_locale_id_from_sv(aTHX_ sv_2mortal(newSVpvn(lsep + 1, len - (lsep + 1 - s))), what);
    tk_zone_spec_from_sv(aTHX_ zone, &z, what);
    if (!tk_instant_valid(&t))
        croak("%s: out of range", what);
    tk_value_init(aTHX_ v, &t, &z);
    v->locale = lid;
}

/* The frozen value with its locale: what STORABLE_freeze and FREEZE give. */
static SV *
tk_freeze_full_sv(pTHX_ const tk_value *v)
{
    SV *out = tk_freeze_sv(aTHX_ v);
    if (v->locale && v->locale < TK_LOCALE_COUNT)
        sv_catpvf(out, " %s", tk_locale_codes[v->locale].code);
    return out;
}


#endif
