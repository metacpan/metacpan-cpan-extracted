# The word grammar (include/tkn/tkn_grammar.h): _phrase, which _point calls
# until Phase 10 makes it C too.

MODULE = Time::Keeper::Natural    PACKAGE = Time::Keeper::Natural

SV *
_phrase(self, lex, words, text, k, info)
        SV *self
        SV *lex
        SV *words
        SV *text
        SV *k
        SV *info
    PREINIT:
        SV *v;
    CODE:
        v = tkn_phrase(aTHX_ self, tkn_lex(aTHX_ lex), words, text, k, tkn_rv_hv(aTHX_ info, "info"));
        RETVAL = v ? newSVsv(v) : &PL_sv_undef;
    OUTPUT:
        RETVAL
