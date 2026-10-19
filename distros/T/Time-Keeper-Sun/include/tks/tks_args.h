#ifndef TKS_ARGS_H
#define TKS_ARGS_H

/* kind => civil | nautical | astronomical, from the rest of an argument
 * list; civil when there is none. Returns the depth index 1 to 3. */
static int
tks_twilight_depth_arg(pTHX_ SV **args, int n, const char *what)
{
    STRLEN klen, vlen;
    const char *k, *v;
    if (n == 0)
        return 1;
    if (n != 2)
        croak("%s takes kind => civil, nautical or astronomical", what);
    SvGETMAGIC(args[0]);
    SvGETMAGIC(args[1]);
    k = SvPV(args[0], klen);
    if (klen != 4 || !memEQ(k, "kind", 4))
        croak("%s: unknown argument '%.*s'", what, (int)klen, k);
    if (!SvOK(args[1]))
        croak("%s takes kind => civil, nautical or astronomical", what);
    v = SvPV(args[1], vlen);
    if (vlen == 5 && memEQ(v, "civil", 5)) return 1;
    if (vlen == 8 && memEQ(v, "nautical", 8)) return 2;
    if (vlen == 12 && memEQ(v, "astronomical", 12)) return 3;
    croak("%s: no twilight is called '%.*s' (civil, nautical or astronomical)", what, (int)vlen, v);
    return 1;
}

#endif

/* A place that carries only a zone and a locale, for the moon's methods,
 * which take no coordinates: filled with the defaults, then set. */
static void
tks_place_set_zone(pTHX_ tks_place *p, SV *v, const char *what)
{
    STRLEN zlen;
    const char *zname;
    if (v)
        SvGETMAGIC(v);
    if (!v || !SvOK(v))
        croak("%s: zone must be a zone name", what);
    zname = SvPVutf8(v, zlen);
    if ((tks_tk(aTHX)->zone_parse)(aTHX_ zname, zlen, &p->zone) != TIME_KEEPER_OK)
        croak("%s: no such zone '%.*s'", what, (int)zlen, zname);
    if (p->zone.kind == TIME_KEEPER_ZONE_FLOATING)
        croak("%s: the floating zone has no day; give one with an offset", what);
    p->zone_id = (uint16_t)tks_name_id(aTHX_ zname, zlen);
}

static void
tks_place_set_locale(pTHX_ tks_place *p, SV *v, const char *what)
{
    STRLEN llen;
    const char *lcode;
    if (v)
        SvGETMAGIC(v);
    if (!v || !SvOK(v))
        croak("%s: locale must be a locale code", what);
    lcode = SvPV(v, llen);
    if ((p->locale = (tks_tk(aTHX)->locale_find)(lcode, llen)) < 0)
        croak("%s: no such locale '%.*s'", what, (int)llen, lcode);
    p->locale_id = (uint16_t)tks_name_id(aTHX_ lcode, llen);
}

static void
tks_place_for_zone(pTHX_ tks_place *p, const char *zname, STRLEN zlen, const char *lcode, STRLEN llen, const char *what)
{
    memset(p, 0, sizeof *p);
    p->magic = TKS_PLACE_MAGIC;
    if ((tks_tk(aTHX)->zone_parse)(aTHX_ zname, zlen, &p->zone) != TIME_KEEPER_OK)
        croak("%s: no such zone '%.*s'", what, (int)zlen, zname);
    p->zone_id = (uint16_t)tks_name_id(aTHX_ zname, zlen);
    p->locale = (tks_tk(aTHX)->locale_find)(lcode, llen);
    if (p->locale < 0)
        p->locale = 0;
    p->locale_id = (uint16_t)tks_name_id(aTHX_ lcode, llen);
}

/* phase => new | first_quarter | full | last_quarter (also first, last). */
static int
tks_phase_arg(pTHX_ SV *v, const char *what)
{
    STRLEN len;
    const char *s;
    if (v)
        SvGETMAGIC(v);
    if (!v || !SvOK(v))
        croak("%s needs phase => new, first_quarter, full or last_quarter", what);
    s = SvPV(v, len);
    if (len == 3 && memEQ(s, "new", 3)) return 0;
    if ((len == 13 && memEQ(s, "first_quarter", 13)) || (len == 5 && memEQ(s, "first", 5))) return 1;
    if (len == 4 && memEQ(s, "full", 4)) return 2;
    if ((len == 12 && memEQ(s, "last_quarter", 12)) || (len == 4 && memEQ(s, "last", 4))) return 3;
    croak("%s: no phase is called '%.*s' (new, first_quarter, full or last_quarter)", what, (int)len, s);
    return 0;
}

/* Where a moon method answers for: UTC and English, or the place given with
 * place => (a Time::Keeper::Sun), then zone => and locale => over either,
 * whatever order they came in. Returns whether a place was given. */
static int
tks_where(pTHX_ tks_place *p, SV *place, SV *zone, SV *locale, const char *what)
{
    tks_place_for_zone(aTHX_ p, "UTC", 3, "en", 2, what);
    if (place)
        *p = *tks_place_of(aTHX_ place, what);
    if (zone)
        tks_place_set_zone(aTHX_ p, zone, what);
    if (locale)
        tks_place_set_locale(aTHX_ p, locale, what);
    return place != NULL;
}
