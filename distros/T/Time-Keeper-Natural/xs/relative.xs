# The relative grammar of Time::Keeper::Natural (include/tkn/tkn_relative.h),
# as the private methods the rest of the grammar calls until it is C too.

MODULE = Time::Keeper::Natural    PACKAGE = Time::Keeper::Natural

SV *
_relative(self, lex, k, text, info, whole = &PL_sv_undef)
        SV *self
        SV *lex
        SV *k
        SV *text
        SV *info
        SV *whole
    PREINIT:
        SV *v;
    CODE:
        PERL_UNUSED_VAR(text);
        v = tkn_relative(aTHX_ self, tkn_lex(aTHX_ lex), k, tkn_rv_hv(aTHX_ info, "info"),
                         SvOK(whole) ? tkn_rv_av(aTHX_ whole, "the whole readings") : NULL);
        RETVAL = v ? newSVsv(v) : &PL_sv_undef;
    OUTPUT:
        RETVAL

IV
_could_chain(lex, k)
        SV *lex
        SV *k
    CODE:
        RETVAL = tkn_could_chain(aTHX_ tkn_lex(aTHX_ lex), k);
    OUTPUT:
        RETVAL

SV *
_one(self, anchor, m, info)
        SV *self
        SV *anchor
        SV *m
        SV *info
    CODE:
        PERL_UNUSED_VAR(self);
        RETVAL = newSVsv(tkn_one(aTHX_ anchor, tkn_rv_hv(aTHX_ m, "a meaning"), tkn_rv_hv(aTHX_ info, "info")));
    OUTPUT:
        RETVAL

SV *
_weekday(self, anchor, d, n, info)
        SV *self
        SV *anchor
        IV d
        SV *n
        SV *info
    CODE:
        PERL_UNUSED_VAR(self);
        RETVAL = newSVsv(tkn_weekday(aTHX_ anchor, (int)d, n, tkn_rv_hv(aTHX_ info, "info")));
    OUTPUT:
        RETVAL

SV *
_add(self, anchor, parts, dir, info)
        SV *self
        SV *anchor
        SV *parts
        SV *dir
        SV *info
    CODE:
        PERL_UNUSED_VAR(self);
        RETVAL = newSVsv(tkn_add_parts(aTHX_ anchor, tkn_rv_av(aTHX_ parts, "the parts"), dir, tkn_rv_hv(aTHX_ info, "info")));
    OUTPUT:
        RETVAL

void
_group(self, lex, piece)
        SV *self
        SV *lex
        SV *piece
    PREINIT:
        AV *out;
        I32 i, n;
    PPCODE:
        PERL_UNUSED_VAR(self);
        out = (AV *)sv_2mortal((SV *)newAV());
        tkn_group(aTHX_ tkn_lex(aTHX_ lex), piece, out);
        n = av_len(out) + 1;
        SP = PL_stack_base + ax - 1;
        if (GIMME_V == G_SCALAR) {
            XPUSHs(sv_2mortal(newSViv(n)));
            XSRETURN(1);
        }
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            PUSHs(sv_2mortal(newSVsv(*av_fetch(out, i, 0))));

void
_choose(lists)
        SV *lists
    PREINIT:
        AV *out;
        I32 i, n;
    PPCODE:
        out = tkn_choose(aTHX_ tkn_rv_av(aTHX_ lists, "the lists"));
        n = av_len(out) + 1;
        SP = PL_stack_base + ax - 1;
        if (GIMME_V == G_SCALAR) {
            XPUSHs(sv_2mortal(newSViv(n)));
            XSRETURN(1);
        }
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            PUSHs(sv_2mortal(newSVsv(*av_fetch(out, i, 0))));

SV *
_groups(self, lex, k, info, read, min_n)
        SV *self
        SV *lex
        SV *k
        SV *info
        SV *read
        IV min_n
    PREINIT:
        tkn_reader r;
        AV *g;
    CODE:
        PERL_UNUSED_VAR(self);
        r.L = tkn_lex(aTHX_ lex);
        r.code = SvROK(read) && SvTYPE(SvRV(read)) == SVt_PVCV ? read : NULL;
        r.memo = (HV *)sv_2mortal((SV *)newHV());
        r.unit = 0;
        g = tkn_groups(aTHX_ r.L, k, tkn_rv_hv(aTHX_ info, "info"), &r, (int)min_n);
        RETVAL = g ? newRV_inc((SV *)g) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
_direction(self, groups, info)
        SV *self
        SV *groups
        SV *info
    PREINIT:
        int dir;
    CODE:
        PERL_UNUSED_VAR(self);
        RETVAL = tkn_direction(aTHX_ tkn_rv_av(aTHX_ groups, "the groups"), tkn_rv_hv(aTHX_ info, "info"), &dir)
               ? newSViv(dir) : &PL_sv_undef;
    OUTPUT:
        RETVAL
