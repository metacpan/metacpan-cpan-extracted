#ifndef TKS_VSOP_H
#define TKS_VSOP_H

/* VSOP87D, every term (tks_vsop87d.h, generated): the heliocentric ecliptic
 * longitude, latitude and radius of a planet, referred to the ecliptic and
 * equinox of date; and from the earth's, the sun's apparent place to an
 * arcsecond (Meeus 25.9, 25.10 and the FK5 correction), behind precise =>. */

typedef struct tks_vsop_term {
    double a, b, c;
} tks_vsop_term;

typedef struct tks_vsop_series {
    const tks_vsop_term *t;
    int n;
} tks_vsop_series;

#include "tks_vsop87d.h"

#define TKS_MERCURY 0
#define TKS_VENUS   1
#define TKS_EARTH   2
#define TKS_MARS    3
#define TKS_JUPITER 4
#define TKS_SATURN  5
#define TKS_URANUS  6
#define TKS_NEPTUNE 7
#define TKS_VSOP_PLANETS 8
#define TKS_PLUTO   8               /* by Meeus's chapter 37, not VSOP87 */
#define TKS_BODIES  9

static const char *const tks_planet_name[TKS_BODIES] = {
    "mercury", "venus", "earth", "mars", "jupiter", "saturn", "uranus", "neptune", "pluto",
};

/* One series, A cos(B + C t) summed smallest term first: the files list the
 * terms largest first, and the small ones added to each other before the
 * large carry their last bits. */
static double
tks_vsop_sum(const tks_vsop_series *s, double t)
{
    double v = 0.0;
    int i;
    for (i = s->n - 1; i >= 0; i--)
        v += s->t[i].a * cos(s->t[i].b + s->t[i].c * t);
    return v;
}

/* L, B (radians, L not reduced) and R (AU) of a planet at a JDE, by the
 * powers of t in Julian millennia from J2000.0 by Horner's rule. TDB is
 * taken as TT: they differ by under 2 ms. */
static void
tks_vsop_lbr(int planet, double jde, double *L, double *B, double *R)
{
    double t = (jde - TKS_J2000) / 365250.0;
    double out[3];
    int k, p;
    for (k = 0; k < 3; k++) {
        double v = 0.0;
        for (p = 5; p >= 0; p--)
            v = v * t + (tks_vsop87d[planet][k][p].n ? tks_vsop_sum(&tks_vsop87d[planet][k][p], t) : 0.0);
        out[k] = v;
    }
    *L = out[0];
    *B = out[1];
    *R = out[2];
}

/* L, B, R as tks_vsop_lbr, and their rates a day: each term's derivative is
 * -A C sin(B + C t), and the powers of t are carried by Horner's rule for
 * the derivative alongside the value's. For the earth's velocity, which the
 * planets' aberration needs. */
static void
tks_vsop_lbr_dot(int planet, double jde, double *v, double *d)
{
    double t = (jde - TKS_J2000) / 365250.0;
    int k, p, i;
    for (k = 0; k < 3; k++) {
        double val = 0.0, der = 0.0, wd = 0.0;
        for (p = 5; p >= 0; p--) {
            const tks_vsop_series *s = &tks_vsop87d[planet][k][p];
            double S = 0.0, Sd = 0.0;
            for (i = s->n - 1; i >= 0; i--) {
                double arg = s->t[i].b + s->t[i].c * t;
                S  += s->t[i].a * cos(arg);
                Sd -= s->t[i].a * s->t[i].c * sin(arg);
            }
            der = der * t + val;
            val = val * t + S;
            wd  = wd * t + Sd;
        }
        v[k] = val;
        d[k] = (der + wd) / 365250.0;
    }
}

/* The sun's apparent place at a JDE from the VSOP87 earth: geocentric
 * longitude L + 180 and latitude -B, the FK5 correction (25.9), the nutation
 * in longitude and the aberration (25.10), then right ascension and
 * declination with the true obliquity, the latitude counted. The equation of
 * time by 28.1, the sun's mean longitude by 28.2. Fills the fields an
 * altitude and position read; the chapter 25 elements (M, e, C) are 0. */
static void
tks_sun_precise(double jde, tks_sunpos *s)
{
    double L, B, R, T = tks_T(jde), tau = T / 10.0;
    double th, be, lp, dpsi, deps, eps, lam, bet, L0, eot;
    tks_vsop_lbr(TKS_EARTH, jde, &L, &B, &R);
    th = tks_deg_norm(tks_deg(L) + 180.0);
    be = -tks_deg(B);
    lp = tks_rad(th - 1.397 * T - 0.00031 * T * T);
    th += -0.09033 / 3600.0;
    be += (0.03916 / 3600.0) * (cos(lp) - sin(lp));
    tks_nutation(T, &dpsi, &deps);
    eps = tks_obliquity_mean(T) + deps / 3600.0;
    lam = tks_deg_norm(th + dpsi / 3600.0 - 20.4898 / (3600.0 * R));

    memset(s, 0, sizeof *s);
    s->T = T;
    s->lon_true = tks_deg_norm(th);
    s->lon = lam;
    s->eps = eps;
    s->R = R;
    bet = tks_rad(be);
    {
        double er = tks_rad(eps), lr = tks_rad(lam);
        s->ra  = tks_deg_norm(tks_deg(atan2(sin(lr) * cos(er) - tan(bet) * sin(er), cos(lr))));
        s->dec = tks_deg(asin(sin(bet) * cos(er) + cos(bet) * sin(er) * sin(lr)));
    }
    L0 = tks_deg_norm(280.4664567 + tau * (360007.6982779 + tau * (0.03032028
         + tau * (1.0 / 49931.0 + tau * (-1.0 / 15300.0 - tau / 2000000.0)))));
    s->L0 = L0;
    eot = L0 - 0.0057183 - s->ra + (dpsi / 3600.0) * cos(tks_rad(eps));
    eot = fmod(eot, 360.0);
    if (eot > 180.0) eot -= 360.0;
    if (eot < -180.0) eot += 360.0;
    s->eot = eot * 240.0;
}

static void
tks_sun_view_precise(pTHX_ const tks_place *p, const time_keeper_instant *t, tks_sunview *v)
{
    double jd  = tks_jd_ut(t);
    double jde = tks_jde(aTHX_ t);
    tks_sun_precise(jde, &v->pos);
    tks_altaz(jd, jde, p->lat, p->lon, v->pos.ra, v->pos.dec, &v->alt, &v->az, &v->H);
    v->app_alt = v->alt + tks_refraction(v->alt) / 60.0;
}

/* A planet's name, as an index; earth only where it is allowed. */
static int
tks_planet_arg(pTHX_ SV *sv, int allow_earth, const char *what)
{
    STRLEN len;
    const char *s;
    int i;
    if (sv)
        SvGETMAGIC(sv);
    if (!sv || !SvOK(sv))
        croak("%s needs a planet's name", what);
    s = SvPV_nomg(sv, len);
    for (i = 0; i < TKS_BODIES; i++) {
        if (i == TKS_EARTH && !allow_earth)
            continue;
        if (strlen(tks_planet_name[i]) == len && memEQ(tks_planet_name[i], s, len))
            return i;
    }
    croak("%s: no planet is called '%.*s' (mercury, venus,%s mars, jupiter, saturn, uranus, neptune or pluto)",
          what, (int)len, s, allow_earth ? " earth," : "");
    return -1;
}

#endif
