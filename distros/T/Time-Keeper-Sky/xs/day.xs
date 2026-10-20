# A day at a place, and the events around an instant.

MODULE = Time::Keeper::Sky    PACKAGE = Time::Keeper::Sky

SV *
on(self, ...)
        SV *self
    PREINIT:
        dMY_CXT;
        const tks_place *p;
        tks_day d;
        int64_t days, start, end, y = 0;
        int have_y = 0, have_m = 0, have_d = 0, m = 0, dd = 0, i;
        time_keeper_instant t;
        SV *inner;
        int n = items, kind = TKS_B_SUN, idx;
        SV *date = NULL, *body = NULL;
    CODE:
        p = tks_place_of(aTHX_ self, "on");
        /* a body after the date, or alone for today */
        if (items == 3 && SvROK(ST(1)) && !SvROK(ST(2))) {
            date = ST(1);
            body = ST(2);
        }
        else if (items == 2 && SvOK(ST(1)) && !SvROK(ST(1)))
            body = ST(1);
        if (body) {
            kind = tks_body_kind_arg(aTHX_ body, &idx, "on", "on takes a Time::Keeper::Date, a Time::Keeper value, or year, month and day");
            n = date ? 2 : 1;
        }
        if (kind != TKS_B_SUN) {
            if (!date) {
                if ((tks_tk(aTHX)->now)(&t) != TIME_KEEPER_OK)
                    croak("on: the clock could not be read");
                date = sv_2mortal(tks_value_sv(aTHX_ p, t.sec));
            }
            RETVAL = tks_body_call(aTHX_ kind, idx, body, "on", date, NULL, ax, 0, 0, self);
        }
        else {
            if (n == 1) {
                if ((tks_tk(aTHX)->now)(&t) != TIME_KEEPER_OK)
                    croak("on: the clock could not be read");
                days = tks_days_in_zone(aTHX_ p, &t, "on");
            }
            else if (n == 2) {
                SV *arg = ST(1);
                SvGETMAGIC(arg);
                if (SvROK(arg) && sv_derived_from(arg, "Time::Keeper::Date"))
                    days = tks_days_of_date(aTHX_ arg);
                else if (SvROK(arg) && (tks_tk(aTHX)->from_sv)(aTHX_ arg, &t, NULL, NULL) == TIME_KEEPER_OK)
                    days = tks_days_in_zone(aTHX_ p, &t, "on");
                else
                    croak("on takes a Time::Keeper::Date, a Time::Keeper value, or year, month and day");
            }
            else {
                if ((items - 1) % 2)
                    croak("on takes a Time::Keeper::Date, a Time::Keeper value, or year, month and day");
                for (i = 1; i < items; i += 2) {
                    STRLEN klen;
                    const char *k = SvPV(ST(i), klen);
                    SV *v = ST(i + 1);
                    SvGETMAGIC(v);
                    if (!SvOK(v) || !looks_like_number(v))
                        croak("on: %.*s must be a number", (int)klen, k);
                    if (klen == 4 && memEQ(k, "year", 4))       { y = (int64_t)SvIV(v); have_y = 1; }
                    else if (klen == 5 && memEQ(k, "month", 5)) { m = (int)SvIV(v); have_m = 1; }
                    else if (klen == 3 && memEQ(k, "day", 3))   { dd = (int)SvIV(v); have_d = 1; }
                    else
                        croak("on: unknown argument '%.*s'", (int)klen, k);
                }
                if (!have_y || !have_m || !have_d)
                    croak("on needs year, month and day");
                if (m < 1 || m > 12)
                    croak("on: there is no month %d", m);
                days = tks_days_from_civil(y, m, dd);
                {
                    int64_t y2; int m2, d2;
                    tks_civil_from_days(days, &y2, &m2, &d2);
                    if (y2 != y || m2 != m || d2 != dd)
                        croak("on: there is no %" IVdf "-%02d-%02d", (IV)y, m, dd);
                }
            }
            start = tks_midnight(aTHX_ p, days, "on");
            end   = tks_midnight(aTHX_ p, days + 1, "on");
            t.sec = start;
            t.nsec = 0;
            tks_year_check(aTHX_ &t, "on");
            t.sec = end - 1;
            tks_year_check(aTHX_ &t, "on");
            tks_day_compute(aTHX_ p, days, start, end, &d);
            inner = newSVpvn((const char *)&d, sizeof d);
            RETVAL = sv_bless(newRV_noinc(inner), MY_CXT.dstash);
        }
    OUTPUT:
        RETVAL

