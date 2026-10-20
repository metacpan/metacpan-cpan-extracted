#ifndef TKN_WORDS_H
#define TKN_WORDS_H

/* Time::Keeper::Natural::Words: a locale's word table (share/words), the
 * words CLDR does not have, read through the locale's chain. A phrase is
 * compiled to a token string, not a regex: a literal (case-folded), one or
 * more spaces, none or more, or an apostrophe of either form. Matching folds
 * the text as typed, with a map from each folded byte back to the text, and
 * follows 0.01's regexes in their backtracking order:
 *
 *   frame     ^\s* PRE (?:\s+|\s*\z) or \s*  (.*?)  \s+ or \s* SUF \s*\z
 *   split_on  ^\s* (.*?\S) \s+ PHRASE \s+ (\S.*?) \s*\z
 *
 * where a space in a phrase is \s+ (\s* in a spaceless locale, which also
 * allows spaces between every character), and . does not match a newline.
 * The object is a blessed hash: code, for, file, spaceless, tests, and
 * phrases (key to [norm, raw, pre, flags, suf, split, split flags]). */

#define TKN_TOK_LIT  'L'
#define TKN_TOK_WS1  'S'
#define TKN_TOK_WS0  's'
#define TKN_TOK_APOS 'A'

#define TKN_F_PRE    1
#define TKN_F_PRE_WS 2
#define TKN_F_SUF    4
#define TKN_F_SUF_WS 8

static const char *const tkn_word_keys[] = { "after", "and", "at", "before", "end_of", "last", "of", "on", "range", "skip", "start_of", "weekend" };
#define TKN_N_WORD_KEYS 12

/* One character's case fold, as /i compares it, appended to out. */
static void
tkn_fold_cat(pTHX_ SV *out, const U8 *p, const U8 *e)
{
    U8 buf[UTF8_MAXBYTES_CASE + 1];
    STRLEN len = 0;
    if (*p < 0x80) {
        char c = (char)toLOWER(*p);
        sv_catpvn(out, &c, 1);
        return;
    }
#if PERL_VERSION_GE(5, 26, 0)
    toFOLD_utf8_safe(p, e, buf, &len);
#else
    PERL_UNUSED_ARG(e);
    to_utf8_fold(p, buf, &len);
#endif
    sv_catpvn(out, (const char *)buf, len);
}

static int
tkn_is_apos(UV cp)
{
    return cp == '\'' || cp == 0x2019;
}

static void
tkn_tok_lit(pTHX_ SV *toks, const U8 *p, const U8 *e)
{
    SV *f = sv_2mortal(newSVpvs(""));
    U32 n;
    while (p < e) {
        tkn_fold_cat(aTHX_ f, p, e);
        p += UTF8SKIP(p);
    }
    n = (U32)SvCUR(f);
    sv_catpvn(toks, "L", 1);
    sv_catpvn(toks, (const char *)&n, sizeof n);
    sv_catpvn(toks, SvPVX(f), SvCUR(f));
}

/* 0.01's _lit: the tokens of a piece of a phrase. */
static SV *
tkn_lit(pTHX_ const U8 *p, const U8 *e, int spaceless)
{
    SV *toks = sv_2mortal(newSVpvs(""));
    while (p < e) {
        STRLEN cl;
        UV cp = tkn_utf8_cp(p, e, &cl);
        if (tkn_is_space_cp(cp)) {
            while (p < e && tkn_is_space_cp(tkn_utf8_cp(p, e, &cl)))
                p += cl;
            sv_catpvn(toks, spaceless ? "s" : "S", 1);
            continue;
        }
        if (tkn_is_apos(cp)) {
            sv_catpvn(toks, "A", 1);
            p += cl;
            continue;
        }
        {
            const U8 *s = p;
            while (p < e) {
                UV c2 = tkn_utf8_cp(p, e, &cl);
                if (tkn_is_space_cp(c2) || tkn_is_apos(c2))
                    break;
                p += cl;
            }
            if (!spaceless)
                tkn_tok_lit(aTHX_ toks, s, p);
            else {
                const U8 *q = s;
                while (q < p) {
                    STRLEN c3 = UTF8SKIP(q);
                    if (q > s)
                        sv_catpvn(toks, "s", 1);
                    tkn_tok_lit(aTHX_ toks, q, q + c3);
                    q += c3;
                }
            }
        }
    }
    return toks;
}

