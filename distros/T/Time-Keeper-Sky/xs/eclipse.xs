# Eclipses.

MODULE = Time::Keeper::Sky    PACKAGE = Time::Keeper::Eclipse

# The next (or previous) eclipse of a kind after (before) an instant or now.
SV *
next(class, ...)
        SV *class
    ALIAS:
        previous = 1
    PREINIT:
        const char *what = ix ? "Time::Keeper::Eclipse->previous" : "Time::Keeper::Eclipse->next";
        dMY_CXT;
        SV *kind_sv = NULL, *from_sv = NULL, *place_sv = NULL, *zone_sv = NULL, *locale_sv = NULL;
        tks_place p;
        tks_eclipse e;
        time_keeper_instant in;
        int i, kind, found;
    CODE:
        PERL_UNUSED_VAR(class);
        if ((items - 1) % 2)
            croak("%s takes name and value pairs", what);
        for (i = 1; i < items; i += 2) {
            STRLEN klen;
            const char *k;
            SV *v = ST(i + 1);
            SvGETMAGIC(ST(i));
            k = SvPV_nomg(ST(i), klen);
            SvGETMAGIC(v);
            if (klen == 4 && memEQ(k, "kind", 4)) kind_sv = v;
            else if (!ix && klen == 5 && memEQ(k, "after", 5)) from_sv = v;
            else if (ix && klen == 6 && memEQ(k, "before", 6)) from_sv = v;
            else if (klen == 5 && memEQ(k, "place", 5)) place_sv = v;
            else if (klen == 4 && memEQ(k, "zone", 4)) zone_sv = v;
            else if (klen == 6 && memEQ(k, "locale", 6)) locale_sv = v;
            else croak("%s: unknown argument '%.*s'", what, (int)klen, k);
        }
        kind = tks_eclipse_kind_arg(aTHX_ kind_sv, what);
        tks_where(aTHX_ &p, place_sv, zone_sv, locale_sv, what);
        if (from_sv)
            tks_instant_arg(aTHX_ from_sv, &in, what);
        else if ((tks_tk(aTHX)->now)(&in) != TIME_KEEPER_OK)
            croak("%s: the clock could not be read", what);
        tks_year_check(aTHX_ &in, what);
        found = 0;
        if (kind == TKS_E_LUNAR)
            found = tks_lunar_eclipse_find(aTHX_ in.sec, ix, &p, &e);
        else {
            /* with a place, the next one seen from there: some of it with the sun up */
            int64_t at = in.sec;
            int tries;
            for (tries = 0; tries < 400; tries++) {
                tks_local L;
                if (!tks_solar_eclipse_find(aTHX_ at, ix, &p, &e))
                    break;
                if (!place_sv || (tks_local_compute(aTHX_ &p, e.jde_greatest, &L) && tks_local_sun_up(aTHX_ &L))) {
                    found = 1;
                    break;
                }
                at = e.greatest;
            }
        }
        if (found)
            RETVAL = sv_bless(newRV_noinc(newSVpvn((const char *)&e, sizeof e)), MY_CXT.estash);
        else
            RETVAL = &PL_sv_undef;
    OUTPUT:
        RETVAL

