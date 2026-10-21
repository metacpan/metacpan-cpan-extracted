#ifndef TKN_MATCH_H
#define TKN_MATCH_H

static SV *tkn_in_cal(pTHX_ SV *self, SV *v);
static void tkn_lex_words_cal(pTHX_ SV *self, SV *cal, SV **lexsv, SV **words);

/* The Match, the reasons and the errors. A death from reading has one
 * shape, "Time::Keeper::Natural->parse: cannot read 'TEXT' at 'TOKEN':
 * REASON", and the reason is one of a fixed sixteen; any other is refused
 * with a confession. Deaths go through Carp, so they name the caller's line
 * as 0.01's did. A Match is a blessed hash locked as Hash::Util's
 * lock_hashref locks one, its assumptions a read-only array. */

static const char *const tkn_assumptions[] = {
    "year", "month", "century", "date", "time", "period start", "weekday next", "weekday last", "direction",
    "bare_hour am", "bare_hour pm", "bare_hour next", "zone"
};
#define TKN_N_ASSUMPTIONS 13

static const char *const tkn_precisions[] = {
    "year", "quarter", "month", "week", "day", "hour", "minute", "second", "millisecond", "microsecond",
    "nanosecond", "none"
};

/* Carp::croak or Carp::confess with a message; never returns. Called
 * straight from code outside this distribution's packages, a croak dies
 * at the calling line itself, which is the line Carp's short message names;
 * Carp would find no frame of ours to skip and write a backtrace. */
static void
tkn_carp(pTHX_ const char *fn, SV *msg)
{
    dSP;
    if (strEQ(fn, "Carp::croak")) {
        const char *pkg = CopSTASHPV(PL_curcop);
        if (!pkg || strnNE(pkg, "Time::Keeper::Natural", 21)) {
            /* Carp's short form: no ", <FH> line N", which a plain die
               adds once a filehandle has been read. */
            SV *full = sv_2mortal(newSVsv(msg));
            sv_catpvf(full, " at %s line %" IVdf ".\n", CopFILE(PL_curcop), (IV)CopLINE(PL_curcop));
            croak("%" SVf, SVfARG(full));
        }
    }
    if (!get_cv(fn, 0))
        load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("Carp"), NULL);
    SPAGAIN;
    PUSHMARK(SP);
    XPUSHs(msg);
    PUTBACK;
    call_pv(fn, G_VOID | G_DISCARD);
    croak("%" SVf, SVfARG(msg));
}

static AV *
tkn_reason_patterns(pTHX)
{
    dMY_CXT;
    if (!MY_CXT.reasons)
        MY_CXT.reasons = newSVsv(eval_pv(
            "[ qr/^the text is empty\\z/, qr/^no such word in \\S+\\z/, qr/^one direction a phrase\\z/,"
            " qr/^a duration, not a time; parse_duration reads it\\z/, qr/^a time, not a duration\\z/,"
            " qr/^\\S+ is given twice\\z/, qr/^a sign; a duration is unsigned\\z/,"
            " qr/^a bare hour; say am, pm or pass bare_hour\\z/, qr/^\\d{4}-\\d\\d-\\d\\d was an? \\S+\\z/,"
            " qr/^a time on a time\\z/, qr/^a moment, not a period\\z/, qr/^nothing left after '.+'\\z/,"
            " qr/^an ordinal weekday is counted in a month, not a \\S+\\z/, qr/^no month has a \\S+ \\S+\\z/,"
            " qr/^\\d{4}-\\d\\d has no \\S+ \\S+\\z/, qr/^coverage of \\S+ is data; '.+' needs its words\\z/,"
            " qr/^'.+' means .+ in \\S+; pass prefer\\z/, qr/^the interval ends before it starts\\z/,"
            " qr/^a single time, not an interval\\z/, qr/^'.+' names more than one zone in \\S+\\z/,"
            " qr/^an? \\S+ has no fixed length\\z/, qr/^a fraction finer than a nanosecond\\z/ ]", TRUE));
    return (AV *)SvRV(MY_CXT.reasons);
}

static int
tkn_reason_known(pTHX_ SV *reason)
{
    AV *pats = tkn_reason_patterns(aTHX);
    SV *r = sv_2mortal(newSVsv(reason));
    I32 i;
    for (i = 0; i <= av_len(pats); i++) {
        char *s = SvPV_nolen(r);
        if (pregexec(SvRX(*av_fetch(pats, i, 0)), s, SvEND(r), s, 0, r, 1))
            return 1;
    }
    return 0;
}