/* A text folded for matching, and where each folded byte came from. */
typedef struct {
    const char *t;
    STRLEN tlen;
    int utf8;
    const char *f;
    STRLEN flen;
    STRLEN *off;
} tkn_fold;

static void
tkn_fold_text(pTHX_ SV *text, tkn_fold *F)
{
    STRLEN len;
    const U8 *p, *e, *s;
    SV *out = sv_2mortal(newSVpvs(""));
    STRLEN cap, n;
    if (!SvOK(text))
        text = sv_2mortal(newSVpvs(""));
    F->t = tkn_utf8_bytes(aTHX_ text, &len);
    F->tlen = len;
    F->utf8 = 1;
    s = p = (const U8 *)F->t;
    e = p + len;
    cap = len * UTF8_MAXBYTES_CASE + 1;
    Newx(F->off, cap, STRLEN);
    SAVEFREEPV(F->off);
    while (p < e) {
        STRLEN before = SvCUR(out), i;
        STRLEN cl = UTF8SKIP(p);
        if (p + cl > e)
            cl = (STRLEN)(e - p);
        tkn_fold_cat(aTHX_ out, p, e);
        for (i = before; i < SvCUR(out); i++)
            F->off[i] = (STRLEN)(p - s);
        p += cl;
    }
    n = SvCUR(out);
    F->off[n] = len;
    F->f = SvPVX(out);
    F->flen = n;
}

static STRLEN
tkn_fskip_ws(const tkn_fold *F, STRLEN p)
{
    while (p < F->flen) {
        STRLEN cl;
        if (!tkn_is_space_cp(tkn_utf8_cp((const U8 *)F->f + p, (const U8 *)F->f + F->flen, &cl)))
            break;
        p += cl;
    }
    return p;
}

/* The tokens matched at p: where they end, or -1. */
static IV
tkn_match_toks(const tkn_fold *F, SV *toks, STRLEN p)
{
    const char *t = SvPVX(toks), *te = t + SvCUR(toks);
    while (t < te) {
        char k = *t++;
        if (k == TKN_TOK_LIT) {
            U32 n;
            memcpy(&n, t, sizeof n);
            t += sizeof n;
            if (p + n > F->flen || memNE(F->f + p, t, n))
                return -1;
            p += n;
            t += n;
        }
        else if (k == TKN_TOK_WS1 || k == TKN_TOK_WS0) {
            STRLEN q = tkn_fskip_ws(F, p);
            if (k == TKN_TOK_WS1 && q == p)
                return -1;
            p = q;
        }
        else {
            if (p < F->flen && F->f[p] == '\'')
                p++;
            else if (p + 3 <= F->flen && memEQ(F->f + p, "\xE2\x80\x99", 3))
                p += 3;
            else
                return -1;
        }
    }
    return (IV)p;
}

static STRLEN
tkn_fnext(const tkn_fold *F, STRLEN p)
{
    STRLEN cl = UTF8SKIP((const U8 *)F->f + p);
    return p + cl > F->flen ? F->flen : p + cl;
}

static int
tkn_fhas_nl(const tkn_fold *F, STRLEN a, STRLEN b)
{
    return b > a && memchr(F->f + a, '\n', b - a) != NULL;
}

/* The end of [a, b) without its trailing white space. */
static STRLEN
tkn_ftrim_end(const tkn_fold *F, STRLEN a, STRLEN b)
{
    STRLEN last = a, p = a;
    while (p < b) {
        STRLEN cl;
        UV cp = tkn_utf8_cp((const U8 *)F->f + p, (const U8 *)F->f + F->flen, &cl);
        p += cl;
        if (!tkn_is_space_cp(cp))
            last = p;
    }
    return last;
}

static SV *
tkn_fsub(pTHX_ const tkn_fold *F, STRLEN a, STRLEN b)
{
    SV *sv = newSVpvn(F->t + F->off[a], F->off[b] - F->off[a]);
    SvUTF8_on(sv);
    return sv_2mortal(sv);
}

