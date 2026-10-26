# Sets: rules with dates added and removed; iCalendar text in and out; the
# frozen forms of a rule and a set.

MODULE = Time::Keeper::Recurrence    PACKAGE = Time::Keeper::Recurrence

SV *
with(self, ...)
        SV *self
    PREINIT:
        const char *what = "Time::Keeper::Recurrence->with";
        tkr_set_parts p;
    CODE:
        tkr_parts_from_rule(aTHX_ &p, tkr_rule_of(aTHX_ self, what), what);
        tkr_with_args(aTHX_ &p, &ST(1), items - 1, what);
        RETVAL = tkr_set_new_sv(aTHX_ tkr_set_stash(aTHX), &p, what);
    OUTPUT:
        RETVAL

SV *
ical(self)
        SV *self
    PREINIT:
        const char *what = "Time::Keeper::Recurrence->ical";
        tkr_set_parts p;
        SV *set;
    CODE:
        tkr_parts_from_rule(aTHX_ &p, tkr_rule_of(aTHX_ self, what), what);
        set = sv_2mortal(tkr_set_new_sv(aTHX_ tkr_set_stash(aTHX), &p, what));
        RETVAL = newSVpvs("");
        tkr_ical_write(aTHX_ tkr_set_of(aTHX_ set, what), RETVAL, 0, what);
    OUTPUT:
        RETVAL

SV *
parse_ical(class, text)
        SV *class
        SV *text
    PREINIT:
        const char *what = "Time::Keeper::Recurrence->parse_ical";
        tkr_set_parts p;
        STRLEN len;
        const char *s;
        HV *stash;
    CODE:
        s = SvPV(text, len);
        tkr_ical_parse(aTHX_ s, len, &p, what);
        PERL_UNUSED_VAR(class);
        RETVAL = tkr_set_new_sv(aTHX_ tkr_set_stash(aTHX), &p, what);
    OUTPUT:
        RETVAL

void
STORABLE_freeze(self, cloning)
        SV *self
        SV *cloning
    ALIAS:
        FREEZE = 1
    PREINIT:
        const tkr_rule *r;
    PPCODE:
        PERL_UNUSED_VAR(cloning);
        r = tkr_rule_of(aTHX_ self, ix ? "Time::Keeper::Recurrence->FREEZE" : "Time::Keeper::Recurrence->STORABLE_freeze");
        XPUSHs(sv_2mortal(tkr_rule_freeze_sv(aTHX_ r, ix ? "Time::Keeper::Recurrence->FREEZE" : "Time::Keeper::Recurrence->STORABLE_freeze")));

void
STORABLE_thaw(self, cloning, frozen)
        SV *self
        SV *cloning
        SV *frozen
    PREINIT:
        const char *what = "Time::Keeper::Recurrence->STORABLE_thaw";
        tkr_rule r;
    PPCODE:
        PERL_UNUSED_VAR(cloning);
        tkr_rule_thaw(aTHX_ frozen, &r, what);
        if (!SvROK(self))
            croak("%s: not a reference", what);
        sv_setpvn(SvRV(self), (const char *)&r, sizeof r);
        XSRETURN_EMPTY;

SV *
THAW(class, serialiser, frozen)
        SV *class
        SV *serialiser
        SV *frozen
    PREINIT:
        tkr_rule r;
    CODE:
        PERL_UNUSED_VAR(serialiser);
        tkr_rule_thaw(aTHX_ frozen, &r, "Time::Keeper::Recurrence->THAW");
        RETVAL = tkr_rule_new_sv(aTHX_ tkr_stash_for(aTHX_ class), &r);
    OUTPUT:
        RETVAL

SV *
TO_JSON(self)
        SV *self
    PREINIT:
        const char *what = "Time::Keeper::Recurrence->TO_JSON";
        const tkr_rule *r;
        char err[TKR_ERR];
    CODE:
        r = tkr_rule_of(aTHX_ self, what);
        RETVAL = newSVpvs("");
        if (r->flags & TKR_F_CRON) {
            if (!tkr_cron_write(aTHX_ r, RETVAL, err))
                croak("%s: %s", what, err);
        }
        else
            tkr_rrule_write(aTHX_ r, RETVAL);
    OUTPUT:
        RETVAL

MODULE = Time::Keeper::Recurrence    PACKAGE = Time::Keeper::Recurrence::Set

SV *
with(self, ...)
        SV *self
    PREINIT:
        const char *what = "Time::Keeper::Recurrence::Set->with";
        tkr_set_parts p;
    CODE:
        tkr_parts_from_set(aTHX_ &p, tkr_set_of(aTHX_ self, what), what);
        tkr_with_args(aTHX_ &p, &ST(1), items - 1, what);
        RETVAL = tkr_set_new_sv(aTHX_ SvSTASH(SvRV(self)), &p, what);
    OUTPUT:
        RETVAL

