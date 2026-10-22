#ifndef TKN_PATTERNS_H
#define TKN_PATTERNS_H

/* A lexicon's date and time patterns, as the absolute reader tries them:
 * the locale's four date-time combinations, its date and time formats and
 * its skeletons, each with zone letters taken out, classified (kind,
 * precision, how many numbers and whether it has words), with an unpadded
 * twin and, for a time, a twin without spaces; datetime first, then date,
 * then time, the most letters first within each. Built on first use. */

typedef struct {
    STRLEN s, e;
    int q;
} tkn_seg;

static int
tkn_ascii_letter(char c)
{
    return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
}

/* The pattern split at its quoted literals, as 0.01's
 * split /('(?:[^']|'')*')/ did; segs needs room for n + 2. */
static int
tkn_segments(const char *b, STRLEN n, tkn_seg *segs)
{
    STRLEN i = 0, start = 0;
    int ns = 0;
    while (i < n) {
        if (b[i] == '\'') {
            STRLEN j = i + 1, cand = 0, close = 0;
            int has_cand = 0, closed = 0;
            for (;;) {
                if (j < n && b[j] != '\'') {
                    j++;
                    continue;
                }
                if (j + 1 < n && b[j] == '\'' && b[j + 1] == '\'') {
                    cand = j;
                    has_cand = 1;
                    j += 2;
                    continue;
                }
                break;
            }
            if (j < n && b[j] == '\'') {
                close = j;
                closed = 1;
            }
            else if (has_cand) {
                close = cand;
                closed = 1;
            }
            if (closed) {
                if (i > start) {
                    segs[ns].s = start;
                    segs[ns].e = i;
                    segs[ns++].q = 0;
                }
                segs[ns].s = i;
                segs[ns].e = close + 1;
                segs[ns++].q = 1;
                i = close + 1;
                start = i;
                continue;
            }
        }
        i++;
    }
    segs[ns].s = start;
    segs[ns].e = n;
    segs[ns++].q = 0;
    return ns;
}

static int
tkn_in_hhdm(char c)
{
    return c == 'H' || c == 'h' || c == 'd' || c == 'M';
}

/* A character class test through Perl's regex engine (\p{L} and the like),
 * for one character at p. */
static int
tkn_rx_char(pTHX_ SV *qr, SV *scratch, const char *p, STRLEN cl)
{
    char *s;
    sv_setpvn(scratch, p, cl);
    SvUTF8_on(scratch);
    s = SvPVX(scratch);
    return pregexec(SvRX(qr), s, s + cl, s, 0, scratch, 1) ? 1 : 0;
}

/* _analyse: the pattern without zone letters, empty brackets and doubled
 * spaces, trimmed of spaces and commas; runs_max holds each letter's longest run. */
