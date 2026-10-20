#ifndef TKN_POINTS_H
#define TKN_POINTS_H

/* Relative to a point, read where the plain reading failed: a duration
 * before or after a point ("3 days after tomorrow", "2 weeks before 15
 * October", "the day after the 20th"), round the word table's after and
 * before; a day and a part of it ("tomorrow morning", "demain matin"), the
 * part's name CLDR's and its start the locale's day-period rules; and the
 * weekend ("this weekend", "next weekend"), the locale's weekend days in
 * the week CLDR's "this week" or "next week" names, the word table giving
 * the noun. */

static SV *tkn_phrase_dated(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *text, SV *k, HV *info);

static int
tkn_rank_of_parts(const time_keeper_parts *p)
{
    if (p->nanoseconds) return tkn_rank("nanosecond");
    if (p->seconds) return tkn_rank("second");
    if (p->minutes) return tkn_rank("minute");
    if (p->hours) return tkn_rank("hour");
    if (p->days || p->weeks) return tkn_rank("day");
    if (p->months) return tkn_rank("month");
    return tkn_rank("year");
}

/* The point moved by the duration, forward or back, its precision the finer
 * of the two. */
static SV *
tkn_point_moved(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *dtext, SV *ptext, int dir, HV *info)
{
    HV *di = (HV *)sv_2mortal((SV *)newHV()), *pi = tkn_info_new(aTHX);
    SV *d, *p, *v, *pr;
    time_keeper_parts parts;
    (void)hv_stores(di, "assumed", newRV_noinc((SV *)newAV()));
    if (dtext) {
        d = tkn_duration_value(aTHX_ L, tkn_key_sv(aTHX_ L, dtext), dtext, di);
        if (!d || !SvTRUE(d))
            d = tkn_frac_duration(aTHX_ L, dtext, di);
        if (!d || !SvTRUE(d))
            return NULL;
    }
    else {
        const char *n = "days";
        SV *one = sv_2mortal(newSViv(1));
        d = tkn_new_duration(aTHX_ &n, &one, 1);
    }
    p = tkn_phrase_dated(aTHX_ self, L, words, ptext, tkn_key_sv(aTHX_ L, ptext), pi);
    if (!p)
        return NULL;
    v = tkn_method(aTHX_ p, dir > 0 ? "plus" : "minus", &d, 1);
    tkn_info_set(aTHX_ info, pi);
    pr = tkn_hsv(aTHX_ pi, "precision");
    if ((TKN_TK->duration_from_sv)(aTHX_ d, &parts) == TIME_KEEPER_OK) {
        int r = tkn_rank_of_parts(&parts);
        if (!pr || r > tkn_rank(SvPV_nolen(pr)))
            (void)hv_stores(info, "precision", newSVpv(tkn_order[r], 0));
    }
    return v;
}

static SV *
tkn_before_after(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *text, HV *info)
{
    static const char *const keys[2] = { "after", "before" };
    tkn_fold F;
    int kx;
    if (!tkn_words_ok(words))
        return NULL;
    tkn_fold_text(aTHX_ tkn_trim(aTHX_ text), &F);
    for (kx = 0; kx < 2; kx++) {
        AV *list = tkn_phrases_of(aTHX_ words, sv_2mortal(newSVpv(keys[kx], 0)));
        I32 i;
        for (i = 0; list && i <= av_len(list); i++) {
            AV *ph = (AV *)SvRV(*av_fetch(list, i, 0));
            SV *pre = *av_fetch(ph, 2, 0), *mid = *av_fetch(ph, 5, 0), *post = *av_fetch(ph, 4, 0), *v;
            STRLEN p = tkn_fskip_ws(&F, 0), yend = F.flen, c;
            if (SvOK(pre)) {
                IV m = tkn_match_toks(&F, pre, p);
                if (m < 0)
                    continue;
                p = tkn_fskip_ws(&F, (STRLEN)m);
            }
            if (SvOK(post)) {
                STRLEN e2;
                int found = 0;
                for (e2 = F.flen; e2 > p; e2--) {
                    IV m;
                    if (((U8)F.f[e2 - 1] & 0xC0) == 0x80)
                        continue;
                    m = tkn_match_toks(&F, post, e2 - 1);
                    if (m >= 0 && tkn_fskip_ws(&F, (STRLEN)m) == F.flen) {
                        yend = e2 - 1;
                        found = 1;
                        break;
                    }
                }
                if (!found)
                    continue;
            }
            if (!SvOK(mid)) {
                /* one slot: a point a day away */
                STRLEN ye = tkn_ftrim_end(&F, p, yend);
                if (ye <= p)
                    continue;
                v = tkn_point_moved(aTHX_ self, L, words, NULL, tkn_fsub(aTHX_ &F, p, ye), kx ? -1 : 1, info);
                if (v)
                    return v;
                continue;
            }
            for (c = p + 1; c < yend; c = tkn_fnext(&F, c)) {
                IV m = tkn_match_toks(&F, mid, c);
                STRLEN xe, ya, ye;
                if (m < 0 || (STRLEN)m >= yend)
                    continue;
                xe = tkn_ftrim_end(&F, p, c);
                ya = tkn_fskip_ws(&F, (STRLEN)m);
                ye = tkn_ftrim_end(&F, ya, yend);
                if (xe <= p || ye <= ya)
                    continue;
                v = tkn_point_moved(aTHX_ self, L, words, tkn_fsub(aTHX_ &F, p, xe), tkn_fsub(aTHX_ &F, ya, ye), kx ? -1 : 1, info);
                if (v)
                    return v;
            }
        }
    }
    return NULL;
}

