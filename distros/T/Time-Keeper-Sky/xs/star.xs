# The stars of the Bright Star Catalogue.

MODULE = Time::Keeper::Sky    PACKAGE = Time::Keeper::Star

# What the catalogue says of a star, by name, designation or HR number; undef
# when there is no such star.
SV *
find(class, ...)
        SV *class
    PREINIT:
        int row = -1;
        const tks_star_row *s;
        HV *hv;
        char buf[16];
    CODE:
        PERL_UNUSED_VAR(class);
        if (items == 2)
            row = tks_star_row_arg(aTHX_ ST(1), 0, "Time::Keeper::Star->find");
        else if (items == 3) {
            STRLEN klen;
            const char *k;
            SvGETMAGIC(ST(1));
            k = SvPV_nomg(ST(1), klen);
            if (klen == 2 && memEQ(k, "hr", 2)) {
                SvGETMAGIC(ST(2));
                if (!SvOK(ST(2)) || !looks_like_number(ST(2)))
                    croak("Time::Keeper::Star->find: hr must be a number");
                row = tks_star_hr_index((int)SvIV_nomg(ST(2)));
            }
            else if (klen == 4 && memEQ(k, "name", 4))
                row = tks_star_row_arg(aTHX_ ST(2), 0, "Time::Keeper::Star->find");
            else
                croak("Time::Keeper::Star->find: unknown argument '%.*s'", (int)klen, k);
        }
        else
            croak("Time::Keeper::Star->find takes a name, or hr => or name =>");
        if (row < 0)
            XSRETURN_UNDEF;
        s = &tks_bsc5[row];
        hv = newHV();
        (void)hv_stores(hv, "hr", newSViv(s->hr));
        (void)hv_stores(hv, "name", s->name >= 0 ? newSVpvn_flags(tks_star_names[s->name][1], strlen(tks_star_names[s->name][1]), SVf_UTF8) : newSV(0));
        if (s->bayer[0]) {
            snprintf(buf, sizeof buf, "%s%s%c %s", s->bayer, "", s->sup ? s->sup : ' ', s->con);
            if (!s->sup)
                snprintf(buf, sizeof buf, "%s %s", s->bayer, s->con);
            (void)hv_stores(hv, "bayer", newSVpv(buf, 0));
        }
        else
            (void)hv_stores(hv, "bayer", newSV(0));
        if (s->flamsteed) {
            snprintf(buf, sizeof buf, "%d %s", s->flamsteed, s->con);
            (void)hv_stores(hv, "flamsteed", newSVpv(buf, 0));
        }
        else
            (void)hv_stores(hv, "flamsteed", newSV(0));
        (void)hv_stores(hv, "constellation", s->con[0] ? newSVpv(s->con, 0) : newSV(0));
        (void)hv_stores(hv, "magnitude", newSVnv(tks_nv_of(aTHX_ s->vmag)));
        (void)hv_stores(hv, "colour", isnan(s->bv) ? newSV(0) : newSVnv(tks_nv_of(aTHX_ s->bv)));
        (void)hv_stores(hv, "right_ascension", newSVnv(tks_nv_of(aTHX_ s->ra)));
        (void)hv_stores(hv, "declination", newSVnv(tks_nv_of(aTHX_ s->dec)));
        (void)hv_stores(hv, "proper_motion_ra", newSVnv(tks_nv_of(aTHX_ s->pmra)));
        (void)hv_stores(hv, "proper_motion_dec", newSVnv(tks_nv_of(aTHX_ s->pmdec)));
        (void)hv_stores(hv, "parallax", newSVnv(tks_nv_of(aTHX_ s->plx)));
        (void)hv_stores(hv, "radial_velocity", newSVnv(tks_nv_of(aTHX_ s->rv)));
        RETVAL = newRV_noinc((SV *)hv);
    OUTPUT:
        RETVAL

