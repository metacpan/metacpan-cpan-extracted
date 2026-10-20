# Holiday rules: the five kinds, the three changes, a year's holidays,
# and the three example sets.

MODULE = Time::Keeper::Business    PACKAGE = Time::Keeper::Business::Rule

SV *
fixed(class, ...)
        SV *class
    ALIAS:
        nth = 1
        easter = 2
        relative = 3
        weekday_on_or_after = 5
        weekday_on_or_before = 6
        sandwiched = 7
    PREINIT:
        static const char *const names[] = {
            "Time::Keeper::Business::Rule->fixed", "Time::Keeper::Business::Rule->nth",
            "Time::Keeper::Business::Rule->easter", "Time::Keeper::Business::Rule->relative", "",
            "Time::Keeper::Business::Rule->weekday_on_or_after", "Time::Keeper::Business::Rule->weekday_on_or_before",
            "Time::Keeper::Business::Rule->sandwiched" };
        const char *what = names[ix];
        tkb_rule *r;
        SV *rv, *month = NULL, *day = NULL, *dow = NULL, *n = NULL, *offset = NULL, *orthodox = NULL, *rule = NULL, *days = NULL;
        SV *from = NULL, *to = NULL, *calendar = NULL, *code = NULL, *leap = NULL;
        I32 i;
    CODE:
        if ((items - 1) % 2)
            croak("%s: needs key/value pairs", what);
        r = tkb_rule_new(aTHX_ (int)ix);
        rv = sv_2mortal(tkb_rule_wrap(aTHX_ r, tkb_stash_of(aTHX_ class)));
        for (i = 1; i < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            SV *v = ST(i + 1);
            if ((ix == 0 || ix == 1) && strEQ(k, "month")) month = v;
            else if (ix == 0 && strEQ(k, "day")) day = v;
            else if ((ix == 1 || ix == 5 || ix == 6) && strEQ(k, "day_of_week")) dow = v;
            else if ((ix == 1 || ix == 5 || ix == 6) && strEQ(k, "n")) n = v;
            else if ((ix == 5 || ix == 6) && strEQ(k, "rule")) rule = v;
            else if ((ix == 5 || ix == 6) && strEQ(k, "days")) days = v;
            else if (ix == 2 && strEQ(k, "offset")) offset = v;
            else if (ix == 2 && strEQ(k, "orthodox")) orthodox = v;
            else if (ix == 3 && strEQ(k, "rule")) rule = v;
            else if (ix == 3 && strEQ(k, "days")) days = v;
            else if (ix <= 1 && strEQ(k, "calendar")) calendar = v;
            else if (ix <= 1 && strEQ(k, "month_code")) code = v;
            else if (ix <= 1 && strEQ(k, "leap_month")) leap = v;
            else if (!tkb_rule_common_key(aTHX_ r, k, v, &from, &to, what))
                croak("%s: unknown argument '%s'", what, k);
        }
        if (ix <= 1) {
            if (month && SvOK(month) && code && SvOK(code))
                croak("%s: month and month_code are one or the other", what);
            tkb_rule_set_calendar(aTHX_ r, calendar, code, leap, what);
            if (r->calendar && month && SvOK(month))
                croak("%s: in another calendar a month is given by its month_code", what);
            if (r->calendar && !(code && SvOK(code)))
                croak("%s: month_code is needed", what);
            if (!r->calendar && code && SvOK(code)) {
                if (r->month_leap || r->month_number > 12)
                    croak("%s: the gregory calendar has no month %s", what, SvPV_nolen(code));
                month = sv_2mortal(newSViv(r->month_number));
            }
        }
        switch (ix) {
        case 0:
            if (r->calendar) {
                r->day = (int)tkb_rule_int(aTHX_ what, "day", day, 1, 30);
                break;
            }
            r->month = (int)tkb_rule_int(aTHX_ what, "month", month, 1, 12);
            r->day = (int)tkb_rule_int(aTHX_ what, "day", day, 1, 31);
            if (!tkb_valid_civil(2000, (unsigned)r->month, (unsigned)r->day))
                croak("%s: --%02d-%02d is not a date", what, r->month, r->day);
            break;
        case 1:
            if (!r->calendar)
                r->month = (int)tkb_rule_int(aTHX_ what, "month", month, 1, 12);
            r->dow = (int)tkb_rule_int(aTHX_ what, "day_of_week", dow, 1, 7);
            r->n = (int)tkb_rule_int(aTHX_ what, "n", n, -1, 5);
            if (r->n == 0)
                croak("%s: n is 1 to 5, or -1 for the last", what);
            break;
        case 2:
            r->offset = offset && SvOK(offset) ? (int)tkb_rule_int(aTHX_ what, "offset", offset, -366, 366) : 0;
            r->orthodox = orthodox && SvTRUE(orthodox) ? 1 : 0;
            break;
        case 7:
            break;
        default: {
            tkb_rule *base = tkb_rule_magic(aTHX_ rule);
            if (!base)
                croak("%s: rule must be a Time::Keeper::Business::Rule", what);
            if (base->kind == TKB_RULE_SET)
                croak("%s: rule must not be a set", what);
            if (base->kind == TKB_RULE_SANDWICH)
                croak("%s: rule must not be a sandwiched day", what);
            r->child = newSVsv(rule);
            if (ix == 3)
                r->days = (int)tkb_rule_int(aTHX_ what, "days", days, -366, 366);
            else {
                r->days = days && SvOK(days) ? (int)tkb_rule_int(aTHX_ what, "days", days, -366, 366) : 0;
                r->dow = (int)tkb_rule_int(aTHX_ what, "day_of_week", dow, 1, 7);
                r->n = n && SvOK(n) ? (int)tkb_rule_int(aTHX_ what, "n", n, 1, 5) : 1;
            }
        }
        }
        if (from || to)
            tkb_rule_set_years(aTHX_ r, from, to, what);
        RETVAL = SvREFCNT_inc_simple_NN(rv);
    OUTPUT:
        RETVAL

