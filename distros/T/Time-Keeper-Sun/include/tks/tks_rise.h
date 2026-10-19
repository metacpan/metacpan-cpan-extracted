#ifndef TKS_RISE_H
#define TKS_RISE_H

/* The event engine: the sun's altitude from a place as a function of the
 * instant, its transits, the true extrema of the altitude around them, and
 * the moments it crosses a depth below the horizon, found by a bracketed
 * root search between consecutive extrema. Everything is in JD (UT) as a
 * double until the result is rounded to the second. */

#define TKS_EARTH_RADIUS 6372000.0      /* metres, as Calendrical Calculations has it */

/* The kinds of event a day holds, in pairs: even rising, odd setting. */
#define TKS_K_SUNRISE   0
#define TKS_K_SUNSET    1
#define TKS_K_CIVIL_DAWN 2
#define TKS_K_CIVIL_DUSK 3
#define TKS_K_NAUT_DAWN 4
#define TKS_K_NAUT_DUSK 5
#define TKS_K_ASTRO_DAWN 6
#define TKS_K_ASTRO_DUSK 7
#define TKS_K_NOON      8
#define TKS_K_MIDNIGHT  9
#define TKS_K_COUNT     10
#define TKS_DEPTHS      4

static const char *const tks_kind_name[TKS_K_COUNT] = {
    "sunrise", "sunset", "civil_dawn", "civil_dusk", "nautical_dawn", "nautical_dusk",
    "astronomical_dawn", "astronomical_dusk", "solar_noon", "solar_midnight",
};

/* The depression of the horizon for rise and set at a place, degrees,
 * negative: 50 arcminutes (34 of refraction and 16 of semidiameter) plus the
 * dip of a horizon seen from a height and the height's refraction term, as
 * Reingold and Dershowitz have them. The twilights are fixed depths. */
static double
tks_horizon(const tks_place *p)
{
    double h = p->elev;
    double dip = tks_deg(acos(TKS_EARTH_RADIUS / (TKS_EARTH_RADIUS + h)));
    return -(50.0 / 60.0 + dip + (19.0 / 3600.0) * sqrt(h));
}

static double
tks_depth(const tks_place *p, int k)
{
    return k == 0 ? tks_horizon(p) : k == 1 ? -6.0 : k == 2 ? -12.0 : -18.0;
}

/* The sun's geometric altitude from the place at a JD in UT, and its hour
 * angle. */
/* A body the engine follows from a place: the sun, or the moon. The sun's
 * altitude is its centre's, geometric; the moon's is its upper limb's,
 * topocentric (the centre seen from the place, which the parallax lowers by
 * up to a degree, plus the semidiameter, 0.2725 times the parallax), so that
 * its horizon is a fixed depth as the sun's is. */
typedef struct tks_body {
    const tks_place *p;
    int moon;
    double rs, rc;              /* the moon's: the place's parallax constants, once */
} tks_body;

/* A moon body, its place's constants worked out once. */
static void
tks_moon_body(const tks_place *p, tks_body *b)
{
    b->p = p;
    b->moon = 1;
    tks_parallax_constants(p->lat, p->elev, &b->rs, &b->rc);
}

#define TKS_SUN_RATE  360.0            /* the sun's hour angle, degrees a day */
#define TKS_MOON_RATE 347.81           /* the moon's, on average: it lags 12.19 degrees a day */

static double
tks_body_rate(const tks_body *b)
{
    return b->moon ? TKS_MOON_RATE : TKS_SUN_RATE;
}

