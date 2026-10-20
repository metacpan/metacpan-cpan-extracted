#ifndef TKS_PLANET_H
#define TKS_PLANET_H

/* The planets' apparent places: heliocentric places of date from VSOP87D
 * (Pluto from chapter 37, precessed from J2000 by 21.5 to 21.7), the
 * light-time iterated with the earth at the instant, the sun's light
 * deflection, the annual aberration from the earth's velocity, the FK5
 * correction (32.3), the nutation in longitude and the true obliquity; then
 * the phase, the illumination, the apparent diameter and the magnitude by
 * Mallama and Hilton (2018). */

#include "tks_pluto37.h"

#define TKS_LIGHT_DAYS_PER_AU 0.0057755183          /* AU / c, days */
#define TKS_C_AU_PER_DAY      173.14463267424034    /* c in AU a day */
#define TKS_SUN_2MU_C2_AU     1.97412574336e-8      /* 2 G M_sun / c^2, in AU */
#define TKS_AU_KM_EXACT       149597870.7
#define TKS_OBL_J2000         23.4392911            /* the mean obliquity at J2000.0, degrees */
#define TKS_GAUSS_K2          2.9591220828559115e-4 /* k^2, the sun's GM in AU^3 a day^2 */

/* Equatorial radii, km (IAU WGCCRE 2015). */
static const double tks_planet_radius_km[TKS_BODIES] = {
    2440.53, 6051.8, 6378.137, 3396.19, 71492.0, 60268.0, 25559.0, 24764.0, 1188.3,
};

/* ---- Pluto and precession ---------------------------------------------------- */

/* Pluto's heliocentric ecliptic longitude and latitude (degrees) and radius
 * (AU), J2000.0, by table 37.A, at a JDE. */
static void
tks_pluto_j2000(double jde, double *l, double *b, double *r)
{
    double T = tks_T(jde);
    double J = 34.35 + 3034.9057 * T, S = 50.08 + 1222.1138 * T, P = 238.96 + 144.96 * T;
    double sl = 0.0, sb = 0.0, sr = 0.0;
    int i;
    for (i = 0; i < 43; i++) {
        const double *t = tks_pluto_37a[i];
        double a = tks_rad(tks_deg_norm(t[0] * J + t[1] * S + t[2] * P));
        double sa = sin(a), ca = cos(a);
        sl += t[3] * sa + t[4] * ca;
        sb += t[5] * sa + t[6] * ca;
        sr += t[7] * sa + t[8] * ca;
    }
    *l = tks_deg_norm(sl + 238.958116 + 144.96 * T);
    *b = sb - 3.908239;
    *r = sr + 40.7241346;
}

/* Ecliptic coordinates (degrees) from the ecliptic and equinox of J2000.0 to
 * those of a date T Julian centuries later (21.5 to 21.7, from J2000.0). */
static void
tks_precess_ecliptic(double T, double lam0, double bet0, double *lam, double *bet)
{
    double eta = tks_rad((47.0029 * T - 0.03302 * T * T + 0.000060 * T * T * T) / 3600.0);
    double Pi  = 174.876384 + (-869.8089 * T + 0.03536 * T * T) / 3600.0;
    double p   = (5029.0966 * T + 1.11113 * T * T - 0.000006 * T * T * T) / 3600.0;
    double b0 = tks_rad(bet0), d = tks_rad(Pi - lam0);
    double A = cos(eta) * cos(b0) * sin(d) - sin(eta) * sin(b0);
    double B = cos(b0) * cos(d);
    double C = cos(eta) * sin(b0) + sin(eta) * cos(b0) * sin(d);
    *lam = tks_deg_norm(p + Pi - tks_deg(atan2(A, B)));
    *bet = tks_deg(asin(C > 1.0 ? 1.0 : C < -1.0 ? -1.0 : C));
}

/* A body's heliocentric L, B (radians) and R (AU), ecliptic and equinox of
 * date. */
static void
tks_helio(int body, double jde, double *L, double *B, double *R)
{
    if (body == TKS_PLUTO) {
        double l0, b0, lam, bet;
        tks_pluto_j2000(jde, &l0, &b0, R);
        tks_precess_ecliptic(tks_T(jde), l0, b0, &lam, &bet);
        *L = tks_rad(lam);
        *B = tks_rad(bet);
    }
    else
        tks_vsop_lbr(body, jde, L, B, R);
}

