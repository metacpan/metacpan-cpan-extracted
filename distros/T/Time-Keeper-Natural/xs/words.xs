# Time::Keeper::Natural::Words: a locale's word table, the words CLDR does
# not have (include/tkn/tkn_words.h).

MODULE = Time::Keeper::Natural    PACKAGE = Time::Keeper::Natural::Words

SV *
dir(...)
    PREINIT:
        SV *d;
    CODE:
        PERL_UNUSED_VAR(items);
        d = tkn_data_dir(aTHX_ 1);
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
        RETVAL = newSVsv(tkn_words_for(aTHX_ klass, locale));
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

SV *
from_file(klass, file, code, forl = &PL_sv_undef)
        SV *klass
        SV *file
        SV *code
        SV *forl
    CODE:
        RETVAL = newSVsv(tkn_words_from_file(aTHX_ klass, file, code, forl));
    OUTPUT:
        RETVAL

void
frame(self, text, key)
        SV *self
        SV *text
        SV *key
    ALIAS:
        starts = 1
    PREINIT:
        AV *list;
        I32 i, n;
        tkn_fold F;
        SV *got = NULL, *raw = NULL;
    PPCODE:
        list = tkn_phrases_of(aTHX_ self, key);
        n = list && !tkn_key_is(key, "nth") && !tkn_key_is(key, "alias") ? av_len(list) + 1 : 0;
        if (n)
            tkn_fold_text(aTHX_ text, &F);
        for (i = 0; i < n && !got; i++) {
            AV *ph = (AV *)SvRV(*av_fetch(list, i, 0));
            IV flags = SvIV(*av_fetch(ph, 3, 0));
            got = tkn_frame_match(aTHX_ &F, *av_fetch(ph, 2, 0), flags, *av_fetch(ph, 4, 0));
            if (got && (flags & TKN_F_MARK) && !SvCUR(got))
                got = NULL;
            if (got)
                raw = *av_fetch(ph, 1, 0);
        }
        SP = PL_stack_base + ax - 1;
        if (ix == 1) {
            XPUSHs(raw ? sv_2mortal(newSVsv(raw)) : &PL_sv_undef);
            XSRETURN(1);
        }
        if (!got)
            XSRETURN_EMPTY;
        EXTEND(SP, 2);
        PUSHs(got);
        PUSHs(sv_2mortal(newSVsv(raw)));

void
split_on(self, text, key)
        SV *self
        SV *text
        SV *key
    PREINIT:
        AV *list;
        I32 i, n;
        tkn_fold F;
        SV *left = NULL, *right = NULL, *raw = NULL;
    PPCODE:
        list = tkn_phrases_of(aTHX_ self, key);
        n = list && !tkn_key_is(key, "nth") && !tkn_key_is(key, "alias") ? av_len(list) + 1 : 0;
        if (n)
            tkn_fold_text(aTHX_ text, &F);
        for (i = 0; i < n; i++) {
            AV *ph = (AV *)SvRV(*av_fetch(list, i, 0));
            SV *toks = *av_fetch(ph, 5, 0);
            if (!SvOK(toks))
                continue;
            if (tkn_split_match(aTHX_ &F, toks, SvIV(*av_fetch(ph, 6, 0)), &left, &right)) {
                raw = *av_fetch(ph, 1, 0);
                break;
            }
        }
        SP = PL_stack_base + ax - 1;
        if (!raw)
            XSRETURN_EMPTY;
        EXTEND(SP, 3);
        PUSHs(left);
        PUSHs(right);
        PUSHs(sv_2mortal(newSVsv(raw)));

void
articled(self, text)
        SV *self
        SV *text
    PREINIT:
        AV *list;
        I32 i, n;
        int spaceless;
        SV **sp_flag;
    PPCODE:
        list = tkn_phrases_of(aTHX_ self, sv_2mortal(newSVpvs("skip")));
        n = list ? av_len(list) + 1 : 0;
        sp_flag = hv_fetchs((HV *)SvRV(self), "spaceless", 0);
        spaceless = sp_flag && SvTRUE(*sp_flag);
        SP = PL_stack_base + ax - 1;
        if (GIMME_V == G_SCALAR) {
            XPUSHs(sv_2mortal(newSViv(n + 1)));
            XSRETURN(1);
        }
        EXTEND(SP, n + 1);
        PUSHs(sv_2mortal(newSVsv(text)));
        for (i = 0; i < n; i++) {
            SV *a = *av_fetch((AV *)SvRV(*av_fetch(list, i, 0)), 1, 0);
            STRLEN al;
            const char *ab = SvPV_const(a, al);
            SV *s = newSVsv(a);
            if (!spaceless && !tkn_ends_apos(ab, al))
                sv_catpvs(s, " ");
            sv_catsv(s, text);
            PUSHs(sv_2mortal(s));
        }

IV
is(self, k, key)
        SV *self
        SV *k
        SV *key
    PREINIT:
        AV *list;
        I32 i, n;
    CODE:
        list = tkn_phrases_of(aTHX_ self, key);
        n = list ? av_len(list) + 1 : 0;
        RETVAL = 0;
        for (i = 0; i < n; i++)
            if (SvOK(k) && sv_eq(*av_fetch((AV *)SvRV(*av_fetch(list, i, 0)), 0, 0), k))
                RETVAL++;
    OUTPUT:
        RETVAL

void
phrases(self, key)
        SV *self
        SV *key
    PREINIT:
        AV *list;
        I32 i, n;
    PPCODE:
        list = tkn_phrases_of(aTHX_ self, key);
        n = list ? av_len(list) + 1 : 0;
        if (GIMME_V == G_SCALAR) {
            XPUSHs(sv_2mortal(newSViv(n)));
            XSRETURN(1);
        }
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            PUSHs(sv_2mortal(newSVsv(*av_fetch((AV *)SvRV(*av_fetch(list, i, 0)), 1, 0))));

void
keys(self)
        SV *self
    PREINIT:
        SV **ph;
        AV *ks;
        I32 i, n;
    PPCODE:
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
            croak("Time::Keeper::Natural::Words: not a word table");
        ph = hv_fetchs((HV *)SvRV(self), "phrases", 0);
        ks = tkn_sorted_keys(aTHX_ ph && SvROK(*ph) ? (HV *)SvRV(*ph) : NULL);
        n = av_len(ks) + 1;
        if (GIMME_V == G_SCALAR) {
            XPUSHs(sv_2mortal(newSViv(n)));
            XSRETURN(1);
        }
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            PUSHs(sv_2mortal(newSVsv(*av_fetch(ks, i, 0))));

void
tests(self)
        SV *self
    PREINIT:
        SV **t;
        AV *av;
        I32 i, n;
    PPCODE:
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
            croak("Time::Keeper::Natural::Words: not a word table");
        t = hv_fetchs((HV *)SvRV(self), "tests", 0);
        av = t && SvROK(*t) ? (AV *)SvRV(*t) : NULL;
        n = av ? av_len(av) + 1 : 0;
        if (GIMME_V == G_SCALAR) {
            XPUSHs(sv_2mortal(newSViv(n)));
            XSRETURN(1);
        }
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            PUSHs(sv_2mortal(newSVsv(*av_fetch(av, i, 0))));

SV *
code(self)
        SV *self
    ALIAS:
        file = 1
    PREINIT:
        SV **c;
    CODE:
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
            croak("Time::Keeper::Natural::Words: not a word table");
        c = hv_fetch((HV *)SvRV(self), ix ? "file" : "code", ix ? 4 : 4, 0);
        RETVAL = c ? newSVsv(*c) : &PL_sv_undef;
    OUTPUT:
        RETVAL
