# The moon: its phases, and a day's phase in a zone.

MODULE = Time::Keeper::Sun    PACKAGE = Time::Keeper::Moon

# zone => and locale => from a list of pairs into a place that holds only
# them; other keys are left for the caller, who passes the ones it takes.
SV *
phase_name(class, t)
        SV *class
        SV *t
    ALIAS:
        phase_angle = 1
        elongation = 2
        illumination = 3
        age = 4
        lunation = 5
    PREINIT:
        static const char *const names[6] = { "phase_name", "phase_angle", "elongation", "illumination", "age", "lunation" };
        time_keeper_instant in;
        tks_moon m;
        const char *what;
    CODE:
        PERL_UNUSED_VAR(class);
        what = names[ix];
        tks_instant_arg(aTHX_ t, &in, what);
        tks_year_check(aTHX_ &in, what);
        tks_moon_at(aTHX_ &in, &m);
        switch (ix) {
        case 0: RETVAL = newSVpv(tks_moon_name[m.name], 0); break;
        case 1: RETVAL = newSVnv(m.phase_angle); break;
        case 2: RETVAL = newSVnv(m.elongation); break;
        case 3: RETVAL = newSVnv(m.illumination); break;
        case 4: RETVAL = newSVnv(m.age); break;
        default: RETVAL = newSViv((IV)m.k_new + TKS_LUNATION_BROWN_AT_K0); break;
        }
    OUTPUT:
        RETVAL

SV *
next(class, ...)
        SV *class
    ALIAS:
        previous = 1
    PREINIT:
        SV *place_sv = NULL, *zone_sv = NULL, *locale_sv = NULL;
        const char *what;
        tks_place p;
        time_keeper_instant in;
        int have_t = 0, which = -1, i;
        double k;
        int64_t sec;
    CODE:
        PERL_UNUSED_VAR(class);
        what = ix ? "Time::Keeper::Moon->previous" : "Time::Keeper::Moon->next";
        if ((items - 1) % 2)
            croak("%s takes name and value pairs", what);
        for (i = 1; i < items; i += 2) {
            STRLEN klen;
            const char *k2 = SvPV(ST(i), klen);
            SV *v = ST(i + 1);
            SvGETMAGIC(v);
            if (klen == 5 && memEQ(k2, "phase", 5))
                which = tks_phase_arg(aTHX_ v, what);
            else if ((klen == 5 && memEQ(k2, "after", 5) && !ix) || (klen == 6 && memEQ(k2, "before", 6) && ix)) {
                tks_instant_arg(aTHX_ v, &in, what);
                have_t = 1;
            }
            else if (klen == 5 && memEQ(k2, "place", 5))
                place_sv = v;
            else if (klen == 4 && memEQ(k2, "zone", 4))
                zone_sv = v;
            else if (klen == 6 && memEQ(k2, "locale", 6))
                locale_sv = v;
            else
                croak("%s: unknown argument '%.*s'", what, (int)klen, k2);
        }
        tks_where(aTHX_ &p, place_sv, zone_sv, locale_sv, what);
        if (which < 0)
            croak("%s needs phase => new, first_quarter, full or last_quarter", what);
        if (!have_t && (tks_tk(aTHX)->now)(&in) != TIME_KEEPER_OK)
            croak("%s: the clock could not be read", what);
        tks_year_check(aTHX_ &in, what);
        tks_phase_next(aTHX_ in.sec, which, ix, &k, &sec);
        RETVAL = tks_value_sv(aTHX_ &p, sec);
    OUTPUT:
        RETVAL

