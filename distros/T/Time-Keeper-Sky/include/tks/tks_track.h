#ifndef TKS_TRACK_H
#define TKS_TRACK_H

/* Tracks: the sun's or the moon's place at every step from one instant to
 * another, into flat arrays, with the sub-point (where the body is
 * overhead) at each. Every sample is what position gives at that instant,
 * to the bit: the same functions on the same Julian days, with the
 * sidereal time and the Delta T read once a sample instead of once a
 * function. */

#define TKS_TRACK_MAX      20000
#define TKS_TRACK_STEP_MAX 86400

typedef struct tks_track_sv {
    SV *from, *to, *step, *place;
} tks_track_sv;

/* from =>, to =>, step => (and place => where the caller takes it) from a
 * list of name and value pairs. */
static void
tks_track_args(pTHX_ SV **args, int n, tks_track_sv *a, int with_place, const char *what)
{
    int i;
    a->from = a->to = a->step = a->place = NULL;
    if (n % 2)
        croak("%s takes name and value pairs: from, to, step%s", what, with_place ? ", place" : "");
    for (i = 0; i < n; i += 2) {
        STRLEN klen;
        const char *k;
        SvGETMAGIC(args[i]);
        k = SvPV_nomg(args[i], klen);
        SvGETMAGIC(args[i + 1]);
        if (klen == 4 && memEQ(k, "from", 4)) a->from = args[i + 1];
        else if (klen == 2 && memEQ(k, "to", 2)) a->to = args[i + 1];
        else if (klen == 4 && memEQ(k, "step", 4)) a->step = args[i + 1];
        else if (with_place && klen == 5 && memEQ(k, "place", 5)) a->place = args[i + 1];
        else croak("%s: unknown argument '%.*s'", what, (int)klen, k);
    }
    if (!a->from)
        croak("%s needs from =>", what);
    if (!a->to)
        croak("%s needs to =>", what);
}

/* The step in whole seconds, 60 unless given. */
static IV
tks_track_step(pTHX_ SV *sv, const char *what)
{
    NV s;
    if (!sv)
        return 60;
    if (!SvOK(sv) || !looks_like_number(sv))
        croak("%s: step must be a number of seconds", what);
    s = SvNV_nomg(sv);
    if (s != floor(s) || s < 1 || s > TKS_TRACK_STEP_MAX)
        croak("%s: step must be a whole number of seconds from 1 to %d", what, TKS_TRACK_STEP_MAX);
    return (IV)s;
}

/* The number of samples from one instant to another at a step: both ends
 * are in when the span is a whole number of steps. */
static IV
tks_track_count(pTHX_ const time_keeper_instant *from, const time_keeper_instant *to, IV step, const char *what)
{
    double span = (double)(to->sec - from->sec) + (double)(to->nsec - from->nsec) / 1e9;
    double n;
    if (!(span > 0.0))
        croak("%s: to must be after from", what);
    n = floor(span / (double)step) + 1.0;
    if (n > TKS_TRACK_MAX)
        croak("%s: %.0f samples is more than %d; take a longer step or a shorter span", what, n, TKS_TRACK_MAX);
    return (IV)n;
}

/* The instants of a track, read and checked. */
static IV
tks_track_span(pTHX_ const tks_track_sv *a, time_keeper_instant *from, IV *step, const char *what)
{
    time_keeper_instant to;
    tks_instant_arg(aTHX_ a->from, from, what);
    tks_instant_arg(aTHX_ a->to, &to, what);
    *step = tks_track_step(aTHX_ a->step, what);
    tks_year_check(aTHX_ from, what);
    tks_year_check(aTHX_ &to, what);
    return tks_track_count(aTHX_ from, &to, *step, what);
}

/* The east longitude, -180 to 180, under a body at right ascension ra when
 * the apparent sidereal time at Greenwich is theta: where its hour angle
 * is 0. */
static double
tks_sub_longitude(double ra, double theta)
{
    double l = tks_deg_norm(ra - theta);
    return l > 180.0 ? l - 360.0 : l;
}

/* An epoch as a number: an integer when the instant is a whole second. */
static SV *
tks_epoch_sv(pTHX_ const time_keeper_instant *t)
{
    if (t->nsec == 0)
        return newSViv((IV)t->sec);
    return newSVnv((NV)t->sec + (NV)t->nsec / 1e9);
}

static AV *
tks_track_av(pTHX_ HV *hv, const char *key, I32 klen, IV n)
{
    AV *av = newAV();
    av_extend(av, n - 1);
    (void)hv_store(hv, key, klen, newRV_noinc((SV *)av), 0);
    return av;
}

