# The schedule: construction, the three questions about a day, copies and
# serialisation.

MODULE = Time::Keeper::Business    PACKAGE = Time::Keeper::Business

SV *
new(class, ...)
        SV *class
    PREINIT:
        const char *what = "Time::Keeper::Business->new";
        HV *spec = newHV();
    CODE:
        {
            SV *guard = sv_2mortal(newRV_noinc((SV *)spec));
            tkb_spec_set(aTHX_ spec, &ST(1), items - 1, what);
            SvREFCNT_inc_simple_void_NN((SV *)spec);
            PERL_UNUSED_VAR(guard);
        }
        RETVAL = tkb_schedule_make(aTHX_ spec, tkb_stash_of(aTHX_ class), what);
    OUTPUT:
        RETVAL

int
is_business_day(self, value)
        SV *self
        SV *value
    ALIAS:
        is_weekend_day = 1
    PREINIT:
        const char *what = ix ? "Time::Keeper::Business->is_weekend_day" : "Time::Keeper::Business->is_business_day";
        tkb_schedule *s;
        tkb_val v;
    CODE:
        s = tkb_schedule_of(aTHX_ self, what);
        tkb_in_or_croak(aTHX_ value, &v, what);
        if (!ix)
            tkb_ensure(aTHX_ s, v.day, what);
        RETVAL = ix ? tkb_is_weekend(s, v.day) : !tkb_is_closed(s, v.day);
    OUTPUT:
        RETVAL

SV *
is_holiday(self, value)
        SV *self
        SV *value
    PREINIT:
        const char *what = "Time::Keeper::Business->is_holiday";
        tkb_schedule *s;
        tkb_val v;
        SV *name = NULL;
    CODE:
        s = tkb_schedule_of(aTHX_ self, what);
        tkb_in_or_croak(aTHX_ value, &v, what);
        tkb_ensure(aTHX_ s, v.day, what);
        if (!tkb_holiday(s, v.day, &name))
            RETVAL = &PL_sv_undef;
        else
            RETVAL = name ? newSVsv(name) : newSViv(1);
    OUTPUT:
        RETVAL

void
weekend(self)
        SV *self
    PREINIT:
        tkb_schedule *s;
        int d;
    PPCODE:
        s = tkb_schedule_of(aTHX_ self, "Time::Keeper::Business->weekend");
        for (d = 1; d <= 7; d++)
            if (s->weekend & TKB_WEEKEND_BIT(d))
                mXPUSHi(d);

SV *
zone(self)
        SV *self
    ALIAS:
        name = 1
        hours = 2
    PREINIT:
        static const char *const keys[] = { "zone", "name", "hours" };
        HV *spec;
        SV **p;
    CODE:
        spec = tkb_spec_of(aTHX_ self, "Time::Keeper::Business accessor");
        p = hv_fetch(spec, keys[ix], (I32)strlen(keys[ix]), 0);
        RETVAL = p && SvOK(*p) ? newSVsv(*p) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
with(self, ...)
        SV *self
    PREINIT:
        const char *what = "Time::Keeper::Business->with";
        HV *spec;
    CODE:
        spec = tkb_spec_copy(aTHX_ tkb_spec_of(aTHX_ self, what));
        {
            SV *guard = sv_2mortal(newRV_noinc((SV *)spec));
            tkb_spec_set(aTHX_ spec, &ST(1), items - 1, what);
            SvREFCNT_inc_simple_void_NN((SV *)spec);
            PERL_UNUSED_VAR(guard);
        }
        RETVAL = tkb_schedule_make(aTHX_ spec, tkb_stash_of(aTHX_ self), what);
    OUTPUT:
        RETVAL

