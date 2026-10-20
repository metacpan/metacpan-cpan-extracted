# Durations (include/tkn/tkn_duration.h), as the private methods the rest
# of the grammar and parse_duration call until they are C too.

MODULE = Time::Keeper::Natural    PACKAGE = Time::Keeper::Natural

void
_duration(self, method, text)
        SV *self
        SV *method
        SV *text
    PREINIT:
        HV *info = NULL;
        SV *d;
    PPCODE:
        d = tkn_duration(aTHX_ self, method, text, &info);
        SP = PL_stack_base + ax - 1;
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSVsv(d)));
        PUSHs(sv_2mortal(newRV_inc((SV *)info)));

SV *
_duration_value(self, lex, k, text, info)
        SV *self
        SV *lex
        SV *k
        SV *text
        SV *info
    PREINIT:
        SV *d;
    CODE:
        PERL_UNUSED_VAR(self);
        d = tkn_duration_value(aTHX_ tkn_lex(aTHX_ lex), k, text, tkn_rv_hv(aTHX_ info, "info"));
        RETVAL = d ? newSVsv(d) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
_first_token(text)
        SV *text
    CODE:
        RETVAL = newSVsv(tkn_first_token(aTHX_ text));
    OUTPUT:
        RETVAL
