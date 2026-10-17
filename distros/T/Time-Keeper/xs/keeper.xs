# The public surface: constructors, accessors, and the methods that make a
# new value from an old one.

MODULE = Time::Keeper    PACKAGE = Time::Keeper

SV *
now(class, ...)
        SV *class
    PREINIT:
        tk_args a;
        tk_zone_spec z;
        tk_instant t;
        tk_value v;
    CODE:
        tk_args_parse(aTHX_ &ST(1), items - 1, TK_A(TK_A_ZONE) | TK_A(TK_A_LOCALE), &a, "Time::Keeper->now");
        tk_zone_spec_from_sv(aTHX_ a.v[TK_A_ZONE], &z, "Time::Keeper->now");
        tk_now(&t);
        tk_value_init(aTHX_ &v, &t, &z);
        v.locale = tk_args_locale(&a, "Time::Keeper->now");
        RETVAL = tk_value_new_sv(aTHX_ tk_stash_for(aTHX_ class), &v);
    OUTPUT:
        RETVAL

SV *
today(class, ...)
        SV *class
    PREINIT:
        tk_args a;
        tk_zone_spec z;
        tk_instant t;
        tk_value v, day;
    CODE:
        tk_args_parse(aTHX_ &ST(1), items - 1, TK_A(TK_A_ZONE) | TK_A(TK_A_LOCALE), &a, "Time::Keeper->today");
        tk_zone_spec_from_sv(aTHX_ a.v[TK_A_ZONE], &z, "Time::Keeper->today");
        tk_now(&t);
        tk_value_init(aTHX_ &v, &t, &z);
        tk_value_start_of_day(aTHX_ &day, &v, "Time::Keeper->today");
        day.locale = tk_args_locale(&a, "Time::Keeper->today");
        RETVAL = tk_value_new_sv(aTHX_ tk_stash_for(aTHX_ class), &day);
    OUTPUT:
        RETVAL

