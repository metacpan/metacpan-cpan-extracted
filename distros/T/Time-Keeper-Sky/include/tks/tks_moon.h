#ifndef TKS_MOON_H
#define TKS_MOON_H

/* The moon's principal phases by chapter 49 (the mean phase, the periodic
 * corrections for new and full moons and for the quarters with the W term,
 * and the fourteen additional corrections), to a few seconds; the moon's
 * elongation, phase angle and illuminated fraction by the approximation 48.4
 * on the mean arguments of chapter 47, to about a tenth of a degree. The
 * tables are sources/meeus-49-terms.tsv. */

#define TKS_LUNATIONS_A_YEAR 12.3685
#define TKS_LUNATION_BROWN_AT_K0 953        /* the new moon of 2000 January 6 */

/* Lunation k's quarter: 0 new, 1 first, 2 full, 3 last. */
static int
tks_phase_which(double k)
{
    return (int)floor((k - floor(k)) * 4.0 + 0.5) % 4;
}

static const char *const tks_phase_kind_name[4] = { "new", "first_quarter", "full", "last_quarter" };

/* k of the phase of a quarter nearest a decimal year (49.2). */
static double
tks_phase_snap(double year, int which)
{
    double q = which / 4.0;
    double k = (year - 2000.0) * TKS_LUNATIONS_A_YEAR;
    return floor(k - q + 0.5) + q;
}

/* The JDE of the mean phase k (49.1). */
static double
tks_phase_mean_jde(double k)
{
    double T = k / 1236.85;
    return 2451550.09766 + 29.530588861 * k + T * T * (0.00015437 + T * (-0.00000015 + T * 0.00000000073));
}

static const double tks_nc[25] = {
    -0.40720, 0.17241, 0.01608, 0.01039, 0.00739, -0.00514, 0.00208, -0.00111, -0.00057, 0.00056,
    -0.00042, 0.00042, 0.00038, -0.00024, -0.00017, -0.00007, 0.00004, 0.00004, 0.00003, 0.00003,
    -0.00003, 0.00003, -0.00002, -0.00002, 0.00002,
};
static const double tks_fc[25] = {
    -0.40614, 0.17302, 0.01614, 0.01043, 0.00734, -0.00515, 0.00209, -0.00111, -0.00057, 0.00056,
    -0.00042, 0.00042, 0.00038, -0.00024, -0.00017, -0.00007, 0.00004, 0.00004, 0.00003, 0.00003,
    -0.00003, 0.00003, -0.00002, -0.00002, 0.00002,
};
static const double tks_ac[14] = {
    0.000325, 0.000165, 0.000164, 0.000126, 0.000110, 0.000062, 0.000060,
    0.000056, 0.000047, 0.000042, 0.000040, 0.000037, 0.000035, 0.000023,
};