# The next or previous crossing after an instant: ix is the kind for the
# four without a depth argument, and dawn/dusk take kind => civil (the
# default), nautical or astronomical.
SV *
next_sunrise(self, t)
        SV *self
        SV *t
    ALIAS:
        next_sunset = 1
        previous_sunrise = 2
        previous_sunset = 3
        next_solar_noon = 4
        previous_solar_noon = 5
    PREINIT:
        static const char *const names[6] = { "next_sunrise", "next_sunset", "previous_sunrise", "previous_sunset", "next_solar_noon", "previous_solar_noon" };
        const tks_place *p;
        time_keeper_instant in;
        int64_t out;
    CODE:
        p = tks_place_of(aTHX_ self, names[ix]);
        tks_instant_arg(aTHX_ t, &in, names[ix]);
        tks_year_check(aTHX_ &in, names[ix]);
        if (ix >= 4) {
            tks_body b;
            double j0 = TKS_JD_EPOCH + (double)in.sec / 86400.0 + (double)in.nsec / 86400.0e9;
            double tr;
            b.p = p;
            b.moon = 0;
            tr = tks_transit(aTHX_ &b, j0, 0);
            int back = ix == 5;
            out = tks_round_jd(tr);
            if (!back && out <= in.sec) out = tks_round_jd(tks_transit(aTHX_ &b, tr + 1.0, 0));
            if (back && out >= in.sec)  out = tks_round_jd(tks_transit(aTHX_ &b, tr - 1.0, 0));
            RETVAL = tks_value_sv(aTHX_ p, out);
        }
        else if (tks_find_crossing(aTHX_ p, in.sec, ix % 2 == 0 ? TKS_K_SUNRISE : TKS_K_SUNSET, ix >= 2, &out))
            RETVAL = tks_value_sv(aTHX_ p, out);
        else
            RETVAL = &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
next_dawn(self, t, ...)
        SV *self
        SV *t
    ALIAS:
        next_dusk = 1
        previous_dawn = 2
        previous_dusk = 3
    PREINIT:
        static const char *const names[4] = { "next_dawn", "next_dusk", "previous_dawn", "previous_dusk" };
        const tks_place *p;
        time_keeper_instant in;
        int64_t out;
        int depth = 1, kind;
    CODE:
        p = tks_place_of(aTHX_ self, names[ix]);
        tks_instant_arg(aTHX_ t, &in, names[ix]);
        tks_year_check(aTHX_ &in, names[ix]);
        depth = tks_twilight_depth_arg(aTHX_ &ST(2), items - 2, names[ix]);
        kind = 2 * depth + (ix % 2);
        if (tks_find_crossing(aTHX_ p, in.sec, kind, ix >= 2, &out))
            RETVAL = tks_value_sv(aTHX_ p, out);
        else
            RETVAL = &PL_sv_undef;
    OUTPUT:
        RETVAL

MODULE = Time::Keeper::Sky    PACKAGE = Time::Keeper::Sun::Day

SV *
sunrise(self)
        SV *self
    ALIAS:
        sunset = 1
        solar_noon = 8
        solar_midnight = 9
    PREINIT:
        tks_day *d;
    CODE:
        d = tks_day_of(aTHX_ self, tks_kind_name[ix]);
        RETVAL = d->n[ix] ? tks_value_sv(aTHX_ &d->place, tks_day_ev(d, ix, 0)) : &PL_sv_undef;
    OUTPUT:
        RETVAL

void
sunrises(self)
        SV *self
    ALIAS:
        sunsets = 1
        solar_noons = 8
        solar_midnights = 9
    PREINIT:
        tks_day *d;
        int i, n;
    PPCODE:
        d = tks_day_of(aTHX_ self, ix == 0 ? "sunrises" : ix == 1 ? "sunsets" : ix == 8 ? "solar_noons" : "solar_midnights");
        n = d->n[ix] > 2 ? 2 : d->n[ix];
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            mPUSHs(tks_value_sv(aTHX_ &d->place, tks_day_ev(d, ix, i)));

SV *
dawn(self, ...)
        SV *self
    ALIAS:
        dusk = 1
    PREINIT:
        tks_day *d;
        int depth, kind;
    CODE:
        d = tks_day_of(aTHX_ self, ix ? "dusk" : "dawn");
        depth = tks_twilight_depth_arg(aTHX_ &ST(1), items - 1, ix ? "dusk" : "dawn");
        tks_day_depth(aTHX_ d, depth);
        kind = 2 * depth + ix;
        RETVAL = d->n[kind] ? tks_value_sv(aTHX_ &d->place, tks_day_ev(d, kind, 0)) : &PL_sv_undef;
    OUTPUT:
        RETVAL

void
dawns(self, ...)
        SV *self
    ALIAS:
        dusks = 1
    PREINIT:
        tks_day *d;
        int depth, kind, i, n;
    PPCODE:
        d = tks_day_of(aTHX_ self, ix ? "dusks" : "dawns");
        depth = tks_twilight_depth_arg(aTHX_ &ST(1), items - 1, ix ? "dusks" : "dawns");
        tks_day_depth(aTHX_ d, depth);
        kind = 2 * depth + ix;
        n = d->n[kind] > 2 ? 2 : d->n[kind];
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            mPUSHs(tks_value_sv(aTHX_ &d->place, tks_day_ev(d, kind, i)));

