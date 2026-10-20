# The class methods of Time::Keeper::Sun that are not about a place.

MODULE = Time::Keeper::Sky    PACKAGE = Time::Keeper::Sky

NV
delta_t(class, t)
        SV *class
        SV *t
    PREINIT:
        time_keeper_instant in;
    CODE:
        PERL_UNUSED_VAR(class);
        tks_instant_arg(aTHX_ t, &in, "Time::Keeper::Sun->delta_t");
        tks_year_check(aTHX_ &in, "Time::Keeper::Sun->delta_t");
        RETVAL = tks_delta_t(aTHX_ &in);
    OUTPUT:
        RETVAL

# ---- a place -------------------------------------------------------------

SV *
new(class, ...)
        SV *class
    PREINIT:
        tks_place p;
        int i, have_lat = 0, have_lon = 0, have_zone = 0;
        const char *zname = "UTC";
        const char *lcode = "en";
        STRLEN zlen = 3, llen = 2;
        const tks_place_row *row = NULL;
        SV *inner;
        HV *stash;
        const char *cn;
    CODE:
        /* the class it was called on, or an object's: Time::Keeper::Sun->new
         * makes a Sun as it always has, Time::Keeper::Sky->new a Sky */
        stash = SvROK(class) ? SvSTASH(SvRV(class)) : gv_stashsv(class, GV_ADD);
        cn = HvNAME(stash);
        if ((items - 1) % 2)
            croak("%s->new takes name and value pairs", cn);
        memset(&p, 0, sizeof p);
        p.magic = TKS_PLACE_MAGIC;
        for (i = 1; i < items; i += 2) {
            STRLEN klen;
            const char *k = SvPV(ST(i), klen);
            SV *v = ST(i + 1);
            SvGETMAGIC(v);
            if (klen == 8 && memEQ(k, "latitude", 8)) {
                if (!SvOK(v) || !looks_like_number(v))
                    croak("%s->new: latitude must be a number of degrees, north positive", cn);
                p.lat = (double)SvNV(v);
                if (p.lat < -90.0 || p.lat > 90.0)
                    croak("%s->new: latitude must be between -90 and 90, not %" NVgf, cn, SvNV(v));
                have_lat = 1;
            }
            else if (klen == 9 && memEQ(k, "longitude", 9)) {
                if (!SvOK(v) || !looks_like_number(v))
                    croak("%s->new: longitude must be a number of degrees, east positive", cn);
                p.lon = (double)SvNV(v);
                if (p.lon < -180.0 || p.lon > 180.0)
                    croak("%s->new: longitude must be between -180 and 180, not %" NVgf, cn, SvNV(v));
                have_lon = 1;
            }
            else if (klen == 9 && memEQ(k, "elevation", 9)) {
                if (!SvOK(v) || !looks_like_number(v))
                    croak("%s->new: elevation must be a number of metres", cn);
                p.elev = (double)SvNV(v);
                if (p.elev < 0.0)
                    croak("%s->new: elevation is the height above the horizon seen and cannot be negative (%" NVgf ")", cn, SvNV(v));
            }
            else if (klen == 4 && memEQ(k, "zone", 4)) {
                if (!SvOK(v))
                    croak("%s->new: zone must be a zone name", cn);
                zname = SvPVutf8(v, zlen);
                have_zone = 1;
            }
            else if (klen == 5 && memEQ(k, "place", 5)) {
                STRLEN plen;
                const char *pname;
                if (!SvOK(v))
                    croak("%s->new: place must be a zone name", cn);
                pname = SvPVutf8(v, plen);
                row = tks_place_find(pname, plen);
                if (!row)
                    croak("%s->new: no place is known for '%.*s' (a zone of tzdata " TKS_PLACES_RELEASE ")", cn, (int)plen, pname);
            }
            else if (klen == 6 && memEQ(k, "locale", 6)) {
                if (!SvOK(v))
                    croak("%s->new: locale must be a locale code", cn);
                lcode = SvPV(v, llen);
            }
            else
                croak("%s->new: unknown argument '%.*s'", cn, (int)klen, k);
        }
        if (row && (have_lat || have_lon))
            croak("%s->new: give place, or latitude and longitude, not both", cn);
        if (row) {
            p.lat = row->lat / 10000.0;
            p.lon = row->lon / 10000.0;
            if (!have_zone) {
                zname = row->name;
                zlen = strlen(row->name);
            }
        }
        else if (!have_lat || !have_lon)
            croak("%s->new needs latitude and longitude, or place", cn);
        if ((tks_tk(aTHX)->zone_parse)(aTHX_ zname, zlen, &p.zone) != TIME_KEEPER_OK)
            croak("%s->new: no such zone '%.*s'", cn, (int)zlen, zname);
        if (p.zone.kind == TIME_KEEPER_ZONE_FLOATING)
            croak("%s->new: a place has an offset; the floating zone cannot be one", cn);
        p.zone_id = (uint16_t)tks_name_id(aTHX_ zname, zlen);
        if ((p.locale = (tks_tk(aTHX)->locale_find)(lcode, llen)) < 0)
            croak("%s->new: no such locale '%.*s'", cn, (int)llen, lcode);
        p.locale_id = (uint16_t)tks_name_id(aTHX_ lcode, llen);
        inner = newSVpvn((const char *)&p, sizeof p);
        RETVAL = sv_bless(newRV_noinc(inner), stash);
    OUTPUT:
        RETVAL

