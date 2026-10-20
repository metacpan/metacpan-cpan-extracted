#ifndef TKS_TONIGHT_H
#define TKS_TONIGHT_H

/* Any body by name, and tonight. A body is the sun, the moon, a planet
 * (mercury to pluto, not the earth) or a star of the Bright Star Catalogue
 * by what Time::Keeper::Star->find takes; the generic methods hand a body
 * other than the sun to its own class with place => the Sky. Tonight is
 * the night from a date's civil dusk to the next civil dawn, and what is
 * up in it: each body's altitude sampled every two minutes, the moments it
 * passes the minimum altitude and its greatest altitude refined from the
 * exact places. */

#define TKS_B_SUN    0
#define TKS_B_MOON   1
#define TKS_B_PLANET 2
#define TKS_B_STAR   3

static const char *const tks_body_kind_name[4] = { "sun", "moon", "planet", "star" };
static const char *const tks_body_class[4] = {
    "Time::Keeper::Sky", "Time::Keeper::Moon", "Time::Keeper::Planet", "Time::Keeper::Star",
};

/* A body's kind from its name, and the planet's index or the star's row.
 * Where a call's shape only might have a body, usage is what the call
 * takes without one, and an unknown name dies with it first. */
static int
tks_body_kind_arg(pTHX_ SV *sv, int *idx, const char *what, const char *usage)
{
    STRLEN len;
    const char *s;
    int i, row;
    if (sv)
        SvGETMAGIC(sv);
    if (!sv || !SvOK(sv))
        croak("%s needs a body: sun, moon, a planet or a star", what);
    *idx = -1;
    if (!SvROK(sv) && !SvIOK(sv) && !SvNOK(sv)) {
        s = SvPV_nomg(sv, len);
        if (tks_ci_eq(s, len, "sun"))
            return TKS_B_SUN;
        if (tks_ci_eq(s, len, "moon"))
            return TKS_B_MOON;
        for (i = 0; i < TKS_BODIES; i++)
            if (i != TKS_EARTH && tks_ci_eq(s, len, tks_planet_name[i])) {
                *idx = i;
                return TKS_B_PLANET;
            }
    }
    if (!SvROK(sv)) {
        row = tks_star_row_arg(aTHX_ sv, 0, what);
        if (row >= 0) {
            *idx = row;
            return TKS_B_STAR;
        }
    }
    s = SvPV_nomg(sv, len);
    if (usage)
        croak("%s, or a body first: no body is called '%.*s'", usage, (int)len, s);
    croak("%s: no body is called '%.*s' (sun, moon, a planet, or a star by name, designation or HR number)",
          what, (int)len, s);
    return -1;
}

/* Class->method(before, the body's name, after, the caller's ST(first) to
 * ST(last - 1), place => place) for a moon, planet or star, in scalar
 * context; the result with a reference count the caller owns. The moon
 * takes no name; a planet's is passed in lower case, a star's as given. */
static SV *
tks_body_call(pTHX_ int kind, int idx, SV *body, const char *method, SV *before, SV *after,
              I32 ax, int first, int last, SV *place)
{
    dSP;
    SV *ret;
    int i, count;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 6 + (last > first ? last - first : 0));
    PUSHs(sv_2mortal(newSVpv(tks_body_class[kind], 0)));
    if (before)
        PUSHs(before);
    if (kind == TKS_B_PLANET)
        PUSHs(sv_2mortal(newSVpv(tks_planet_name[idx], 0)));
    else if (kind == TKS_B_STAR)
        PUSHs(body);
    if (after)
        PUSHs(after);
    for (i = first; i < last; i++)
        PUSHs(PL_stack_base[ax + i]);
    PUSHs(sv_2mortal(newSVpvs("place")));
    PUSHs(place);
    PUTBACK;
    count = call_method(method, G_SCALAR);
    SPAGAIN;
    ret = count ? newSVsv(POPs) : newSV(0);
    PUTBACK;
    FREETMPS;
    LEAVE;
    return ret;
}

/* ---- the night ----------------------------------------------------------- */

#define TKS_N_NIGHT       0
#define TKS_N_POLAR_NIGHT 1
#define TKS_N_WHITE_NIGHT 2
#define TKS_N_POLAR_DAY   3

