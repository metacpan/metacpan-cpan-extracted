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
        else if (v->calendar != TK_CAL_GREGORY && !(items >= 2 && tk_is_dur(aTHX_ ST(1)))) {
            /* in another calendar, years go first by month code; a duration's months are the calendar's months */
            tk_dur_args da;
            tk_value mid;
            int64_t years;
            tk_dur_args_parse(aTHX_ &ST(1), items - 1, TK_D_UNITS | TK_D(TK_D_GAP) | TK_D(TK_D_OVERLAP), &da, what);
            years = tk_dur_int(aTHX_ &da, TK_D_YEARS, what);
            da.v[TK_D_YEARS] = NULL;
            tk_dur_from_args(aTHX_ &da, &d, what);
            gap = da.v[TK_D_GAP] ? tk_opt_gap(aTHX_ da.v[TK_D_GAP], what) : TK_GAP_DEFAULT;
            overlap = da.v[TK_D_OVERLAP] ? tk_opt_overlap(aTHX_ da.v[TK_D_OVERLAP], what) : TK_OVERLAP_DEFAULT;
            if (ix) {
                years = -years;
                tk_dur_negate(&d, da.v[TK_D_EOM] != NULL);
            }
            tk_value_plus_years(aTHX_ &mid, v, years, da.v[TK_D_EOM] ? d.eom : tk_dur_default_eom(years), gap, overlap, what);
            tk_value_plus(aTHX_ &out, &mid, &d, gap, overlap, what);
            RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(self)), &out);
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
            fb.calendar = b->calendar;
            fa.calendar = a->calendar;
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
until(self, other, ...)
        SV *self
        SV *other
    ALIAS:
        since = 1
    PREINIT:
        const char *what = ix ? "Time::Keeper->since" : "Time::Keeper->until";
        tk_args a;
        tk_value *from, *to;
        tk_duration d;
        int largest = TK_U_MONTH, smallest = TK_U_NANOSECOND, mode = TK_RM_TRUNC;
        int64_t inc = 1;
    CODE:
        from = tk_value_rw(ix ? other : self, what);
        to   = tk_value_rw(ix ? self : other, what);
        tk_args_parse(aTHX_ &ST(2), items - 2,
                      TK_A(TK_A_LARGEST) | TK_A(TK_A_SMALLEST) | TK_A(TK_A_INCREMENT) | TK_A(TK_A_MODE),
                      &a, what);
        if (a.v[TK_A_LARGEST])
            largest = tk_opt_dur_unit(aTHX_ a.v[TK_A_LARGEST], "largest", what);
        if (a.v[TK_A_SMALLEST])
            smallest = tk_opt_dur_unit(aTHX_ a.v[TK_A_SMALLEST], "smallest", what);
        if (!a.v[TK_A_LARGEST] && smallest < largest)
            largest = smallest;        /* months unless smallest is larger, as Temporal has it */
        if (smallest < largest)
            croak("%s: smallest (%ss) is a larger unit than largest (%ss)", what,
                  tk_unit_names[smallest], tk_unit_names[largest]);
        if (a.v[TK_A_INCREMENT])
            inc = tk_opt_increment(aTHX_ a.v[TK_A_INCREMENT], smallest, what);
        if (a.v[TK_A_MODE])
            mode = tk_opt_mode(aTHX_ a.v[TK_A_MODE], what);
        tk_value_until(aTHX_ &d, to, from, largest, smallest, inc, mode);
        RETVAL = tk_dur_new_sv(aTHX_ tk_dur_stash(aTHX), &d);
    OUTPUT:
        RETVAL

SV *
truncate(self, ...)
        SV *self
    ALIAS:
        round = 1
        end_of = 2
    PREINIT:
        static const char *const whats[] = {
            "Time::Keeper->truncate", "Time::Keeper->round", "Time::Keeper->end_of"
        };
        const char *what = whats[ix];
        tk_args a;
        tk_value *v;
        tk_value out;
        int unit, mode = TK_RM_HALF_CEIL, ws = 1;
        int64_t inc = 1;
    CODE:
        v = tk_value_rw(self, what);
        if ((items - 1) % 2)
            croak("%s: say to => one of " TK_UNIT_LIST, what);
        tk_args_parse(aTHX_ &ST(1), items - 1,
                      TK_A(TK_A_TO) | TK_A(TK_A_WEEK_START) | (ix == 1 ? TK_A(TK_A_INCREMENT) | TK_A(TK_A_MODE) : 0), &a, what);
        if (a.v[TK_A_WEEK_START]) {
            /* a day, 1 Monday to 7 Sunday, or 'locale' for the locale's first day */
            SV *w = a.v[TK_A_WEEK_START];
            if (SvPOK(w) && strEQ(SvPV_nolen(w), "locale"))
                ws = tk_locale_of(v)->first_day;
            else
                ws = (int)tk_opt_int(aTHX_ w, what, "week_start", 1, 7);
        }
        if (!a.v[TK_A_TO])
            croak("%s: say to => one of " TK_UNIT_LIST, what);
        unit = tk_opt_unit(aTHX_ a.v[TK_A_TO], what);
        if (a.v[TK_A_INCREMENT])
            inc = tk_opt_increment(aTHX_ a.v[TK_A_INCREMENT], unit, what);
        if (a.v[TK_A_MODE])
            mode = tk_opt_mode(aTHX_ a.v[TK_A_MODE], what);
        switch (ix) {
        case 0:  tk_value_truncate_ws(aTHX_ &out, v, unit, ws, what); break;
        case 1:  tk_value_round(aTHX_ &out, v, unit, inc, mode, ws, what); break;
        default: tk_value_end_of(aTHX_ &out, v, unit, ws, what); break;
        }
        RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(self)), &out);
    OUTPUT:
        RETVAL