static SV *
tkn_analyse(pTHX_ SV *p, int *runs_max)
{
    STRLEN len, i;
    const char *c = tkn_utf8_bytes(aTHX_ p, &len);
    SV *out = sv_2mortal(newSVpvs("")), *res;
    int inq = 0, run[128];
    char prev = 0;
    const char *o, *e;
    Zero(run, 128, int);
    Zero(runs_max, 128, int);
    SvUTF8_on(out);
    for (i = 0; i < len; i++) {
        char ch = c[i];
        if (ch == '\'') {
            if (inq && i + 1 < len && c[i + 1] == '\'') {
                sv_catpvs(out, "''");
                i++;
                continue;
            }
            inq = !inq;
            sv_catpvn(out, &ch, 1);
            prev = 0;
            continue;
        }
        if (inq || !tkn_ascii_letter(ch)) {
            sv_catpvn(out, &ch, 1);
            prev = 0;
            continue;
        }
        if (strchr("zvOxXZV", ch))
            continue;
        sv_catpvn(out, &ch, 1);
        run[(int)ch] = prev == ch ? run[(int)ch] + 1 : 1;
        if (run[(int)ch] > runs_max[(int)ch])
            runs_max[(int)ch] = run[(int)ch];
        prev = ch;
    }

    o = SvPVX(out);
    e = o + SvCUR(out);
    res = sv_2mortal(newSVpvs(""));
    SvUTF8_on(res);
    while (o < e) {
        if (*o == '(') {
            const char *q = o + 1;
            while (q < e) {
                STRLEN cl;
                if (!tkn_is_space_cp(tkn_utf8_cp((const U8 *)q, (const U8 *)e, &cl)))
                    break;
                q += cl;
            }
            if (q < e && *q == ')') {
                o = q + 1;
                continue;
            }
        }
        sv_catpvn(res, o, 1);
        o++;
    }

    o = SvPVX(res);
    e = o + SvCUR(res);
    out = sv_2mortal(newSVpvs(""));
    SvUTF8_on(out);
    while (o < e) {
        STRLEN cl;
        UV cp = tkn_utf8_cp((const U8 *)o, (const U8 *)e, &cl);
        if (tkn_is_space_cp(cp)) {
            const char *q = o + cl;
            int n = 1;
            while (q < e) {
                STRLEN cl2;
                if (!tkn_is_space_cp(tkn_utf8_cp((const U8 *)q, (const U8 *)e, &cl2)))
                    break;
                q += cl2;
                n++;
            }
            if (n >= 2)
                sv_catpvs(out, " ");
            else
                sv_catpvn(out, o, cl);
            o = q;
            continue;
        }
        sv_catpvn(out, o, cl);
        o += cl;
    }

    o = SvPVX(out);
    e = o + SvCUR(out);
    while (o < e) {
        STRLEN cl;
        UV cp = tkn_utf8_cp((const U8 *)o, (const U8 *)e, &cl);
        if (cp != ',' && !tkn_is_space_cp(cp))
            break;
        o += cl;
    }
    while (e > o) {
        const char *q = e - 1;
        STRLEN cl;
        UV cp;
        while (q > o && ((U8)*q & 0xC0) == 0x80)
            q--;
        cp = tkn_utf8_cp((const U8 *)q, (const U8 *)e, &cl);
        if (cp != ',' && !tkn_is_space_cp(cp))
            break;
        e = q;
    }
    res = sv_2mortal(newSVpvn(o, (STRLEN)(e - o)));
    SvUTF8_on(res);
    return res;
}

/* The unquoted parts of v rewritten: 1 unpadded (HH, hh, dd, MM alone
 * become one letter), 2 without spaces. */
static SV *
tkn_rewrite(pTHX_ SV *v, int mode)
{
    STRLEN len;
    const char *b = SvPV_const(v, len);
    tkn_seg *segs;
    int ns, k;
    SV *out = sv_2mortal(newSVpvs(""));
    SvUTF8_on(out);
    Newx(segs, len + 2, tkn_seg);
    SAVEFREEPV(segs);
    ns = tkn_segments(b, len, segs);
    for (k = 0; k < ns; k++) {
        const char *s = b + segs[k].s;
        STRLEN n = segs[k].e - segs[k].s, i;
        if (segs[k].q) {
            sv_catpvn(out, s, n);
            continue;
        }
        for (i = 0; i < n;) {
            if (mode == 1 && i + 1 < n && s[i] == s[i + 1] && tkn_in_hhdm(s[i])
                && (i == 0 || !tkn_in_hhdm(s[i - 1])) && (i + 2 >= n || !tkn_in_hhdm(s[i + 2]))) {
                sv_catpvn(out, s + i, 1);
                i += 2;
                continue;
            }
            if (mode == 2 && s[i] == ' ') {
                i++;
                continue;
            }
            sv_catpvn(out, s + i, 1);
            i++;
        }
    }
    return out;
}

/* The characters of v's unquoted parts that are neither letters, digits nor
 * spaces, each once, in order. */