SV *
with_holidays(self, ...)
        SV *self
    ALIAS:
        with_working_days = 1
    PREINIT:
        const char *what = ix ? "Time::Keeper::Business->with_working_days" : "Time::Keeper::Business->with_holidays";
        const char *key = ix ? "working" : "holidays";
        HV *spec;
        AV *list = newAV();
        SV **p;
        I32 i;
    CODE:
        spec = tkb_spec_copy(aTHX_ tkb_spec_of(aTHX_ self, what));
        if ((p = hv_fetch(spec, key, (I32)strlen(key), 0)) && SvOK(*p)) {
            AV *old = tkb_list_of(aTHX_ *p);
            SSize_t j, n = av_len(old) + 1;
            for (j = 0; j < n; j++) {
                SV **e = av_fetch(old, j, 0);
                av_push(list, e ? newSVsv(*e) : newSV(0));
            }
        }
        for (i = 1; i < items; i++)
            av_push(list, newSVsv(ST(i)));
        (void)hv_store(spec, key, (I32)strlen(key), newRV_noinc((SV *)list), 0);
        RETVAL = tkb_schedule_make(aTHX_ spec, tkb_stash_of(aTHX_ self), what);
    OUTPUT:
        RETVAL

SV *
join(self, other, ...)
        SV *self
        SV *other
    PREINIT:
        const char *what = "Time::Keeper::Business->join";
        tkb_schedule *a, *b, *s;
        HV *spec;
        AV *parts;
        int both = 0;
        I32 i;
        SV *rv;
    CODE:
        a = tkb_schedule_of(aTHX_ self, what);
        b = tkb_schedule_of(aTHX_ other, what);
        if ((items - 2) % 2)
            croak("%s: needs key/value pairs after the other schedule", what);
        spec = newHV();
        for (i = 2; i < items; i += 2) {
            STRLEN klen;
            const char *key = SvPV(ST(i), klen);
            if (klen == 4 && memEQ(key, "mode", 4)) {
                const char *mode = SvPV_nolen(ST(i + 1));
                if (strEQ(mode, "either")) both = 0;
                else if (strEQ(mode, "both")) both = 1;
                else { SvREFCNT_dec((SV *)spec); croak("%s: mode is 'either' or 'both', not '%s'", what, mode); }
                (void)hv_stores(spec, "mode", newSVsv(ST(i + 1)));
            }
            else if (klen == 4 && memEQ(key, "name", 4))
                (void)hv_stores(spec, "name", newSVsv(ST(i + 1)));
            else { SvREFCNT_dec((SV *)spec); croak("%s: unknown argument '%s'", what, key); }
        }
        if (!hv_fetchs(spec, "mode", 0))
            (void)hv_stores(spec, "mode", newSVpvs("either"));
        parts = newAV();
        av_push(parts, newSVsv(self));
        av_push(parts, newSVsv(other));
        (void)hv_stores(spec, "join", newRV_noinc((SV *)parts));
        s = tkb_schedule_new(aTHX);
        rv = tkb_schedule_wrap(aTHX_ s, spec, tkb_stash_of(aTHX_ self));
        s->join_a = newSVsv(self);
        s->join_b = newSVsv(other);
        s->join_both = both;
        tkb_join_refresh(aTHX_ s, what);
        PERL_UNUSED_VAR(a);
        PERL_UNUSED_VAR(b);
        RETVAL = rv;
    OUTPUT:
        RETVAL

SV *
TO_JSON(self)
        SV *self
    PREINIT:
        const char *what = "Time::Keeper::Business->TO_JSON";
    CODE:
        tkb_freezable(aTHX_ tkb_schedule_of(aTHX_ self, what), what);
        RETVAL = newRV_noinc((SV *)tkb_plain(aTHX_ tkb_schedule_of(aTHX_ self, what), tkb_spec_of(aTHX_ self, what)));
    OUTPUT:
        RETVAL

void
STORABLE_freeze(self, cloning)
        SV *self
        SV *cloning
    ALIAS:
        FREEZE = 1
    PREINIT:
        const char *what = ix ? "Time::Keeper::Business->FREEZE" : "Time::Keeper::Business->STORABLE_freeze";
        tkb_schedule *s;
    PPCODE:
        PERL_UNUSED_VAR(cloning);
        s = tkb_schedule_of(aTHX_ self, what);
        tkb_freezable(aTHX_ s, what);
        if (!ix)
            mXPUSHs(newSVpvs(""));
        mXPUSHs(newRV_noinc((SV *)tkb_plain(aTHX_ s, tkb_spec_of(aTHX_ self, what))));

