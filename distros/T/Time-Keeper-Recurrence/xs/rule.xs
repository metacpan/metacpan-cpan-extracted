# The rule: its three doors, what it says about itself, and the text back.

MODULE = Time::Keeper::Recurrence    PACKAGE = Time::Keeper::Recurrence

SV *
new(class, ...)
        SV *class
    PREINIT:
        const char *what = "Time::Keeper::Recurrence->new";
        tkr_opts o;
        tkr_rule r;
        char err[TKR_ERR];
        STRLEN len;
        const char *s;
    CODE:
        tkr_opts_parse(aTHX_ &ST(1), items - 1, &o, "rsgoC", what);
        if (!o.rrule)
            croak("%s: rrule => is wanted", what);
        if (!o.start)
            croak("%s: start => a Time::Keeper value is wanted: a rule needs a start", what);
        tkr_rule_init(&r);
        r.gap = TKR_GAP_FORWARD;
        r.overlap = TKR_OVERLAP_EARLIER;
        tkr_start_from_sv(aTHX_ o.start, &r, what);
        s = SvPV(o.rrule, len);
        if (!tkr_rrule_parse(s, len, &r, err))
            croak("%s: %s", what, err);
        if (o.calendar) {
            if (r.flags & TKR_F_RSCALE)
                croak("%s: calendar => and RSCALE in the rule both name a calendar: give one", what);
            tkr_calendar_opt(aTHX_ o.calendar, &r, what);
        }
        tkr_check_until_form(aTHX_ &r, what);
        tkr_gap_overlap(aTHX_ &o, &r, what);
        if (!tkr_can_fire(aTHX_ &r, 0, err))
            croak("%s: %s", what, err);
        RETVAL = tkr_rule_new_sv(aTHX_ tkr_stash_for(aTHX_ class), &r);
    OUTPUT:
        RETVAL

SV *
cron(self, ...)
        SV *self
    PREINIT:
        const char *what = "Time::Keeper::Recurrence->cron";
        tkr_opts o;
        tkr_rule r;
        char err[TKR_ERR];
        STRLEN len;
        const char *s;
    CODE:
        if (SvROK(self)) {
            /* a method on a rule: its cron spelling */
            const tkr_rule *me = tkr_rule_of(aTHX_ self, what);
            if (items != 1)
                croak("%s: a rule's cron takes no arguments", what);
            RETVAL = newSVpvs("");
            if (!tkr_cron_write(aTHX_ me, RETVAL, err))
                croak("%s: %s", what, err);
        }
        else {
            if (items < 2)
                croak("%s: a cron expression is wanted", what);
            tkr_opts_parse(aTHX_ &ST(2), items - 2, &o, "szgo", what);
            if (o.start && o.zone)
                croak("%s: start => carries the zone: not zone => as well", what);
            tkr_rule_init(&r);
            r.gap = TKR_GAP_SKIP;
            r.overlap = TKR_OVERLAP_BOTH;   /* every real minute of a doubled hour, a pinned minute once: Vixie's and Punk::Queue's rule */
            if (o.start)
                tkr_start_from_sv(aTHX_ o.start, &r, what);
            else if (o.zone)
                tkr_zone_from_sv(aTHX_ o.zone, &r, what);
            s = SvPV(ST(1), len);
            if (!tkr_cron_parse(s, len, &r, err))
                croak("%s: %s", what, err);
            tkr_gap_overlap(aTHX_ &o, &r, what);
            if (!tkr_can_fire(aTHX_ &r, tkr_now_sec(aTHX), err))
                croak("%s: cron '%s' %s", what, s, err);
            RETVAL = tkr_rule_new_sv(aTHX_ tkr_stash_for(aTHX_ self), &r);
        }
    OUTPUT:
        RETVAL

SV *
every(class, n, unit, ...)
        SV *class
        IV n
        const char *unit
    PREINIT:
        const char *what = "Time::Keeper::Recurrence->every";
        tkr_opts o;
        tkr_rule r;
        char err[TKR_ERR];
    CODE:
        tkr_opts_parse(aTHX_ &ST(3), items - 3, &o, "snaucsgoC", what);
        if (!o.start)
            croak("%s: start => a Time::Keeper value is wanted: a rule needs a start", what);
        tkr_rule_init(&r);
        r.gap = TKR_GAP_FORWARD;
        r.overlap = TKR_OVERLAP_EARLIER;
        tkr_start_from_sv(aTHX_ o.start, &r, what);
        tkr_every_build(aTHX_ n, unit, &o, &r, what);
        if (o.calendar)
            tkr_calendar_opt(aTHX_ o.calendar, &r, what);
        tkr_check_until_form(aTHX_ &r, what);
        tkr_gap_overlap(aTHX_ &o, &r, what);
        if (!tkr_can_fire(aTHX_ &r, 0, err))
            croak("%s: %s", what, err);
        RETVAL = tkr_rule_new_sv(aTHX_ tkr_stash_for(aTHX_ class), &r);
    OUTPUT:
        RETVAL