/* The JDE (TT) of the true phase k. */
static double
tks_phase_jde(double k)
{
    int which = tks_phase_which(k);
    double T = k / 1236.85;
    double E  = 1.0 - T * (0.002516 + T * 0.0000074);
    double M  = tks_rad(tks_deg_norm(2.5534 + 29.10535670 * k + T * T * (-0.0000014 - T * 0.00000011)));
    double Mp = tks_rad(tks_deg_norm(201.5643 + 385.81693528 * k + T * T * (0.0107582 + T * (0.00001238 - T * 0.000000058))));
    double F  = tks_rad(tks_deg_norm(160.7108 + 390.67050284 * k + T * T * (-0.0016118 + T * (-0.00000227 + T * 0.000000011))));
    double Om = tks_rad(tks_deg_norm(124.7746 - 1.56375588 * k + T * T * (0.0020672 + T * 0.00000215)));
    double A[14], corr = 0.0, extra = 0.0;
    int i;

    A[0]  = 299.77 + 0.107408 * k - 0.009173 * T * T;
    A[1]  = 251.88 + 0.016321 * k;
    A[2]  = 251.83 + 26.651886 * k;
    A[3]  = 349.42 + 36.412478 * k;
    A[4]  = 84.66 + 18.206239 * k;
    A[5]  = 141.74 + 53.303771 * k;
    A[6]  = 207.14 + 2.453732 * k;
    A[7]  = 154.84 + 7.306860 * k;
    A[8]  = 34.52 + 27.261239 * k;
    A[9]  = 207.19 + 0.121824 * k;
    A[10] = 291.34 + 1.844379 * k;
    A[11] = 161.72 + 24.198154 * k;
    A[12] = 239.56 + 25.513099 * k;
    A[13] = 331.55 + 3.592518 * k;
    for (i = 0; i < 14; i++)
        extra += tks_ac[i] * sin(tks_rad(tks_deg_norm(A[i])));

    if (which == 0 || which == 2) {
        const double *c = which == 0 ? tks_nc : tks_fc;
        corr = c[0] * sin(Mp)
             + c[1] * sin(M) * E
             + c[2] * sin(2 * Mp)
             + c[3] * sin(2 * F)
             + c[4] * sin(Mp - M) * E
             + c[5] * sin(Mp + M) * E
             + c[6] * sin(2 * M) * E * E
             + c[7] * sin(Mp - 2 * F)
             + c[8] * sin(Mp + 2 * F)
             + c[9] * sin(2 * Mp + M) * E
             + c[10] * sin(3 * Mp)
             + c[11] * sin(M + 2 * F) * E
             + c[12] * sin(M - 2 * F) * E
             + c[13] * sin(2 * Mp - M) * E
             + c[14] * sin(Om)
             + c[15] * sin(Mp + 2 * M)
             + c[16] * sin(2 * (Mp - F))
             + c[17] * sin(3 * M)
             + c[18] * sin(Mp + M - 2 * F)
             + c[19] * sin(2 * (Mp + F))
             + c[20] * sin(Mp + M + 2 * F)
             + c[21] * sin(Mp - M + 2 * F)
             + c[22] * sin(Mp - M - 2 * F)
             + c[23] * sin(3 * Mp + M)
             + c[24] * sin(4 * Mp);
    }
    else {
        double w;
        corr = -0.62801 * sin(Mp)
             + 0.17172 * sin(M) * E
             - 0.01183 * sin(Mp + M) * E
             + 0.00862 * sin(2 * Mp)
             + 0.00804 * sin(2 * F)
             + 0.00454 * sin(Mp - M) * E
             + 0.00204 * sin(2 * M) * E * E
             - 0.00180 * sin(Mp - 2 * F)
             - 0.00070 * sin(Mp + 2 * F)
             - 0.00040 * sin(3 * Mp)
             - 0.00034 * sin(2 * Mp - M) * E
             + 0.00032 * sin(M + 2 * F) * E
             + 0.00032 * sin(M - 2 * F) * E
             - 0.00028 * sin(Mp + 2 * M) * E * E
             + 0.00027 * sin(2 * Mp + M) * E
             - 0.00017 * sin(Om)
             - 0.00005 * sin(Mp - M - 2 * F)
             + 0.00004 * sin(2 * Mp + 2 * F)
             - 0.00004 * sin(Mp + M + 2 * F)
             + 0.00004 * sin(Mp - 2 * M)
             + 0.00003 * sin(Mp + M - 2 * F)
             + 0.00003 * sin(3 * M)
             + 0.00002 * sin(2 * Mp - 2 * F)
             + 0.00002 * sin(Mp - M + 2 * F)
             - 0.00002 * sin(3 * Mp + M);
        w = 0.00306 - 0.00038 * E * cos(M) + 0.00026 * cos(Mp)
          - 0.00002 * (cos(Mp - M) - cos(Mp + M) - cos(2 * F));
        corr += which == 1 ? w : -w;
    }
    return tks_phase_mean_jde(k) + corr + extra;
}

/* The instant of phase k in UT, rounded to the second: Delta T at the
 * phase itself, which one pass settles. */
static int64_t
tks_phase_instant(pTHX_ double k)
{
    double jde = tks_phase_jde(k);
    time_keeper_instant t;
    tks_instant_from_jd(jde, &t);
    return tks_round_jd(jde - tks_delta_t(aTHX_ &t) / 86400.0);
}

/* The k of the last new moon at or before an instant: the estimate from
 * the year is off by one either way near a phase, so three are tried. */
static double
tks_new_moon_before(pTHX_ int64_t sec)
{
    double jd = TKS_JD_EPOCH + (double)sec / 86400.0;
    double k = floor((tks_decimal_year(jd) - 2000.0) * TKS_LUNATIONS_A_YEAR);
    k += 1.0;
    while (tks_phase_instant(aTHX_ k) > sec)
        k -= 1.0;
    while (tks_phase_instant(aTHX_ k + 1.0) <= sec)
        k += 1.0;
    return k;
}

