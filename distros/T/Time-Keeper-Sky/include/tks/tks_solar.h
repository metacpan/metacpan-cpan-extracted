#ifndef TKS_SOLAR_H
#define TKS_SOLAR_H

/* Solar eclipses. The sun (VSOP87, tks_sun_precise) and the moon (Meeus
 * 47) as vectors in the earth's equatorial radii, in the true equator and
 * equinox of date; the axis of the moon's shadow is the line from the moon
 * away from the sun. In the fundamental plane (through the earth's centre,
 * perpendicular to the axis) the axis is at (x, y), the moon at height z,
 * and the penumbral and umbral cones have radii l1 and l2: the Besselian
 * quantities, computed here directly from the two places at each instant
 * rather than from fitted polynomials. Greatest eclipse is the axis nearest
 * the earth's centre (gamma); where the axis meets the earth (the WGS84
 * ellipsoid) is the central line, and the umbra's radius there, l2 less its
 * height above the plane times tan f2, says total (negative) or annular.
 * Seen from a place, the topocentric sun and moon and their semidiameters
 * give the contacts, the magnitude and the obscuration. The moon's radius is
 * k1 = 0.2724880 for the penumbra and the outer contacts and k2 = 0.2722810
 * for the umbra and the inner, the Five Millennium Canon's (Espenak). */

#define TKS_ER_KM        6378.137
#define TKS_ER_F         (1.0 / 298.257223563)
#define TKS_K1           0.2724880
#define TKS_K2           0.2722810

#define TKS_SE_PARTIAL 0
#define TKS_SE_ANNULAR 1
#define TKS_SE_TOTAL   2
#define TKS_SE_HYBRID  3
static const char *const tks_solar_type_name[4] = { "partial", "annular", "total", "hybrid" };

static const char *const tks_solar_contact_name[4] = { "c1", "c2", "c3", "c4" };

/* The sun's radius in the earth's equatorial radii, from the Canon's
 * semidiameter of 959.63 arcseconds at 1 AU. */
static double
tks_sun_radius_er(void)
{
    return tan(tks_rad(TKS_SUN_SD_1AU / 3600.0)) * (TKS_AU_KM_EXACT / TKS_ER_KM);
}

typedef struct tks_bessel {
    double S[3], M[3];              /* the sun and the moon, equatorial radii, true of date */
    double G[3], i[3], j[3];        /* the axis (from the moon to the sun) and the plane's east and north */
    double x, y, z;                 /* the moon in the fundamental plane, and its height */
    double f1, f2, l1, l2;          /* the cones' half-angles (radians) and radii on the plane */
    double theta;                   /* the apparent sidereal time at Greenwich, degrees */
} tks_bessel;

static void
tks_bessel_at(double jd, double jde, tks_bessel *b)
{
    tks_moonplace mp;
    tks_sunpos s;
    double rs, sm[3], len, a, d, Rs = tks_sun_radius_er();
    int k;
    tks_moon_place(jde, &mp);
    tks_sun_precise(jde, &s);
    rs = s.R * (TKS_AU_KM_EXACT / TKS_ER_KM);
    tks_rect(tks_rad(s.ra), tks_rad(s.dec), rs, b->S);
    tks_rect(tks_rad(mp.ra), tks_rad(mp.dec), mp.distance / TKS_ER_KM, b->M);
    for (k = 0; k < 3; k++)
        sm[k] = b->S[k] - b->M[k];
    len = tks_len3(sm);
    for (k = 0; k < 3; k++)
        b->G[k] = sm[k] / len;
    a = atan2(b->G[1], b->G[0]);
    d = asin(b->G[2]);
    b->i[0] = -sin(a);           b->i[1] = cos(a);            b->i[2] = 0.0;
    b->j[0] = -sin(d) * cos(a);  b->j[1] = -sin(d) * sin(a);  b->j[2] = cos(d);
    b->x = tks_dot3(b->M, b->i);
    b->y = tks_dot3(b->M, b->j);
    b->z = tks_dot3(b->M, b->G);
    b->f1 = asin((Rs + TKS_K1) / len);
    b->f2 = asin((Rs - TKS_K2) / len);
    b->l1 = b->z * tan(b->f1) + TKS_K1 / cos(b->f1);
    b->l2 = b->z * tan(b->f2) - TKS_K2 / cos(b->f2);
    b->theta = tks_sidereal_apparent(jd, jde);
}