# Every eclipse of a kind with its greatest from one instant to another, in
# order (at most a century).
void
between(class, ...)
        SV *class
    PREINIT:
        const char *what = "Time::Keeper::Eclipse->between";
        dMY_CXT;
        SV *kind_sv = NULL, *from_sv = NULL, *to_sv = NULL, *place_sv = NULL, *zone_sv = NULL, *locale_sv = NULL;
        tks_place p;
        tks_eclipse e;
        time_keeper_instant from, to;
        int i, kind;
        int64_t at;
    PPCODE:
        PERL_UNUSED_VAR(class);
        if ((items - 1) % 2)
            croak("%s takes name and value pairs", what);
        for (i = 1; i < items; i += 2) {
            STRLEN klen;
            const char *k;
            SV *v = ST(i + 1);
            SvGETMAGIC(ST(i));
            k = SvPV_nomg(ST(i), klen);
            SvGETMAGIC(v);
            if (klen == 4 && memEQ(k, "kind", 4)) kind_sv = v;
            else if (klen == 4 && memEQ(k, "from", 4)) from_sv = v;
            else if (klen == 2 && memEQ(k, "to", 2)) to_sv = v;
            else if (klen == 5 && memEQ(k, "place", 5)) place_sv = v;
            else if (klen == 4 && memEQ(k, "zone", 4)) zone_sv = v;
            else if (klen == 6 && memEQ(k, "locale", 6)) locale_sv = v;
            else croak("%s: unknown argument '%.*s'", what, (int)klen, k);
        }
        kind = tks_eclipse_kind_arg(aTHX_ kind_sv, what);
        if (!from_sv || !to_sv)
            croak("%s needs from => and to =>", what);
        tks_where(aTHX_ &p, place_sv, zone_sv, locale_sv, what);
        tks_instant_arg(aTHX_ from_sv, &from, what);
        tks_instant_arg(aTHX_ to_sv, &to, what);
        tks_year_check(aTHX_ &from, what);
        tks_year_check(aTHX_ &to, what);
        if (to.sec <= from.sec)
            croak("%s: to must be after from", what);
        if (to.sec - from.sec > (int64_t)36525 * 86400 + 86400)
            croak("%s: a span of at most a century", what);
        at = from.sec - 1;
        while ((kind == TKS_E_LUNAR ? tks_lunar_eclipse_find(aTHX_ at, 0, &p, &e) : tks_solar_eclipse_find(aTHX_ at, 0, &p, &e))
               && e.greatest <= to.sec) {
            EXTEND(SP, 1);
            mPUSHs(sv_bless(newRV_noinc(newSVpvn((const char *)&e, sizeof e)), MY_CXT.estash));
            at = e.greatest;
        }

SV *
kind(self)
        SV *self
    ALIAS:
        type = 1
    PREINIT:
        const tks_eclipse *e;
    CODE:
        e = tks_eclipse_of(aTHX_ self, ix ? "type" : "kind");
        RETVAL = newSVpv(ix ? (e->kind == TKS_E_LUNAR ? tks_lunar_type_name[e->type] : tks_solar_type_name[e->type])
                            : (e->kind == TKS_E_LUNAR ? "lunar" : "solar"), 0);
    OUTPUT:
        RETVAL

SV *
greatest(self)
        SV *self
    PREINIT:
        const tks_eclipse *e;
    CODE:
        e = tks_eclipse_of(aTHX_ self, "greatest");
        RETVAL = tks_value_sv(aTHX_ &e->place, e->greatest);
    OUTPUT:
        RETVAL

NV
umbral_magnitude(self)
        SV *self
    ALIAS:
        penumbral_magnitude = 1
        gamma = 2
    PREINIT:
        const tks_eclipse *e;
    CODE:
        e = tks_eclipse_of(aTHX_ self, ix == 0 ? "umbral_magnitude" : ix == 1 ? "penumbral_magnitude" : "gamma");
        if (ix < 2 && e->kind != TKS_E_LUNAR)
            croak("%s: a solar eclipse has a magnitude, not an umbral or penumbral one", ix ? "penumbral_magnitude" : "umbral_magnitude");
        RETVAL = ix == 0 ? e->umbral : ix == 1 ? e->penumbral : e->gamma;
    OUTPUT:
        RETVAL

# The contacts the eclipse has, in order, as [name, value] pairs.
void
contacts(self)
        SV *self
    PREINIT:
        const tks_eclipse *e;
        int i;
    PPCODE:
        e = tks_eclipse_of(aTHX_ self, "contacts");
        if (e->kind != TKS_E_LUNAR)
            croak("contacts: a solar eclipse's contacts are a place's: ask local(place => ...)");
        for (i = 0; i < 6; i++) {
            AV *pair;
            if (!e->has[i])
                continue;
            pair = newAV();
            av_push(pair, newSVpv(tks_lunar_contact_name[i], 0));
            av_push(pair, tks_value_sv(aTHX_ &e->place, e->contact[i]));
            EXTEND(SP, 1);
            mPUSHs(newRV_noinc((SV *)pair));
        }

