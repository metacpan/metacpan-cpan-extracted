# The Match, the reasons and the errors (include/tkn/tkn_match.h).

MODULE = Time::Keeper::Natural    PACKAGE = Time::Keeper::Natural

void
_invocant(method, self, text = &PL_sv_undef, ...)
        SV *method
        SV *self
        SV *text
    PREINIT:
        SV *obj;
    PPCODE:
        obj = tkn_invocant(aTHX_ SvPV_nolen(method), self, items > 3 ? &ST(3) : NULL, items > 3 ? items - 3 : 0);
        SP = PL_stack_base + ax - 1;
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSVsv(obj)));
        PUSHs(sv_2mortal(newSVsv(text)));

void
_cannot(self, method, text, token, reason)
        SV *self
        SV *method
        SV *text
        SV *token
        SV *reason
    CODE:
        PERL_UNUSED_VAR(self);
        tkn_cannot(aTHX_ method, text, token, reason);

SV *
_as_typed(lex, text, token)
        SV *lex
        SV *text
        SV *token
    CODE:
        RETVAL = newSVsv(tkn_as_typed(aTHX_ tkn_lex(aTHX_ lex), text, token));
    OUTPUT:
        RETVAL

void
_point(self, method, text)
        SV *self
        SV *method
        SV *text
    PREINIT:
        HV *info = NULL;
        SV *v;
    PPCODE:
        v = tkn_point(aTHX_ self, method, text, &info);
        SP = PL_stack_base + ax - 1;
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSVsv(v)));
        PUSHs(sv_2mortal(newRV_inc((SV *)info)));

SV *
_match(self, method, kind, text)
        SV *self
        SV *method
        SV *kind
        SV *text
    PREINIT:
        SV *m;
    CODE:
        m = tkn_match(aTHX_ self, method, SvPV_nolen(kind), text);
        RETVAL = m ? newSVsv(m) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
match(self, ...)
        SV *self
    ALIAS:
        match_date = 1
        match_duration = 2
        match_interval = 3
    PREINIT:
        static const char *const names[4] = { "match", "match_date", "match_duration", "match_interval" };
        static const char *const kinds[4] = { "point", "date", "duration", "interval" };
        SV *obj, *text, *m;
        SV *method;
    CODE:
        method = sv_2mortal(newSVpv(names[ix], 0));
        text = items > 1 ? ST(1) : &PL_sv_undef;
        obj = tkn_invocant(aTHX_ names[ix], self, items > 2 ? &ST(2) : NULL, items > 2 ? items - 2 : 0);
        m = tkn_match(aTHX_ obj, method, kinds[ix], text);
        RETVAL = m ? newSVsv(m) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
try_parse(self, ...)
        SV *self
    ALIAS:
        try_parse_date = 1
        try_parse_duration = 2
    PREINIT:
        static const char *const names[3] = { "parse", "parse_date", "parse_duration" };
        SV **args = NULL;
        I32 i, n = items - 1;
        AV *r;
    CODE:
        if (n > 0) {
            Newx(args, n, SV *);
            SAVEFREEPV(args);
            for (i = 0; i < n; i++)
                args[i] = ST(1 + i);
        }
        r = tkn_try_call(aTHX_ self, names[ix], args, n > 0 ? (int)n : 0, G_SCALAR);
        RETVAL = r && av_len(r) >= 0 ? newSVsv(*av_fetch(r, 0, 0)) : &PL_sv_undef;
    OUTPUT:
        RETVAL

void
try_parse_interval(self, ...)
        SV *self
    PREINIT:
        SV **args = NULL;
        I32 i, n = items - 1;
        AV *r;
    PPCODE:
        if (n > 0) {
            Newx(args, n, SV *);
            SAVEFREEPV(args);
            for (i = 0; i < n; i++)
                args[i] = ST(1 + i);
        }
        r = tkn_try_call(aTHX_ self, "parse_interval", args, n > 0 ? (int)n : 0, G_ARRAY);
        SP = PL_stack_base + ax - 1;
        if (r && av_len(r) == 1) {
            EXTEND(SP, 2);
            PUSHs(sv_2mortal(newSVsv(*av_fetch(r, 0, 0))));
            PUSHs(sv_2mortal(newSVsv(*av_fetch(r, 1, 0))));
        }

MODULE = Time::Keeper::Natural    PACKAGE = Time::Keeper::Natural::Match

void
assumptions(...)
    PREINIT:
        int i;
    PPCODE:
        PERL_UNUSED_VAR(items);
        SP = PL_stack_base + ax - 1;
        if (GIMME_V == G_SCALAR) {
            XPUSHs(sv_2mortal(newSViv(TKN_N_ASSUMPTIONS)));
            XSRETURN(1);
        }
        EXTEND(SP, TKN_N_ASSUMPTIONS);
        for (i = 0; i < TKN_N_ASSUMPTIONS; i++)
            PUSHs(sv_2mortal(newSVpv(tkn_assumptions[i], 0)));

SV *
_new(klass, ...)
        SV *klass
    PREINIT:
        HV *a;
        I32 i;
    CODE:
        a = (HV *)sv_2mortal((SV *)newHV());
        for (i = 1; i + 1 < items; i += 2)
            (void)hv_store_ent(a, ST(i), newSVsv(ST(i + 1)), 0);
        RETVAL = newSVsv(tkn_match_new(aTHX_ klass, a));
    OUTPUT:
        RETVAL

SV *
value(self)
        SV *self
    ALIAS:
        kind = 1
        precision = 2
        text = 3
        start = 4
        end = 5
        locale = 6
        anchor = 7
        to = 8
    PREINIT:
        static const char *const keys[9] = { "value", "kind", "precision", "text", "start", "end", "locale", "anchor", "to" };
        SV **e;
    CODE:
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
            croak("Time::Keeper::Natural::Match: not a match");
        e = hv_exists((HV *)SvRV(self), keys[ix], (I32)strlen(keys[ix])) ? hv_fetch((HV *)SvRV(self), keys[ix], (I32)strlen(keys[ix]), 0) : NULL;
        RETVAL = e ? newSVsv(*e) : &PL_sv_undef;
    OUTPUT:
        RETVAL

void
assumed(self)
        SV *self
    PREINIT:
        SV **e;
        AV *av;
        I32 i, n;
    PPCODE:
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
            croak("Time::Keeper::Natural::Match: not a match");
        e = hv_fetchs((HV *)SvRV(self), "assumed", 0);
        av = e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVAV ? (AV *)SvRV(*e) : NULL;
        n = av ? av_len(av) + 1 : 0;
        SP = PL_stack_base + ax - 1;
        if (GIMME_V == G_SCALAR) {
            XPUSHs(sv_2mortal(newSViv(n)));
            XSRETURN(1);
        }
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            PUSHs(sv_2mortal(newSVsv(*av_fetch(av, i, 0))));
