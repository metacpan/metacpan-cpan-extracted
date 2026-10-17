# Arithmetic on values: plus and minus, differences, truncating and
# rounding, and the + and - operators of both classes.

MODULE = Time::Keeper    PACKAGE = Time::Keeper

SV *
plus(self, ...)
        SV *self
    ALIAS:
        minus = 1
    PREINIT:
        tk_value *v;
        tk_value out;
        tk_duration d;
        int gap, overlap;
        const char *what = ix ? "Time::Keeper->minus" : "Time::Keeper->plus";
    CODE:
        v = tk_value_rw(self, what);
        if (ix && items == 2 && tk_is_value(aTHX_ ST(1))) {
            /* $b->minus($a): the duration from $a to $b */
            tk_value_difference(aTHX_ &d, v, tk_value_rw(ST(1), what), 1);
            RETVAL = tk_dur_new_sv(aTHX_ tk_dur_stash(aTHX), &d);
        }
        else {
            tk_plus_args(aTHX_ &ST(1), items - 1, &d, &gap, &overlap, what);
            if (ix) {
                int eom_given = 0;
                if (items >= 2 && !tk_is_dur(aTHX_ ST(1))) {
                    I32 i;
                    for (i = 1; i + 1 < items; i += 2)
                        if (strEQ(SvPV_nolen(ST(i)), "end_of_month"))
                            eom_given = 1;
                }
                tk_dur_negate(&d, eom_given);
            }
            tk_value_plus(aTHX_ &out, v, &d, gap, overlap, what);
            RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(self)), &out);
        }
    OUTPUT:
        RETVAL

SV *
minus_absolute(self, other)
        SV *self
        SV *other
    ALIAS:
        delta_ms = 1
        delta_md = 2
        delta_days = 3
    PREINIT:
        static const char *const whats[] = {
            "Time::Keeper->minus_absolute", "Time::Keeper->delta_ms",
            "Time::Keeper->delta_md", "Time::Keeper->delta_days"
        };
        const char *what = whats[ix];
        tk_value *a, *b, *big, *small;
        tk_duration d;
    CODE:
        b = tk_value_rw(self, what);
        a = tk_value_rw(other, what);
        Zero(&d, 1, tk_duration);
        switch (ix) {
        case 0: {
            tk_value aa;
            int64_t s;
            int32_t n;
            tk_value_in_zone_of(aTHX_ &aa, a, b);
            tk_value_minus_exact(b, &aa, &s, &n);
            d.seconds = s;
            d.nsec = n;
            break;
        }
        case 1:
            if (tk_value_cmp(b, a) >= 0) { big = b; small = a; } else { big = a; small = b; }
            tk_value_difference(aTHX_ &d, big, small, 0);
            d.nsec = 0;                     /* minutes and seconds only, as DateTime has it */
            break;
        case 2: {
            const tk_civil *cb = tk_value_civil(b), *ca = tk_value_civil(a);
            tk_value fb, fa;
            tk_zone_spec fl;
            fl.zone = TK_ZONE_FLOATING;
            fl.fixed = 0;
            tk_value_from_local(aTHX_ &fb, &fl, cb->year, cb->month, cb->day, 0, 0, 0, 0,
                                TKZ_GAP_CROAK, TK_OVERLAP_DEFAULT, what);
            tk_value_from_local(aTHX_ &fa, &fl, ca->year, ca->month, ca->day, 0, 0, 0, 0,
                                TKZ_GAP_CROAK, TK_OVERLAP_DEFAULT, what);
            if (tk_value_cmp(&fb, &fa) >= 0)
                tk_value_difference(aTHX_ &d, &fb, &fa, 1);
            else
                tk_value_difference(aTHX_ &d, &fa, &fb, 1);
            d.minutes = d.seconds = 0;
            d.nsec = 0;
            break;
        }
        default: {
            const tk_civil *cb = tk_value_civil(b), *ca = tk_value_civil(a);
            int64_t z = tk_days_from_civil(cb->year, cb->month, cb->day)
                      - tk_days_from_civil(ca->year, ca->month, ca->day);
            d.days = z < 0 ? -z : z;
            break;
        }
        }
        d.eom = tk_dur_default_eom(d.months);
        RETVAL = tk_dur_new_sv(aTHX_ tk_dur_stash(aTHX), &d);
    OUTPUT:
        RETVAL

