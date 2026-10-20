#ifndef TKS_MOONPOS_H
#define TKS_MOONPOS_H

/* The moon's place by chapter 47: its geocentric ecliptic longitude,
 * latitude and distance from the mean arguments 47.1 to 47.5 and the 60
 * terms of each of tables 47.A and 47.B (good to 10 arcseconds in longitude
 * and 4 in latitude); the apparent place with the nutation in longitude and
 * the true obliquity; the horizontal parallax; and the topocentric hour angle
 * and declination from a place by chapter 40's rigorous method. */

#include "tks_moon47.h"

#define TKS_EARTH_A_KM 6378.14
#define TKS_EARTH_F    (1.0 / 298.257)

typedef struct tks_moonplace {
    double lon_geo, lat;        /* geometric longitude (mean equinox of date) and latitude, degrees */
    double lon;                 /* apparent longitude, with the nutation, degrees */
    double distance;            /* km, centre to centre */
    double parallax;            /* equatorial horizontal parallax, degrees */
    double ra, dec;             /* apparent geocentric right ascension and declination, degrees */
    double dpsi, eps_true;      /* the nutation in longitude (arcseconds) and the true obliquity (degrees) used */
} tks_moonplace;

/* cos(k x) and sin(k x) for k = -4 to 4, at index k + 4. */
static void
tks_multiples(double x, double *c, double *s)
{
    int k;
    c[4] = 1.0;
    s[4] = 0.0;
    c[5] = cos(x);
    s[5] = sin(x);
    for (k = 6; k < 9; k++) {
        c[k] = c[k - 1] * c[5] - s[k - 1] * s[5];
        s[k] = s[k - 1] * c[5] + c[k - 1] * s[5];
    }
    for (k = 0; k < 4; k++) {
        c[k] = c[8 - k];
        s[k] = -s[8 - k];
    }
}

/* The cosine and sine of a D + b M + c M' + d F from the multiples. */
static void
tks_term(const int32_t *r, const double *cD, const double *sD, const double *cM, const double *sM,
         const double *cP, const double *sP, const double *cF, const double *sF, double *c, double *s)
{
    double c1 = cD[r[0] + 4], s1 = sD[r[0] + 4], c2, s2, t;
    c2 = cM[r[1] + 4]; s2 = sM[r[1] + 4];
    t = c1 * c2 - s1 * s2; s1 = s1 * c2 + c1 * s2; c1 = t;
    c2 = cP[r[2] + 4]; s2 = sP[r[2] + 4];
    t = c1 * c2 - s1 * s2; s1 = s1 * c2 + c1 * s2; c1 = t;
    c2 = cF[r[3] + 4]; s2 = sF[r[3] + 4];
    t = c1 * c2 - s1 * s2; s1 = s1 * c2 + c1 * s2; c1 = t;
    *c = c1;
    *s = s1;
}

/* The moon at a JDE. */
static void
tks_moon_place(double jde, tks_moonplace *m)
{
    double T = tks_T(jde);
    double Lp = tks_deg_norm(218.3164477 + T * (481267.88123421 + T * (-0.0015786 + T * (1.0 / 538841.0 - T / 65194000.0))));
    double D  = tks_deg_norm(297.8501921 + T * (445267.1114034 + T * (-0.0018819 + T * (1.0 / 545868.0 - T / 113065000.0))));
    double M  = tks_deg_norm(357.5291092 + T * (35999.0502909 + T * (-0.0001536 + T / 24490000.0)));
    double Mp = tks_deg_norm(134.9633964 + T * (477198.8675055 + T * (0.0087414 + T * (1.0 / 69699.0 - T / 14712000.0))));
    double F  = tks_deg_norm(93.2720950 + T * (483202.0175233 + T * (-0.0036539 + T * (-1.0 / 3526000.0 + T / 863310000.0))));
    double A1 = tks_rad(tks_deg_norm(119.75 + 131.849 * T));
    double A2 = tks_rad(tks_deg_norm(53.09 + 479264.290 * T));
    double A3 = tks_rad(tks_deg_norm(313.45 + 481266.484 * T));
    double E  = 1.0 - T * (0.002516 + T * 0.0000074);
    double Lr = tks_rad(Lp), Fr = tks_rad(F), Mpr = tks_rad(Mp);
    double sl = 0.0, sr = 0.0, sb = 0.0;
    double dpsi, deps, eps, lam, bet;
    double cD[9], sD[9], cM[9], sM[9], cP[9], sP[9], cF[9], sF[9];
    int i;

    /* The cosine and sine of each argument's small multiples, by the
     * angle-addition recurrence from one cosine and one sine each; a term's
     * cosine and sine are then the product of its four as complex numbers.
     * Index k holds the multiple k - 4: the tables use -3 to 4. */
    tks_multiples(tks_rad(D), cD, sD);
    tks_multiples(tks_rad(M), cM, sM);
    tks_multiples(tks_rad(Mp), cP, sP);
    tks_multiples(tks_rad(F), cF, sF);
    for (i = 0; i < 60; i++) {
        const int32_t *r = tks_moon_47a[i];
        double ca, sa;
        double e = r[1] == 0 ? 1.0 : (r[1] == 1 || r[1] == -1) ? E : E * E;
        tks_term(r, cD, sD, cM, sM, cP, sP, cF, sF, &ca, &sa);
        sl += r[4] * sa * e;
        sr += r[5] * ca * e;
    }
    for (i = 0; i < 60; i++) {
        const int32_t *r = tks_moon_47b[i];
        double ca, sa;
        double e = r[1] == 0 ? 1.0 : (r[1] == 1 || r[1] == -1) ? E : E * E;
        tks_term(r, cD, sD, cM, sM, cP, sP, cF, sF, &ca, &sa);
        sb += r[4] * sa * e;
    }
    sl += 3958.0 * sin(A1) + 1962.0 * sin(Lr - Fr) + 318.0 * sin(A2);
    sb += -2235.0 * sin(Lr) + 382.0 * sin(A3) + 175.0 * sin(A1 - Fr) + 175.0 * sin(A1 + Fr)
        + 127.0 * sin(Lr - Mpr) - 115.0 * sin(Lr + Mpr);

    m->lon_geo = tks_deg_norm(Lp + sl / 1e6);
    m->lat = sb / 1e6;
    m->distance = 385000.56 + sr / 1e3;
    m->parallax = tks_deg(asin(TKS_EARTH_A_KM / m->distance));

    tks_nutation(T, &dpsi, &deps);
    m->lon = tks_deg_norm(m->lon_geo + dpsi / 3600.0);
    eps = tks_rad(tks_obliquity_mean(T) + deps / 3600.0);
    m->dpsi = dpsi;
    m->eps_true = tks_deg(eps);
    lam = tks_rad(m->lon);
    bet = tks_rad(m->lat);
    m->ra  = tks_deg_norm(tks_deg(atan2(sin(lam) * cos(eps) - tan(bet) * sin(eps), cos(lam))));
    m->dec = tks_deg(asin(sin(bet) * cos(eps) + cos(bet) * sin(eps) * sin(lam)));
}