/* _cannot: the death, or the confession for a reason off the list. */
static void
tkn_cannot(pTHX_ SV *method, SV *text, SV *token, SV *reason)
{
    dMY_CXT;
    if (MY_CXT.quiet)
        return;
    if (!SvOK(reason) || !tkn_reason_known(aTHX_ reason))
        tkn_carp(aTHX_ "Carp::confess", sv_2mortal(newSVpvf("Time::Keeper::Natural: '%" SVf "' is not one of the reasons",
                                                            SVfARG(SvOK(reason) ? reason : &PL_sv_no))));
    tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("Time::Keeper::Natural->%" SVf ": cannot read '%" SVf "' at '%" SVf "': %" SVf,
                                                      SVfARG(method), SVfARG(text), SVfARG(token), SVfARG(reason))));
}

/* lc, as Perl writes it. */
static SV *
tkn_lc(pTHX_ SV *sv)
{
    STRLEN len;
    const U8 *p = (const U8 *)SvPV_const(sv, len), *e = p + len;
    int utf8 = SvUTF8(sv) ? 1 : 0;
    SV *out = sv_2mortal(newSVpvs(""));
    if (utf8)
        SvUTF8_on(out);
    while (p < e) {
        STRLEN cl = utf8 ? UTF8SKIP(p) : 1;
        if (p + cl > e)
            cl = (STRLEN)(e - p);
        if (*p < 0x80) {
            char c = (char)toLOWER(*p);
            sv_catpvn(out, &c, 1);
        }
        else if (utf8)
            tkn_lower_cat(aTHX_ out, p, e);
        else
            sv_catpvn(out, (const char *)p, 1);
        p += cl;
    }
    return out;
}

/* _as_typed: the word of the text, as typed, whose key is the token. */
static SV *
tkn_as_typed(pTHX_ tkn_lexicon *L, SV *text, SV *token)
{
    STRLEN len, tl;
    const char *b, *s, *e;
    int utf8 = SvUTF8(text) ? 1 : 0;
    if (!SvOK(token) || !SvCUR(token))
        return token;
    (void)SvPV_const(token, tl);
    b = SvPV_const(text, len);
    s = b;
    e = b + len;
    while (s < e) {
        const char *t = s;
        STRLEN cl = 1;
        SV *w;
        while (t < e) {
            UV cp = utf8 ? tkn_utf8_cp((const U8 *)t, (const U8 *)e, &cl) : (U8)*t;
            if (utf8 ? tkn_is_space_cp(cp) : isSPACE_A(*t))
                break;
            t += utf8 ? cl : 1;
        }
        if (t > s) {
            w = sv_2mortal(newSVpvn(s, (STRLEN)(t - s)));
            if (utf8)
                SvUTF8_on(w);
            if (sv_eq(tkn_key_sv(aTHX_ L, w), token) || sv_eq(tkn_lc(aTHX_ w), token))
                return w;
        }
        s = t;
        while (s < e) {
            UV cp = utf8 ? tkn_utf8_cp((const U8 *)s, (const U8 *)e, &cl) : (U8)*s;
            if (!(utf8 ? tkn_is_space_cp(cp) : isSPACE_A(*s)))
                break;
            s += utf8 ? cl : 1;
        }
    }
    return token;
}