static void
tks_rect(double L, double B, double R, double *x)
{
    x[0] = R * cos(B) * cos(L);
    x[1] = R * cos(B) * sin(L);
    x[2] = R * sin(B);
}

static double tks_dot3(const double *a, const double *b) { return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]; }
static double tks_len3(const double *a) { return sqrt(tks_dot3(a, a)); }

/* A unit vector in the ecliptic of date from a J2000.0 equatorial pole. */
static void
tks_pole_of_date(double T, double ra, double dec, double *u)
{
    double e = tks_rad(TKS_OBL_J2000), a = tks_rad(ra), d = tks_rad(dec);
    double lam0 = tks_deg(atan2(sin(a) * cos(e) + tan(d) * sin(e), cos(a)));
    double bet0 = tks_deg(asin(sin(d) * cos(e) - cos(d) * sin(e) * sin(a)));
    double lam, bet;
    tks_precess_ecliptic(T, lam0, bet0, &lam, &bet);
    tks_rect(tks_rad(lam), tks_rad(bet), 1.0, u);
}

/* The planetocentric latitude (degrees) of the end of v seen from the
 * planet, with a pole u: the angle from the pole less 90, of the direction
 * from the planet to the sun or the earth, as Skyfield takes it. */
static double
tks_sub_latitude(const double *u, const double *v)
{
    double c = tks_dot3(u, v) / tks_len3(v);
    return tks_deg(acos(c > 1.0 ? 1.0 : c < -1.0 ? -1.0 : c)) - 90.0;
}

/* ---- magnitudes, Mallama and Hilton (2018), as in Skyfield's magnitudelib -- */

/* The magnitude, or NAN where the formulae give none (Saturn beyond 6.5
 * degrees of phase, Neptune beyond 1.9 before 2000, Pluto). */
static double
tks_magnitude(int body, double r, double delta, double i, double sat_sun, double sat_obs, double year)
{
    double d5 = 5.0 * log10(r * delta), m;
    switch (body) {
    case TKS_MERCURY:
        return -0.613 + d5 + i * (6.3280e-02 + i * (-1.6336e-03 + i * (3.3644e-05
               + i * (-3.4265e-07 + i * (1.6893e-09 - i * 3.0334e-12)))));
    case TKS_VENUS:
        if (i < 163.7)
            return -4.384 + d5 + i * (-1.044e-03 + i * (3.687e-04 + i * (-2.814e-06 + i * 8.938e-09)));
        return -4.384 + d5 + (236.05828 + 4.384) + i * (-2.81914 + i * 8.39034e-03);
    case TKS_MARS:
        if (i <= 50.0)
            return -1.601 + d5 + i * (2.267e-02 - 1.302e-04 * i);
        return -0.367 + d5 + i * (-0.02573 + 0.0003445 * i);
    case TKS_JUPITER:
        if (i <= 12.0)
            return -9.395 + d5 + (6.16e-04 * i - 3.7e-04) * i;
        {
            double x = i / 180.0;
            return -9.428 + d5 - 2.5 * log10(((((-1.876 * x + 2.809) * x - 0.062) * x - 0.363) * x - 1.507) * x + 1.0);
        }
    case TKS_SATURN:
        {
            double prod = sat_sun * sat_obs, lat = prod >= 0.0 ? sqrt(prod) : 0.0;
            if (i <= 6.5 && lat <= 27.0)
                return -8.914 - 1.825 * sin(tks_rad(lat)) + 0.026 * i
                       - 0.378 * sin(tks_rad(lat)) * exp(-2.25 * i) + d5;
            return NAN;
        }
    case TKS_URANUS:
        m = -7.110 + d5 - 0.00084 * (fabs(sat_sun) + fabs(sat_obs)) / 2.0;
        if (i > 3.1)
            m += (1.045e-4 * i + 6.587e-3) * i;
        return m;
    case TKS_NEPTUNE:
        m = -6.89 - 0.0054 * (year - 1980.0);
        if (m < -7.00) m = -7.00;
        if (m > -6.89) m = -6.89;
        m += d5;
        if (i > 1.9)
            return year >= 2000.0 ? m + 7.944e-3 * i + 9.617e-5 * i * i : NAN;
        return m;
    }
    return NAN;
}

/* ---- the apparent place --------------------------------------------------------- */