static const char *const tks_night_kind_name[4] = { "night", "polar_night", "white_night", "polar_day" };

typedef struct tks_night {
    int     kind;
    int64_t start, end;         /* the dark span, when kind is night or polar_night */
    int64_t w0, w1;             /* the window: the date's noon to the next */
} tks_night;

/* The middle of a civil day in the place's zone: halfway between its
 * midnights, so a day of 23 or 25 hours has its noon where it falls. */
static int64_t
tks_civil_noon(pTHX_ const tks_place *p, int64_t days, const char *what)
{
    int64_t a = tks_midnight(aTHX_ p, days, what), b = tks_midnight(aTHX_ p, days + 1, what);
    return a + (b - a) / 2;
}

/* The night of a date: in the window from its noon to the next day's, the
 * first span with the sun's centre below -6 degrees (civil dusk to civil
 * dawn). Dark all the window is a polar night, and the window is the
 * night; never dark, a white night if the sun sets in it and polar day if
 * it does not. */
static void
tks_night_of(pTHX_ const tks_place *p, int64_t days, tks_night *n, const char *what)
{
    double tt[TKS_MAX_TRANSITS], et[TKS_MAX_TRANSITS], ey[TKS_MAX_TRANSITS];
    int lower[TKS_MAX_TRANSITS];
    tks_xing xs[TKS_MAX_TRANSITS];
    time_keeper_instant t;
    tks_body b;
    int nt, nx, i, started, ended = 0;
    double alt0;

    n->w0 = tks_civil_noon(aTHX_ p, days, what);
    n->w1 = tks_civil_noon(aTHX_ p, days + 1, what);
    t.sec = n->w0; t.nsec = 0;
    tks_year_check(aTHX_ &t, what);
    t.sec = n->w1;
    tks_year_check(aTHX_ &t, what);
    b.p = p;
    b.moon = 0;
    alt0 = tks_alt_at(aTHX_ &b, TKS_JD_EPOCH + (double)n->w0 / 86400.0, NULL);
    nt = tks_day_walk(aTHX_ &b, n->w0, n->w1, tt, lower, et, ey);
    nx = tks_walk_crossings(aTHX_ &b, -6.0, nt, et, ey, xs);
    started = alt0 < -6.0;
    n->start = n->w0;
    n->end = n->w1;
    for (i = 0; i < nx; i++) {
        int64_t s = tks_round_jd(xs[i].t);
        if (s <= n->w0)
            continue;
        if (s >= n->w1)
            break;
        if (!started && xs[i].kind == 1) {
            n->start = s;
            started = 1;
        }
        else if (started && xs[i].kind == 0) {
            n->end = s;
            ended = 1;
            break;
        }
    }
    if (started) {
        n->kind = n->start == n->w0 && !ended ? TKS_N_POLAR_NIGHT : TKS_N_NIGHT;
        return;
    }
    n->start = n->end = 0;
    nx = tks_walk_crossings(aTHX_ &b, tks_horizon(p), nt, et, ey, xs);
    n->kind = TKS_N_POLAR_DAY;
    if (alt0 < tks_horizon(p))
        n->kind = TKS_N_WHITE_NIGHT;
    for (i = 0; i < nx; i++) {
        int64_t s = tks_round_jd(xs[i].t);
        if (s > n->w0 && s < n->w1)
            n->kind = TKS_N_WHITE_NIGHT;
    }
}

/* ---- tonight --------------------------------------------------------------- */

#define TKS_TN_STEP 120                 /* seconds between samples */

typedef struct tks_tn_body {
    int kind, idx;
    double ra, dec;                     /* a star's, at the night's middle */
} tks_tn_body;

/* A body's topocentric geometric altitude and azimuth at a JD (UT), from
 * its exact place (a star's from the night's middle: its apparent place
 * moves under an arcsecond in a night); the apparent right ascension and
 * declination (the moon's and a planet's geocentric) for the
 * constellation. */