SV *
set(class, ...)
        SV *class
    PREINIT:
        const char *what = "Time::Keeper::Business::Rule->set";
        tkb_rule *r;
        SV *rv, *from = NULL, *to = NULL;
        I32 i;
    CODE:
        r = tkb_rule_new(aTHX_ TKB_RULE_SET);
        rv = sv_2mortal(tkb_rule_wrap(aTHX_ r, tkb_stash_of(aTHX_ class)));
        for (i = 1; i < items; i++) {
            SV *x = ST(i);
            if (tkb_rule_magic(aTHX_ x)) {
                Renew(r->members, r->n_members + 1, SV *);
                r->members[r->n_members++] = newSVsv(x);
                continue;
            }
            if (SvROK(x) || i + 1 >= items)
                croak("%s: a member is a rule, or a key with its value", what);
            if (!tkb_rule_common_key(aTHX_ r, SvPV_nolen(x), ST(i + 1), &from, &to, what))
                croak("%s: unknown argument '%s'", what, SvPV_nolen(x));
            i++;
        }
        if (!r->n_members)
            croak("%s: a set needs at least one rule", what);
        if (from || to)
            tkb_rule_set_years(aTHX_ r, from, to, what);
        RETVAL = SvREFCNT_inc_simple_NN(rv);
    OUTPUT:
        RETVAL

SV *
observed(self, form, ...)
        SV *self
        SV *form
    PREINIT:
        const char *what = "Time::Keeper::Business::Rule->observed";
        tkb_rule *r;
        SV *rv;
        I32 i;
    CODE:
        r = tkb_rule_copy(aTHX_ tkb_rule_of(aTHX_ self, what));
        rv = sv_2mortal(tkb_rule_wrap(aTHX_ r, SvSTASH(SvRV(self))));
        tkb_rule_set_observed(aTHX_ r, form, what);
        r->observed_keep = 0;
        if ((items - 2) % 2)
            croak("%s: needs key/value pairs after the form", what);
        for (i = 2; i < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            if (strEQ(k, "keep")) {
                r->observed_keep = SvTRUE(ST(i + 1)) ? 1 : 0;
                continue;
            }
            if (!strEQ(k, "weekend"))
                croak("%s: unknown argument '%s'", what, k);
            r->weekend = tkb_rule_weekend_of(aTHX_ ST(i + 1), what);
            r->has_weekend = 1;
        }
        RETVAL = SvREFCNT_inc_simple_NN(rv);
    OUTPUT:
        RETVAL