/* _point: a text read as a time, and its info; else the death. */
static SV *
tkn_point(pTHX_ SV *self, SV *method, SV *text, HV **info_out)
{
    SV *lexsv, *words, *k, *v;
    tkn_lexicon *L;
    HV *info;
    if (!SvOK(text))
        tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("Time::Keeper::Natural->%" SVf ": the text is undefined", SVfARG(method))));
    tkn_lex_words(aTHX_ self, &lexsv, &words);
    L = tkn_lex(aTHX_ lexsv);
    k = tkn_key_sv(aTHX_ L, text);
    if (!SvCUR(k)) {
        tkn_cannot(aTHX_ method, text, sv_2mortal(newSVpvs("")), sv_2mortal(newSVpvs("the text is empty")));
        return NULL;
    }
    info = tkn_info_new(aTHX);
    v = tkn_phrase(aTHX_ self, L, words, text, k, info);
    /* in a calendar, a date written in the Gregorian still reads, and is
       given back in the calendar */
    if (!v && L->calendar) {
        HV *gi = tkn_info_new(aTHX);
        SV *glex, *gw, *g;
        tkn_lex_words_cal(aTHX_ self, NULL, &glex, &gw);
        g = tkn_phrase(aTHX_ self, tkn_lex(aTHX_ glex), gw, text, tkn_key_sv(aTHX_ tkn_lex(aTHX_ glex), text), gi);
        if (g) {
            v = g;
            info = gi;
        }
    }
    if (v) {
        SV *zn = tkn_hsv(aTHX_ info, "zone_named");
        if (!zn || !SvTRUE(zn))
            tkn_info_assume(aTHX_ info, "zone");
        *info_out = info;
        return tkn_in_cal(aTHX_ self, v);
    }
    {
        dMY_CXT;
        if (MY_CXT.quiet)
            return NULL;
    }
    {
        HV *scratch = (HV *)sv_2mortal((SV *)newHV());
        SV *d = tkn_duration_value(aTHX_ L, k, text, scratch);
        if (d && SvTRUE(d)) {
            (void)hv_stores(info, "reason", newSVpvs("a duration, not a time; parse_duration reads it"));
            (void)hv_stores(info, "token", newSV(0));
        }
    }
    if (!tkn_hsv(aTHX_ info, "reason") && !tkn_hsv(aTHX_ info, "token")) {
        AV *tok = (AV *)sv_2mortal((SV *)newAV());
        STRLEN kl, a = 0, q;
        const char *kb = SvPV_const(k, kl);
        I32 i, nt;
        for (q = 0; q <= kl; q++)
            if (q == kl || kb[q] == ' ') {
                SV *t = newSVpvn(kb + a, q - a);
                SvUTF8_on(t);
                av_push(tok, t);
                a = q + 1;
            }
        while (av_len(tok) >= 0 && !SvCUR(*av_fetch(tok, av_len(tok), 0)))
            SvREFCNT_dec(av_pop(tok));
        nt = av_len(tok) + 1;
        for (i = nt - 1; i >= 1; i--) {
            SV *head = sv_2mortal(newSVpvs(""));
            AV *g = (AV *)sv_2mortal((SV *)newAV());
            I32 j;
            SvUTF8_on(head);
            for (j = 0; j < i; j++) {
                if (j)
                    sv_catpvs(head, " ");
                sv_catsv(head, *av_fetch(tok, j, 0));
            }
            /* 0.01 asked "$self->_group(...)" in boolean context, which
               is its last list, the unit readings. */
            if (av_len(tkn_whole(aTHX_ L, head)) < 0) {
                tkn_unit_read(aTHX_ L, head, g);
                if (av_len(g) < 0)
                    continue;
            }
            (void)hv_stores(info, "token", newSVsv(*av_fetch(tok, i, 0)));
            break;
        }
    }
    if (!tkn_hsv(aTHX_ info, "reason") && !tkn_words_ok(words) && strNE(SvPV_nolen(L->code), "en")) {
        SV *en = tkn_words_for(aTHX_ sv_2mortal(newSVpvs("Time::Keeper::Natural::Words")), sv_2mortal(newSVpvs("en")));
        if (tkn_words_ok(en)) {
            static const char *const keys[4] = { "start_of", "end_of", "at", "on" };
            SV *t = tkn_trim(aTHX_ text), *rest, *raw;
            int x;
            for (x = 0; x < 4; x++) {
                if (!tkn_w_frame(aTHX_ en, t, keys[x], &rest, &raw) || !SvCUR(rest))
                    continue;
                (void)hv_stores(info, "reason", newSVpvf("coverage of %" SVf " is data; '%" SVf "' needs its words",
                                                         SVfARG(L->code), SVfARG(raw)));
                (void)hv_stores(info, "token", newSVsv(raw));
                break;
            }
        }
    }
    {
        SV *tok = tkn_hsv(aTHX_ info, "token"), *reason = tkn_hsv(aTHX_ info, "reason"), *tie = tkn_hsv(aTHX_ info, "tie");
        int typed_tok = 0;
        if (reason && tie) {
            /* A tie's phrase is quoted as typed, not as keyed, in the token
               and the reason; it may be the whole text. */
            SV *whole = tkn_trim(aTHX_ text);
            SV *typed = sv_eq(tkn_key_sv(aTHX_ L, whole), tie) ? whole : tkn_as_typed(aTHX_ L, text, tie);
            if (tok && sv_eq(tok, tie)) {
                tok = typed;
                typed_tok = 1;
            }
            STRLEN kl, rl;
            const char *kb = SvPV_const(tie, kl), *rb = SvPV_const(reason, rl);
            if (rl > kl + 1 && rb[0] == '\'' && memEQ(rb + 1, kb, kl) && rb[kl + 1] == '\'') {
                SV *r2 = sv_2mortal(newSVpvs("'"));
                SvUTF8_on(r2);
                sv_catsv(r2, typed);
                sv_catpvn(r2, rb + kl + 1, rl - kl - 1);
                reason = r2;
            }
        }
        tkn_cannot(aTHX_ method, text, tok ? (typed_tok ? tok : tkn_as_typed(aTHX_ L, text, tok)) : tkn_first_token(aTHX_ text),
                   reason ? reason : sv_2mortal(newSVpvf("no such word in %" SVf, SVfARG(L->code))));
    }
    return NULL;
}