static double
tks_alt_at(pTHX_ const tks_body *b, double jd, double *H_out)
{
    time_keeper_instant t;
    double jde, alt, az, H;
    tks_instant_from_jd(jd, &t);
    if (b->moon) {
        /* tks_moon_view without what the event engine does not read: the
         * nutation is the one the moon's place worked out, the parallax
         * constants the body's, and no geocentric altitude or refraction. */
        tks_moonplace m;
        double theta, h, Ht, dect;
        jde = jd + tks_delta_t(aTHX_ &t) / 86400.0;
        tks_moon_place(jde, &m);
        theta = tks_deg_norm(tks_sidereal_mean(jd) + (m.dpsi / 3600.0) * cos(tks_rad(m.eps_true)));
        h = tks_deg_norm(theta + b->p->lon - m.ra);
        tks_topocentric(h > 180.0 ? h - 360.0 : h, m.dec, m.parallax, b->rs, b->rc, &Ht, &dect);
        tks_altaz_hd(b->p->lat, Ht, dect, &alt, &az);
        if (H_out)
            *H_out = Ht;
        return alt + 0.2725 * m.parallax;
    }
    else {
        const tks_place *p = b->p;
        tks_sunpos s;
        jde = jd + tks_delta_t(aTHX_ &t) / 86400.0;
        tks_sun_place(jde, &s);
        tks_altaz(jd, jde, p->lat, p->lon, s.ra, s.dec, &alt, &az, &H);
        if (H_out)
            *H_out = H;
        return alt;
    }
}

/* The upper (lower = 0) or lower transit nearest a guess, by fixed-point
 * iteration on the hour angle: it closes by a factor of a few hundred a
 * round, so three rounds settle it. The guess is a JD near the one wanted,
 * never a local time reduced modulo a day. */
static double
tks_transit(pTHX_ const tks_body *b, double guess, int lower)
{
    double t = guess;
    int i;
    for (i = 0; i < 10; i++) {
        double H;
        tks_alt_at(aTHX_ b, t, &H);
        if (lower)
            H = H > 0.0 ? H - 180.0 : H + 180.0;
        t -= H / tks_body_rate(b);
        /* the sun to 1e-5 degrees of hour angle (2 ms), as 0.01 did; the
         * moon, whose results are rounded to the second too, to 1e-4 (24 ms) */
        if (fabs(H) < (b->moon ? 1e-4 : 1e-5))
            break;
    }
    return t;
}

/* The true extremum of the altitude around a transit: the vertex of the
 * parabola through three points half an hour apart (chapter 3), since the
 * declination's motion moves the extremum off the transit. */
static void
tks_extremum(pTHX_ const tks_body *body, double t, double *tm, double *ym)
{
    const double h = 1.0 / 48.0;
    double y1 = tks_alt_at(aTHX_ body, t - h, NULL);
    double y2 = tks_alt_at(aTHX_ body, t, NULL);
    double y3 = tks_alt_at(aTHX_ body, t + h, NULL);
    double a = y2 - y1, b = y3 - y2, c = b - a, n;
    /* Where the daily swing is smaller than the declination's drift (near a
     * pole) the three points are nearly a line and the vertex is nowhere
     * near: then the transit stands, and the bracket's ends decide the
     * crossing. A vertex more than 45 minutes off, or with the curvature of
     * the wrong kind of extremum, is such a case. */
    *tm = t;
    *ym = y2;
    if (fabs(c) < 1e-12)
        return;
    n = -(a + b) / (2.0 * c);
    if (fabs(n) > 1.5)
        return;
    *tm = t + n * h;
    *ym = y2 - (a + b) * (a + b) / (8.0 * c);
}

/* The crossing of a depth between two extrema (ta, ya) and (tb, yb) with
 * ta < tb, if there is one: there is iff the higher is at or above the depth
 * and the lower below it. Found by the Illinois method on the bracket, to
 * under a hundredth of a second. Returns 1 and the JD, or 0. */