# A star's apparent place at an instant; with place => its altitude and
# azimuth from there.
SV *
position(class, star, t, ...)
        SV *class
        SV *star
        SV *t
    PREINIT:
        const char *what = "Time::Keeper::Star->position";
        time_keeper_instant in;
        tks_starframe f;
        tks_place p;
        SV *place_sv = NULL;
        HV *hv;
        int row, i;
        double ra, dec, jd, jde;
    CODE:
        PERL_UNUSED_VAR(class);
        if ((items - 3) % 2)
            croak("%s takes a star, an instant and then name and value pairs", what);
        for (i = 3; i < items; i += 2) {
            STRLEN klen;
            const char *k;
            SvGETMAGIC(ST(i));
            k = SvPV_nomg(ST(i), klen);
            SvGETMAGIC(ST(i + 1));
            if (klen == 5 && memEQ(k, "place", 5)) place_sv = ST(i + 1);
            else croak("%s: unknown argument '%.*s'", what, (int)klen, k);
        }
        row = tks_star_row_arg(aTHX_ star, 1, what);
        tks_instant_arg(aTHX_ t, &in, what);
        tks_year_check(aTHX_ &in, what);
        jd = tks_jd_ut(&in);
        jde = tks_jde(aTHX_ &in);
        tks_starframe_at(jde, &f);
        tks_star_apparent(&tks_bsc5[row], &f, &ra, &dec);
        hv = newHV();
        (void)hv_stores(hv, "right_ascension", newSVnv(ra));
        (void)hv_stores(hv, "declination", newSVnv(dec));
        (void)hv_stores(hv, "magnitude", newSVnv(tks_nv_of(aTHX_ tks_bsc5[row].vmag)));
        (void)hv_stores(hv, "hr", newSViv(tks_bsc5[row].hr));
        if (place_sv) {
            double alt, az, H;
            tks_where(aTHX_ &p, place_sv, NULL, NULL, what);
            tks_altaz_theta(tks_sidereal_apparent(jd, jde), p.lat, p.lon, ra, dec, &alt, &az, &H);
            (void)hv_stores(hv, "altitude", newSVnv(alt));
            (void)hv_stores(hv, "apparent_altitude", newSVnv(alt + tks_refraction(alt) / 60.0));
            (void)hv_stores(hv, "azimuth", newSVnv(az));
            (void)hv_stores(hv, "hour_angle", newSVnv(H));
        }
        RETVAL = newRV_noinc((SV *)hv);
    OUTPUT:
        RETVAL

