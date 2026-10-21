#ifndef TKN_FIND_H
#define TKN_FIND_H

/* find: every mention of a time in a text, as Matches in text order. A
 * mention is a span the readers read whole, made only of words the locale
 * knows (its CLDR words, its number words, its table's phrases, the words
 * its formats write), longest first from the leftmost start, never
 * overlapping. It must hold a digit, a number word or one of CLDR's
 * relative words ("tomorrow", "next week"), unless names => 1 lets a
 * month or a weekday name alone be one. */

#define TKN_FIND_SPAN   12      /* tokens in a mention, at most */
#define TKN_FIND_CHARS  48      /* characters, in a spaceless locale */

#define TKN_FK_POINT    1
#define TKN_FK_DATE     2
#define TKN_FK_DURATION 4
#define TKN_FK_INTERVAL 8

typedef struct {
    STRLEN bs, be;      /* the token without its outer punctuation, in bytes */
    STRLEN rbs, re;     /* and with it */
    STRLEN cs, ce;      /* and in characters */
    int known, anchor, punct, digit, bad_end, bad_start, range_start, can_start, can_end;
} tkn_ftok;

/* Punctuation a mention does not begin with. */
static int
tkn_find_open(UV c)
{
    return c == '(' || c == '[' || c == '{' || c == '"' || c == '\'' || c == 0x201C || c == 0x2018 || c == 0xAB
        || c == 0x2039 || c == 0xBF || c == 0xA1 || c == 0x201E || c == 0x201A || c == 0x300C || c == 0x300E
        || c == 0xFF08 || c == 0x3010 || c == 0x3008 || c == 0x300A;
}

/* Punctuation a mention does not end with (a full stop may: "a.m."). */
static int
tkn_find_close(UV c)
{
    return c == ')' || c == ']' || c == '}' || c == '"' || c == '\'' || c == 0x201D || c == 0x2019 || c == 0xBB
        || c == 0x203A || c == ',' || c == ';' || c == ':' || c == '!' || c == '?' || c == 0x300D || c == 0x300F
        || c == 0xFF09 || c == 0x3011 || c == 0x3009 || c == 0x300B || c == 0x3002 || c == 0x3001 || c == 0xFF0C
        || c == 0xFF01 || c == 0xFF1F || c == 0xFF1A || c == 0xFF1B || c == 0x060C || c == 0x061F || c == 0x2E41;
}

/* A character a spaceless mention may hold besides the locale's words:
 * ASCII punctuation a date or a time is written with. */
static int
tkn_find_glue(UV c)
{
    return c == ':' || c == '/' || c == '.' || c == '-' || c == '+' || c == ',' || c == '~' || c == 0xFF5E
        || c == 0x2013 || c == 0x2014 || c == 0x301C;
}

static void
tkn_find_add_tokens(pTHX_ HV *set, const char *k, STRLEN n, int spaceless)
{
    STRLEN a = 0, q;
    for (q = 0; q <= n; q++) {
        if (q < n && k[q] != ' ' && k[q] != '\0')
            continue;
        if (q > a) {
            if (spaceless) {
                STRLEN c = a;
                while (c < q) {
                    STRLEN cl = UTF8SKIP((const U8 *)k + c);
                    if (c + cl > q)
                        cl = q - c;
                    (void)hv_store(set, k + c, -(I32)cl, &PL_sv_yes, 0);
                    c += cl;
                }
            }
            else
                (void)hv_store(set, k + a, -(I32)(q - a), &PL_sv_yes, 0);
        }
        a = q + 1;
    }
}

/* In a spaceless locale, the characters a word can begin and end with:
 * each piece of [s, e) between spaces, its first and its last. */
static void
tkn_find_edges(pTHX_ HV *starts, HV *ends, const char *s, const char *e, int first, int last)
{
    const char *p = s;
    while (p < e) {
        const char *w = p, *lc;
        while (p < e && *p != ' ')
            p++;
        if (p > w) {
            lc = p - 1;
            while (lc > w && ((U8)*lc & 0xC0) == 0x80)
                lc--;
            if (first || w > s)
                (void)hv_store(starts, w, -(I32)UTF8SKIP((const U8 *)w), &PL_sv_yes, 0);
            if (last || p < e)
                (void)hv_store(ends, lc, -(I32)(p - lc), &PL_sv_yes, 0);
        }
        while (p < e && *p == ' ')
            p++;
    }
}

/* A text's words added to a set, and in a spaceless locale its edges
 * (first: it begins a word; last: it ends one). */
static void
tkn_find_add_key(pTHX_ tkn_lexicon *L, HV *set, SV *text, HV *starts, HV *ends, int first, int last)
{
    STRLEN n;
    SV *k = tkn_key_sv(aTHX_ L, text);
    const char *b = tkn_utf8_bytes(aTHX_ k, &n);
    tkn_find_add_tokens(aTHX_ set, b, n, L->spaceless);
    if (L->spaceless && starts)
        tkn_find_edges(aTHX_ starts, ends, b, b + n, first, last);
}