SV *
new(class, ...)
        SV *class
    ALIAS:
        last_day_of_month = 1
        from_day_of_year = 2
        from_iso_week = 3
    PREINIT:
        static const char *const whats[] = {
            "Time::Keeper->new", "Time::Keeper->last_day_of_month",
            "Time::Keeper->from_day_of_year", "Time::Keeper->from_iso_week"
        };
        static const unsigned allowed[] = {
            TK_A(TK_A_YEAR) | TK_A(TK_A_MONTH) | TK_A(TK_A_DAY) | TK_A_TIME | TK_A_RESOLVE | TK_A(TK_A_LOCALE),
            TK_A(TK_A_YEAR) | TK_A(TK_A_MONTH) | TK_A_TIME | TK_A_RESOLVE | TK_A(TK_A_LOCALE),
            TK_A(TK_A_YEAR) | TK_A(TK_A_DAY_OF_YEAR) | TK_A_TIME | TK_A_RESOLVE | TK_A(TK_A_LOCALE),
            TK_A(TK_A_YEAR) | TK_A(TK_A_WEEK) | TK_A(TK_A_DAY) | TK_A_TIME | TK_A_RESOLVE | TK_A(TK_A_LOCALE)
        };
        const char *what = whats[ix];
        tk_args a;
        tk_zone_spec z;
        int gap, overlap;
        int64_t y, m = 1, d = 1, h, mi, s, yy;
        int32_t ns;
        unsigned mm, dd;
        tk_value v;
    CODE:
        tk_args_parse(aTHX_ &ST(1), items - 1, allowed[ix], &a, what);
        if (!a.v[TK_A_YEAR])
            croak("%s: year is required", what);
        y = tk_args_int(aTHX_ &a, TK_A_YEAR, 0, TK_YEAR_MIN, TK_YEAR_MAX, what);
        switch (ix) {
        case 0:
            m = tk_args_int(aTHX_ &a, TK_A_MONTH, 1, 1, 12, what);
            d = tk_args_int(aTHX_ &a, TK_A_DAY, 1, 1, 31, what);
            if (d > (int64_t)tk_days_in_month(y, (unsigned)m))
                croak("%s: %04" IVdf "-%02u has no day %" IVdf, what, (IV)y, (unsigned)m, (IV)d);
            break;
        case 1:
            if (!a.v[TK_A_MONTH])
                croak("%s: month is required", what);
            m = tk_args_int(aTHX_ &a, TK_A_MONTH, 1, 1, 12, what);
            d = tk_days_in_month(y, (unsigned)m);
            break;
        case 2: {
            int64_t doy;
            if (!a.v[TK_A_DAY_OF_YEAR])
                croak("%s: day_of_year is required", what);
            doy = tk_args_int(aTHX_ &a, TK_A_DAY_OF_YEAR, 1, 1, 366, what);
            if (doy == 366 && !tk_is_leap_year(y))
                croak("%s: %" IVdf " has no day 366", what, (IV)y);
            tk_civil_from_days(tk_days_from_civil(y, 1, 1) + doy - 1, &yy, &mm, &dd);
            m = mm;
            d = dd;
            break;
        }
        case 3: {
            int64_t wk, wd, wy, monday;
            unsigned last;
            if (!a.v[TK_A_WEEK])
                croak("%s: week is required", what);
            wk = tk_args_int(aTHX_ &a, TK_A_WEEK, 1, 1, 53, what);
            wd = tk_args_int(aTHX_ &a, TK_A_DAY, 1, 1, 7, what);
            tk_iso_week(y, 12, 28, &wy, &last);
            if (wk > last)
                croak("%s: %" IVdf " has %u ISO weeks, not %" IVdf, what, (IV)y, last, (IV)wk);
            monday = tk_days_from_civil(y, 1, 4);
            monday -= tk_dow_from_days(monday) - 1;
            tk_civil_from_days(monday + (wk - 1) * 7 + wd - 1, &yy, &mm, &dd);
            y = yy;
            m = mm;
            d = dd;
            break;
        }
        }
        tk_args_time(aTHX_ &a, &h, &mi, &s, &ns, what);
        tk_args_resolve(aTHX_ &a, &z, &gap, &overlap, what);
        tk_value_from_local(aTHX_ &v, &z, y, (unsigned)m, (unsigned)d, h, mi, s, ns, gap, overlap, what);
        v.locale = tk_args_locale(&a, what);
        RETVAL = tk_value_new_sv(aTHX_ tk_stash_for(aTHX_ class), &v);
    OUTPUT:
        RETVAL

SV *
from_epoch(class, epoch, ...)
        SV *class
        SV *epoch
    PREINIT:
        tk_args a;
        tk_zone_spec z;
        tk_instant t;
        tk_value v;
    CODE:
        tk_args_parse(aTHX_ &ST(2), items - 2, TK_A(TK_A_ZONE) | TK_A(TK_A_LOCALE), &a, "Time::Keeper->from_epoch");
        tk_zone_spec_from_sv(aTHX_ a.v[TK_A_ZONE], &z, "Time::Keeper->from_epoch");
        tk_epoch_from_sv(aTHX_ epoch, &t, "Time::Keeper->from_epoch");
        if (!tk_instant_valid(&t))
            croak("Time::Keeper->from_epoch: out of range");
        tk_value_init(aTHX_ &v, &t, &z);
        v.locale = tk_args_locale(&a, "Time::Keeper->from_epoch");
        RETVAL = tk_value_new_sv(aTHX_ tk_stash_for(aTHX_ class), &v);
    OUTPUT:
        RETVAL

SV *
max(class)
        SV *class
    ALIAS:
        min = 1
        leap_seconds_expire = 2
    PREINIT:
        tk_zone_spec z;
        tk_instant t;
        tk_value v;
    CODE:
        z.zone = TK_ZONE_UTC;
        z.fixed = 0;
        if (ix == 0) {
            t.sec = tk_sec_max();
            t.nsec = TK_NSECS_PER_SEC - 1;
        }
        else if (ix == 1) {
            t.sec = tk_sec_min();
            t.nsec = 0;
        }
        else {
            t.sec = TK_LEAP_EXPIRES;
            t.nsec = 0;
        }
        tk_value_init(aTHX_ &v, &t, &z);
        RETVAL = tk_value_new_sv(aTHX_ tk_stash_for(aTHX_ class), &v);
    OUTPUT:
        RETVAL