void
STORABLE_thaw(self, cloning, serialized, plain)
        SV *self
        SV *cloning
        SV *serialized
        SV *plain
    PREINIT:
        const char *what = "Time::Keeper::Business->STORABLE_thaw";
        tkb_schedule *s;
        HV *spec;
    CODE:
        PERL_UNUSED_VAR(cloning);
        PERL_UNUSED_VAR(serialized);
        if (!SvROK(self) || !SvROK(plain) || SvTYPE(SvRV(plain)) != SVt_PVHV)
            croak("%s: not a frozen schedule", what);
        spec = tkb_spec_copy(aTHX_ (HV *)SvRV(plain));
        s = tkb_schedule_new(aTHX);
        tkb_schedule_attach(aTHX_ SvRV(self), s, spec);
        tkb_build_into(aTHX_ s, spec, what);

SV *
THAW(class, serialiser, plain)
        SV *class
        SV *serialiser
        SV *plain
    PREINIT:
        const char *what = "Time::Keeper::Business->THAW";
    CODE:
        PERL_UNUSED_VAR(serialiser);
        if (!SvROK(plain) || SvTYPE(SvRV(plain)) != SVt_PVHV)
            croak("%s: not a frozen schedule", what);
        RETVAL = tkb_schedule_make(aTHX_ tkb_spec_copy(aTHX_ (HV *)SvRV(plain)), tkb_stash_of(aTHX_ class), what);
    OUTPUT:
        RETVAL

SV *
_string(self, ...)
        SV *self
    PREINIT:
        HV *spec;
        SV **p;
    CODE:
        spec = tkb_spec_of(aTHX_ self, "Time::Keeper::Business");
        p = hv_fetchs(spec, "name", 0);
        if (p && SvOK(*p))
            RETVAL = newSVpvf("%s(%" SVf ")", HvNAME(SvSTASH(SvRV(self))), SVfARG(*p));
        else
            RETVAL = newSVpv(HvNAME(SvSTASH(SvRV(self))), 0);
    OUTPUT:
        RETVAL

void
holidays(self, ...)
        SV *self
    PREINIT:
        const char *what = "Time::Keeper::Business->holidays";
        tkb_schedule *s;
        int64_t from, to, y;
        unsigned m, d;
        tkb_val v;
        int n;
    PPCODE:
        s = tkb_schedule_of(aTHX_ self, what);
        if (items == 3 && !SvROK(ST(1)) && SvOK(ST(1)) && strEQ(SvPV_nolen(ST(1)), "year")) {
            if (!tkb_sv_to_i64(aTHX_ ST(2), &y))
                croak("%s: the year is not an integer", what);
            from = tkb_days_from_civil(y, 1, 1);
            to = tkb_days_from_civil(y, 12, 31);
        }
        else if (items == 3) {
            tkb_val w;
            tkb_in_or_croak(aTHX_ ST(1), &v, what);
            tkb_in_or_croak(aTHX_ ST(2), &w, what);
            from = v.day;
            to = w.day;
            if (from > to) { int64_t t = from; from = to; to = t; }
        }
        else if (items == 2) {
            tkb_in_or_croak(aTHX_ ST(1), &v, what);
            tkb_civil_from_days(v.day, &y, &m, &d);
            from = tkb_days_from_civil(y, m, 1);
            to = tkb_days_from_civil(y, m, tkb_days_in_month(y, m));
        }
        else
            croak("%s: takes year => $y, two dates, or a month", what);
        n = tkb_push_holidays(aTHX_ SP, s, from, to, what, &SP);
        XSRETURN(n);

void
holiday_sources(self)
        SV *self
    PREINIT:
        HV *spec;
        SV **p;
    PPCODE:
        spec = tkb_spec_of(aTHX_ self, "Time::Keeper::Business->holiday_sources");
        if ((p = hv_fetchs(spec, "holidays", 0)) && SvOK(*p)) {
            AV *av = tkb_list_of(aTHX_ *p);
            SSize_t i, n = av_len(av) + 1;
            EXTEND(SP, n);
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(av, i, 0);
                PUSHs(e ? sv_2mortal(newSVsv(*e)) : &PL_sv_undef);
            }
        }