void
phases(class, ...)
        SV *class
    PREINIT:
        SV *place_sv = NULL, *zone_sv = NULL, *locale_sv = NULL;
        tks_place p;
        time_keeper_instant from, to;
        int have_from = 0, have_to = 0, i, n;
        tks_phase_row rows[64];
    PPCODE:
        PERL_UNUSED_VAR(class);
        if ((items - 1) % 2)
            croak("Time::Keeper::Moon->phases takes name and value pairs");
        for (i = 1; i < items; i += 2) {
            STRLEN klen;
            const char *k2 = SvPV(ST(i), klen);
            SV *v = ST(i + 1);
            SvGETMAGIC(v);
            if (klen == 4 && memEQ(k2, "from", 4))      { tks_instant_arg(aTHX_ v, &from, "Time::Keeper::Moon->phases"); have_from = 1; }
            else if (klen == 2 && memEQ(k2, "to", 2))   { tks_instant_arg(aTHX_ v, &to, "Time::Keeper::Moon->phases"); have_to = 1; }
            else if (klen == 5 && memEQ(k2, "place", 5)) place_sv = v;
            else if (klen == 4 && memEQ(k2, "zone", 4)) zone_sv = v;
            else if (klen == 6 && memEQ(k2, "locale", 6)) locale_sv = v;
            else croak("Time::Keeper::Moon->phases: unknown argument '%.*s'", (int)klen, k2);
        }
        tks_where(aTHX_ &p, place_sv, zone_sv, locale_sv, "Time::Keeper::Moon->phases");
        if (!have_from || !have_to)
            croak("Time::Keeper::Moon->phases needs from and to");
        tks_year_check(aTHX_ &from, "Time::Keeper::Moon->phases");
        tks_year_check(aTHX_ &to, "Time::Keeper::Moon->phases");
        if (to.sec - from.sec > 366LL * 86400)
            croak("Time::Keeper::Moon->phases takes at most a year at a time");
        n = tks_phases_between(aTHX_ from.sec, to.sec, rows, 64);
        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            AV *pair = newAV();
            av_push(pair, newSVpv(tks_phase_kind_name[tks_phase_which(rows[i].k)], 0));
            av_push(pair, tks_value_sv(aTHX_ &p, rows[i].sec));
            mPUSHs(newRV_noinc((SV *)pair));
        }

SV *
on(class, date, ...)
        SV *class
        SV *date
    PREINIT:
        SV *place_sv = NULL, *zone_sv = NULL, *locale_sv = NULL;
        dMY_CXT;
        tks_place p;
        tks_moonday d;
        time_keeper_instant t;
        time_keeper_civil c;
        int64_t days, start, end, noon, y;
        int m, dd, i, has_place;
        SV *inner;
    CODE:
        PERL_UNUSED_VAR(class);
        if ((items - 2) % 2)
            croak("Time::Keeper::Moon->on takes a date and then name and value pairs");
        SvGETMAGIC(date);
        for (i = 2; i < items; i += 2) {
            STRLEN klen;
            const char *k2 = SvPV(ST(i), klen);
            SvGETMAGIC(ST(i + 1));
            if (klen == 5 && memEQ(k2, "place", 5)) place_sv = ST(i + 1);
            else if (klen == 4 && memEQ(k2, "zone", 4)) zone_sv = ST(i + 1);
            else if (klen == 6 && memEQ(k2, "locale", 6)) locale_sv = ST(i + 1);
            else croak("Time::Keeper::Moon->on: unknown argument '%.*s'", (int)klen, k2);
        }
        has_place = tks_where(aTHX_ &p, place_sv, zone_sv, locale_sv, "Time::Keeper::Moon->on");
        if (SvROK(date) && sv_derived_from(date, "Time::Keeper::Date"))
            days = tks_days_of_date(aTHX_ date);
        else if (SvROK(date) && (tks_tk(aTHX)->from_sv)(aTHX_ date, &t, NULL, NULL) == TIME_KEEPER_OK)
            days = tks_days_in_zone(aTHX_ &p, &t, "Time::Keeper::Moon->on");
        else
            croak("Time::Keeper::Moon->on takes a Time::Keeper::Date or a Time::Keeper value");
        start = tks_midnight(aTHX_ &p, days, "Time::Keeper::Moon->on");
        end   = tks_midnight(aTHX_ &p, days + 1, "Time::Keeper::Moon->on");
        memset(&c, 0, sizeof c);
        tks_civil_from_days(days, &y, &m, &dd);
        c.year = y; c.month = m; c.day = dd; c.hour = 12;
        if ((tks_tk(aTHX)->from_civil)(aTHX_ &c, &p.zone, TIME_KEEPER_GAP_FORWARD, TIME_KEEPER_OVERLAP_EARLIER, &t) != TIME_KEEPER_OK)
            noon = start + (end - start) / 2;
        else
            noon = t.sec;
        t.sec = start; t.nsec = 0;
        tks_year_check(aTHX_ &t, "Time::Keeper::Moon->on");
        t.sec = end - 1;
        tks_year_check(aTHX_ &t, "Time::Keeper::Moon->on");
        tks_moonday_compute(aTHX_ &p, days, start, end, noon, &d);
        d.has_place = (uint8_t)has_place;
        if (has_place)
            tks_moonday_rise(aTHX_ &d);
        inner = newSVpvn((const char *)&d, sizeof d);
        RETVAL = sv_bless(newRV_noinc(inner), MY_CXT.mstash);
    OUTPUT:
        RETVAL