IV
year(self)
        SV *self
    ALIAS:
        month = 1
        day = 2
        hour = 3
        minute = 4
        second = 5
        nanosecond = 6
        millisecond = 7
        microsecond = 8
        day_of_week = 9
        day_of_year = 10
        quarter = 11
        day_of_quarter = 12
        week = 13
        week_year = 14
        week_of_month = 15
        is_leap_year = 16
        days_in_month = 17
        offset = 18
        is_dst = 19
        is_utc = 20
        is_floating = 21
        days_in_year = 22
        days_in_quarter = 23
    PREINIT:
        tk_value *v;
        const tk_civil *c;
        int64_t wy;
        unsigned w;
    CODE:
        v = tk_value_rw(self, "Time::Keeper accessor");
        if (ix >= 18 && ix <= 21) {
            switch (ix) {
            case 18: RETVAL = v->utoff; break;
            case 19: RETVAL = (v->flags & TK_F_DST) ? 1 : 0; break;
            case 20: RETVAL = v->zone == TK_ZONE_UTC; break;
            default: RETVAL = v->zone == TK_ZONE_FLOATING; break;
            }
        }
        else {
            c = tk_value_civil(v);
            switch (ix) {
            case 0:  RETVAL = c->year; break;
            case 1:  RETVAL = c->month; break;
            case 2:  RETVAL = c->day; break;
            case 3:  RETVAL = c->hour; break;
            case 4:  RETVAL = c->minute; break;
            case 5:  RETVAL = c->second; break;
            case 6:  RETVAL = c->nsec; break;
            case 7:  RETVAL = c->nsec / 1000000; break;
            case 8:  RETVAL = c->nsec / 1000; break;
            case 9:  RETVAL = c->dow; break;
            case 10: RETVAL = c->doy; break;
            case 11: RETVAL = tk_quarter(c->month); break;
            case 12: RETVAL = tk_day_of_quarter(c->year, c->month, c->day); break;
            case 13: tk_iso_week(c->year, c->month, c->day, &wy, &w); RETVAL = w; break;
            case 14: tk_iso_week(c->year, c->month, c->day, &wy, &w); RETVAL = (IV)wy; break;
            case 15: RETVAL = (c->day + 4 - c->dow + 6) / 7; break;
            case 16: RETVAL = tk_is_leap_year(c->year); break;
            case 17: RETVAL = tk_days_in_month(c->year, c->month); break;
            case 22: RETVAL = tk_is_leap_year(c->year) ? 366 : 365; break;
            default: {
                unsigned first = (tk_quarter(c->month) - 1) * 3 + 1;
                RETVAL = tk_days_in_month(c->year, first) + tk_days_in_month(c->year, first + 1)
                       + tk_days_in_month(c->year, first + 2);
                break;
            }
            }
        }
    OUTPUT:
        RETVAL

NV
julian_day(self)
        SV *self
    ALIAS:
        mjd = 1
        hires_epoch = 2
    PREINIT:
        const tk_value *v;
        int64_t whole;
        double frac;
    CODE:
        v = tk_value_of(aTHX_ self, "Time::Keeper accessor");
        if (ix == 2)
            RETVAL = (NV)v->inst.sec + (NV)v->inst.nsec / TK_NSECS_PER_SEC;
        else {
            if (ix == 0)
                tk_julian_day(&v->inst, &whole, &frac);
            else
                tk_mjd(&v->inst, &whole, &frac);
            RETVAL = (NV)whole + frac;
        }
    OUTPUT:
        RETVAL

