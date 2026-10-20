#ifndef TKS_ECLIPSE_H
#define TKS_ECLIPSE_H

/* Lunar eclipses. At each full moon (49.1) the moon's place (47) and the
 * VSOP87 sun give the moon's distance from the axis of the earth's shadow,
 * the antisolar point. The shadows' radii at the moon are Danjon's, as the
 * Five Millennium Canon (Espenak and Meeus) and the Connaissance des Temps
 * take them: the moon's parallax enlarged by 1.01 (1/85 for the opaque air,
 * less 1/594 for the earth's figure at 45 degrees),
 *     penumbra  1.01 Pm + Ss + Ps        umbra  1.01 Pm - Ss + Ps
 * with Pm the moon's equatorial horizontal parallax, Ss the sun's
 * semidiameter, Ps its parallax. Greatest eclipse is the moon's centre
 * nearest the axis, found by golden section; the contacts are where the
 * moon's limb meets each shadow's edge, by the Illinois method; the
 * magnitudes are the fraction of the moon's diameter inside each shadow at
 * greatest. Everything in JDE (TT) until the end. */

#define TKS_ECLIPSE_MAGIC 0x54534b45u
#define TKS_MOON_K        0.2725076     /* the moon's radius over the earth's equatorial (IAU) */
#define TKS_SUN_SD_1AU    959.63        /* the sun's semidiameter at 1 AU, arcseconds */
#define TKS_SUN_PI_1AU    8.794148      /* the sun's parallax at 1 AU, arcseconds */

#define TKS_E_LUNAR 0
#define TKS_E_SOLAR 1

#define TKS_LE_PENUMBRAL 0
#define TKS_LE_PARTIAL   1
#define TKS_LE_TOTAL     2

static const char *const tks_lunar_type_name[3] = { "penumbral", "partial", "total" };

/* P1 U1 U2 U3 U4 P4: the penumbra's, the umbra's first and last contacts,
 * and totality's beginning and end. */
#define TKS_LC_P1 0
#define TKS_LC_U1 1
#define TKS_LC_U2 2
#define TKS_LC_U3 3
#define TKS_LC_U4 4
#define TKS_LC_P4 5
static const char *const tks_lunar_contact_name[6] = { "p1", "u1", "u2", "u3", "u4", "p4" };

typedef struct tks_eclipse {
    uint32_t  magic;
    int32_t   kind, type;
    tks_place place;                /* only its zone and locale are used */
    double    jde_greatest;
    int64_t   greatest;
    int64_t   contact[6];
    uint8_t   has[6];
    double    umbral, penumbral, gamma;
    /* a solar eclipse's */
    double    magnitude, lat, lon, sun_alt, width, duration;
    double    central_start, central_end;     /* JDE; a central eclipse's line */
    int32_t   central;
} tks_eclipse;

/* What a lunar eclipse turns on at a JDE: the moon's distance from the
 * shadow's axis (m), the two shadows' radii (Rp, Ru) and the moon's
 * semidiameter (Sm), degrees; and whether the moon is north of the axis. */
typedef struct tks_lunar_geom {
    double m, Rp, Ru, Sm, Pm;
    int north;
} tks_lunar_geom;

static void
tks_lunar_at(double jde, tks_lunar_geom *g)
{
    tks_moonplace mp;
    tks_sunpos s;
    double ara, adec, Ps, Ss;
    tks_moon_place(jde, &mp);
    tks_sun_precise(jde, &s);
    ara = tks_deg_norm(s.ra + 180.0);
    adec = -s.dec;
    g->m = tks_separation(mp.ra, mp.dec, ara, adec);
    g->north = mp.dec > adec;
    Ps = TKS_SUN_PI_1AU / 3600.0 / s.R;
    Ss = TKS_SUN_SD_1AU / 3600.0 / s.R;
    g->Pm = mp.parallax;
    g->Rp = 1.01 * mp.parallax + Ss + Ps;
    g->Ru = 1.01 * mp.parallax - Ss + Ps;
    g->Sm = tks_deg(asin(TKS_MOON_K * sin(tks_rad(mp.parallax))));
}

static double
tks_lunar_m(double jde)
{
    tks_lunar_geom g;
    tks_lunar_at(jde, &g);
    return g.m;
}

/* m less a contact's reach (which: 0 penumbra outer, 1 umbra outer, 2 umbra
 * inner): nought at the contact, negative inside. */
static double
tks_lunar_contact_f(double jde, int which)
{
    tks_lunar_geom g;
    tks_lunar_at(jde, &g);
    return which == 0 ? g.m - (g.Rp + g.Sm) : which == 1 ? g.m - (g.Ru + g.Sm) : g.m - (g.Ru - g.Sm);
}

/* The root of tks_lunar_contact_f between lo and hi (of opposite signs), by
 * the Illinois method to 1e-7 day. */
static double
tks_lunar_contact(int which, double lo, double hi)
{
    double flo = tks_lunar_contact_f(lo, which), fhi = tks_lunar_contact_f(hi, which), t = lo;
    int side = 0, i;
    for (i = 0; i < 100 && hi - lo > 1e-7; i++) {
        double f;
        t = (lo * fhi - hi * flo) / (fhi - flo);
        if (t <= lo || t >= hi)
            t = 0.5 * (lo + hi);
        f = tks_lunar_contact_f(t, which);
        if (f == 0.0)
            return t;
        if ((f < 0.0) == (flo < 0.0)) {
            lo = t; flo = f;
            if (side == -1) fhi *= 0.5;
            side = -1;
        }
        else {
            hi = t; fhi = f;
            if (side == 1) flo *= 0.5;
            side = 1;
        }
    }
    return t;
}