/* The moon at an instant: elongation from the sun (degrees, 0 new to 360),
 * phase angle (0 full to 180 new), illuminated fraction, age in days, the
 * lunation, and the name by eighths of the elongation. */
typedef struct tks_moon {
    double elongation, phase_angle, illumination, age;
    double k_new;                       /* the last new moon's k */
    int    name;                        /* 0 new .. 7 waning_crescent */
} tks_moon;

static const char *const tks_moon_name[8] = {
    "new", "waxing_crescent", "first_quarter", "waxing_gibbous",
    "full", "waning_gibbous", "last_quarter", "waning_crescent",
};

static void
tks_moon_angles(double jde, double *elongation)
{
    double T = tks_T(jde);
    double D  = tks_rad(tks_deg_norm(297.8501921 + T * (445267.1114034 + T * (-0.0018819 + T * (1.0 / 545868.0 - T / 113065000.0)))));
    double M  = tks_rad(tks_deg_norm(357.5291092 + T * (35999.0502909 + T * (-0.0001536 + T / 24490000.0))));
    double Mp = tks_rad(tks_deg_norm(134.9633964 + T * (477198.8675055 + T * (0.0087414 + T * (1.0 / 69699.0 - T / 14712000.0)))));
    *elongation = tks_deg_norm(tks_deg(D)
                  + 6.289 * sin(Mp) - 2.100 * sin(M) + 1.274 * sin(2 * D - Mp)
                  + 0.658 * sin(2 * D) + 0.214 * sin(2 * Mp) + 0.110 * sin(D));
}

#define TKS_AU_KM 149597870.7

/* The elongation in longitude (0 to 360, under 180 waxing) and the phase
 * angle (0 full to 180 new), degrees, from the moon's and the sun's
 * apparent places: 48.2 for the angle between them, 48.3 for the phase
 * angle, which counts the moon's latitude and both distances. */
static double
tks_moon_phase_angle(const tks_moonplace *mp, const tks_sunpos *s)
{
    double b = tks_rad(mp->lat);
    double dl = tks_rad(mp->lon - s->lon);
    double cpsi = cos(b) * cos(dl);
    double psi = acos(cpsi > 1.0 ? 1.0 : cpsi < -1.0 ? -1.0 : cpsi);
    double R = s->R * TKS_AU_KM;
    return tks_deg(atan2(R * sin(psi), mp->distance - R * cpsi));
}

/* The position angle of the moon's bright limb (48.5), degrees from the
 * north point of the disc through the east, 0 to 360: the direction of the
 * sun from the moon, from both apparent places. */
static double
tks_bright_limb(double ra0, double dec0, double ra, double dec)
{
    double d0 = tks_rad(dec0), d = tks_rad(dec), da = tks_rad(ra0 - ra);
    return tks_deg_norm(tks_deg(atan2(cos(d0) * sin(da), sin(d0) * cos(d) - cos(d0) * sin(d) * cos(da))));
}

/* The parallactic angle (14.1), degrees, -180 to 180: the angle at the body
 * between the direction of the celestial pole and that of the zenith, from
 * the latitude, the hour angle and the declination. 0 on the meridian,
 * positive west of it in the northern sky. */
static double
tks_parallactic_angle(double lat, double H, double dec)
{
    double phi = tks_rad(lat), h = tks_rad(H), d = tks_rad(dec);
    return tks_deg(atan2(sin(h), tan(phi) * cos(d) - sin(d) * cos(h)));
}

static void
tks_moon_exact(double jde, double *elongation, double *phase_angle)
{
    tks_moonplace mp;
    tks_sunpos s;
    tks_moon_place(jde, &mp);
    tks_sun_place(jde, &s);
    *phase_angle = tks_moon_phase_angle(&mp, &s);
    *elongation = tks_deg_norm(mp.lon - s.lon);
}

static void
tks_moon_at(pTHX_ const time_keeper_instant *t, tks_moon *m)
{
    double jde = tks_jde(aTHX_ t);
    double e, i;
    tks_moon_exact(jde, &e, &i);
    m->elongation = e;
    m->phase_angle = i;
    m->illumination = (1.0 + cos(tks_rad(i))) / 2.0;
    m->k_new = tks_new_moon_before(aTHX_ t->sec);
    m->age = ((double)t->sec + (double)t->nsec / 1e9 - (double)tks_phase_instant(aTHX_ m->k_new)) / 86400.0;
    m->name = (int)floor(tks_deg_norm(e + 22.5) / 45.0) % 8;
}