static double
tks_tn_alt(pTHX_ const tks_place *p, const tks_tn_body *b, double jd, double *az, double *ra, double *dec)
{
    time_keeper_instant t;
    double jde, theta, alt, a, H, Ht;
    tks_instant_from_jd(jd, &t);
    jde = jd + tks_delta_t(aTHX_ &t) / 86400.0;
    theta = tks_sidereal_apparent(jd, jde);
    if (b->kind == TKS_B_MOON) {
        tks_moonview v;
        tks_moon_place(jde, &v.m);
        tks_moon_seen(p, theta, &v);
        alt = v.alt; a = v.az;
        if (ra) { *ra = v.m.ra; *dec = v.m.dec; }
    }
    else if (b->kind == TKS_B_PLANET) {
        tks_planetpos pp;
        double app;
        tks_planet_compute(b->idx, jde, &pp, 0);
        tks_planet_seen(p, theta, &pp, &alt, &app, &a, &Ht);
        if (ra) { *ra = pp.ra; *dec = pp.dec; }
    }
    else {
        tks_altaz_theta(theta, p->lat, p->lon, b->ra, b->dec, &alt, &a, &H);
        if (ra) { *ra = b->ra; *dec = b->dec; }
    }
    if (az)
        *az = a;
    return alt;
}

/* Quadratic interpolation (3.3) through three values at n = -1, 0, 1. */
static double
tks_interp3(double y1, double y2, double y3, double n)
{
    double a = y2 - y1, b = y3 - y2, c = b - a;
    return y2 + n / 2.0 * (a + b + n * c);
}

/* Where between two samples the altitude crosses h: bisection to a second. */
static double
tks_tn_cross(pTHX_ const tks_place *p, const tks_tn_body *b, double lo, double hi, double h)
{
    int above_lo = tks_tn_alt(aTHX_ p, b, lo, NULL, NULL, NULL) >= h;
    while (hi - lo > 0.5 / 86400.0) {
        double mid = 0.5 * (lo + hi);
        if ((tks_tn_alt(aTHX_ p, b, mid, NULL, NULL, NULL) >= h) == above_lo)
            lo = mid;
        else
            hi = mid;
    }
    return 0.5 * (lo + hi);
}

/* The greatest altitude between two JDs, by golden section to a second. */
static double
tks_tn_peak(pTHX_ const tks_place *p, const tks_tn_body *b, double a, double c)
{
    const double g = 0.6180339887498949;
    double x = c - g * (c - a), y = a + g * (c - a);
    double fx = tks_tn_alt(aTHX_ p, b, x, NULL, NULL, NULL), fy = tks_tn_alt(aTHX_ p, b, y, NULL, NULL, NULL);
    while (c - a > 0.5 / 86400.0) {
        if (fx > fy) { c = y; y = x; fy = fx; x = c - g * (c - a); fx = tks_tn_alt(aTHX_ p, b, x, NULL, NULL, NULL); }
        else         { a = x; x = y; fx = fy; y = a + g * (c - a); fy = tks_tn_alt(aTHX_ p, b, y, NULL, NULL, NULL); }
    }
    return 0.5 * (a + c);
}

/* One body's night: whether it is listed, and its best moment, the first
 * and last moments at or above the minimum (epoch seconds). Altitudes are
 * sampled every TKS_TN_STEP from the night's start to its end; the moon's
 * exactly, a planet's from its place at the start, middle and end
 * interpolated, a star's from its place at the middle. The crossings of the
 * minimum and the greatest altitude are then refined from the exact place. */
