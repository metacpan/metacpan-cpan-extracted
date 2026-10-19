# The walk from Perl: next, previous, between, first, iterate, contains.

MODULE = Time::Keeper::Recurrence    PACKAGE = Time::Keeper::Recurrence

SV *
next(self, ...)
        SV *self
    ALIAS:
        previous = 1
    PREINIT:
        static const char *const whats[] = { "Time::Keeper::Recurrence->next", "Time::Keeper::Recurrence->previous" };
        const tkr_rule *r;
        int64_t from, got, detail = 0;
        int rc;
    CODE:
        r = tkr_rule_of(aTHX_ self, whats[ix]);
        from = items > 1 ? tkr_instant_arg(aTHX_ ST(1), whats[ix]) : tkr_now_sec(aTHX);
        if (r->flags & TKR_F_EVERY) {
            got = ix ? from - r->every_sec : from + r->every_sec;
            rc = TKR_W_GOT;
        }
        else
            rc = ix ? tkr_previous_before(aTHX_ r, from, &got, &detail) : tkr_next_after(aTHX_ r, from, 0, &got, &detail);
        tkr_rc_croak(aTHX_ rc, r, detail, whats[ix]);
        RETVAL = rc == TKR_W_GOT ? tkr_occurrence_sv(aTHX_ r, got, whats[ix]) : &PL_sv_undef;
    OUTPUT:
        RETVAL

void
between(self, a, b)
        SV *self
        SV *a
        SV *b
    PREINIT:
        const char *what = "Time::Keeper::Recurrence->between";
        const tkr_rule *r;
        int64_t from, to, got, n = 0;
        tkr_walk w;
        int rc;
    PPCODE:
        r = tkr_rule_of(aTHX_ self, what);
        from = tkr_instant_arg(aTHX_ a, what);
        to = tkr_instant_arg(aTHX_ b, what);
        if (r->flags & TKR_F_EVERY)
            croak("%s: an @every cron has no occurrences of its own, only the next after a moment", what);
        tkr_walk_init(aTHX_ &w, r, tkr_wall_of(aTHX_ r, from, NULL) - tkr_lookback(aTHX_ r, from), 0);
        while ((rc = tkr_walk_next(aTHX_ &w, &got)) == TKR_W_GOT) {
            if (got < from)
                continue;
            if (got >= to)
                break;
            if (++n > TKR_BETWEEN_MAX) {
                tkr_walk_free(&w);
                croak("%s: more than %d occurrences; use iterate", what, TKR_BETWEEN_MAX);
            }
            XPUSHs(sv_2mortal(tkr_occurrence_sv(aTHX_ r, got, what)));
        }
        tkr_rc_croak(aTHX_ rc, r, w.fail_wall, what);
        tkr_walk_free(&w);

void
first(self, n)
        SV *self
        IV n
    PREINIT:
        const char *what = "Time::Keeper::Recurrence->first";
        const tkr_rule *r;
        int64_t got, from;
        tkr_walk w;
        int rc;
        IV i = 0;
    PPCODE:
        r = tkr_rule_of(aTHX_ self, what);
        if (n < 1 || n > TKR_BETWEEN_MAX)
            croak("%s: how many? %" IVdf " is not 1 to %d", what, n, TKR_BETWEEN_MAX);
        if (r->flags & TKR_F_EVERY)
            croak("%s: an @every cron has no occurrences of its own, only the next after a moment", what);
        from = (r->flags & TKR_F_HAS_START) ? r->start.sec : tkr_now_sec(aTHX);
        tkr_walk_init(aTHX_ &w, r, tkr_wall_of(aTHX_ r, from, NULL) - tkr_lookback(aTHX_ r, from), (r->flags & TKR_F_HAS_START) != 0);
        while (i < n && (rc = tkr_walk_next(aTHX_ &w, &got)) == TKR_W_GOT) {
            if ((r->flags & TKR_F_CRON) && got <= from)
                continue;
            XPUSHs(sv_2mortal(tkr_occurrence_sv(aTHX_ r, got, what)));
            i++;
        }
        if (i < n)
            tkr_rc_croak(aTHX_ rc, r, w.fail_wall, what);
        tkr_walk_free(&w);

IV
contains(self, t)
        SV *self
        SV *t
    PREINIT:
        const char *what = "Time::Keeper::Recurrence->contains";
        const tkr_rule *r;
        time_keeper_instant in;
        int64_t got, detail = 0;
        int rc;
    CODE:
        r = tkr_rule_of(aTHX_ self, what);
        if ((tkr_tk(aTHX)->from_sv)(aTHX_ t, &in, NULL, NULL) != TIME_KEEPER_OK)
            croak("%s: a Time::Keeper value is wanted", what);
        if (r->flags & TKR_F_EVERY)
            croak("%s: an @every cron has no occurrences of its own, only the next after a moment", what);
        rc = tkr_next_after(aTHX_ r, in.sec, 1, &got, &detail);
        tkr_rc_croak(aTHX_ rc, r, detail, what);
        RETVAL = rc == TKR_W_GOT && got == in.sec && in.nsec == tkr_occurrence_nsec(r);
    OUTPUT:
        RETVAL

void
_iterate_step(...)
    PREINIT:
        tkr_iter *it;
        int64_t got;
        int rc;
    PPCODE:
        PERL_UNUSED_VAR(items);
        it = tkr_iter_of(aTHX_ cv, "Time::Keeper::Recurrence->iterate");
        it->w.r = &it->w.rule;
        for (;;) {
            rc = tkr_walk_next(aTHX_ &it->w, &got);
            if (rc != TKR_W_GOT)
                break;
            if (got > it->from || (it->inclusive && got == it->from))
                break;
        }
        tkr_rc_croak(aTHX_ rc, &it->w.rule, it->w.fail_wall, "Time::Keeper::Recurrence->iterate");
        if (rc == TKR_W_GOT)
            XPUSHs(sv_2mortal(tkr_occurrence_sv(aTHX_ &it->w.rule, got, "Time::Keeper::Recurrence->iterate")));
        else
            XPUSHs(&PL_sv_undef);

SV *
iterate(self, ...)
        SV *self
    PREINIT:
        const char *what = "Time::Keeper::Recurrence->iterate";
        const tkr_rule *r;
        tkr_iter it;
        CV *cv;
        SV *state;
    CODE:
        r = tkr_rule_of(aTHX_ self, what);
        if (r->flags & TKR_F_EVERY)
            croak("%s: an @every cron has no occurrences of its own, only the next after a moment", what);
        memset(&it, 0, sizeof it);
        if (items > 1) {
            it.from = tkr_instant_arg(aTHX_ ST(1), what);
            it.inclusive = 0;
        }
        else if (r->flags & TKR_F_HAS_START) {
            it.from = r->start.sec;
            it.inclusive = !(r->flags & TKR_F_CRON);
        }
        else {
            it.from = tkr_now_sec(aTHX);
            it.inclusive = 0;
        }
        tkr_walk_init(aTHX_ &it.w, r, tkr_wall_of(aTHX_ r, it.from, NULL) - tkr_lookback(aTHX_ r, it.from), items == 1 && (r->flags & TKR_F_HAS_START));
        cv = newXS(NULL, XS_Time__Keeper__Recurrence__iterate_step, __FILE__);
        state = newSVpvn((const char *)&it, sizeof it);
        sv_magicext((SV *)cv, state, PERL_MAGIC_ext, &tkr_iter_vtbl, NULL, 0);
        SvREFCNT_dec(state);
        RETVAL = newRV_noinc((SV *)cv);
    OUTPUT:
        RETVAL