/* The words a locale's mentions are made of, and its relative words:
 * [known, relative tokens, relative phrases], built once a locale. */
static AV *
tkn_find_vocab(pTHX_ tkn_lexicon *L, SV *words, SV *anchor)
{
    static const char *const fields[8] = { "year", "quarter", "month", "week", "day", "hour", "minute", "second" };
    static const char *const ws[3] = { "long", "short", "narrow" };
    dMY_CXT;
    HE *he = hv_fetch_ent(MY_CXT.known, L->code, 0, 0);
    AV *out, *rel;
    HV *known, *rtok, *starts, *ends;
    int t, f, w;
    U32 i;
    if (he)
        return (AV *)SvRV(HeVAL(he));
    out = newAV();
    known = newHV();
    rtok = newHV();
    rel = newAV();
    av_push(out, newRV_noinc((SV *)known));
    av_push(out, newRV_noinc((SV *)rtok));
    av_push(out, newRV_noinc((SV *)rel));
    (void)hv_store_ent(MY_CXT.known, L->code, newRV_noinc((SV *)out), 0);
    starts = (HV *)sv_2mortal((SV *)newHV());
    ends = (HV *)sv_2mortal((SV *)newHV());
    if (!L->ordinals_read) {
        L->ordinals_read = 1;
        tkn_number_words(aTHX_ L, TKN_T_ORDINALS, "ordinals");
    }
    /* every key of the lexicon, a counted one's text either side of its number */
    for (t = 0; t < TKN_T_N; t++) {
        if (t == TKN_T_NUM_CHAR)
            continue;
        for (i = 0; i < L->t[t].cap; i++) {
            const tkn_slot *s = &L->t[t].s[i];
            const char *kb, *z;
            if (s->off == TKN_EMPTY)
                continue;
            kb = L->arena + s->off;
            tkn_find_add_tokens(aTHX_ known, kb, s->len, L->spaceless);
            if (!L->spaceless)
                continue;
            /* a counted key is the text either side of its number */
            if ((z = (const char *)memchr(kb, '\0', s->len))) {
                tkn_find_edges(aTHX_ starts, ends, kb, z, 1, 0);
                tkn_find_edges(aTHX_ starts, ends, z + 1, kb + s->len, 0, 1);
            }
            else
                tkn_find_edges(aTHX_ starts, ends, kb, kb + s->len, 1, 1);
        }
    }
    /* the words the locale's formats write, a day in each month, each a
       different weekday and hour (every month's name, every day period's) */
    {
        time_keeper_zone z;
        time_keeper_civil c;
        int lid = tkn_locale_id(aTHX_ L), d;
        char buf[512];
        tkn_patterns_of(aTHX_ L);
        if ((TKN_TK->zone_parse)(aTHX_ "UTC", 3, &z) == TIME_KEEPER_OK)
            for (d = 0; d < 12; d++) {
                time_keeper_instant in;
                I32 j;
                Zero(&c, 1, time_keeper_civil);
                c.year = 2026;
                c.month = d + 1;
                c.day = d + 1;
                c.hour = (d * 2 + 1) % 24;
                c.minute = 5;
                if ((TKN_TK->from_civil)(aTHX_ &c, &z, TIME_KEEPER_GAP_FORWARD, TIME_KEEPER_OVERLAP_EARLIER, &in) != TIME_KEEPER_OK)
                    continue;
                for (j = 0; j <= av_len(L->patterns); j++) {
                    SV *pat = tkn_hsv(aTHX_ (HV *)SvRV(*av_fetch(L->patterns, j, 0)), "pattern");
                    STRLEN pl;
                    const char *pb;
                    size_t n;
                    if (!pat)
                        continue;
                    pb = SvPV_const(pat, pl);
                    n = (TKN_TK->format)(aTHX_ buf, sizeof buf, pb, pl, &in, &z, lid);
                    if (n && n < sizeof buf)
                        tkn_find_add_key(aTHX_ L, known, sv_2mortal(newSVpvn_flags(buf, n, SVf_UTF8)), starts, ends, 1, 1);
                }
            }
    }
    /* every word of the locale's zone names ("GMT", "غرينتش", "Central European
       Summer Time") */
    {
        HV *zw = tkn_zone_words(aTHX_ L, anchor);
        HE *e;
        hv_iterinit(zw);
        while ((e = hv_iternext(zw))) {
            STRLEN kl;
            const char *kb = HePV(e, kl);
            if (kl && kb[0] == '\1')
                continue;
            if (kl && kb[0] == '\2') {
                kb++;
                kl--;
            }
            if (kl) {
                tkn_find_add_tokens(aTHX_ known, kb, kl, L->spaceless);
                if (L->spaceless)
                    tkn_find_edges(aTHX_ starts, ends, kb, kb + kl, 1, 1);
            }
        }
    }
    /* CLDR's relative words: "tomorrow", "next week" */
    for (f = 0; f < 8; f++)
        for (w = 0; w < 3; w++) {
            SV *args[3], *at;
            HE *e;
            args[0] = L->code;
            args[1] = sv_2mortal(newSVpv(fields[f], 0));
            args[2] = sv_2mortal(newSVpv(ws[w], 0));
            at = tkn_hget(aTHX_ tkn_call1(aTHX_ TKN_LOC, "relative_names", args, 3), "at");
            if (!at || !SvROK(at) || SvTYPE(SvRV(at)) != SVt_PVHV)
                continue;
            hv_iterinit((HV *)SvRV(at));
            while ((e = hv_iternext((HV *)SvRV(at)))) {
                SV *k = tkn_key_sv(aTHX_ L, HeVAL(e));
                STRLEN kl;
                const char *kb = tkn_utf8_bytes(aTHX_ k, &kl);
                if (!kl)
                    continue;
                tkn_find_add_tokens(aTHX_ known, kb, kl, L->spaceless);
                if (L->spaceless) {
                    av_push(rel, newSVpvn_flags(kb, kl, SVf_UTF8));
                    tkn_find_edges(aTHX_ starts, ends, kb, kb + kl, 1, 1);
                }
                else
                    tkn_find_add_tokens(aTHX_ rtok, kb, kl, 0);
            }
        }
    /* the word table's phrases: a word that stands only before a slot (or
       before what a frame takes) cannot end a mention ("to", "of", ja "の"),
       one that stands only after one cannot begin it; a word CLDR has
       too is either */
    if (tkn_words_ok(words)) {
        SV **ph = hv_fetchs((HV *)SvRV(words), "phrases", 0);
        HV *tw = (HV *)sv_2mortal((SV *)newHV()), *be = (HV *)sv_2mortal((SV *)newHV()), *bs = (HV *)sv_2mortal((SV *)newHV()),
           *rs = (HV *)sv_2mortal((SV *)newHV()), *okst = (HV *)sv_2mortal((SV *)newHV()), *oken = (HV *)sv_2mortal((SV *)newHV());
        AV *apre = newAV(), *asuf = newAV();
        (void)hv_stores(known, "\3", newRV_noinc((SV *)apre));
        (void)hv_stores(known, "\4", newRV_noinc((SV *)asuf));
        HE *e;
        if (ph && SvROK(*ph)) {
            hv_iterinit((HV *)SvRV(*ph));
            while ((e = hv_iternext((HV *)SvRV(*ph)))) {
                AV *list = (AV *)SvRV(HeVAL(e));
                const char *kn = HePV(e, PL_na);
                int infix_key = strEQ(kn, "of") || strEQ(kn, "and"), plain = strEQ(kn, "weekend") || strEQ(kn, "alias");
                I32 j;
                for (j = 0; j <= av_len(list); j++) {
                    SV *raw = *av_fetch((AV *)SvRV(*av_fetch(list, j, 0)), 1, 0);
                    STRLEN rl;
                    const char *rb = SvPV_const(raw, rl), *p = rb, *z = rb + rl;
                    int slots = 0, seg = 0;
                    const char *q;
                    for (q = rb; q < z; q++)
                        if (*q == '{' && memchr(q, '}', (size_t)(z - q)))
                            slots++;
                    while (p <= z) {
                        const char *o = p;
                        SV *part;
                        HV *toks = (HV *)sv_2mortal((SV *)newHV());
                        HE *te;
                        int prefix, suffix;
                        while (o < z && !(*o == '{' && memchr(o, '}', (size_t)(z - o))))
                            o++;
                        part = sv_2mortal(newSVpvn_flags(p, (STRLEN)(o - p), SVf_UTF8));
                        {
                            char *x = SvPVX(part), *xe = x + SvCUR(part);
                            for (; x < xe; x++)
                                if (*x == '!' || *x == '=' || *x == '|')
                                    *x = ' ';
                        }
                        tkn_find_add_key(aTHX_ L, toks, part, starts, ends, plain || !seg, plain || o >= z);
                        if (!L->spaceless && !plain && SvCUR(part)) {
                            /* a particle written onto the next word or the last */
                            const char *x = SvPVX(part), *xe = x + SvCUR(part), *w;
                            int apos = xe[-1] == '\'' || (SvCUR(part) >= 3 && memEQ(xe - 3, "\xE2\x80\x99", 3));
                            if (apos || (seg < slots && xe[-1] != ' ')) {
                                for (w = xe; w > x && w[-1] != ' '; w--)
                                    ;
                                av_push(apre, newSVsv(tkn_key_sv(aTHX_ L, sv_2mortal(newSVpvn_flags(w, (STRLEN)(xe - w), SVf_UTF8)))));
                            }
                            if (seg > 0 && x[0] != ' ') {
                                for (w = x; w < xe && *w != ' '; w++)
                                    ;
                                av_push(asuf, newSVsv(tkn_key_sv(aTHX_ L, sv_2mortal(newSVpvn_flags(x, (STRLEN)(w - x), SVf_UTF8)))));
                            }
                        }
                        if (plain || !slots) {
                            prefix = !plain && !infix_key;
                            suffix = !plain && infix_key;
                            if (infix_key)
                                prefix = 1;
                        }
                        else {
                            prefix = seg < slots;
                            suffix = seg > 0;
                        }
                        hv_iterinit(toks);
                        while ((te = hv_iternext(toks))) {
                            SV *tk = hv_iterkeysv(te);
                            (void)hv_store_ent(tw, tk, &PL_sv_yes, 0);
                            if (hv_exists_ent(known, tk, 0))
                                continue;
                            if (prefix)
                                (void)hv_store_ent(be, tk, &PL_sv_yes, 0);
                            if (suffix)
                                (void)hv_store_ent(bs, tk, &PL_sv_yes, 0);
                            /* a word some phrase begins or ends with may begin or end a mention */
                            if (plain || (!seg && (slots || !infix_key)))
                                (void)hv_store_ent(okst, tk, &PL_sv_yes, 0);
                            if (plain || (slots && seg == slots))
                                (void)hv_store_ent(oken, tk, &PL_sv_yes, 0);
                            /* "from", "between": they begin only a range */
                            if (strEQ(kn, "range") && slots && !seg)
                                (void)hv_store_ent(rs, tk, &PL_sv_yes, 0);
                        }
                        if (o >= z)
                            break;
                        p = (const char *)memchr(o, '}', (size_t)(z - o)) + 1;
                        seg++;
                    }
                }
            }
        }
        {
            HV *bad_end = newHV(), *bad_start = newHV(), *range_start = newHV();
            HE *te;
            hv_iterinit(tw);
            while ((te = hv_iternext(tw)))
                (void)hv_store_ent(known, hv_iterkeysv(te), &PL_sv_yes, 0);
            hv_iterinit(be);
            while ((te = hv_iternext(be)))
                if (!hv_exists_ent(oken, hv_iterkeysv(te), 0))
                    (void)hv_store_ent(bad_end, hv_iterkeysv(te), &PL_sv_yes, 0);
            hv_iterinit(bs);
            while ((te = hv_iternext(bs)))
                if (!hv_exists_ent(okst, hv_iterkeysv(te), 0))
                    (void)hv_store_ent(bad_start, hv_iterkeysv(te), &PL_sv_yes, 0);
            hv_iterinit(rs);
            while ((te = hv_iternext(rs)))
                (void)hv_store_ent(range_start, hv_iterkeysv(te), &PL_sv_yes, 0);
            av_push(out, newRV_noinc((SV *)bad_end));
            av_push(out, newRV_noinc((SV *)bad_start));
            av_push(out, newRV_noinc((SV *)range_start));
        }
    }
    else {
        av_push(out, newRV_noinc((SV *)newHV()));
        av_push(out, newRV_noinc((SV *)newHV()));
        av_push(out, newRV_noinc((SV *)newHV()));
    }
    av_push(out, newRV_inc((SV *)starts));
    av_push(out, newRV_inc((SV *)ends));
    return out;
}

