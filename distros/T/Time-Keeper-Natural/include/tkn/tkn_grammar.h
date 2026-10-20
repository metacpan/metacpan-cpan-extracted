#ifndef TKN_GRAMMAR_H
#define TKN_GRAMMAR_H

/* The word grammar: a whole CLDR phrase first, then the word table's
 * edges ("end of", "start of"), "at" before a time or between a day and a
 * time, "on" before a day, "the third Friday of", and the skip words
 * (articles) a part may begin with; then the plain readers. The table's
 * phrases match through Phase 05's matchers. An info is 0.01's hash: a
 * reader that fails with a reason replaces the caller's info with its own. */

static HV *
tkn_info_new(pTHX)
{
    HV *h = (HV *)sv_2mortal((SV *)newHV());
    (void)hv_stores(h, "assumed", newRV_noinc((SV *)newAV()));
    return h;
}

/* %$info = %$from. */
static void
tkn_info_set(pTHX_ HV *info, HV *from)
{
    if (info == from)
        return;
    SvREFCNT_inc_simple_void((SV *)from);
    hv_clear(info);
    tkn_merge(aTHX_ info, from);
    SvREFCNT_dec((SV *)from);
}

static void
tkn_info_reset(pTHX_ HV *info)
{
    hv_clear(info);
    (void)hv_stores(info, "assumed", newRV_noinc((SV *)newAV()));
}

static AV *
tkn_assumed(pTHX_ HV *info)
{
    SV **a = hv_fetchs(info, "assumed", 0);
    if (a && SvROK(*a) && SvTYPE(SvRV(*a)) == SVt_PVAV)
        return (AV *)SvRV(*a);
    {
        AV *av = newAV();
        (void)hv_stores(info, "assumed", newRV_noinc((SV *)av));
        return av;
    }
}

/* @{ $info->{assumed} } without period start and time. */
static void
tkn_assumed_drop(pTHX_ AV *from, AV *into, int drop_period_start)
{
    I32 i;
    for (i = 0; i <= av_len(from); i++) {
        const char *a = SvPV_nolen(*av_fetch(from, i, 0));
        if (strEQ(a, "time") || (drop_period_start && strEQ(a, "period start")))
            continue;
        av_push(into, newSVsv(*av_fetch(from, i, 0)));
    }
}

static int
tkn_has_reason(pTHX_ HV *info)
{
    return tkn_hsv(aTHX_ info, "reason") != NULL;
}

static int
tkn_words_ok(SV *words)
{
    return words && SvROK(words) && SvTYPE(SvRV(words)) == SVt_PVHV;
}

/* Words->frame and ->split_on, in C. */
static int
tkn_w_frame(pTHX_ SV *words, SV *text, const char *key, SV **rest, SV **raw)
{
    AV *list = tkn_phrases_of(aTHX_ words, sv_2mortal(newSVpv(key, 0)));
    I32 i, n = list ? av_len(list) + 1 : 0;
    tkn_fold F;
    if (!n)
        return 0;
    tkn_fold_text(aTHX_ text, &F);
    for (i = 0; i < n; i++) {
        AV *ph = (AV *)SvRV(*av_fetch(list, i, 0));
        SV *got = tkn_frame_match(aTHX_ &F, *av_fetch(ph, 2, 0), SvIV(*av_fetch(ph, 3, 0)), *av_fetch(ph, 4, 0));
        if (got) {
            *rest = got;
            *raw = *av_fetch(ph, 1, 0);
            return 1;
        }
    }
    return 0;
}

static int
tkn_w_split(pTHX_ SV *words, SV *text, const char *key, SV **left, SV **right, SV **raw)
{
    AV *list = tkn_phrases_of(aTHX_ words, sv_2mortal(newSVpv(key, 0)));
    I32 i, n = list ? av_len(list) + 1 : 0;
    tkn_fold F;
    if (!n)
        return 0;
    tkn_fold_text(aTHX_ text, &F);
    for (i = 0; i < n; i++) {
        AV *ph = (AV *)SvRV(*av_fetch(list, i, 0));
        SV *toks = *av_fetch(ph, 5, 0);
        if (!SvOK(toks))
            continue;
        if (tkn_split_match(aTHX_ &F, toks, SvIV(*av_fetch(ph, 6, 0)), left, right)) {
            *raw = *av_fetch(ph, 1, 0);
            return 1;
        }
    }
    return 0;
}