/* Match->_new: the checks, then the locked hash. */
static SV *
tkn_match_new(pTHX_ SV *klass, HV *a)
{
    SV *kind = tkn_hsv(aTHX_ a, "kind"), *precision = tkn_hsv(aTHX_ a, "precision"), *text, **ap;
    const char *ks = kind ? SvPV_nolen(kind) : "";
    AV *assumed = newAV();
    HV *self, *seen = (HV *)sv_2mortal((SV *)newHV());
    SV *obj;
    STRLEN tl, lead = 0, trail = 0, chars;
    const char *tb;
    int i, ok = 0;
    sv_2mortal((SV *)assumed);
    if (!(strEQ(ks, "point") || strEQ(ks, "date") || strEQ(ks, "duration") || strEQ(ks, "interval")))
        tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("Time::Keeper::Natural::Match: kind '%s' is not one", ks)));
    if (precision)
        for (i = 0; i < 12; i++)
            if (strEQ(SvPV_nolen(precision), tkn_precisions[i]))
                ok = 1;
    if (!ok)
        tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("Time::Keeper::Natural::Match: precision '%" SVf "' is not one",
                                                          SVfARG(precision ? precision : sv_2mortal(newSVpvs("undef"))))));
    ap = hv_fetchs(a, "assumed", 0);
    if (ap && SvROK(*ap) && SvTYPE(SvRV(*ap)) == SVt_PVAV) {
        AV *in = (AV *)SvRV(*ap);
        I32 j;
        for (j = 0; j <= av_len(in); j++) {
            SV **e = av_fetch(in, j, 0);
            SV *s = e ? *e : &PL_sv_undef;
            const char *ss = SvOK(s) ? SvPV_nolen(s) : "";
            int known = 0;
            for (i = 0; i < TKN_N_ASSUMPTIONS; i++)
                if (strEQ(ss, tkn_assumptions[i]))
                    known = 1;
            if (!known)
                tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("Time::Keeper::Natural::Match: '%s' is not an assumption", ss)));
            if (!hv_exists(seen, ss, (I32)strlen(ss))) {
                (void)hv_store(seen, ss, (I32)strlen(ss), &PL_sv_yes, 0);
                av_push(assumed, newSVpv(ss, 0));
            }
        }
    }
    text = tkn_hsv(aTHX_ a, "text");
    if (!text)
        text = sv_2mortal(newSVpvs(""));
    tb = SvPV_const(text, tl);
    {
        int utf8 = SvUTF8(text) ? 1 : 0;
        const char *s = tb, *e = tb + tl;
        STRLEN cl = 1;
        while (s < e) {
            UV cp = utf8 ? tkn_utf8_cp((const U8 *)s, (const U8 *)e, &cl) : (U8)*s;
            if (!(utf8 ? tkn_is_space_cp(cp) : isSPACE_A(*s)))
                break;
            s += utf8 ? cl : 1;
            lead++;
        }
        while (e > tb) {
            const char *q = e - 1;
            UV cp;
            if (utf8)
                while (q > tb && ((U8)*q & 0xC0) == 0x80)
                    q--;
            cp = utf8 ? tkn_utf8_cp((const U8 *)q, (const U8 *)tb + tl, &cl) : (U8)*q;
            if (!(utf8 ? tkn_is_space_cp(cp) : isSPACE_A(*q)))
                break;
            e = q;
            trail++;
        }
        chars = utf8 ? tkn_char_len(tb, tl) : tl;
    }
    self = newHV();
    obj = sv_2mortal(newRV_noinc((SV *)self));
    {
        SV *v = tkn_hsv(aTHX_ a, "value"), *loc = tkn_hsv(aTHX_ a, "locale"), *anc = tkn_hsv(aTHX_ a, "anchor");
        (void)hv_stores(self, "value", v ? newSVsv(v) : newSV(0));
        (void)hv_stores(self, "kind", newSVsv(kind));
        (void)hv_stores(self, "precision", newSVsv(precision));
        (void)hv_stores(self, "assumed", newRV_inc((SV *)assumed));
        (void)hv_stores(self, "text", newSVsv(text));
        /* find gives where a mention is in a longer text */
        SV *gs = tkn_hsv(aTHX_ a, "start"), *ge = tkn_hsv(aTHX_ a, "end");
        (void)hv_stores(self, "start", gs ? newSViv(SvIV(gs)) : newSViv((IV)lead));
        (void)hv_stores(self, "end", ge ? newSViv(SvIV(ge)) : newSViv((IV)(lead == chars ? 0 : chars - trail)));
        (void)hv_stores(self, "locale", loc ? newSVsv(loc) : newSV(0));
        (void)hv_stores(self, "anchor", anc ? newSVsv(anc) : newSV(0));
        if (strEQ(ks, "interval")) {
            SV *to = tkn_hsv(aTHX_ a, "to");
            (void)hv_stores(self, "to", to ? newSVsv(to) : newSV(0));
        }
    }
    sv_bless(obj, gv_stashsv(klass, GV_ADD));
    {
        HE *he;
        hv_iterinit(self);
        while ((he = hv_iternext(self)))
            SvREADONLY_on(HeVAL(he));
        SvREADONLY_on((SV *)self);
        SvREADONLY_on((SV *)assumed);
    }
    return obj;
}

