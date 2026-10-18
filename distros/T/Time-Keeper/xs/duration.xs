# Time::Keeper::Duration: an amount of time in months, days, minutes and
# seconds, which do not convert into one another.

MODULE = Time::Keeper    PACKAGE = Time::Keeper::Duration

SV *
new(class, ...)
        SV *class
    PREINIT:
        tk_dur_args a;
        tk_duration d;
    CODE:
        tk_dur_args_parse(aTHX_ &ST(1), items - 1, TK_D_UNITS, &a, "Time::Keeper::Duration->new");
        tk_dur_from_args(aTHX_ &a, &d, "Time::Keeper::Duration->new");
        RETVAL = tk_dur_new_sv(aTHX_ tk_dur_stash_for(aTHX_ class), &d);
    OUTPUT:
        RETVAL

SV *
from_seconds(class, seconds)
        SV *class
        SV *seconds
    PREINIT:
        tk_duration d;
        tk_instant t;
    CODE:
        tk_epoch_from_sv(aTHX_ seconds, &t, "Time::Keeper::Duration->from_seconds");
        Zero(&d, 1, tk_duration);
        d.seconds = t.sec;
        if (!tk_dur_normalize(&d, t.nsec))
            croak("Time::Keeper::Duration->from_seconds: out of range");
        d.eom = TK_EOM_WRAP;
        RETVAL = tk_dur_new_sv(aTHX_ tk_dur_stash_for(aTHX_ class), &d);
    OUTPUT:
        RETVAL

IV
years(self)
        SV *self
    ALIAS:
        months = 1
        weeks = 2
        days = 3
        hours = 4
        minutes = 5
        seconds = 6
        nanoseconds = 7
    PREINIT:
        const tk_duration *d;
        int64_t v = 0;
    CODE:
        d = tk_dur_of(aTHX_ self, "Time::Keeper::Duration accessor");
        switch (ix) {
        case 0: v = d->months / 12; break;
        case 1: v = d->months % 12; break;
        case 2: v = d->days / 7; break;
        case 3: v = d->days % 7; break;
        case 4: v = d->minutes / 60; break;
        case 5: v = d->minutes % 60; break;
        case 6: v = d->seconds; break;
        default: v = d->nsec; break;
        }
        RETVAL = (IV)(v < 0 ? -v : v);
    OUTPUT:
        RETVAL

void
in_units(self, ...)
        SV *self
    PREINIT:
        const tk_duration *d;
        int64_t months, days, minutes, seconds;
        SV *out[8];
        int want[8] = { 0, 0, 0, 0, 0, 0, 0, 0 };
        static const char *const names[8] = {
            "years", "months", "weeks", "days", "hours", "minutes", "seconds", "nanoseconds"
        };
        I32 i;
        int j;
    PPCODE:
        d = tk_dur_of(aTHX_ self, "Time::Keeper::Duration->in_units");
        for (i = 1; i < items; i++) {
            const char *u = SvPV_nolen(ST(i));
            for (j = 0; j < 8; j++)
                if (strEQ(u, names[j])) { want[j] = 1; break; }
            if (j == 8)
                croak("Time::Keeper::Duration->in_units: '%s' is not a unit", u);
        }
        months = d->months; days = d->days; minutes = d->minutes; seconds = d->seconds;
        for (j = 0; j < 8; j++) out[j] = NULL;
        /* each unit takes what it can from its own group, the larger first,
           as DateTime does it */
        if (want[0]) { out[0] = tk_newSVi64(aTHX_ months / 12); months -= (months / 12) * 12; }
        if (want[1]) out[1] = tk_newSVi64(aTHX_ months);
        if (want[2]) { out[2] = tk_newSVi64(aTHX_ days / 7); days -= (days / 7) * 7; }
        if (want[3]) out[3] = tk_newSVi64(aTHX_ days);
        if (want[4]) { out[4] = tk_newSVi64(aTHX_ minutes / 60); minutes -= (minutes / 60) * 60; }
        if (want[5]) out[5] = tk_newSVi64(aTHX_ minutes);
        if (want[6]) { out[6] = tk_newSVi64(aTHX_ seconds); seconds = 0; }
        if (want[7]) {
            if (seconds > INT64_MAX / TK_NSECS_PER_SEC - 1 || seconds < INT64_MIN / TK_NSECS_PER_SEC + 1)
                out[7] = newSVnv((NV)seconds * TK_NSECS_PER_SEC + d->nsec);
            else
                out[7] = tk_newSVi64(aTHX_ seconds * TK_NSECS_PER_SEC + d->nsec);
        }
        if (GIMME_V == G_ARRAY) {
            EXTEND(SP, items - 1);
            for (i = 1; i < items; i++) {
                const char *u = SvPV_nolen(ST(i));
                for (j = 0; j < 8; j++)
                    if (strEQ(u, names[j])) break;
                PUSHs(sv_2mortal(newSVsv(out[j])));
            }
        }
        else if (items > 1) {
            const char *u = SvPV_nolen(ST(1));
            for (j = 0; j < 8; j++)
                if (strEQ(u, names[j])) break;
            XPUSHs(sv_2mortal(newSVsv(out[j])));
        }
        for (j = 0; j < 8; j++)
            if (out[j]) SvREFCNT_dec(out[j]);