/* The JD (UT) of a JDE, Delta T read at the instant it names. */
static double
tks_jde_to_jd(pTHX_ double jde)
{
    time_keeper_instant t;
    double jd = jde;
    int i;
    for (i = 0; i < 2; i++) {
        tks_instant_from_jd(jd, &t);
        jd = jde - tks_delta_t(aTHX_ &t) / 86400.0;
    }
    return jd;
}

static void
tks_bessel_jde(pTHX_ double jde, tks_bessel *b)
{
    tks_bessel_at(tks_jde_to_jd(aTHX_ jde), jde, b);
}

/* Where a line through P along -G (toward the earth) meets the ellipsoid,
 * the sunward meeting: 1 and the point, or 0. */
static int
tks_axis_hit(const double *P, const double *G, double *out)
{
    double q = 1.0 - TKS_ER_F, q2 = q * q;
    double A = G[0] * G[0] + G[1] * G[1] + G[2] * G[2] / q2;
    double B = -2.0 * (P[0] * G[0] + P[1] * G[1] + P[2] * G[2] / q2);
    double C = P[0] * P[0] + P[1] * P[1] + P[2] * P[2] / q2 - 1.0;
    double disc = B * B - 4.0 * A * C, s;
    int k;
    if (disc < 0.0)
        return 0;
    s = (-B - sqrt(disc)) / (2.0 * A);
    for (k = 0; k < 3; k++)
        out[k] = P[k] - s * G[k];
    return 1;
}

/* A point on the ellipsoid (true of date) to geodetic latitude and east
 * longitude, degrees, at sidereal time theta. */
static void
tks_geodetic(const double *P, double theta, double *lat, double *lon)
{
    double q = 1.0 - TKS_ER_F;
    double r = sqrt(P[0] * P[0] + P[1] * P[1]);
    *lat = tks_deg(atan2(P[2], q * q * r));
    *lon = tks_deg_norm(tks_deg(atan2(P[1], P[0])) - theta);
    if (*lon > 180.0)
        *lon -= 360.0;
}

/* An observer at geodetic latitude and east longitude (degrees) and height
 * (metres), as a point in equatorial radii, true of date, at sidereal time
 * theta. */
static void
tks_observer(double lat, double lon, double height, double theta, double *O)
{
    double rs, rc, a = tks_rad(theta + lon);
    tks_parallax_constants(lat, height, &rs, &rc);
    O[0] = rc * cos(a);
    O[1] = rc * sin(a);
    O[2] = rs;
}

/* ---- seen from a place --------------------------------------------------------- */

typedef struct tks_seen {
    double sep, ss, sm1, sm2;       /* the centres' separation and the semidiameters (sun, moon k1, moon k2), degrees */
    double sun_alt, sun_az;         /* the sun's apparent altitude and azimuth there */
} tks_seen;

static void
tks_seen_at(pTHX_ const tks_place *p, double jde, tks_seen *v)
{
    tks_bessel b;
    double O[3], s[3], m[3], ls, lm, c, h, rs = tks_sun_radius_er();
    double jd = tks_jde_to_jd(aTHX_ jde);
    int k;
    tks_bessel_at(jd, jde, &b);
    tks_observer(p->lat, p->lon, p->elev, b.theta, O);
    for (k = 0; k < 3; k++) {
        s[k] = b.S[k] - O[k];
        m[k] = b.M[k] - O[k];
    }
    ls = tks_len3(s);
    lm = tks_len3(m);
    c = tks_dot3(s, m) / (ls * lm);
    v->sep = tks_deg(acos(c > 1.0 ? 1.0 : c < -1.0 ? -1.0 : c));
    v->ss = tks_deg(asin(rs / ls));
    v->sm1 = tks_deg(asin(TKS_K1 / lm));
    v->sm2 = tks_deg(asin(TKS_K2 / lm));
    {
        double ra = tks_deg(atan2(s[1], s[0])), dec = tks_deg(asin(s[2] / ls)), H;
        tks_altaz_theta(b.theta, p->lat, p->lon, ra, dec, &h, &v->sun_az, &H);
        v->sun_alt = h + tks_refraction(h) / 60.0;
    }
}