/* frame: the text inside a phrase's frame, or NULL. */
static SV *
tkn_frame_match(pTHX_ const tkn_fold *F, SV *pre, IV flags, SV *suf)
{
    STRLEN q = tkn_fskip_ws(F, 0), c;
    if (flags & TKN_F_PRE) {
        IV m = tkn_match_toks(F, pre, q);
        STRLEN q2;
        if (m < 0)
            return NULL;
        q2 = tkn_fskip_ws(F, (STRLEN)m);
        if ((flags & TKN_F_PRE_WS) && q2 == (STRLEN)m && (STRLEN)m != F->flen)
            return NULL;
        q = q2;
    }
    if (!(flags & TKN_F_SUF)) {
        STRLEN e = tkn_ftrim_end(F, q, F->flen);
        if (tkn_fhas_nl(F, q, e))
            return NULL;
        return tkn_fsub(aTHX_ F, q, e);
    }
    for (c = q;;) {
        STRLEN w = tkn_fskip_ws(F, c);
        if (!((flags & TKN_F_SUF_WS) && w == c)) {
            IV m = tkn_match_toks(F, suf, w);
            if (m >= 0 && tkn_fskip_ws(F, (STRLEN)m) == F->flen)
                return tkn_fsub(aTHX_ F, q, c);
        }
        if (c >= F->flen || F->f[c] == '\n')
            return NULL;
        c = tkn_fnext(F, c);
    }
}

/* split_on: the texts before and after a phrase between them. */
static int
tkn_split_match(pTHX_ const tkn_fold *F, SV *toks, IV sflags, SV **left, SV **right)
{
    STRLEN q = tkn_fskip_ws(F, 0), c = q;
    int before1 = sflags & 1, after1 = sflags & 2;
    while (c < F->flen) {
        STRLEN cl, w, a, e;
        UV cp = tkn_utf8_cp((const U8 *)F->f + c, (const U8 *)F->f + F->flen, &cl);
        IV m;
        if (cp == '\n')
            return 0;
        c += cl;
        if (tkn_is_space_cp(cp))
            continue;
        w = tkn_fskip_ws(F, c);
        if (before1 && w == c)
            continue;
        m = tkn_match_toks(F, toks, w);
        if (m < 0)
            continue;
        a = tkn_fskip_ws(F, (STRLEN)m);
        if (after1 && a == (STRLEN)m)
            continue;
        if (a >= F->flen)
            continue;
        e = tkn_ftrim_end(F, a, F->flen);
        if (tkn_fhas_nl(F, a, e))
            continue;
        *left = tkn_fsub(aTHX_ F, q, c);
        *right = tkn_fsub(aTHX_ F, a, e);
        return 1;
    }
    return 0;
}

static int
tkn_ends_apos(const char *b, STRLEN n)
{
    return (n && b[n - 1] == '\'') || (n >= 3 && memEQ(b + n - 3, "\xE2\x80\x99", 3));
}

/* [s, e) without white space at its start (front) and/or end (back). */
static void
tkn_trim_ws(const char **s, const char **e, int front, int back)
{
    STRLEN cl;
    while (front && *s < *e && tkn_is_space_cp(tkn_utf8_cp((const U8 *)*s, (const U8 *)*e, &cl)))
        *s += cl;
    while (back && *e > *s) {
        const char *q = *e - 1;
        while (q > *s && ((U8)*q & 0xC0) == 0x80)
            q--;
        if (!tkn_is_space_cp(tkn_utf8_cp((const U8 *)q, (const U8 *)*e, &cl)))
            break;
        *e = q;
    }
}

static int
tkn_has_nonspace(const char *s, const char *e)
{
    while (s < e) {
        STRLEN cl;
        if (!tkn_is_space_cp(tkn_utf8_cp((const U8 *)s, (const U8 *)e, &cl)))
            return 1;
        s += cl;
    }
    return 0;
}