SV *
epoch(self)
        SV *self
    ALIAS:
        epoch_string = 1
    PREINIT:
        const tk_value *v;
        int64_t s;
        int32_t n;
    CODE:
        v = tk_value_of(aTHX_ self, "Time::Keeper->epoch");
        s = v->inst.sec;
        n = v->inst.nsec;
        if (n >= TK_NSECS_PER_SEC) {
            s += 1;
            n -= TK_NSECS_PER_SEC;
        }
        if (ix == 0)
            RETVAL = tk_newSVi64_nv(aTHX_ s);
        else {
            /* A decimal that reads back as the same instant: before 1970
             * with a fraction, the whole part is one second nearer zero
             * and the fraction counts back from it (-0.5, not -1 and .5). */
            char frac[16];
            int fl = 0, neg_frac = s < 0 && n > 0;
            if (neg_frac) {
                s += 1;
                n = TK_NSECS_PER_SEC - n;
            }
            RETVAL = newSVpvs("");
            if (neg_frac && s == 0)
                sv_catpvs(RETVAL, "-");
            sv_catsv(RETVAL, sv_2mortal(tk_newSVi64(aTHX_ s)));
            if (n) {
                fl = sprintf(frac, ".%09d", (int)n);
                while (frac[fl - 1] == '0')
                    frac[--fl] = '\0';
                sv_catpvn(RETVAL, frac, fl);
            }
        }
    OUTPUT:
        RETVAL

SV *
zone_name(self, ...)
        SV *self
    ALIAS:
        zone_abbr = 1
        locale = 2
        TO_JSON = 4
        tai_offset = 5
    PREINIT:
        tk_value *v;
        char buf[64];
        int off;
    CODE:
        v = tk_value_rw(self, "Time::Keeper accessor");
        switch (ix) {
        case 0:  RETVAL = tk_zone_name_sv(aTHX_ v); break;
        case 1:  RETVAL = tk_zone_abbr_sv(aTHX_ v); break;
        case 2:  RETVAL = newSVpv(tk_locale_codes[v->locale < TK_LOCALE_COUNT ? v->locale : 0].code, 0); break;
        case 5:
            if (v->zone == TK_ZONE_FLOATING || !tk_tai_minus_utc(&v->inst, &off))
                XSRETURN_UNDEF;
            RETVAL = newSViv(off);
            break;
        default: RETVAL = newSVpvn(buf, tk_iso8601(v, buf)); break;
        }
    OUTPUT:
        RETVAL

SV *
with(self, ...)
        SV *self
    PREINIT:
        tk_args a;
        tk_value *v;
        tk_value nv;
        const tk_civil *c;
        tk_zone_spec z;
        int gap, overlap;
        int64_t y, m, d, h, mi, s;
        int32_t ns;
        const char *what = "Time::Keeper->with";
    CODE:
        v = tk_value_rw(self, what);
        tk_args_parse(aTHX_ &ST(1), items - 1,
                      TK_A(TK_A_YEAR) | TK_A(TK_A_MONTH) | TK_A(TK_A_DAY) | TK_A_TIME
                      | TK_A(TK_A_GAP) | TK_A(TK_A_OVERLAP), &a, what);
        c = tk_value_civil(v);
        y  = tk_args_int(aTHX_ &a, TK_A_YEAR, c->year, TK_YEAR_MIN, TK_YEAR_MAX, what);
        m  = tk_args_int(aTHX_ &a, TK_A_MONTH, c->month, 1, 12, what);
        d  = tk_args_int(aTHX_ &a, TK_A_DAY, c->day, 1, 31, what);
        h  = tk_args_int(aTHX_ &a, TK_A_HOUR, c->hour, 0, 23, what);
        mi = tk_args_int(aTHX_ &a, TK_A_MINUTE, c->minute, 0, 59, what);
        s  = tk_args_int(aTHX_ &a, TK_A_SECOND, c->second, 0, 60, what);
        ns = (int32_t)tk_args_int(aTHX_ &a, TK_A_NANOSECOND, c->nsec, 0, TK_NSECS_PER_SEC - 1, what);
        if (d > (int64_t)tk_days_in_month(y, (unsigned)m))
            croak("%s: %04" IVdf "-%02u has no day %" IVdf, what, (IV)y, (unsigned)m, (IV)d);
        tk_value_zone(v, &z);
        gap = a.v[TK_A_GAP] ? tk_opt_gap(aTHX_ a.v[TK_A_GAP], what) : TK_GAP_DEFAULT;
        overlap = a.v[TK_A_OVERLAP] ? tk_opt_overlap(aTHX_ a.v[TK_A_OVERLAP], what) : TK_OVERLAP_DEFAULT;
        tk_value_from_local(aTHX_ &nv, &z, y, (unsigned)m, (unsigned)d, h, mi, s, ns, gap, overlap, what);
        nv.locale = v->locale;
        RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(self)), &nv);
    OUTPUT:
        RETVAL

