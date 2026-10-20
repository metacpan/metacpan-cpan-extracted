#ifndef TKS_SUN_H
#define TKS_SUN_H

/* The sun's apparent place by chapter 25's low-accuracy method (0.01
 * degree in longitude), the equation of time by 28.3, the local hour angle,
 * altitude and azimuth by chapter 13, and Saemundsson's refraction (16.4)
 * for the apparent altitude only.
 *
 * Longitudes on the ground are EAST positive and azimuths run from NORTH
 * through east, here and in everything above this header. The book counts
 * longitude west and azimuth from the south; the two conversions are made
 * once each, in tks_altaz, and nowhere else. */

typedef struct tks_sunpos {
    double T;           /* Julian centuries from J2000.0, TT */
    double L0, M, e, C; /* mean longitude, mean anomaly (both reduced), eccentricity, equation of centre, degrees */
    double lon_true;    /* the true geometric longitude, degrees */
    double lon;         /* the apparent longitude, degrees */
    double eps;         /* the obliquity used for the apparent place (25.8), degrees */
    double ra, dec;     /* apparent right ascension and declination, degrees */
    double R;           /* the radius vector, AU */
    double eot;         /* the equation of time, seconds: positive when the sundial is ahead */
} tks_sunpos;

/* The sun's place at a JDE, everything but the equation of time: what an
 * altitude needs. */
static void
tks_sun_place(double jde, tks_sunpos *s)
{
    double T = tks_T(jde);
    double Mr, nu, om, lam, eps_r, e;

    s->T  = T;
    s->L0 = tks_deg_norm(280.46646 + T * (36000.76983 + T * 0.0003032));
    s->M  = tks_deg_norm(357.52911 + T * (35999.05029 - T * 0.0001537));
    s->e  = e = 0.016708634 - T * (0.000042037 + T * 0.0000001267);
    Mr    = tks_rad(s->M);
    s->C  = (1.914602 - T * (0.004817 + T * 0.000014)) * sin(Mr)
          + (0.019993 - 0.000101 * T) * sin(2.0 * Mr)
          + 0.000289 * sin(3.0 * Mr);
    s->lon_true = tks_deg_norm(s->L0 + s->C);
    nu    = s->M + s->C;
    s->R  = 1.000001018 * (1.0 - e * e) / (1.0 + e * cos(tks_rad(nu)));
    om    = tks_rad(tks_deg_norm(125.04 - 1934.136 * T));
    s->lon = lam = tks_deg_norm(s->lon_true - 0.00569 - 0.00478 * sin(om));
    s->eps = tks_obliquity_mean(T) + 0.00256 * cos(om);
    eps_r = tks_rad(s->eps);
    s->ra  = tks_deg_norm(tks_deg(atan2(cos(eps_r) * sin(tks_rad(lam)), cos(tks_rad(lam)))));
    s->dec = tks_deg(asin(sin(eps_r) * sin(tks_rad(lam))));
    s->eot = 0.0;
}

/* The sun at a JDE, with the equation of time. */
static void
tks_sun_at(double jde, tks_sunpos *s)
{
    double T, Mr, e, y, L0r, eot_rad, eps_true, dpsi, deps;
    tks_sun_place(jde, s);
    T = s->T;
    e = s->e;
    Mr = tks_rad(s->M);

    /* 28.3, with the true obliquity, in radians, then seconds of time. */
    tks_nutation(T, &dpsi, &deps);
    eps_true = tks_obliquity_mean(T) + deps / 3600.0;
    y = tan(tks_rad(eps_true) / 2.0);
    y *= y;
    L0r = tks_rad(s->L0);
    eot_rad = y * sin(2.0 * L0r) - 2.0 * e * sin(Mr) + 4.0 * e * y * sin(Mr) * cos(2.0 * L0r)
            - 0.5 * y * y * sin(4.0 * L0r) - 1.25 * e * e * sin(2.0 * Mr);
    s->eot = tks_deg(eot_rad) * 240.0;
}