IV
is_positive(self)
        SV *self
    ALIAS:
        is_negative = 1
        is_zero = 2
    PREINIT:
        const tk_duration *d;
    CODE:
        d = tk_dur_of(aTHX_ self, "Time::Keeper::Duration accessor");
        if (ix == 0)
            RETVAL = tk_dur_has_positive(d) && !tk_dur_has_negative(d);
        else if (ix == 1)
            RETVAL = tk_dur_has_negative(d) && !tk_dur_has_positive(d);
        else
            RETVAL = tk_dur_is_zero(d);
    OUTPUT:
        RETVAL

SV *
end_of_month(self)
        SV *self
    CODE:
        RETVAL = newSVpv(tk_eom_name(tk_dur_of(aTHX_ self, "Time::Keeper::Duration->end_of_month")->eom), 0);
    OUTPUT:
        RETVAL

SV *
inverse(self, ...)
        SV *self
    ALIAS:
        calendar_duration = 1
        clock_duration = 2
    PREINIT:
        tk_dur_args a;
        tk_duration d;
        const char *what = ix == 0 ? "Time::Keeper::Duration->inverse"
                         : ix == 1 ? "Time::Keeper::Duration->calendar_duration"
                         : "Time::Keeper::Duration->clock_duration";
    CODE:
        d = *tk_dur_of(aTHX_ self, what);
        tk_dur_args_parse(aTHX_ &ST(1), items - 1, ix == 0 ? TK_D(TK_D_EOM) : 0, &a, what);
        if (ix == 0) {
            d.months = -d.months; d.days = -d.days; d.minutes = -d.minutes;
            d.seconds = -d.seconds; d.nsec = -d.nsec;
            d.eom = a.v[TK_D_EOM] ? (uint8_t)tk_opt_eom(aTHX_ a.v[TK_D_EOM], what)
                                  : tk_dur_default_eom(d.months);
        }
        else if (ix == 1) {
            d.minutes = d.seconds = 0;
            d.nsec = 0;
        }
        else
            d.months = d.days = 0;
        RETVAL = tk_dur_new_sv(aTHX_ SvSTASH(SvRV(self)), &d);
    OUTPUT:
        RETVAL

void
deltas(self)
        SV *self
    PREINIT:
        const tk_duration *d;
    PPCODE:
        d = tk_dur_of(aTHX_ self, "Time::Keeper::Duration->deltas");
        EXTEND(SP, 10);
        mPUSHp("months", 6);      mPUSHs(tk_newSVi64(aTHX_ d->months));
        mPUSHp("days", 4);        mPUSHs(tk_newSVi64(aTHX_ d->days));
        mPUSHp("minutes", 7);     mPUSHs(tk_newSVi64(aTHX_ d->minutes));
        mPUSHp("seconds", 7);     mPUSHs(tk_newSVi64(aTHX_ d->seconds));
        mPUSHp("nanoseconds", 11); mPUSHi(d->nsec);

SV *
plus(self, other)
        SV *self
        SV *other
    ALIAS:
        minus = 1
    PREINIT:
        tk_duration d, o;
        int64_t ns;
        const char *what = ix ? "Time::Keeper::Duration->minus" : "Time::Keeper::Duration->plus";
    CODE:
        d = *tk_dur_of(aTHX_ self, what);
        o = *tk_dur_of(aTHX_ other, what);
        if (ix) {
            o.months = -o.months; o.days = -o.days; o.minutes = -o.minutes;
            o.seconds = -o.seconds; o.nsec = -o.nsec;
        }
        d.months += o.months;
        d.days += o.days;
        d.minutes += o.minutes;
        d.seconds += o.seconds;
        ns = (int64_t)d.nsec + o.nsec;
        if (!tk_dur_normalize(&d, ns))
            croak("%s: out of range", what);
        RETVAL = tk_dur_new_sv(aTHX_ SvSTASH(SvRV(self)), &d);
    OUTPUT:
        RETVAL