static int
tks_tn_body_night(pTHX_ const tks_place *p, tks_tn_body *b, const tks_night *n, int ns,
                  const double *jd, const double *theta, double minimum,
                  int64_t *best, int64_t *from, int64_t *until)
{
    double pra[3], pdec[3], pdel[3], amax = -91.0, above = 0.0, seg_start = 0.0;
    double jd0 = jd[0], jd1 = jd[ns - 1], first = -1.0, last = -1.0;
    int i, kmax = 0, in = 0;

    if (b->kind == TKS_B_PLANET) {
        for (i = 0; i < 3; i++) {
            time_keeper_instant t;
            tks_planetpos pp;
            double j = jd0 + 0.5 * i * (jd1 - jd0);
            tks_instant_from_jd(j, &t);
            tks_planet_compute(b->idx, j + tks_delta_t(aTHX_ &t) / 86400.0, &pp, 0);
            pra[i] = pp.ra; pdec[i] = pp.dec; pdel[i] = pp.delta;
        }
        if (pra[0] - pra[1] > 180.0) pra[0] -= 360.0;
        if (pra[1] - pra[0] > 180.0) pra[0] += 360.0;
        if (pra[2] - pra[1] > 180.0) pra[2] -= 360.0;
        if (pra[1] - pra[2] > 180.0) pra[2] += 360.0;
    }
    for (i = 0; i < ns; i++) {
        double alt, az, Ht, app;
        if (b->kind == TKS_B_PLANET) {
            tks_planetpos pp;
            double x = jd1 > jd0 ? 2.0 * (jd[i] - jd0) / (jd1 - jd0) - 1.0 : 0.0;
            pp.ra = tks_deg_norm(tks_interp3(pra[0], pra[1], pra[2], x));
            pp.dec = tks_interp3(pdec[0], pdec[1], pdec[2], x);
            pp.delta = tks_interp3(pdel[0], pdel[1], pdel[2], x);
            tks_planet_seen(p, theta[i], &pp, &alt, &app, &az, &Ht);
        }
        else if (b->kind == TKS_B_STAR) {
            double H;
            tks_altaz_theta(theta[i], p->lat, p->lon, b->ra, b->dec, &alt, &az, &H);
        }
        else
            alt = tks_tn_alt(aTHX_ p, b, jd[i], NULL, NULL, NULL);
        if (alt > amax) {
            amax = alt;
            kmax = i;
        }
        if ((alt >= minimum) != in) {
            double c = i == 0 ? jd[0] : tks_tn_cross(aTHX_ p, b, jd[i - 1], jd[i], minimum);
            if (!in) {
                seg_start = c;
                if (first < 0.0)
                    first = c;
            }
            else {
                above += c - seg_start;
                last = c;
            }
            in = !in;
        }
    }
    if (in) {
        above += jd[ns - 1] - seg_start;
        last = jd[ns - 1];
    }
    if (first < 0.0 || above * 86400.0 < 1800.0 - 0.5)
        return 0;
    {
        /* between the samples either side, the night's ends closing it: a
         * peak just inside an end lies between it and the next sample */
        double t = tks_tn_peak(aTHX_ p, b, jd[kmax > 0 ? kmax - 1 : 0], jd[kmax < ns - 1 ? kmax + 1 : ns - 1]);
        *best = tks_round_jd(t);
        if (*best < n->start) *best = n->start;
        if (*best > n->end) *best = n->end;
    }
    *from = tks_round_jd(first);
    *until = tks_round_jd(last);
    if (*from < n->start) *from = n->start;
    if (*until > n->end) *until = n->end;
    if (tks_tn_alt(aTHX_ p, b, TKS_JD_EPOCH + (double)*best / 86400.0, NULL, NULL, NULL) < minimum)
        return 0;
    return 1;
}

typedef struct tks_tn_row {
    int64_t best;
    SV *hv;
    SV *name;
} tks_tn_row;

static int
tks_tn_row_cmp(const void *a, const void *b)
{
    const tks_tn_row *x = (const tks_tn_row *)a, *y = (const tks_tn_row *)b;
    if (x->best != y->best)
        return x->best < y->best ? -1 : 1;
    {
        dTHX;
        return sv_cmp(x->name, y->name);
    }
}

/* What is up tonight: an array of hashrefs, in order of each one's best
 * moment, pushed into out. */