typedef struct tks_planetpos {
    double lon, lat;        /* apparent geocentric ecliptic of date, degrees */
    double ra, dec;         /* apparent, degrees */
    double delta;           /* AU, the planet at t - tau from the earth at t */
    double tau;             /* the light-time, days */
    double r, R;            /* the planet's and the earth's distances from the sun, AU */
    double elongation;      /* from the sun, degrees, 0 to 180 */
    double phase_angle;     /* sun-planet-earth, degrees */
    double illumination;    /* the fraction lit */
    double diameter;        /* arcseconds, equatorial */
    double magnitude;       /* NAN where there is none */
    double sun_lat, obs_lat;/* Saturn's and Uranus's planetocentric latitudes of the sun and the earth */
} tks_planetpos;

/* The apparent place; with full, the phase, illumination, diameter and
 * magnitude too (the event engine asks for the place alone). */
static void
tks_planet_compute(int body, double jde, tks_planetpos *pp, int full)
{
    double e[3], ed[3], E[3], Ev[3], P[3], G[3], u[3], q[3], ehat[3];
    double L, B, R, tau = 0.0, delta = 0.0, T = tks_T(jde);
    double lam, bet, dpsi, deps, eps, g1, g2, pq, ep, n;
    int i, k;

    tks_vsop_lbr_dot(TKS_EARTH, jde, e, ed);
    tks_rect(e[0], e[1], e[2], E);
    /* the velocity of the earth, AU a day, from the rates of L, B and R */
    Ev[0] = ed[2] * cos(e[1]) * cos(e[0]) - e[2] * sin(e[1]) * ed[1] * cos(e[0]) - e[2] * cos(e[1]) * sin(e[0]) * ed[0];
    Ev[1] = ed[2] * cos(e[1]) * sin(e[0]) - e[2] * sin(e[1]) * ed[1] * sin(e[0]) + e[2] * cos(e[1]) * cos(e[0]) * ed[0];
    Ev[2] = ed[2] * sin(e[1]) + e[2] * cos(e[1]) * ed[1];

    if (body == TKS_PLUTO) {
        for (i = 0; i < 10; i++) {
            double nt;
            tks_helio(body, jde - tau, &L, &B, &R);
            tks_rect(L, B, R, P);
            for (k = 0; k < 3; k++)
                G[k] = P[k] - E[k];
            delta = tks_len3(G);
            nt = delta * TKS_LIGHT_DAYS_PER_AU;
            if (fabs(nt - tau) < 1e-9) {
                tau = nt;
                break;
            }
            tau = nt;
        }
    }
    else {
        /* the planet and its velocity at the instant, once; then the
         * light-time on the two-body path back from there, P0 - V tau +
         * A tau^2 / 2 with A the sun's pull. Over the light-time (under a
         * fifth of a day) it agrees with iterating the whole series to
         * 1e-5 arcseconds and 4e-10 AU, 1900 to 2100 */
        double p0[3], pd[3], P0[3], V[3], A[3], r3;
        tks_vsop_lbr_dot(body, jde, p0, pd);
        tks_rect(p0[0], p0[1], p0[2], P0);
        V[0] = pd[2] * cos(p0[1]) * cos(p0[0]) - p0[2] * sin(p0[1]) * pd[1] * cos(p0[0]) - p0[2] * cos(p0[1]) * sin(p0[0]) * pd[0];
        V[1] = pd[2] * cos(p0[1]) * sin(p0[0]) - p0[2] * sin(p0[1]) * pd[1] * sin(p0[0]) + p0[2] * cos(p0[1]) * cos(p0[0]) * pd[0];
        V[2] = pd[2] * sin(p0[1]) + p0[2] * cos(p0[1]) * pd[1];
        r3 = p0[2] * p0[2] * p0[2];
        for (k = 0; k < 3; k++)
            A[k] = -TKS_GAUSS_K2 * P0[k] / r3;
        for (i = 0; i < 10; i++) {
            double nt;
            for (k = 0; k < 3; k++) {
                P[k] = P0[k] - V[k] * tau + 0.5 * A[k] * tau * tau;
                G[k] = P[k] - E[k];
            }
            delta = tks_len3(G);
            nt = delta * TKS_LIGHT_DAYS_PER_AU;
            if (fabs(nt - tau) < 1e-12) {
                tau = nt;
                break;
            }
            tau = nt;
        }
        for (k = 0; k < 3; k++) {
            P[k] = P0[k] - V[k] * tau + 0.5 * A[k] * tau * tau;
            G[k] = P[k] - E[k];
        }
        delta = tks_len3(G);
        R = tks_len3(P);
    }
    pp->delta = delta;
    pp->tau = tau;
    pp->r = R;
    pp->R = e[2];

    /* light deflection by the sun (the Explanatory Supplement's 3.32) */
    for (k = 0; k < 3; k++) {
        u[k] = G[k] / delta;
        q[k] = P[k] / R;
        ehat[k] = E[k] / e[2];
    }
    g1 = TKS_SUN_2MU_C2_AU / e[2];
    g2 = 1.0 + tks_dot3(q, ehat);
    pq = tks_dot3(u, q);
    ep = tks_dot3(ehat, u);
    for (k = 0; k < 3; k++)
        u[k] += (g1 / g2) * (pq * ehat[k] - ep * q[k]);
    /* aberration: the earth's velocity over c */
    for (k = 0; k < 3; k++)
        u[k] += Ev[k] / TKS_C_AU_PER_DAY;
    n = tks_len3(u);
    for (k = 0; k < 3; k++)
        u[k] /= n;

    lam = tks_deg_norm(tks_deg(atan2(u[1], u[0])));
    bet = tks_deg(asin(u[2]));
    if (body != TKS_PLUTO) {
        /* VSOP87's dynamical frame to FK5 (32.3); Pluto's chapter 37 is FK5 already */
        double lp = tks_rad(lam - 1.397 * T - 0.00031 * T * T);
        double tb = tan(tks_rad(bet));
        lam += (-0.09033 + 0.03916 * (cos(lp) + sin(lp)) * tb) / 3600.0;
        bet += (0.03916 * (cos(lp) - sin(lp))) / 3600.0;
    }
    tks_nutation(T, &dpsi, &deps);
    lam = tks_deg_norm(lam + dpsi / 3600.0);
    eps = tks_rad(tks_obliquity_mean(T) + deps / 3600.0);
    pp->lon = lam;
    pp->lat = bet;
    {
        double lr = tks_rad(lam), br = tks_rad(bet);
        pp->ra  = tks_deg_norm(tks_deg(atan2(sin(lr) * cos(eps) - tan(br) * sin(eps), cos(lr))));
        pp->dec = tks_deg(asin(sin(br) * cos(eps) + cos(br) * sin(eps) * sin(lr)));
    }
    if (!full)
        return;

    {
        double r = R, D = delta, Re = e[2], c;
        c = (Re * Re + D * D - r * r) / (2.0 * Re * D);
        pp->elongation = tks_deg(acos(c > 1.0 ? 1.0 : c < -1.0 ? -1.0 : c));
        c = (r * r + D * D - Re * Re) / (2.0 * r * D);
        pp->phase_angle = tks_deg(acos(c > 1.0 ? 1.0 : c < -1.0 ? -1.0 : c));
        pp->illumination = (1.0 + cos(tks_rad(pp->phase_angle))) / 2.0;
    }
    pp->diameter = 2.0 * tks_deg(atan(tks_planet_radius_km[body] / (delta * TKS_AU_KM_EXACT))) * 3600.0;

    {
        double sun_lat = 0.0, obs_lat = 0.0, year = 2000.0 + (jde - TKS_J2000) / 365.25;
        if (body == TKS_SATURN || body == TKS_URANUS) {
            double pole[3];
            if (body == TKS_SATURN)
                tks_pole_of_date(T, 40.589, 83.537, pole);
            else
                tks_pole_of_date(T, 257.311, -15.175, pole);
            sun_lat = tks_sub_latitude(pole, P);
            obs_lat = tks_sub_latitude(pole, G);
        }
        pp->sun_lat = sun_lat;
        pp->obs_lat = obs_lat;
        pp->magnitude = tks_magnitude(body, R, delta, pp->phase_angle, sun_lat, obs_lat, year);
    }
}