SV *
in_zone(self, ...)
        SV *self
    ALIAS:
        as_utc = 1
        as_floating = 2
    PREINIT:
        static const char *const whats[] = {
            "Time::Keeper->in_zone", "Time::Keeper->as_utc", "Time::Keeper->as_floating"
        };
        const char *what = whats[ix];
        tk_args a;
        tk_value *v;
        tk_value nv;
        tk_zone_spec z;
        int gap, overlap, first = ix == 0 ? 2 : 1;
    CODE:
        v = tk_value_rw(self, what);
        if (ix == 0 && items < 2)
            croak("%s: which zone?", what);
        tk_args_parse(aTHX_ &ST(first), items - first, TK_A(TK_A_GAP) | TK_A(TK_A_OVERLAP), &a, what);
        if (ix == 0)
            tk_zone_spec_from_sv(aTHX_ ST(1), &z, what);
        else {
            z.zone = ix == 1 ? TK_ZONE_UTC : TK_ZONE_FLOATING;
            z.fixed = 0;
        }
        gap = a.v[TK_A_GAP] ? tk_opt_gap(aTHX_ a.v[TK_A_GAP], what) : TK_GAP_DEFAULT;
        overlap = a.v[TK_A_OVERLAP] ? tk_opt_overlap(aTHX_ a.v[TK_A_OVERLAP], what) : TK_OVERLAP_DEFAULT;
        if (z.zone == TK_ZONE_FLOATING || v->zone == TK_ZONE_FLOATING) {
            /* to or from floating, the wall-clock time is what is kept */
            const tk_civil *c = tk_value_civil(v);
            tk_value_from_local(aTHX_ &nv, &z, c->year, c->month, c->day, c->hour, c->minute,
                                c->second, c->nsec, gap, overlap, what);
        }
        else
            tk_value_init(aTHX_ &nv, &v->inst, &z);
        nv.locale = v->locale;
        RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(self)), &nv);
    OUTPUT:
        RETVAL

SV *
in_locale(self, locale)
        SV *self
        SV *locale
    PREINIT:
        tk_value *v;
        tk_value nv;
    CODE:
        v = tk_value_rw(self, "Time::Keeper->in_locale");
        nv = *v;
        nv.locale = tk_locale_id_from_sv(aTHX_ locale, "Time::Keeper->in_locale");
        RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(self)), &nv);
    OUTPUT:
        RETVAL

IV
_compare(a, b, swapped)
        SV *a
        SV *b
        SV *swapped
    PREINIT:
        const tk_value *x, *y;
        int64_t xs, ys;
    CODE:
        if (!tk_is_value(aTHX_ b))
            croak("Time::Keeper: a value can be compared only with another Time::Keeper value");
        x = tk_value_of(aTHX_ a, "Time::Keeper comparison");
        y = tk_value_of(aTHX_ b, "Time::Keeper comparison");
        xs = x->inst.sec;
        ys = y->inst.sec;
        if (x->zone == TK_ZONE_FLOATING || y->zone == TK_ZONE_FLOATING) {
            /* a floating value is a wall-clock time: compare wall clocks */
            xs += x->utoff;
            ys += y->utoff;
        }
        RETVAL = xs < ys ? -1 : xs > ys ? 1 : x->inst.nsec < y->inst.nsec ? -1 : x->inst.nsec > y->inst.nsec;
        if (SvTRUE(swapped))
            RETVAL = -RETVAL;
    OUTPUT:
        RETVAL

