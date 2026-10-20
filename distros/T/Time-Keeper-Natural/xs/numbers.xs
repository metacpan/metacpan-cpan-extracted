# Time::Keeper::Natural::Numbers: number words from CLDR's spellout rules
# (include/tkn/tkn_numbers.h).

MODULE = Time::Keeper::Natural    PACKAGE = Time::Keeper::Natural::Numbers

SV *
dir(...)
    PREINIT:
        SV *d;
    CODE:
        PERL_UNUSED_VAR(items);
        d = tkn_data_dir(aTHX_ 0);
        RETVAL = d ? newSVsv(d) : &PL_sv_undef;
    OUTPUT:
        RETVAL

void
chain(klass, code)
        SV *klass
        SV *code
    PREINIT:
        AV *av;
        I32 i, n;
    PPCODE:
        PERL_UNUSED_VAR(klass);
        av = tkn_chain(aTHX_ code);
        n = av_len(av) + 1;
        if (GIMME_V == G_SCALAR) {
            XPUSHs(sv_2mortal(newSViv(n)));
            XSRETURN(1);
        }
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            PUSHs(sv_2mortal(newSVsv(*av_fetch(av, i, 0))));

SV *
for(klass, locale = &PL_sv_undef)
        SV *klass
        SV *locale
    CODE:
        RETVAL = newSVsv(tkn_numbers_for(aTHX_ klass, locale));
    OUTPUT:
        RETVAL

void
locales(...)
    PREINIT:
        AV *av;
        I32 i, n;
    PPCODE:
        PERL_UNUSED_VAR(items);
        av = tkn_locales(aTHX_ 0);
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

void
cardinals(self)
        SV *self
    ALIAS:
        ordinals = 1
        days = 2
    PREINIT:
        SV **h;
        HV *hv;
        HE *he;
    PPCODE:
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
            croak("Time::Keeper::Natural::Numbers: not a number table");
        h = hv_fetch((HV *)SvRV(self), ix == 2 ? "d" : ix ? "o" : "c", 1, 0);
        if (!h || !SvROK(*h))
            XSRETURN_EMPTY;
        hv = (HV *)SvRV(*h);
        if (GIMME_V == G_SCALAR) {
            XPUSHs(sv_2mortal(newSViv(HvUSEDKEYS(hv))));
            XSRETURN(1);
        }
        EXTEND(SP, (SSize_t)(2 * HvUSEDKEYS(hv)));
        hv_iterinit(hv);
        while ((he = hv_iternext(hv))) {
            XPUSHs(sv_2mortal(newSVsv(hv_iterkeysv(he))));
            XPUSHs(sv_2mortal(newSVsv(HeVAL(he))));
        }

SV *
read(self, text)
        SV *self
        SV *text
    ALIAS:
        ordinal = 1
        day = 2
    PREINIT:
        SV *v;
    CODE:
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
            croak("Time::Keeper::Natural::Numbers: not a number table");
        v = tkn_numbers_read(aTHX_ self, ix == 2 ? "d" : ix ? "o" : "c", text);
        RETVAL = v ? newSVsv(v) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
code(self)
        SV *self
    PREINIT:
        SV **c;
    CODE:
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
            croak("Time::Keeper::Natural::Numbers: not a number table");
        c = hv_fetchs((HV *)SvRV(self), "code", 0);
        RETVAL = c ? newSVsv(*c) : &PL_sv_undef;
    OUTPUT:
        RETVAL