# One contact by name (p1 u1 u2 u3 u4 p4), or undef if the eclipse has none.
SV *
contact(self, name)
        SV *self
        SV *name
    PREINIT:
        const tks_eclipse *e;
        STRLEN len;
        const char *s;
        int i, which = -1;
    CODE:
        e = tks_eclipse_of(aTHX_ self, "contact");
        if (e->kind != TKS_E_LUNAR)
            croak("contact: a solar eclipse's contacts are a place's: ask local(place => ...)");
        SvGETMAGIC(name);
        s = SvPV_nomg(name, len);
        for (i = 0; i < 6; i++)
            if (tks_ci_eq(s, len, tks_lunar_contact_name[i]))
                which = i;
        if (which < 0)
            croak("contact: no contact is called '%.*s' (p1, u1, u2, u3, u4 or p4)", (int)len, s);
        RETVAL = e->has[which] ? tks_value_sv(aTHX_ &e->place, e->contact[which]) : &PL_sv_undef;
    OUTPUT:
        RETVAL

# The contacts seen from a place, as [name, value, altitude] with the moon's
# altitude (topocentric, with refraction) there; only those with the moon up
# unless all => 1.
void
visible(self, ...)
        SV *self
    PREINIT:
        const char *what = "visible";
        const tks_eclipse *e;
        SV *place_sv = NULL;
        tks_place p;
        int i, all = 0;
    PPCODE:
        e = tks_eclipse_of(aTHX_ self, what);
        if (e->kind != TKS_E_LUNAR)
            croak("visible: for a solar eclipse ask local(place => ...)");
        if ((items - 1) % 2)
            croak("%s takes place => and all =>", what);
        for (i = 1; i < items; i += 2) {
            STRLEN klen;
            const char *k;
            SvGETMAGIC(ST(i));
            k = SvPV_nomg(ST(i), klen);
            SvGETMAGIC(ST(i + 1));
            if (klen == 5 && memEQ(k, "place", 5)) place_sv = ST(i + 1);
            else if (klen == 3 && memEQ(k, "all", 3)) all = SvTRUE(ST(i + 1));
            else croak("%s: unknown argument '%.*s'", what, (int)klen, k);
        }
        if (!place_sv)
            croak("%s needs place => a Time::Keeper::Sky", what);
        tks_where(aTHX_ &p, place_sv, NULL, NULL, what);
        for (i = 0; i < 6; i++) {
            time_keeper_instant t;
            tks_moonview v;
            AV *row;
            if (!e->has[i])
                continue;
            t.sec = e->contact[i];
            t.nsec = 0;
            tks_moon_view(aTHX_ &p, &t, &v);
            if (!all && v.app_alt <= 0.0)
                continue;
            row = newAV();
            av_push(row, newSVpv(tks_lunar_contact_name[i], 0));
            av_push(row, tks_value_sv(aTHX_ &p, e->contact[i]));
            av_push(row, newSVnv(v.app_alt));
            EXTEND(SP, 1);
            mPUSHs(newRV_noinc((SV *)row));
        }

# A solar eclipse's: the magnitude at greatest (the moon's diameter over the
# sun's on a central eclipse), and where and how it is seen at greatest.
NV
magnitude(self)
        SV *self
    ALIAS:
        sun_altitude = 1
        path_width = 2
    PREINIT:
        static const char *const names[3] = { "magnitude", "sun_altitude", "path_width" };
        const tks_eclipse *e;
    CODE:
        e = tks_eclipse_of(aTHX_ self, names[ix]);
        if (e->kind != TKS_E_SOLAR)
            croak("%s: a lunar eclipse has umbral_magnitude and penumbral_magnitude", names[ix]);
        RETVAL = ix == 0 ? e->magnitude : ix == 1 ? e->sun_alt : e->width;
    OUTPUT:
        RETVAL

# Where greatest eclipse is seen: (latitude, longitude), degrees.
void
greatest_place(self)
        SV *self
    PREINIT:
        const tks_eclipse *e;
    PPCODE:
        e = tks_eclipse_of(aTHX_ self, "greatest_place");
        if (e->kind != TKS_E_SOLAR)
            croak("greatest_place: a lunar eclipse is seen alike wherever the moon is up");
        EXTEND(SP, 2);
        mPUSHn(e->lat);
        mPUSHn(e->lon);