static int
tkn_w_count(pTHX_ SV *words, const char *key)
{
    AV *list = tkn_phrases_of(aTHX_ words, sv_2mortal(newSVpv(key, 0)));
    return list ? av_len(list) + 1 : 0;
}

static int
tkn_w_is(pTHX_ SV *words, SV *k, const char *key)
{
    AV *list = tkn_phrases_of(aTHX_ words, sv_2mortal(newSVpv(key, 0)));
    I32 i;
    if (!list)
        return 0;
    for (i = 0; i <= av_len(list); i++)
        if (sv_eq(*av_fetch((AV *)SvRV(*av_fetch(list, i, 0)), 0, 0), k))
            return 1;
    return 0;
}

static AV *
tkn_w_articled(pTHX_ SV *words, SV *text)
{
    AV *out = (AV *)sv_2mortal((SV *)newAV());
    AV *list = tkn_phrases_of(aTHX_ words, sv_2mortal(newSVpvs("skip")));
    SV **sp = hv_fetchs((HV *)SvRV(words), "spaceless", 0);
    int spaceless = sp && SvTRUE(*sp);
    I32 i;
    av_push(out, newSVsv(text));
    for (i = 0; list && i <= av_len(list); i++) {
        SV *a = *av_fetch((AV *)SvRV(*av_fetch(list, i, 0)), 1, 0);
        STRLEN al;
        const char *ab = SvPV_const(a, al);
        SV *s = newSVsv(a);
        if (!spaceless && !tkn_ends_apos(ab, al))
            sv_catpvs(s, " ");
        sv_catsv(s, text);
        av_push(out, s);
    }
    return out;
}

/* _after: what follows one of a key's phrases, its key, and the phrase. */
static int
tkn_after(pTHX_ SV *words, tkn_lexicon *L, SV *text, const char *key, SV **rest, SV **rk, SV **raw)
{
    if (!tkn_words_ok(words))
        return 0;
    if (!tkn_w_frame(aTHX_ words, tkn_trim(aTHX_ text), key, rest, raw))
        return 0;
    *rk = tkn_key_sv(aTHX_ L, *rest);
    return 1;
}

/* _skip: the skip words (articles) dropped from the front while something
 * is left. */
static void
tkn_skip(pTHX_ SV *words, tkn_lexicon *L, SV **text, SV **k)
{
    SV *t, *kk, *raw;
    while (tkn_after(aTHX_ words, L, *text, "skip", &t, &kk, &raw)) {
        if (!SvCUR(kk))
            break;
        *text = t;
        *k = kk;
    }
}

/* _nothing_after: a phrase with nothing after it. */
static SV *
tkn_nothing_after(pTHX_ HV *info, SV *raw)
{
    STRLEN len;
    const char *b = tkn_utf8_bytes(aTHX_ raw, &len), *o = NULL, *q, *s, *e;
    SV *word;
    for (q = b; q + 3 <= b + len; q++)
        if (memEQ(q, "{0}", 3)) {
            o = q;
            break;
        }
    if (!o)
        word = sv_2mortal(newSVpvn(b, len));
    else {
        s = o;
        while (s > b) {
            const char *p = s - 1;
            STRLEN cl;
            while (p > b && ((U8)*p & 0xC0) == 0x80)
                p--;
            if (!tkn_is_space_cp(tkn_utf8_cp((const U8 *)p, (const U8 *)b + len, &cl)))
                break;
            s = p;
        }
        e = o + 3;
        while (e < b + len) {
            STRLEN cl;
            if (!tkn_is_space_cp(tkn_utf8_cp((const U8 *)e, (const U8 *)b + len, &cl)))
                break;
            e += cl;
        }
        word = sv_2mortal(newSVpvn(b, (STRLEN)(s - b)));
        sv_catpvn(word, e, (STRLEN)(b + len - e));
    }
    SvUTF8_on(word);
    (void)hv_stores(info, "reason", newSVpvf("nothing left after '%" SVf "'", SVfARG(word)));
    (void)hv_stores(info, "token", newSVsv(word));
    return NULL;
}

