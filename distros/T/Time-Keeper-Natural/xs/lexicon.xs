# Time::Keeper::Natural::Lexicon: a locale's words compiled into C tables
# (include/tkn/tkn_lexicon.h), its date and time patterns
# (include/tkn/tkn_patterns.h) and the normalisation every lookup starts
# from (include/tkn/tkn_norm.h).

MODULE = Time::Keeper::Natural    PACKAGE = Time::Keeper::Natural::Lexicon

SV *
for(klass, locale = &PL_sv_undef, calendar = NULL)
        SV *klass
        SV *locale
        SV *calendar
    CODE:
        if (calendar && SvOK(calendar))
            calendar = tkn_canonical_calendar(aTHX_ "Time::Keeper::Natural::Lexicon->for", calendar);
        RETVAL = newSVsv(tkn_lexicon_for_cal(aTHX_ klass, locale, calendar));
    OUTPUT:
        RETVAL

SV *
normalise(self, s)
        SV *self
        SV *s
    CODE:
        RETVAL = SvREFCNT_inc(tkn_normalise(aTHX_ s, tkn_lex(aTHX_ self)->spaceless));
    OUTPUT:
        RETVAL

SV *
ascii_digits(self, s)
        SV *self
        SV *s
    PREINIT:
        tkn_lexicon *L;
    CODE:
        L = tkn_lex(aTHX_ self);
        if (!SvOK(s))
            RETVAL = &PL_sv_undef;
        else
            RETVAL = newSVsv(tkn_ascii_digits(aTHX_ s, L->has_digits ? L->digits : NULL));
    OUTPUT:
        RETVAL

SV *
key(self, s)
        SV *self
        SV *s
    CODE:
        RETVAL = SvREFCNT_inc(tkn_key_sv(aTHX_ tkn_lex(aTHX_ self), s));
    OUTPUT:
        RETVAL

void
_spellings(self, k)
        SV *self
        SV *k
    PREINIT:
        SV *spl[2];
        int n, i;
    PPCODE:
        PERL_UNUSED_VAR(self);
        n = tkn_spellings(aTHX_ k, spl);
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            PUSHs(spl[i]);

SV *
number(self, s)
        SV *self
        SV *s
    PREINIT:
        tkn_lexicon *L;
        SV *k, *v;
        STRLEN len, i;
        const char *b;
    CODE:
        L = tkn_lex(aTHX_ self);
        RETVAL = &PL_sv_undef;
        if (SvOK(s)) {
            k = tkn_key_sv(aTHX_ L, s);
            b = SvPV_const(k, len);
            for (i = 0; i < len && b[i] >= '0' && b[i] <= '9'; i++)
                ;
            if (len && i == len)
                RETVAL = tkn_digits_sv(aTHX_ b, len, 1);
            else if ((v = tkn_value_of(aTHX_ L, TKN_T_NUMBERS, k)))
                RETVAL = newSVsv(v);
        }
    OUTPUT:
        RETVAL

SV *
ordinal(self, s)
        SV *self
        SV *s
    PREINIT:
        tkn_lexicon *L;
        SV *v;
    CODE:
        L = tkn_lex(aTHX_ self);
        RETVAL = &PL_sv_undef;
        if (SvOK(s)) {
            if (!L->ordinals_read) {
                L->ordinals_read = 1;
                tkn_number_words(aTHX_ L, TKN_T_ORDINALS, "ordinals");
            }
            if ((v = tkn_value_of(aTHX_ L, TKN_T_ORDINALS, tkn_key_sv(aTHX_ L, s))))
                RETVAL = newSVsv(v);
        }
    OUTPUT:
        RETVAL

void
fixed(self, s)
        SV *self
        SV *s
    ALIAS:
        counted = 1
        read = 2
        unit = 3
        bare = 4
        field_name = 5
        read_k = 6
        unit_k = 7
        bare_k = 8
    PREINIT:
        static const int fx[9] = { TKN_T_FIXED, -1, TKN_T_FIXED, TKN_T_UNIT_FIXED, TKN_T_BARE_FIXED, TKN_T_FIELD_NAMES,
                                   TKN_T_FIXED, TKN_T_UNIT_FIXED, TKN_T_BARE_FIXED };
        static const int cx[9] = { -1, TKN_T_COUNTED, TKN_T_COUNTED, TKN_T_UNIT_COUNTED, TKN_T_BARE, -1,
                                   TKN_T_COUNTED, TKN_T_UNIT_COUNTED, TKN_T_BARE };
        tkn_lexicon *L;
        AV *out;
        I32 i, n;
    PPCODE:
        L = tkn_lex(aTHX_ self);
        out = (AV *)sv_2mortal((SV *)newAV());
        if (ix >= 6)
            tkn_lookup_k(aTHX_ L, fx[ix], cx[ix], s, out);
        else if (SvOK(s))
            tkn_lookup_k(aTHX_ L, fx[ix], cx[ix], tkn_key_sv(aTHX_ L, s), out);
        n = av_len(out) + 1;
        SP = PL_stack_base + ax - 1;
        if (GIMME_V == G_SCALAR) {
            XPUSHs(n ? sv_2mortal(newSViv(n)) : &PL_sv_undef);
            XSRETURN(1);
        }
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            PUSHs(sv_2mortal(SvREFCNT_inc(*av_fetch(out, i, 0))));