/* A table part that is a CLDR word: what it means, or NULL. */
static SV *
tkn_cldr_word(pTHX_ tkn_lexicon *L, const char *s, const char *e)
{
    AV *out = (AV *)sv_2mortal((SV *)newAV());
    SV *part = sv_2mortal(newSVpvn(s, (STRLEN)(e - s))), **m;
    HV *hv;
    SV **v;
    SvUTF8_on(part);
    tkn_lookup_k(aTHX_ L, TKN_T_FIXED, TKN_T_COUNTED, tkn_key_sv(aTHX_ L, part), out);
    if (!(m = av_fetch(out, 0, 0)))
        return NULL;
    hv = (HV *)SvRV(*m);
    if ((v = hv_fetchs(hv, "field", 0))) {
        SV **n = hv_fetchs(hv, "n", 0);
        return sv_2mortal(newSVpvf("%" SVf " %" SVf, SVfARG(*v), SVfARG(n ? *n : &PL_sv_no)));
    }
    if ((v = hv_fetchs(hv, "weekday", 0)))
        return sv_2mortal(newSVpvf("weekday %" SVf, SVfARG(*v)));
    if ((v = hv_fetchs(hv, "month", 0)))
        return sv_2mortal(newSVpvf("month %" SVf, SVfARG(*v)));
    v = hv_fetchs(hv, "period", 0);
    return sv_2mortal(newSVpvf("period %" SVf, SVfARG(v ? *v : &PL_sv_no)));
}

/* "# test: TEXT => EXPECT", as 0.01's /^#\s*test:\s*(.+?)\s*=>\s*(\S.*?)\s*\z/. */
static int
tkn_test_line(pTHX_ const char *s, const char *e, SV **text, SV **want)
{
    const char *p = s + 1, *start, *j;
    if (s >= e || *s != '#')
        return 0;
    tkn_trim_ws(&p, &e, 1, 0);
    if (e - p < 5 || memNE(p, "test:", 5))
        return 0;
    p += 5;
    tkn_trim_ws(&p, &e, 1, 0);
    start = p;
    if (start >= e)
        return 0;
    for (j = start + UTF8SKIP((const U8 *)start); j + 2 <= e; j++) {
        const char *ce = j, *k, *we;
        if (j[0] != '=' || j[1] != '>')
            continue;
        tkn_trim_ws(&start, &ce, 0, 1);
        if (ce == start)
            ce = start + UTF8SKIP((const U8 *)start);
        k = j + 2;
        we = e;
        tkn_trim_ws(&k, &we, 1, 0);
        if (k >= we)
            continue;
        tkn_trim_ws(&k, &we, 0, 1);
        *text = sv_2mortal(newSVpvn(start, (STRLEN)(ce - start)));
        *want = sv_2mortal(newSVpvn(k, (STRLEN)(we - k)));
        SvUTF8_on(*text);
        SvUTF8_on(*want);
        return 1;
    }
    return 0;
}

