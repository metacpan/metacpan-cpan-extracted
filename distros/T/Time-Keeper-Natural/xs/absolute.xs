# Absolute dates and times (include/tkn/tkn_absolute.h), as the private
# methods the word grammar calls until it is C too.

MODULE = Time::Keeper::Natural    PACKAGE = Time::Keeper::Natural

SV *
_trim(text)
        SV *text
    CODE:
        RETVAL = SvOK(text) ? newSVsv(tkn_trim(aTHX_ text)) : newSVpvs("");
    OUTPUT:
        RETVAL

SV *
_absolute(self, lex, text, info, dates_only = &PL_sv_undef)
        SV *self
        SV *lex
        SV *text
        SV *info
        SV *dates_only
    PREINIT:
        SV *v;
    CODE:
        v = tkn_absolute(aTHX_ self, tkn_lex(aTHX_ lex), text, tkn_rv_hv(aTHX_ info, "info"), SvTRUE(dates_only));
        RETVAL = v ? newSVsv(v) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
_combined(self, lex, words, text, info)
        SV *self
        SV *lex
        SV *words
        SV *text
        SV *info
    PREINIT:
        SV *v;
    CODE:
        v = tkn_combined(aTHX_ self, tkn_lex(aTHX_ lex), lex, words, text, tkn_rv_hv(aTHX_ info, "info"));
        RETVAL = v ? newSVsv(v) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
_time_of_day(self, lex, anchor, raw, info)
        SV *self
        SV *lex
        SV *anchor
        SV *raw
        SV *info
    PREINIT:
        tkn_tod tod;
        int shape;
    CODE:
        if (tkn_time_of_day(aTHX_ self, tkn_lex(aTHX_ lex), anchor, raw, tkn_rv_hv(aTHX_ info, "info"), &tod, &shape))
            RETVAL = newSVsv(tkn_tod_hv(aTHX_ &tod, shape == 1, shape == 2));
        else
            RETVAL = &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
_at_time(self, day, tod)
        SV *self
        SV *day
        SV *tod
    PREINIT:
        tkn_tod t;
    CODE:
        PERL_UNUSED_VAR(self);
        tkn_tod_of(aTHX_ tod, &t);
        RETVAL = newSVsv(tkn_at_time(aTHX_ day, &t));
    OUTPUT:
        RETVAL

SV *
_day_part(self, lex, words, text, info)
        SV *self
        SV *lex
        SV *words
        SV *text
        SV *info
    PREINIT:
        SV *v;
    CODE:
        v = tkn_day_part(aTHX_ self, tkn_lex(aTHX_ lex), lex, words, text, tkn_rv_hv(aTHX_ info, "info"));
        RETVAL = v ? newSVsv(v) : &PL_sv_undef;
    OUTPUT:
        RETVAL