/* The local hour angle (degrees, -180 to 180, positive after the meridian),
 * the geometric altitude and the azimuth from the north through the east,
 * of a body at apparent (ra, dec) seen from (lat, east longitude) at the UT
 * JD given, with its JDE for the nutation. */
static void
tks_altaz_theta(double theta, double lat, double lon_east, double ra, double dec,
                double *alt, double *az, double *H)
{
    double h = tks_deg_norm(theta + lon_east - ra);
    double phi = tks_rad(lat), d = tks_rad(dec), hr = tks_rad(h);
    *alt = tks_deg(asin(sin(phi) * sin(d) + cos(phi) * cos(d) * cos(hr)));
    *az  = tks_deg_norm(tks_deg(atan2(sin(hr), cos(hr) * sin(phi) - tan(d) * cos(phi))) + 180.0);
    *H   = h > 180.0 ? h - 360.0 : h;
}

static void
tks_altaz(double jd_ut, double jde, double lat, double lon_east, double ra, double dec,
          double *alt, double *az, double *H)
{
    tks_altaz_theta(tks_sidereal_apparent(jd_ut, jde), lat, lon_east, ra, dec, alt, az, H);
}

/* Saemundsson's refraction (16.4), arcminutes, for a GEOMETRIC altitude in
 * degrees; the small term makes it zero at the zenith. Applied only from a
 * degree below the horizon up: the formula has a pole at -5.11 degrees and
 * means nothing under the horizon band. */
static double
tks_refraction(double h)
{
    if (h < -1.0)
        return 0.0;
    return 1.02 / tan(tks_rad(h + 10.3 / (h + 5.11))) + 0.0019279;
}

/* A double stored in a struct, as an NV: on a perl whose NV is wider than a
 * double, the double printed to the 15 digits it holds and read back, so a
 * latitude given as 51.5074 comes back as 51.5074 and not as the double's
 * 51.507399999999997. */
static NV
tks_nv_of(pTHX_ double d)
{
    if (sizeof(NV) > sizeof(double)) {
        char buf[40];
        snprintf(buf, sizeof buf, "%.15g", d);
        return Atof(buf);
    }
    return (NV)d;
}

/* ---- a place ------------------------------------------------------------- */

#define TKS_PLACE_MAGIC 0x54534b50u

typedef struct tks_place {
    uint32_t magic;
    uint16_t zone_id, locale_id;  /* the names, interned (tks_names.h) */
    double   lat, lon, elev;      /* degrees north, degrees east, metres */
    time_keeper_zone zone;
    int      locale;
} tks_place;

static const tks_place *
tks_place_of(pTHX_ SV *sv, const char *what)
{
    SV *inner;
    const tks_place *p;
    if (!sv || !SvROK(sv) || !sv_derived_from(sv, "Time::Keeper::Sky"))
        croak("%s: not a Time::Keeper::Sun place", what);
    inner = SvRV(sv);
    if (!SvPOK(inner) || SvCUR(inner) != sizeof(tks_place))
        croak("%s: not a Time::Keeper::Sun place", what);
    p = (const tks_place *)SvPVX(inner);
    if (p->magic != TKS_PLACE_MAGIC)
        croak("%s: not a Time::Keeper::Sun place", what);
    return p;
}

/* The sun seen from a place at an instant: everything position reports. */
typedef struct tks_sunview {
    tks_sunpos sun;
    double alt, app_alt, az, H;
} tks_sunview;

static void
tks_sun_view(pTHX_ const tks_place *p, const time_keeper_instant *t, tks_sunview *v)
{
    double jd  = tks_jd_ut(t);
    double jde = tks_jde(aTHX_ t);
    tks_sun_at(jde, &v->sun);
    tks_altaz(jd, jde, p->lat, p->lon, v->sun.ra, v->sun.dec, &v->alt, &v->az, &v->H);
    v->app_alt = v->alt + tks_refraction(v->alt) / 60.0;
}

#endif