static void
tks_planet_at(int body, double jde, tks_planetpos *pp)
{
    tks_planet_compute(body, jde, pp, 1);
}

/* Pluto's chapter 37 holds from 1885 to 2099. */
static void
tks_planet_range(pTHX_ int body, const time_keeper_instant *t, const char *what)
{
    double jd = tks_jd_ut(t);
    if (body == TKS_PLUTO && (jd < 2409542.5 || jd >= 2488069.5))
        croak("%s: Pluto's place is computed from 1885 to 2099 only (Meeus's chapter 37)", what);
}

/* The planet seen from a place: topocentric by chapter 40 with the parallax
 * of 8.794148 arcseconds at 1 AU. */
static void
tks_planet_seen(const tks_place *p, double theta, const tks_planetpos *pp,
                double *alt, double *app_alt, double *az, double *Ht)
{
    double h = tks_deg_norm(theta + p->lon - pp->ra), H = h > 180.0 ? h - 360.0 : h;
    double pi = tks_deg(asin(sin(tks_rad(8.794148 / 3600.0)) / pp->delta));
    double rs, rc, dect;
    tks_parallax_constants(p->lat, p->elev, &rs, &rc);
    tks_topocentric(H, pp->dec, pi, rs, rc, Ht, &dect);
    tks_altaz_hd(p->lat, *Ht, dect, alt, az);
    *app_alt = *alt + tks_refraction(*alt) / 60.0;
}