/* A digit of any script, or a number word, in a key. */
static int
tkn_find_numeric(pTHX_ tkn_lexicon *L, SV *k)
{
    STRLEN kl, i;
    SV *d = tkn_ascii_digits(aTHX_ k, L->has_digits ? L->digits : NULL);
    const char *kb = SvPV_const(d, kl);
    for (i = 0; i < kl; i++)
        if (isDIGIT_A(kb[i]))
            return 1;
    kb = tkn_utf8_bytes(aTHX_ k, &kl);
    if (L->spaceless) {
        for (i = 0; i < kl; i += UTF8SKIP((const U8 *)kb + i))
            if (tkn_tfind(L, &L->t[TKN_T_NUM_CHAR], kb + i, UTF8SKIP((const U8 *)kb + i)) >= 0)
                return 1;
        return 0;
    }
    return tkn_tfind(L, &L->t[TKN_T_NUMBERS], kb, kl) >= 0 || tkn_tfind(L, &L->t[TKN_T_ORDINALS], kb, kl) >= 0
        || tkn_tfind(L, &L->t[TKN_T_NUM_TOK], kb, kl) >= 0;
}

/* A word with a table's particle on it: an elided article or preposition
 * before ("d'octobre", "l'ultimo"), a case ending after ("মাসের", "화요일에"),
 * the rest a known word. The particles are under "\3" and "\4". */