# The duration of totality or annularity on the central line at greatest,
# a Time::Keeper::Duration, or undef.
SV *
duration(self)
        SV *self
    PREINIT:
        const tks_eclipse *e;
    CODE:
        e = tks_eclipse_of(aTHX_ self, "duration");
        if (e->kind != TKS_E_SOLAR)
            croak("duration: a lunar eclipse's phases are its contacts");
        RETVAL = e->central && e->duration > 0.0 ? tks_duration_sv(aTHX_ (int64_t)e->duration) : &PL_sv_undef;
    OUTPUT:
        RETVAL

# The eclipse seen from a place: a Time::Keeper::Eclipse::Local, or undef if
# the moon covers none of the sun there.
SV *
local(self, ...)
        SV *self
    PREINIT:
        dMY_CXT;
        const tks_eclipse *e;
        SV *place_sv = NULL;
        tks_place p;
        tks_local L;
        int i;
    CODE:
        e = tks_eclipse_of(aTHX_ self, "local");
        if (e->kind != TKS_E_SOLAR)
            croak("local: for a lunar eclipse ask visible(place => ...)");
        for (i = 1; i + 1 < items; i += 2) {
            STRLEN klen;
            const char *k;
            SvGETMAGIC(ST(i));
            k = SvPV_nomg(ST(i), klen);
            SvGETMAGIC(ST(i + 1));
            if (klen == 5 && memEQ(k, "place", 5)) place_sv = ST(i + 1);
            else croak("local: unknown argument '%.*s'", (int)klen, k);
        }
        if (!place_sv)
            croak("local needs place => a Time::Keeper::Sky");
        tks_where(aTHX_ &p, place_sv, NULL, NULL, "local");
        if (tks_local_compute(aTHX_ &p, e->jde_greatest, &L))
            RETVAL = sv_bless(newRV_noinc(newSVpvn((const char *)&L, sizeof L)), MY_CXT.lstash);
        else
            RETVAL = &PL_sv_undef;
    OUTPUT:
        RETVAL

# The central line: where the axis meets the earth every step (seconds, 60
# unless given) from its start to its end, as arrays; undef for an eclipse
# that is not central.
SV *
central_line(self, ...)
        SV *self
    PREINIT:
        const tks_eclipse *e;
        IV step = 60;
        HV *hv;
        AV *ep, *la, *lo, *wi, *du;
        double t, jde_step;
        int i, with_duration = 1;
    CODE:
        e = tks_eclipse_of(aTHX_ self, "central_line");
        if (e->kind != TKS_E_SOLAR)
            croak("central_line: a lunar eclipse has none");
        for (i = 1; i + 1 < items; i += 2) {
            STRLEN klen;
            const char *k;
            SvGETMAGIC(ST(i));
            k = SvPV_nomg(ST(i), klen);
            SvGETMAGIC(ST(i + 1));
            if (klen == 4 && memEQ(k, "step", 4)) step = tks_track_step(aTHX_ ST(i + 1), "central_line");
            else if (klen == 8 && memEQ(k, "duration", 8)) with_duration = SvTRUE(ST(i + 1));
            else croak("central_line: unknown argument '%.*s'", (int)klen, k);
        }
        if (!e->central)
            XSRETURN_UNDEF;
        hv = newHV();
        ep = TKS_TRACK_AV(hv, "epoch", 1);
        la = TKS_TRACK_AV(hv, "latitude", 1);
        lo = TKS_TRACK_AV(hv, "longitude", 1);
        wi = TKS_TRACK_AV(hv, "width", 1);
        du = with_duration ? TKS_TRACK_AV(hv, "duration", 1) : NULL;
        jde_step = (double)step / 86400.0;
        /* from the first whole step after the line begins */
        {
            int64_t first = tks_jde_to_sec(aTHX_ e->central_start);
            int64_t s;
            first += step - (first % step + step) % step;
            for (s = first; ; s += step) {
                time_keeper_instant tt;
                double lat, lon, L2;
                tt.sec = s;
                tt.nsec = 0;
                t = tks_jde(aTHX_ &tt);
                if (t > e->central_end)
                    break;
                if (!tks_central_point(aTHX_ t, &lat, &lon, &L2, NULL))
                    continue;
                av_push(ep, newSViv((IV)s));
                av_push(la, newSVnv(lat));
                av_push(lo, newSVnv(lon));
                av_push(wi, newSVnv(tks_path_width(aTHX_ t)));
                if (du) {
                    tks_place cp;
                    tks_local L;
                    memset(&cp, 0, sizeof cp);
                    cp.lat = lat;
                    cp.lon = lon;
                    av_push(du, tks_local_compute(aTHX_ &cp, t, &L) && L.has[1]
                                ? newSViv((IV)(L.contact[2] - L.contact[1])) : newSV(0));
                }
            }
        }
        PERL_UNUSED_VAR(jde_step);
        RETVAL = newRV_noinc((SV *)hv);
    OUTPUT:
        RETVAL