SV *
truncate(self, ...)
        SV *self
    ALIAS:
        round = 1
    PREINIT:
        tk_value *v;
        tk_value lo;
        int unit;
        const char *what = ix ? "Time::Keeper->round" : "Time::Keeper->truncate";
    CODE:
        v = tk_value_rw(self, what);
        if (items != 3 || strNE(SvPV_nolen(ST(1)), "to"))
            croak("%s: say to => 'year', 'quarter', 'month', 'week', 'day', 'hour', 'minute' or 'second'", what);
        unit = tk_opt_unit(aTHX_ ST(2), what);
        tk_value_truncate(aTHX_ &lo, v, unit, what);
        if (ix) {
            tk_value hi;
            int ok;
            int64_t s1, s2;
            int32_t n1, n2;
            switch (unit) {
            case TK_U_YEAR:    ok = tk_value_calendar_rc(aTHX_ &hi, &lo, 12, 0, TK_EOM_WRAP, TKZ_GAP_FORWARD, TK_OVERLAP_DEFAULT) == TK_LOCAL_OK; break;
            case TK_U_QUARTER: ok = tk_value_calendar_rc(aTHX_ &hi, &lo, 3, 0, TK_EOM_WRAP, TKZ_GAP_FORWARD, TK_OVERLAP_DEFAULT) == TK_LOCAL_OK; break;
            case TK_U_MONTH:   ok = tk_value_calendar_rc(aTHX_ &hi, &lo, 1, 0, TK_EOM_WRAP, TKZ_GAP_FORWARD, TK_OVERLAP_DEFAULT) == TK_LOCAL_OK; break;
            case TK_U_WEEK:    ok = tk_value_calendar_rc(aTHX_ &hi, &lo, 0, 7, TK_EOM_WRAP, TKZ_GAP_FORWARD, TK_OVERLAP_DEFAULT) == TK_LOCAL_OK; break;
            case TK_U_DAY:     ok = tk_value_calendar_rc(aTHX_ &hi, &lo, 0, 1, TK_EOM_WRAP, TKZ_GAP_FORWARD, TK_OVERLAP_DEFAULT) == TK_LOCAL_OK; break;
            case TK_U_HOUR:    ok = tk_value_clock_rc(aTHX_ &hi, &lo, 60, 0, 0); break;
            case TK_U_MINUTE:  ok = tk_value_clock_rc(aTHX_ &hi, &lo, 1, 0, 0); break;
            default:           ok = tk_value_clock_rc(aTHX_ &hi, &lo, 0, 1, 0); break;
            }
            /* the nearer of the two, the later when they are as near */
            tk_value_minus_exact(v, &lo, &s1, &n1);
            if (ok) {
                tk_value_minus_exact(&hi, v, &s2, &n2);
                if (s2 < s1 || (s2 == s1 && n2 <= n1))
                    lo = hi;
            }
        }
        RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(self)), &lo);
    OUTPUT:
        RETVAL

SV *
_add_overload(self, other, swapped)
        SV *self
        SV *other
        SV *swapped
    ALIAS:
        _sub_overload = 1
    PREINIT:
        tk_value *v;
        tk_value out;
        tk_duration d;
    CODE:
        v = tk_value_rw(self, "Time::Keeper");
        if (ix && tk_is_value(aTHX_ other)) {
            if (SvTRUE(swapped))
                tk_value_difference(aTHX_ &d, tk_value_rw(other, "Time::Keeper"), v, 1);
            else
                tk_value_difference(aTHX_ &d, v, tk_value_rw(other, "Time::Keeper"), 1);
            RETVAL = tk_dur_new_sv(aTHX_ tk_dur_stash(aTHX), &d);
        }
        else {
            if (!tk_is_dur(aTHX_ other))
                croak("Time::Keeper: a value takes a Time::Keeper::Duration in + and -, or another value in -");
            if (ix && SvTRUE(swapped))
                croak("Time::Keeper: a duration minus a value means nothing");
            d = *tk_dur_of(aTHX_ other, "Time::Keeper");
            if (ix)
                tk_dur_negate(&d, 0);
            tk_value_plus(aTHX_ &out, v, &d, TK_GAP_DEFAULT, TK_OVERLAP_DEFAULT, ix ? "Time::Keeper -" : "Time::Keeper +");
            RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(self)), &out);
        }
    OUTPUT:
        RETVAL

MODULE = Time::Keeper    PACKAGE = Time::Keeper::Duration

