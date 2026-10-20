#ifndef TKS_STAR_H
#define TKS_STAR_H

/* The stars of the Bright Star Catalogue (tks_bsc5.h): finding one by name,
 * Bayer or Flamsteed designation or HR number, and its apparent place by the
 * rigorous model the Astronomical Almanac and NOVAS use: the star's position
 * and space velocity from its catalogue place, proper motion, parallax and
 * radial velocity (with the Doppler factor), moved to the instant its light
 * reaches the earth; seen from the earth (the annual parallax); the sun's
 * light deflection and the annual aberration; then precession (Meeus 21.2 to
 * 21.4) and nutation (22) to the true equator and equinox of date. The
 * vectors are rotated to the mean equator of date first, where the earth's
 * place and velocity from VSOP87D meet them: a rotation commutes with every
 * step that follows. */

#include "tks_bsc5.h"

#define TKS_AU_PER_PARSEC 206264.80624709636

/* The HR number's row, or -1: a table filled the first time it is asked. */
static int16_t tks_star_by_hr[9111];
static int tks_star_by_hr_ready = 0;

static int
tks_star_hr_index(int hr)
{
    if (!tks_star_by_hr_ready) {
        int i;
        for (i = 0; i < 9111; i++)
            tks_star_by_hr[i] = -1;
        for (i = 0; i < TKS_STARS; i++)
            tks_star_by_hr[tks_bsc5[i].hr] = (int16_t)i;
        tks_star_by_hr_ready = 1;
    }
    return hr >= 1 && hr <= 9110 ? tks_star_by_hr[hr] : -1;
}

static const char *const tks_greek[24][2] = {
    { "alpha", "Alp" }, { "beta", "Bet" }, { "gamma", "Gam" }, { "delta", "Del" },
    { "epsilon", "Eps" }, { "zeta", "Zet" }, { "eta", "Eta" }, { "theta", "The" },
    { "iota", "Iot" }, { "kappa", "Kap" }, { "lambda", "Lam" }, { "mu", "Mu" },
    { "nu", "Nu" }, { "xi", "Xi" }, { "omicron", "Omi" }, { "pi", "Pi" },
    { "rho", "Rho" }, { "sigma", "Sig" }, { "tau", "Tau" }, { "upsilon", "Ups" },
    { "phi", "Phi" }, { "chi", "Chi" }, { "psi", "Psi" }, { "omega", "Ome" },
};

static int
tks_ci_eq(const char *a, STRLEN alen, const char *b)
{
    STRLEN i, blen = strlen(b);
    if (alen != blen)
        return 0;
    for (i = 0; i < alen; i++) {
        char x = a[i], y = b[i];
        if (x >= 'A' && x <= 'Z') x = (char)(x - 'A' + 'a');
        if (y >= 'A' && y <= 'Z') y = (char)(y - 'A' + 'a');
        if (x != y)
            return 0;
    }
    return 1;
}

/* A star by what a person would call it: an IAU name ("Betelgeuse"), "HR
 * 2061", a Bayer designation ("alpha Ori", "Alp Ori", "alf Ori", with a
 * superscript as "alpha1 Cen" or "Alp1 Cen"), or a Flamsteed one ("58 Ori").
 * Case is not minded. Returns the row, or -1. */