static int
tkn_find_affixed(pTHX_ HV *known, const char *w, STRLEN n)
{
    SV **pre = hv_fetchs(known, "\3", 0), **suf = hv_fetchs(known, "\4", 0);
    I32 i;
    if (pre && SvROK(*pre))
        for (i = 0; i <= av_len((AV *)SvRV(*pre)); i++) {
            STRLEN pl;
            const char *pb = SvPV_const(*av_fetch((AV *)SvRV(*pre), i, 0), pl);
            if (pl < n && memEQ(w, pb, pl) && hv_exists(known, w + pl, -(I32)(n - pl)))
                return 1;
        }
    if (suf && SvROK(*suf))
        for (i = 0; i <= av_len((AV *)SvRV(*suf)); i++) {
            STRLEN sl;
            const char *sb = SvPV_const(*av_fetch((AV *)SvRV(*suf), i, 0), sl);
            if (sl < n && memEQ(w + n - sl, sb, sl) && hv_exists(known, w, -(I32)(n - sl)))
                return 1;
        }
    return 0;
}

/* Every part of a token's key is a known word, a number or punctuation. */
static int
tkn_find_known(pTHX_ tkn_lexicon *L, HV *known, SV *k)
{
    STRLEN kl, a = 0, q;
    const char *kb = tkn_utf8_bytes(aTHX_ k, &kl);
    for (q = 0; q <= kl; q++) {
        if (q < kl && kb[q] != ' ')
            continue;
        if (q > a && !hv_exists(known, kb + a, -(I32)(q - a))) {
            SV *part = sv_2mortal(newSVpvn_flags(kb + a, q - a, SVf_UTF8));
            if (tkn_has_letter(aTHX_ part) && !tkn_find_numeric(aTHX_ L, part) && !strchr(SvPV_nolen(part), '/')
                && !tkn_find_affixed(aTHX_ known, kb + a, q - a))
                return 0;
        }
        a = q + 1;
    }
    return 1;
}