/* The first meaning of a fixed lookup that has a key, as a hash. */
static HV *
tkn_fixed_with(pTHX_ tkn_lexicon *L, SV *s, const char *field)
{
    AV *r = (AV *)sv_2mortal((SV *)newAV());
    I32 i;
    tkn_lookup_k(aTHX_ L, TKN_T_FIXED, -1, tkn_key_sv(aTHX_ L, s), r);
    for (i = 0; i <= av_len(r); i++) {
        HV *m = (HV *)SvRV(*av_fetch(r, i, 0));
        if (hv_exists(m, field, (I32)strlen(field)))
            return m;
    }
    return NULL;
}

static SV *tkn_phrase(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *text, SV *k, HV *info);

/* _weekday_name: a bare weekday, the coming one (or the past one). */
static SV *
tkn_weekday_name(pTHX_ SV *self, tkn_lexicon *L, SV *k, HV *info)
{
    HV *m = tkn_fixed_with(aTHX_ L, k, "weekday");
    SV *anchor, *prefer, *v;
    int past;
    if (!m)
        return NULL;
    anchor = tkn_anchor(aTHX_ self);
    prefer = tkn_self_opt(aTHX_ self, "prefer");
    past = prefer && strEQ(SvPV_nolen(prefer), "past");
    v = tkn_adjust_dow_or(aTHX_ anchor, (int)SvIV(tkn_hsv(aTHX_ m, "weekday")), past ? -1 : 1, 1);
    (void)hv_stores(info, "precision", newSVpvs("day"));
    tkn_info_assume(aTHX_ info, past ? "weekday last" : "weekday next");
    tkn_info_assume(aTHX_ info, "time");
    return tkn_truncate(aTHX_ v, TIME_KEEPER_UNIT_DAY);
}

/* The readings of a key that are whole relative phrases. */
static AV *
tkn_whole(pTHX_ tkn_lexicon *L, SV *k)
{
    AV *r = (AV *)sv_2mortal((SV *)newAV()), *out = (AV *)sv_2mortal((SV *)newAV());
    I32 i;
    tkn_lookup_k(aTHX_ L, TKN_T_FIXED, TKN_T_COUNTED, k, r);
    for (i = 0; i <= av_len(r); i++)
        if (hv_exists((HV *)SvRV(*av_fetch(r, i, 0)), "field", 5))
            av_push(out, newSVsv(*av_fetch(r, i, 0)));
    return out;
}

/* _day: a day a time can go on, or that an edge or an ordinal is of. */
static SV *
tkn_day(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *text, SV *k, HV *info)
{
    SV *ct[2], *ck[2];
    int nc = 1, c;
    ct[0] = text;
    ck[0] = k;
    if (tkn_words_ok(words)) {
        SV *t, *kk, *raw, *st, *sk;
        if (tkn_after(aTHX_ words, L, text, "on", &t, &kk, &raw)) {
            ct[0] = t;
            ck[0] = kk;
        }
        st = ct[0];
        sk = ck[0];
        tkn_skip(aTHX_ words, L, &st, &sk);
        if (!sv_eq(sk, ck[0])) {
            ct[1] = st;
            ck[1] = sk;
            nc = 2;
        }
    }
    for (c = 0; c < nc; c++) {
        SV *v;
        if (!SvCUR(ck[c]))
            continue;
        v = tkn_relative(aTHX_ self, L, ck[c], info, NULL);
        if (v || tkn_has_reason(aTHX_ info))
            return v;
        v = tkn_weekday_name(aTHX_ self, L, ck[c], info);
        if (v)
            return v;
        (void)hv_stores(info, "absolute", newSViv(1));
        v = tkn_absolute(aTHX_ self, L, ct[c], info, 1);
        if (v || tkn_has_reason(aTHX_ info))
            return v;
        (void)hv_delete(info, "absolute", 8, G_DISCARD);
    }
    return NULL;
}