SV *
ical(self)
        SV *self
    PREINIT:
        const char *what = "Time::Keeper::Recurrence::Set->ical";
    CODE:
        RETVAL = newSVpvs("");
        tkr_ical_write(aTHX_ tkr_set_of(aTHX_ self, what), RETVAL, 0, what);
    OUTPUT:
        RETVAL

SV *
parse_ical(class, text)
        SV *class
        SV *text
    PREINIT:
        const char *what = "Time::Keeper::Recurrence::Set->parse_ical";
        tkr_set_parts p;
        STRLEN len;
        const char *s;
        HV *stash;
    CODE:
        s = SvPV(text, len);
        tkr_ical_parse(aTHX_ s, len, &p, what);
        stash = SvROK(class) ? SvSTASH(SvRV(class)) : SvPOK(class) ? gv_stashsv(class, 0) : NULL;
        RETVAL = tkr_set_new_sv(aTHX_ stash ? stash : tkr_set_stash(aTHX), &p, what);
    OUTPUT:
        RETVAL

SV *
next(self, ...)
        SV *self
    ALIAS:
        previous = 1
    PREINIT:
        static const char *const whats[] = { "Time::Keeper::Recurrence::Set->next", "Time::Keeper::Recurrence::Set->previous" };
        const tkr_set *s;
        tkr_setiter it;
        int64_t from, got, detail = 0;
        int rc;
    CODE:
        s = tkr_set_of(aTHX_ self, whats[ix]);
        from = items > 1 ? tkr_instant_arg(aTHX_ ST(1), whats[ix]) : tkr_now_sec(aTHX);
        if (ix)
            rc = tkr_set_previous(aTHX_ self, from, &got, &detail);
        else {
            rc = tkr_setiter_init(aTHX_ &it, self, from, 0, 0);
            if (rc == TKR_W_GOT)
                rc = tkr_setiter_next(aTHX_ &it, &got);
            detail = it.fail_wall;
            tkr_setiter_free(aTHX_ &it);
        }
        tkr_set_rc_croak(aTHX_ rc, s, detail, whats[ix]);
        RETVAL = rc == TKR_W_GOT ? tkr_set_value_sv(aTHX_ s, got, whats[ix]) : &PL_sv_undef;
    OUTPUT:
        RETVAL

void
between(self, a, b)
        SV *self
        SV *a
        SV *b
    PREINIT:
        const char *what = "Time::Keeper::Recurrence::Set->between";
        const tkr_set *s;
        tkr_setiter it;
        int64_t from, to, got, n = 0, i;
        SV *held;
        int rc;
    PPCODE:
        s = tkr_set_of(aTHX_ self, what);
        from = tkr_instant_arg(aTHX_ a, what);
        to = tkr_instant_arg(aTHX_ b, what);
        held = sv_2mortal(newSV(64 * sizeof(int64_t)));
        rc = tkr_setiter_init(aTHX_ &it, self, from, 1, 0);
        if (rc == TKR_W_GOT)
            while ((rc = tkr_setiter_next(aTHX_ &it, &got)) == TKR_W_GOT) {
                if (got >= to)
                    break;
                if (n >= TKR_BETWEEN_MAX) {
                    tkr_setiter_free(aTHX_ &it);
                    croak("%s: more than %d occurrences; use iterate", what, TKR_BETWEEN_MAX);
                }
                if ((STRLEN)(n + 1) * sizeof(int64_t) > SvLEN(held))
                    SvGROW(held, SvLEN(held) * 2);
                ((int64_t *)SvPVX(held))[n++] = got;
            }
        if (rc < 0) {
            int64_t detail = it.fail_wall;
            tkr_setiter_free(aTHX_ &it);
            tkr_set_rc_croak(aTHX_ rc, s, detail, what);
        }
        tkr_setiter_free(aTHX_ &it);
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            PUSHs(sv_2mortal(tkr_set_value_sv(aTHX_ s, ((int64_t *)SvPVX(held))[i], what)));

void
first(self, n)
        SV *self
        IV n
    PREINIT:
        const char *what = "Time::Keeper::Recurrence::Set->first";
        const tkr_set *s;
        tkr_setiter it;
        int64_t got, from;
        int rc;
        IV i = 0;
    PPCODE:
        s = tkr_set_of(aTHX_ self, what);
        if (n < 1 || n > TKR_BETWEEN_MAX)
            croak("%s: how many? %" IVdf " is not 1 to %d", what, n, TKR_BETWEEN_MAX);
        from = s->has_start ? s->start.sec : tkr_now_sec(aTHX);
        rc = tkr_setiter_init(aTHX_ &it, self, from, s->has_start, s->has_start);
        if (rc == TKR_W_GOT)
            while (i < n && (rc = tkr_setiter_next(aTHX_ &it, &got)) == TKR_W_GOT) {
                XPUSHs(sv_2mortal(tkr_set_value_sv(aTHX_ s, got, what)));
                i++;
            }
        if (rc < 0) {
            int64_t detail = it.fail_wall;
            tkr_setiter_free(aTHX_ &it);
            tkr_set_rc_croak(aTHX_ rc, s, detail, what);
        }
        tkr_setiter_free(aTHX_ &it);