/* An anchor of M8 in a spaced token: a number, a number word, or a word
 * of one of CLDR's relative phrases. */
static int
tkn_find_anchor_tok(pTHX_ tkn_lexicon *L, HV *rtok, SV *k)
{
    STRLEN kl, a = 0, q;
    const char *kb;
    if (tkn_find_numeric(aTHX_ L, k))
        return 1;
    kb = tkn_utf8_bytes(aTHX_ k, &kl);
    for (q = 0; q <= kl; q++) {
        if (q < kl && kb[q] != ' ')
            continue;
        if (q > a && (hv_exists(rtok, kb + a, -(I32)(q - a)) || tkn_find_numeric(aTHX_ L, sv_2mortal(newSVpvn_flags(kb + a, q - a, SVf_UTF8)))))
            return 1;
        a = q + 1;
    }
    return 0;
}

/* A spaceless span holds an anchor: a digit, a number character, or a
 * whole relative phrase of CLDR's. */
static int
tkn_find_anchor_span(pTHX_ tkn_lexicon *L, AV *rel, SV *span)
{
    SV *k = tkn_key_sv(aTHX_ L, span);
    STRLEN kl;
    const char *kb;
    I32 i;
    if (tkn_find_numeric(aTHX_ L, k))
        return 1;
    kb = tkn_utf8_bytes(aTHX_ k, &kl);
    for (i = 0; i <= av_len(rel); i++) {
        STRLEN rl;
        const char *rb = SvPV_const(*av_fetch(rel, i, 0), rl);
        if (rl && rl <= kl && ninstr(kb, kb + kl, rb, rb + rl))
            return 1;
    }
    return 0;
}

/* The text cut into tokens: words in a spaced locale, characters in a
 * spaceless one, each without its outer punctuation. */
static tkn_ftok *
tkn_find_tokens(pTHX_ tkn_lexicon *L, const char *b, STRLEN n, I32 *count)
{
    tkn_ftok *T;
    I32 nt = 0;
    STRLEN p = 0, ch = 0;
    Newxz(T, n + 1, tkn_ftok);
    SAVEFREEPV(T);
    while (p < n) {
        STRLEN cl;
        UV c = tkn_utf8_cp((const U8 *)b + p, (const U8 *)b + n, &cl);
        if (tkn_is_space_cp(c)) {
            p += cl;
            ch++;
            continue;
        }
        if (L->spaceless) {
            T[nt].bs = T[nt].rbs = p;
            T[nt].be = T[nt].re = p + cl;
            T[nt].cs = ch;
            T[nt].ce = ch + 1;
            T[nt].punct = tkn_find_glue(c);
            nt++;
            p += cl;
            ch++;
            continue;
        }
        {
            STRLEN s = p, sc = ch, e, ec;
            T[nt].rbs = p;
            while (p < n) {
                c = tkn_utf8_cp((const U8 *)b + p, (const U8 *)b + n, &cl);
                if (tkn_is_space_cp(c))
                    break;
                p += cl;
                ch++;
            }
            e = p;
            ec = ch;
            T[nt].re = p;
            /* outer punctuation off */
            while (s < e) {
                c = tkn_utf8_cp((const U8 *)b + s, (const U8 *)b + e, &cl);
                if (!tkn_find_open(c))
                    break;
                s += cl;
                sc++;
            }
            while (e > s) {
                const char *q = b + e - 1;
                while (q > b + s && ((U8)*q & 0xC0) == 0x80)
                    q--;
                c = tkn_utf8_cp((const U8 *)q, (const U8 *)b + e, &cl);
                if (!tkn_find_close(c))
                    break;
                e = (STRLEN)(q - b);
                ec--;
            }
            T[nt].bs = s;
            T[nt].be = e;
            T[nt].cs = sc;
            T[nt].ce = ec;
            T[nt].punct = e == s;
            nt++;
        }
    }
    *count = nt;
    return T;
}

