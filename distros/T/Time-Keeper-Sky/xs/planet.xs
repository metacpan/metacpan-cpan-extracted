# The planets, by VSOP87D.

MODULE = Time::Keeper::Sky    PACKAGE = Time::Keeper::Planet

# A planet's heliocentric ecliptic longitude, latitude (degrees) and radius
# (AU), referred to the ecliptic and equinox of date. The earth is one, and
# Pluto (chapter 37, precessed to the date).
SV *
heliocentric(class, name, t)
        SV *class
        SV *name
        SV *t
    PREINIT:
        time_keeper_instant in;
        int planet;
        double L, B, R;
        HV *hv;
    CODE:
        PERL_UNUSED_VAR(class);
        planet = tks_planet_arg(aTHX_ name, 1, "Time::Keeper::Planet->heliocentric");
        tks_instant_arg(aTHX_ t, &in, "Time::Keeper::Planet->heliocentric");
        tks_year_check(aTHX_ &in, "Time::Keeper::Planet->heliocentric");
        tks_planet_range(aTHX_ planet, &in, "Time::Keeper::Planet->heliocentric");
        tks_helio(planet, tks_jde(aTHX_ &in), &L, &B, &R);
        hv = newHV();
        (void)hv_stores(hv, "longitude", newSVnv(tks_deg_norm(tks_deg(L))));
        (void)hv_stores(hv, "latitude",  newSVnv(tks_deg(B)));
        (void)hv_stores(hv, "radius",    newSVnv(R));
        RETVAL = newRV_noinc((SV *)hv);
    OUTPUT:
        RETVAL

# The planets this dist knows, in order from the sun, Pluto last; the earth is
# left out.
void
planets(class)
        SV *class
    PREINIT:
        int i;
    PPCODE:
        PERL_UNUSED_VAR(class);
        EXTEND(SP, TKS_BODIES - 1);
        for (i = 0; i < TKS_BODIES; i++)
            if (i != TKS_EARTH)
                mPUSHs(newSVpv(tks_planet_name[i], 0));

# A planet's apparent place at an instant; with place => also its altitude
# and azimuth from there.
SV *
position(class, name, t, ...)
        SV *class
        SV *name
        SV *t
    PREINIT:
        time_keeper_instant in;
        tks_planetpos pp;
        tks_place p;
        SV *place_sv = NULL;
        HV *hv;
        int body, i;
        double jd, jde;
    CODE:
        PERL_UNUSED_VAR(class);
        if ((items - 3) % 2)
            croak("Time::Keeper::Planet->position takes a planet, an instant and then name and value pairs");
        for (i = 3; i < items; i += 2) {
            STRLEN klen;
            const char *k;
            SvGETMAGIC(ST(i));
            k = SvPV_nomg(ST(i), klen);
            SvGETMAGIC(ST(i + 1));
            if (klen == 5 && memEQ(k, "place", 5)) place_sv = ST(i + 1);
            else croak("Time::Keeper::Planet->position: unknown argument '%.*s'", (int)klen, k);
        }
        body = tks_planet_arg(aTHX_ name, 0, "Time::Keeper::Planet->position");
        tks_instant_arg(aTHX_ t, &in, "Time::Keeper::Planet->position");
        tks_year_check(aTHX_ &in, "Time::Keeper::Planet->position");
        tks_planet_range(aTHX_ body, &in, "Time::Keeper::Planet->position");
        jd = tks_jd_ut(&in);
        jde = tks_jde(aTHX_ &in);
        tks_planet_at(body, jde, &pp);
        hv = newHV();
        (void)hv_stores(hv, "longitude",       newSVnv(pp.lon));
        (void)hv_stores(hv, "latitude",        newSVnv(pp.lat));
        (void)hv_stores(hv, "right_ascension", newSVnv(pp.ra));
        (void)hv_stores(hv, "declination",     newSVnv(pp.dec));
        (void)hv_stores(hv, "distance",        newSVnv(pp.delta));
        (void)hv_stores(hv, "light_time",      newSVnv(pp.tau * 86400.0));
        (void)hv_stores(hv, "elongation",      newSVnv(pp.elongation));
        (void)hv_stores(hv, "phase_angle",     newSVnv(pp.phase_angle));
        (void)hv_stores(hv, "illumination",    newSVnv(pp.illumination));
        (void)hv_stores(hv, "diameter",        newSVnv(pp.diameter));
        (void)hv_stores(hv, "magnitude",       isnan(pp.magnitude) ? newSV(0) : newSVnv(pp.magnitude));
        (void)hv_stores(hv, "constellation",   newSVpv(tks_cons_names[tks_constellation_at(aTHX_ pp.ra, pp.dec, jde)][0], 0));
        if (place_sv) {
            double alt, app, az, Ht;
            tks_where(aTHX_ &p, place_sv, NULL, NULL, "Time::Keeper::Planet->position");
            tks_planet_seen(&p, tks_sidereal_apparent(jd, jde), &pp, &alt, &app, &az, &Ht);
            (void)hv_stores(hv, "altitude",          newSVnv(alt));
            (void)hv_stores(hv, "apparent_altitude", newSVnv(app));
            (void)hv_stores(hv, "azimuth",           newSVnv(az));
            (void)hv_stores(hv, "hour_angle",        newSVnv(Ht));
        }
        RETVAL = newRV_noinc((SV *)hv);
    OUTPUT:
        RETVAL