/* _edge: the start or the end of the period a text names. */
static SV *
tkn_edge(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *text, SV *k, int end, SV *raw, HV *info)
{
    SV *anchor, *v = NULL;
    const char *p = NULL;
    HV *failed = NULL;
    AV *cands;
    I32 i;
    if (!SvCUR(k))
        return tkn_nothing_after(aTHX_ info, raw);
    anchor = tkn_anchor(aTHX_ self);
    cands = tkn_w_articled(aTHX_ words, text);
    for (i = 0; i <= av_len(cands); i++) {
        SV *cand = *av_fetch(cands, i, 0), *st = cand, *sk = tkn_key_sv(aTHX_ L, cand);
        HV *ci = tkn_info_new(aTHX);
        AV *fr = (AV *)sv_2mortal((SV *)newAV());
        HV *fm = NULL;
        tkn_skip(aTHX_ words, L, &st, &sk);
        tkn_lookup_k(aTHX_ L, TKN_T_FIELD_NAMES, -1, sk, fr);
        if (av_len(fr) >= 0)
            fm = (HV *)SvRV(*av_fetch(fr, 0, 0));
        if (fm && tkn_hstr(aTHX_ fm, "field")) {
            HV *one = (HV *)sv_2mortal((SV *)newHV());
            p = SvPV_nolen(sv_2mortal(newSVsv(tkn_hsv(aTHX_ fm, "field"))));
            (void)hv_stores(one, "field", newSVpv(p, 0));
            (void)hv_stores(one, "n", newSViv(0));
            (void)hv_stores(one, "width", newSVpvs("long"));
            v = tkn_one(aTHX_ anchor, one, ci);
        }
        else {
            v = tkn_day(aTHX_ self, L, words, cand, tkn_key_sv(aTHX_ L, cand), ci);
            if (v) {
                SV *pr = tkn_hsv(aTHX_ ci, "precision");
                p = pr ? SvPV_nolen(sv_2mortal(newSVsv(pr))) : NULL;
            }
        }
        if (v) {
            tkn_info_set(aTHX_ info, ci);
            break;
        }
        if (!failed && tkn_has_reason(aTHX_ ci))
            failed = ci;
    }
    if (!v) {
        if (failed)
            tkn_info_set(aTHX_ info, failed);
        return NULL;
    }
    if (tkn_rank(p) > tkn_rank("day")) {
        (void)hv_stores(info, "reason", newSVpvs("a moment, not a period"));
        (void)hv_stores(info, "token", newSVsv(tkn_first_token(aTHX_ text)));
        return NULL;
    }
    (void)hv_stores(info, "precision", newSVpv(p, 0));
    {
        AV *a = tkn_assumed(aTHX_ info), *keep = (AV *)sv_2mortal((SV *)newAV());
        I32 x;
        tkn_assumed_drop(aTHX_ a, keep, 1);
        av_clear(a);
        for (x = 0; x <= av_len(keep); x++)
            av_push(a, newSVsv(*av_fetch(keep, x, 0)));
    }
    {
        int unit = tkn_rank(p);
        time_keeper_point in, out;
        tkn_pt(aTHX_ v, &in);
        if (unit >= 0 && (end ? (TKN_TK->end_of)(aTHX_ &in, unit, TIME_KEEPER_WEEK_LOCALE, &out, NULL, 0)
                              : (TKN_TK->truncate)(aTHX_ &in, unit, TIME_KEEPER_WEEK_LOCALE, &out, NULL, 0)) == TIME_KEEPER_OK)
            return tkn_pt_sv(aTHX_ &out);
        {
            SV *args[4];
            args[0] = sv_2mortal(newSVpvs("to"));
            args[1] = sv_2mortal(newSVpv(p, 0));
            args[2] = sv_2mortal(newSVpvs("week_start"));
            args[3] = sv_2mortal(newSVpvs("locale"));
            return tkn_method(aTHX_ v, end ? "end_of" : "truncate", args, 4);
        }
    }
}

