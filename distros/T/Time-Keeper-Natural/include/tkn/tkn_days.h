#ifndef TKN_DAYS_H
#define TKN_DAYS_H

/* Day ordinals in digits, "15th", "1er", "1.º", read where the plain
 * reading failed: "the 15th" alone is that day of the anchor's month (or the
 * next or last one under prefer); "15th of October", "15th October", "le
 * 1er octobre" set the day in a month read from the rest; otherwise the
 * ordinal is put back as its digits ("October 15th, 2026") and read again,
 * kept only where it was read as that day of a date. */

/* The text's tokens, split at white space. */
static AV *
tkn_ws_tokens(pTHX_ SV *text)
{
    AV *out = (AV *)sv_2mortal((SV *)newAV());
    STRLEN len;
    const U8 *p = (const U8 *)tkn_utf8_bytes(aTHX_ text, &len), *e = p + len, *s = NULL;
    while (p <= e) {
        STRLEN cl = 1;
        int sp = p == e || tkn_is_space_cp(tkn_utf8_cp(p, e, &cl));
        if (sp && s) {
            SV *t = newSVpvn((const char *)s, (STRLEN)(p - s));
            SvUTF8_on(t);
            av_push(out, t);
            s = NULL;
        }
        else if (!sp && !s)
            s = p;
        if (p == e)
            break;
        p += cl;
    }
    return out;
}

static SV *
tkn_join_tokens(pTHX_ AV *t, I32 from, I32 to)
{
    SV *out = sv_2mortal(newSVpvs(""));
    I32 i;
    SvUTF8_on(out);
    for (i = from; i < to; i++) {
        if (i > from)
            sv_catpvs(out, " ");
        sv_catsv(out, *av_fetch(t, i, 0));
    }
    return out;
}

/* A token's day, its trailing comma aside: 1 to 31, or 0. */
static int
tkn_day_token(pTHX_ SV *nw, SV *tok, STRLEN *keep)
{
    SV *t = sv_2mortal(newSVsv(tok)), *v;
    STRLEN n = SvCUR(t);
    *keep = n;
    while (n && (SvPVX(t)[n - 1] == ',' || SvPVX(t)[n - 1] == ';'))
        n--;
    SvCUR_set(t, n);
    *keep = n;
    v = n ? tkn_numbers_read(aTHX_ nw, "d", t) : NULL;
    return v ? (int)SvIV(v) : 0;
}

static void
tkn_assume_but(pTHX_ HV *info, HV *from, const char *drop)
{
    AV *b = tkn_assumed(aTHX_ from);
    I32 i;
    for (i = 0; i <= av_len(b); i++) {
        SV *x = *av_fetch(b, i, 0);
        if (!strEQ(SvPV_nolen(x), drop))
            tkn_info_assume(aTHX_ info, SvPV_nolen(x));
    }
}

/* Day d of the month a civil date is in: the value, or NULL with the reason
 * Time::Keeper gives ("2026-11 has no day 31"). */
static SV *
tkn_day_of(pTHX_ tkn_lexicon *L, SV *anchor, time_keeper_civil c, int d, HV *info, SV *tok)
{
    SV *v;
    c.day = d;
    c.hour = c.minute = c.second = 0;
    c.nanosecond = 0;
    v = tkn_value_at(aTHX_ L, anchor, &c);
    if (!v) {
        (void)hv_stores(info, "reason", newSVpvf("%04d-%02d has no day %d", (int)c.year, (int)c.month, d));
        (void)hv_stores(info, "token", newSVsv(tok));
    }
    return v;
}

/* Day d of the anchor's month, or the next or last such day under prefer. */
static int
tkn_anchor_month(pTHX_ SV *self, SV *anchor, int d, time_keeper_civil *c)
{
    SV *pf = tkn_self_opt(aTHX_ self, "prefer");
    const char *pfs = pf && SvOK(pf) ? SvPV_nolen(pf) : "";
    tkn_civil_of(aTHX_ anchor, c);
    if (strEQ(pfs, "future") && d < c->day) {
        if (++c->month > 12) {
            c->month = 1;
            c->year++;
        }
    }
    else if (strEQ(pfs, "past") && d > c->day) {
        if (--c->month < 1) {
            c->month = 12;
            c->year--;
        }
    }
    return 1;
}