SV *
track(class, name, ...)
        SV *class
        SV *name
    PREINIT:
        tks_track_sv a;
        time_keeper_instant from, to;
        tks_place p;
        IV step, n;
        int has, body;
    CODE:
        PERL_UNUSED_VAR(class);
        body = tks_planet_arg(aTHX_ name, 0, "Time::Keeper::Planet->track");
        tks_track_args(aTHX_ &ST(2), items - 2, &a, 1, "Time::Keeper::Planet->track");
        has = tks_where(aTHX_ &p, a.place, NULL, NULL, "Time::Keeper::Planet->track");
        n = tks_track_span(aTHX_ &a, &from, &step, "Time::Keeper::Planet->track");
        tks_planet_range(aTHX_ body, &from, "Time::Keeper::Planet->track");
        tks_track_at(&from, step, n - 1, &to);
        tks_planet_range(aTHX_ body, &to, "Time::Keeper::Planet->track");
        RETVAL = tks_planet_track(aTHX_ body, has ? &p : NULL, &from, step, n);
    OUTPUT:
        RETVAL

# Where on the earth a planet is overhead.
void
sub_point(class, name, t)
        SV *class
        SV *name
        SV *t
    PREINIT:
        time_keeper_instant in;
        tks_planetpos pp;
        int body;
        double jd, jde;
    CODE:
        PERL_UNUSED_VAR(class);
        body = tks_planet_arg(aTHX_ name, 0, "Time::Keeper::Planet->sub_point");
        tks_instant_arg(aTHX_ t, &in, "Time::Keeper::Planet->sub_point");
        tks_year_check(aTHX_ &in, "Time::Keeper::Planet->sub_point");
        tks_planet_range(aTHX_ body, &in, "Time::Keeper::Planet->sub_point");
        jd = tks_jd_ut(&in);
        jde = tks_jde(aTHX_ &in);
        tks_planet_at(body, jde, &pp);
        ST(0) = sv_2mortal(newSVnv(pp.dec));
        ST(1) = sv_2mortal(newSVnv(tks_sub_longitude(pp.ra, tks_sidereal_apparent(jd, jde))));
        XSRETURN(2);