static int
tks_star_find(const char *s, STRLEN len)
{
    int i, g;
    STRLEN sp = 0;
    /* an IAU name */
    for (i = 0; i < TKS_STARS; i++)
        if (tks_bsc5[i].name >= 0 && tks_ci_eq(s, len, tks_star_names[tks_bsc5[i].name][0]))
            return i;
    /* HR n */
    if (len > 3 && (s[0] == 'H' || s[0] == 'h') && (s[1] == 'R' || s[1] == 'r')) {
        STRLEN k = 2;
        int hr = 0;
        while (k < len && s[k] == ' ') k++;
        if (k == len) return -1;
        for (; k < len; k++) {
            if (s[k] < '0' || s[k] > '9') return -1;
            hr = hr * 10 + (s[k] - '0');
            if (hr > 9110) return -1;
        }
        return tks_star_hr_index(hr);
    }
    /* the first word, then the constellation */
    while (sp < len && s[sp] != ' ') sp++;
    if (sp == 0 || sp == len) return -1;
    {
        const char *con = s + sp + 1;
        STRLEN clen = len - sp - 1, wl = sp;
        char sup = '\0';
        if (s[0] >= '0' && s[0] <= '9') {
            int f = 0;
            STRLEN k;
            for (k = 0; k < wl; k++) {
                if (s[k] < '0' || s[k] > '9') return -1;
                f = f * 10 + (s[k] - '0');
            }
            for (i = 0; i < TKS_STARS; i++)
                if (tks_bsc5[i].flamsteed == f && tks_ci_eq(con, clen, tks_bsc5[i].con))
                    return i;
            return -1;
        }
        if (wl > 1 && s[wl - 1] >= '1' && s[wl - 1] <= '9') {
            sup = s[wl - 1];
            wl--;
        }
        for (g = 0; g < 24; g++) {
            const char *abbr = tks_greek[g][1];
            if (tks_ci_eq(s, wl, tks_greek[g][0]) || tks_ci_eq(s, wl, abbr)
                || (g == 0 && tks_ci_eq(s, wl, "alf")))
                for (i = 0; i < TKS_STARS; i++)
                    if (tks_ci_eq(abbr, strlen(abbr), tks_bsc5[i].bayer)
                        && tks_ci_eq(con, clen, tks_bsc5[i].con)
                        && (sup == '\0' || tks_bsc5[i].sup == sup))
                        return i;
        }
    }
    return -1;
}

/* ---- the place ------------------------------------------------------------------ */

/* The precession matrix from the mean equator and equinox of J2000.0 to
 * those of a date T Julian centuries later (21.2 to 21.4). */
static void
tks_precession_matrix(double T, double m[3][3])
{
    double z = tks_rad((2306.2181 * T + 1.09468 * T * T + 0.018203 * T * T * T) / 3600.0);
    double ze = tks_rad((2306.2181 * T + 0.30188 * T * T + 0.017998 * T * T * T) / 3600.0);
    double th = tks_rad((2004.3109 * T - 0.42665 * T * T - 0.041833 * T * T * T) / 3600.0);
    double cz = cos(z), sz = sin(z), cx = cos(ze), sx = sin(ze), ct = cos(th), st = sin(th);
    m[0][0] =  cx * ct * cz - sx * sz;  m[0][1] = -sx * ct * cz - cx * sz;  m[0][2] = -st * cz;
    m[1][0] =  cx * ct * sz + sx * cz;  m[1][1] = -sx * ct * sz + cx * cz;  m[1][2] = -st * sz;
    m[2][0] =  cx * st;                 m[2][1] = -sx * st;                 m[2][2] =  ct;
}

static void
tks_rot3(const double m[3][3], const double *v, double *out)
{
    double r[3];
    int i;
    for (i = 0; i < 3; i++)
        r[i] = m[i][0] * v[0] + m[i][1] * v[1] + m[i][2] * v[2];
    for (i = 0; i < 3; i++)
        out[i] = r[i];
}

/* An ecliptic vector of date to the mean equator of date. */
static void
tks_ecl_to_eq(double eps, const double *v, double *out)
{
    double c = cos(eps), s = sin(eps), y = v[1], z = v[2];
    out[0] = v[0];
    out[1] = c * y - s * z;
    out[2] = s * y + c * z;
}

/* What the stars at one instant share: the precession, the earth's place and
 * velocity in the mean equator of date, the nutation. Made once for many. */
typedef struct tks_starframe {
    double jde, days, T;
    double P[3][3];             /* J2000 to the mean equator of date */
    double E[3], Ev[3];         /* the earth from the sun, AU and AU a day, mean equator of date */
    double Elen;
    double eps0, eps, dpsi;     /* mean and true obliquity (radians), the nutation in longitude (radians) */
} tks_starframe;