/* What stands between an interval's two ends in a locale, normalised:
 * each interval format's separator, the table's range words, the
 * fallback's dash, a hyphen and a slash. Worked out once a locale. */
static AV *
tkn_find_seps(pTHX_ tkn_lexicon *L, SV *words)
{
    dMY_CXT;
    SV *mk = sv_2mortal(newSVpvf("is\1%" SVf, SVfARG(L->code))), *all;
    HE *he = hv_fetch_ent(MY_CXT.memo, mk, 0, 0);
    AV *seps;
    HV *seen;
    int swap = 0;
    if (he)
        return (AV *)SvRV(HeVAL(he));
    seps = newAV();
    (void)hv_store_ent(MY_CXT.memo, mk, newRV_noinc((SV *)seps), 0);
    seen = (HV *)sv_2mortal((SV *)newHV());
#define TKN_FIND_SEP(sv) do {                                                        \
        SV *k_ = tkn_key_sv(aTHX_ L, (sv));                                          \
        if (SvCUR(k_) && !hv_exists_ent(seen, k_, 0)) {                              \
            (void)hv_store_ent(seen, k_, &PL_sv_yes, 0);                             \
            av_push(seps, newSVsv(k_));                                              \
        }                                                                            \
    } while (0)
    TKN_FIND_SEP(sv_2mortal(newSVpvs("-")));
    TKN_FIND_SEP(sv_2mortal(newSVpvs("/")));
    {
        SV *dash = tkn_fallback_dash(aTHX_ L, &swap);
        if (dash)
            TKN_FIND_SEP(dash);
    }
    all = tkn_call1(aTHX_ TKN_LOC, "interval_formats", &L->code, 1);
    if (tkn_hv_of(all)) {
        HE *e;
        hv_iterinit(tkn_hv_of(all));
        while ((e = hv_iternext(tkn_hv_of(all)))) {
            HV *by = tkn_hv_of(HeVAL(e));
            HE *pe;
            if (!by)
                continue;
            hv_iterinit(by);
            while ((pe = hv_iternext(by))) {
                SV *p = HeVAL(pe), *p1, *sep, *p2;
                STRLEN pl;
                const char *pb;
                if (!SvOK(p))
                    continue;
                pb = SvPV_const(p, pl);
                if (tkn_pat_split(aTHX_ pb, pl, &p1, &sep, &p2)) {
                    if (SvUTF8(p))
                        SvUTF8_on(sep);
                    TKN_FIND_SEP(sep);
                }
            }
        }
    }
    if (tkn_words_ok(words)) {
        AV *list = tkn_phrases_of(aTHX_ words, sv_2mortal(newSVpvs("range")));
        I32 i;
        for (i = 0; list && i <= av_len(list); i++) {
            static const char s0[] = "{0}", s1[] = "{1}";
            STRLEN rl;
            const char *rb = SvPV_const(*av_fetch((AV *)SvRV(*av_fetch(list, i, 0)), 1, 0), rl);
            const char *o = ninstr(rb, rb + rl, s0, s0 + 3), *t = o ? ninstr(o + 3, rb + rl, s1, s1 + 3) : NULL;
            if (o && t && t > o + 3)
                TKN_FIND_SEP(sv_2mortal(newSVpvn_flags(o + 3, (STRLEN)(t - o - 3), SVf_UTF8)));
        }
    }
#undef TKN_FIND_SEP
    return seps;
}

/* A span holds one of the locale's interval separators: a word one as a
 * whole word in a spaced locale. */
static int
tkn_find_has_sep(pTHX_ tkn_lexicon *L, AV *seps, SV *span)
{
    SV *k = tkn_key_sv(aTHX_ L, span);
    STRLEN kl;
    const char *kb = tkn_utf8_bytes(aTHX_ k, &kl);
    I32 i;
    for (i = 0; i <= av_len(seps); i++) {
        STRLEN sl;
        const char *sb = SvPV_const(*av_fetch(seps, i, 0), sl), *x = kb;
        int word = !L->spaceless && sl && (isALPHA_A(sb[0]) || (U8)sb[0] >= 0xC0);
        while ((x = ninstr(x, kb + kl, sb, sb + sl))) {
            /* a word separator is one at a word's edge, written on ("و5", "월요일부터") or apart */
            if (!word || x == kb || x[-1] == ' ' || x + sl == kb + kl || x[sl] == ' ')
                return 1;
            x++;
        }
    }
    return 0;
}

/* A span read by the kinds asked for: the kind, the value, an interval's
 * end and the info; NULL when none reads. */