SV *
_add_overload(self, other, swapped)
        SV *self
        SV *other
        SV *swapped
    ALIAS:
        _sub_overload = 1
        _mul_overload = 2
    PREINIT:
        tk_duration d, o;
        int64_t ns;
    CODE:
        d = *tk_dur_of(aTHX_ self, "Time::Keeper::Duration");
        if (ix == 2) {
            int64_t f;
            if (!tk_sv_to_i64(aTHX_ other, &f) || f > TK_DUR_LIMIT || f < -TK_DUR_LIMIT)
                croak("Time::Keeper::Duration: a duration is multiplied only by an integer");
            if (f && ((d.months > TK_DUR_LIMIT / (f < 0 ? -f : f)) || (d.months < -TK_DUR_LIMIT / (f < 0 ? -f : f))
                      || (d.days > TK_DUR_LIMIT / (f < 0 ? -f : f)) || (d.days < -TK_DUR_LIMIT / (f < 0 ? -f : f))
                      || (d.minutes > TK_DUR_LIMIT / (f < 0 ? -f : f)) || (d.minutes < -TK_DUR_LIMIT / (f < 0 ? -f : f))
                      || (d.seconds > TK_DUR_LIMIT / (f < 0 ? -f : f)) || (d.seconds < -TK_DUR_LIMIT / (f < 0 ? -f : f))))
                croak("Time::Keeper::Duration: out of range");
            d.months *= f; d.days *= f; d.minutes *= f; d.seconds *= f;
            ns = (int64_t)d.nsec * f;
            if (!tk_dur_normalize(&d, ns))
                croak("Time::Keeper::Duration: out of range");
            RETVAL = tk_dur_new_sv(aTHX_ SvSTASH(SvRV(self)), &d);
        }
        else if (tk_is_value(aTHX_ other)) {
            tk_value out;
            if (ix)
                croak("Time::Keeper::Duration: a duration minus a value means nothing");
            tk_value_plus(aTHX_ &out, tk_value_rw(other, "Time::Keeper"), &d, TK_GAP_DEFAULT,
                          TK_OVERLAP_DEFAULT, "Time::Keeper +");
            RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(other)), &out);
        }
        else {
            if (!tk_is_dur(aTHX_ other))
                croak("Time::Keeper::Duration: a duration takes another duration in + and -");
            o = *tk_dur_of(aTHX_ other, "Time::Keeper::Duration");
            if (ix && SvTRUE(swapped)) {
                tk_duration t = d; d = o; o = t;
            }
            if (ix)
                tk_dur_negate(&o, 1);
            d.months += o.months; d.days += o.days; d.minutes += o.minutes; d.seconds += o.seconds;
            ns = (int64_t)d.nsec + o.nsec;
            if (!tk_dur_normalize(&d, ns))
                croak("Time::Keeper::Duration: out of range");
            RETVAL = tk_dur_new_sv(aTHX_ SvSTASH(SvRV(self)), &d);
        }
    OUTPUT:
        RETVAL

SV *
_neg_overload(self, ...)
        SV *self
    PREINIT:
        tk_duration d;
    CODE:
        d = *tk_dur_of(aTHX_ self, "Time::Keeper::Duration");
        tk_dur_negate(&d, 0);
        RETVAL = tk_dur_new_sv(aTHX_ SvSTASH(SvRV(self)), &d);
    OUTPUT:
        RETVAL

IV
compare(class, x, y, ...)
        SV *class
        SV *x
        SV *y
    PREINIT:
        tk_value start, vx, vy;
        tk_value *base;
        const char *what = "Time::Keeper::Duration->compare";
    CODE:
        PERL_UNUSED_VAR(class);
        if (items > 3 && SvOK(ST(3)))
            base = tk_value_rw(ST(3), what);
        else {
            tk_zone_spec z;
            tk_instant t;
            z.zone = TK_ZONE_UTC;
            z.fixed = 0;
            tk_now(&t);
            tk_value_init(aTHX_ &start, &t, &z);
            base = &start;
        }
        tk_value_plus(aTHX_ &vx, base, tk_dur_of(aTHX_ x, what), TK_GAP_DEFAULT, TK_OVERLAP_DEFAULT, what);
        tk_value_plus(aTHX_ &vy, base, tk_dur_of(aTHX_ y, what), TK_GAP_DEFAULT, TK_OVERLAP_DEFAULT, what);
        RETVAL = tk_value_cmp(&vx, &vy);
    OUTPUT:
        RETVAL