/* Words->from_file: a table read, checked and compiled. */
static SV *
tkn_words_from_file(pTHX_ SV *klass, SV *file, SV *code, SV *forl)
{
    SV *lexsv = tkn_lexicon_for(aTHX_ sv_2mortal(newSVpvs("Time::Keeper::Natural::Lexicon")), SvOK(forl) ? forl : code);
    tkn_lexicon *L = tkn_lex(aTHX_ lexsv);
    SV *text = tkn_slurp(aTHX_ file, "Time::Keeper::Natural::Words");
    HV *self = newHV(), *phrases = newHV(), *seen = (HV *)sv_2mortal((SV *)newHV());
    AV *tests = newAV();
    SV *obj = sv_2mortal(newRV_noinc((SV *)self));
    const char *p = SvPVX(text), *end = p + SvCUR(text);
    IV lineno = 0;
    HE *he;
    sv_bless(obj, gv_stashsv(klass, GV_ADD));
    (void)hv_stores(self, "code", newSVsv(code));
    (void)hv_stores(self, "for", newSVsv(L->code));
    (void)hv_stores(self, "file", newSVsv(file));
    (void)hv_stores(self, "spaceless", newSViv(L->spaceless));
    (void)hv_stores(self, "tests", newRV_noinc((SV *)tests));
    (void)hv_stores(self, "phrases", newRV_noinc((SV *)phrases));
    while (p < end) {
        const char *nl = (const char *)memchr(p, '\n', (size_t)(end - p));
        const char *ls = p, *le = nl ? nl : end, *tab, *ks, *ke;
        SV *line, *t1, *t2, *key;
        AV *list;
        SV **lp;
        STRLEN i;
        p = nl ? nl + 1 : end;
        lineno++;
        line = sv_2mortal(newSVpvn(ls, (STRLEN)(le - ls)));
        {
            char *f = SvPVX(line);
            for (i = 0; i + 3 <= SvCUR(line); i++)
                if (memEQ(f + i, "\xEF\xBB\xBF", 3)) {
                    Move(f + i + 3, f + i, SvCUR(line) - i - 3, char);
                    SvCUR_set(line, SvCUR(line) - 3);
                    break;
                }
        }
        ls = SvPVX(line);
        le = ls + SvCUR(line);
        if (tkn_test_line(aTHX_ ls, le, &t1, &t2)) {
            AV *pair = newAV();
            av_push(pair, newSVsv(t1));
            av_push(pair, newSVsv(t2));
            av_push(tests, newRV_noinc((SV *)pair));
            continue;
        }
        {
            const char *q = ls, *qe = le;
            tkn_trim_ws(&q, &qe, 1, 0);
            if (q >= qe || *q == '#')
                continue;
        }
        tab = (const char *)memchr(ls, '\t', (size_t)(le - ls));
        ks = ls;
        ke = tab ? tab : le;
        {
            int ok = 0, k;
            for (k = 0; k < TKN_N_WORD_KEYS; k++)
                if ((STRLEN)(ke - ks) == strlen(tkn_word_keys[k]) && memEQ(ks, tkn_word_keys[k], ke - ks))
                    ok = 1;
            if (!ok)
                tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("Time::Keeper::Natural::Words: %" SVf " line %" IVdf ": '%" SVf "' is not a key; the keys are after, and, at, before, end_of, last, of, on, range, skip, start_of, weekend",
                      SVfARG(file), lineno, SVfARG(sv_2mortal(newSVpvn_flags(ks, (STRLEN)(ke - ks), SVf_UTF8))))));
        }
        key = sv_2mortal(newSVpvn(ks, (STRLEN)(ke - ks)));
        lp = hv_fetch(phrases, ks, (I32)(ke - ks), 0);
        if (lp)
            list = (AV *)SvRV(*lp);
        else {
            list = newAV();
            (void)hv_store(phrases, ks, (I32)(ke - ks), newRV_noinc((SV *)list), 0);
        }
        if (!tab || tab + 1 >= le)
            continue;
        {
            const char *r = tab + 1;
            while (r <= le) {
                const char *bar = (const char *)memchr(r, '|', (size_t)(le - r)), *re = bar ? bar : le;
                const char *rs = r, *rend = re, *z;
                SV *raw, *norm, *sk, *rec[7];
                AV *ph;
                int k;
                r = bar ? bar + 1 : le + 1;
                tkn_trim_ws(&rs, &rend, 1, 1);
                if (rs >= rend)
                    continue;
                raw = sv_2mortal(newSVpvn_flags(rs, (STRLEN)(rend - rs), SVf_UTF8));
                norm = tkn_normalise(aTHX_ raw, L->spaceless);
                sk = sv_2mortal(newSVsv(key));
                sv_catpvn(sk, "\0", 1);
                sv_catsv(sk, norm);
                if (hv_exists_ent(seen, sk, 0))
                    continue;
                (void)hv_store_ent(seen, sk, &PL_sv_yes, 0);
                for (z = rs; z + 3 <= rend; z++)
                    if (memEQ(z, "{0}", 3))
                        break;
                if ((SvCUR(key) == 5 && memEQ(SvPVX(key), "range", 5)) || (SvCUR(key) == 5 && memEQ(SvPVX(key), "after", 5))
                    || (SvCUR(key) == 6 && memEQ(SvPVX(key), "before", 6))) {
                    /* A range, text before {0}, between {0} and {1}, after {1};
                       after and before the same, a duration in {0} and a point
                       in {1}, or a point alone in {0} a day away ("the day
                       after {0}"). */
                    const char *o1 = NULL, *q;
                    SV *what = NULL;
                    IV flags = 0;
                    int one = 0;
                    for (q = z + 3; q + 3 <= rend; q++)
                        if (memEQ(q, "{1}", 3)) {
                            o1 = q;
                            break;
                        }
                    if (z + 3 <= rend && !o1 && SvPVX(key)[0] != 'r') {
                        one = 1;
                        o1 = z;
                    }
                    if (z + 3 > rend || !o1)
                        tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("Time::Keeper::Natural::Words: %" SVf ": the %" SVf " '%" SVf "' needs {0} and then {1}",
                              SVfARG(file), SVfARG(key), SVfARG(raw))));
                    if (tkn_has_nonspace(rs, z))
                        what = tkn_cldr_word(aTHX_ L, rs, z);
                    if (!what && !one && tkn_has_nonspace(z + 3, o1))
                        what = tkn_cldr_word(aTHX_ L, z + 3, o1);
                    if (!what && tkn_has_nonspace(o1 + 3, rend))
                        what = tkn_cldr_word(aTHX_ L, o1 + 3, rend);
                    if (what)
                        tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("Time::Keeper::Natural::Words: %" SVf ": '%" SVf "' is a CLDR word in %" SVf " (%" SVf "); a table may not take one",
                              SVfARG(file), SVfARG(raw), SVfARG(L->code), SVfARG(what))));
                    {
                        const char *a = rs, *b = z, *c = o1 + 3, *d = rend;
                        tkn_trim_ws(&a, &b, 1, 1);
                        tkn_trim_ws(&c, &d, 1, 1);
                        if (b > a)
                            flags |= TKN_F_PRE;
                        if (d > c)
                            flags |= TKN_F_SUF;
                        rec[0] = newSVsv(norm);
                        rec[1] = newSVsv(raw);
                        rec[2] = newSVsv(b > a ? tkn_lit(aTHX_ (const U8 *)a, (const U8 *)b, L->spaceless) : &PL_sv_undef);
                        rec[3] = newSViv(flags);
                        rec[4] = newSVsv(d > c ? tkn_lit(aTHX_ (const U8 *)c, (const U8 *)d, L->spaceless) : &PL_sv_undef);
                        rec[5] = one ? newSV(0) : newSVsv(tkn_lit(aTHX_ (const U8 *)z + 3, (const U8 *)o1, L->spaceless));
                        rec[6] = newSViv(0);
                    }
                }
                else {
                    int has0 = z + 3 <= rend;
                    const char *ps = rs, *pe = has0 ? z : rend, *ss = has0 ? z + 3 : NULL, *se = rend;
                    SV *what = NULL;
                    if (tkn_has_nonspace(ps, pe))
                        what = tkn_cldr_word(aTHX_ L, ps, pe);
                    if (!what && has0 && tkn_has_nonspace(ss, se))
                        what = tkn_cldr_word(aTHX_ L, ss, se);
                    if (what)
                        tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("Time::Keeper::Natural::Words: %" SVf ": '%" SVf "' is a CLDR word in %" SVf " (%" SVf "); a table may not take one",
                              SVfARG(file), SVfARG(raw), SVfARG(L->code), SVfARG(what))));
                    {
                        IV flags = 0;
                        SV *pre_t = &PL_sv_undef, *suf_t = &PL_sv_undef, *split_t = &PL_sv_undef;
                        IV sflags = 0;
                        const char *a = ps, *b = pe;
                        int pre_extra = 0;
                        if (!has0 && !L->spaceless && !tkn_ends_apos(rs, (STRLEN)(rend - rs)))
                            pre_extra = 1;
                        if (b > a || pre_extra) {
                            int ends_ws = pre_extra;
                            if (!pre_extra && b > a) {
                                const char *q = b - 1;
                                STRLEN cl;
                                while (q > a && ((U8)*q & 0xC0) == 0x80)
                                    q--;
                                ends_ws = tkn_is_space_cp(tkn_utf8_cp((const U8 *)q, (const U8 *)b, &cl));
                            }
                            flags |= TKN_F_PRE | (ends_ws ? TKN_F_PRE_WS : 0);
                            tkn_trim_ws(&a, &b, 0, 1);
                            pre_t = tkn_lit(aTHX_ (const U8 *)a, (const U8 *)b, L->spaceless);
                        }
                        if (has0 && se > ss) {
                            STRLEN cl;
                            const char *c2 = ss, *d2 = se;
                            int starts_ws = tkn_is_space_cp(tkn_utf8_cp((const U8 *)ss, (const U8 *)se, &cl));
                            flags |= TKN_F_SUF | (starts_ws ? TKN_F_SUF_WS : 0);
                            tkn_trim_ws(&c2, &d2, 1, 0);
                            suf_t = tkn_lit(aTHX_ (const U8 *)c2, (const U8 *)d2, L->spaceless);
                        }
                        if (!has0) {
                            split_t = tkn_lit(aTHX_ (const U8 *)rs, (const U8 *)rend, L->spaceless);
                            sflags = (L->spaceless ? 0 : 1) | (L->spaceless || tkn_ends_apos(rs, (STRLEN)(rend - rs)) ? 0 : 2);
                        }
                        rec[0] = newSVsv(norm);
                        rec[1] = newSVsv(raw);
                        rec[2] = newSVsv(pre_t);
                        rec[3] = newSViv(flags);
                        rec[4] = newSVsv(suf_t);
                        rec[5] = newSVsv(split_t);
                        rec[6] = newSViv(sflags);
                    }
                }
                ph = av_make(7, rec);
                for (k = 0; k < 7; k++)
                    SvREFCNT_dec(rec[k]);
                av_push(list, newRV_noinc((SV *)ph));
            }
        }
    }
    hv_iterinit(phrases);
    while ((he = hv_iternext(phrases))) {
        AV *list = (AV *)SvRV(HeVAL(he));
        I32 n = av_len(list) + 1, a, b;
        SV **arr = AvARRAY(list);
        for (a = 1; a < n; a++) {
            SV *x = arr[a];
            STRLEN xl, yl;
            const char *xs = SvPV_const(*av_fetch((AV *)SvRV(x), 0, 0), xl);
            STRLEN xc = tkn_char_len(xs, xl);
            b = a - 1;
            while (b >= 0) {
                const char *ys = SvPV_const(*av_fetch((AV *)SvRV(arr[b]), 0, 0), yl);
                if (tkn_char_len(ys, yl) >= xc)
                    break;
                arr[b + 1] = arr[b];
                b--;
            }
            arr[b + 1] = x;
        }
    }
    return obj;
}