#define TKS_TRACK_AV(hv, key, n) tks_track_av(aTHX_ hv, "" key "", sizeof(key) - 1, n)

/* The sample k of a track: from plus k steps. */
static void
tks_track_at(const time_keeper_instant *from, IV step, IV k, time_keeper_instant *t)
{
    *t = *from;
    t->sec += (int64_t)k * (int64_t)step;
}

static SV *
tks_sun_track(pTHX_ const tks_place *p, const time_keeper_instant *from, IV step, IV n)
{
    HV *hv = newHV();
    AV *ep   = TKS_TRACK_AV(hv, "epoch", n);
    AV *alt  = TKS_TRACK_AV(hv, "altitude", n);
    AV *app  = TKS_TRACK_AV(hv, "apparent_altitude", n);
    AV *az   = TKS_TRACK_AV(hv, "azimuth", n);
    AV *slat = TKS_TRACK_AV(hv, "sub_latitude", n);
    AV *slon = TKS_TRACK_AV(hv, "sub_longitude", n);
    IV k;
    for (k = 0; k < n; k++) {
        time_keeper_instant t;
        tks_sunpos s;
        double jd, jde, theta, a, z, H;
        tks_track_at(from, step, k, &t);
        jd = tks_jd_ut(&t);
        jde = tks_jde(aTHX_ &t);
        tks_sun_place(jde, &s);
        theta = tks_sidereal_apparent(jd, jde);
        tks_altaz_theta(theta, p->lat, p->lon, s.ra, s.dec, &a, &z, &H);
        av_push(ep,   tks_epoch_sv(aTHX_ &t));
        av_push(alt,  newSVnv(a));
        av_push(app,  newSVnv(a + tks_refraction(a) / 60.0));
        av_push(az,   newSVnv(z));
        av_push(slat, newSVnv(s.dec));
        av_push(slon, newSVnv(tks_sub_longitude(s.ra, theta)));
    }
    return newRV_noinc((SV *)hv);
}

/* The moon's track; seen from p when there is one, else only what needs
 * no place: the sub-point, the illumination and the distance. */
static SV *
tks_moon_track(pTHX_ const tks_place *p, const time_keeper_instant *from, IV step, IV n)
{
    HV *hv = newHV();
    AV *ep   = TKS_TRACK_AV(hv, "epoch", n);
    AV *alt  = p ? TKS_TRACK_AV(hv, "altitude", n) : NULL;
    AV *app  = p ? TKS_TRACK_AV(hv, "apparent_altitude", n) : NULL;
    AV *az   = p ? TKS_TRACK_AV(hv, "azimuth", n) : NULL;
    AV *pa   = p ? TKS_TRACK_AV(hv, "parallactic_angle", n) : NULL;
    AV *limb = TKS_TRACK_AV(hv, "bright_limb", n);
    AV *ill  = TKS_TRACK_AV(hv, "illumination", n);
    AV *dist = TKS_TRACK_AV(hv, "distance", n);
    AV *slat = TKS_TRACK_AV(hv, "sub_latitude", n);
    AV *slon = TKS_TRACK_AV(hv, "sub_longitude", n);
    IV k;
    for (k = 0; k < n; k++) {
        time_keeper_instant t;
        tks_moonview v;
        tks_sunpos s;
        double jd, jde, theta, i;
        tks_track_at(from, step, k, &t);
        jd = tks_jd_ut(&t);
        jde = tks_jde(aTHX_ &t);
        tks_moon_place(jde, &v.m);
        theta = tks_sidereal_apparent(jd, jde);
        av_push(ep, tks_epoch_sv(aTHX_ &t));
        if (p) {
            tks_moon_seen(p, theta, &v);
            av_push(alt, newSVnv(v.alt));
            av_push(app, newSVnv(v.app_alt));
            av_push(az,  newSVnv(v.az));
            av_push(pa,  newSVnv(tks_parallactic_angle(p->lat, v.Ht, v.dect)));
        }
        tks_sun_place(jde, &s);
        av_push(limb, newSVnv(tks_bright_limb(s.ra, s.dec, v.m.ra, v.m.dec)));
        i = tks_moon_phase_angle(&v.m, &s);
        av_push(ill,  newSVnv((1.0 + cos(tks_rad(i))) / 2.0));
        av_push(dist, newSVnv(v.m.distance));
        av_push(slat, newSVnv(v.m.dec));
        av_push(slon, newSVnv(tks_sub_longitude(v.m.ra, theta)));
    }
    return newRV_noinc((SV *)hv);
}