/* $obj->method(args) under eval with $@ kept as it was; NULL on a death. */
static AV *
tkn_try_call(pTHX_ SV *inv, const char *method, SV **args, int n, I32 ctx)
{
    dSP;
    int i, c;
    AV *out = (AV *)sv_2mortal((SV *)newAV());
    int died;
    ENTER;
    SAVETMPS;
    save_scalar(PL_errgv);
    PUSHMARK(SP);
    XPUSHs(inv);
    for (i = 0; i < n; i++)
        XPUSHs(args[i]);
    PUTBACK;
    c = call_method(method, ctx | G_EVAL);
    SPAGAIN;
    died = SvTRUE(ERRSV);
    for (i = 0; i < c; i++)
        av_store(out, i, newSVsv(*(SP - c + 1 + i)));
    SP -= c;
    PUTBACK;
    FREETMPS;
    LEAVE;
    return died ? NULL : out;
}

/* _match: what the method would read, as a Match; undef for a death. */
static SV *
tkn_match(pTHX_ SV *self, SV *method, const char *kind, SV *text)
{
    SV *args[2], *v;
    AV *r;
    HV *info, *a;
    if (!SvOK(text))
        return NULL;
    args[0] = method;
    args[1] = text;
    r = tkn_try_call(aTHX_ self, strEQ(kind, "duration") ? "_duration" : strEQ(kind, "interval") ? "_interval" : "_point", args, 2, G_ARRAY);
    if (!r || av_len(r) < (strEQ(kind, "interval") ? 2 : 1))
        return NULL;
    v = *av_fetch(r, 0, 0);
    info = tkn_rv_hv(aTHX_ *av_fetch(r, av_len(r), 0), "info");
    if (strEQ(kind, "date")) {
        if (!get_cv("Time::Keeper::Date::new", 0))
            load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("Time::Keeper::Date"), NULL);
        v = tkn_method(aTHX_ v, "to_date", NULL, 0);
    }
    a = (HV *)sv_2mortal((SV *)newHV());
    (void)hv_stores(a, "value", newSVsv(v));
    (void)hv_stores(a, "kind", newSVpv(kind, 0));
    if (strEQ(kind, "interval"))
        (void)hv_stores(a, "to", newSVsv(*av_fetch(r, 1, 0)));
    {
        SV *p = tkn_hsv(aTHX_ info, "precision"), **as = hv_fetchs(info, "assumed", 0);
        if (p)
            (void)hv_stores(a, "precision", newSVsv(p));
        if (as)
            (void)hv_stores(a, "assumed", newSVsv(*as));
    }
    (void)hv_stores(a, "text", newSVsv(text));
    (void)hv_stores(a, "locale", newSVsv(tkn_locale_of(aTHX_ self)));
    (void)hv_stores(a, "anchor", newSVsv(tkn_now(aTHX_ self)));
    return tkn_match_new(aTHX_ sv_2mortal(newSVpvs("Time::Keeper::Natural::Match")), a);
}

#endif