IV
contains(self, t)
        SV *self
        SV *t
    PREINIT:
        const char *what = "Time::Keeper::Recurrence::Set->contains";
        const tkr_set *s;
        time_keeper_instant in;
        tkr_setiter it;
        int64_t got;
        int rc;
    CODE:
        s = tkr_set_of(aTHX_ self, what);
        if ((tkr_tk(aTHX)->from_sv)(aTHX_ t, &in, NULL, NULL) != TIME_KEEPER_OK)
            croak("%s: a Time::Keeper value is wanted", what);
        rc = tkr_setiter_init(aTHX_ &it, self, in.sec, 1, 0);
        if (rc == TKR_W_GOT)
            rc = tkr_setiter_next(aTHX_ &it, &got);
        if (rc < 0) {
            int64_t detail = it.fail_wall;
            tkr_setiter_free(aTHX_ &it);
            tkr_set_rc_croak(aTHX_ rc, s, detail, what);
        }
        tkr_setiter_free(aTHX_ &it);
        RETVAL = rc == TKR_W_GOT && got == in.sec && in.nsec == tkr_set_nsec(s);
    OUTPUT:
        RETVAL

void
_iterate_step(...)
    PREINIT:
        const char *what = "Time::Keeper::Recurrence::Set->iterate";
        tkr_setiter *it;
        const tkr_set *s;
        int64_t got;
        int rc;
    PPCODE:
        PERL_UNUSED_VAR(items);
        it = tkr_setiter_of(aTHX_ cv, what);
        s = (const tkr_set *)SvPVX(SvRV(it->set_sv));
        rc = tkr_setiter_next(aTHX_ it, &got);
        tkr_set_rc_croak(aTHX_ rc, s, it->fail_wall, what);
        if (rc == TKR_W_GOT)
            XPUSHs(sv_2mortal(tkr_set_value_sv(aTHX_ s, got, what)));
        else
            XPUSHs(&PL_sv_undef);

SV *
iterate(self, ...)
        SV *self
    PREINIT:
        const char *what = "Time::Keeper::Recurrence::Set->iterate";
        const tkr_set *s;
        tkr_setiter it;
        int64_t from;
        int rc, inclusive, from_start;
        CV *cv;
        SV *state;
    CODE:
        s = tkr_set_of(aTHX_ self, what);
        if (items > 1) {
            from = tkr_instant_arg(aTHX_ ST(1), what);
            inclusive = from_start = 0;
        }
        else {
            from = s->has_start ? s->start.sec : tkr_now_sec(aTHX);
            inclusive = from_start = s->has_start;
        }
        rc = tkr_setiter_init(aTHX_ &it, self, from, inclusive, from_start);
        if (rc < 0) {
            int64_t detail = it.fail_wall;
            tkr_setiter_free(aTHX_ &it);
            tkr_set_rc_croak(aTHX_ rc, s, detail, what);
        }
        cv = newXS(NULL, XS_Time__Keeper__Recurrence__Set__iterate_step, __FILE__);
        state = newSVpvn((const char *)&it, sizeof it);
        sv_magicext((SV *)cv, state, PERL_MAGIC_ext, &tkr_setiter_vtbl, NULL, 0);
        SvREFCNT_dec(state);
        RETVAL = newRV_noinc((SV *)cv);
    OUTPUT:
        RETVAL

void
rules(self)
        SV *self
    ALIAS:
        exrules = 1
    PREINIT:
        const tkr_set *s;
        unsigned i, from, n;
    PPCODE:
        s = tkr_set_of(aTHX_ self, ix ? "Time::Keeper::Recurrence::Set->exrules" : "Time::Keeper::Recurrence::Set->rules");
        from = ix ? s->n_rules : 0;
        n = ix ? s->n_exrules : s->n_rules;
        for (i = 0; i < n; i++)
            XPUSHs(sv_2mortal(tkr_rule_new_sv(aTHX_ tkr_rule_stash(aTHX), &tkr_set_rules(s)[from + i])));