MODULE = Time::Keeper::Sun    PACKAGE = Time::Keeper::Moon::Day

SV *
phase_name(self)
        SV *self
    PREINIT:
        const tks_moonday *d;
    CODE:
        d = tks_moonday_of(aTHX_ self, "phase_name");
        RETVAL = newSVpv(tks_moon_name[d->name], 0);
    OUTPUT:
        RETVAL

SV *
phase(self)
        SV *self
    PREINIT:
        const tks_moonday *d;
    CODE:
        d = tks_moonday_of(aTHX_ self, "phase");
        RETVAL = d->principal < 0 ? &PL_sv_undef : tks_value_sv(aTHX_ &d->place, d->principal_sec);
    OUTPUT:
        RETVAL

NV
illumination(self)
        SV *self
    ALIAS:
        age = 1
    PREINIT:
        const tks_moonday *d;
    CODE:
        d = tks_moonday_of(aTHX_ self, ix ? "age" : "illumination");
        RETVAL = ix ? d->age : d->illumination;
    OUTPUT:
        RETVAL

SV *
date(self)
        SV *self
    PREINIT:
        const tks_moonday *d;
    CODE:
        d = tks_moonday_of(aTHX_ self, "date");
        RETVAL = tks_date_sv(aTHX_ d->days);
    OUTPUT:
        RETVAL

SV *
place(self)
        SV *self
    PREINIT:
        dMY_CXT;
        const tks_moonday *d;
    CODE:
        d = tks_moonday_of(aTHX_ self, "place");
        RETVAL = d->has_place ? sv_bless(newRV_noinc(newSVpvn((const char *)&d->place, sizeof d->place)), MY_CXT.pstash) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
zone_name(self)
        SV *self
    PREINIT:
        const tks_moonday *d;
    CODE:
        d = tks_moonday_of(aTHX_ self, "zone_name");
        RETVAL = tks_name_sv(aTHX_ d->place.zone_id);
    OUTPUT:
        RETVAL

SV *
start(self)
        SV *self
    ALIAS:
        end = 1
        noon = 2
    PREINIT:
        const tks_moonday *d;
    CODE:
        d = tks_moonday_of(aTHX_ self, ix == 0 ? "start" : ix == 1 ? "end" : "noon");
        RETVAL = tks_value_sv(aTHX_ &d->place, ix == 0 ? d->start : ix == 1 ? d->end : d->noon);
    OUTPUT:
        RETVAL

MODULE = Time::Keeper::Sun    PACKAGE = Time::Keeper::Moon