SV *
multiply(self, factor)
        SV *self
        SV *factor
    PREINIT:
        tk_duration d;
        int64_t f;
        const char *what = "Time::Keeper::Duration->multiply";
    CODE:
        if (!tk_sv_to_i64(aTHX_ factor, &f))
            croak("%s: the factor is not an integer", what);
        if (!tk_dur_multiply(tk_dur_of(aTHX_ self, what), f, &d))
            croak("%s: out of range", what);
        RETVAL = tk_dur_new_sv(aTHX_ SvSTASH(SvRV(self)), &d);
    OUTPUT:
        RETVAL

SV *
total_seconds(self)
        SV *self
    PREINIT:
        const tk_duration *d;
        int64_t s;
    CODE:
        d = tk_dur_of(aTHX_ self, "Time::Keeper::Duration->total_seconds");
        if (d->months || d->days)
            croak("Time::Keeper::Duration->total_seconds: a duration with months or days is not a number of seconds");
        s = d->minutes * 60 + d->seconds;
        if (d->nsec)
            RETVAL = newSVnv((NV)s + (NV)d->nsec / TK_NSECS_PER_SEC);
        else
            RETVAL = tk_newSVi64_nv(aTHX_ s);
    OUTPUT:
        RETVAL

SV *
iso8601(self, ...)
        SV *self
    PREINIT:
        const tk_duration *d;
        int same, neg;
        int64_t y, mo, w, dd, h, mi, s;
        int32_t n;
        SV *out;
    CODE:
        d = tk_dur_of(aTHX_ self, "Time::Keeper::Duration->iso8601");
        same = !(tk_dur_has_positive(d) && tk_dur_has_negative(d));
        neg = same && tk_dur_has_negative(d);
        y = d->months / 12; mo = d->months % 12;
        w = 0; dd = d->days;
        h = d->minutes / 60; mi = d->minutes % 60;
        s = d->seconds; n = d->nsec;
        if (neg) { y = -y; mo = -mo; dd = -dd; h = -h; mi = -mi; s = -s; n = -n; }
        PERL_UNUSED_VAR(w);
        out = newSVpvs("");
        if (neg) sv_catpvs(out, "-");
        sv_catpvs(out, "P");
        if (y)  sv_catpvf(out, "%" IVdf "Y", (IV)y);
        if (mo) sv_catpvf(out, "%" IVdf "M", (IV)mo);
        if (dd) sv_catpvf(out, "%" IVdf "D", (IV)dd);
        if (h || mi || s || n || tk_dur_is_zero(d)) {
            sv_catpvs(out, "T");
            if (h)  sv_catpvf(out, "%" IVdf "H", (IV)h);
            if (mi) sv_catpvf(out, "%" IVdf "M", (IV)mi);
            if (s || n || tk_dur_is_zero(d)) {
                char frac[16];
                int fl;
                if (n && s == 0 && n < 0)
                    sv_catpvs(out, "-");
                sv_catpvf(out, "%" IVdf, (IV)s);
                if (n) {
                    fl = sprintf(frac, ".%09d", (int)(n < 0 ? -n : n));
                    while (frac[fl - 1] == '0')
                        frac[--fl] = '\0';
                    sv_catpvn(out, frac, fl);
                }
                sv_catpvs(out, "S");
            }
        }
        RETVAL = out;
    OUTPUT:
        RETVAL

IV
_compare(a, b, swapped)
        SV *a
        SV *b
        SV *swapped
    PREINIT:
        const tk_duration *x, *y;
        int64_t xs, ys;
    CODE:
        if (!tk_is_dur(aTHX_ b))
            croak("Time::Keeper::Duration: a duration can be compared only with another duration");
        x = tk_dur_of(aTHX_ a, "Time::Keeper::Duration comparison");
        y = tk_dur_of(aTHX_ b, "Time::Keeper::Duration comparison");
        if (x->months || x->days || y->months || y->days)
            croak("Time::Keeper::Duration: durations with months or days compare only from a starting point:"
                  " Time::Keeper::Duration->compare($a, $b, $start)");
        xs = x->minutes * 60 + x->seconds;
        ys = y->minutes * 60 + y->seconds;
        RETVAL = xs < ys ? -1 : xs > ys ? 1 : x->nsec < y->nsec ? -1 : x->nsec > y->nsec;
        if (SvTRUE(swapped))
            RETVAL = -RETVAL;
    OUTPUT:
        RETVAL