/* The lunar eclipse at the full moon of lunation k + 0.5, if there is one:
 * 1 and the eclipse filled in (its values' zone and locale from p), or 0. */
static int
tks_lunar_eclipse_at(pTHX_ double k, const tks_place *p, tks_eclipse *e)
{
    const double g = 0.6180339887498949;
    double full = tks_phase_jde(k), a = full - 0.3, c = full + 0.3, b, d, fb, fd, tg;
    tks_lunar_geom G;
    int i;

    /* far from the shadow at the full moon: no eclipse that month */
    tks_lunar_at(full, &G);
    if (G.m > G.Rp + G.Sm + 0.5)
        return 0;
    b = c - g * (c - a);
    d = a + g * (c - a);
    fb = tks_lunar_m(b);
    fd = tks_lunar_m(d);
    while (c - a > 1e-7) {
        if (fb < fd) { c = d; d = b; fd = fb; b = c - g * (c - a); fb = tks_lunar_m(b); }
        else         { a = b; b = d; fb = fd; d = a + g * (c - a); fd = tks_lunar_m(d); }
    }
    tg = 0.5 * (a + c);
    tks_lunar_at(tg, &G);
    if (G.m >= G.Rp + G.Sm)
        return 0;                       /* the penumbra misses the moon */

    memset(e, 0, sizeof *e);
    e->magic = TKS_ECLIPSE_MAGIC;
    e->kind = TKS_E_LUNAR;
    e->place = *p;
    e->jde_greatest = tg;
    e->greatest = tks_jde_to_sec(aTHX_ tg);
    e->penumbral = (G.Rp + G.Sm - G.m) / (2.0 * G.Sm);
    e->umbral = (G.Ru + G.Sm - G.m) / (2.0 * G.Sm);
    e->gamma = (G.north ? 1.0 : -1.0) * sin(tks_rad(G.m)) / sin(tks_rad(G.Pm));
    e->type = e->umbral >= 1.0 ? TKS_LE_TOTAL : e->umbral > 0.0 ? TKS_LE_PARTIAL : TKS_LE_PENUMBRAL;

    /* the contacts, each side of greatest: the penumbra's always, the
     * umbra's in a partial or total eclipse, totality's in a total one;
     * contact[i] before and contact[5 - i] after is P1 U1 U2 ... U3 U4 P4 */
    for (i = 0; i < 3; i++) {
        double before, after;
        if ((i == 1 && e->type == TKS_LE_PENUMBRAL) || (i == 2 && e->type != TKS_LE_TOTAL))
            continue;
        before = tks_lunar_contact(i, tg - 0.3, tg);
        after  = tks_lunar_contact(i, tg, tg + 0.3);
        e->contact[i]     = tks_jde_to_sec(aTHX_ before);
        e->contact[5 - i] = tks_jde_to_sec(aTHX_ after);
        e->has[i] = e->has[5 - i] = 1;
    }
    return 1;
}

/* The next (or previous) lunar eclipse whose greatest is after (before) an
 * instant: lunations walked from just behind it, at most 60 years. */
static int
tks_lunar_eclipse_find(pTHX_ int64_t from, int backwards, const tks_place *p, tks_eclipse *e)
{
    double jd = TKS_JD_EPOCH + (double)from / 86400.0;
    double k = floor((tks_decimal_year(jd) - 2000.0) * TKS_LUNATIONS_A_YEAR) + 0.5;
    int n;
    k += backwards ? 2.0 : -2.0;
    for (n = 0; n < 750; n++, k += backwards ? -1.0 : 1.0)
        if (tks_lunar_eclipse_at(aTHX_ k, p, e)
            && ((!backwards && e->greatest > from) || (backwards && e->greatest < from)))
            return 1;
    return 0;
}

static const tks_eclipse *
tks_eclipse_of(pTHX_ SV *sv, const char *what)
{
    SV *inner;
    const tks_eclipse *e;
    if (!sv || !SvROK(sv) || !sv_derived_from(sv, "Time::Keeper::Eclipse"))
        croak("%s: not a Time::Keeper::Eclipse", what);
    inner = SvRV(sv);
    if (!SvPOK(inner) || SvCUR(inner) != sizeof(tks_eclipse))
        croak("%s: not a Time::Keeper::Eclipse", what);
    e = (const tks_eclipse *)SvPVX(inner);
    if (e->magic != TKS_ECLIPSE_MAGIC)
        croak("%s: not a Time::Keeper::Eclipse", what);
    return e;
}

/* kind => lunar or solar. */
static int
tks_eclipse_kind_arg(pTHX_ SV *sv, const char *what)
{
    STRLEN len;
    const char *s;
    if (!sv || !SvOK(sv))
        croak("%s needs kind => lunar or solar", what);
    s = SvPV_nomg(sv, len);
    if (len == 5 && memEQ(s, "lunar", 5))
        return TKS_E_LUNAR;
    if (len == 5 && memEQ(s, "solar", 5))
        return TKS_E_SOLAR;
    croak("%s: no eclipse kind is called '%.*s' (lunar or solar)", what, (int)len, s);
    return -1;
}

#endif