NV
latitude(self)
        SV *self
    ALIAS:
        longitude = 1
        elevation = 2
    PREINIT:
        const tks_place *p;
    CODE:
        p = tks_place_of(aTHX_ self, ix == 0 ? "latitude" : ix == 1 ? "longitude" : "elevation");
        RETVAL = tks_nv_of(aTHX_ ix == 0 ? p->lat : ix == 1 ? p->lon : p->elev);
    OUTPUT:
        RETVAL

SV *
zone_name(self)
        SV *self
    ALIAS:
        locale = 1
    PREINIT:
        const tks_place *p;
    CODE:
        p = tks_place_of(aTHX_ self, ix ? "locale" : "zone_name");
        RETVAL = tks_name_sv(aTHX_ ix ? p->locale_id : p->zone_id);
        if (ix)
            SvUTF8_off(RETVAL);
    OUTPUT:
        RETVAL

# The sun's place from here at an instant; or, with a body first, that
# body's: the moon's, a planet's or a star's from its own class, with
# place => this Sky.
SV *
position(self, ...)
        SV *self
    PREINIT:
        const tks_place *p;
        time_keeper_instant in;
        tks_sunview v;
        HV *hv;
        int i, precise = 0, at = 1, kind = TKS_B_SUN, idx;
        SV *t;
    CODE:
        p = tks_place_of(aTHX_ self, "position");
        if (items < 2)
            croak("position takes an instant, or a body and an instant");
        if (items % 2) {
            kind = tks_body_kind_arg(aTHX_ ST(1), &idx, "position", "position takes an instant and then name and value pairs");
            at = 2;
        }
        if (kind != TKS_B_SUN)
            RETVAL = tks_body_call(aTHX_ kind, idx, ST(1), "position", NULL, ST(2), ax, 3, items, self);
        else {
            t = ST(at);
            for (i = at + 1; i < items; i += 2) {
                STRLEN klen;
                const char *k;
                SvGETMAGIC(ST(i));
                k = SvPV_nomg(ST(i), klen);
                SvGETMAGIC(ST(i + 1));
                if (klen == 7 && memEQ(k, "precise", 7)) precise = SvTRUE(ST(i + 1));
                else croak("position: unknown argument '%.*s'", (int)klen, k);
            }
            tks_instant_arg(aTHX_ t, &in, "position");
            tks_year_check(aTHX_ &in, "position");
            if (precise)
                tks_sun_view_precise(aTHX_ p, &in, &v);
            else
                tks_sun_view(aTHX_ p, &in, &v);
            hv = newHV();
            (void)hv_stores(hv, "altitude",          newSVnv(v.alt));
            (void)hv_stores(hv, "apparent_altitude", newSVnv(v.app_alt));
            (void)hv_stores(hv, "azimuth",           newSVnv(v.az));
            (void)hv_stores(hv, "hour_angle",        newSVnv(v.H));
            (void)hv_stores(hv, "declination",       newSVnv(v.sun.dec));
            (void)hv_stores(hv, "right_ascension",   newSVnv(v.sun.ra));
            (void)hv_stores(hv, "equation_of_time",  newSVnv(v.sun.eot));
            (void)hv_stores(hv, "distance",          newSVnv(v.sun.R));
            RETVAL = newRV_noinc((SV *)hv);
        }
    OUTPUT:
        RETVAL