static SV *
tkn_day_phrase(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *text, HV *info)
{
    SV *nw = tkn_numbers_for(aTHX_ sv_2mortal(newSVpvs("Time::Keeper::Natural::Numbers")), L->code);
    AV *tok;
    I32 i, n, at = -1, span = 1;
    int day = 0, have = tkn_words_ok(words);
    STRLEN keep = 0;
    SV *anchor;
    if (!SvOK(nw) || !SvROK(nw))
        return NULL;
    {
        SV **d = hv_fetchs((HV *)SvRV(nw), "d", 0);
        if (!d || !SvROK(*d) || !HvUSEDKEYS((HV *)SvRV(*d)))
            return NULL;
    }
    tok = tkn_ws_tokens(aTHX_ text);
    n = av_len(tok) + 1;
    /* a form may hold a space ("ที่ 1", "No. 1"): spans of three tokens down */
    for (i = 0; i < n; i++) {
        I32 w;
        for (w = n - i < 3 ? n - i : 3; w >= 1; w--) {
            STRLEN kp;
            int d = tkn_day_token(aTHX_ nw, tkn_join_tokens(aTHX_ tok, i, i + w), &kp);
            if (!d)
                continue;
            if (at >= 0)
                return NULL;
            at = i;
            span = w;
            day = d;
            keep = kp;
            break;
        }
        if (at == i)
            i += span - 1;
    }
    if (at < 0)
        return NULL;
    if (span > 1) {
        AV *t = newAV();
        sv_2mortal((SV *)t);
        for (i = 0; i < n; i++) {
            if (i == at) {
                av_push(t, newSVsv(tkn_join_tokens(aTHX_ tok, at, at + span)));
                i += span - 1;
            }
            else
                av_push(t, newSVsv(*av_fetch(tok, i, 0)));
        }
        tok = t;
        n = av_len(tok) + 1;
    }
    anchor = tkn_anchor(aTHX_ self);
    /* skip words, the ordinal, "of", a month or nothing */
    {
        SV *pre = tkn_join_tokens(aTHX_ tok, 0, at + 1), *pk = tkn_key_sv(aTHX_ L, pre);
        int bare = at == 0;
        if (!bare && have) {
            SV *t = pre;
            tkn_skip(aTHX_ words, L, &t, &pk);
            bare = sv_eq(pk, tkn_key_sv(aTHX_ L, *av_fetch(tok, at, 0)));
        }
        if (bare) {
            SV *rest = tkn_join_tokens(aTHX_ tok, at + 1, n), *rk = tkn_key_sv(aTHX_ L, rest);
            SV *tsv = *av_fetch(tok, at, 0);
            if (have && SvCUR(rk)) {
                SV *t, *kk, *raw;
                if (tkn_after(aTHX_ words, L, rest, "of", &t, &kk, &raw)) {
                    rest = t;
                    rk = kk;
                }
            }
            if (!SvCUR(rk)) {
                time_keeper_civil c;
                SV *v;
                tkn_anchor_month(aTHX_ self, anchor, day, &c);
                tkn_info_reset(aTHX_ info);
                v = tkn_day_of(aTHX_ L, anchor, c, day, info, tsv);
                if (!v)
                    return NULL;
                (void)hv_stores(info, "precision", newSVpvs("day"));
                tkn_info_assume(aTHX_ info, "month");
                tkn_info_assume(aTHX_ info, "time");
                return v;
            }
            {
                HV *ri = tkn_info_new(aTHX);
                SV *mv = tkn_phrase0(aTHX_ self, L, words, rest, rk, ri), *pr = mv ? tkn_hsv(aTHX_ ri, "precision") : NULL;
                if (pr && strEQ(SvPV_nolen(pr), "month")) {
                    time_keeper_civil c;
                    SV *v;
                    tkn_civil_of(aTHX_ mv, &c);
                    tkn_info_reset(aTHX_ info);
                    v = tkn_day_of(aTHX_ L, anchor, c, day, info, tsv);
                    if (!v)
                        return NULL;
                    (void)hv_stores(info, "precision", newSVpvs("day"));
                    tkn_assume_but(aTHX_ info, ri, "period start");
                    tkn_info_assume(aTHX_ info, "time");
                    if (tkn_hsv(aTHX_ ri, "zone_named"))
                        (void)hv_stores(info, "zone_named", newSViv(1));
                    return v;
                }
                /* a time on that day of the anchor's month: "the 2nd at 3 pm" */
                if (mv && tkn_assumed_has(aTHX_ ri, "date")) {
                    time_keeper_civil c, t;
                    SV *v;
                    tkn_anchor_month(aTHX_ self, anchor, day, &c);
                    tkn_civil_of(aTHX_ mv, &t);
                    tkn_info_reset(aTHX_ info);
                    v = tkn_day_of(aTHX_ L, anchor, c, day, info, tsv);
                    if (!v)
                        return NULL;
                    c.day = day;
                    c.hour = t.hour;
                    c.minute = t.minute;
                    c.second = t.second;
                    c.nanosecond = t.nanosecond;
                    v = tkn_value_at(aTHX_ L, anchor, &c);
                    if (!v)
                        return NULL;
                    (void)hv_stores(info, "precision", newSVsv(pr));
                    tkn_info_assume(aTHX_ info, "month");
                    tkn_assume_but(aTHX_ info, ri, "date");
                    if (tkn_hsv(aTHX_ ri, "zone_named"))
                        (void)hv_stores(info, "zone_named", newSViv(1));
                    return v;
                }
            }
        }
    }
    /* the ordinal as its digits, read again; kept where the number was read
       as the day: written as another day, the day read moves with it */
    {
        SV *v = NULL;
        HV *si = tkn_info_new(aTHX);
        int pass;
        for (pass = 0; pass < 2; pass++) {
            int want = pass ? (day == 1 ? 2 : 1) : day;
            SV *sub = *av_fetch(tok, at, 0), *t2, *got;
            HV *pi = pass ? tkn_info_new(aTHX) : si;
            AV *t = (AV *)sv_2mortal((SV *)tkn_av_copy(n, AvARRAY(tok)));
            time_keeper_civil c;
            STRLEN sl;
            const char *sb = SvPV_const(sub, sl);
            SV *num = sv_2mortal(newSVpvf("%d", want));
            sv_catpvn(num, sb + keep, sl - keep);
            av_store(t, at, newSVsv(num));
            t2 = tkn_join_tokens(aTHX_ t, 0, n);
            got = tkn_phrase0(aTHX_ self, L, words, t2, tkn_key_sv(aTHX_ L, t2), pi);
            if (!got || tkn_assumed_has(aTHX_ pi, "date"))
                return NULL;
            tkn_civil_of(aTHX_ got, &c);
            if (c.day != want)
                return NULL;
            if (!pass)
                v = got;
        }
        tkn_info_set(aTHX_ info, si);
        return v;
    }
}

#endif
