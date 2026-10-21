# find: every mention in a text (include/tkn/tkn_find.h).

MODULE = Time::Keeper::Natural    PACKAGE = Time::Keeper::Natural

void
find(self, text = &PL_sv_undef, ...)
        SV *self
        SV *text
    PREINIT:
        SV **opts = NULL, *obj;
        I32 i, no = 0;
        int kinds = 0, names = 0;
        AV *found;
    PPCODE:
        if (items > 2 && (items - 2) % 2)
            tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvs("Time::Keeper::Natural->find: options come in pairs")));
        if (items > 2)
            Newx(opts, items - 2, SV *);
        if (opts)
            SAVEFREEPV(opts);
        for (i = 2; i + 1 < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            if (strEQ(k, "names"))
                names = SvTRUE(ST(i + 1)) ? 1 : 0;
            else if (strEQ(k, "kinds")) {
                AV *ka;
                I32 j;
                if (!SvROK(ST(i + 1)) || SvTYPE(SvRV(ST(i + 1))) != SVt_PVAV)
                    tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvs("Time::Keeper::Natural->find: kinds is a list of point, date, duration and interval")));
                ka = (AV *)SvRV(ST(i + 1));
                for (j = 0; j <= av_len(ka); j++) {
                    SV **e = av_fetch(ka, j, 0);
                    const char *ks = e && SvOK(*e) ? SvPV_nolen(*e) : "";
                    if (strEQ(ks, "point")) kinds |= TKN_FK_POINT;
                    else if (strEQ(ks, "date")) kinds |= TKN_FK_DATE;
                    else if (strEQ(ks, "duration")) kinds |= TKN_FK_DURATION;
                    else if (strEQ(ks, "interval")) kinds |= TKN_FK_INTERVAL;
                    else
                        tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("Time::Keeper::Natural->find: '%s' is not a kind; the kinds are point, date, duration and interval", ks)));
                }
                if (!kinds)
                    tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvs("Time::Keeper::Natural->find: kinds is a list of point, date, duration and interval")));
            }
            else {
                opts[no++] = ST(i);
                opts[no++] = ST(i + 1);
            }
        }
        if (!kinds)
            kinds = TKN_FK_POINT | TKN_FK_DURATION | TKN_FK_INTERVAL;
        obj = tkn_invocant(aTHX_ "find", self, no ? opts : NULL, no);
        found = tkn_find(aTHX_ obj, text, kinds, names);
        SP = PL_stack_base + ax - 1;
        if (GIMME_V == G_SCALAR) {
            XPUSHs(sv_2mortal(newSViv(av_len(found) + 1)));
            XSRETURN(1);
        }
        EXTEND(SP, av_len(found) + 1);
        for (i = 0; i <= av_len(found); i++)
            PUSHs(sv_2mortal(newSVsv(*av_fetch(found, i, 0))));