# The sun's track from here; or, with a body first, that body's.
SV *
track(self, ...)
        SV *self
    PREINIT:
        const tks_place *p;
        tks_track_sv a;
        time_keeper_instant from;
        IV step, n;
        int kind = TKS_B_SUN, idx, at = 1;
    CODE:
        p = tks_place_of(aTHX_ self, "track");
        if (items % 2 == 0) {
            kind = tks_body_kind_arg(aTHX_ ST(1), &idx, "track", "track takes name and value pairs: from, to, step");
            at = 2;
        }
        if (kind != TKS_B_SUN)
            RETVAL = tks_body_call(aTHX_ kind, idx, ST(1), "track", NULL, NULL, ax, 2, items, self);
        else {
            tks_track_args(aTHX_ &ST(at), items - at, &a, 0, "track");
            n = tks_track_span(aTHX_ &a, &from, &step, "track");
            RETVAL = tks_sun_track(aTHX_ p, &from, step, n);
        }
    OUTPUT:
        RETVAL

# Where the sun is overhead: (latitude, east longitude). The place, if
# called on one, does not enter into it.
void
sub_point(self, t)
        SV *self
        SV *t
    PREINIT:
        time_keeper_instant in;
        double lat, lon;
    CODE:
        PERL_UNUSED_VAR(self);
        tks_instant_arg(aTHX_ t, &in, "sub_point");
        tks_year_check(aTHX_ &in, "sub_point");
        tks_sub_point(aTHX_ &in, 0, &lat, &lon);
        ST(0) = sv_2mortal(newSVnv(lat));
        ST(1) = sv_2mortal(newSVnv(lon));
        XSRETURN(2);

# ---- the seasons ---------------------------------------------------------

MODULE = Time::Keeper::Sky    PACKAGE = Time::Keeper::Sky

SV *
equinox(class, ...)
        SV *class
    ALIAS:
        solstice = 1
    PREINIT:
        const char *what;
        tks_place p;
        int64_t year = 0;
        int have_year = 0, which = -1, i;
        time_keeper_instant t;
    CODE:
        PERL_UNUSED_VAR(class);
        what = ix ? "Time::Keeper::Sun->solstice" : "Time::Keeper::Sun->equinox";
        if ((items - 1) % 2)
            croak("%s takes name and value pairs", what);
        tks_place_for_zone(aTHX_ &p, "UTC", 3, "en", 2, what);
        for (i = 1; i < items; i += 2) {
            STRLEN klen;
            const char *k = SvPV(ST(i), klen);
            SV *v = ST(i + 1);
            SvGETMAGIC(v);
            if (klen == 4 && memEQ(k, "year", 4)) {
                if (!SvOK(v) || !looks_like_number(v))
                    croak("%s: year must be a number", what);
                year = (int64_t)SvIV(v);
                have_year = 1;
            }
            else if (klen == 5 && memEQ(k, "month", 5))
                which = tks_season_arg(aTHX_ v, what);
            else if (klen == 4 && memEQ(k, "zone", 4))
                tks_place_set_zone(aTHX_ &p, v, what);
            else if (klen == 6 && memEQ(k, "locale", 6))
                tks_place_set_locale(aTHX_ &p, v, what);
            else
                croak("%s: unknown argument '%.*s'", what, (int)klen, k);
        }
        if (!have_year)
            croak("%s needs year", what);
        if (which < 0)
            croak("%s needs month => %s", what, ix ? "june or december" : "march or september");
        if (ix == 0 && (which == TKS_SEASON_JUNE || which == TKS_SEASON_DECEMBER))
            croak("%s: there is no equinox in %s; solstice takes it", what, tks_season_name[which]);
        if (ix == 1 && (which == TKS_SEASON_MARCH || which == TKS_SEASON_SEPTEMBER))
            croak("%s: there is no solstice in %s; equinox takes it", what, tks_season_name[which]);
        if (year < TKS_YEAR_MIN || year > TKS_YEAR_MAX)
            croak("%s: the year %" IVdf " is outside the years Time::Keeper::Sun computes (%d to %d)", what, (IV)year, TKS_YEAR_MIN, TKS_YEAR_MAX);
        t.sec = tks_season_instant(aTHX_ year, which);
        t.nsec = 0;
        RETVAL = tks_value_sv(aTHX_ &p, t.sec);
    OUTPUT:
        RETVAL