static int
tks_crossing(pTHX_ const tks_body *b, double ta, double ya, double tb, double yb, double h0, double *out)
{
    double lo = ta, hi = tb, flo = ya - h0, fhi = yb - h0, t = ta, f;
    int side = 0, i;
    double ymax = ya > yb ? ya : yb, ymin = ya > yb ? yb : ya;
    if (!(ymax >= h0 && h0 > ymin))
        return 0;
    if (flo == 0.0) { *out = ta; return 1; }
    if (fhi == 0.0) { *out = tb; return 1; }
    for (i = 0; i < 80; i++) {
        t = (lo * fhi - hi * flo) / (fhi - flo);
        if (t <= lo || t >= hi)
            t = 0.5 * (lo + hi);
        f = tks_alt_at(aTHX_ b, t, NULL) - h0;
        if (f == 0.0 || hi - lo < (b->moon ? 1e-6 : 1e-7))   /* 86 ms for the moon, 9 ms for the sun */
            break;
        if ((f < 0.0) == (flo < 0.0)) {
            lo = t;
            flo = f;
            if (side == -1)
                fhi *= 0.5;
            side = -1;
        }
        else {
            hi = t;
            fhi = f;
            if (side == 1)
                flo *= 0.5;
            side = 1;
        }
    }
    *out = t;
    return 1;
}

/* ---- a day -------------------------------------------------------------- */

#define TKS_DAY_MAGIC 0x54534b44u
#define TKS_MAX_TRANSITS 12

typedef struct tks_xing {
    double t;
    int    kind;
} tks_xing;

typedef struct tks_day {
    uint32_t  magic;
    tks_place place;
    int64_t   days;                     /* the date, days since 1970 */
    int64_t   start, end;               /* the civil window, epoch seconds, [start, end) */
    int32_t   ev[TKS_K_COUNT][2];       /* the events in the window, seconds after start, in order */
    int32_t   day_length;               /* seconds, -1 when there is none */
    uint8_t   n[TKS_K_COUNT];           /* how many of each kind the window holds (two kept) */
    uint8_t   polar_day, polar_night;
    uint8_t   done;                     /* the depths computed: bit k for depth k (0 rise and set, 1 to 3 the twilights) */
} tks_day;

static int tks_day_walks = 0;           /* for a test door: how many times a day's transits were walked */

static int64_t
tks_round_jd(double jd)
{
    time_keeper_instant t;
    tks_instant_from_jd_second(jd, &t);
    return t.sec;
}

/* Whether a rounded second lies in the window: the start is in, the end is
 * the next day's. */
static int
tks_in_window(const tks_day *d, int64_t sec)
{
    return sec >= d->start && sec < d->end;
}

static void
tks_day_add(tks_day *d, int kind, int64_t sec)
{
    if (!tks_in_window(d, sec))
        return;
    if (d->n[kind] < 2)
        d->ev[kind][d->n[kind]] = (int32_t)(sec - d->start);
    if (d->n[kind] < 255)
        d->n[kind]++;
}

/* The i-th event of a kind, as an epoch second. */
static int64_t
tks_day_ev(const tks_day *d, int kind, int i)
{
    return d->start + d->ev[kind][i];
}

/* The transits around the window: from the lower one at or before the
 * start to the first lower one at or after the end (the sunset after the
 * day's last sunrise always comes before that lower transit, so it is seen
 * too), and the extrema of the altitude at each. Returns the count. */
static int
tks_day_walk(pTHX_ const tks_body *b, int64_t start, int64_t end,
             double *tt, int *lower, double *et, double *ey)
{
    double jstart = TKS_JD_EPOCH + (double)start / 86400.0;
    double jend   = TKS_JD_EPOCH + (double)end / 86400.0;
    double t, half = 180.0 / tks_body_rate(b), whole = 360.0 / tks_body_rate(b);
    int nt = 0, i;

    tks_day_walks++;
    t = tks_transit(aTHX_ b, jstart, 1);
    if (t > jstart)
        t = tks_transit(aTHX_ b, t - whole, 1);
    tt[nt] = t; lower[nt] = 1; nt++;
    while (nt < TKS_MAX_TRANSITS - 1) {
        t = tks_transit(aTHX_ b, tt[nt - 1] + half, 0);
        tt[nt] = t; lower[nt] = 0; nt++;
        t = tks_transit(aTHX_ b, tt[nt - 1] + half, 1);
        tt[nt] = t; lower[nt] = 1; nt++;
        if (t >= jend)
            break;
    }
    for (i = 0; i < nt; i++)
        tks_extremum(aTHX_ b, tt[i], &et[i], &ey[i]);
    return nt;
}