static SV *
tkn_find_read(pTHX_ SV *self, SV *method, SV *span, int kinds, int multi, const char **kind, SV **to, HV **info)
{
    SV *v;
    *to = NULL;
    if (kinds & (TKN_FK_POINT | TKN_FK_DATE)) {
        if ((v = tkn_point(aTHX_ self, method, span, info))) {
            if (kinds & TKN_FK_POINT)
                *kind = "point";
            else {
                if (!get_cv("Time::Keeper::Date::new", 0))
                    load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("Time::Keeper::Date"), NULL);
                v = tkn_method(aTHX_ v, "to_date", NULL, 0);
                *kind = "date";
            }
            return v;
        }
    }
    if ((kinds & TKN_FK_INTERVAL) && multi) {
        dMY_CXT;
        SV *s = NULL, *e = NULL;
        SAVEINT(MY_CXT.quiet);
        if (kinds & (TKN_FK_POINT | TKN_FK_DATE))
            MY_CXT.quiet = 2;
        tkn_interval(aTHX_ self, method, span, &s, &e, info);
        MY_CXT.quiet = 1;
        if (s && e) {
            *kind = "interval";
            *to = e;
            return s;
        }
    }
    if (kinds & TKN_FK_DURATION) {
        if ((v = tkn_duration(aTHX_ self, method, span, info))) {
            *kind = "duration";
            return v;
        }
    }
    return NULL;
}