/* A part of the day by any of its CLDR names in the locale: its start in
 * minutes, or -1. Where two parts share a name (fr "matin", night1 and
 * morning1), the longer. */
static int
tkn_period_start(pTHX_ tkn_lexicon *L, SV *name)
{
    static const char *const ws[3] = { "wide", "abbreviated", "narrow" };
    static const char *const cs[2] = { "format", "stand-alone" };
    SV *key = tkn_key_sv(aTHX_ L, name);
    AV *rules;
    HV *hit = (HV *)sv_2mortal((SV *)newHV());
    int w, c, best = -1, best_len = -1;
    I32 i;
    for (w = 0; w < 3; w++)
        for (c = 0; c < 2; c++) {
            SV *args[3], *dp;
            HE *he;
            args[0] = L->code;
            args[1] = sv_2mortal(newSVpv(ws[w], 0));
            args[2] = sv_2mortal(newSVpv(cs[c], 0));
            dp = tkn_call1(aTHX_ TKN_LOC, "day_periods", args, 3);
            if (!dp || !SvROK(dp) || SvTYPE(SvRV(dp)) != SVt_PVHV)
                continue;
            hv_iterinit((HV *)SvRV(dp));
            while ((he = hv_iternext((HV *)SvRV(dp)))) {
                SV *pk = hv_iterkeysv(he);
                if (strEQ(SvPV_nolen(pk), "am") || strEQ(SvPV_nolen(pk), "pm") || !SvOK(HeVAL(he)))
                    continue;
                if (sv_eq(tkn_key_sv(aTHX_ L, HeVAL(he)), key))
                    (void)hv_store_ent(hit, pk, &PL_sv_yes, 0);
            }
        }
    if (!HvUSEDKEYS(hit))
        return -1;
    rules = tkn_call(aTHX_ TKN_LOC, "day_period_rules", &L->code, 1);
    for (i = 0; rules && i <= av_len(rules); i++) {
        SV *r = *av_fetch(rules, i, 0), *pn = tkn_hget(aTHX_ r, "period"), *at = tkn_hget(aTHX_ r, "at"),
           *from = tkn_hget(aTHX_ r, "from"), *before = tkn_hget(aTHX_ r, "before");
        int start, len;
        if (!pn || !hv_exists_ent(hit, pn, 0))
            continue;
        if (at && SvOK(at)) {
            start = (int)SvIV(at);
            len = 0;
        }
        else if (from && SvOK(from) && before && SvOK(before)) {
            start = (int)SvIV(from);
            len = ((int)SvIV(before) - start + 1440) % 1440;
            if (!len)
                len = 1440;
        }
        else
            continue;
        if (len > best_len) {
            best = start;
            best_len = len;
        }
    }
    return best;
}

static SV *
tkn_day_and_period(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *text, HV *info)
{
    AV *off = tkn_ws_offsets(aTHX_ text);
    I32 n = (av_len(off) + 1) / 2, cut, o;
    STRLEN len;
    const char *tb = tkn_utf8_bytes(aTHX_ text, &len);
    for (cut = 1; cut < n; cut++)
        for (o = 0; o < 2; o++) {
            /* the day first ("tomorrow morning"), or the part ("matin demain"
               is not written; "morning tomorrow" is read for symmetry) */
            STRLEN e1 = (STRLEN)SvIV(*av_fetch(off, 2 * (cut - 1) + 1, 0)), s2 = (STRLEN)SvIV(*av_fetch(off, 2 * cut, 0));
            SV *left = sv_2mortal(newSVpvn_flags(tb, e1, SVf_UTF8)), *right = sv_2mortal(newSVpvn_flags(tb + s2, len - s2, SVf_UTF8));
            SV *dt = o ? right : left, *pt = o ? left : right, *day, *v;
            HV *di = tkn_info_new(aTHX);
            int start = tkn_period_start(aTHX_ L, pt);
            if (start < 0)
                continue;
            day = tkn_day_part(aTHX_ self, L, NULL, words, dt, di);
            if (!day)
                continue;
            {
                SV *args[6];
                args[0] = sv_2mortal(newSVpvs("hour"));
                args[1] = sv_2mortal(newSViv(start / 60));
                args[2] = sv_2mortal(newSVpvs("minute"));
                args[3] = sv_2mortal(newSViv(start % 60));
                args[4] = sv_2mortal(newSVpvs("second"));
                args[5] = sv_2mortal(newSViv(0));
                v = tkn_method(aTHX_ tkn_truncate(aTHX_ day, TIME_KEEPER_UNIT_DAY), "with", args, 6);
            }
            tkn_info_reset(aTHX_ info);
            {
                AV *a = tkn_assumed(aTHX_ di);
                I32 j;
                for (j = 0; j <= av_len(a); j++)
                    if (strNE(SvPV_nolen(*av_fetch(a, j, 0)), "time"))
                        tkn_info_assume(aTHX_ info, SvPV_nolen(*av_fetch(a, j, 0)));
            }
            (void)hv_stores(info, "precision", newSVpvs("hour"));
            tkn_info_assume(aTHX_ info, "period start");
            return v;
        }
    return NULL;
}

