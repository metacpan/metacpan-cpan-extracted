# The night of a date, and what is up in it.

MODULE = Time::Keeper::Sky    PACKAGE = Time::Keeper::Sky

# The night of a date at the place, as a hashref; tonight, what is up in
# it, a list of hashrefs (empty in a white night or polar day). The date
# is date => (a Time::Keeper::Date or value), by default the night now in
# or the coming one.
void
night(self, ...)
        SV *self
    ALIAS:
        tonight = 1
    PREINIT:
        const char *what = ix ? "tonight" : "night";
        const tks_place *p;
        tks_night n;
        SV *date_sv = NULL;
        NV minimum = 10.0, maglimit = 1.5;
        time_keeper_instant t;
        int64_t days;
        int i;
        AV *out;
    PPCODE:
        p = tks_place_of(aTHX_ self, what);
        if ((items - 1) % 2)
            croak("%s takes name and value pairs", what);
        for (i = 1; i < items; i += 2) {
            STRLEN klen;
            const char *k;
            SV *v = ST(i + 1);
            SvGETMAGIC(ST(i));
            k = SvPV_nomg(ST(i), klen);
            SvGETMAGIC(v);
            if (klen == 4 && memEQ(k, "date", 4)) date_sv = v;
            else if (ix && klen == 16 && memEQ(k, "minimum_altitude", 16)) {
                if (!SvOK(v) || !looks_like_number(v))
                    croak("%s: minimum_altitude must be a number", what);
                minimum = SvNV_nomg(v);
                if (minimum < -1.0 || minimum >= 90.0)
                    croak("%s: minimum_altitude must be from -1 to under 90 degrees", what);
            }
            else if (ix && klen == 9 && memEQ(k, "magnitude", 9)) {
                if (!SvOK(v) || !looks_like_number(v))
                    croak("%s: magnitude must be a number", what);
                maglimit = SvNV_nomg(v);
            }
            else croak("%s: unknown argument '%.*s'", what, (int)klen, k);
        }
        if (date_sv) {
            if (SvROK(date_sv) && sv_derived_from(date_sv, "Time::Keeper::Date"))
                days = tks_days_of_date(aTHX_ date_sv);
            else if (SvROK(date_sv) && (tks_tk(aTHX)->from_sv)(aTHX_ date_sv, &t, NULL, NULL) == TIME_KEEPER_OK)
                days = tks_days_in_zone(aTHX_ p, &t, what);
            else
                croak("%s: date must be a Time::Keeper::Date or a Time::Keeper value", what);
        }
        else {
            if ((tks_tk(aTHX)->now)(&t) != TIME_KEEPER_OK)
                croak("%s: the clock could not be read", what);
            days = tks_days_in_zone(aTHX_ p, &t, what);
            if (t.sec < tks_civil_noon(aTHX_ p, days, what))
                days--;
        }
        tks_night_of(aTHX_ p, days, &n, what);
        out = (AV *)sv_2mortal((SV *)newAV());
        if (ix) {
            if (n.kind == TKS_N_NIGHT || n.kind == TKS_N_POLAR_NIGHT)
                tks_tonight(aTHX_ p, &n, minimum, maglimit, out);
        }
        else {
            HV *hv = newHV();
            int dark = n.kind == TKS_N_NIGHT || n.kind == TKS_N_POLAR_NIGHT;
            (void)hv_stores(hv, "kind", newSVpv(tks_night_kind_name[n.kind], 0));
            (void)hv_stores(hv, "start", dark ? tks_value_sv(aTHX_ p, n.start) : newSV(0));
            (void)hv_stores(hv, "end", dark ? tks_value_sv(aTHX_ p, n.end) : newSV(0));
            (void)hv_stores(hv, "date", tks_date_sv(aTHX_ days));
            av_push(out, newRV_noinc((SV *)hv));
        }
        /* tks_date_sv ran Perl, which may have moved the stack */
        SP = PL_stack_base + ax - 1;
        EXTEND(SP, av_len(out) + 1);
        for (i = 0; i <= av_len(out); i++)
            PUSHs(sv_2mortal(SvREFCNT_inc(*av_fetch(out, i, 0))));