# Every event of the day in order of time, as [name, value] pairs.
void
events(self)
        SV *self
    PREINIT:
        tks_day *d;
        int k, i, n = 0, a, b;
        int64_t when[2 * TKS_K_COUNT];
        int kind[2 * TKS_K_COUNT];
    PPCODE:
        d = tks_day_of(aTHX_ self, "events");
        tks_day_all(aTHX_ d);
        for (k = 0; k < TKS_K_COUNT; k++)
            for (i = 0; i < d->n[k] && i < 2; i++) {
                when[n] = tks_day_ev(d, k, i);
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
            av_push(pair, newSVpv(tks_kind_name[kind[i]], 0));
            av_push(pair, tks_value_sv(aTHX_ &d->place, when[i]));
            mPUSHs(newRV_noinc((SV *)pair));
        }

# Every crossing of an altitude in the day, in order, as [value, 'rising'
# or 'setting'] pairs.
void
crossings(self, ...)
        SV *self
    PREINIT:
        tks_day *d;
        STRLEN klen;
        const char *k;
        NV alt;
        int64_t sec[TKS_MAX_TRANSITS];
        int rising[TKS_MAX_TRANSITS];
        int i, n;
    PPCODE:
        d = tks_day_of(aTHX_ self, "crossings");
        if (items != 3)
            croak("crossings takes altitude => degrees");
        SvGETMAGIC(ST(1));
        k = SvPV_nomg(ST(1), klen);
        if (klen != 8 || !memEQ(k, "altitude", 8))
            croak("crossings: unknown argument '%.*s'", (int)klen, k);
        SvGETMAGIC(ST(2));
        if (!SvOK(ST(2)) || !looks_like_number(ST(2)))
            croak("crossings: altitude must be a number of degrees");
        alt = SvNV_nomg(ST(2));
        if (!(alt >= -90.0 && alt <= 90.0))
            croak("crossings: altitude must be from -90 to 90 degrees");
        n = tks_day_crossings(aTHX_ d, (double)alt, sec, rising);
        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            AV *pair = newAV();
            av_push(pair, tks_value_sv(aTHX_ &d->place, sec[i]));
            av_push(pair, newSVpv(rising[i] ? "rising" : "setting", 0));
            mPUSHs(newRV_noinc((SV *)pair));
        }

# Golden hour, the sun from 6 degrees up to 4 below, and blue hour, 4 to 6
# below: the day's spans as [start, end], undef for an end outside the day.
void
golden_hours(self)
        SV *self
    ALIAS:
        blue_hours = 1
    PREINIT:
        tks_day *d;
        int64_t s[TKS_MAX_TRANSITS], e[TKS_MAX_TRANSITS];
        int hs[TKS_MAX_TRANSITS], he[TKS_MAX_TRANSITS];
        int i, n;
    PPCODE:
        d = tks_day_of(aTHX_ self, ix ? "blue_hours" : "golden_hours");
        n = ix ? tks_day_bands(aTHX_ d, -6.0, -4.0, s, hs, e, he)
               : tks_day_bands(aTHX_ d, -4.0, 6.0, s, hs, e, he);
        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            AV *span = newAV();
            av_push(span, hs[i] ? tks_value_sv(aTHX_ &d->place, s[i]) : newSV(0));
            av_push(span, he[i] ? tks_value_sv(aTHX_ &d->place, e[i]) : newSV(0));
            mPUSHs(newRV_noinc((SV *)span));
        }

SV *
day_length(self)
        SV *self
    PREINIT:
        tks_day *d;
    CODE:
        d = tks_day_of(aTHX_ self, "day_length");
        RETVAL = d->day_length < 0 ? &PL_sv_undef : tks_duration_sv(aTHX_ (int64_t)d->day_length);
    OUTPUT:
        RETVAL

IV
is_polar_day(self)
        SV *self
    ALIAS:
        is_polar_night = 1
    PREINIT:
        tks_day *d;
    CODE:
        d = tks_day_of(aTHX_ self, ix ? "is_polar_night" : "is_polar_day");
        RETVAL = ix ? d->polar_night : d->polar_day;
    OUTPUT:
        RETVAL

SV *
date(self)
        SV *self
    PREINIT:
        tks_day *d;
    CODE:
        d = tks_day_of(aTHX_ self, "date");
        RETVAL = tks_date_sv(aTHX_ d->days);
    OUTPUT:
        RETVAL

SV *
place(self)
        SV *self
    PREINIT:
        dMY_CXT;
        const tks_day *d;
    CODE:
        d = tks_day_of(aTHX_ self, "place");
        RETVAL = sv_bless(newRV_noinc(newSVpvn((const char *)&d->place, sizeof d->place)), MY_CXT.pstash);
    OUTPUT:
        RETVAL

SV *
zone_name(self)
        SV *self
    PREINIT:
        tks_day *d;
    CODE:
        d = tks_day_of(aTHX_ self, "zone_name");
        RETVAL = tks_name_sv(aTHX_ d->place.zone_id);
    OUTPUT:
        RETVAL

# The window's edges, as values: the midnight the day began at and the one
# it ends before.
SV *
start(self)
        SV *self
    ALIAS:
        end = 1
    PREINIT:
        tks_day *d;
    CODE:
        d = tks_day_of(aTHX_ self, ix ? "end" : "start");
        RETVAL = tks_value_sv(aTHX_ &d->place, ix ? d->end : d->start);
    OUTPUT:
        RETVAL
