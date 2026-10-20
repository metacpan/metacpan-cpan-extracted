# The parser object and its public methods (include/tkn/tkn_surface.h).

MODULE = Time::Keeper::Natural    PACKAGE = Time::Keeper::Natural

SV *
new(klass, ...)
        SV *klass
    CODE:
        RETVAL = newSVsv(tkn_new(aTHX_ klass, items > 1 ? &ST(1) : NULL, items - 1));
    OUTPUT:
        RETVAL

SV *
in_locale(self, value = &PL_sv_undef)
        SV *self
        SV *value
    ALIAS:
        in_zone = 1
    PREINIT:
        SV *args[2];
    CODE:
        args[0] = sv_2mortal(newSVpv(ix ? "zone" : "locale", 0));
        args[1] = value;
        RETVAL = newSVsv(tkn_new(aTHX_ self, args, 2));
    OUTPUT:
        RETVAL

SV *
now(self)
        SV *self
    CODE:
        RETVAL = newSVsv(tkn_now(aTHX_ self));
    OUTPUT:
        RETVAL

SV *
zone(self)
        SV *self
    ALIAS:
        locale = 1
    CODE:
        RETVAL = newSVsv(ix ? tkn_locale_of(aTHX_ self) : tkn_zone_of(aTHX_ self));
    OUTPUT:
        RETVAL

SV *
bare_hour(self)
        SV *self
    ALIAS:
        prefer = 1
        keep_zone = 2
        calendar = 3
    PREINIT:
        static const char *const keys[4] = { "bare_hour", "prefer", "keep_zone", "calendar" };
        SV *v;
    CODE:
        v = SvROK(self) ? tkn_opt(aTHX_ self, keys[ix]) : NULL;
        RETVAL = v ? newSVsv(v) : &PL_sv_undef;
    OUTPUT:
        RETVAL

void
_lex_words(self)
        SV *self
    PREINIT:
        SV *lexsv, *words;
    PPCODE:
        tkn_lex_words(aTHX_ self, &lexsv, &words);
        SP = PL_stack_base + ax - 1;
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSVsv(lexsv)));
        PUSHs(sv_2mortal(newSVsv(words)));

SV *
parse(self, text = &PL_sv_undef, ...)
        SV *self
        SV *text
    ALIAS:
        parse_date = 1
        parse_duration = 2
    PREINIT:
        static const char *const names[3] = { "parse", "parse_date", "parse_duration" };
        SV *obj, *v, *method;
        HV *info = NULL;
    CODE:
        obj = tkn_invocant(aTHX_ names[ix], self, items > 2 ? &ST(2) : NULL, items > 2 ? items - 2 : 0);
        method = sv_2mortal(newSVpv(names[ix], 0));
        if (ix == 2)
            v = tkn_duration(aTHX_ obj, method, text, &info);
        else {
            v = tkn_point(aTHX_ obj, method, text, &info);
            if (ix == 1) {
                if (!get_cv("Time::Keeper::Date::new", 0))
                    load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("Time::Keeper::Date"), NULL);
                v = tkn_method(aTHX_ v, "to_date", NULL, 0);
            }
        }
        RETVAL = newSVsv(v);
    OUTPUT:
        RETVAL

SV *
coverage(self, locale = &PL_sv_undef)
        SV *self
        SV *locale
    PREINIT:
        SV *arg, *code, *w;
    CODE:
        PERL_UNUSED_VAR(self);
        arg = SvOK(locale) ? locale : sv_2mortal(newSVpvs(""));
        code = tkn_call1(aTHX_ TKN_LOC, "code", &arg, 1);
        if (!SvOK(code))
            tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("Time::Keeper::Natural->coverage: there is no locale '%" SVf "'", SVfARG(arg))));
        w = tkn_words_for(aTHX_ sv_2mortal(newSVpvs("Time::Keeper::Natural::Words")), code);
        RETVAL = newSVpv(SvTRUE(w) ? "words" : "data", 0);
    OUTPUT:
        RETVAL

void
locales(...)
    PREINIT:
        AV *av;
        I32 i, n;
    PPCODE:
        PERL_UNUSED_VAR(items);
        av = tkn_locales(aTHX_ 1);
        SP = PL_stack_base + ax - 1;
        if (!av)
            XSRETURN_EMPTY;
        n = av_len(av) + 1;
        if (GIMME_V == G_SCALAR) {
            XPUSHs(sv_2mortal(newSViv(n)));
            XSRETURN(1);
        }
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            PUSHs(sv_2mortal(newSVsv(*av_fetch(av, i, 0))));