SV *
round(self, ...)
        SV *self
    PREINIT:
        const char *what = "Time::Keeper::Duration->round";
        const tk_duration *d;
        tk_duration out;
        tk_args a;
        int unit, mode = TK_RM_HALF_CEIL;
        int64_t inc = 1;
    CODE:
        d = tk_dur_of(aTHX_ self, what);
        if ((items - 1) % 2)
            croak("%s: say to => a unit", what);
        tk_args_parse(aTHX_ &ST(1), items - 1,
                      TK_A(TK_A_TO) | TK_A(TK_A_INCREMENT) | TK_A(TK_A_MODE) | TK_A(TK_A_RELATIVE_TO), &a, what);
        if (!a.v[TK_A_TO])
            croak("%s: say to => a unit", what);
        unit = tk_opt_dur_unit(aTHX_ a.v[TK_A_TO], "the unit", what);
        if (a.v[TK_A_INCREMENT])
            inc = tk_opt_increment(aTHX_ a.v[TK_A_INCREMENT], unit, what);
        if (a.v[TK_A_MODE])
            mode = tk_opt_mode(aTHX_ a.v[TK_A_MODE], what);
        if (a.v[TK_A_RELATIVE_TO]) {
            tk_value *rel = tk_value_rw(a.v[TK_A_RELATIVE_TO], what);
            tk_value end;
            int largest = d->months ? TK_U_MONTH : (d->days || unit <= TK_U_DAY) ? TK_U_DAY : TK_U_HOUR;
            if (!tk_value_plus_rc(aTHX_ &end, rel, d))
                croak("%s: out of range", what);
            tk_value_until(aTHX_ &out, &end, rel, largest, unit, inc, mode);
        }
        else {
            if (unit < TK_U_HOUR)
                croak("%s: %ss have no fixed length in a duration; give relative_to, a value to measure"
                      " from, or round to hours, minutes, seconds, milliseconds, microseconds or nanoseconds",
                      what, tk_unit_names[unit]);
            if (d->months || d->days)
                croak("%s: a duration with months or days has no fixed length to round; give relative_to,"
                      " a value to measure from", what);
            if (!tk_dur_round(&out, d, unit, inc, mode))
                croak("%s: out of range", what);
        }
        RETVAL = tk_dur_new_sv(aTHX_ SvSTASH(SvRV(self)), &out);
    OUTPUT:
        RETVAL

SV *
total(self, unit, ...)
        SV *self
        SV *unit
    PREINIT:
        const char *what = "Time::Keeper::Duration->total";
        const tk_duration *d;
        tk_args a;
        int u;
        double t;
    CODE:
        d = tk_dur_of(aTHX_ self, what);
        u = tk_opt_dur_unit(aTHX_ unit, "the unit", what);
        tk_args_parse(aTHX_ &ST(2), items - 2, TK_A(TK_A_RELATIVE_TO), &a, what);
        if (a.v[TK_A_RELATIVE_TO]) {
            if (!tk_dur_total_from(aTHX_ &t, d, u, tk_value_rw(a.v[TK_A_RELATIVE_TO], what)))
                croak("%s: out of range", what);
        }
        else {
            if (d->months || u <= TK_U_MONTH)
                croak("%s: months have no fixed length; give relative_to, a value to measure from", what);
            if (d->days && u >= TK_U_HOUR)
                croak("%s: a day is not always 24 hours; give relative_to, a value to measure from", what);
            t = ((double)d->days * 86400 + (double)d->minutes * 60 + (double)d->seconds
                 + (double)d->nsec / TK_NSECS_PER_SEC) / tk_unit_seconds(u);
        }
        if (t == (double)(IV)t)
            RETVAL = newSViv((IV)t);
        else
            RETVAL = newSVnv(t);
    OUTPUT:
        RETVAL