/* The weekend: CLDR's week at-strings ("last week", "this week", "next
 * week") with the table's noun in place of the week's name, and the
 * locale's weekend days. */
static SV *
tkn_weekend(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *text, HV *info)
{
    AV *list;
    SV *args[3], *rel, *at, *disp, *key;
    I32 i;
    if (!tkn_words_ok(words))
        return NULL;
    list = tkn_phrases_of(aTHX_ words, sv_2mortal(newSVpvs("weekend")));
    if (!list || av_len(list) < 0)
        return NULL;
    args[0] = L->code;
    args[1] = sv_2mortal(newSVpvs("week"));
    args[2] = sv_2mortal(newSVpvs("long"));
    rel = tkn_call1(aTHX_ TKN_LOC, "relative_names", args, 3);
    at = rel ? tkn_hget(aTHX_ rel, "at") : NULL;
    disp = rel ? tkn_hget(aTHX_ rel, "display") : NULL;
    if (!at || !disp || !SvOK(disp))
        return NULL;
    key = tkn_key_sv(aTHX_ L, text);
    for (i = 0; i <= av_len(list); i++) {
        SV *noun = *av_fetch((AV *)SvRV(*av_fetch(list, i, 0)), 1, 0);
        HE *he;
        hv_iterinit((HV *)SvRV(at));
        while ((he = hv_iternext((HV *)SvRV(at)))) {
            SV *s = HeVAL(he), *dk = tkn_key_sv(aTHX_ L, disp), *sk = tkn_key_sv(aTHX_ L, s), *cand;
            STRLEN sl, dl;
            const char *sb = SvPV_const(sk, sl), *db = SvPV_const(dk, dl), *q = NULL, *x;
            IV nn = SvIV(hv_iterkeysv(he));
            for (x = sb; x + dl <= sb + sl; x++)
                if (memEQ(x, db, dl)) {
                    q = x;
                    break;
                }
            if (!q)
                continue;
            cand = sv_2mortal(newSVpvn(sb, (STRLEN)(q - sb)));
            sv_catsv(cand, tkn_key_sv(aTHX_ L, noun));
            sv_catpvn(cand, q + dl, (STRLEN)(sb + sl - q - dl));
            SvUTF8_on(cand);
            if (!sv_eq(tkn_key_sv(aTHX_ L, cand), key))
                continue;
            {
                /* this weekend is the one under way, else the coming one,
                   whatever day the week starts on (en-IN's is Sunday alone,
                   en-SD's Friday and Saturday across its week's start); next
                   and last a week either side */
                SV *anchor = tkn_anchor(aTHX_ self), *day, *v;
                IV ws = SvIV(tkn_call1(aTHX_ TKN_LOC, "weekend_start", &L->code, 1));
                IV we = SvIV(tkn_call1(aTHX_ TKN_LOC, "weekend_end", &L->code, 1));
                IV span = (we - ws + 7) % 7;
                day = tkn_truncate(aTHX_ anchor, TIME_KEEPER_UNIT_DAY);
                if (span)
                    day = tkn_plus1(aTHX_ day, "days", sv_2mortal(newSViv(-span)));
                v = tkn_adjust_dow_or(aTHX_ day, (int)ws, 1, 1);
                if (nn)
                    v = tkn_plus1(aTHX_ v, "weeks", sv_2mortal(newSViv(nn)));
                tkn_info_reset(aTHX_ info);
                (void)hv_stores(info, "precision", newSVpvs("day"));
                tkn_info_assume(aTHX_ info, "period start");
                return v;
            }
        }
    }
    return NULL;
}

/* All three, in turn. */
static SV *
tkn_point_phrase(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *text, HV *info)
{
    SV *v = tkn_before_after(aTHX_ self, L, words, text, info);
    if (!v)
        v = tkn_day_and_period(aTHX_ self, L, words, text, info);
    if (!v)
        v = tkn_weekend(aTHX_ self, L, words, text, info);
    return v;
}

#endif