static void
tks_tonight(pTHX_ const tks_place *p, const tks_night *n, double minimum, double maglimit, AV *out)
{
    double *jd, *theta;
    tks_tn_row *rows;
    int ns, nrows = 0, cap, i, nstars;
    int64_t span = n->end - n->start;
    double jdm;

    ns = (int)(span / TKS_TN_STEP) + 1;
    if ((int64_t)(ns - 1) * TKS_TN_STEP < span)
        ns++;
    Newx(jd, ns, double);
    SAVEFREEPV(jd);
    Newx(theta, ns, double);
    SAVEFREEPV(theta);
    for (i = 0; i < ns; i++) {
        time_keeper_instant t;
        int64_t s = n->start + (int64_t)i * TKS_TN_STEP;
        if (s > n->end)
            s = n->end;
        jd[i] = TKS_JD_EPOCH + (double)s / 86400.0;
        t.sec = s; t.nsec = 0;
        theta[i] = tks_sidereal_apparent(jd[i], jd[i] + tks_delta_t(aTHX_ &t) / 86400.0);
    }
    for (nstars = 0; nstars < TKS_STARS && tks_bsc5[nstars].vmag <= maglimit; nstars++)
        ;
    cap = 1 + 7 + nstars;
    Newxz(rows, cap, tks_tn_row);
    SAVEFREEPV(rows);

    jdm = 0.5 * (jd[0] + jd[ns - 1]);
    {
        tks_starframe f;
        time_keeper_instant t;
        tks_instant_from_jd(jdm, &t);
        tks_starframe_at(jdm + tks_delta_t(aTHX_ &t) / 86400.0, &f);
        for (i = -8; i < nstars; i++) {
            tks_tn_body b;
            int64_t best, from, until;
            if (i < -7) { b.kind = TKS_B_MOON; b.idx = -1; }
            else if (i < 0) {
                b.kind = TKS_B_PLANET;
                b.idx = i + 7 >= TKS_EARTH ? i + 8 : i + 7;          /* mercury, venus, mars .. neptune */
            }
            else {
                b.kind = TKS_B_STAR;
                b.idx = i;
                tks_star_apparent(&tks_bsc5[i], &f, &b.ra, &b.dec);
            }
            if (!tks_tn_body_night(aTHX_ p, &b, n, ns, jd, theta, minimum, &best, &from, &until))
                continue;
            {
                HV *hv = newHV();
                double bjd = TKS_JD_EPOCH + (double)best / 86400.0, az, ra, dec, alt, jde;
                time_keeper_instant t;
                SV *name;
                t.sec = best; t.nsec = 0;
                jde = tks_jde(aTHX_ &t);
                if (b.kind == TKS_B_STAR) {
                    tks_starframe g;
                    tks_starframe_at(jde, &g);
                    tks_star_apparent(&tks_bsc5[i], &g, &b.ra, &b.dec);
                }
                alt = tks_tn_alt(aTHX_ p, &b, bjd, &az, &ra, &dec);
                name = b.kind == TKS_B_MOON ? newSVpvs("moon")
                     : b.kind == TKS_B_PLANET ? newSVpv(tks_planet_name[b.idx], 0)
                     : tks_star_name_sv(aTHX_ b.idx);
                (void)hv_stores(hv, "body", name);
                (void)hv_stores(hv, "kind", newSVpv(tks_body_kind_name[b.kind], 0));
                (void)hv_stores(hv, "best", tks_value_sv(aTHX_ p, best));
                (void)hv_stores(hv, "from", tks_value_sv(aTHX_ p, from));
                (void)hv_stores(hv, "until", tks_value_sv(aTHX_ p, until));
                (void)hv_stores(hv, "altitude", newSVnv(alt));
                (void)hv_stores(hv, "apparent_altitude", newSVnv(alt + tks_refraction(alt) / 60.0));
                (void)hv_stores(hv, "azimuth", newSVnv(az));
                (void)hv_stores(hv, "constellation", newSVpv(tks_cons_names[tks_constellation_at(aTHX_ ra, dec, jde)][0], 0));
                if (b.kind == TKS_B_MOON) {
                    double e, ph;
                    tks_moon_exact(jde, &e, &ph);
                    (void)hv_stores(hv, "magnitude", newSV(0));
                    (void)hv_stores(hv, "illumination", newSVnv((1.0 + cos(tks_rad(ph))) / 2.0));
                }
                else if (b.kind == TKS_B_PLANET) {
                    tks_planetpos pp;
                    tks_planet_at(b.idx, jde, &pp);
                    (void)hv_stores(hv, "magnitude", Perl_isnan(pp.magnitude) ? newSV(0) : newSVnv(pp.magnitude));
                    (void)hv_stores(hv, "illumination", newSVnv(pp.illumination));
                }
                else {
                    (void)hv_stores(hv, "magnitude", newSVnv(tks_nv_of(aTHX_ tks_bsc5[b.idx].vmag)));
                    (void)hv_stores(hv, "hr", newSViv(tks_bsc5[b.idx].hr));
                }
                rows[nrows].best = best;
                rows[nrows].hv = newRV_noinc((SV *)hv);
                rows[nrows].name = name;
                nrows++;
            }
        }
    }
    qsort(rows, nrows, sizeof *rows, tks_tn_row_cmp);
    for (i = 0; i < nrows; i++)
        av_push(out, rows[i].hv);
}

#endif