static void
tks_starframe_at(double jde, tks_starframe *f)
{
    double e[3], ed[3], Er[3], Evr[3], deps, dpsi;
    f->jde = jde;
    f->days = jde - TKS_J2000;
    f->T = tks_T(jde);
    tks_precession_matrix(f->T, f->P);
    tks_vsop_lbr_dot(TKS_EARTH, jde, e, ed);
    tks_rect(e[0], e[1], e[2], Er);
    Evr[0] = ed[2] * cos(e[1]) * cos(e[0]) - e[2] * sin(e[1]) * ed[1] * cos(e[0]) - e[2] * cos(e[1]) * sin(e[0]) * ed[0];
    Evr[1] = ed[2] * cos(e[1]) * sin(e[0]) - e[2] * sin(e[1]) * ed[1] * sin(e[0]) + e[2] * cos(e[1]) * cos(e[0]) * ed[0];
    Evr[2] = ed[2] * sin(e[1]) + e[2] * cos(e[1]) * ed[1];
    f->eps0 = tks_rad(tks_obliquity_mean(f->T));
    tks_ecl_to_eq(f->eps0, Er, f->E);
    tks_ecl_to_eq(f->eps0, Evr, f->Ev);
    f->Elen = tks_len3(f->E);
    tks_nutation(f->T, &dpsi, &deps);
    f->dpsi = tks_rad(dpsi / 3600.0);
    f->eps = f->eps0 + tks_rad(deps / 3600.0);
}

/* A star's apparent right ascension and declination of date, degrees. */
static void
tks_star_apparent(const tks_star_row *s, const tks_starframe *f, double *ra, double *dec)
{
    double plx = s->plx > 0.0 ? s->plx : 1.0e-9;            /* a gigaparsec where unknown */
    double dist = 1.0 / sin(tks_rad(plx / 3600.0));
    double a = tks_rad(s->ra), d = tks_rad(s->dec);
    double ca = cos(a), sa = sin(a), cd = cos(d), sd = sin(d);
    double k = 1.0 / (1.0 - s->rv / 299792.458);
    double pmr = s->pmra / (plx * 365.25) * k, pmd = s->pmdec / (plx * 365.25) * k;
    double rvl = s->rv * 86400.0 / TKS_AU_KM_EXACT * k;
    double P[3], V[3], u[3], q[3], ehat[3], x[3], n, dt, g1, g2, pq, ep;
    int i;
    P[0] = dist * cd * ca;  P[1] = dist * cd * sa;  P[2] = dist * sd;
    V[0] = -pmr * sa - pmd * sd * ca + rvl * cd * ca;
    V[1] =  pmr * ca - pmd * sd * sa + rvl * cd * sa;
    V[2] =  pmd * cd + rvl * sd;
    tks_rot3(f->P, P, P);
    tks_rot3(f->P, V, V);
    /* the light-time to the earth, less that to the sun */
    dt = (tks_dot3(P, f->E) / dist) / TKS_C_AU_PER_DAY;
    for (i = 0; i < 3; i++)
        x[i] = P[i] + V[i] * (f->days + dt);
    for (i = 0; i < 3; i++) {
        q[i] = x[i];
        u[i] = x[i] - f->E[i];
    }
    n = tks_len3(u);
    for (i = 0; i < 3; i++) u[i] /= n;
    n = tks_len3(q);
    for (i = 0; i < 3; i++) {
        q[i] /= n;
        ehat[i] = f->E[i] / f->Elen;
    }
    /* the sun's deflection, then the aberration */
    g1 = TKS_SUN_2MU_C2_AU / f->Elen;
    g2 = 1.0 + tks_dot3(q, ehat);
    pq = tks_dot3(u, q);
    ep = tks_dot3(ehat, u);
    for (i = 0; i < 3; i++)
        u[i] += (g1 / g2) * (pq * ehat[i] - ep * q[i]);
    for (i = 0; i < 3; i++)
        u[i] += f->Ev[i] / TKS_C_AU_PER_DAY;
    /* the nutation: the mean equator of date to the ecliptic, the turn
     * in longitude, and back by the true obliquity */
    {
        double c0 = cos(f->eps0), s0 = sin(f->eps0), c1 = cos(f->eps), s1 = sin(f->eps);
        double cp = cos(f->dpsi), spsi = sin(f->dpsi);
        double ex = u[0], ey = c0 * u[1] + s0 * u[2], ez = -s0 * u[1] + c0 * u[2];
        double rx = cp * ex - spsi * ey, ry = spsi * ex + cp * ey;
        u[0] = rx;
        u[1] = c1 * ry - s1 * ez;
        u[2] = s1 * ry + c1 * ez;
    }
    n = tks_len3(u);
    *ra = tks_deg_norm(tks_deg(atan2(u[1], u[0])));
    *dec = tks_deg(asin(u[2] / n));
}