/* The principal phases from one instant to another, in order, into an
 * array of (k, instant); the count, at most max. */
typedef struct tks_phase_row {
    double  k;
    int64_t sec;
} tks_phase_row;

static int
tks_phases_between(pTHX_ int64_t from, int64_t to, tks_phase_row *out, int max)
{
    double jd = TKS_JD_EPOCH + (double)from / 86400.0;
    double k = floor((tks_decimal_year(jd) - 2000.0) * TKS_LUNATIONS_A_YEAR) - 2.0;
    int n = 0;
    for (;;) {
        int64_t s = tks_phase_instant(aTHX_ k);
        if (s > to)
            break;
        if (s >= from) {
            if (n == max)
                break;
            out[n].k = k;
            out[n].sec = s;
            n++;
        }
        k += 0.25;
    }
    return n;
}

/* The first phase of a quarter (or of any, which = -1) strictly after an
 * instant, or the last strictly before it. */
static void
tks_phase_next(pTHX_ int64_t from, int which, int backwards, double *k_out, int64_t *sec_out)
{
    double jd = TKS_JD_EPOCH + (double)from / 86400.0;
    double k = floor((tks_decimal_year(jd) - 2000.0) * TKS_LUNATIONS_A_YEAR) + (backwards ? 2.0 : -2.0);
    double step = backwards ? -0.25 : 0.25;
    for (;;) {
        int64_t s = tks_phase_instant(aTHX_ k);
        if ((which < 0 || tks_phase_which(k) == which)
            && ((!backwards && s > from) || (backwards && s < from))) {
            *k_out = k;
            *sec_out = s;
            return;
        }
        k += step;
    }
}

/* ---- a day ---------------------------------------------------------------- */

#define TKS_MOONDAY_MAGIC 0x54534b4du

typedef struct tks_moonday {
    uint32_t  magic;
    tks_place place;                    /* only its zone, locale and names are used */
    int64_t   days, start, end, noon;
    int       name;                     /* 0..7 */
    int       principal;                /* 0..3, or -1 */
    int64_t   principal_sec;
    double    illumination, age;
    uint8_t   has_place;                /* made with place =>, so the moon's rise can be asked */
    uint8_t   mn[3];                    /* how many moonrises, moonsets, upper transits in the window (two kept) */
    uint8_t   up_all, down_all;         /* the moon neither rose nor set, and was up, or down, throughout */
    int32_t   mev[3][2];                /* their seconds after start, in order */
} tks_moonday;

/* Whether a second lies in the day's window: the start is in, the end is the
 * next day's. */
static int
tks_moonday_in(const tks_moonday *d, int64_t sec)
{
    return sec >= d->start && sec < d->end;
}

static const tks_moonday *
tks_moonday_of(pTHX_ SV *sv, const char *what)
{
    SV *inner;
    const tks_moonday *d;
    if (!sv || !SvROK(sv) || !sv_derived_from(sv, "Time::Keeper::Moon::Day"))
        croak("%s: not a Time::Keeper::Moon::Day", what);
    inner = SvRV(sv);
    if (!SvPOK(inner) || SvCUR(inner) != sizeof(tks_moonday))
        croak("%s: not a Time::Keeper::Moon::Day", what);
    d = (const tks_moonday *)SvPVX(inner);
    if (d->magic != TKS_MOONDAY_MAGIC)
        croak("%s: not a Time::Keeper::Moon::Day", what);
    return d;
}

/* The day: the principal phase in the window if there is one, else the
 * intermediate name between the last principal phase before noon and the
 * next; the fraction and the age at local noon. */