# Every star to a magnitude at one instant, as arrays, brightest first: the
# star map's call.
SV *
positions(class, t, ...)
        SV *class
        SV *t
    PREINIT:
        const char *what = "Time::Keeper::Star->positions";
        time_keeper_instant in;
        tks_starframe f;
        tks_place p;
        SV *place_sv = NULL;
        NV limit = 4.5;
        HV *hv;
        AV *hr, *ra_av, *dec_av, *mag, *alt_av = NULL, *az_av = NULL;
        int i, n, has = 0;
        double jd, jde, theta = 0.0;
    CODE:
        PERL_UNUSED_VAR(class);
        if ((items - 2) % 2)
            croak("%s takes an instant and then name and value pairs", what);
        for (i = 2; i < items; i += 2) {
            STRLEN klen;
            const char *k;
            SvGETMAGIC(ST(i));
            k = SvPV_nomg(ST(i), klen);
            SvGETMAGIC(ST(i + 1));
            if (klen == 5 && memEQ(k, "place", 5)) place_sv = ST(i + 1);
            else if (klen == 9 && memEQ(k, "magnitude", 9)) {
                if (!SvOK(ST(i + 1)) || !looks_like_number(ST(i + 1)))
                    croak("%s: magnitude must be a number", what);
                limit = SvNV_nomg(ST(i + 1));
            }
            else croak("%s: unknown argument '%.*s'", what, (int)klen, k);
        }
        tks_instant_arg(aTHX_ t, &in, what);
        tks_year_check(aTHX_ &in, what);
        if (place_sv)
            has = tks_where(aTHX_ &p, place_sv, NULL, NULL, what);
        jd = tks_jd_ut(&in);
        jde = tks_jde(aTHX_ &in);
        tks_starframe_at(jde, &f);
        if (has)
            theta = tks_sidereal_apparent(jd, jde);
        for (n = 0; n < TKS_STARS && tks_bsc5[n].vmag <= limit; n++)
            ;
        hv = newHV();
        hr     = TKS_TRACK_AV(hv, "hr", n > 0 ? n : 1);
        ra_av  = TKS_TRACK_AV(hv, "right_ascension", n > 0 ? n : 1);
        dec_av = TKS_TRACK_AV(hv, "declination", n > 0 ? n : 1);
        mag    = TKS_TRACK_AV(hv, "magnitude", n > 0 ? n : 1);
        if (has) {
            alt_av = TKS_TRACK_AV(hv, "altitude", n > 0 ? n : 1);
            az_av  = TKS_TRACK_AV(hv, "azimuth", n > 0 ? n : 1);
        }
        for (i = 0; i < n; i++) {
            double ra, dec;
            tks_star_apparent(&tks_bsc5[i], &f, &ra, &dec);
            av_push(hr, newSViv(tks_bsc5[i].hr));
            av_push(ra_av, newSVnv(ra));
            av_push(dec_av, newSVnv(dec));
            av_push(mag, newSVnv(tks_nv_of(aTHX_ tks_bsc5[i].vmag)));
            if (has) {
                double alt, az, H;
                tks_altaz_theta(theta, p.lat, p.lon, ra, dec, &alt, &az, &H);
                av_push(alt_av, newSVnv(alt));
                av_push(az_av, newSVnv(az));
            }
        }
        RETVAL = newRV_noinc((SV *)hv);
    OUTPUT:
        RETVAL

# The HR numbers of every star at or brighter than a magnitude, brightest
# first.
void
brighter_than(class, limit)
        SV *class
        NV limit
    PREINIT:
        int i;
    PPCODE:
        PERL_UNUSED_VAR(class);
        for (i = 0; i < TKS_STARS && tks_bsc5[i].vmag <= limit; i++) {
            EXTEND(SP, 1);
            mPUSHi(tks_bsc5[i].hr);
        }

SV *
track(class, star, ...)
        SV *class
        SV *star
    PREINIT:
        const char *what = "Time::Keeper::Star->track";
        tks_track_sv a;
        time_keeper_instant from;
        tks_place p;
        IV step, n;
        int has, row;
    CODE:
        PERL_UNUSED_VAR(class);
        row = tks_star_row_arg(aTHX_ star, 1, what);
        tks_track_args(aTHX_ &ST(2), items - 2, &a, 1, what);
        has = tks_where(aTHX_ &p, a.place, NULL, NULL, what);
        n = tks_track_span(aTHX_ &a, &from, &step, what);
        RETVAL = tks_star_track(aTHX_ row, has ? &p : NULL, &from, step, n);
    OUTPUT:
        RETVAL

void
sub_point(class, star, t)
        SV *class
        SV *star
        SV *t
    PREINIT:
        const char *what = "Time::Keeper::Star->sub_point";
        time_keeper_instant in;
        tks_starframe f;
        int row;
        double ra, dec, jd, jde;
    CODE:
        PERL_UNUSED_VAR(class);
        row = tks_star_row_arg(aTHX_ star, 1, what);
        tks_instant_arg(aTHX_ t, &in, what);
        tks_year_check(aTHX_ &in, what);
        jd = tks_jd_ut(&in);
        jde = tks_jde(aTHX_ &in);
        tks_starframe_at(jde, &f);
        tks_star_apparent(&tks_bsc5[row], &f, &ra, &dec);
        ST(0) = sv_2mortal(newSVnv(dec));
        ST(1) = sv_2mortal(newSVnv(tks_sub_longitude(ra, tks_sidereal_apparent(jd, jde))));
        XSRETURN(2);