MODULE = Time::Keeper::Sky    PACKAGE = Time::Keeper::Eclipse::Local

SV *
type(self)
        SV *self
    PREINIT:
        const tks_local *L;
    CODE:
        L = tks_local_of(aTHX_ self, "type");
        RETVAL = newSVpv(tks_solar_type_name[L->type], 0);
    OUTPUT:
        RETVAL

SV *
maximum(self)
        SV *self
    PREINIT:
        const tks_local *L;
    CODE:
        L = tks_local_of(aTHX_ self, "maximum");
        RETVAL = tks_value_sv(aTHX_ &L->place, L->maximum);
    OUTPUT:
        RETVAL

NV
magnitude(self)
        SV *self
    ALIAS:
        obscuration = 1
    PREINIT:
        const tks_local *L;
    CODE:
        L = tks_local_of(aTHX_ self, ix ? "obscuration" : "magnitude");
        RETVAL = ix ? L->obscuration : L->magnitude;
    OUTPUT:
        RETVAL

# The contacts the place sees, as [name, value, altitude, azimuth] with the
# sun's apparent altitude and azimuth: c1 c4 always, c2 c3 in a total or
# annular eclipse there; then the maximum as [maximum, value, ...] last.
void
contacts(self)
        SV *self
    PREINIT:
        const tks_local *L;
        int i;
    PPCODE:
        L = tks_local_of(aTHX_ self, "contacts");
        for (i = 0; i < 4; i++) {
            AV *row;
            if (!L->has[i])
                continue;
            row = newAV();
            av_push(row, newSVpv(tks_solar_contact_name[i], 0));
            av_push(row, tks_value_sv(aTHX_ &L->place, L->contact[i]));
            av_push(row, newSVnv(L->alt[i]));
            av_push(row, newSVnv(L->az[i]));
            EXTEND(SP, 1);
            mPUSHs(newRV_noinc((SV *)row));
        }

SV *
contact(self, name)
        SV *self
        SV *name
    PREINIT:
        const tks_local *L;
        STRLEN len;
        const char *s;
        int i, which = -1;
    CODE:
        L = tks_local_of(aTHX_ self, "contact");
        SvGETMAGIC(name);
        s = SvPV_nomg(name, len);
        for (i = 0; i < 4; i++)
            if (tks_ci_eq(s, len, tks_solar_contact_name[i]))
                which = i;
        if (which < 0)
            croak("contact: no contact is called '%.*s' (c1, c2, c3 or c4)", (int)len, s);
        RETVAL = L->has[which] ? tks_value_sv(aTHX_ &L->place, L->contact[which]) : &PL_sv_undef;
    OUTPUT:
        RETVAL

# The duration of totality or annularity at the place (a Duration), or undef.
SV *
duration(self)
        SV *self
    PREINIT:
        const tks_local *L;
    CODE:
        L = tks_local_of(aTHX_ self, "duration");
        RETVAL = L->has[1] ? tks_duration_sv(aTHX_ L->contact[2] - L->contact[1]) : &PL_sv_undef;
    OUTPUT:
        RETVAL

# The sun's apparent altitude and azimuth at the maximum.
void
sun_at_maximum(self)
        SV *self
    PREINIT:
        const tks_local *L;
    PPCODE:
        L = tks_local_of(aTHX_ self, "sun_at_maximum");
        EXTEND(SP, 2);
        mPUSHn(L->alt[4]);
        mPUSHn(L->az[4]);

# Whether the sun is up at some time between C1 and C4.
IV
is_seen(self)
        SV *self
    PREINIT:
        const tks_local *L;
    CODE:
        L = tks_local_of(aTHX_ self, "is_seen");
        RETVAL = tks_local_sun_up(aTHX_ L);
    OUTPUT:
        RETVAL