/* _nth: "the third Friday of next month", "the last Friday of October". */
static SV *
tkn_nth(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *text, HV *info)
{
    SV *left, *right, *of, *lk, *tk;
    AV *tok = (AV *)sv_2mortal((SV *)newAV());
    I32 cut, nt;
    if (!tkn_w_split(aTHX_ words, tkn_trim(aTHX_ text), "of", &left, &right, &of))
        return NULL;
    lk = tkn_key_sv(aTHX_ L, left);
    tkn_skip(aTHX_ words, L, &left, &lk);
    tk = tkn_key_sv(aTHX_ L, left);
    {
        STRLEN kl, a = 0, q;
        const char *kb = SvPV_const(tk, kl);
        for (q = 0; q <= kl; q++)
            if (q == kl || kb[q] == ' ') {
                SV *t = newSVpvn(kb + a, q - a);
                SvUTF8_on(t);
                av_push(tok, t);
                a = q + 1;
            }
        while (av_len(tok) >= 0 && !SvCUR(*av_fetch(tok, av_len(tok), 0)))
            SvREFCNT_dec(av_pop(tok));
    }
    nt = av_len(tok) + 1;
    for (cut = 1; cut < nt; cut++) {
        SV *first = sv_2mortal(newSVpvs("")), *rest = sv_2mortal(newSVpvs("")), *nsv, *period = NULL;
        HV *wd, *pi = NULL;
        IV n;
        I32 j;
        AV *cands;
        SvUTF8_on(first);
        SvUTF8_on(rest);
        for (j = 0; j < cut; j++) {
            if (j)
                sv_catpvs(first, " ");
            sv_catsv(first, *av_fetch(tok, j, 0));
        }
        for (j = cut; j < nt; j++) {
            if (j > cut)
                sv_catpvs(rest, " ");
            sv_catsv(rest, *av_fetch(tok, j, 0));
        }
        if (tkn_w_is(aTHX_ words, first, "last"))
            n = -1;
        else {
            SV *v;
            if (!L->ordinals_read) {
                L->ordinals_read = 1;
                tkn_number_words(aTHX_ L, TKN_T_ORDINALS, "ordinals");
            }
            v = tkn_value_of(aTHX_ L, TKN_T_ORDINALS, tkn_key_sv(aTHX_ L, first));
            if (!v)
                continue;
            n = SvIV(v);
        }
        if (!(wd = tkn_fixed_with(aTHX_ L, rest, "weekday")))
            continue;
        cands = tkn_w_articled(aTHX_ words, right);
        for (j = 0; j <= av_len(cands); j++) {
            SV *cand = *av_fetch(cands, j, 0);
            pi = tkn_info_new(aTHX);
            period = tkn_day(aTHX_ self, L, words, cand, tkn_key_sv(aTHX_ L, cand), pi);
            if (period || tkn_has_reason(aTHX_ pi))
                break;
        }
        if (!period) {
            if (pi && tkn_has_reason(aTHX_ pi))
                tkn_merge(aTHX_ info, pi);
            return NULL;
        }
        {
            SV *pp = tkn_hsv(aTHX_ pi, "precision");
            const char *p = pp && SvTRUE(pp) ? SvPV_nolen(pp) : "day";
            time_keeper_point in, mo, out;
            int dow = (int)SvIV(tkn_hsv(aTHX_ wd, "weekday"));
            SV *month;
            if (strNE(p, "month")) {
                (void)hv_stores(info, "reason", newSVpvf("an ordinal weekday is counted in a month, not a %s", p));
                (void)hv_stores(info, "token", newSVsv(of));
                return NULL;
            }
            if (n > 5) {
                (void)hv_stores(info, "reason", newSVpvf("no month has a %" SVf " %" SVf, SVfARG(first), SVfARG(*av_fetch(tok, cut, 0))));
                (void)hv_stores(info, "token", newSVsv(first));
                return NULL;
            }
            month = tkn_truncate(aTHX_ period, TIME_KEEPER_UNIT_MONTH);
            tkn_pt(aTHX_ month, &mo);
            in = mo;
            if (n == 0 || (TKN_TK->nth_in_month)(aTHX_ &in, dow, n < 0 ? -1 : (int)n, TIME_KEEPER_GAP_FAIL,
                                                 TIME_KEEPER_OVERLAP_EARLIER, &out, NULL, 0) != TIME_KEEPER_OK) {
                time_keeper_civil mc;
                tkn_civil_of(aTHX_ month, &mc);
                (void)hv_stores(info, "reason", newSVpvf("%04d-%02d has no %" SVf " %" SVf, (int)mc.year, mc.month,
                                                         SVfARG(first), SVfARG(*av_fetch(tok, cut, 0))));
                (void)hv_stores(info, "token", newSVsv(first));
                return NULL;
            }
            (void)hv_stores(info, "precision", newSVpvs("day"));
            {
                AV *a = tkn_assumed(aTHX_ info);
                tkn_assumed_drop(aTHX_ tkn_assumed(aTHX_ pi), a, 1);
                av_push(a, newSVpvs("time"));
            }
            nsv = tkn_pt_sv(aTHX_ &out);
            return tkn_truncate(aTHX_ nsv, TIME_KEEPER_UNIT_DAY);
        }
    }
    return NULL;
}