/* The local function a contact is a root of: which 0 the outer contacts
 * (C1, C4), 1 the inner (C2, C3). */
static double
tks_seen_f(pTHX_ const tks_place *p, double jde, int which)
{
    tks_seen v;
    tks_seen_at(aTHX_ p, jde, &v);
    return which == 0 ? v.sep - (v.ss + v.sm1) : v.sep - fabs(v.ss - v.sm2);
}

static double
tks_seen_root(pTHX_ const tks_place *p, int which, double lo, double hi)
{
    double flo = tks_seen_f(aTHX_ p, lo, which), fhi = tks_seen_f(aTHX_ p, hi, which), t = lo;
    int side = 0, i;
    for (i = 0; i < 100 && hi - lo > 1e-7; i++) {
        double f;
        t = (lo * fhi - hi * flo) / (fhi - flo);
        if (t <= lo || t >= hi)
            t = 0.5 * (lo + hi);
        f = tks_seen_f(aTHX_ p, t, which);
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

/* The area of the sun's disc covered by the moon's, as a fraction: two
 * circles of radii R (the sun) and r at a distance d. */
static double
tks_obscuration(double R, double r, double d)
{
    double a, b, area;
    if (d >= R + r)
        return 0.0;
    if (d <= fabs(R - r))
        return r >= R ? 1.0 : (r * r) / (R * R);
    a = acos((d * d + R * R - r * r) / (2.0 * d * R));
    b = acos((d * d + r * r - R * R) / (2.0 * d * r));
    area = R * R * a + r * r * b - 0.5 * sqrt((-d + r + R) * (d + r - R) * (d - r + R) * (d + r + R));
    return area / (TKS_PI * R * R);
}

#define TKS_LOCAL_MAGIC 0x54534b4cu

typedef struct tks_local {
    uint32_t  magic;
    int32_t   type;                 /* partial, annular or total at the place */
    tks_place place;
    int64_t   maximum, contact[4];
    uint8_t   has[4];
    double    magnitude, obscuration;
    double    alt[5], az[5];        /* the sun's at C1 C2 C3 C4 and maximum */
} tks_local;

/* The eclipse seen from a place, around a greatest at jde_g: 1 if the moon
 * covers any of the sun there (whether or not the sun is up), or 0. */
static int
tks_local_compute(pTHX_ const tks_place *p, double jde_g, tks_local *L)
{
    const double g = 0.6180339887498949;
    double a = jde_g - 0.25, c = jde_g + 0.25, x, y, fx, fy, tm, c1, c4;
    tks_seen v;
    memset(L, 0, sizeof *L);
    L->magic = TKS_LOCAL_MAGIC;
    L->place = *p;
    x = c - g * (c - a);
    y = a + g * (c - a);
    tks_seen_at(aTHX_ p, x, &v); fx = v.sep;
    tks_seen_at(aTHX_ p, y, &v); fy = v.sep;
    while (c - a > 1e-7) {
        if (fx < fy) { c = y; y = x; fy = fx; x = c - g * (c - a); tks_seen_at(aTHX_ p, x, &v); fx = v.sep; }
        else         { a = x; x = y; fx = fy; y = a + g * (c - a); tks_seen_at(aTHX_ p, y, &v); fy = v.sep; }
    }
    tm = 0.5 * (a + c);
    tks_seen_at(aTHX_ p, tm, &v);
    if (v.sep >= v.ss + v.sm1)
        return 0;
    L->maximum = tks_jde_to_sec(aTHX_ tm);
    L->magnitude = (v.ss + v.sm1 - v.sep) / (2.0 * v.ss);
    L->obscuration = tks_obscuration(v.ss, v.sm1, v.sep);
    L->alt[4] = v.sun_alt;
    L->az[4] = v.sun_az;
    c1 = tks_seen_root(aTHX_ p, 0, tm - 0.25, tm);
    c4 = tks_seen_root(aTHX_ p, 0, tm, tm + 0.25);
    L->contact[0] = tks_jde_to_sec(aTHX_ c1);
    L->contact[3] = tks_jde_to_sec(aTHX_ c4);
    L->has[0] = L->has[3] = 1;
    tks_seen_at(aTHX_ p, c1, &v); L->alt[0] = v.sun_alt; L->az[0] = v.sun_az;
    tks_seen_at(aTHX_ p, c4, &v); L->alt[3] = v.sun_alt; L->az[3] = v.sun_az;
    tks_seen_at(aTHX_ p, tm, &v);
    L->type = TKS_SE_PARTIAL;
    if (v.sep < fabs(v.ss - v.sm2)) {
        double c2 = tks_seen_root(aTHX_ p, 1, c1, tm), c3 = tks_seen_root(aTHX_ p, 1, tm, c4);
        L->type = v.sm2 > v.ss ? TKS_SE_TOTAL : TKS_SE_ANNULAR;
        L->contact[1] = tks_jde_to_sec(aTHX_ c2);
        L->contact[2] = tks_jde_to_sec(aTHX_ c3);
        L->has[1] = L->has[2] = 1;
        tks_seen_at(aTHX_ p, c2, &v); L->alt[1] = v.sun_alt; L->az[1] = v.sun_az;
        tks_seen_at(aTHX_ p, c3, &v); L->alt[2] = v.sun_alt; L->az[2] = v.sun_az;
    }
    return 1;
}

/* Whether the sun is up at any time between C1 and C4: at the contacts, the
 * maximum, or every two minutes between. */
static int
tks_local_sun_up(pTHX_ const tks_local *L)
{
    int64_t s;
    int k;
    for (k = 0; k < 5; k++)
        if ((k == 4 || L->has[k]) && L->alt[k] > -0.8333)
            return 1;
    for (s = L->contact[0]; s < L->contact[3]; s += 120) {
        time_keeper_instant t;
        tks_sunview sv;
        t.sec = s;
        t.nsec = 0;
        tks_sun_view(aTHX_ &L->place, &t, &sv);
        if (sv.app_alt > -0.8333)
            return 1;
    }
    return 0;
}

/* ---- the eclipse on the earth --------------------------------------------------- */

static double
tks_axis_distance2(pTHX_ double jde)
{
    tks_bessel b;
    tks_bessel_jde(aTHX_ jde, &b);
    return b.x * b.x + b.y * b.y;
}

/* The axis's height above the earth's outline in the fundamental plane, the
 * flattening counted: below 0 the axis meets the earth. */
static double
tks_axis_outside(pTHX_ double jde)
{
    tks_bessel b;
    double d1, rho1;
    tks_bessel_jde(aTHX_ jde, &b);
    d1 = asin(b.G[2]);
    rho1 = sqrt(1.0 - (2.0 * TKS_ER_F - TKS_ER_F * TKS_ER_F) * cos(d1) * cos(d1));
    return b.x * b.x + (b.y / rho1) * (b.y / rho1) - 1.0;
}

/* The central point at a JDE (where the axis meets the earth): 1 and its
 * latitude, longitude and the umbra's radius there (negative: total), or 0. */
static int
tks_central_point(pTHX_ double jde, double *lat, double *lon, double *L2, double *P_out)
{
    tks_bessel b;
    double P[3], zeta;
    tks_bessel_jde(aTHX_ jde, &b);
    if (!tks_axis_hit(b.M, b.G, P))
        return 0;
    tks_geodetic(P, b.theta, lat, lon);
    zeta = tks_dot3(P, b.G);
    *L2 = b.l2 - zeta * tan(b.f2);
    if (P_out) {
        P_out[0] = P[0]; P_out[1] = P[1]; P_out[2] = P[2];
    }
    return 1;
}

/* The width of the path at a central point, km: the umbra's edge each side of
 * the axis, across the path's direction on the ground, met on the earth. */
static double
tks_path_width(pTHX_ double jde)
{
    tks_bessel b;
    double P0[3], Pa[3], Pb[3], la, lo, L2, t[3], tp[3], w[3], n, off[3], Qa[3], Qb[3];
    int k;
    if (!tks_central_point(aTHX_ jde - 10.0 / 86400.0, &la, &lo, &L2, Pa)
        || !tks_central_point(aTHX_ jde + 10.0 / 86400.0, &la, &lo, &L2, Pb)
        || !tks_central_point(aTHX_ jde, &la, &lo, &L2, P0))
        return 0.0;
    tks_bessel_jde(aTHX_ jde, &b);
    /* the track on the ground, in the frame that turns with the earth: undo
     * the earth's turn of 20 seconds between the two points */
    {
        double rot = tks_rad(360.98564736629 * 20.0 / 86400.0), c = cos(rot), s = sin(rot);
        double x = Pb[0] * c + Pb[1] * s, y = -Pb[0] * s + Pb[1] * c;
        t[0] = x - Pa[0]; t[1] = y - Pa[1]; t[2] = Pb[2] - Pa[2];
    }
    for (k = 0; k < 3; k++)
        tp[k] = t[k] - tks_dot3(t, b.G) * b.G[k];
    w[0] = b.G[1] * tp[2] - b.G[2] * tp[1];
    w[1] = b.G[2] * tp[0] - b.G[0] * tp[2];
    w[2] = b.G[0] * tp[1] - b.G[1] * tp[0];
    n = tks_len3(w);
    if (n == 0.0)
        return 0.0;
    for (k = 0; k < 3; k++)
        off[k] = fabs(L2) * w[k] / n;
    {
        double A[3], B[3];
        for (k = 0; k < 3; k++) {
            A[k] = b.M[k] + off[k];
            B[k] = b.M[k] - off[k];
        }
        if (!tks_axis_hit(A, b.G, Qa) || !tks_axis_hit(B, b.G, Qb))
            return 0.0;
    }
    for (k = 0; k < 3; k++)
        t[k] = Qa[k] - Qb[k];
    return tks_len3(t) * TKS_ER_KM;
}

/* The global solar eclipse near the new moon of lunation k, if any. */
static int
tks_solar_eclipse_at(pTHX_ double k, const tks_place *p, tks_eclipse *e)
{
    const double g = 0.6180339887498949;
    double nm = tks_phase_jde(k), a = nm - 0.3, c = nm + 0.3, x, y, fx, fy, tg;
    tks_bessel b;
    double gam, lat, lon, L2;

    tks_bessel_jde(aTHX_ nm, &b);
    if (b.x * b.x + b.y * b.y > (1.0 + b.l1 + 0.6) * (1.0 + b.l1 + 0.6))
        return 0;
    x = c - g * (c - a);
    y = a + g * (c - a);
    fx = tks_axis_distance2(aTHX_ x);
    fy = tks_axis_distance2(aTHX_ y);
    while (c - a > 1e-7) {
        if (fx < fy) { c = y; y = x; fy = fx; x = c - g * (c - a); fx = tks_axis_distance2(aTHX_ x); }
        else         { a = x; x = y; fx = fy; y = a + g * (c - a); fy = tks_axis_distance2(aTHX_ y); }
    }
    tg = 0.5 * (a + c);
    tks_bessel_jde(aTHX_ tg, &b);
    gam = sqrt(b.x * b.x + b.y * b.y);
    {
        double d1 = asin(b.G[2]);
        double rho1 = sqrt(1.0 - (2.0 * TKS_ER_F - TKS_ER_F * TKS_ER_F) * cos(d1) * cos(d1));
        double m1 = sqrt(b.x * b.x + (b.y / rho1) * (b.y / rho1));
        if (m1 - 1.0 >= b.l1)
            return 0;                       /* the penumbra misses the earth */
    }
    memset(e, 0, sizeof *e);
    e->magic = TKS_ECLIPSE_MAGIC;
    e->kind = TKS_E_SOLAR;
    e->place = *p;
    e->jde_greatest = tg;
    e->greatest = tks_jde_to_sec(aTHX_ tg);
    e->gamma = (b.y >= 0.0 ? 1.0 : -1.0) * gam;

    if (tks_central_point(aTHX_ tg, &lat, &lon, &L2, NULL)) {
        /* central: the type by the umbra's sign along the path; the
         * magnitude the moon's diameter over the sun's at the central point */
        tks_place cp;
        tks_seen v;
        double lo_t = tg - 0.2, hi_t = tg, start, end, t;
        int tot = 0, ann = 0, i;
        memset(&cp, 0, sizeof cp);
        cp.lat = lat;
        cp.lon = lon;
        tks_seen_at(aTHX_ &cp, tg, &v);
        e->magnitude = v.sm2 / v.ss;
        e->lat = lat;
        e->lon = lon;
        e->sun_alt = v.sun_alt;
        e->central = 1;
        /* the central line's ends: the axis leaving the earth's outline */
        for (i = 0; i < 60; i++) {
            double mid = 0.5 * (lo_t + hi_t);
            if (tks_axis_outside(aTHX_ mid) > 0.0) lo_t = mid; else hi_t = mid;
        }
        start = hi_t;
        lo_t = tg; hi_t = tg + 0.2;
        for (i = 0; i < 60; i++) {
            double mid = 0.5 * (lo_t + hi_t);
            if (tks_axis_outside(aTHX_ mid) > 0.0) hi_t = mid; else lo_t = mid;
        }
        end = lo_t;
        e->central_start = start;
        e->central_end = end;
        for (t = start; t <= end; t += 60.0 / 86400.0) {
            double la, lo, l2;
            if (tks_central_point(aTHX_ t, &la, &lo, &l2, NULL)) {
                if (l2 < 0.0) tot = 1; else ann = 1;
            }
        }
        e->type = tot && ann ? TKS_SE_HYBRID : L2 < 0.0 ? TKS_SE_TOTAL : TKS_SE_ANNULAR;
        e->width = tks_path_width(aTHX_ tg);
        {
            tks_local Lc;
            if (tks_local_compute(aTHX_ &cp, tg, &Lc) && Lc.has[1])
                e->duration = (double)(Lc.contact[2] - Lc.contact[1]);
        }
    }
    else {
        /* not central: the point on the earth's limb nearest the axis; the
         * magnitude by the penumbra's reach past the limb (54) */
        double d1 = asin(b.G[2]);
        double rho1 = sqrt(1.0 - (2.0 * TKS_ER_F - TKS_ER_F * TKS_ER_F) * cos(d1) * cos(d1));
        double m1 = sqrt(b.x * b.x + (b.y / rho1) * (b.y / rho1)), Q[3];
        int kk;
        e->type = (m1 - 1.0) < fabs(b.l2) ? (b.l2 < 0.0 ? TKS_SE_TOTAL : TKS_SE_ANNULAR) : TKS_SE_PARTIAL;
        for (kk = 0; kk < 3; kk++)
            Q[kk] = (b.x / m1) * b.i[kk] + (b.y / m1) * b.j[kk];
        tks_geodetic(Q, b.theta, &e->lat, &e->lon);
        e->sun_alt = 0.0;
        /* the magnitude as the limb point sees it at greatest: the fraction
         * of the sun's diameter covered there, the Canon's definition. (54's
         * estimate from the fundamental plane, the flattening counted, reads
         * 0.0011 smaller on average and 0.003 on the grazing ones.) */
        {
            tks_place lp;
            tks_seen v;
            memset(&lp, 0, sizeof lp);
            lp.lat = e->lat;
            lp.lon = e->lon;
            tks_seen_at(aTHX_ &lp, tg, &v);
            e->magnitude = (v.ss + v.sm1 - v.sep) / (2.0 * v.ss);
        }
    }
    return 1;
}

static int
tks_solar_eclipse_find(pTHX_ int64_t from, int backwards, const tks_place *p, tks_eclipse *e)
{
    double jd = TKS_JD_EPOCH + (double)from / 86400.0;
    double k = floor((tks_decimal_year(jd) - 2000.0) * TKS_LUNATIONS_A_YEAR);
    int n;
    k += backwards ? 2.0 : -2.0;
    for (n = 0; n < 750; n++, k += backwards ? -1.0 : 1.0)
        if (tks_solar_eclipse_at(aTHX_ k, p, e)
            && ((!backwards && e->greatest > from) || (backwards && e->greatest < from)))
            return 1;
    return 0;
}

static const tks_local *
tks_local_of(pTHX_ SV *sv, const char *what)
{
    SV *inner;
    const tks_local *L;
    if (!sv || !SvROK(sv) || !sv_derived_from(sv, "Time::Keeper::Eclipse::Local"))
        croak("%s: not a Time::Keeper::Eclipse::Local", what);
    inner = SvRV(sv);
    if (!SvPOK(inner) || SvCUR(inner) != sizeof(tks_local))
        croak("%s: not a Time::Keeper::Eclipse::Local", what);
    L = (const tks_local *)SvPVX(inner);
    if (L->magic != TKS_LOCAL_MAGIC)
        croak("%s: not a Time::Keeper::Eclipse::Local", what);
    return L;
}

#endif