static void
tks_moonday_compute(pTHX_ const tks_place *p, int64_t days, int64_t start, int64_t end, int64_t noon, tks_moonday *d)
{
    tks_phase_row rows[4];
    int n;
    time_keeper_instant t;
    tks_moon m;
    double k;
    int64_t s;

    memset(d, 0, sizeof *d);
    d->magic = TKS_MOONDAY_MAGIC;
    d->place = *p;
    d->days = days;
    d->start = start;
    d->end = end;
    d->noon = noon;
    t.sec = noon;
    t.nsec = 0;
    tks_moon_at(aTHX_ &t, &m);
    d->illumination = m.illumination;
    d->age = m.age;
    n = tks_phases_between(aTHX_ start, end, rows, 4);
    if (n > 0 && !tks_moonday_in(d, rows[0].sec))
        n = 0;
    if (n > 0) {
        d->principal = tks_phase_which(rows[0].k);
        d->principal_sec = rows[0].sec;
        d->name = d->principal * 2;
    }
    else {
        d->principal = -1;
        tks_phase_next(aTHX_ noon, -1, 1, &k, &s);
        d->name = tks_phase_which(k) * 2 + 1;
    }
}

#endif

#ifndef TKS_MOONRISE_H
#define TKS_MOONRISE_H

/* The moon's rises, sets and transits on a civil day, from a place: the
 * engine of the sun's day with the moon as its body. */

#define TKS_M_RISE    0
#define TKS_M_SET     1
#define TKS_M_TRANSIT 2

static const char *const tks_moon_event_name[3] = { "moonrise", "moonset", "moon_transit" };

/* The depth of the horizon for the moon's upper limb (T2): refraction's 34
 * arcminutes and, from a height, the dip and its refraction term; the
 * semidiameter and the parallax are in the moon's altitude itself. */
static double
tks_moon_horizon(const tks_place *p)
{
    double h = p->elev;
    double dip = tks_deg(acos(TKS_EARTH_RADIUS / (TKS_EARTH_RADIUS + h)));
    return -(34.0 / 60.0 + dip + (19.0 / 3600.0) * sqrt(h));
}

static void
tks_moonday_add(tks_moonday *d, int kind, int64_t sec)
{
    if (!tks_moonday_in(d, sec))
        return;
    if (d->mn[kind] < 2)
        d->mev[kind][d->mn[kind]] = (int32_t)(sec - d->start);
    if (d->mn[kind] < 255)
        d->mn[kind]++;
}

static void
tks_moonday_rise(pTHX_ tks_moonday *d)
{
    double tt[TKS_MAX_TRANSITS], et[TKS_MAX_TRANSITS], ey[TKS_MAX_TRANSITS];
    int lower[TKS_MAX_TRANSITS];
    double h0 = tks_moon_horizon(&d->place);
    tks_body b;
    int nt, i;
    tks_moon_body(&d->place, &b);
    nt = tks_day_walk(aTHX_ &b, d->start, d->end, tt, lower, et, ey);
    for (i = 0; i < nt; i++)
        if (!lower[i])
            tks_moonday_add(d, TKS_M_TRANSIT, tks_round_jd(tt[i]));
    for (i = 0; i + 1 < nt; i++) {
        double c;
        if (tks_crossing(aTHX_ &b, et[i], ey[i], et[i + 1], ey[i + 1], h0, &c))
            tks_moonday_add(d, ey[i] < ey[i + 1] ? TKS_M_RISE : TKS_M_SET, tks_round_jd(c));
    }
    if (d->mn[TKS_M_RISE] == 0 && d->mn[TKS_M_SET] == 0) {
        if (tks_alt_at(aTHX_ &b, TKS_JD_EPOCH + (double)d->start / 86400.0, NULL) > h0)
            d->up_all = 1;
        else
            d->down_all = 1;
    }
}

/* The moon's next (or previous) rise or set from an instant. */
static int
tks_moon_find(pTHX_ const tks_place *p, int64_t from, int set, int backwards, int64_t *out)
{
    tks_body b;
    tks_moon_body(p, &b);
    return tks_find_crossing_b(aTHX_ &b, from, tks_moon_horizon(p), !set, backwards, out);
}

/* The moon's next (or previous) upper transit from an instant. */
static int64_t
tks_moon_transit_find(pTHX_ const tks_place *p, int64_t from, int backwards)
{
    tks_body b;
    double j0 = TKS_JD_EPOCH + (double)from / 86400.0, tr, whole = 360.0 / TKS_MOON_RATE;
    int64_t out;
    tks_moon_body(p, &b);
    tr = tks_transit(aTHX_ &b, j0, 0);
    out = tks_round_jd(tr);
    if (!backwards && out <= from) out = tks_round_jd(tks_transit(aTHX_ &b, tr + whole, 0));
    if (backwards && out >= from)  out = tks_round_jd(tks_transit(aTHX_ &b, tr - whole, 0));
    return out;
}

#endif