# A planet's day at a place: its rises, sets and upper transits in the civil
# day of the place's zone (place => is required).
SV *
on(class, date, name, ...)
        SV *class
        SV *date
        SV *name
    PREINIT:
        SV *place_sv = NULL, *zone_sv = NULL, *locale_sv = NULL;
        dMY_CXT;
        tks_place p;
        tks_planetday d;
        time_keeper_instant t;
        int64_t days, start, end;
        int i, body;
        SV *inner;
    CODE:
        PERL_UNUSED_VAR(class);
        if ((items - 3) % 2)
            croak("Time::Keeper::Planet->on takes a date, a planet and then name and value pairs");
        SvGETMAGIC(date);
        for (i = 3; i < items; i += 2) {
            STRLEN klen;
            const char *k2;
            SvGETMAGIC(ST(i));
            k2 = SvPV_nomg(ST(i), klen);
            SvGETMAGIC(ST(i + 1));
            if (klen == 5 && memEQ(k2, "place", 5)) place_sv = ST(i + 1);
            else if (klen == 4 && memEQ(k2, "zone", 4)) zone_sv = ST(i + 1);
            else if (klen == 6 && memEQ(k2, "locale", 6)) locale_sv = ST(i + 1);
            else croak("Time::Keeper::Planet->on: unknown argument '%.*s'", (int)klen, k2);
        }
        body = tks_planet_arg(aTHX_ name, 0, "Time::Keeper::Planet->on");
        if (!place_sv)
            croak("Time::Keeper::Planet->on needs place => a Time::Keeper::Sky");
        tks_where(aTHX_ &p, place_sv, zone_sv, locale_sv, "Time::Keeper::Planet->on");
        if (SvROK(date) && sv_derived_from(date, "Time::Keeper::Date"))
            days = tks_days_of_date(aTHX_ date);
        else if (SvROK(date) && (tks_tk(aTHX)->from_sv)(aTHX_ date, &t, NULL, NULL) == TIME_KEEPER_OK)
            days = tks_days_in_zone(aTHX_ &p, &t, "Time::Keeper::Planet->on");
        else
            croak("Time::Keeper::Planet->on takes a Time::Keeper::Date or a Time::Keeper value");
        start = tks_midnight(aTHX_ &p, days, "Time::Keeper::Planet->on");
        end   = tks_midnight(aTHX_ &p, days + 1, "Time::Keeper::Planet->on");
        t.sec = start; t.nsec = 0;
        tks_year_check(aTHX_ &t, "Time::Keeper::Planet->on");
        tks_planet_range(aTHX_ body, &t, "Time::Keeper::Planet->on");
        t.sec = end - 1;
        tks_year_check(aTHX_ &t, "Time::Keeper::Planet->on");
        tks_planet_range(aTHX_ body, &t, "Time::Keeper::Planet->on");
        tks_planetday_compute(aTHX_ &p, body, days, start, end, &d);
        inner = newSVpvn((const char *)&d, sizeof d);
        RETVAL = sv_bless(newRV_noinc(inner), MY_CXT.ystash);
    OUTPUT:
        RETVAL

# A planet's next or previous rise, set or upper transit from an instant,
# seen from a place (place => is required).
SV *
next_rise(class, name, t, ...)
        SV *class
        SV *name
        SV *t
    ALIAS:
        next_set = 1
        previous_rise = 2
        previous_set = 3
        next_transit = 4
        previous_transit = 5
    PREINIT:
        static const char *const names[6] = {
            "Time::Keeper::Planet->next_rise", "Time::Keeper::Planet->next_set",
            "Time::Keeper::Planet->previous_rise", "Time::Keeper::Planet->previous_set",
            "Time::Keeper::Planet->next_transit", "Time::Keeper::Planet->previous_transit" };
        SV *place_sv = NULL, *zone_sv = NULL, *locale_sv = NULL;
        tks_place p;
        time_keeper_instant in;
        int64_t out;
        int i, body;
    CODE:
        PERL_UNUSED_VAR(class);
        if ((items - 3) % 2)
            croak("%s takes a planet, an instant and then name and value pairs", names[ix]);
        for (i = 3; i < items; i += 2) {
            STRLEN klen;
            const char *k2;
            SV *v = ST(i + 1);
            SvGETMAGIC(ST(i));
            k2 = SvPV_nomg(ST(i), klen);
            SvGETMAGIC(v);
            if (klen == 5 && memEQ(k2, "place", 5)) place_sv = v;
            else if (klen == 4 && memEQ(k2, "zone", 4)) zone_sv = v;
            else if (klen == 6 && memEQ(k2, "locale", 6)) locale_sv = v;
            else croak("%s: unknown argument '%.*s'", names[ix], (int)klen, k2);
        }
        body = tks_planet_arg(aTHX_ name, 0, names[ix]);
        if (!place_sv)
            croak("%s needs place => a Time::Keeper::Sky", names[ix]);
        tks_where(aTHX_ &p, place_sv, zone_sv, locale_sv, names[ix]);
        tks_instant_arg(aTHX_ t, &in, names[ix]);
        tks_year_check(aTHX_ &in, names[ix]);
        tks_planet_range(aTHX_ body, &in, names[ix]);
        if (ix >= 4)
            RETVAL = tks_value_sv(aTHX_ &p, tks_planet_transit_find(aTHX_ &p, body, in.sec, ix == 5));
        else if (tks_planet_find(aTHX_ &p, body, in.sec, ix % 2, ix >= 2, &out))
            RETVAL = tks_value_sv(aTHX_ &p, out);
        else
            RETVAL = &PL_sv_undef;
    OUTPUT:
        RETVAL