void
markers(self, dir = &PL_sv_undef)
        SV *self
        SV *dir
    PREINIT:
        tkn_lexicon *L;
        int d = 0;
    PPCODE:
        L = tkn_lex(aTHX_ self);
        if (SvOK(dir)) {
            const char *s = SvPV_nolen(dir);
            d = strEQ(s, "past") || strEQ(s, "-1");
        }
        SP = PL_stack_base + ax - 1;
        if (GIMME_V == G_SCALAR) {
            XPUSHs(sv_2mortal(newSViv(2)));
            XSRETURN(1);
        }
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSVsv(L->markers[d][0])));
        PUSHs(sv_2mortal(newSVsv(L->markers[d][1])));

void
joiners(self)
        SV *self
    ALIAS:
        lead_joiners = 1
        tail_joiners = 2
    PREINIT:
        tkn_lexicon *L;
        I32 i, n;
    PPCODE:
        L = tkn_lex(aTHX_ self);
        n = av_len(L->jword) + 1;
        SP = PL_stack_base + ax - 1;
        if (GIMME_V == G_SCALAR) {
            IV c = 0;
            for (i = 0; i < n; i++)
                if (!ix || L->jkind[i] == ix)
                    c++;
            XPUSHs(sv_2mortal(newSViv(c)));
            XSRETURN(1);
        }
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            if (!ix || L->jkind[i] == ix)
                PUSHs(sv_2mortal(newSVsv(*av_fetch(L->jword, i, 0))));

void
patterns(self)
        SV *self
    PREINIT:
        tkn_lexicon *L;
        I32 i, n;
    PPCODE:
        L = tkn_lex(aTHX_ self);
        tkn_patterns_of(aTHX_ L);
        n = av_len(L->patterns) + 1;
        SP = PL_stack_base + ax - 1;
        if (GIMME_V == G_SCALAR) {
            XPUSHs(sv_2mortal(newSViv(n)));
            XSRETURN(1);
        }
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            PUSHs(sv_2mortal(newSVsv(*av_fetch(L->patterns, i, 0))));

SV *
code(self)
        SV *self
    ALIAS:
        spaceless = 1
        digital = 2
    PREINIT:
        tkn_lexicon *L;
    CODE:
        L = tkn_lex(aTHX_ self);
        RETVAL = ix == 0 ? newSVsv(L->code) : ix == 1 ? newSViv(L->spaceless) : newSVsv(L->digital);
    OUTPUT:
        RETVAL

SV *
lists(self, type = &PL_sv_undef)
        SV *self
        SV *type
    PREINIT:
        tkn_lexicon *L;
        SV *v;
    CODE:
        L = tkn_lex(aTHX_ self);
        v = tkn_hget(aTHX_ L->lists, SvOK(type) ? SvPV_nolen(type) : "standard");
        RETVAL = v ? newSVsv(v) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
ties(self)
        SV *self
    PREINIT:
        tkn_lexicon *L;
        tkn_table *t;
        HV *res;
        U32 i;
    CODE:
        L = tkn_lex(aTHX_ self);
        t = &L->t[TKN_T_FIXED];
        res = newHV();
        for (i = 0; i < t->cap; i++) {
            tkn_slot *s = &t->s[i];
            I32 x, count = 0, kinds = 0;
            const tkn_rec *first = NULL;
            if (s->off == TKN_EMPTY)
                continue;
            for (x = s->head; x >= 0; x = L->nodes[x].next) {
                const tkn_rec *r = &L->m[L->nodes[x].m].r;
                count++;
                if (!first) {
                    first = r;
                    kinds = 1;
                }
                else if (kinds == 1 && !(r->field == first->field && r->has_n == first->has_n && (!r->has_n || r->n == first->n)
                                         && r->weekday == first->weekday && r->month == first->month && r->period == first->period))
                    kinds = 2;
            }
            if (count < 2 || kinds < 2)
                continue;
            {
                AV *av = newAV();
                SV *k = sv_2mortal(tkn_arena_sv(aTHX_ L, s));
                for (x = s->head; x >= 0; x = L->nodes[x].next)
                    av_push(av, SvREFCNT_inc(tkn_meaning_rv(aTHX_ L, L->nodes[x].m)));
                (void)hv_store_ent(res, k, newRV_noinc((SV *)av), 0);
            }
        }
        RETVAL = newRV_noinc((SV *)res);
    OUTPUT:
        RETVAL