static AV *
tkn_punct(pTHX_ SV *v, SV *lns, SV *scratch)
{
    STRLEN len;
    const char *b = SvPV_const(v, len);
    tkn_seg *segs;
    int ns, k;
    AV *av = newAV();
    HV *seen = (HV *)sv_2mortal((SV *)newHV());
    Newx(segs, len + 2, tkn_seg);
    SAVEFREEPV(segs);
    ns = tkn_segments(b, len, segs);
    for (k = 0; k < ns; k++) {
        const char *s = b + segs[k].s, *e = b + segs[k].e;
        if (segs[k].q)
            continue;
        while (s < e) {
            STRLEN cl;
            UV cp = tkn_utf8_cp((const U8 *)s, (const U8 *)e, &cl);
            int other;
            if (cp < 0x80)
                other = !(tkn_ascii_letter((char)cp) || isDIGIT((U8)cp) || isSPACE((U8)cp));
            else
                other = !tkn_rx_char(aTHX_ lns, scratch, s, cl);
            if (other && !hv_exists(seen, s, -(I32)cl)) {
                SV *c = newSVpvn(s, cl);
                SvUTF8_on(c);
                (void)hv_store(seen, s, -(I32)cl, &PL_sv_yes, 0);
                av_push(av, c);
            }
            s += cl;
        }
    }
    return av;
}

/* Whether the pattern, its ASCII letters outside quotes taken out, has a
 * letter: a word written in it. */
static int
tkn_has_word(pTHX_ SV *q, SV *letter, SV *scratch)
{
    STRLEN len;
    const char *b = SvPV_const(q, len);
    tkn_seg *segs;
    int ns, k;
    Newx(segs, len + 2, tkn_seg);
    SAVEFREEPV(segs);
    ns = tkn_segments(b, len, segs);
    for (k = 0; k < ns; k++) {
        const char *s = b + segs[k].s, *e = b + segs[k].e;
        while (s < e) {
            STRLEN cl;
            UV cp = tkn_utf8_cp((const U8 *)s, (const U8 *)e, &cl);
            if (cp < 0x80) {
                if (tkn_ascii_letter((char)cp) && segs[k].q)
                    return 1;
            }
            else if (tkn_rx_char(aTHX_ letter, scratch, s, cl))
                return 1;
            s += cl;
        }
    }
    return 0;
}

typedef struct {
    int order, letters, prim;
    HV *hv;
} tkn_pat;