/* An observer's parallax constants, rho sin phi' and rho cos phi', from the
 * geographic latitude and the height in metres (11.1 to 11.3). */
static void
tks_parallax_constants(double lat, double height, double *rs, double *rc)
{
    double boa = 1.0 - TKS_EARTH_F;
    double phi = tks_rad(lat);
    double u = atan(boa * tan(phi));
    double hoa = height / (TKS_EARTH_A_KM * 1000.0);
    *rs = boa * sin(u) + hoa * sin(phi);
    *rc = cos(u) + hoa * cos(phi);
}

/* The topocentric hour angle and declination (degrees) of a body at a
 * geocentric hour angle H and declination dec with horizontal parallax pi,
 * seen from rho sin phi', rho cos phi' (chapter 40, the rigorous method). */
static void
tks_topocentric(double H, double dec, double pi, double rs, double rc, double *Ht, double *dect)
{
    double sp = sin(tks_rad(pi)), h = tks_rad(H), d = tks_rad(dec);
    double A = cos(d) * sin(h);
    double B = cos(d) * cos(h) - rc * sp;
    double C = sin(d) - rs * sp;
    double q = sqrt(A * A + B * B + C * C);
    *Ht = tks_deg(atan2(A, B));
    *dect = tks_deg(asin(C / q));
}

/* Altitude and azimuth (from the north through the east) from an hour angle
 * and a declination at a latitude, degrees. */
static void
tks_altaz_hd(double lat, double H, double dec, double *alt, double *az)
{
    double phi = tks_rad(lat), d = tks_rad(dec), h = tks_rad(H);
    *alt = tks_deg(asin(sin(phi) * sin(d) + cos(phi) * cos(d) * cos(h)));
    *az  = tks_deg_norm(tks_deg(atan2(sin(h), cos(h) * sin(phi) - tan(d) * cos(phi))) + 180.0);
}

/* The moon seen from a place at an instant. */
typedef struct tks_moonview {
    tks_moonplace m;
    double H;                   /* geocentric local hour angle, -180 to 180 */
    double alt_geo, az_geo;     /* as from the earth's centre, measured on the place's horizon */
    double Ht, dect;            /* topocentric hour angle and declination */
    double alt, app_alt, az;    /* topocentric altitude, with refraction, azimuth */
} tks_moonview;

/* The moon whose place is in v->m, seen from a place when the apparent
 * sidereal time at Greenwich is theta. */
static void
tks_moon_seen(const tks_place *p, double theta, tks_moonview *v)
{
    double h, rs, rc;
    h = tks_deg_norm(theta + p->lon - v->m.ra);
    v->H = h > 180.0 ? h - 360.0 : h;
    tks_altaz_hd(p->lat, v->H, v->m.dec, &v->alt_geo, &v->az_geo);
    tks_parallax_constants(p->lat, p->elev, &rs, &rc);
    tks_topocentric(v->H, v->m.dec, v->m.parallax, rs, rc, &v->Ht, &v->dect);
    tks_altaz_hd(p->lat, v->Ht, v->dect, &v->alt, &v->az);
    v->app_alt = v->alt + tks_refraction(v->alt) / 60.0;
}

static void
tks_moon_view(pTHX_ const tks_place *p, const time_keeper_instant *t, tks_moonview *v)
{
    double jd = tks_jd_ut(t);
    double jde = tks_jde(aTHX_ t);
    tks_moon_place(jde, &v->m);
    tks_moon_seen(p, tks_sidereal_apparent(jd, jde), v);
}

#endif