IV
check(class, expr, ...)
        SV *class
        SV *expr
    PREINIT:
        const char *what = "Time::Keeper::Recurrence->check";
        tkr_rule r;
        char err[TKR_ERR];
        STRLEN len;
        const char *s;
    CODE:
        PERL_UNUSED_VAR(class);
        tkr_rule_init(&r);
        s = SvPV(expr, len);
        if (items > 2)
            tkr_zone_from_sv(aTHX_ ST(2), &r, what);
        if (!tkr_cron_parse(s, len, &r, err))
            croak("%s: %s", what, err);
        if (!tkr_can_fire(aTHX_ &r, tkr_now_sec(aTHX), err))
            croak("%s: cron '%s' %s", what, s, err);
        RETVAL = 1;
    OUTPUT:
        RETVAL

SV *
rrule(self)
        SV *self
    PREINIT:
        const tkr_rule *r;
    CODE:
        r = tkr_rule_of(aTHX_ self, "Time::Keeper::Recurrence->rrule");
        if (r->flags & TKR_F_EVERY)
            croak("Time::Keeper::Recurrence->rrule: an @every cron is an interval from the last occurrence, which no RRULE says");
        RETVAL = newSVpvs("");
        tkr_rrule_write(aTHX_ r, RETVAL);
    OUTPUT:
        RETVAL

SV *
freq(self)
        SV *self
    ALIAS:
        interval = 1
        count = 2
        until = 3
        start = 4
        zone = 5
        gap = 6
        overlap = 7
        is_finite = 8
        wkst = 9
        calendar = 10
        skip = 11
    PREINIT:
        static const char *const whats[] = {
            "Time::Keeper::Recurrence->freq", "Time::Keeper::Recurrence->interval", "Time::Keeper::Recurrence->count",
            "Time::Keeper::Recurrence->until", "Time::Keeper::Recurrence->start", "Time::Keeper::Recurrence->zone",
            "Time::Keeper::Recurrence->gap", "Time::Keeper::Recurrence->overlap", "Time::Keeper::Recurrence->is_finite",
            "Time::Keeper::Recurrence->wkst", "Time::Keeper::Recurrence->calendar", "Time::Keeper::Recurrence->skip"
        };
        const tkr_rule *r;
    CODE:
        r = tkr_rule_of(aTHX_ self, whats[ix]);
        switch (ix) {
        case 0:  RETVAL = (r->flags & TKR_F_EVERY) ? newSVpvs("every") : newSVpv(tkr_freq_lower[r->freq], 0); break;
        case 1:  RETVAL = newSViv((IV)r->interval); break;
        case 2:  RETVAL = r->count ? newSViv((IV)r->count) : &PL_sv_undef; break;
        case 3:  RETVAL = tkr_until_sv(aTHX_ r, whats[ix]); break;
        case 4:
            if (!(r->flags & TKR_F_HAS_START)) { RETVAL = &PL_sv_undef; break; }
            RETVAL = tkr_occurrence_sv(aTHX_ r, r->start.sec, whats[ix]);
            if (!RETVAL) croak("%s: the start is outside the years Time::Keeper holds", whats[ix]);
            break;
        case 5:  RETVAL = tkr_zone_name_sv(aTHX_ r); break;
        case 6:  RETVAL = newSVpv(tkr_gap_names[r->gap], 0); break;
        case 7:  RETVAL = newSVpv(tkr_overlap_names[r->overlap], 0); break;
        case 8:  RETVAL = tkr_is_finite(r) ? &PL_sv_yes : &PL_sv_no; break;
        case 9:  RETVAL = newSViv(r->wkst + 1); break;
        case 10: {
            const char *id = NULL;
            if (!(r->flags & TKR_F_RSCALE)) { RETVAL = &PL_sv_undef; break; }
            if ((tkr_tk(aTHX)->calendar_id)(r->calendar, &id) != TIME_KEEPER_OK || !id)
                croak("%s: a calendar this build does not know", whats[ix]);
            RETVAL = newSVpv(id, 0);
            break;
        }
        default: RETVAL = (r->flags & TKR_F_RSCALE) ? newSVpv(tkr_skip_names[r->skip], 0) : &PL_sv_undef; break;
        }
    OUTPUT:
        RETVAL