void
seasons(class, ...)
        SV *class
    PREINIT:
        tks_place p;
        int64_t year = 0;
        int have_year = 0, i;
    PPCODE:
        PERL_UNUSED_VAR(class);
        if ((items - 1) % 2)
            croak("Time::Keeper::Sun->seasons takes name and value pairs");
        tks_place_for_zone(aTHX_ &p, "UTC", 3, "en", 2, "Time::Keeper::Sun->seasons");
        for (i = 1; i < items; i += 2) {
            STRLEN klen;
            const char *k = SvPV(ST(i), klen);
            SV *v = ST(i + 1);
            SvGETMAGIC(v);
            if (klen == 4 && memEQ(k, "year", 4)) {
                if (!SvOK(v) || !looks_like_number(v))
                    croak("Time::Keeper::Sun->seasons: year must be a number");
                year = (int64_t)SvIV(v);
                have_year = 1;
            }
            else if (klen == 4 && memEQ(k, "zone", 4))
                tks_place_set_zone(aTHX_ &p, v, "Time::Keeper::Sun->seasons");
            else if (klen == 6 && memEQ(k, "locale", 6))
                tks_place_set_locale(aTHX_ &p, v, "Time::Keeper::Sun->seasons");
            else
                croak("Time::Keeper::Sun->seasons: unknown argument '%.*s'", (int)klen, k);
        }
        if (!have_year)
            croak("Time::Keeper::Sun->seasons needs year");
        if (year < TKS_YEAR_MIN || year > TKS_YEAR_MAX)
            croak("Time::Keeper::Sun->seasons: the year %" IVdf " is outside the years Time::Keeper::Sun computes (%d to %d)", (IV)year, TKS_YEAR_MIN, TKS_YEAR_MAX);
        EXTEND(SP, 4);
        for (i = 0; i < 4; i++)
            mPUSHs(tks_value_sv(aTHX_ &p, tks_season_instant(aTHX_ year, i)));

# ---- places --------------------------------------------------------------

MODULE = Time::Keeper::Sky    PACKAGE = Time::Keeper::Sky

void
place_of(class, name)
        SV *class
        SV *name
    PREINIT:
        STRLEN len;
        const char *s;
        const tks_place_row *row;
    PPCODE:
        PERL_UNUSED_VAR(class);
        SvGETMAGIC(name);
        if (!SvOK(name))
            croak("Time::Keeper::Sun->place_of needs a zone name");
        s = SvPVutf8(name, len);
        row = tks_place_find(s, len);
        if (!row)
            croak("Time::Keeper::Sun->place_of: no place is known for '%.*s' (a zone of tzdata " TKS_PLACES_RELEASE ")", (int)len, s);
        EXTEND(SP, 2);
        mPUSHn(row->lat / 10000.0);
        mPUSHn(row->lon / 10000.0);

void
places(class)
        SV *class
    PREINIT:
        int i;
    PPCODE:
        PERL_UNUSED_VAR(class);
        EXTEND(SP, TKS_PLACES_COUNT);
        for (i = 0; i < TKS_PLACES_COUNT; i++)
            mPUSHs(newSVpv(tks_places[i].name, 0));

SV *
places_release(class)
        SV *class
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = newSVpvs(TKS_PLACES_RELEASE);
    OUTPUT:
        RETVAL