# A star's day at a place: its rises, sets and upper transits in the civil
# day of the place's zone (place => is required).
SV *
on(class, date, star, ...)
        SV *class
        SV *date
        SV *star
    PREINIT:
        const char *what = "Time::Keeper::Star->on";
        SV *place_sv = NULL, *zone_sv = NULL, *locale_sv = NULL;
        dMY_CXT;
        tks_place p;
        tks_planetday d;
        time_keeper_instant t;
        int64_t days, start, end;
        int i, row;
        SV *inner;
    CODE:
        PERL_UNUSED_VAR(class);
        if ((items - 3) % 2)
            croak("%s takes a date, a star and then name and value pairs", what);
        SvGETMAGIC(date);
        for (i = 3; i < items; i += 2) {
            STRLEN klen;
            const char *k;
            SvGETMAGIC(ST(i));
            k = SvPV_nomg(ST(i), klen);
            SvGETMAGIC(ST(i + 1));
            if (klen == 5 && memEQ(k, "place", 5)) place_sv = ST(i + 1);
            else if (klen == 4 && memEQ(k, "zone", 4)) zone_sv = ST(i + 1);
            else if (klen == 6 && memEQ(k, "locale", 6)) locale_sv = ST(i + 1);
            else croak("%s: unknown argument '%.*s'", what, (int)klen, k);
        }
        row = tks_star_row_arg(aTHX_ star, 1, what);
        if (!place_sv)
            croak("%s needs place => a Time::Keeper::Sky", what);
        tks_where(aTHX_ &p, place_sv, zone_sv, locale_sv, what);
        if (SvROK(date) && sv_derived_from(date, "Time::Keeper::Date"))
            days = tks_days_of_date(aTHX_ date);
        else if (SvROK(date) && (tks_tk(aTHX)->from_sv)(aTHX_ date, &t, NULL, NULL) == TIME_KEEPER_OK)
            days = tks_days_in_zone(aTHX_ &p, &t, what);
        else
            croak("%s takes a Time::Keeper::Date or a Time::Keeper value", what);
        start = tks_midnight(aTHX_ &p, days, what);
        end   = tks_midnight(aTHX_ &p, days + 1, what);
        t.sec = start; t.nsec = 0;
        tks_year_check(aTHX_ &t, what);
        t.sec = end - 1;
        tks_year_check(aTHX_ &t, what);
        tks_starday_compute(aTHX_ &p, row, days, start, end, &d);
        inner = newSVpvn((const char *)&d, sizeof d);
        RETVAL = sv_bless(newRV_noinc(inner), MY_CXT.sstash);
    OUTPUT:
        RETVAL

# A star's next or previous rise, set or upper transit from an instant,
# seen from a place (place => is required); undef for a rise or set when the
# star never crosses the horizon there.
SV *
next_rise(class, star, t, ...)
        SV *class
        SV *star
        SV *t
    ALIAS:
        next_set = 1
        previous_rise = 2
        previous_set = 3
        next_transit = 4
        previous_transit = 5
    PREINIT:
        static const char *const names[6] = {
            "Time::Keeper::Star->next_rise", "Time::Keeper::Star->next_set",
            "Time::Keeper::Star->previous_rise", "Time::Keeper::Star->previous_set",
            "Time::Keeper::Star->next_transit", "Time::Keeper::Star->previous_transit" };
        SV *place_sv = NULL, *zone_sv = NULL, *locale_sv = NULL;
        tks_place p;
        tks_body b;
        time_keeper_instant in;
        int64_t out;
        int i, row;
    CODE:
        PERL_UNUSED_VAR(class);
        if ((items - 3) % 2)
            croak("%s takes a star, an instant and then name and value pairs", names[ix]);
        for (i = 3; i < items; i += 2) {
            STRLEN klen;
            const char *k;
            SV *v = ST(i + 1);
            SvGETMAGIC(ST(i));
            k = SvPV_nomg(ST(i), klen);
            SvGETMAGIC(v);
            if (klen == 5 && memEQ(k, "place", 5)) place_sv = v;
            else if (klen == 4 && memEQ(k, "zone", 4)) zone_sv = v;
            else if (klen == 6 && memEQ(k, "locale", 6)) locale_sv = v;
            else croak("%s: unknown argument '%.*s'", names[ix], (int)klen, k);
        }
        row = tks_star_row_arg(aTHX_ star, 1, names[ix]);
        if (!place_sv)
            croak("%s needs place => a Time::Keeper::Sky", names[ix]);
        tks_where(aTHX_ &p, place_sv, zone_sv, locale_sv, names[ix]);
        tks_instant_arg(aTHX_ t, &in, names[ix]);
        tks_year_check(aTHX_ &in, names[ix]);
        tks_star_body(&p, row, &b);
        if (ix >= 4)
            RETVAL = tks_value_sv(aTHX_ &p, tks_body_transit_find(aTHX_ &b, in.sec, ix == 5));
        else if (!tks_star_never_crosses(aTHX_ &p, row, in.sec, tks_planet_horizon(&p))
                 && tks_find_crossing_b(aTHX_ &b, in.sec, tks_planet_horizon(&p), ix % 2 == 0, ix >= 2, &out))
            RETVAL = tks_value_sv(aTHX_ &p, out);
        else
            RETVAL = &PL_sv_undef;
    OUTPUT:
        RETVAL