/* ---- rise, set and transit ------------------------------------------------- */

/* The planet's topocentric centre's altitude from the body's place at a JD
 * (UT), for the event engine: a point, so its horizon is refraction's 34
 * arcminutes, as the Naval Observatory takes it. */
static double
tks_planet_alt(pTHX_ const tks_body *b, double jd, double *H_out)
{
    time_keeper_instant t;
    tks_planetpos pp;
    double jde, alt, app, az, Ht;
    tks_instant_from_jd(jd, &t);
    jde = jd + tks_delta_t(aTHX_ &t) / 86400.0;
    tks_planet_compute(b->planet, jde, &pp, 0);
    tks_planet_seen(b->p, tks_sidereal_apparent(jd, jde), &pp, &alt, &app, &az, &Ht);
    if (H_out)
        *H_out = Ht;
    return alt;
}

/* A planet as the engine's body, its hour angle's rate from its motion in
 * right ascension over the day after jd: 360.9856 a day less that motion. */
static void
tks_planet_body(pTHX_ const tks_place *p, int planet, double jd, tks_body *b)
{
    time_keeper_instant t;
    tks_planetpos a, c;
    double jde, d;
    memset(b, 0, sizeof *b);
    b->p = p;
    b->moon = 2;
    b->planet = planet;
    tks_instant_from_jd(jd, &t);
    jde = jd + tks_delta_t(aTHX_ &t) / 86400.0;
    tks_planet_compute(planet, jde, &a, 0);
    tks_planet_compute(planet, jde + 1.0, &c, 0);
    d = c.ra - a.ra;
    if (d > 180.0) d -= 360.0;
    if (d < -180.0) d += 360.0;
    b->rate = 360.98564736629 - d;
}

static double
tks_planet_horizon(const tks_place *p)
{
    double h = p->elev;
    double dip = tks_deg(acos(TKS_EARTH_RADIUS / (TKS_EARTH_RADIUS + h)));
    return -(34.0 / 60.0 + dip + (19.0 / 3600.0) * sqrt(h));
}

#define TKS_P_RISE    0
#define TKS_P_SET     1
#define TKS_P_TRANSIT 2
#define TKS_PLANETDAY_MAGIC 0x54534b59u

static const char *const tks_planet_event_name[3] = { "rise", "set", "transit" };

/* A planet's or a star's day (Time::Keeper::Body::Day): planet is the
 * planet's index or -1, star the star's row or -1. */
typedef struct tks_planetday {
    uint32_t  magic;
    tks_place place;
    int64_t   days, start, end;
    int32_t   planet, star;
    uint8_t   n[3];                 /* how many rises, sets, upper transits (two kept) */
    uint8_t   up_all, down_all;
    int32_t   ev[3][2];             /* seconds after start */
} tks_planetday;

static void
tks_planetday_add(tks_planetday *d, int kind, int64_t sec)
{
    if (sec < d->start || sec >= d->end)
        return;
    if (d->n[kind] < 2)
        d->ev[kind][d->n[kind]] = (int32_t)(sec - d->start);
    if (d->n[kind] < 255)
        d->n[kind]++;
}

/* A body's day: its upper transits, and its crossings of the horizon h0
 * between the walk's extrema. The body's place must be d->place. */
