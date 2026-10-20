#ifndef TKS_CONFIG_H
#define TKS_CONFIG_H

/* The planets' configurations with the sun, and the closest approach of any
 * two bodies. Every search runs in JDE (TT) over the apparent geocentric
 * longitude of the planet less the sun's (the VSOP87 sun, tks_sun_precise):
 * the nutation, common to both, cancels. A step of a fortieth or a
 * seventy-second of the synodic period brackets every event, and the
 * Illinois method or a golden section refines it. */

/* Mean synodic periods, days; the earth's slot is unused. */
static const double tks_synodic[TKS_BODIES] = {
    115.88, 583.92, 365.25, 779.94, 398.88, 378.09, 369.66, 367.49, 366.73,
};

#define TKS_C_CONJUNCTION     0
#define TKS_C_INFERIOR        1
#define TKS_C_SUPERIOR        2
#define TKS_C_OPPOSITION      3
#define TKS_C_ELONGATION_EAST 4
#define TKS_C_ELONGATION_WEST 5
#define TKS_C_STATION_RETRO   6
#define TKS_C_STATION_DIRECT  7
#define TKS_C_COUNT           8

/* A found event must be past the instant it was sought from by a margin, or
 * the event at the instant itself, sought again from its own value, is found
 * again. A conjunction or an opposition is a sharp root, and the margin is a
 * second (the rounding). A greatest elongation or a station is an extremum,
 * flat: near it the elongation moves 1e-10 degree a second, the size of the
 * arithmetic's own noise, so its moment is held to about a second and two
 * searches put it seconds apart. One within a minute of the instant is the
 * instant's own. */
#define TKS_ONE_SECOND (1.0 / 86400.0)
#define TKS_ONE_MINUTE (60.0 / 86400.0)

static const char *const tks_config_name[TKS_C_COUNT] = {
    "conjunction", "inferior_conjunction", "superior_conjunction", "opposition",
    "greatest_elongation_east", "greatest_elongation_west", "station_retrograde", "station_direct",
};

static double
tks_wrap180(double d)
{
    d = fmod(d, 360.0);
    if (d > 180.0) d -= 360.0;
    if (d <= -180.0) d += 360.0;
    return d;
}

/* The planet's apparent longitude less the sun's, -180 to 180, at a JDE; and
 * whether the planet is nearer than the sun (for the inner planets, an
 * inferior conjunction). */
static double
tks_dlon(int planet, double jde, int *nearer)
{
    tks_planetpos pp;
    tks_sunpos s;
    tks_planet_compute(planet, jde, &pp, 0);
    tks_sun_precise(jde, &s);
    if (nearer)
        *nearer = pp.delta < s.R;
    return tks_wrap180(pp.lon - s.lon);
}

/* The angle between the planet and the sun, degrees, from their apparent
 * ecliptic places. */
static double
tks_elongation_at(int planet, double jde, double *dl)
{
    tks_planetpos pp;
    tks_sunpos s;
    double c;
    tks_planet_compute(planet, jde, &pp, 0);
    tks_sun_precise(jde, &s);
    *dl = tks_wrap180(pp.lon - s.lon);
    c = cos(tks_rad(pp.lat)) * cos(tks_rad(*dl));
    return tks_deg(acos(c > 1.0 ? 1.0 : c < -1.0 ? -1.0 : c));
}

/* The planet's daily motion in apparent longitude, degrees, by a central
 * difference over six hours. */
static double
tks_lon_rate(int planet, double jde)
{
    tks_planetpos a, b;
    tks_planet_compute(planet, jde - 0.125, &a, 0);
    tks_planet_compute(planet, jde + 0.125, &b, 0);
    return tks_wrap180(b.lon - a.lon) / 0.25;
}

/* A root of one of the two functions below between lo and hi (values flo,
 * fhi of opposite signs), by the Illinois method, to 1e-6 day. */
static double
tks_config_value(int kind, int planet, double jde, double target)
{
    if (kind == 0)
        return tks_wrap180(tks_dlon(planet, jde, NULL) - target);
    return tks_lon_rate(planet, jde);
}