MODULE = Time::Keeper::Sky    PACKAGE = Time::Keeper::Sky

# The IAU abbreviation of the constellation a direction lies in: right
# ascension and declination in degrees, referred to J2000.0, or to the mean
# equator and equinox of the date given (an instant: a position of date).
SV *
constellation_of(class, ra, dec, ...)
        SV *class
        NV ra
        NV dec
    PREINIT:
        const char *what = "Time::Keeper::Sky->constellation_of";
        time_keeper_instant in;
        double frame = TKS_J2000;
        int c;
    CODE:
        PERL_UNUSED_VAR(class);
        if (items > 4)
            croak("%s takes a right ascension, a declination and the instant their equinox is of", what);
        if (items == 4) {
            tks_instant_arg(aTHX_ ST(3), &in, what);
            tks_year_check(aTHX_ &in, what);
            frame = tks_jde(aTHX_ &in);
        }
        if (dec < -90.0 || dec > 90.0)
            croak("%s: the declination must be from -90 to 90, not %" NVgf, what, dec);
        c = tks_constellation_of((double)ra, (double)dec, frame);
        RETVAL = c < 0 ? &PL_sv_undef : newSVpv(tks_cons_names[c][0], 0);
    OUTPUT:
        RETVAL

# A constellation's abbreviation, name and genitive, by its abbreviation or
# name; undef if there is none.
SV *
constellation(class, name)
        SV *class
        SV *name
    PREINIT:
        STRLEN len;
        const char *s;
        int c;
        HV *hv;
    CODE:
        PERL_UNUSED_VAR(class);
        SvGETMAGIC(name);
        if (!SvOK(name))
            croak("Time::Keeper::Sky->constellation needs an abbreviation or a name");
        s = SvPV_nomg(name, len);
        c = tks_constellation_find(s, len);
        if (c < 0)
            XSRETURN_UNDEF;
        hv = newHV();
        (void)hv_stores(hv, "abbreviation", newSVpv(tks_cons_names[c][0], 0));
        (void)hv_stores(hv, "name", newSVpv(tks_cons_names[c][1], 0));
        (void)hv_stores(hv, "genitive", newSVpv(tks_cons_names[c][2], 0));
        RETVAL = newRV_noinc((SV *)hv);
    OUTPUT:
        RETVAL

# The 88 abbreviations, in alphabetical order of their names.
void
constellations(class)
        SV *class
    PREINIT:
        int i;
    PPCODE:
        PERL_UNUSED_VAR(class);
        EXTEND(SP, TKS_CONSTELLATIONS);
        for (i = 0; i < TKS_CONSTELLATIONS; i++)
            mPUSHs(newSVpv(tks_cons_names[i][0], 0));