static void
tks_bodyday_fill(pTHX_ tks_planetday *d, const tks_body *b, double h0)
{
    double tt[TKS_MAX_TRANSITS], et[TKS_MAX_TRANSITS], ey[TKS_MAX_TRANSITS];
    int lower[TKS_MAX_TRANSITS];
    int nt, i;
    nt = tks_day_walk(aTHX_ b, d->start, d->end, tt, lower, et, ey);
    for (i = 0; i < nt; i++)
        if (!lower[i])
            tks_planetday_add(d, TKS_P_TRANSIT, tks_round_jd(tt[i]));
    for (i = 0; i + 1 < nt; i++) {
        double c;
        if (tks_crossing(aTHX_ b, et[i], ey[i], et[i + 1], ey[i + 1], h0, &c))
            tks_planetday_add(d, ey[i] < ey[i + 1] ? TKS_P_RISE : TKS_P_SET, tks_round_jd(c));
    }
    if (d->n[TKS_P_RISE] == 0 && d->n[TKS_P_SET] == 0) {
        if (tks_alt_at(aTHX_ b, TKS_JD_EPOCH + (double)d->start / 86400.0, NULL) > h0)
            d->up_all = 1;
        else
            d->down_all = 1;
    }
}

static void
tks_bodyday_init(tks_planetday *d, const tks_place *p, int64_t days, int64_t start, int64_t end)
{
    memset(d, 0, sizeof *d);
    d->magic = TKS_PLANETDAY_MAGIC;
    d->place = *p;
    d->days = days;
    d->start = start;
    d->end = end;
    d->planet = -1;
    d->star = -1;
}

static void
tks_planetday_compute(pTHX_ const tks_place *p, int planet, int64_t days, int64_t start, int64_t end, tks_planetday *d)
{
    tks_body b;
    tks_bodyday_init(d, p, days, start, end);
    d->planet = planet;
    tks_planet_body(aTHX_ &d->place, planet, TKS_JD_EPOCH + (double)start / 86400.0, &b);
    tks_bodyday_fill(aTHX_ d, &b, tks_planet_horizon(&d->place));
}

static const tks_planetday *
tks_planetday_of(pTHX_ SV *sv, const char *what)
{
    SV *inner;
    const tks_planetday *d;
    if (!sv || !SvROK(sv) || !sv_derived_from(sv, "Time::Keeper::Body::Day"))
        croak("%s: not a Time::Keeper::Planet::Day or Time::Keeper::Star::Day", what);
    inner = SvRV(sv);
    if (!SvPOK(inner) || SvCUR(inner) != sizeof(tks_planetday))
        croak("%s: not a Time::Keeper::Planet::Day or Time::Keeper::Star::Day", what);
    d = (const tks_planetday *)SvPVX(inner);
    if (d->magic != TKS_PLANETDAY_MAGIC)
        croak("%s: not a Time::Keeper::Planet::Day or Time::Keeper::Star::Day", what);
    return d;
}

/* The next (or previous) rise or set of a planet from an instant. */
static int
tks_planet_find(pTHX_ const tks_place *p, int planet, int64_t from, int set, int backwards, int64_t *out)
{
    tks_body b;
    tks_planet_body(aTHX_ p, planet, TKS_JD_EPOCH + (double)from / 86400.0, &b);
    return tks_find_crossing_b(aTHX_ &b, from, tks_planet_horizon(p), !set, backwards, out);
}

/* The next (or previous) upper transit of a body from an instant. */
static int64_t
tks_body_transit_find(pTHX_ const tks_body *b, int64_t from, int backwards)
{
    double j0 = TKS_JD_EPOCH + (double)from / 86400.0, tr, whole;
    int64_t out;
    whole = 360.0 / b->rate;
    tr = tks_transit(aTHX_ b, j0, 0);
    out = tks_round_jd(tr);
    if (!backwards && out <= from) out = tks_round_jd(tks_transit(aTHX_ b, tr + whole, 0));
    if (backwards && out >= from)  out = tks_round_jd(tks_transit(aTHX_ b, tr - whole, 0));
    return out;
}

static int64_t
tks_planet_transit_find(pTHX_ const tks_place *p, int planet, int64_t from, int backwards)
{
    tks_body b;
    tks_planet_body(aTHX_ p, planet, TKS_JD_EPOCH + (double)from / 86400.0, &b);
    return tks_body_transit_find(aTHX_ &b, from, backwards);
}

#endif