static double
tks_config_root(int kind, int planet, double target, double lo, double hi, double flo, double fhi)
{
    int side = 0, i;
    double t = lo;
    for (i = 0; i < 100 && hi - lo > 1e-6; i++) {
        double f;
        t = (lo * fhi - hi * flo) / (fhi - flo);
        if (t <= lo || t >= hi)
            t = 0.5 * (lo + hi);
        f = tks_config_value(kind, planet, t, target);
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

/* The maximum of the elongation between a and c (a < c), by golden section to
 * 1e-7 day: a flat maximum, sought from two brackets, must come out the same
 * second, or the search from one finds the other (1e-5 day did, 2 s apart). */
static double
tks_elongation_max(int planet, double a, double c)
{
    const double g = 0.6180339887498949;
    double b = c - g * (c - a), d = a + g * (c - a), dl;
    double fb = tks_elongation_at(planet, b, &dl), fd = tks_elongation_at(planet, d, &dl);
    while (c - a > 1e-7) {
        if (fb > fd) { c = d; d = b; fd = fb; b = c - g * (c - a); fb = tks_elongation_at(planet, b, &dl); }
        else         { a = b; b = d; fb = fd; d = a + g * (c - a); fd = tks_elongation_at(planet, d, &dl); }
    }
    return 0.5 * (a + c);
}

/* The next (or previous) configuration of a kind after (before) a JDE, within
 * three synodic periods; 1 and the JDE, or 0. */
static int
tks_config_find(int planet, int kind, double jde0, int backwards, double *out)
{
    double S = tks_synodic[planet], dir = backwards ? -1.0 : 1.0, limit = 3.0 * S;
    double h, t, prev_t, prev_f, f, target = kind == TKS_C_OPPOSITION ? 180.0 : 0.0;
    int i, n;

    if (kind <= TKS_C_OPPOSITION) {
        h = S / 40.0;
        prev_t = jde0;
        prev_f = tks_config_value(0, planet, prev_t, target);
        for (n = (int)(limit / h), i = 0; i < n; i++) {
            t = prev_t + dir * h;
            f = tks_config_value(0, planet, t, target);
            if ((f < 0.0) != (prev_f < 0.0) && fabs(f) < 90.0 && fabs(prev_f) < 90.0) {
                double lo = backwards ? t : prev_t, hi = backwards ? prev_t : t;
                double flo = backwards ? f : prev_f, fhi = backwards ? prev_f : f;
                double r = tks_config_root(0, planet, target, lo, hi, flo, fhi);
                int nearer;
                tks_dlon(planet, r, &nearer);
                if ((!backwards && r > jde0 + TKS_ONE_SECOND) || (backwards && r < jde0 - TKS_ONE_SECOND)) {
                    if (kind == TKS_C_CONJUNCTION || kind == TKS_C_OPPOSITION
                        || (kind == TKS_C_INFERIOR && nearer) || (kind == TKS_C_SUPERIOR && !nearer)) {
                        *out = r;
                        return 1;
                    }
                }
            }
            prev_t = t;
            prev_f = f;
        }
        return 0;
    }
    if (kind == TKS_C_STATION_RETRO || kind == TKS_C_STATION_DIRECT) {
        h = S / 72.0;
        prev_t = jde0;
        prev_f = tks_lon_rate(planet, prev_t);
        for (n = (int)(limit / h), i = 0; i < n; i++) {
            t = prev_t + dir * h;
            f = tks_lon_rate(planet, t);
            if ((f < 0.0) != (prev_f < 0.0)) {
                double lo = backwards ? t : prev_t, hi = backwards ? prev_t : t;
                double flo = backwards ? f : prev_f, fhi = backwards ? prev_f : f;
                /* retrograde: the motion goes from direct to retrograde in time */
                int retro = flo > 0.0;
                if (retro == (kind == TKS_C_STATION_RETRO)) {
                    double r = tks_config_root(1, planet, 0.0, lo, hi, flo, fhi);
                    if ((!backwards && r > jde0 + TKS_ONE_MINUTE) || (backwards && r < jde0 - TKS_ONE_MINUTE)) {
                        *out = r;
                        return 1;
                    }
                }
            }
            prev_t = t;
            prev_f = f;
        }
        return 0;
    }
    /* greatest elongations: a maximum of the elongation on the right side */
    {
        double ta, tb, tc, fa, fb, fc, dl;
        int east = kind == TKS_C_ELONGATION_EAST;
        h = S / 72.0;
        ta = jde0 - dir * h;
        tb = jde0;
        fa = tks_elongation_at(planet, ta, &dl);
        fb = tks_elongation_at(planet, tb, &dl);
        for (n = (int)(limit / h), i = 0; i < n; i++) {
            tc = tb + dir * h;
            fc = tks_elongation_at(planet, tc, &dl);
            if (fb >= fa && fb >= fc && (dl > 0.0) == east) {
                double lo = backwards ? tc : ta, hi = backwards ? ta : tc;
                double r = tks_elongation_max(planet, lo, hi);
                if ((!backwards && r > jde0 + TKS_ONE_MINUTE) || (backwards && r < jde0 - TKS_ONE_MINUTE)) {
                    *out = r;
                    return 1;
                }
            }
            ta = tb; fa = fb;
            tb = tc; fb = fc;
        }
        return 0;
    }
}

/* A JDE to the second of UT nearest it, Delta T read at the instant it
 * names (twice, so the instant is the right one). */
static int64_t
tks_jde_to_sec(pTHX_ double jde)
{
    time_keeper_instant t;
    double jd = jde;
    int i;
    for (i = 0; i < 2; i++) {
        tks_instant_from_jd(jd, &t);
        jd = jde - tks_delta_t(aTHX_ &t) / 86400.0;
    }
    return tks_round_jd(jd);
}

/* ---- any two bodies ---------------------------------------------------------- */

#define TKS_SUN_ID  (-1)
#define TKS_MOON_ID (-2)

/* A body by name: sun, moon, or a planet (not the earth). */
static int
tks_body_arg(pTHX_ SV *sv, const char *what)
{
    STRLEN len;
    const char *s;
    if (sv)
        SvGETMAGIC(sv);
    if (!sv || !SvOK(sv))
        croak("%s needs two bodies: sun, moon, or a planet", what);
    s = SvPV_nomg(sv, len);
    if (len == 3 && memEQ(s, "sun", 3)) return TKS_SUN_ID;
    if (len == 4 && memEQ(s, "moon", 4)) return TKS_MOON_ID;
    return tks_planet_arg(aTHX_ sv, 0, what);
}

/* A body's apparent right ascension and declination at a JD (UT) and its
 * JDE; the moon topocentric when a place is given (its parallax is up to a
 * degree), the others geocentric (the sun's is 9 arcseconds, a planet's
 * under 35). */
static void
tks_body_radec(int body, double jd, double jde, const tks_place *p, double *ra, double *dec)
{
    if (body == TKS_SUN_ID) {
        tks_sunpos s;
        tks_sun_precise(jde, &s);
        *ra = s.ra;
        *dec = s.dec;
    }
    else if (body == TKS_MOON_ID) {
        tks_moonview v;
        double theta;
        tks_moon_place(jde, &v.m);
        if (!p) {
            *ra = v.m.ra;
            *dec = v.m.dec;
            return;
        }
        theta = tks_sidereal_apparent(jd, jde);
        tks_moon_seen(p, theta, &v);
        *ra = tks_deg_norm(theta + p->lon - v.Ht);
        *dec = v.dect;
    }
    else {
        tks_planetpos pp;
        tks_planet_compute(body, jde, &pp, 0);
        *ra = pp.ra;
        *dec = pp.dec;
    }
}

/* The angle between two directions, degrees: by the haversine, which holds
 * its digits when they are close. */
static double
tks_separation(double ra1, double dec1, double ra2, double dec2)
{
    double d1 = tks_rad(dec1), d2 = tks_rad(dec2), da = tks_rad(ra2 - ra1);
    double s1 = sin((d2 - d1) / 2.0), s2 = sin(da / 2.0);
    double h = s1 * s1 + cos(d1) * cos(d2) * s2 * s2;
    return tks_deg(2.0 * asin(sqrt(h > 1.0 ? 1.0 : h)));
}

static double
tks_pair_separation(pTHX_ int a, int b, double jd, const tks_place *p)
{
    time_keeper_instant t;
    double jde, r1, d1, r2, d2;
    tks_instant_from_jd(jd, &t);
    jde = jd + tks_delta_t(aTHX_ &t) / 86400.0;
    tks_body_radec(a, jd, jde, p, &r1, &d1);
    tks_body_radec(b, jd, jde, p, &r2, &d2);
    return tks_separation(r1, d1, r2, d2);
}

/* Every local minimum of the separation of two bodies from jd0 to jd1 (UT),
 * sampled every six hours with the moon and every day without, each
 * refined by golden section to 1e-6 day: the JDs and separations, the count
 * (at most max). */
static int
tks_closest(pTHX_ int a, int b, double jd0, double jd1, const tks_place *p, double *when, double *sep, int max)
{
    const double g = 0.6180339887498949;
    double h = (a == TKS_MOON_ID || b == TKS_MOON_ID) ? 0.25 : 1.0;
    double ta = jd0 - h, tb = jd0, tc, fa, fb, fc;
    int n = 0;
    fa = tks_pair_separation(aTHX_ a, b, ta, p);
    fb = tks_pair_separation(aTHX_ a, b, tb, p);
    while (tb <= jd1 + h && n < max) {
        tc = tb + h;
        fc = tks_pair_separation(aTHX_ a, b, tc, p);
        if (fb <= fa && fb < fc) {
            double lo = ta, hi = tc, x = hi - g * (hi - lo), y = lo + g * (hi - lo);
            double fx = tks_pair_separation(aTHX_ a, b, x, p), fy = tks_pair_separation(aTHX_ a, b, y, p);
            while (hi - lo > 1e-6) {
                if (fx < fy) { hi = y; y = x; fy = fx; x = hi - g * (hi - lo); fx = tks_pair_separation(aTHX_ a, b, x, p); }
                else         { lo = x; x = y; fx = fy; y = lo + g * (hi - lo); fy = tks_pair_separation(aTHX_ a, b, y, p); }
            }
            x = 0.5 * (lo + hi);
            if (x >= jd0 && x <= jd1) {
                when[n] = x;
                sep[n] = tks_pair_separation(aTHX_ a, b, x, p);
                n++;
            }
        }
        ta = tb; fa = fb;
        tb = tc; fb = fc;
    }
    return n;
}

#endif