SV *
balance(self, ...)
        SV *self
    PREINIT:
        const char *what = "Time::Keeper::Duration->balance";
        const tk_duration *d;
        tk_duration out;
        tk_args a;
        tk_value *rel, base, end;
        int largest = TK_U_MONTH;
    CODE:
        d = tk_dur_of(aTHX_ self, what);
        tk_args_parse(aTHX_ &ST(1), items - 1, TK_A(TK_A_LARGEST) | TK_A(TK_A_RELATIVE_TO), &a, what);
        if (a.v[TK_A_LARGEST])
            largest = tk_opt_dur_unit(aTHX_ a.v[TK_A_LARGEST], "largest", what);
        if (a.v[TK_A_RELATIVE_TO])
            rel = tk_value_rw(a.v[TK_A_RELATIVE_TO], what);
        else {
            tk_zone_spec fl;
            tk_instant t0;
            if (d->months || d->days)
                croak("%s: months and days have no fixed length; give relative_to, a value to measure from", what);
            fl.zone = TK_ZONE_FLOATING;
            fl.fixed = 0;
            t0.sec = 0;
            t0.nsec = 0;
            tk_value_init(aTHX_ &base, &t0, &fl);
            rel = &base;
        }
        if (!tk_value_plus_rc(aTHX_ &end, rel, d))
            croak("%s: out of range", what);
        tk_value_until_raw(aTHX_ &out, &end, rel, largest);
        RETVAL = tk_dur_new_sv(aTHX_ SvSTASH(SvRV(self)), &out);
    OUTPUT:
        RETVAL

SV *
divide(self, divisor)
        SV *self
        SV *divisor
    PREINIT:
        tk_duration d;
        int64_t f, q, r, ns;
        const char *what = "Time::Keeper::Duration->divide";
    CODE:
        d = *tk_dur_of(aTHX_ self, what);
        if (!tk_sv_to_i64(aTHX_ divisor, &f))
            croak("%s: the divisor is not an integer", what);
        if (f == 0)
            croak("%s: cannot divide by zero", what);
        if (d.months % f)
            croak("%s: %" IVdf " months do not divide by %" IVdf, what, (IV)d.months, (IV)f);
        if (d.days % f)
            croak("%s: %" IVdf " days do not divide by %" IVdf, what, (IV)d.days, (IV)f);
        if (d.minutes % f)
            croak("%s: %" IVdf " minutes do not divide by %" IVdf, what, (IV)d.minutes, (IV)f);
        d.months /= f;
        d.days /= f;
        d.minutes /= f;
        q = d.seconds / f;
        r = d.seconds - q * f;
        if (r > INT64_MAX / TK_NSECS_PER_SEC || r < -(INT64_MAX / TK_NSECS_PER_SEC))
            croak("%s: out of range", what);
        ns = (r * TK_NSECS_PER_SEC + d.nsec) / f;      /* to the nanosecond, the rest dropped */
        d.seconds = q;
        if (!tk_dur_normalize(&d, ns))
            croak("%s: out of range", what);
        RETVAL = tk_dur_new_sv(aTHX_ SvSTASH(SvRV(self)), &d);
    OUTPUT:
        RETVAL

SV *
abs(self)
        SV *self
    PREINIT:
        tk_duration d;
        int neg = 0, pos = 0;
        const char *what = "Time::Keeper::Duration->abs";
    CODE:
        d = *tk_dur_of(aTHX_ self, what);
        if (d.months < 0 || d.days < 0 || d.minutes < 0 || d.seconds < 0 || d.nsec < 0) neg = 1;
        if (d.months > 0 || d.days > 0 || d.minutes > 0 || d.seconds > 0 || d.nsec > 0) pos = 1;
        if (neg && pos)
            croak("%s: a duration with parts of both signs has no absolute value", what);
        if (neg)
            tk_dur_negate(&d, 1);               /* the rule as given, not the default of the new sign */
        RETVAL = tk_dur_new_sv(aTHX_ SvSTASH(SvRV(self)), &d);
    OUTPUT:
        RETVAL

void
STORABLE_freeze(self, cloning)
        SV *self
        SV *cloning
    ALIAS:
        FREEZE = 1
    PREINIT:
        const tk_duration *d;
    PPCODE:
        PERL_UNUSED_VAR(cloning);
        d = tk_dur_of(aTHX_ self, ix ? "Time::Keeper::Duration->FREEZE" : "Time::Keeper::Duration->STORABLE_freeze");
        XPUSHs(sv_2mortal(tk_dur_freeze_sv(aTHX_ d)));