/* _plain: the readers that need no word table. */
static SV *
tkn_plain(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *text, SV *k, HV *info)
{
    SV *v = tkn_relative(aTHX_ self, L, k, info, NULL);
    if (v || tkn_has_reason(aTHX_ info))
        return v;
    if ((v = tkn_weekday_name(aTHX_ self, L, k, info)))
        return v;
    v = tkn_absolute(aTHX_ self, L, text, info, 0);
    if (v || tkn_has_reason(aTHX_ info))
        return v;
    return tkn_combined(aTHX_ self, L, NULL, words, text, info);
}

/* _worded: the readers that need the word table. */
static SV *
tkn_worded(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *text, SV *k, HV *info)
{
    static const char *const edges[2] = { "start_of", "end_of" };
    SV *t, *kk, *raw, *v;
    int e;
    PERL_UNUSED_ARG(k);
    for (e = 0; e < 2; e++) {
        HV *ei;
        if (!tkn_after(aTHX_ words, L, text, edges[e], &t, &kk, &raw))
            continue;
        if (!SvCUR(kk))
            return tkn_nothing_after(aTHX_ info, raw);
        ei = tkn_info_new(aTHX);
        v = tkn_edge(aTHX_ self, L, words, t, kk, e == 1, raw, ei);
        if (v || tkn_has_reason(aTHX_ ei)) {
            tkn_info_set(aTHX_ info, ei);
            return v;
        }
    }
    if (tkn_after(aTHX_ words, L, text, "at", &t, &kk, &raw)) {
        SV *anchor;
        HV *ti, *ci;
        tkn_tod tod;
        int shape;
        if (!SvCUR(kk))
            return tkn_nothing_after(aTHX_ info, raw);
        anchor = tkn_anchor(aTHX_ self);
        ti = tkn_info_new(aTHX);
        if (tkn_time_of_day(aTHX_ self, L, anchor, tkn_trim(aTHX_ tkn_ascii_digits(aTHX_ t, L->has_digits ? L->digits : NULL)),
                            ti, &tod, &shape)) {
            tkn_info_set(aTHX_ info, ti);
            tkn_info_assume(aTHX_ info, "date");
            return tkn_at_time(aTHX_ anchor, &tod);
        }
        if (tkn_has_reason(aTHX_ ti)) {
            tkn_info_set(aTHX_ info, ti);
            return NULL;
        }
        ci = tkn_info_new(aTHX);
        v = tkn_combined(aTHX_ self, L, NULL, words, t, ci);
        if (v || tkn_has_reason(aTHX_ ci)) {
            tkn_info_set(aTHX_ info, ci);
            return v;
        }
    }
    if (tkn_after(aTHX_ words, L, text, "on", &t, &kk, &raw)) {
        HV *di;
        if (!SvCUR(kk))
            return tkn_nothing_after(aTHX_ info, raw);
        di = tkn_info_new(aTHX);
        v = tkn_day(aTHX_ self, L, words, t, kk, di);
        if (!v && !tkn_has_reason(aTHX_ di))
            v = tkn_combined(aTHX_ self, L, NULL, words, t, di);
        if (v || tkn_has_reason(aTHX_ di)) {
            tkn_info_set(aTHX_ info, di);
            return v;
        }
    }
    {
        SV *left, *right, *sraw;
        if (tkn_w_split(aTHX_ words, tkn_trim(aTHX_ text), "at", &left, &right, &sraw)) {
            HV *ti = tkn_info_new(aTHX);
            tkn_tod tod;
            int shape;
            if (tkn_time_of_day(aTHX_ self, L, tkn_anchor(aTHX_ self),
                                tkn_trim(aTHX_ tkn_ascii_digits(aTHX_ right, L->has_digits ? L->digits : NULL)), ti, &tod, &shape)) {
                HV *di = tkn_info_new(aTHX);
                SV *day = tkn_day_part(aTHX_ self, L, NULL, words, left, di);
                if (day) {
                    SV *tp = tkn_hsv(aTHX_ ti, "precision");
                    AV *assumed = newAV();
                    I32 x;
                    AV *ta = tkn_assumed(aTHX_ ti);
                    tkn_assumed_drop(aTHX_ tkn_assumed(aTHX_ di), assumed, 0);
                    for (x = 0; x <= av_len(ta); x++)
                        av_push(assumed, newSVsv(*av_fetch(ta, x, 0)));
                    hv_clear(info);
                    (void)hv_stores(info, "precision", tp ? newSVsv(tp) : newSV(0));
                    (void)hv_stores(info, "assumed", newRV_noinc((SV *)assumed));
                    return tkn_at_time(aTHX_ day, &tod);
                }
                if (tkn_has_reason(aTHX_ di)) {
                    tkn_info_set(aTHX_ info, di);
                    return NULL;
                }
            }
            else if (tkn_hsv(aTHX_ ti, "bare") && SvTRUE(tkn_hsv(aTHX_ ti, "bare")) && tkn_has_reason(aTHX_ ti)) {
                tkn_info_set(aTHX_ info, ti);
                return NULL;
            }
        }
    }
    if (tkn_w_count(aTHX_ words, "of")) {
        HV *ni = tkn_info_new(aTHX);
        v = tkn_nth(aTHX_ self, L, words, text, ni);
        if (v || tkn_has_reason(aTHX_ ni)) {
            tkn_info_set(aTHX_ info, ni);
            return v;
        }
    }
    return NULL;
}