/* A planet's track (tks_planet.h); seen from p when there is one. */
static SV *
tks_planet_track(pTHX_ int body, const tks_place *p, const time_keeper_instant *from, IV step, IV n)
{
    HV *hv = newHV();
    AV *ep   = TKS_TRACK_AV(hv, "epoch", n);
    AV *alt  = p ? TKS_TRACK_AV(hv, "altitude", n) : NULL;
    AV *app  = p ? TKS_TRACK_AV(hv, "apparent_altitude", n) : NULL;
    AV *az   = p ? TKS_TRACK_AV(hv, "azimuth", n) : NULL;
    AV *mag  = TKS_TRACK_AV(hv, "magnitude", n);
    AV *ill  = TKS_TRACK_AV(hv, "illumination", n);
    AV *dist = TKS_TRACK_AV(hv, "distance", n);
    AV *slat = TKS_TRACK_AV(hv, "sub_latitude", n);
    AV *slon = TKS_TRACK_AV(hv, "sub_longitude", n);
    IV k;
    for (k = 0; k < n; k++) {
        time_keeper_instant t;
        tks_planetpos pp;
        double jd, jde, theta;
        tks_track_at(from, step, k, &t);
        jd = tks_jd_ut(&t);
        jde = tks_jde(aTHX_ &t);
        tks_planet_at(body, jde, &pp);
        theta = tks_sidereal_apparent(jd, jde);
        av_push(ep, tks_epoch_sv(aTHX_ &t));
        if (p) {
            double a, ap, z, Ht;
            tks_planet_seen(p, theta, &pp, &a, &ap, &z, &Ht);
            av_push(alt, newSVnv(a));
            av_push(app, newSVnv(ap));
            av_push(az,  newSVnv(z));
        }
        av_push(mag,  isnan(pp.magnitude) ? newSV(0) : newSVnv(pp.magnitude));
        av_push(ill,  newSVnv(pp.illumination));
        av_push(dist, newSVnv(pp.delta));
        av_push(slat, newSVnv(pp.dec));
        av_push(slon, newSVnv(tks_sub_longitude(pp.ra, theta)));
    }
    return newRV_noinc((SV *)hv);
}

/* A star's track (tks_star.h). */
static SV *
tks_star_track(pTHX_ int row, const tks_place *p, const time_keeper_instant *from, IV step, IV n)
{
    HV *hv = newHV();
    AV *ep   = TKS_TRACK_AV(hv, "epoch", n);
    AV *alt  = p ? TKS_TRACK_AV(hv, "altitude", n) : NULL;
    AV *app  = p ? TKS_TRACK_AV(hv, "apparent_altitude", n) : NULL;
    AV *az   = p ? TKS_TRACK_AV(hv, "azimuth", n) : NULL;
    AV *slat = TKS_TRACK_AV(hv, "sub_latitude", n);
    AV *slon = TKS_TRACK_AV(hv, "sub_longitude", n);
    IV k;
    for (k = 0; k < n; k++) {
        time_keeper_instant t;
        tks_starframe f;
        double jd, jde, theta, ra, dec;
        tks_track_at(from, step, k, &t);
        jd = tks_jd_ut(&t);
        jde = tks_jde(aTHX_ &t);
        tks_starframe_at(jde, &f);
        tks_star_apparent(&tks_bsc5[row], &f, &ra, &dec);
        theta = tks_sidereal_apparent(jd, jde);
        av_push(ep, tks_epoch_sv(aTHX_ &t));
        if (p) {
            double a, z, H;
            tks_altaz_theta(theta, p->lat, p->lon, ra, dec, &a, &z, &H);
            av_push(alt, newSVnv(a));
            av_push(app, newSVnv(a + tks_refraction(a) / 60.0));
            av_push(az,  newSVnv(z));
        }
        av_push(slat, newSVnv(dec));
        av_push(slon, newSVnv(tks_sub_longitude(ra, theta)));
    }
    return newRV_noinc((SV *)hv);
}

/* The sun's or the moon's sub-point at one instant: (latitude, east
 * longitude), degrees. */
static void
tks_sub_point(pTHX_ const time_keeper_instant *t, int moon, double *lat, double *lon)
{
    double jd = tks_jd_ut(t), jde = tks_jde(aTHX_ t);
    double theta = tks_sidereal_apparent(jd, jde);
    if (moon) {
        tks_moonplace m;
        tks_moon_place(jde, &m);
        *lat = m.dec;
        *lon = tks_sub_longitude(m.ra, theta);
    }
    else {
        tks_sunpos s;
        tks_sun_place(jde, &s);
        *lat = s.dec;
        *lon = tks_sub_longitude(s.ra, theta);
    }
}

#endif