SV *
between(self, ...)
        SV *self
    PREINIT:
        const char *what = "Time::Keeper::Business::Rule->between";
        tkb_rule *r;
        SV *rv, *from = NULL, *to = NULL;
        I32 i;
    CODE:
        r = tkb_rule_copy(aTHX_ tkb_rule_of(aTHX_ self, what));
        rv = sv_2mortal(tkb_rule_wrap(aTHX_ r, SvSTASH(SvRV(self))));
        if ((items - 1) % 2)
            croak("%s: needs key/value pairs", what);
        for (i = 1; i < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            if (strEQ(k, "from")) from = ST(i + 1);
            else if (strEQ(k, "to")) to = ST(i + 1);
            else croak("%s: unknown argument '%s'", what, k);
        }
        tkb_rule_set_years(aTHX_ r, from, to, what);
        RETVAL = SvREFCNT_inc_simple_NN(rv);
    OUTPUT:
        RETVAL

SV *
only_if(self, code)
        SV *self
        SV *code
    PREINIT:
        const char *what = "Time::Keeper::Business::Rule->only_if";
        tkb_rule *r;
        SV *rv;
    CODE:
        r = tkb_rule_copy(aTHX_ tkb_rule_of(aTHX_ self, what));
        rv = sv_2mortal(tkb_rule_wrap(aTHX_ r, SvSTASH(SvRV(self))));
        tkb_rule_set_only_if(aTHX_ r, code, what);
        RETVAL = SvREFCNT_inc_simple_NN(rv);
    OUTPUT:
        RETVAL

SV *
name(self)
        SV *self
    PREINIT:
        tkb_rule *r;
    CODE:
        r = tkb_rule_of(aTHX_ self, "Time::Keeper::Business::Rule->name");
        RETVAL = r->name ? newSVsv(r->name) : &PL_sv_undef;
    OUTPUT:
        RETVAL

void
holidays(self, ...)
        SV *self
    PREINIT:
        const char *what = "Time::Keeper::Business::Rule->holidays";
        tkb_rule *r;
        SV *year_sv = NULL;
        int64_t year;
        AV *pairs;
        SSize_t i, n;
        I32 k;
    PPCODE:
        r = tkb_rule_of(aTHX_ self, what);
        if ((items - 1) % 2)
            croak("%s: takes year => $y", what);
        for (k = 1; k < items; k += 2) {
            const char *key = SvPV_nolen(ST(k));
            if (!strEQ(key, "year"))
                croak("%s: unknown argument '%s'", what, key);
            year_sv = ST(k + 1);
        }
        year = tkb_rule_int(aTHX_ what, "year", year_sv, -999999999, 999999999);
        PUTBACK;
        pairs = tkb_rule_pairs(aTHX_ r, year);
        SPAGAIN;
        n = av_len(pairs) + 1;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            AV *src = (AV *)SvRV(*av_fetch(pairs, i, 0));
            AV *copy = newAV();
            av_push(copy, newSVsv(*av_fetch(src, 0, 0)));
            av_push(copy, newSVsv(*av_fetch(src, 1, 0)));
            PUSHs(sv_2mortal(newRV_noinc((SV *)copy)));
        }

SV *
uk(class)
        SV *class
    ALIAS:
        us_federal = 1
        target2 = 2
    PREINIT:
        HV *stash;
    CODE:
        stash = tkb_stash_of(aTHX_ class);
        RETVAL = tkb_rule_country(aTHX_ (int)ix, stash);
    OUTPUT:
        RETVAL

SV *
TO_JSON(self)
        SV *self
    CODE:
        RETVAL = tkb_rule_spec_sv(aTHX_ self, "Time::Keeper::Business::Rule->TO_JSON");
    OUTPUT:
        RETVAL