SV *
next(self, ...)
        SV *self
    ALIAS:
        previous = 1
    PREINIT:
        const char *what = ix ? "Time::Keeper->previous" : "Time::Keeper->next";
        tk_args a;
        tk_value *v;
        tk_value out;
        int gap, overlap, or_same;
        int64_t dow;
    CODE:
        v = tk_value_rw(self, what);
        tk_args_parse(aTHX_ &ST(1), items - 1,
                      TK_A(TK_A_DAY_OF_WEEK) | TK_A(TK_A_OR_SAME) | TK_A(TK_A_GAP) | TK_A(TK_A_OVERLAP),
                      &a, what);
        if (!a.v[TK_A_DAY_OF_WEEK])
            croak("%s: day_of_week is required", what);
        dow = tk_args_int(aTHX_ &a, TK_A_DAY_OF_WEEK, 1, 1, 7, what);
        or_same = a.v[TK_A_OR_SAME] ? SvTRUE(a.v[TK_A_OR_SAME]) : 0;
        tk_args_gap_overlap(aTHX_ &a, &gap, &overlap, what);
        tk_value_adjust_dow(aTHX_ &out, v, (int)dow, ix ? -1 : 1, or_same, gap, overlap, what);
        RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(self)), &out);
    OUTPUT:
        RETVAL

SV *
nth_in_month(self, ...)
        SV *self
    ALIAS:
        last_in_month = 1
    PREINIT:
        const char *what = ix ? "Time::Keeper->last_in_month" : "Time::Keeper->nth_in_month";
        tk_args a;
        tk_value *v;
        tk_value out;
        int gap, overlap;
        int64_t dow, n = -1;
    CODE:
        v = tk_value_rw(self, what);
        tk_args_parse(aTHX_ &ST(1), items - 1,
                      TK_A(TK_A_DAY_OF_WEEK) | (ix ? 0 : TK_A(TK_A_N)) | TK_A(TK_A_GAP) | TK_A(TK_A_OVERLAP),
                      &a, what);
        if (!a.v[TK_A_DAY_OF_WEEK])
            croak("%s: day_of_week is required", what);
        dow = tk_args_int(aTHX_ &a, TK_A_DAY_OF_WEEK, 1, 1, 7, what);
        if (!ix) {
            if (!a.v[TK_A_N])
                croak("%s: n is required: 1 to 5, or -1 for the last", what);
            n = tk_args_int(aTHX_ &a, TK_A_N, 1, -1, 5, what);
            if (n == 0)
                croak("%s: n is 1 to 5, or -1 for the last, not 0", what);
        }
        tk_args_gap_overlap(aTHX_ &a, &gap, &overlap, what);
        tk_value_nth_in_month(aTHX_ &out, v, (int)dow, (int)n, gap, overlap, what);
        RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(self)), &out);
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
        else if (tk_plain_kind_of(aTHX_ other) > 0) {
            tk_value out, *pv;
            int kind = tk_plain_kind_of(aTHX_ other);
            if (ix)
                croak("Time::Keeper::Duration: a duration minus a value means nothing");
            pv = tk_plain_of(aTHX_ other, kind, "Time::Keeper::Duration +");
            tk_plain_add(aTHX_ &out, kind, pv, &d, "Time::Keeper::Duration +");
            RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(other)), &out);
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
            tk_now_sv(aTHX_ &t);
            tk_value_init(aTHX_ &start, &t, &z);
            base = &start;
        }
        tk_value_plus(aTHX_ &vx, base, tk_dur_of(aTHX_ x, what), TK_GAP_DEFAULT, TK_OVERLAP_DEFAULT, what);
        tk_value_plus(aTHX_ &vy, base, tk_dur_of(aTHX_ y, what), TK_GAP_DEFAULT, TK_OVERLAP_DEFAULT, what);
        RETVAL = tk_value_cmp(&vx, &vy);
    OUTPUT:
        RETVAL

MODULE = Time::Keeper    PACKAGE = Time::Keeper

void
range(self, end, ...)
        SV *self
        SV *end
    PREINIT:
        tk_iter it;
        tk_value out;
        const char *what = "Time::Keeper->range";
    PPCODE:
        tk_range_init(aTHX_ &it, self, end, &ST(2), items - 2, what);
        if (tk_range_estimate(&it) > TK_RANGE_MAX)
            croak("%s: more than %d values; use iterate", what, TK_RANGE_MAX);
        while (tk_range_next(aTHX_ &it, &out, what))
            XPUSHs(sv_2mortal(tk_value_new_sv(aTHX_ it.stash, &out)));

void
_iterate_step(...)
    PREINIT:
        tk_iter *it;
        tk_value out;
    PPCODE:
        PERL_UNUSED_VAR(items);
        it = tk_iter_of(aTHX_ cv, "Time::Keeper->iterate");
        if (tk_range_next(aTHX_ it, &out, "Time::Keeper->iterate"))
            XPUSHs(sv_2mortal(tk_value_new_sv(aTHX_ it->stash, &out)));
        else
            XPUSHs(&PL_sv_undef);

SV *
iterate(self, end, ...)
        SV *self
        SV *end
    PREINIT:
        tk_iter it;
        CV *cv;
        SV *state;
    CODE:
        tk_range_init(aTHX_ &it, self, end, &ST(2), items - 2, "Time::Keeper->iterate");
        cv = newXS(NULL, XS_Time__Keeper__iterate_step, __FILE__);
        state = newSVpvn((const char *)&it, sizeof it);
        sv_magicext((SV *)cv, state, PERL_MAGIC_ext, &tk_iter_vtbl, NULL, 0);
        SvREFCNT_dec(state);
        RETVAL = newRV_noinc((SV *)cv);
    OUTPUT:
        RETVAL