void
STORABLE_thaw(self, cloning, frozen)
        SV *self
        SV *cloning
        SV *frozen
    PREINIT:
        tk_duration d;
        const char *what = "Time::Keeper::Duration->STORABLE_thaw";
    PPCODE:
        PERL_UNUSED_VAR(cloning);
        tk_dur_thaw(aTHX_ frozen, &d, what);
        if (!SvROK(self))
            croak("%s: not a reference", what);
        sv_setpvn(SvRV(self), (const char *)&d, sizeof d);
        XSRETURN_EMPTY;

SV *
THAW(class, serialiser, frozen)
        SV *class
        SV *serialiser
        SV *frozen
    PREINIT:
        tk_duration d;
    CODE:
        PERL_UNUSED_VAR(serialiser);
        tk_dur_thaw(aTHX_ frozen, &d, "Time::Keeper::Duration->THAW");
        RETVAL = tk_dur_new_sv(aTHX_ tk_dur_stash_for(aTHX_ class), &d);
    OUTPUT:
        RETVAL

SV *
format(self, ...)
        SV *self
    PREINIT:
        static const char *const units[TK_DU_COUNT] = { "year", "month", "week", "day", "hour", "minute", "second",
                                                        "millisecond", "microsecond", "nanosecond" };
        const char *what = "Time::Keeper::Duration->format";
        const tk_duration *d;
        tk_args a;
        const tk_locale_data *loc;
        tk_out o;
        int width = TK_RW_LONG, list_type = TK_LT_UNIT, digital = 0, largest = TK_DU_COUNT;
        unsigned allowed = (1u << TK_DU_COUNT) - 1;
    CODE:
        d = tk_dur_of(aTHX_ self, what);
        tk_args_parse(aTHX_ &ST(1), items - 1, TK_A(TK_A_LOCALE) | TK_A(TK_A_STYLE) | TK_A(TK_A_UNITS) | TK_A(TK_A_LARGEST), &a, what);
        loc = tk_locale_get(aTHX_ tk_args_locale(&a, what));
        if (a.v[TK_A_STYLE]) {
            const char *s = SvPV_nolen(a.v[TK_A_STYLE]);
            if (strEQ(s, "long")) { width = TK_RW_LONG; list_type = TK_LT_UNIT; }
            else if (strEQ(s, "short")) { width = TK_RW_SHORT; list_type = TK_LT_UNIT_SHORT; }
            else if (strEQ(s, "narrow")) { width = TK_RW_NARROW; list_type = TK_LT_UNIT_NARROW; }
            else if (strEQ(s, "digital")) digital = 1;
            else croak("%s: style is 'long', 'short', 'narrow' or 'digital', not '%s'", what, s);
        }
        if (a.v[TK_A_UNITS]) {
            AV *av;
            I32 i, n;
            if (!SvROK(a.v[TK_A_UNITS]) || SvTYPE(SvRV(a.v[TK_A_UNITS])) != SVt_PVAV)
                croak("%s: units is a list of unit names", what);
            av = (AV *)SvRV(a.v[TK_A_UNITS]);
            n = av_len(av) + 1;
            if (!n)
                croak("%s: units is empty", what);
            allowed = 0;
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(av, i, 0);
                STRLEN len;
                const char *u = e ? SvPV(*e, len) : "";
                int k;
                if (len > 1 && u[len - 1] == 's') len--;
                for (k = 0; k < TK_DU_COUNT && !(strlen(units[k]) == len && memEQ(u, units[k], len)); k++) ;
                if (k == TK_DU_COUNT)
                    croak("%s: '%s' is not a unit: years, months, weeks, days, hours, minutes, seconds, milliseconds,"
                          " microseconds or nanoseconds", what, u);
                allowed |= 1u << k;
            }
        }
        if (a.v[TK_A_LARGEST])
            largest = (int)tk_opt_int(aTHX_ a.v[TK_A_LARGEST], what, "largest", 1, TK_DU_COUNT);
        o.sv = newSVpvs("");
        o.utf8 = 0;
        o.digits = loc->ascii_digits ? NULL : loc->s.digits;
        if (digital)
            tk_out_duration_digital(aTHX_ &o, loc, d, what);
        else
            tk_out_duration_words(aTHX_ &o, loc, d, width, list_type, allowed, largest, what);
        if (o.utf8)
            SvUTF8_on(o.sv);
        RETVAL = o.sv;
    OUTPUT:
        RETVAL