# A planet's next or previous configuration with the sun.
SV *
next(class, ...)
        SV *class
    ALIAS:
        previous = 1
    PREINIT:
        const char *what = ix ? "Time::Keeper::Planet->previous" : "Time::Keeper::Planet->next";
        SV *event_sv = NULL, *planet_sv = NULL, *from_sv = NULL, *place_sv = NULL, *zone_sv = NULL, *locale_sv = NULL;
        tks_place p;
        time_keeper_instant in;
        int i, body, kind = -1;
        double r;
    CODE:
        PERL_UNUSED_VAR(class);
        if ((items - 1) % 2)
            croak("%s takes name and value pairs", what);
        for (i = 1; i < items; i += 2) {
            STRLEN klen;
            const char *k2;
            SV *v = ST(i + 1);
            SvGETMAGIC(ST(i));
            k2 = SvPV_nomg(ST(i), klen);
            SvGETMAGIC(v);
            if (klen == 5 && memEQ(k2, "event", 5)) event_sv = v;
            else if (klen == 6 && memEQ(k2, "planet", 6)) planet_sv = v;
            else if (!ix && klen == 5 && memEQ(k2, "after", 5)) from_sv = v;
            else if (ix && klen == 6 && memEQ(k2, "before", 6)) from_sv = v;
            else if (klen == 5 && memEQ(k2, "place", 5)) place_sv = v;
            else if (klen == 4 && memEQ(k2, "zone", 4)) zone_sv = v;
            else if (klen == 6 && memEQ(k2, "locale", 6)) locale_sv = v;
            else croak("%s: unknown argument '%.*s'", what, (int)klen, k2);
        }
        if (!event_sv || !SvOK(event_sv))
            croak("%s needs event => (conjunction, inferior_conjunction, superior_conjunction, opposition, greatest_elongation_east, greatest_elongation_west, station_retrograde or station_direct)", what);
        {
            STRLEN elen;
            const char *e = SvPV_nomg(event_sv, elen);
            for (i = 0; i < TKS_C_COUNT; i++)
                if (strlen(tks_config_name[i]) == elen && memEQ(tks_config_name[i], e, elen))
                    kind = i;
            if (kind < 0)
                croak("%s: no event is called '%.*s'", what, (int)elen, e);
        }
        body = tks_planet_arg(aTHX_ planet_sv, 0, what);
        if (body <= TKS_VENUS && kind == TKS_C_OPPOSITION)
            croak("%s: %s has no opposition: it is never opposite the sun", what, tks_planet_name[body]);
        if (body > TKS_VENUS && kind != TKS_C_CONJUNCTION && kind != TKS_C_OPPOSITION
            && kind != TKS_C_STATION_RETRO && kind != TKS_C_STATION_DIRECT)
            croak("%s: %s is an outer planet: it has no %s", what, tks_planet_name[body], tks_config_name[kind]);
        tks_where(aTHX_ &p, place_sv, zone_sv, locale_sv, what);
        if (from_sv)
            tks_instant_arg(aTHX_ from_sv, &in, what);
        else if ((tks_tk(aTHX)->now)(&in) != TIME_KEEPER_OK)
            croak("%s: the clock could not be read", what);
        tks_year_check(aTHX_ &in, what);
        tks_planet_range(aTHX_ body, &in, what);
        if (tks_config_find(body, kind, tks_jde(aTHX_ &in), ix, &r))
            RETVAL = tks_value_sv(aTHX_ &p, tks_jde_to_sec(aTHX_ r));
        else
            RETVAL = &PL_sv_undef;
    OUTPUT:
        RETVAL