/* The crossings of one depth between consecutive extrema, into the day;
 * for depth 0 also the list of them, for day_length. */
static int
tks_day_cross(pTHX_ tks_day *d, int k, int nt, const double *et, const double *ey, tks_xing *xs)
{
    double h0 = tks_depth(&d->place, k);
    int i, nx = 0;
    tks_body b;
    b.p = &d->place;
    b.moon = 0;
    for (i = 0; i + 1 < nt; i++) {
        double c;
        if (tks_crossing(aTHX_ &b, et[i], ey[i], et[i + 1], ey[i + 1], h0, &c)) {
            /* rising or setting by the altitudes either side, not by which
             * transit came first: at a pole the two transits mean nothing
             * and the declination alone carries the sun across */
            int kind = 2 * k + (ey[i] < ey[i + 1] ? 0 : 1);
            if (xs) {
                xs[nx].t = c;
                xs[nx].kind = kind;
            }
            nx++;
            tks_day_add(d, kind, tks_round_jd(c));
        }
    }
    d->done |= (uint8_t)(1u << k);
    return nx;
}

/* What on() computes: the transits, the sunrises and sunsets, the polar
 * flags and day_length. The twilights wait for tks_day_depth. */
static void
tks_day_compute(pTHX_ const tks_place *p, int64_t days, int64_t start, int64_t end, tks_day *d)
{
    double tt[TKS_MAX_TRANSITS], et[TKS_MAX_TRANSITS], ey[TKS_MAX_TRANSITS];
    tks_xing xs[TKS_MAX_TRANSITS];
    int lower[TKS_MAX_TRANSITS];
    int nt, nx, i;
    int64_t first_rise;
    tks_body b;
    b.p = p;
    b.moon = 0;

    memset(d, 0, sizeof *d);
    d->magic = TKS_DAY_MAGIC;
    d->place = *p;
    d->days = days;
    d->start = start;
    d->end = end;
    d->day_length = -1;

    nt = tks_day_walk(aTHX_ &b, start, end, tt, lower, et, ey);
    for (i = 0; i < nt; i++)
        tks_day_add(d, lower[i] ? TKS_K_MIDNIGHT : TKS_K_NOON, tks_round_jd(tt[i]));
    nx = tks_day_cross(aTHX_ d, 0, nt, et, ey, xs);

    if (d->n[TKS_K_SUNRISE] == 0 && d->n[TKS_K_SUNSET] == 0) {
        if (tks_alt_at(aTHX_ &b, TKS_JD_EPOCH + (double)start / 86400.0, NULL) > tks_horizon(p))
            d->polar_day = 1;
        else
            d->polar_night = 1;
    }
    if (d->n[TKS_K_SUNRISE] > 0) {
        first_rise = tks_day_ev(d, TKS_K_SUNRISE, 0);
        for (i = 0; i < nx; i++) {
            if (xs[i].kind == TKS_K_SUNSET) {
                int64_t s = tks_round_jd(xs[i].t);
                if (s > first_rise) {
                    d->day_length = (int32_t)(s - first_rise);
                    break;
                }
            }
        }
    }
    else if (d->polar_day)
        d->day_length = (int32_t)(end - start);
}

/* A twilight depth (1 to 3, or 0), computed the first time it is asked for
 * and kept in the day. */
static void
tks_day_depth(pTHX_ tks_day *d, int k)
{
    double tt[TKS_MAX_TRANSITS], et[TKS_MAX_TRANSITS], ey[TKS_MAX_TRANSITS];
    int lower[TKS_MAX_TRANSITS];
    int nt;
    tks_body b;
    b.p = &d->place;
    b.moon = 0;
    if (d->done & (1u << k))
        return;
    nt = tks_day_walk(aTHX_ &b, d->start, d->end, tt, lower, et, ey);
    tks_day_cross(aTHX_ d, k, nt, et, ey, NULL);
}