# The moon's geocentric place at an instant; with place => also its
# topocentric altitude and azimuth from there (T6: none without a place).
SV *
position(class, t, ...)
        SV *class
        SV *t
    PREINIT:
        time_keeper_instant in;
        tks_moonplace m;
        tks_moonview v;
        tks_place p;
        SV *place_sv = NULL;
        HV *hv;
        int i;
    CODE:
        PERL_UNUSED_VAR(class);
        if ((items - 2) % 2)
            croak("Time::Keeper::Moon->position takes an instant and then name and value pairs");
        for (i = 2; i < items; i += 2) {
            STRLEN klen;
            const char *k2 = SvPV(ST(i), klen);
            SvGETMAGIC(ST(i + 1));
            if (klen == 5 && memEQ(k2, "place", 5)) place_sv = ST(i + 1);
            else croak("Time::Keeper::Moon->position: unknown argument '%.*s'", (int)klen, k2);
        }
        tks_instant_arg(aTHX_ t, &in, "Time::Keeper::Moon->position");
        tks_year_check(aTHX_ &in, "Time::Keeper::Moon->position");
        hv = newHV();
        if (place_sv) {
            tks_where(aTHX_ &p, place_sv, NULL, NULL, "Time::Keeper::Moon->position");
            tks_moon_view(aTHX_ &p, &in, &v);
            m = v.m;
            (void)hv_stores(hv, "altitude",          newSVnv(v.alt));
            (void)hv_stores(hv, "apparent_altitude", newSVnv(v.app_alt));
            (void)hv_stores(hv, "azimuth",           newSVnv(v.az));
            (void)hv_stores(hv, "hour_angle",        newSVnv(v.Ht));
        }
        else
            tks_moon_place(tks_jde(aTHX_ &in), &m);
        (void)hv_stores(hv, "longitude",       newSVnv(m.lon));
        (void)hv_stores(hv, "latitude",        newSVnv(m.lat));
        (void)hv_stores(hv, "right_ascension", newSVnv(m.ra));
        (void)hv_stores(hv, "declination",     newSVnv(m.dec));
        (void)hv_stores(hv, "distance",        newSVnv(m.distance));
        (void)hv_stores(hv, "parallax",        newSVnv(m.parallax));
        RETVAL = newRV_noinc((SV *)hv);
    OUTPUT:
        RETVAL

MODULE = Time::Keeper::Sun    PACKAGE = Time::Keeper::Moon

# The moon's next or previous rise, set or upper transit from an instant,
# seen from a place (place => is required).
SV *
next_moonrise(class, t, ...)
        SV *class
        SV *t
    ALIAS:
        next_moonset = 1
        previous_moonrise = 2
        previous_moonset = 3
        next_moon_transit = 4
        previous_moon_transit = 5
    PREINIT:
        static const char *const names[6] = {
            "Time::Keeper::Moon->next_moonrise", "Time::Keeper::Moon->next_moonset",
            "Time::Keeper::Moon->previous_moonrise", "Time::Keeper::Moon->previous_moonset",
            "Time::Keeper::Moon->next_moon_transit", "Time::Keeper::Moon->previous_moon_transit" };
        SV *place_sv = NULL, *zone_sv = NULL, *locale_sv = NULL;
        tks_place p;
        time_keeper_instant in;
        int64_t out;
        int i;
    CODE:
        PERL_UNUSED_VAR(class);
        if ((items - 2) % 2)
            croak("%s takes an instant and then name and value pairs", names[ix]);
        for (i = 2; i < items; i += 2) {
            STRLEN klen;
            const char *k2 = SvPV(ST(i), klen);
            SV *v = ST(i + 1);
            SvGETMAGIC(v);
            if (klen == 5 && memEQ(k2, "place", 5)) place_sv = v;
            else if (klen == 4 && memEQ(k2, "zone", 4)) zone_sv = v;
            else if (klen == 6 && memEQ(k2, "locale", 6)) locale_sv = v;
            else croak("%s: unknown argument '%.*s'", names[ix], (int)klen, k2);
        }
        if (!place_sv)
            croak("%s needs place => a Time::Keeper::Sun place", names[ix]);
        tks_where(aTHX_ &p, place_sv, zone_sv, locale_sv, names[ix]);
        tks_instant_arg(aTHX_ t, &in, names[ix]);
        tks_year_check(aTHX_ &in, names[ix]);
        if (ix >= 4)
            RETVAL = tks_value_sv(aTHX_ &p, tks_moon_transit_find(aTHX_ &p, in.sec, ix == 5));
        else if (tks_moon_find(aTHX_ &p, in.sec, ix % 2, ix >= 2, &out))
            RETVAL = tks_value_sv(aTHX_ &p, out);
        else
            RETVAL = &PL_sv_undef;
    OUTPUT:
        RETVAL