/* Words->for: the table of a locale's first code in its chain that has
 * one, or undef. */
static SV *
tkn_words_for(pTHX_ SV *klass, SV *locale)
{
    dMY_CXT;
    SV *code;
    HE *he;
    if (SvOK(locale) && (he = hv_fetch_ent(MY_CXT.words, locale, 0, 0)))
        return HeVAL(he);
    code = tkn_code_of(aTHX_ locale, "Time::Keeper::Natural::Words");
    he = hv_fetch_ent(MY_CXT.words, code, 0, 0);
    SV *dir, *obj = NULL;
    AV *chain;
    I32 i;
    if (he)
        return HeVAL(he);
    dir = tkn_data_dir(aTHX_ 1);
    chain = tkn_chain(aTHX_ code);
    for (i = 0; dir && i <= av_len(chain); i++) {
        SV *c = *av_fetch(chain, i, 0);
        SV *file = sv_2mortal(newSVpvf("%" SVf "/%" SVf ".txt", SVfARG(dir), SVfARG(c)));
        if (!tkn_is_file(aTHX_ file))
            continue;
        obj = newSVsv(tkn_words_from_file(aTHX_ klass, file, c, code));
        break;
    }
    he = hv_store_ent(MY_CXT.words, code, obj ? obj : newSV(0), 0);
    return HeVAL(he);
}

/* A table's phrases for a key, or NULL. */
static AV *
tkn_phrases_of(pTHX_ SV *self, SV *key)
{
    HV *hv;
    SV **ph, **l;
    STRLEN kl;
    const char *k;
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Time::Keeper::Natural::Words: not a word table");
    hv = (HV *)SvRV(self);
    ph = hv_fetchs(hv, "phrases", 0);
    if (!ph || !SvROK(*ph) || !SvOK(key))
        return NULL;
    k = SvPV_const(key, kl);
    l = hv_fetch((HV *)SvRV(*ph), k, (I32)kl, 0);
    return l && SvROK(*l) ? (AV *)SvRV(*l) : NULL;
}

#endif