void
rdates(self)
        SV *self
    ALIAS:
        exdates = 1
    PREINIT:
        const char *what;
        const tkr_set *s;
        const tkr_date *d;
        unsigned i, n;
    PPCODE:
        what = ix ? "Time::Keeper::Recurrence::Set->exdates" : "Time::Keeper::Recurrence::Set->rdates";
        s = tkr_set_of(aTHX_ self, what);
        d = ix ? tkr_set_exdates(s) : tkr_set_rdates(s);
        n = ix ? s->n_exdates : s->n_rdates;
        for (i = 0; i < n; i++) {
            SV *v;
            PUTBACK;
            if (d[i].is_day)
                v = tkr_date_sv(aTHX_ tkr_floor_div(ix ? d[i].at : tkr_zone_wall(aTHX_ &s->zone, d[i].at), 86400), s->locale);
            else
                v = tkr_set_value_sv(aTHX_ s, d[i].at, what);
            SPAGAIN;
            XPUSHs(sv_2mortal(v));
        }

SV *
start(self)
        SV *self
    ALIAS:
        zone = 1
        gap = 2
        overlap = 3
        is_finite = 4
    PREINIT:
        static const char *const whats[] = { "Time::Keeper::Recurrence::Set->start", "Time::Keeper::Recurrence::Set->zone",
            "Time::Keeper::Recurrence::Set->gap", "Time::Keeper::Recurrence::Set->overlap", "Time::Keeper::Recurrence::Set->is_finite" };
        const tkr_set *s;
        tkr_rule probe;
        unsigned i;
    CODE:
        s = tkr_set_of(aTHX_ self, whats[ix]);
        tkr_rule_init(&probe);
        probe.zone = s->zone;
        switch (ix) {
        case 0:
            RETVAL = s->has_start ? tkr_set_value_sv(aTHX_ s, s->start.sec, whats[ix]) : &PL_sv_undef;
            break;
        case 1: RETVAL = tkr_zone_name_sv(aTHX_ &probe); break;
        case 2: RETVAL = newSVpv(tkr_gap_names[s->gap], 0); break;
        case 3: RETVAL = newSVpv(tkr_overlap_names[s->overlap], 0); break;
        default:
            RETVAL = &PL_sv_yes;
            for (i = 0; i < s->n_rules; i++) {
                const tkr_rule *r = &tkr_set_rules(s)[i];
                if ((r->flags & TKR_F_EVERY) || (!r->count && r->until_kind == TKR_UNTIL_NONE))
                    RETVAL = &PL_sv_no;
            }
        }
    OUTPUT:
        RETVAL

void
STORABLE_freeze(self, cloning)
        SV *self
        SV *cloning
    ALIAS:
        FREEZE = 1
    PREINIT:
        const char *what;
        const tkr_set *s;
    PPCODE:
        PERL_UNUSED_VAR(cloning);
        what = ix ? "Time::Keeper::Recurrence::Set->FREEZE" : "Time::Keeper::Recurrence::Set->STORABLE_freeze";
        s = tkr_set_of(aTHX_ self, what);
        XPUSHs(sv_2mortal(tkr_set_freeze_sv(aTHX_ s, what)));

void
STORABLE_thaw(self, cloning, frozen)
        SV *self
        SV *cloning
        SV *frozen
    PREINIT:
        const char *what = "Time::Keeper::Recurrence::Set->STORABLE_thaw";
        tkr_set_parts p;
        SV *made;
    PPCODE:
        PERL_UNUSED_VAR(cloning);
        if (!SvROK(self))
            croak("%s: not a reference", what);
        tkr_set_thaw(aTHX_ frozen, &p, what);
        made = sv_2mortal(tkr_set_new_sv(aTHX_ tkr_set_stash(aTHX), &p, what));
        sv_setsv(SvRV(self), SvRV(made));
        XSRETURN_EMPTY;

SV *
THAW(class, serialiser, frozen)
        SV *class
        SV *serialiser
        SV *frozen
    PREINIT:
        const char *what = "Time::Keeper::Recurrence::Set->THAW";
        tkr_set_parts p;
        HV *stash;
    CODE:
        PERL_UNUSED_VAR(serialiser);
        tkr_set_thaw(aTHX_ frozen, &p, what);
        stash = SvROK(class) ? SvSTASH(SvRV(class)) : SvPOK(class) ? gv_stashsv(class, 0) : NULL;
        RETVAL = tkr_set_new_sv(aTHX_ stash ? stash : tkr_set_stash(aTHX), &p, what);
    OUTPUT:
        RETVAL

SV *
TO_JSON(self)
        SV *self
    PREINIT:
        const char *what = "Time::Keeper::Recurrence::Set->TO_JSON";
    CODE:
        RETVAL = newSVpvs("");
        tkr_ical_write(aTHX_ tkr_set_of(aTHX_ self, what), RETVAL, 0, what);
    OUTPUT:
        RETVAL