SV *
_tables(self)
        SV *self
    PREINIT:
        tkn_lexicon *L;
        HV *res, *mk;
        AV *j;
        int tb, d;
        I32 i;
    CODE:
        L = tkn_lex(aTHX_ self);
        if (!L->ordinals_read) {
            L->ordinals_read = 1;
            tkn_number_words(aTHX_ L, TKN_T_ORDINALS, "ordinals");
        }
        res = newHV();
        for (tb = 0; tb < TKN_T_N; tb++) {
            tkn_table *t = &L->t[tb];
            HV *h = newHV();
            U32 s;
            for (s = 0; s < t->cap; s++) {
                tkn_slot *sl = &t->s[s];
                SV *k, *v;
                if (sl->off == TKN_EMPTY)
                    continue;
                k = sv_2mortal(tkn_arena_sv(aTHX_ L, sl));
                if (tb == TKN_T_NUMBERS || tb == TKN_T_ORDINALS)
                    v = newSViv(sl->head);
                else if (tb == TKN_T_NUM_TOK || tb == TKN_T_NUM_CHAR)
                    v = newSViv(1);
                else {
                    AV *av = newAV();
                    I32 x;
                    for (x = sl->head; x >= 0; x = L->nodes[x].next)
                        av_push(av, newRV_noinc((SV *)tkn_rec_hv(aTHX_ L, &L->m[L->nodes[x].m].r)));
                    v = newRV_noinc((SV *)av);
                }
                (void)hv_store_ent(h, k, v, 0);
            }
            (void)hv_store(res, tkn_table_names[tb], (I32)strlen(tkn_table_names[tb]), newRV_noinc((SV *)h), 0);
        }
        mk = newHV();
        for (d = 0; d < 2; d++) {
            AV *av = newAV();
            av_push(av, newSVsv(L->markers[d][0]));
            av_push(av, newSVsv(L->markers[d][1]));
            (void)hv_store(mk, d ? "past" : "future", d ? 4 : 6, newRV_noinc((SV *)av), 0);
        }
        (void)hv_stores(res, "markers", newRV_noinc((SV *)mk));
        j = newAV();
        for (i = 0; i <= av_len(L->jword); i++) {
            HV *h = newHV();
            (void)hv_stores(h, "word", newSVsv(*av_fetch(L->jword, i, 0)));
            (void)hv_stores(h, "raw", newSVsv(*av_fetch(L->jraw, i, 0)));
            av_push(j, newRV_noinc((SV *)h));
        }
        (void)hv_stores(res, "joiners", newRV_noinc((SV *)j));
        (void)hv_stores(res, "num_max", newSViv(L->num_max));
        (void)hv_stores(res, "spaceless", newSViv(L->spaceless));
        if (L->has_digits) {
            HV *dm = newHV();
            for (i = 0; i < 10; i++) {
                U8 buf[UTF8_MAXBYTES + 1];
                U8 *e = uvchr_to_utf8(buf, L->digits[i]);
                (void)hv_store(dm, (const char *)buf, -(I32)(e - buf), newSViv(i), 0);
            }
            (void)hv_stores(res, "digit_map", newRV_noinc((SV *)dm));
        }
        RETVAL = newRV_noinc((SV *)res);
    OUTPUT:
        RETVAL

void
phrases(self)
        SV *self
    ALIAS:
        prefixes = 1
    PREINIT:
        tkn_lexicon *L;
        tkn_table *t;
        HV *seen;
        AV *out;
        U32 s;
        I32 i, n;
    PPCODE:
        L = tkn_lex(aTHX_ self);
        t = &L->t[ix ? TKN_T_COUNTED : TKN_T_FIXED];
        seen = (HV *)sv_2mortal((SV *)newHV());
        out = (AV *)sv_2mortal((SV *)newAV());
        for (s = 0; s < t->cap; s++) {
            tkn_slot *sl = &t->s[s];
            SV *k;
            if (sl->off == TKN_EMPTY)
                continue;
            k = sv_2mortal(tkn_arena_sv(aTHX_ L, sl));
            if (ix) {
                const char *nul = (const char *)memchr(SvPVX(k), '\0', SvCUR(k));
                if (nul)
                    SvCUR_set(k, (STRLEN)(nul - SvPVX(k)));
            }
            if (hv_exists_ent(seen, k, 0))
                continue;
            (void)hv_store_ent(seen, k, &PL_sv_yes, 0);
            av_push(out, newSVsv(k));
        }
        n = av_len(out) + 1;
        if (n > 1)
            sortsv(AvARRAY(out), n, Perl_sv_cmp);
        SP = PL_stack_base + ax - 1;
        if (GIMME_V == G_SCALAR) {
            XPUSHs(sv_2mortal(newSViv(n)));
            XSRETURN(1);
        }
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            PUSHs(sv_2mortal(newSVsv(*av_fetch(out, i, 0))));