SV *
from_spec(class, spec)
        SV *class
        SV *spec
    CODE:
        RETVAL = newSVsv(tkb_rule_from_spec(aTHX_ class, spec, "Time::Keeper::Business::Rule->from_spec", 0));
    OUTPUT:
        RETVAL

void
STORABLE_freeze(self, cloning)
        SV *self
        SV *cloning
    ALIAS:
        FREEZE = 1
    PPCODE:
        PERL_UNUSED_VAR(cloning);
        if (!ix)
            mXPUSHs(newSVpvs(""));
        mXPUSHs(tkb_rule_spec_sv(aTHX_ self, ix ? "Time::Keeper::Business::Rule->FREEZE" : "Time::Keeper::Business::Rule->STORABLE_freeze"));

void
STORABLE_thaw(self, cloning, serialized, spec)
        SV *self
        SV *cloning
        SV *serialized
        SV *spec
    PREINIT:
        const char *what = "Time::Keeper::Business::Rule->STORABLE_thaw";
        SV *built, *cls;
        tkb_rule *r;
        MAGIC *mg;
    CODE:
        PERL_UNUSED_VAR(cloning);
        PERL_UNUSED_VAR(serialized);
        if (!SvROK(self))
            croak("%s: not a frozen rule", what);
        cls = sv_2mortal(newSVpv(HvNAME(SvSTASH(SvRV(self))), 0));
        built = tkb_rule_from_spec(aTHX_ cls, spec, what, 0);
        r = tkb_rule_copy(aTHX_ tkb_rule_of(aTHX_ built, what));
        mg = sv_magicext(SvRV(self), NULL, PERL_MAGIC_ext, &tkb_rule_vtbl, (const char *)r, 0);
#ifdef USE_ITHREADS
        mg->mg_flags |= MGf_DUP;
#else
        PERL_UNUSED_VAR(mg);
#endif

SV *
THAW(class, serialiser, spec)
        SV *class
        SV *serialiser
        SV *spec
    CODE:
        PERL_UNUSED_VAR(serialiser);
        RETVAL = newSVsv(tkb_rule_from_spec(aTHX_ class, spec, "Time::Keeper::Business::Rule->THAW", 0));
    OUTPUT:
        RETVAL

SV *
except(self, ...)
        SV *self
    ALIAS:
        also = 1
    PREINIT:
        const char *what = ix ? "Time::Keeper::Business::Rule->also" : "Time::Keeper::Business::Rule->except";
        const char *key = ix ? "dates" : "years";
        tkb_rule *r;
        SV *rv, *list = NULL;
        AV *av;
        SSize_t j, n;
        I32 i;
    CODE:
        r = tkb_rule_copy(aTHX_ tkb_rule_of(aTHX_ self, what));
        rv = sv_2mortal(tkb_rule_wrap(aTHX_ r, SvSTASH(SvRV(self))));
        if ((items - 1) % 2)
            croak("%s: needs key/value pairs", what);
        for (i = 1; i < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            if (!strEQ(k, key))
                croak("%s: unknown argument '%s'", what, k);
            list = ST(i + 1);
        }
        if (!list || !SvROK(list) || SvTYPE(SvRV(list)) != SVt_PVAV || sv_isobject(list))
            croak("%s: %s is a list", what, key);
        av = (AV *)SvRV(list);
        n = av_len(av) + 1;
        for (j = 0; j < n; j++) {
            SV **e = av_fetch(av, j, 0);
            int64_t v = ix ? tkb_day_from_sv(aTHX_ e ? *e : NULL, what)
                           : tkb_rule_int(aTHX_ what, "a year", e ? *e : NULL, -999999999, 999999999);
            if (ix) {
                Renew(r->also, r->n_also + 1, int64_t);
                r->also[r->n_also++] = v;
            }
            else {
                Renew(r->except, r->n_except + 1, int64_t);
                r->except[r->n_except++] = v;
            }
        }
        RETVAL = SvREFCNT_inc_simple_NN(rv);
    OUTPUT:
        RETVAL