/* A star from what a caller passes: an HR number, or a name or designation;
 * dies naming what it could not find when it must be found. */
static int
tks_star_row_arg(pTHX_ SV *sv, int must, const char *what)
{
    STRLEN len;
    const char *s;
    int row;
    if (sv)
        SvGETMAGIC(sv);
    if (!sv || !SvOK(sv))
        croak("%s needs a star: a name, a designation or an HR number", what);
    if (SvIOK(sv) || (looks_like_number(sv) && !SvPOK(sv)))
        row = tks_star_hr_index((int)SvIV_nomg(sv));
    else {
        s = SvPV_nomg(sv, len);
        row = tks_star_find(s, len);
        if (row < 0 && looks_like_number(sv))
            row = tks_star_hr_index((int)SvIV_nomg(sv));
    }
    if (row < 0 && must) {
        s = SvPV_nomg(sv, len);
        croak("%s: no star is known as '%.*s' in the Bright Star Catalogue", what, (int)len, s);
    }
    return row;
}

/* ---- rise, set and transit ------------------------------------------------- */

#define TKS_STAR_RATE 360.98564736629      /* a star's hour angle, degrees a day */

/* The star's altitude from the body's place at a JD (UT), for the event
 * engine: its apparent place at that instant (no parallax: a star is as far
 * from every place); a point, so its horizon is the planets'. */
static double
tks_star_alt(pTHX_ const tks_body *b, double jd, double *H_out)
{
    time_keeper_instant t;
    tks_starframe f;
    double jde, ra, dec, alt, az, H;
    tks_instant_from_jd(jd, &t);
    jde = jd + tks_delta_t(aTHX_ &t) / 86400.0;
    tks_starframe_at(jde, &f);
    tks_star_apparent(&tks_bsc5[b->planet], &f, &ra, &dec);
    tks_altaz_theta(tks_sidereal_apparent(jd, jde), b->p->lat, b->p->lon, ra, dec, &alt, &az, &H);
    if (H_out)
        *H_out = H;
    return alt;
}

static void
tks_star_body(const tks_place *p, int row, tks_body *b)
{
    memset(b, 0, sizeof *b);
    b->p = p;
    b->moon = 3;
    b->planet = row;
    b->rate = TKS_STAR_RATE;
}

static void
tks_starday_compute(pTHX_ const tks_place *p, int row, int64_t days, int64_t start, int64_t end, tks_planetday *d)
{
    tks_body b;
    tks_bodyday_init(d, p, days, start, end);
    d->star = row;
    tks_star_body(&d->place, row, &b);
    tks_bodyday_fill(aTHX_ d, &b, tks_planet_horizon(&d->place));
}

/* Whether a star stays above (or below) a horizon all year at a place: its
 * lowest altitude, -90 + |lat + dec|, over it, or its highest, 90 - |lat -
 * dec|, under it, by more than a year's change of declination can close. A
 * search for a crossing that cannot be found walks a year. */
static int
tks_star_never_crosses(pTHX_ const tks_place *p, int row, int64_t from, double h0)
{
    time_keeper_instant t;
    tks_starframe f;
    double ra, dec, lo, hi;
    t.sec = from;
    t.nsec = 0;
    tks_starframe_at(tks_jde(aTHX_ &t), &f);
    tks_star_apparent(&tks_bsc5[row], &f, &ra, &dec);
    lo = -90.0 + fabs(p->lat + dec);
    hi = 90.0 - fabs(p->lat - dec);
    return lo > h0 + 0.1 || hi < h0 - 0.1;
}

/* A star's name for people: its IAU name, else "HR n". */
static SV *
tks_star_name_sv(pTHX_ int row)
{
    const tks_star_row *s = &tks_bsc5[row];
    if (s->name >= 0)
        return newSVpvn_flags(tks_star_names[s->name][1], strlen(tks_star_names[s->name][1]), SVf_UTF8);
    return newSVpvf("HR %d", (int)s->hr);
}