/* find: the mentions, longest from the leftmost start. */
static AV *
tkn_find(pTHX_ SV *self, SV *text, int kinds, int names)
{
    dMY_CXT;
    SV *lexsv, *words, *method = sv_2mortal(newSVpvs("find"));
    tkn_lexicon *L;
    AV *vocab, *rel, *seps, *out = (AV *)sv_2mortal((SV *)newAV());
    HV *known, *rtok, *bad_end, *bad_start, *range_start, *starts, *ends;
    STRLEN n;
    const char *b;
    tkn_ftok *T;
    I32 nt, i, *anchors;
    if (!SvOK(text))
        tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvs("Time::Keeper::Natural->find: the text is undefined")));
    b = tkn_utf8_bytes(aTHX_ text, &n);
    tkn_lex_words(aTHX_ self, &lexsv, &words);
    L = tkn_lex(aTHX_ lexsv);
    vocab = tkn_find_vocab(aTHX_ L, words, tkn_anchor(aTHX_ self));
    known = (HV *)SvRV(*av_fetch(vocab, 0, 0));
    rtok = (HV *)SvRV(*av_fetch(vocab, 1, 0));
    rel = (AV *)SvRV(*av_fetch(vocab, 2, 0));
    bad_end = (HV *)SvRV(*av_fetch(vocab, 3, 0));
    bad_start = (HV *)SvRV(*av_fetch(vocab, 4, 0));
    range_start = (HV *)SvRV(*av_fetch(vocab, 5, 0));
    starts = (HV *)SvRV(*av_fetch(vocab, 6, 0));
    ends = (HV *)SvRV(*av_fetch(vocab, 7, 0));
    seps = tkn_find_seps(aTHX_ L, words);
    T = tkn_find_tokens(aTHX_ L, b, n, &nt);
    Newxz(anchors, nt + 1, I32);
    SAVEFREEPV(anchors);
    for (i = 0; i < nt; i++) {
        SV *tk = sv_2mortal(newSVpvn_flags(b + T[i].bs, T[i].be - T[i].bs, SVf_UTF8));
        SV *k = T[i].punct ? NULL : tkn_key_sv(aTHX_ L, tk);
        if (T[i].punct)
            T[i].known = 1;
        else if (L->spaceless)
            T[i].known = hv_exists(known, SvPVX(k), -(I32)SvCUR(k)) || tkn_find_numeric(aTHX_ L, k);
        else
        {
            STRLEN tl = T[i].be - T[i].bs, x;
            const char *tb = b + T[i].bs;
            int caps = tl >= 2 && tl <= 6;
            for (x = 0; caps && x < tl; x++)
                if (!(tb[x] >= 'A' && tb[x] <= 'Z'))
                    caps = 0;
            /* a zone's abbreviation ("EST"), or a word at a sentence's end ("pm.") */
            T[i].known = caps || tkn_find_known(aTHX_ L, known, k)
                || (T[i].re - T[i].rbs > tl
                    && tkn_find_known(aTHX_ L, known, tkn_key_sv(aTHX_ L, sv_2mortal(newSVpvn_flags(b + T[i].rbs, T[i].re - T[i].rbs, SVf_UTF8)))))
                || (tl > 1 && tb[tl - 1] == '.'
                    && tkn_find_known(aTHX_ L, known, tkn_key_sv(aTHX_ L, sv_2mortal(newSVpvn_flags(tb, tl - 1, SVf_UTF8)))));
        }
        T[i].anchor = !T[i].punct && !L->spaceless && T[i].known
            && (tkn_find_anchor_tok(aTHX_ L, rtok, k)
                || (T[i].be - T[i].bs > 1 && b[T[i].be - 1] == '.'
                    && tkn_find_anchor_tok(aTHX_ L, rtok, tkn_key_sv(aTHX_ L, sv_2mortal(newSVpvn_flags(b + T[i].bs, T[i].be - T[i].bs - 1, SVf_UTF8))))));
        if (k) {
            T[i].bad_end = hv_exists(bad_end, SvPVX(k), -(I32)SvCUR(k));
            T[i].bad_start = hv_exists(bad_start, SvPVX(k), -(I32)SvCUR(k));
            T[i].range_start = hv_exists(range_start, SvPVX(k), -(I32)SvCUR(k));
            T[i].digit = L->spaceless && tkn_find_numeric(aTHX_ L, k);
            T[i].can_start = !L->spaceless || T[i].digit || hv_exists(starts, SvPVX(k), -(I32)SvCUR(k));
            T[i].can_end = !L->spaceless || T[i].digit || hv_exists(ends, SvPVX(k), -(I32)SvCUR(k));
        }
        anchors[i + 1] = anchors[i] + T[i].anchor;
    }
    ENTER;
    SAVEINT(MY_CXT.quiet);
    MY_CXT.quiet = 1;
    i = 0;
    while (i < nt) {
        I32 r = i, j, most;
        int found = 0;
        if (!T[i].known || T[i].punct || T[i].bad_start || !T[i].can_start || (i > 0 && T[i].digit && T[i - 1].digit && T[i - 1].known)) {
            i++;
            continue;
        }
        while (r + 1 < nt && T[r + 1].known)
            r++;
        most = L->spaceless ? TKN_FIND_CHARS : TKN_FIND_SPAN;
        for (j = i + most - 1 < r ? i + most - 1 : r; j >= i && !found; j--) {
            STRLEN be = T[j].be, ext = 0;
            int tries, extc = 0;
            if ((T[j].punct && j > i) || T[j].bad_end || !T[j].can_end || (j + 1 < nt && T[j].digit && T[j + 1].digit))
                continue;
            if (!names && !L->spaceless && anchors[j + 1] == anchors[i])
                continue;
            {
                /* a bracket the span opens takes its closer ("15:05 (GMT)") */
                STRLEN q;
                int round = 0, square = 0;
                for (q = T[i].bs; q < be; q++) {
                    round += b[q] == '(' ? 1 : b[q] == ')' ? -1 : 0;
                    square += b[q] == '[' ? 1 : b[q] == ']' ? -1 : 0;
                }
                if (be < n && ((round > 0 && b[be] == ')') || (square > 0 && b[be] == ']'))) {
                    ext = 1;
                    extc = 1;
                }
            }
            for (tries = 0; tries < 2 && !found; tries++) {
                SV *span, *v, *to;
                HV *info = NULL;
                int sep;
                const char *kind = NULL;
                /* a full stop at the end is tried as the sentence's, then as the word's ("a.m.") */
                int dot = !ext && be > T[i].bs + 1 && b[be - 1] == '.', cut = dot && !tries;
                if (tries && !dot)
                    break;
                span = sv_2mortal(newSVpvn_flags(b + T[i].bs, be + ext - cut - T[i].bs, SVf_UTF8));
                if (!names && L->spaceless && !tkn_find_anchor_span(aTHX_ L, rel, span))
                    break;
                sep = j > i && tkn_find_has_sep(aTHX_ L, seps, span);
                if (T[i].range_start && !sep)
                    break;
                v = tkn_find_read(aTHX_ self, method, span, kinds, sep, &kind, &to, &info);
                if (v) {
                    HV *a = (HV *)sv_2mortal((SV *)newHV());
                    SV *p = info ? tkn_hsv(aTHX_ info, "precision") : NULL, **as = info ? hv_fetchs(info, "assumed", 0) : NULL;
                    (void)hv_stores(a, "value", newSVsv(v));
                    (void)hv_stores(a, "kind", newSVpv(kind, 0));
                    if (to)
                        (void)hv_stores(a, "to", newSVsv(to));
                    if (p)
                        (void)hv_stores(a, "precision", newSVsv(p));
                    if (as)
                        (void)hv_stores(a, "assumed", newSVsv(*as));
                    (void)hv_stores(a, "text", newSVsv(text));
                    (void)hv_stores(a, "start", newSViv((IV)T[i].cs));
                    (void)hv_stores(a, "end", newSViv((IV)(T[j].ce + extc - cut)));
                    (void)hv_stores(a, "locale", newSVsv(tkn_locale_of(aTHX_ self)));
                    (void)hv_stores(a, "anchor", newSVsv(tkn_now(aTHX_ self)));
                    av_push(out, newSVsv(tkn_match_new(aTHX_ sv_2mortal(newSVpvs("Time::Keeper::Natural::Match")), a)));
                    found = 1;
                    i = j + 1;
                }
            }
        }
        if (!found)
            i++;
    }
    LEAVE;
    return out;
}

#endif