IV
compare(class, a, b)
        SV *class
        SV *a
        SV *b
    PREINIT:
        const tk_value *x, *y;
        int64_t xs, ys;
    CODE:
        PERL_UNUSED_VAR(class);
        x = tk_value_of(aTHX_ a, "Time::Keeper->compare");
        y = tk_value_of(aTHX_ b, "Time::Keeper->compare");
        xs = x->inst.sec;
        ys = y->inst.sec;
        if (x->zone == TK_ZONE_FLOATING || y->zone == TK_ZONE_FLOATING) {
            xs += x->utoff;
            ys += y->utoff;
        }
        RETVAL = xs < ys ? -1 : xs > ys ? 1 : x->inst.nsec < y->inst.nsec ? -1 : x->inst.nsec > y->inst.nsec;
    OUTPUT:
        RETVAL

void
utc_rd_values(self)
        SV *self
    ALIAS:
        local_rd_values = 1
    PREINIT:
        const tk_value *v;
        int64_t sec, days, secs;
        int32_t ns;
    PPCODE:
        v = tk_value_of(aTHX_ self, ix ? "Time::Keeper->local_rd_values" : "Time::Keeper->utc_rd_values");
        sec = v->inst.sec + (ix ? v->utoff : 0);
        ns = v->inst.nsec;
        days = sec >= 0 ? sec / 86400 : -((-sec + 86399) / 86400);
        secs = sec - days * 86400;
        if (ns >= TK_NSECS_PER_SEC) {
            secs += 1;
            ns -= TK_NSECS_PER_SEC;
        }
        EXTEND(SP, 3);
        mPUSHs(tk_newSVi64(aTHX_ days + 719163));
        mPUSHs(newSViv((IV)secs));
        mPUSHs(newSViv((IV)ns));

SV *
from_object(class, ...)
        SV *class
    PREINIT:
        const char *what = "Time::Keeper->from_object";
        SV *obj = NULL, *zone = NULL, *locale = NULL;
        SV *tzname = NULL;
        SV *got[3];
        I32 i;
        int count;
        int64_t days, secs, ns;
        tk_instant t;
        tk_zone_spec z;
        tk_value v;
    CODE:
        if (items % 2 == 0)
            croak("%s: arguments come in name => value pairs", what);
        for (i = 1; i < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            if (strEQ(k, "object")) obj = ST(i + 1);
            else if (strEQ(k, "zone")) zone = ST(i + 1);
            else if (strEQ(k, "locale")) locale = ST(i + 1);
            else croak("%s: unknown argument '%s'", what, k);
        }
        if (!obj || !sv_isobject(obj))
            croak("%s: object => an object with utc_rd_values is required", what);
        {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(obj);
            PUTBACK;
            count = call_method("utc_rd_values", G_ARRAY);
            SPAGAIN;
            if (count != 3) {
                PUTBACK;
                FREETMPS;
                LEAVE;
                croak("%s: utc_rd_values gave %d values, not 3", what, count);
            }
            got[2] = POPs;
            got[1] = POPs;
            got[0] = POPs;
            if (!tk_sv_to_i64(aTHX_ got[0], &days))
                croak("%s: utc_rd_values gave a day that is not an integer", what);
            secs = SvIV(got[1]);
            ns = SvIV(got[2]);
            if (!zone && gv_fetchmethod_autoload(SvSTASH(SvRV(obj)), "time_zone", 0)) {
                PUTBACK;
                PUSHMARK(SP);
                XPUSHs(obj);
                PUTBACK;
                {
                    count = call_method("time_zone", G_SCALAR);
                    SPAGAIN;
                    if (count == 1) {
                        SV *tz = POPs;
                        if (sv_isobject(tz) && gv_fetchmethod_autoload(SvSTASH(SvRV(tz)), "name", 0)) {
                            PUTBACK;
                            PUSHMARK(SP);
                            XPUSHs(tz);
                            PUTBACK;
                            count = call_method("name", G_SCALAR);
                            SPAGAIN;
                            if (count == 1)
                                tzname = newSVsv(POPs);
                        }
                        else if (SvOK(tz) && !SvROK(tz))
                            tzname = newSVsv(tz);
                    }
                }
            }
            PUTBACK;
            FREETMPS;
            LEAVE;
        }
        if (tzname)
            zone = sv_2mortal(tzname);
        if (secs < 0 || secs > 86400 || ns < 0 || ns >= TK_NSECS_PER_SEC)
            croak("%s: utc_rd_values gave seconds or nanoseconds out of range", what);
        t.sec = (days - 719163) * 86400 + (secs == 86400 ? 86399 : secs);
        t.nsec = (int32_t)ns + (secs == 86400 ? TK_NSECS_PER_SEC : 0);
        if (!tk_instant_valid(&t))
            croak("%s: %s", what, secs == 86400 ? "there was no leap second then" : "out of range");
        if (zone && SvOK(zone) && strEQ(SvPV_nolen(zone), "floating")) {
            /* a floating object's values are its wall clock */
            z.zone = TK_ZONE_FLOATING;
            z.fixed = 0;
        }
        else
            tk_zone_spec_from_sv(aTHX_ zone, &z, what);
        tk_value_init(aTHX_ &v, &t, &z);
        if (locale)
            v.locale = tk_locale_id_from_sv(aTHX_ locale, what);
        RETVAL = tk_value_new_sv(aTHX_ tk_stash_for(aTHX_ class), &v);
    OUTPUT:
        RETVAL