MODULE = Time::Keeper::Sun    PACKAGE = Time::Keeper::Moon::Day

SV *
moonrise(self)
        SV *self
    ALIAS:
        moonset = 1
        moon_transit = 2
    PREINIT:
        const tks_moonday *d;
    CODE:
        d = tks_moonday_of(aTHX_ self, tks_moon_event_name[ix]);
        if (!d->has_place)
            croak("%s: the day was made without a place; give place => to Time::Keeper::Moon->on", tks_moon_event_name[ix]);
        RETVAL = d->mn[ix] ? tks_value_sv(aTHX_ &d->place, d->start + d->mev[ix][0]) : &PL_sv_undef;
    OUTPUT:
        RETVAL

void
moonrises(self)
        SV *self
    ALIAS:
        moonsets = 1
        moon_transits = 2
    PREINIT:
        static const char *const names[3] = { "moonrises", "moonsets", "moon_transits" };
        const tks_moonday *d;
        int i, n;
    PPCODE:
        d = tks_moonday_of(aTHX_ self, names[ix]);
        if (!d->has_place)
            croak("%s: the day was made without a place; give place => to Time::Keeper::Moon->on", names[ix]);
        n = d->mn[ix] > 2 ? 2 : d->mn[ix];
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            mPUSHs(tks_value_sv(aTHX_ &d->place, d->start + d->mev[ix][i]));

IV
is_moon_up_all_day(self)
        SV *self
    ALIAS:
        is_moon_down_all_day = 1
    PREINIT:
        const tks_moonday *d;
        const char *what;
    CODE:
        what = ix ? "is_moon_down_all_day" : "is_moon_up_all_day";
        d = tks_moonday_of(aTHX_ self, what);
        if (!d->has_place)
            croak("%s: the day was made without a place; give place => to Time::Keeper::Moon->on", what);
        RETVAL = ix ? d->down_all : d->up_all;
    OUTPUT:
        RETVAL

# Every event of the day in order: the principal phase if one falls in it,
# and with a place the moonrises, moonsets and upper transits.
void
events(self)
        SV *self
    PREINIT:
        const tks_moonday *d;
        int64_t when[8];
        const char *name[8];
        int n = 0, k, i, a, b;
    PPCODE:
        d = tks_moonday_of(aTHX_ self, "events");
        if (d->principal >= 0) {
            when[n] = d->principal_sec;
            name[n] = tks_phase_kind_name[d->principal];
            n++;
        }
        if (d->has_place)
            for (k = 0; k < 3; k++)
                for (i = 0; i < d->mn[k] && i < 2; i++) {
                    when[n] = d->start + d->mev[k][i];
                    name[n] = tks_moon_event_name[k];
                    n++;
                }
        for (a = 1; a < n; a++) {
            int64_t w = when[a];
            const char *nm = name[a];
            for (b = a - 1; b >= 0 && when[b] > w; b--) {
                when[b + 1] = when[b];
                name[b + 1] = name[b];
            }
            when[b + 1] = w;
            name[b + 1] = nm;
        }
        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            AV *pair = newAV();
            av_push(pair, newSVpv(name[i], 0));
            av_push(pair, tks_value_sv(aTHX_ &d->place, when[i]));
            mPUSHs(newRV_noinc((SV *)pair));
        }