# A planet's or a star's day: Time::Keeper::Planet::Day and
# Time::Keeper::Star::Day inherit these.
MODULE = Time::Keeper::Sky    PACKAGE = Time::Keeper::Body::Day

SV *
rise(self)
        SV *self
    ALIAS:
        set = 1
        transit = 2
    PREINIT:
        const tks_planetday *d;
    CODE:
        d = tks_planetday_of(aTHX_ self, tks_planet_event_name[ix]);
        RETVAL = d->n[ix] ? tks_value_sv(aTHX_ &d->place, d->start + d->ev[ix][0]) : &PL_sv_undef;
    OUTPUT:
        RETVAL

void
rises(self)
        SV *self
    ALIAS:
        sets = 1
        transits = 2
    PREINIT:
        static const char *const names[3] = { "rises", "sets", "transits" };
        const tks_planetday *d;
        int i, n;
    PPCODE:
        d = tks_planetday_of(aTHX_ self, names[ix]);
        n = d->n[ix] > 2 ? 2 : d->n[ix];
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            mPUSHs(tks_value_sv(aTHX_ &d->place, d->start + d->ev[ix][i]));

IV
is_up_all_day(self)
        SV *self
    ALIAS:
        is_down_all_day = 1
    PREINIT:
        const tks_planetday *d;
    CODE:
        d = tks_planetday_of(aTHX_ self, ix ? "is_down_all_day" : "is_up_all_day");
        RETVAL = ix ? d->down_all : d->up_all;
    OUTPUT:
        RETVAL

void
events(self)
        SV *self
    PREINIT:
        const tks_planetday *d;
        int64_t when[6];
        int kind[6];
        int n = 0, k, i, a, b;
    PPCODE:
        d = tks_planetday_of(aTHX_ self, "events");
        for (k = 0; k < 3; k++)
            for (i = 0; i < d->n[k] && i < 2; i++) {
                when[n] = d->start + d->ev[k][i];
                kind[n] = k;
                n++;
            }
        for (a = 1; a < n; a++) {
            int64_t w = when[a];
            int kk = kind[a];
            for (b = a - 1; b >= 0 && when[b] > w; b--) {
                when[b + 1] = when[b];
                kind[b + 1] = kind[b];
            }
            when[b + 1] = w;
            kind[b + 1] = kk;
        }
        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            AV *pair = newAV();
            av_push(pair, newSVpv(tks_planet_event_name[kind[i]], 0));
            av_push(pair, tks_value_sv(aTHX_ &d->place, when[i]));
            mPUSHs(newRV_noinc((SV *)pair));
        }

SV *
zone_name(self)
        SV *self
    PREINIT:
        const tks_planetday *d;
    CODE:
        d = tks_planetday_of(aTHX_ self, "zone_name");
        RETVAL = tks_name_sv(aTHX_ d->place.zone_id);
    OUTPUT:
        RETVAL

# The body's name: the planet's, or the star's (its IAU name, else HR n).
SV *
body(self)
        SV *self
    PREINIT:
        const tks_planetday *d;
    CODE:
        d = tks_planetday_of(aTHX_ self, "body");
        RETVAL = d->star >= 0 ? tks_star_name_sv(aTHX_ d->star) : newSVpv(tks_planet_name[d->planet], 0);
    OUTPUT:
        RETVAL

SV *
start(self)
        SV *self
    ALIAS:
        end = 1
    PREINIT:
        const tks_planetday *d;
    CODE:
        d = tks_planetday_of(aTHX_ self, ix ? "end" : "start");
        RETVAL = tks_value_sv(aTHX_ &d->place, ix ? d->end : d->start);
    OUTPUT:
        RETVAL

SV *
date(self)
        SV *self
    PREINIT:
        const tks_planetday *d;
    CODE:
        d = tks_planetday_of(aTHX_ self, "date");
        RETVAL = tks_date_sv(aTHX_ d->days);
    OUTPUT:
        RETVAL

SV *
place(self)
        SV *self
    PREINIT:
        dMY_CXT;
        const tks_planetday *d;
    CODE:
        d = tks_planetday_of(aTHX_ self, "place");
        RETVAL = sv_bless(newRV_noinc(newSVpvn((const char *)&d->place, sizeof d->place)), MY_CXT.pstash);
    OUTPUT:
        RETVAL