void
STORABLE_freeze(self, cloning)
        SV *self
        SV *cloning
    PREINIT:
        const tk_value *v;
        SV *out;
    PPCODE:
        PERL_UNUSED_VAR(cloning);
        v = tk_value_of(aTHX_ self, "Time::Keeper->STORABLE_freeze");
        out = sv_2mortal(tk_freeze_sv(aTHX_ v));
        if (v->locale && v->locale < TK_LOCALE_COUNT)
            sv_catpvf(out, " %s", tk_locale_codes[v->locale].code);
        XPUSHs(out);

void
STORABLE_thaw(self, cloning, frozen)
        SV *self
        SV *cloning
        SV *frozen
    PREINIT:
        const char *s, *p;
        STRLEN len;
        tk_instant t;
        tk_zone_spec z;
        tk_value v;
        SV *num, *zone;
        const char *lsep;
        uint16_t lid = 0;
        long ns;
        const char *what = "Time::Keeper->STORABLE_thaw";
    PPCODE:
        PERL_UNUSED_VAR(cloning);
        s = SvPV(frozen, len);
        if (len < 4 || memNE(s, "tk1 ", 4))
            croak("%s: not a frozen Time::Keeper value", what);
        p = strchr(s + 4, ' ');
        if (!p)
            croak("%s: not a frozen Time::Keeper value", what);
        num = sv_2mortal(newSVpvn(s + 4, p - (s + 4)));
        if (!tk_sv_to_i64(aTHX_ num, &t.sec))
            croak("%s: not a frozen Time::Keeper value", what);
        ns = strtol(p + 1, (char **)&p, 10);
        if (*p != ' ' || ns < 0 || ns >= 2L * TK_NSECS_PER_SEC)
            croak("%s: not a frozen Time::Keeper value", what);
        t.nsec = (int32_t)ns;
        lsep = strchr(p + 1, ' ');
        zone = sv_2mortal(newSVpvn(p + 1, (lsep ? lsep : s + len) - (p + 1)));
        if (lsep)
            lid = tk_locale_id_from_sv(aTHX_ sv_2mortal(newSVpvn(lsep + 1, len - (lsep + 1 - s))), what);
        tk_zone_spec_from_sv(aTHX_ zone, &z, what);
        if (!tk_instant_valid(&t))
            croak("%s: out of range", what);
        tk_value_init(aTHX_ &v, &t, &z);
        v.locale = lid;
        if (!SvROK(self))
            croak("%s: not a reference", what);
        sv_setpvn(SvRV(self), (const char *)&v, sizeof v);
        SvREADONLY_on(SvRV(self));
        XSRETURN_EMPTY;

void
CLONE(...)
    CODE:
        PERL_UNUSED_VAR(items);
        {
            MY_CXT_CLONE;
            MY_CXT.stash = gv_stashpvs("Time::Keeper", GV_ADD);
            MY_CXT.dstash = gv_stashpvs("Time::Keeper::Duration", GV_ADD);
        }