/* ---- the constellations (tks_cons.h) ------------------------------------------- */

#include "tks_cons.h"

#define TKS_B1875 2405889.25855     /* B1875.0, the frame of the boundaries */

/* The constellation a direction lies in, by Roman's method: precessed from
 * the mean equator and equinox of the date jde_frame to those of B1875.0
 * (through J2000.0, by 21.2 to 21.4), then the first of his bands whose lower
 * declination is at or below it and whose right ascension holds it. An
 * apparent place differs from the mean by aberration and nutation, under a
 * minute of arc: only a direction on a boundary can tell. The index. */
static double tks_p1875[3][3];         /* J2000.0 to B1875.0, filled once at BOOT */

static void
tks_cons_init(void)
{
    tks_precession_matrix(tks_T(TKS_B1875), tks_p1875);
}

/* The matrix from the mean equator and equinox of a date to those of
 * B1875.0: the date's back to J2000.0 (the transpose), then on, as one. */
static void
tks_cons_matrix(double jde_frame, double c[3][3])
{
    double m[3][3];
    int i, j;
    if (jde_frame == TKS_J2000) {
        memcpy(c, tks_p1875, sizeof tks_p1875);
        return;
    }
    tks_precession_matrix(tks_T(jde_frame), m);
    for (i = 0; i < 3; i++)
        for (j = 0; j < 3; j++)
            c[i][j] = tks_p1875[i][0] * m[j][0] + tks_p1875[i][1] * m[j][1] + tks_p1875[i][2] * m[j][2];
}

static int
tks_cons_lookup(const double c[3][3], double ra, double dec)
{
    double v[3], w[3], rah, d;
    double a = tks_rad(ra), de = tks_rad(dec);
    int i;
    v[0] = cos(de) * cos(a);
    v[1] = cos(de) * sin(a);
    v[2] = sin(de);
    tks_rot3(c, v, w);
    rah = tks_deg_norm(tks_deg(atan2(w[1], w[0]))) / 15.0;
    d = tks_deg(asin(w[2] > 1.0 ? 1.0 : w[2] < -1.0 ? -1.0 : w[2]));
    /* the bands fall in declination: every one before the first at or
     * below d is skipped by Roman's rule, so start there */
    {
        int lo = 0, hi = TKS_CONS_ROWS;
        while (lo < hi) {
            int mid = (lo + hi) / 2;
            if (tks_cons_rows[mid].dec_lo > d) lo = mid + 1;
            else hi = mid;
        }
        i = lo;
    }
    for (; i < TKS_CONS_ROWS; i++) {
        const tks_cons_row *r = &tks_cons_rows[i];
        if (r->ra_hi <= rah || r->ra_lo > rah)
            continue;
        return r->con;
    }
    return -1;      /* not reached: the last band is the whole south cap */
}

static int
tks_constellation_of(double ra, double dec, double jde_frame)
{
    double c[3][3];
    tks_cons_matrix(jde_frame, c);
    return tks_cons_lookup(c, ra, dec);
}

/* The constellation of a body's apparent place at a JDE: the frame taken at
 * the JDE to the nearest half day, whose matrix is kept, since precession
 * moves the frame 0.07 arcseconds in half a day and an apparent place is
 * already up to a minute of arc from the mean. The answer depends on the
 * arguments alone. */
static int
tks_constellation_at(pTHX_ double ra, double dec, double jde)
{
    dMY_CXT;
    double jq = floor(jde * 2.0 + 0.5) / 2.0;
    if (MY_CXT.cons_jq != jq) {
        tks_cons_matrix(jq, MY_CXT.cons_m);
        MY_CXT.cons_jq = jq;
    }
    return tks_cons_lookup((const double (*)[3])MY_CXT.cons_m, ra, dec);
}

/* A constellation by its abbreviation or its name, case not minded; -1. */
static int
tks_constellation_find(const char *s, STRLEN len)
{
    int i, k;
    for (i = 0; i < TKS_CONSTELLATIONS; i++)
        for (k = 0; k < 2; k++)
            if (tks_ci_eq(s, len, tks_cons_names[i][k]))
                return i;
    return -1;
}

#endif