MODULE = Time::Keeper::Sky    PACKAGE = Time::Keeper::Planet::Day

SV *
planet(self)
        SV *self
    PREINIT:
        const tks_planetday *d;
    CODE:
        d = tks_planetday_of(aTHX_ self, "planet");
        if (d->planet < 0)
            croak("planet: not a Time::Keeper::Planet::Day");
        RETVAL = newSVpv(tks_planet_name[d->planet], 0);
    OUTPUT:
        RETVAL

MODULE = Time::Keeper::Sky    PACKAGE = Time::Keeper::Star::Day

# The star's HR number.
IV
hr(self)
        SV *self
    PREINIT:
        const tks_planetday *d;
    CODE:
        d = tks_planetday_of(aTHX_ self, "hr");
        if (d->star < 0)
            croak("hr: not a Time::Keeper::Star::Day");
        RETVAL = tks_bsc5[d->star].hr;
    OUTPUT:
        RETVAL

MODULE = Time::Keeper::Sky    PACKAGE = Time::Keeper::Sky

# Every closest approach of two bodies (sun, moon or planets) between two
# instants, as [value, separation in degrees] pairs; the moon seen from
# place => when one is given.
void
closest_approach(class, a, b, ...)
        SV *class
        SV *a
        SV *b
    PREINIT:
        const char *what = "Time::Keeper::Sky->closest_approach";
        SV *from_sv = NULL, *to_sv = NULL, *place_sv = NULL, *zone_sv = NULL, *locale_sv = NULL;
        tks_place p;
        time_keeper_instant from, to;
        int i, ba, bb, n, has;
        double when[4096], sep[4096], jd0, jd1;
    PPCODE:
        PERL_UNUSED_VAR(class);
        if ((items - 3) % 2)
            croak("%s takes two bodies and then name and value pairs", what);
        for (i = 3; i < items; i += 2) {
            STRLEN klen;
            const char *k2;
            SV *v = ST(i + 1);
            SvGETMAGIC(ST(i));
            k2 = SvPV_nomg(ST(i), klen);
            SvGETMAGIC(v);
            if (klen == 4 && memEQ(k2, "from", 4)) from_sv = v;
            else if (klen == 2 && memEQ(k2, "to", 2)) to_sv = v;
            else if (klen == 5 && memEQ(k2, "place", 5)) place_sv = v;
            else if (klen == 4 && memEQ(k2, "zone", 4)) zone_sv = v;
            else if (klen == 6 && memEQ(k2, "locale", 6)) locale_sv = v;
            else croak("%s: unknown argument '%.*s'", what, (int)klen, k2);
        }
        ba = tks_body_arg(aTHX_ a, what);
        bb = tks_body_arg(aTHX_ b, what);
        if (ba == bb)
            croak("%s needs two different bodies", what);
        if (!from_sv || !to_sv)
            croak("%s needs from => and to =>", what);
        has = tks_where(aTHX_ &p, place_sv, zone_sv, locale_sv, what);
        tks_instant_arg(aTHX_ from_sv, &from, what);
        tks_instant_arg(aTHX_ to_sv, &to, what);
        tks_year_check(aTHX_ &from, what);
        tks_year_check(aTHX_ &to, what);
        if (ba == TKS_PLUTO || bb == TKS_PLUTO) {
            tks_planet_range(aTHX_ TKS_PLUTO, &from, what);
            tks_planet_range(aTHX_ TKS_PLUTO, &to, what);
        }
        jd0 = tks_jd_ut(&from);
        jd1 = tks_jd_ut(&to);
        if (!(jd1 > jd0))
            croak("%s: to must be after from", what);
        if (jd1 - jd0 > 3653.0)
            croak("%s: a span of at most ten years", what);
        n = tks_closest(aTHX_ ba, bb, jd0, jd1, has ? &p : NULL, when, sep, 4096);
        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            AV *pair = newAV();
            av_push(pair, tks_value_sv(aTHX_ &p, tks_round_jd(when[i])));
            av_push(pair, newSVnv(sep[i]));
            mPUSHs(newRV_noinc((SV *)pair));
        }