static AV *
tkn_patterns_build(pTHX_ tkn_lexicon *L)
{
    SV *args[3], *af, *letter, *lns, *scratch;
    I32 nown;
    AV *date, *time, *both, *raw = (AV *)sv_2mortal((SV *)newAV()), *keys, *res;
    HV *seen = (HV *)sv_2mortal((SV *)newHV());
    tkn_pat *pats = NULL;
    I32 i, n, np = 0, pcap = 0;

    letter = sv_2mortal(newSVsv(eval_pv(TKN_RX_LETTER, TRUE)));
    lns = sv_2mortal(newSVsv(eval_pv(TKN_RX_LNS, TRUE)));
    scratch = sv_2mortal(newSVpvs(""));

    args[0] = L->code;
    args[1] = sv_2mortal(newSVpvs("date"));
    args[2] = L->calendar;
    date = tkn_call(aTHX_ TKN_LOC, "formats", args, L->calendar ? 3 : 2);
    args[1] = sv_2mortal(newSVpvs("time"));
    time = tkn_call(aTHX_ TKN_LOC, "formats", args, 2);
    args[1] = sv_2mortal(newSVpvs("datetime"));
    both = tkn_call(aTHX_ TKN_LOC, "formats", args, L->calendar ? 3 : 2);
    for (i = 0; i < 4; i++) {
        SV **b = av_fetch(both, i, 0), **d = av_fetch(date, i, 0), **t = av_fetch(time, i, 0);
        SV *p = newSVpvs("");
        STRLEN bl;
        const char *bb, *q;
        if (!b)
            continue;
        bb = tkn_utf8_bytes(aTHX_ *b, &bl);
        sv_setpvn(p, bb, bl);
        SvUTF8_on(p);
        if (d && (q = strstr(SvPVX(p), "{1}"))) {
            STRLEN at = (STRLEN)(q - SvPVX(p)), dl;
            const char *db = tkn_utf8_bytes(aTHX_ *d, &dl);
            SV *x = newSVpvn(SvPVX(p), at);
            sv_catpvn(x, db, dl);
            sv_catpvn(x, SvPVX(p) + at + 3, SvCUR(p) - at - 3);
            SvUTF8_on(x);
            SvREFCNT_dec(p);
            p = x;
        }
        if (t && (q = strstr(SvPVX(p), "{0}"))) {
            STRLEN at = (STRLEN)(q - SvPVX(p)), tl;
            const char *tb = tkn_utf8_bytes(aTHX_ *t, &tl);
            SV *x = newSVpvn(SvPVX(p), at);
            sv_catpvn(x, tb, tl);
            sv_catpvn(x, SvPVX(p) + at + 3, SvCUR(p) - at - 3);
            SvUTF8_on(x);
            SvREFCNT_dec(p);
            p = x;
        }
        av_push(raw, p);
    }
    for (i = 0; i <= av_len(date); i++)
        av_push(raw, newSVsv(*av_fetch(date, i, 0)));
    for (i = 0; i <= av_len(time); i++)
        av_push(raw, newSVsv(*av_fetch(time, i, 0)));
    nown = av_len(raw) + 1;
    args[1] = L->calendar;
    af = tkn_call1(aTHX_ TKN_LOC, "available_formats", args, L->calendar ? 2 : 1);
    keys = tkn_sorted_keys(aTHX_ tkn_hv_of(af));
    for (i = 0; i <= av_len(keys); i++) {
        SV *k = *av_fetch(keys, i, 0);
        SV *v;
        if (strchr(SvPV_nolen(k), '-'))
            continue;
        v = tkn_hget(aTHX_ af, SvPV_nolen(k));
        av_push(raw, v ? newSVsv(v) : newSVpvs(""));
    }

    n = av_len(raw) + 1;
    /* in a calendar, Y is its year (gl writes Y for y), as Time::Keeper
       writes and reads it */
    if (L->calendar)
        for (i = 0; i < n; i++) {
            SV *r = *av_fetch(raw, i, 0);
            STRLEN j;
            int q = 0;
            char *rb = SvPV_force_nolen(r);
            for (j = 0; j < SvCUR(r); j++) {
                if (rb[j] == '\'')
                    q = !q;
                else if (!q && rb[j] == 'Y')
                    rb[j] = 'y';
            }
        }
    for (i = 0; i < n; i++) {
        int runs_max[128], has_date, has_time, numeric, alpha, mname, kind, v, nv;
        const char *precision, *kinds[3] = { "datetime", "date", "time" };
        SV *q = tkn_analyse(aTHX_ *av_fetch(raw, i, 0), runs_max), *vars[3];
        STRLEN ql, j;
        const char *qb = SvPV_const(q, ql), *x;
#define R(c) runs_max[(int)(c)]
        /* a calendar's related Gregorian year (r, the Chinese and Korean
           calendars' year) is a year, and its cyclic year (U, "bing-wu") is
           read beside it or the anchor's; elsewhere none of these is read */
        if (R('Q') || R('q') || R('w') || R('W') || R('F') || R('g') || R('u') || ((R('U') || R('r')) && !L->calendar))
            continue;
        has_date = R('y') || R('r') || R('M') || R('L') || R('d') || R('G');
        has_time = R('h') || R('H') || R('k') || R('K') || R('m') || R('s') || R('a') || R('b') || R('B');
        if (!has_date && !has_time)
            continue;
        if (!has_date && (R('E') || R('c')))
            continue;
        if (!has_date && !(R('h') || R('H') || R('k') || R('K')))
            continue;
        if (!has_date && ql) {
            for (j = 0; j < ql; j++)
                if (!strchr("hHkK", qb[j]) || !qb[j])
                    break;
            if (j == ql)
                continue;
        }
        if (has_date && !R('y') && !R('r') && !R('d') && R('M') < 3 && R('L') < 3)
            continue;
        if (has_date && !R('y') && !R('r') && !R('M') && !R('L') && R('d'))
            continue;
        kind = has_date && has_time ? 0 : has_date ? 1 : 2;
        precision = R('s') ? "second" : R('m') ? "minute" : (R('h') || R('H') || R('k') || R('K')) ? "hour"
                  : R('d') ? "day" : (R('M') || R('L')) ? "month" : "year";
        numeric = 0;
        for (x = "yrMLdhHkKms"; *x; x++)
            if (R(*x) && ((*x != 'M' && *x != 'L') || R(*x) < 3))
                numeric++;
        mname = R('M') >= 3 || R('L') >= 3;
        alpha = (R('E') || R('c') || R('a') || R('b') || R('B') || R('G') || R('U') || mname
                 || tkn_has_word(aTHX_ q, letter, scratch)) ? 1 : 0;
        nv = 0;
        vars[nv++] = q;
        {
            SV *u = tkn_rewrite(aTHX_ q, 1);
            if (!sv_eq(u, q))
                vars[nv++] = u;
        }
        if (kind == 2) {
            SV *t = tkn_rewrite(aTHX_ q, 2);
            if (!sv_eq(t, q))
                vars[nv++] = t;
        }
        for (v = 0; v < nv; v++) {
            STRLEN vl;
            const char *vb = SvPV_const(vars[v], vl);
            int letters = 0;
            HV *hv;
            if (hv_exists(seen, vb, -(I32)vl))
                continue;
            (void)hv_store(seen, vb, -(I32)vl, &PL_sv_yes, 0);
            for (j = 0; j < vl; j++)
                if (tkn_ascii_letter(vb[j]))
                    letters++;
            hv = newHV();
            (void)hv_stores(hv, "pattern", newSVsv(vars[v]));
            (void)hv_stores(hv, "kind", newSVpv(kinds[kind], 0));
            (void)hv_stores(hv, "year", newSViv(R('y') || R('r') ? 1 : 0));
            (void)hv_stores(hv, "y_run", newSViv(R('y')));
            (void)hv_stores(hv, "era", newSViv(R('G') ? 1 : 0));
            (void)hv_stores(hv, "cyclic_name", newSViv(R('U') ? 1 : 0));
            (void)hv_stores(hv, "weekday", newSViv((R('E') || R('c')) ? 1 : 0));
            (void)hv_stores(hv, "precision", newSVpv(precision, 0));
            (void)hv_stores(hv, "numeric", newSViv(numeric));
            (void)hv_stores(hv, "letters", newSViv(letters));
            (void)hv_stores(hv, "alpha", newSViv(alpha));
            (void)hv_stores(hv, "month_name", newSViv(mname));
            (void)hv_stores(hv, "punct", newRV_noinc((SV *)tkn_punct(aTHX_ vars[v], lns, scratch)));
            if (np == pcap) {
                pcap = pcap ? pcap * 2 : 64;
                Renew(pats, pcap, tkn_pat);
            }
            pats[np].order = kind;
            pats[np].letters = letters;
            /* in a calendar the locale's own formats come before its
               skeletons, which can disagree (es-PA's Hebrew medium date is
               MM/dd/y G, its GyMd d/M/y GGGGG) */
            pats[np].prim = L->calendar && i < nown ? 0 : 1;
            pats[np++].hv = hv;
        }
#undef R
    }
    for (i = 1; i < np; i++) {
        tkn_pat x = pats[i];
        I32 j = i - 1;
        while (j >= 0 && (pats[j].order > x.order || (pats[j].order == x.order && (pats[j].prim > x.prim
                          || (pats[j].prim == x.prim && pats[j].letters < x.letters))))) {
            pats[j + 1] = pats[j];
            j--;
        }
        pats[j + 1] = x;
    }
    res = newAV();
    for (i = 0; i < np; i++)
        av_push(res, newRV_noinc((SV *)pats[i].hv));
    Safefree(pats);
    return res;
}

#endif