/* Every depth, for events. */
static void
tks_day_all(pTHX_ tks_day *d)
{
    double tt[TKS_MAX_TRANSITS], et[TKS_MAX_TRANSITS], ey[TKS_MAX_TRANSITS];
    int lower[TKS_MAX_TRANSITS];
    int nt = -1, k;
    tks_body b;
    b.p = &d->place;
    b.moon = 0;
    for (k = 1; k < TKS_DEPTHS; k++) {
        if (d->done & (1u << k))
            continue;
        if (nt < 0)
            nt = tks_day_walk(aTHX_ &b, d->start, d->end, tt, lower, et, ey);
        tks_day_cross(aTHX_ d, k, nt, et, ey, NULL);
    }
}

/* The next (or previous) crossing of a depth by a body, rising or setting,
 * after (before) an instant, as a rounded epoch second: walks half days of
 * the body outward for up to 366 days and gives 0 when none is found. */
static int
tks_find_crossing_b(pTHX_ const tks_body *b, int64_t from, double h0, int rising, int backwards, int64_t *out)
{
    double j0 = TKS_JD_EPOCH + (double)from / 86400.0;
    double half = 180.0 / tks_body_rate(b), whole = 360.0 / tks_body_rate(b);
    double ta, tb, ya, yb, c, tr, prev_t, prev_y;
    int prev_lower, n;

    /* The first extremum: for a forward search the lower transit at or
     * before the instant, for a backward one the lower transit at or after. */
    tr = tks_transit(aTHX_ b, j0, 1);
    if (!backwards && tr > j0) tr = tks_transit(aTHX_ b, tr - whole, 1);
    if (backwards && tr < j0)  tr = tks_transit(aTHX_ b, tr + whole, 1);
    tks_extremum(aTHX_ b, tr, &prev_t, &prev_y);
    prev_lower = 1;
    for (n = 0; n < 2 * 366; n++) {
        double next_t, next_y;
        int next_lower = !prev_lower;
        double guess = prev_t + (backwards ? -half : half);
        tr = tks_transit(aTHX_ b, guess, next_lower);
        tks_extremum(aTHX_ b, tr, &next_t, &next_y);
        if (backwards) { ta = next_t; ya = next_y; tb = prev_t; yb = prev_y; }
        else           { ta = prev_t; ya = prev_y; tb = next_t; yb = next_y; }
        /* a half-day from a lower to an upper extremum rises */
        if ((yb > ya) == rising && tks_crossing(aTHX_ b, ta, ya, tb, yb, h0, &c)) {
            int64_t s = tks_round_jd(c);
            if ((!backwards && s > from) || (backwards && s < from)) {
                *out = s;
                return 1;
            }
        }
        prev_t = next_t;
        prev_y = next_y;
        prev_lower = next_lower;
    }
    return 0;
}

/* The sun's: a kind of 0.01's (sunrise, sunset, the twilights). */
static int
tks_find_crossing(pTHX_ const tks_place *p, int64_t from, int kind, int backwards, int64_t *out)
{
    tks_body b;
    b.p = p;
    b.moon = 0;
    return tks_find_crossing_b(aTHX_ &b, from, tks_depth(p, kind / 2), (kind % 2) == 0, backwards, out);
}

static tks_day *
tks_day_of(pTHX_ SV *sv, const char *what)
{
    SV *inner;
    tks_day *d;
    if (!sv || !SvROK(sv) || !sv_derived_from(sv, "Time::Keeper::Sun::Day"))
        croak("%s: not a Time::Keeper::Sun::Day", what);
    inner = SvRV(sv);
    if (!SvPOK(inner) || SvCUR(inner) != sizeof(tks_day))
        croak("%s: not a Time::Keeper::Sun::Day", what);
    /* the day is written to when a twilight is first asked for: a copy
     * that shares its buffer must have one of its own first */
#ifdef SvIsCOW
    if (SvIsCOW(inner))
        sv_force_normal_flags(inner, 0);
#endif
    d = (tks_day *)SvPVX(inner);
    if (d->magic != TKS_DAY_MAGIC)
        croak("%s: not a Time::Keeper::Sun::Day", what);
    return d;
}

#endif