/* _phrase: a text read as a time, as 0.01 read it. */
static SV *
tkn_phrase0(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *text, SV *k, HV *info)
{
    AV *whole = tkn_whole(aTHX_ L, k);
    SV *v, *t, *kk;
    int have = tkn_words_ok(words);
    if (av_len(whole) >= 0)
        return tkn_relative(aTHX_ self, L, k, info, whole);
    if (have) {
        v = tkn_worded(aTHX_ self, L, words, text, k, info);
        if (v || tkn_has_reason(aTHX_ info))
            return v;
        tkn_info_reset(aTHX_ info);
    }
    v = tkn_plain(aTHX_ self, L, words, text, k, info);
    if (v || tkn_has_reason(aTHX_ info) || !have)
        return v;
    t = text;
    kk = k;
    tkn_skip(aTHX_ words, L, &t, &kk);
    if (sv_eq(kk, k) || !SvCUR(kk))
        return NULL;
    tkn_info_reset(aTHX_ info);
    return tkn_plain(aTHX_ self, L, words, t, kk, info);
}

static SV *tkn_day_phrase(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *text, HV *info);
static SV *tkn_zone_phrase(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *text, HV *info);
static SV *tkn_frac_phrase(pTHX_ SV *self, tkn_lexicon *L, SV *text, HV *info);
static SV *tkn_point_phrase(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *text, HV *info);

/* _phrase without a zone: and where 0.01's reading fails, with a day
 * ordinal ("the 15th") read. */
static SV *
tkn_phrase_dated(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *text, SV *k, HV *info)
{
    SV *v = tkn_phrase0(aTHX_ self, L, words, text, k, info);
    HV *di;
    if (v)
        return v;
    di = tkn_info_new(aTHX);
    v = tkn_day_phrase(aTHX_ self, L, words, text, di);
    if (v || tkn_has_reason(aTHX_ di)) {
        tkn_info_set(aTHX_ info, di);
        return v;
    }
    di = tkn_info_new(aTHX);
    v = tkn_frac_phrase(aTHX_ self, L, text, di);
    if (v || tkn_has_reason(aTHX_ di)) {
        tkn_info_set(aTHX_ info, di);
        return v;
    }
    di = tkn_info_new(aTHX);
    v = tkn_point_phrase(aTHX_ self, L, words, text, di);
    if (v)
        tkn_info_set(aTHX_ info, di);
    return v;
}

/* _phrase: and where that fails, with a zone after it ("3 pm EST"). */
static SV *
tkn_phrase(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *text, SV *k, HV *info)
{
    SV *v = tkn_phrase_dated(aTHX_ self, L, words, text, k, info);
    HV *di;
    if (v)
        return v;
    di = tkn_info_new(aTHX);
    v = tkn_zone_phrase(aTHX_ self, L, words, text, di);
    if (v || tkn_has_reason(aTHX_ di))
        tkn_info_set(aTHX_ info, di);
    return v;
}

#endif
