#ifndef TKN_LEXICON_H
#define TKN_LEXICON_H

/* A locale's compiled words: every relative phrase, counted pattern, name,
 * unit pattern and number word Time::Keeper::Locale has for it, normalised
 * and keyed. The strings live in one arena; each table is an open-addressing
 * hash of keys to a list of meanings (or, for numbers, to a value); a meaning
 * is a small record shared by every key that has it. A counted pattern is
 * keyed by its text before and after the number, joined by a NUL. The object
 * Perl sees is a blessed hash holding the code, with the compiled lexicon
 * attached as magic; a thread's copy compiles its own on first use. */

static void tkn_carp(pTHX_ const char *fn, SV *msg);

#define TKN_T_FIXED        0
#define TKN_T_COUNTED      1
#define TKN_T_UNIT_FIXED   2
#define TKN_T_UNIT_COUNTED 3
#define TKN_T_BARE         4
#define TKN_T_BARE_FIXED   5
#define TKN_T_FIELD_NAMES  6
#define TKN_T_NUMBERS      7
#define TKN_T_ORDINALS     8
#define TKN_T_NUM_TOK      9
#define TKN_T_NUM_CHAR     10
#define TKN_T_N            11

static const char *const tkn_table_names[TKN_T_N] = {
    "fixed", "counted", "unit_fixed", "unit_counted", "bare", "bare_fixed", "field_names",
    "numbers", "ordinals", "num_tok", "num_char"
};
static const char *const tkn_fields[] = {
    "year", "quarter", "month", "week", "day", "hour", "minute", "second",
    "mon", "tue", "wed", "thu", "fri", "sat", "sun"
};
#define TKN_N_FIELDS 15
#define TKN_N_UNIT_FIELDS 8
static const char *const tkn_widths[] = { "long", "short", "narrow" };
static const char *const tkn_units[] = {
    "year", "month", "week", "day", "hour", "minute", "second", "millisecond", "microsecond", "nanosecond"
};
#define TKN_N_UNITS 10
static const char *const tkn_cats[] = { "zero", "one", "two", "few", "many", "other" };
#define TKN_N_CATS 6

#define TKN_EMPTY 0xFFFFFFFFu

typedef struct {
    I8 field, n, width, direction, category, count, weekday, month, period, unit, has_n, has_count;
} tkn_rec;

typedef struct {
    tkn_rec r;
    HV *hv;
} tkn_meaning;

typedef struct {
    U32 off, len;
    I32 head, tail;
} tkn_slot;

typedef struct {
    tkn_slot *s;
    U32 cap, n;
} tkn_table;

typedef struct {
    I32 m, next;
} tkn_node;

/* What the pattern ladders test of a pattern before they read it (0.04). */
typedef struct {
    char kind;          /* 'd' date, 't' time, 'o' other */
    I8 numeric, alpha, month_name;
} tkn_pmeta;

typedef struct {
    SV *code;
    int spaceless, has_digits, num_max, ordinals_read;
    UV digits[10];
    char *arena;
    STRLEN alen, acap;
    tkn_table t[TKN_T_N];
    tkn_meaning *m;
    I32 nm, mcap;
    I32 *mh;
    U32 mhcap;
    tkn_node *nodes;
    I32 nn, ncap;
    SV *markers[2][2];
    AV *jword, *jraw;
    char *jkind;
    SV *digital, *lists;
    AV *patterns, *periods;
    int jinfo;          /* the joiner facts below are worked out */
    char *jword_w;      /* a joiner has a word character */
    AV *jwords;         /* the joiners without their punctuation and spaces, as words */
    int jmost;          /* the most tokens one of those words has */
    AV *dwords;         /* the joiner words a duration's digit split drops (Phase 07) */
    int locale_id;      /* Time::Keeper's id of the code, 0 until looked up (id + 1) */
    int h24;            /* prefers_24_hour_time, 0 until asked (1 no, 2 yes) */
    AV *dprules;        /* day_period_rules, on first use */
    SV *calendar;       /* a calendar's id other than the Gregorian, or NULL (0.03) */
    int cal_id;         /* Time::Keeper's index of it, 0 for the Gregorian */
    SV *decimal;        /* the locale's decimal sign, on first use (0.03) */
    SV *group;          /* and its group separator */
    tkn_pmeta *pmeta;   /* the patterns' facts, beside L->patterns (0.04) */
} tkn_lexicon;

static U32
tkn_hash(const char *s, STRLEN n)
{
    U32 h = 2166136261u;
    while (n--) {
        h ^= (U8)*s++;
        h *= 16777619u;
    }
    return h;
}

static U32
tkn_arena_add(tkn_lexicon *L, const char *k, STRLEN n)
{
    U32 off;
    if (L->alen + n + 1 > L->acap) {
        STRLEN cap = L->acap ? L->acap : 4096;
        while (L->alen + n + 1 > cap)
            cap *= 2;
        Renew(L->arena, cap, char);
        L->acap = cap;
    }
    off = (U32)L->alen;
    if (n)
        Copy(k, L->arena + off, n, char);
    L->arena[off + n] = '\0';
    L->alen += n + 1;
    return off;
}

static I32
tkn_tfind(const tkn_lexicon *L, const tkn_table *t, const char *k, STRLEN n)
{
    U32 i;
    if (!t->cap)
        return -1;
    i = tkn_hash(k, n) & (t->cap - 1);
    for (;;) {
        const tkn_slot *s = &t->s[i];
        if (s->off == TKN_EMPTY)
            return -1;
        if (s->len == n && memEQ(L->arena + s->off, k, n))
            return (I32)i;
        i = (i + 1) & (t->cap - 1);
    }
}

static void
tkn_tgrow(tkn_lexicon *L, tkn_table *t)
{
    U32 cap = t->cap ? t->cap * 2 : 64, i;
    tkn_slot *s;
    Newx(s, cap, tkn_slot);
    for (i = 0; i < cap; i++)
        s[i].off = TKN_EMPTY;
    for (i = 0; i < t->cap; i++) {
        tkn_slot *o = &t->s[i];
        U32 j;
        if (o->off == TKN_EMPTY)
            continue;
        j = tkn_hash(L->arena + o->off, o->len) & (cap - 1);
        while (s[j].off != TKN_EMPTY)
            j = (j + 1) & (cap - 1);
        s[j] = *o;
    }
    Safefree(t->s);
    t->s = s;
    t->cap = cap;
}

static I32
tkn_tinsert(tkn_lexicon *L, tkn_table *t, const char *k, STRLEN n)
{
    I32 i = tkn_tfind(L, t, k, n);
    U32 j;
    if (i >= 0)
        return i;
    if ((t->n + 1) * 4 >= t->cap * 3)
        tkn_tgrow(L, t);
    j = tkn_hash(k, n) & (t->cap - 1);
    while (t->s[j].off != TKN_EMPTY)
        j = (j + 1) & (t->cap - 1);
    t->s[j].off = tkn_arena_add(L, k, n);
    t->s[j].len = (U32)n;
    t->s[j].head = t->s[j].tail = -1;
    t->n++;
    return (I32)j;
}

/* A record's index, the same record shared by every key that has it. */
static I32
tkn_intern(tkn_lexicon *L, const tkn_rec *r)
{
    U32 h = tkn_hash((const char *)r, sizeof *r), i;
    if ((U32)(L->nm + 1) * 2 >= L->mhcap) {
        U32 cap = L->mhcap ? L->mhcap * 2 : 256, k;
        I32 *mh;
        Newx(mh, cap, I32);
        for (k = 0; k < cap; k++)
            mh[k] = -1;
        for (k = 0; k < (U32)L->nm; k++) {
            U32 j = tkn_hash((const char *)&L->m[k].r, sizeof(tkn_rec)) & (cap - 1);
            while (mh[j] >= 0)
                j = (j + 1) & (cap - 1);
            mh[j] = (I32)k;
        }
        Safefree(L->mh);
        L->mh = mh;
        L->mhcap = cap;
    }
    i = h & (L->mhcap - 1);
    while (L->mh[i] >= 0) {
        if (memEQ(&L->m[L->mh[i]].r, r, sizeof *r))
            return L->mh[i];
        i = (i + 1) & (L->mhcap - 1);
    }
    if (L->nm == L->mcap) {
        L->mcap = L->mcap ? L->mcap * 2 : 256;
        Renew(L->m, L->mcap, tkn_meaning);
    }
    L->m[L->nm].r = *r;
    L->m[L->nm].hv = NULL;
    L->mh[i] = L->nm;
    return L->nm++;
}

/* 0.01's rule: a key lists a meaning once, by field, n, weekday, month,
 * period, direction, count and unit; the first one in (the widest width,
 * the first category) stays. */
static int
tkn_same(const tkn_rec *a, const tkn_rec *b)
{
    return a->field == b->field && a->has_n == b->has_n && (!a->has_n || a->n == b->n)
        && a->weekday == b->weekday && a->month == b->month && a->period == b->period
        && a->direction == b->direction && a->has_count == b->has_count
        && (!a->has_count || a->count == b->count) && a->unit == b->unit;
}

static void
tkn_append(tkn_lexicon *L, int table, const char *k, STRLEN n, I32 mi)
{
    tkn_table *t = &L->t[table];
    I32 si = tkn_tinsert(L, t, k, n), x;
    tkn_slot *s = &t->s[si];
    for (x = s->head; x >= 0; x = L->nodes[x].next)
        if (tkn_same(&L->m[L->nodes[x].m].r, &L->m[mi].r))
            return;
    if (L->nn == L->ncap) {
        L->ncap = L->ncap ? L->ncap * 2 : 512;
        Renew(L->nodes, L->ncap, tkn_node);
    }
    L->nodes[L->nn].m = mi;
    L->nodes[L->nn].next = -1;
    if (s->tail >= 0)
        L->nodes[s->tail].next = L->nn;
    else
        s->head = L->nn;
    s->tail = L->nn++;
}

static void
tkn_rec_init(tkn_rec *r)
{
    Zero(r, 1, tkn_rec);
    r->field = r->width = r->category = r->period = r->unit = -1;
}

/* The text of an SV as UTF-8 bytes. */
static const char *
tkn_utf8_bytes(pTHX_ SV *sv, STRLEN *len)
{
    const char *p = SvPV_const(sv, *len);
    STRLEN i;
    if (SvUTF8(sv))
        return p;
    for (i = 0; i < *len; i++)
        if ((U8)p[i] >= 0x80) {
            SV *u = sv_2mortal(newSVpvn(p, *len));
            sv_utf8_upgrade(u);
            return SvPV_const(u, *len);
        }
    return p;
}

/* A key's spellings: itself, and without its full stops when that differs
 * and is not empty; a full stop between two digits stays ("1.5 hours" is
 * not fifteen). */
static int
tkn_spellings(pTHX_ SV *k, SV **out)
{
    STRLEN len, i, blen;
    const char *s = SvPV_const(k, len);
    SV *bare;
    char *b;
    out[0] = k;
    if (!memchr(s, '.', len))
        return 1;
    bare = sv_2mortal(newSVpvs(""));
    if (SvUTF8(k))
        SvUTF8_on(bare);
    for (i = 0; i < len; i++) {
        if (s[i] == '.' && !(i > 0 && i + 1 < len && isDIGIT_A(s[i - 1]) && isDIGIT_A(s[i + 1])))
            continue;
        if (s[i] == ' ' && SvCUR(bare) && SvPVX(bare)[SvCUR(bare) - 1] == ' ')
            continue;
        sv_catpvn(bare, s + i, 1);
    }
    b = SvPV(bare, blen);
    if (blen && b[blen - 1] == ' ')
        SvCUR_set(bare, --blen);
    if (blen && b[0] == ' ') {
        sv_chop(bare, b + 1);
        b = SvPV(bare, blen);
    }
    *SvEND(bare) = '\0';
    if (!blen || (blen == len && memEQ(b, s, len)))
        return 1;
    out[1] = bare;
    return 2;
}

static SV *
tkn_key_sv(pTHX_ tkn_lexicon *L, SV *s)
{
    return tkn_normalise(aTHX_ tkn_ascii_digits(aTHX_ s, L->has_digits ? L->digits : NULL), L->spaceless);
}

/* _add: a string's key and its spellings in a table, meaning r. */
static void
tkn_add(pTHX_ tkn_lexicon *L, int table, SV *s, const tkn_rec *r)
{
    SV *k, *sp[2];
    int n, i;
    I32 mi;
    if (!s || !SvOK(s))
        return;
    k = tkn_normalise(aTHX_ s, L->spaceless);
    if (!SvCUR(k))
        return;
    mi = tkn_intern(L, r);
    n = tkn_spellings(aTHX_ k, sp);
    for (i = 0; i < n; i++) {
        STRLEN len;
        const char *b = tkn_utf8_bytes(aTHX_ sp[i], &len);
        tkn_append(L, table, b, len, mi);
    }
}

/* _counted: a pattern with one {0}, keyed by its text before and after. */
static void
tkn_counted(pTHX_ tkn_lexicon *L, int table, SV *p, const tkn_rec *r)
{
    SV *k = tkn_normalise(aTHX_ p, L->spaceless), *sp[2];
    int n = tkn_spellings(aTHX_ k, sp), i;
    I32 mi = tkn_intern(L, r);
    for (i = 0; i < n; i++) {
        STRLEN len;
        const char *b = tkn_utf8_bytes(aTHX_ sp[i], &len), *at = NULL, *q;
        int found = 0;
        SV *key;
        for (q = b; q + 3 <= b + len; q++)
            if (q[0] == '{' && q[1] == '0' && q[2] == '}') {
                if (!found)
                    at = q;
                found++;
                q += 2;
            }
        if (found != 1)
            tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("Time::Keeper::Natural::Lexicon: the %" SVf " pattern '%" SVf "' has {0} more than once",
                  SVfARG(L->code), SVfARG(p))));
        key = sv_2mortal(newSVpvn(b, (STRLEN)(at - b)));
        sv_catpvn(key, "\0", 1);
        sv_catpvn(key, at + 3, (STRLEN)(b + len - at - 3));
        tkn_append(L, table, SvPVX(key), SvCUR(key), mi);
    }
}

/* _unmarked: a normalised pattern without its direction's marker, or NULL
 * when it carries neither part. */
static SV *
tkn_unmarked(pTHX_ tkn_lexicon *L, SV *p, SV *mpre, SV *msuf)
{
    SV *k = tkn_normalise(aTHX_ p, L->spaceless);
    STRLEN klen, plen, slen;
    const char *kb = tkn_utf8_bytes(aTHX_ k, &klen);
    const char *pb = tkn_utf8_bytes(aTHX_ mpre, &plen);
    const char *sb = tkn_utf8_bytes(aTHX_ msuf, &slen);
    STRLEN from = 0, to = klen;
    int changed = 0;
    if (plen && klen >= plen && memEQ(kb, pb, plen)) {
        from = plen;
        changed++;
    }
    if (slen && to - from >= slen && memEQ(kb + to - slen, sb, slen)) {
        to -= slen;
        changed++;
    }
    if (!changed)
        return NULL;
    {
        SV *out = sv_2mortal(newSVpvn(kb + from, to - from));
        SvUTF8_on(out);
        return out;
    }
}

/* Calls to Time::Keeper::Locale (or another class) in list context, the
 * results copied into a mortal array. */
static AV *
tkn_call(pTHX_ const char *klass, const char *method, SV **args, int nargs)
{
    dSP;
    int n, i;
    AV *av = (AV *)sv_2mortal((SV *)newAV());
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(klass, 0)));
    for (i = 0; i < nargs; i++)
        XPUSHs(args[i]);
    PUTBACK;
    n = call_method(method, G_ARRAY);
    SPAGAIN;
    for (i = 0; i < n; i++)
        av_store(av, i, newSVsv(*(SP - n + 1 + i)));
    SP -= n;
    PUTBACK;
    FREETMPS;
    LEAVE;
    return av;
}

static SV *
tkn_call1(pTHX_ const char *klass, const char *method, SV **args, int nargs)
{
    AV *av = tkn_call(aTHX_ klass, method, args, nargs);
    SV **e = av_fetch(av, 0, 0);
    return e ? *e : &PL_sv_undef;
}

#define TKN_LOC "Time::Keeper::Locale"

static HV *
tkn_hv_of(SV *ref)
{
    return ref && SvROK(ref) && SvTYPE(SvRV(ref)) == SVt_PVHV ? (HV *)SvRV(ref) : NULL;
}

static SV *
tkn_hget(pTHX_ SV *ref, const char *key)
{
    HV *hv = tkn_hv_of(ref);
    SV **e;
    if (!hv)
        return NULL;
    e = hv_fetch(hv, key, (I32)strlen(key), 0);
    return e && SvOK(*e) ? *e : NULL;
}

static int
tkn_has_space(pTHX_ SV *sv)
{
    STRLEN len;
    const U8 *p = (const U8 *)SvPV_const(sv, len), *e = p + len;
    int utf8 = SvUTF8(sv);
    while (p < e) {
        STRLEN cl = 1;
        UV cp = utf8 ? tkn_utf8_cp(p, e, &cl) : *p;
        if (utf8 ? tkn_is_space_cp(cp) : (cp < 0x80 && isSPACE((U8)cp)))
            return 1;
        p += cl;
    }
    return 0;
}

static STRLEN
tkn_char_len(const char *s, STRLEN n)
{
    STRLEN c = 0, i;
    for (i = 0; i < n; i++)
        if (((U8)s[i] & 0xC0) != 0x80)
            c++;
    return c;
}

/* _common: what the direction's patterns share before and after {0}, cut
 * to whole words unless the locale writes no spaces. */
static void
tkn_common(pTHX_ tkn_lexicon *L, AV *pats, SV **pre_out, SV **suf_out)
{
    I32 n = av_len(pats) + 1, i;
    SV *pre, *suf;
    STRLEN plen = 0, slen = 0;
    const char *pb = NULL, *sb = NULL;
    *pre_out = newSVpvs("");
    *suf_out = newSVpvs("");
    SvUTF8_on(*pre_out);
    SvUTF8_on(*suf_out);
    if (!n)
        return;
    for (i = 0; i < n; i++) {
        SV *k = tkn_normalise(aTHX_ *av_fetch(pats, i, 0), L->spaceless);
        STRLEN len;
        const char *b = tkn_utf8_bytes(aTHX_ k, &len), *at = NULL, *q, *after, *end2;
        for (q = b; q + 3 <= b + len; q++)
            if (q[0] == '{' && q[1] == '0' && q[2] == '}') {
                at = q;
                break;
            }
        if (!at)
            at = b + len;
        after = at < b + len ? at + 3 : b + len;
        end2 = after;
        for (q = after; q + 3 <= b + len; q++)
            if (q[0] == '{' && q[1] == '0' && q[2] == '}')
                break;
        end2 = q + 3 <= b + len ? q : b + len;
        if (i == 0) {
            pb = b;
            plen = (STRLEN)(at - b);
            sb = after;
            slen = (STRLEN)(end2 - after);
        }
        else {
            STRLEN m = 0, alen = (STRLEN)(at - b), blen = (STRLEN)(end2 - after);
            while (m < plen && m < alen && pb[m] == b[m])
                m++;
            while (m > 0 && m < plen && ((U8)pb[m] & 0xC0) == 0x80)
                m--;
            plen = m;
            m = 0;
            while (m < slen && m < blen && sb[slen - 1 - m] == after[blen - 1 - m])
                m++;
            while (m > 0 && m < slen && ((U8)sb[slen - m] & 0xC0) == 0x80)
                m--;
            sb += slen - m;
            slen = m;
        }
    }
    if (!L->spaceless) {
        STRLEN j;
        STRLEN cut = 0;
        for (j = 0; j < plen; j++)
            if (pb[j] == ' ')
                cut = j + 1;
        plen = cut;
        for (j = 0; j < slen; j++)
            if (sb[j] == ' ')
                break;
        if (j < slen) {
            sb += j;
            slen -= j;
        }
        else
            slen = 0;
    }
    pre = *pre_out;
    suf = *suf_out;
    sv_setpvn(pre, pb, plen);
    sv_setpvn(suf, sb, slen);
    SvUTF8_on(pre);
    SvUTF8_on(suf);
}

static I8
tkn_period_id(pTHX_ tkn_lexicon *L, SV *name)
{
    I32 i, n = av_len(L->periods) + 1;
    for (i = 0; i < n; i++)
        if (sv_eq(*av_fetch(L->periods, i, 0), name))
            return (I8)i;
    av_push(L->periods, newSVsv(name));
    return (I8)n;
}

/* A hash's keys sorted as Perl's sort does them, mortal. */
static AV *
tkn_sorted_keys(pTHX_ HV *hv)
{
    AV *av = (AV *)sv_2mortal((SV *)newAV());
    HE *he;
    if (!hv)
        return av;
    hv_iterinit(hv);
    while ((he = hv_iternext(hv)))
        av_push(av, newSVsv(hv_iterkeysv(he)));
    if (av_len(av) > 0)
        sortsv(AvARRAY(av), av_len(av) + 1, Perl_sv_cmp);
    return av;
}

static SV *tkn_numbers_for(pTHX_ SV *klass, SV *locale);

/* The words of a number table (cardinals or ordinals) in a table of
 * values; cardinals also fill num_tok, num_char and num_max. */
static void
tkn_number_words(pTHX_ tkn_lexicon *L, int table, const char *method)
{
    SV *nw = tkn_numbers_for(aTHX_ sv_2mortal(newSVpvs("Time::Keeper::Natural::Numbers")), L->code);
    AV *pairs;
    I32 i, n;
    SV **kh;
    HE *he;
    if (!SvTRUE(nw))
        return;
    pairs = (AV *)sv_2mortal((SV *)newAV());
    kh = hv_fetch((HV *)SvRV(nw), method[0] == 'c' ? "c" : "o", 1, 0);
    if (!kh || !SvROK(*kh))
        return;
    hv_iterinit((HV *)SvRV(*kh));
    while ((he = hv_iternext((HV *)SvRV(*kh)))) {
        av_push(pairs, newSVsv(hv_iterkeysv(he)));
        av_push(pairs, newSVsv(HeVAL(he)));
    }
    n = av_len(pairs) + 1;
    for (i = 0; i + 1 < n; i += 2) {
        SV *k = tkn_normalise(aTHX_ *av_fetch(pairs, i, 0), L->spaceless);
        IV val = SvIV(*av_fetch(pairs, i + 1, 0));
        STRLEN klen, j;
        const char *kb = tkn_utf8_bytes(aTHX_ k, &klen);
        SV *vs[2];
        int nv = 0, v;
        if (L->spaceless) {
            vs[0] = sv_2mortal(newSVpvs(""));
            for (j = 0; j < klen; j++)
                if (kb[j] != '-')
                    sv_catpvn(vs[0], kb + j, 1);
            nv = 1;
        }
        else {
            vs[0] = sv_2mortal(newSVpvn(kb, klen));
            vs[1] = sv_2mortal(newSVpvn(kb, klen));
            for (j = 0; j < klen; j++)
                if (SvPVX(vs[1])[j] == '-')
                    SvPVX(vs[1])[j] = ' ';
            nv = 2;
        }
        for (v = 0; v < nv; v++) {
            STRLEN vl;
            const char *vb = SvPV_const(vs[v], vl);
            I32 si = tkn_tinsert(L, &L->t[table], vb, vl);
            L->t[table].s[si].head = (I32)val;
            if (table == TKN_T_NUMBERS) {
                int len;
                if (L->spaceless) {
                    STRLEN cl = vl ? UTF8SKIP((const U8 *)vb) : 0;
                    if (cl > vl)
                        cl = vl;
                    if (vl)
                        tkn_tinsert(L, &L->t[TKN_T_NUM_CHAR], vb, cl);
                    len = (int)tkn_char_len(vb, vl);
                }
                else {
                    const char *sp = (const char *)memchr(vb, ' ', vl);
                    STRLEN tl = sp ? (STRLEN)(sp - vb) : vl, q;
                    tkn_tinsert(L, &L->t[TKN_T_NUM_TOK], vb, tl);
                    len = 1;
                    for (q = 0; q < vl; q++)
                        if (vb[q] == ' ')
                            len++;
                }
                if (len > L->num_max)
                    L->num_max = len;
            }
        }
    }
}

/* raw =~ /^\s+\S+\z/ (lead, 1) or /^\S+\s+\z/ (tail, 2), else 0. */
static char
tkn_joiner_kind(pTHX_ SV *raw)
{
    STRLEN len;
    const U8 *p = (const U8 *)tkn_utf8_bytes(aTHX_ raw, &len), *e = p + len;
    int runs = 0, first = -1, last = -1;
    while (p < e) {
        STRLEN cl;
        int sp = tkn_is_space_cp(tkn_utf8_cp(p, e, &cl)) ? 1 : 0;
        if (sp != last) {
            runs++;
            if (first < 0)
                first = sp;
            last = sp;
        }
        p += cl;
    }
    if (runs != 2)
        return 0;
    return first ? 1 : 2;
}

static void tkn_lexicon_free(pTHX_ tkn_lexicon *L);

/* A calendar's canonical id through Time::Keeper::Calendar->canonical, or a
 * croak in the caller's name with its reason. */
static SV *
tkn_canonical_calendar(pTHX_ const char *me, SV *cal)
{
    dSP;
    SV *out = NULL, *why = NULL;
    int c;
    if (!get_cv("Time::Keeper::Calendar::canonical", 0))
        load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("Time::Keeper::Calendar"), NULL);
    ENTER;
    SAVETMPS;
    save_scalar(PL_errgv);
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvs("Time::Keeper::Calendar")));
    XPUSHs(cal);
    PUTBACK;
    c = call_method("canonical", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (SvTRUE(ERRSV))
        why = newSVsv(ERRSV);
    else if (c == 1 && SvOK(TOPs))
        out = newSVsv(TOPs);
    SP -= c;
    PUTBACK;
    FREETMPS;
    LEAVE;
    if (!out) {
        STRLEN wl;
        const char *wb;
        SV *w;
        if (!why)
            why = newSVpvf("'%" SVf "' is not a calendar", SVfARG(cal));
        sv_2mortal(why);
        wb = SvPV_const(why, wl);
        if (wl > 36 && memEQ(wb, "Time::Keeper::Calendar->canonical: ", 35))
            w = sv_2mortal(newSVpvn(wb + 35, wl - 35));
        else
            w = why;
        if (SvUTF8(why))
            SvUTF8_on(w);
        {
            /* the reason without " at FILE line N." */
            STRLEN l;
            const char *b = SvPV_const(w, l), *at = NULL, *q;
            for (q = b; q + 4 <= b + l; q++)
                if (memEQ(q, " at ", 4))
                    at = q;
            if (at)
                w = sv_2mortal(newSVpvn(b, (STRLEN)(at - b)));
        }
        tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("%s: %" SVf, me, SVfARG(w))));
    }
    return sv_2mortal(out);
}

/* A lexicon's calendar: its id, and Time::Keeper's index of it. */
static void
tkn_lexicon_calendar(pTHX_ tkn_lexicon *L, SV *cal)
{
    STRLEN n;
    const char *c;
    if (!cal || !SvOK(cal) || strEQ(SvPV_nolen(cal), "gregory"))
        return;
    L->calendar = newSVsv(cal);
    c = SvPV_const(cal, n);
    L->cal_id = (TKN_TK->calendar_find)(c, n);
    if (L->cal_id < 0)
        L->cal_id = 0;
}

static void
tkn_lexicon_compile(pTHX_ tkn_lexicon *L, SV *code)
{
    SV *args[4];
    AV *digits;
    int f, w, d, i;
    static const char *const dirs[2] = { "future", "past" };

    L->code = newSVsv(code);
    L->spaceless = 1;
    L->periods = newAV();
    L->jword = newAV();
    L->jraw = newAV();
    args[0] = L->code;

    digits = tkn_call(aTHX_ TKN_LOC, "digits", args, 1);
    if (av_len(digits) == 9) {
        int ascii = 1;
        for (i = 0; i < 10; i++) {
            SV *dg = *av_fetch(digits, i, 0);
            STRLEN dl, cl;
            const U8 *db = (const U8 *)tkn_utf8_bytes(aTHX_ dg, &dl);
            L->digits[i] = dl ? tkn_utf8_cp(db, db + dl, &cl) : 0;
            if (L->digits[i] != (UV)('0' + i))
                ascii = 0;
        }
        L->has_digits = !ascii;
    }

    for (f = 0; f < 4; f++) {
        static const char *const sf[4] = { "year", "month", "week", "day" };
        SV *at;
        HV *hv;
        HE *he;
        args[1] = sv_2mortal(newSVpv(sf[f], 0));
        args[2] = sv_2mortal(newSVpvs("long"));
        at = tkn_hget(aTHX_ tkn_call1(aTHX_ TKN_LOC, "relative_names", args, 3), "at");
        if (!(hv = tkn_hv_of(at)))
            continue;
        hv_iterinit(hv);
        while ((he = hv_iternext(hv)))
            if (SvOK(HeVAL(he)) && tkn_has_space(aTHX_ HeVAL(he)))
                L->spaceless = 0;
    }

    for (d = 0; d < 2; d++) {
        AV *pats = (AV *)sv_2mortal((SV *)newAV());
        for (f = 0; f < TKN_N_UNIT_FIELDS; f++) {
            SV *p;
            args[1] = sv_2mortal(newSVpv(tkn_fields[f], 0));
            args[2] = sv_2mortal(newSVpvs("long"));
            p = tkn_hget(aTHX_ tkn_hget(aTHX_ tkn_call1(aTHX_ TKN_LOC, "relative_names", args, 3), dirs[d]), "other");
            if (p && strstr(SvPV_nolen(p), "{0}"))
                av_push(pats, newSVsv(p));
        }
        tkn_common(aTHX_ L, pats, &L->markers[d][0], &L->markers[d][1]);
    }

    for (f = 0; f < TKN_N_FIELDS; f++) {
        int unit_field = f < TKN_N_UNIT_FIELDS;
        for (w = 0; w < 3; w++) {
            SV *r, *at;
            tkn_rec m;
            args[1] = sv_2mortal(newSVpv(tkn_fields[f], 0));
            args[2] = sv_2mortal(newSVpv(tkn_widths[w], 0));
            r = tkn_call1(aTHX_ TKN_LOC, "relative_names", args, 3);
            if (unit_field) {
                tkn_rec_init(&m);
                m.field = (I8)f;
                tkn_add(aTHX_ L, TKN_T_FIELD_NAMES, tkn_hget(aTHX_ r, "display"), &m);
            }
            if ((at = tkn_hget(aTHX_ r, "at"))) {
                AV *ks = tkn_sorted_keys(aTHX_ tkn_hv_of(at));
                I32 k, nk = av_len(ks) + 1;
                for (k = 0; k < nk; k++) {
                    SV *key = *av_fetch(ks, k, 0);
                    tkn_rec_init(&m);
                    m.field = (I8)f;
                    m.has_n = 1;
                    m.n = (I8)SvIV(key);
                    m.width = (I8)w;
                    tkn_add(aTHX_ L, TKN_T_FIXED, tkn_hget(aTHX_ at, SvPV_nolen(key)), &m);
                }
            }
            for (d = 0; d < 2; d++) {
                int sign = d ? -1 : 1, c;
                HV *ph = tkn_hv_of(tkn_hget(aTHX_ r, dirs[d]));
                SV *mpre = L->markers[d][0], *msuf = L->markers[d][1];
                if (!ph)
                    continue;
                for (c = 0; c <= TKN_N_CATS; c++) {
                    SV **pp;
                    SV *p;
                    int fixed_count = c <= 2;
                    if (c == TKN_N_CATS)
                        break;
                    pp = hv_fetch(ph, tkn_cats[c], (I32)strlen(tkn_cats[c]), 0);
                    if (!pp)
                        continue;
                    p = *pp;
                    tkn_rec_init(&m);
                    m.field = (I8)f;
                    m.direction = (I8)sign;
                    m.category = (I8)c;
                    m.width = (I8)w;
                    if (SvOK(p) && strstr(SvPV_nolen(p), "{0}")) {
                        STRLEN pl;
                        const char *pb = tkn_utf8_bytes(aTHX_ p, &pl), *q, *open = NULL;
                        tkn_counted(aTHX_ L, TKN_T_COUNTED, p, &m);
                        if (unit_field) {
                            SV *u = tkn_unmarked(aTHX_ L, p, mpre, msuf);
                            if (u)
                                tkn_counted(aTHX_ L, TKN_T_BARE, u, &m);
                        }
                        if (!fixed_count)
                            continue;
                        for (q = pb; q + 5 <= pb + pl; q++)
                            if (memEQ(q, "({0})", 5)) {
                                open = q;
                                break;
                            }
                        if (open) {
                            const char *from = open;
                            SV *bare;
                            tkn_rec fm = m;
                            while (from > pb) {
                                const char *prev = from - 1;
                                STRLEN cl;
                                while (prev > pb && ((U8)*prev & 0xC0) == 0x80)
                                    prev--;
                                if (!tkn_is_space_cp(tkn_utf8_cp((const U8 *)prev, (const U8 *)pb + pl, &cl)))
                                    break;
                                from = prev;
                            }
                            bare = sv_2mortal(newSVpvn(pb, (STRLEN)(from - pb)));
                            sv_catpvn(bare, open + 5, (STRLEN)(pb + pl - open - 5));
                            SvUTF8_on(bare);
                            fm.has_count = 1;
                            fm.count = (I8)c;
                            fm.has_n = 1;
                            fm.n = (I8)(sign * c);
                            tkn_add(aTHX_ L, TKN_T_FIXED, bare, &fm);
                            if (unit_field) {
                                SV *u = tkn_unmarked(aTHX_ L, bare, mpre, msuf);
                                if (u)
                                    tkn_add(aTHX_ L, TKN_T_BARE_FIXED, u, &fm);
                            }
                        }
                    }
                    else {
                        tkn_rec fm = m;
                        if (!fixed_count)
                            tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("Time::Keeper::Natural::Lexicon: the %" SVf " %s %s %s pattern '%" SVf "' for '%s' has no {0} and no fixed count",
                                  SVfARG(L->code), tkn_fields[f], tkn_widths[w], dirs[d], SVfARG(p), tkn_cats[c])));
                        fm.has_count = 1;
                        fm.count = (I8)c;
                        fm.has_n = 1;
                        fm.n = (I8)(sign * c);
                        tkn_add(aTHX_ L, TKN_T_FIXED, p, &fm);
                        if (unit_field) {
                            SV *u = tkn_unmarked(aTHX_ L, p, mpre, msuf);
                            if (u)
                                tkn_add(aTHX_ L, TKN_T_BARE_FIXED, u, &fm);
                        }
                    }
                }
            }
        }
    }

    {
        static const char *const types[4] = { "standard", "unit", "unit-short", "unit-narrow" };
        static const char *const slots[4] = { "two", "start", "middle", "end" };
        HV *seen = (HV *)sv_2mortal((SV *)newHV());
        AV *words = (AV *)sv_2mortal((SV *)newAV()), *raws = (AV *)sv_2mortal((SV *)newAV());
        HV *lists = newHV();
        I32 n, a, b;
        L->lists = newRV_noinc((SV *)lists);
        for (i = 0; i < 4; i++) {
            SV *lp, *ta[2];
            int s;
            ta[0] = L->code;
            ta[1] = sv_2mortal(newSVpv(types[i], 0));
            lp = tkn_call1(aTHX_ TKN_LOC, "list_patterns", ta, 2);
            (void)hv_store(lists, types[i], (I32)strlen(types[i]), newSVsv(lp), 0);
            for (s = 0; s < 4; s++) {
                SV *v = tkn_hget(aTHX_ lp, slots[s]), *raw, *word;
                STRLEN vl;
                const char *vb, *o = NULL, *c = NULL, *q;
                if (!v)
                    continue;
                vb = tkn_utf8_bytes(aTHX_ v, &vl);
                for (q = vb; q + 3 <= vb + vl; q++)
                    if (memEQ(q, "{0}", 3)) {
                        o = q;
                        break;
                    }
                if (!o)
                    continue;
                for (q = vb + vl - 3; q >= o + 3; q--)
                    if (memEQ(q, "{1}", 3)) {
                        c = q;
                        break;
                    }
                if (!c)
                    continue;
                raw = sv_2mortal(newSVpvn(o + 3, (STRLEN)(c - o - 3)));
                SvUTF8_on(raw);
                word = tkn_normalise(aTHX_ raw, L->spaceless);
                if (!SvCUR(word) || hv_exists_ent(seen, word, 0))
                    continue;
                (void)hv_store_ent(seen, word, &PL_sv_yes, 0);
                av_push(words, newSVsv(word));
                av_push(raws, newSVsv(raw));
            }
        }
        n = av_len(words) + 1;
        {
            I32 *ord;
            STRLEN *lens;
            Newx(ord, n ? n : 1, I32);
            Newx(lens, n ? n : 1, STRLEN);
            for (a = 0; a < n; a++) {
                STRLEN wl;
                const char *wb = SvPV_const(*av_fetch(words, a, 0), wl);
                ord[a] = a;
                lens[a] = SvUTF8(*av_fetch(words, a, 0)) ? tkn_char_len(wb, wl) : wl;
            }
            for (a = 1; a < n; a++) {
                I32 x = ord[a];
                b = a - 1;
                while (b >= 0 && lens[ord[b]] < lens[x]) {
                    ord[b + 1] = ord[b];
                    b--;
                }
                ord[b + 1] = x;
            }
            Newx(L->jkind, n ? n : 1, char);
            for (a = 0; a < n; a++) {
                SV *raw = *av_fetch(raws, ord[a], 0);
                av_push(L->jword, newSVsv(*av_fetch(words, ord[a], 0)));
                av_push(L->jraw, newSVsv(raw));
                L->jkind[a] = tkn_joiner_kind(aTHX_ raw);
            }
            Safefree(ord);
            Safefree(lens);
        }
    }

    {
        static const char *const ctxs[2] = { "format", "stand-alone" };
        static const char *const nws[3] = { "wide", "abbreviated", "short" };
        int c;
        for (c = 0; c < 2; c++)
            for (w = 0; w < 3; w++) {
                SV *na[4];
                AV *days, *months;
                tkn_rec m;
                na[0] = L->code;
                na[1] = sv_2mortal(newSVpvs("days"));
                na[2] = sv_2mortal(newSVpv(nws[w], 0));
                na[3] = sv_2mortal(newSVpv(ctxs[c], 0));
                days = tkn_call(aTHX_ TKN_LOC, "names", na, 4);
                for (i = 0; i < 7; i++) {
                    SV **e = av_fetch(days, i, 0);
                    tkn_rec_init(&m);
                    m.weekday = (I8)(i + 1);
                    tkn_add(aTHX_ L, TKN_T_FIXED, e ? *e : NULL, &m);
                }
                if (w == 2)
                    continue;
                na[1] = sv_2mortal(newSVpvs("months"));
                months = tkn_call(aTHX_ TKN_LOC, "names", na, 4);
                for (i = 0; i < 12; i++) {
                    SV **e = av_fetch(months, i, 0);
                    tkn_rec_init(&m);
                    m.month = (I8)(i + 1);
                    tkn_add(aTHX_ L, TKN_T_FIXED, e ? *e : NULL, &m);
                }
            }
        for (w = 0; w < 2; w++) {
            SV *pa[2], *ph;
            AV *ks;
            I32 k, nk;
            pa[0] = L->code;
            pa[1] = sv_2mortal(newSVpv(nws[w], 0));
            ph = tkn_call1(aTHX_ TKN_LOC, "day_periods", pa, 2);
            ks = tkn_sorted_keys(aTHX_ tkn_hv_of(ph));
            nk = av_len(ks) + 1;
            for (k = 0; k < nk; k++) {
                SV *key = *av_fetch(ks, k, 0);
                tkn_rec m;
                tkn_rec_init(&m);
                m.period = tkn_period_id(aTHX_ L, key);
                tkn_add(aTHX_ L, TKN_T_FIXED, tkn_hget(aTHX_ ph, SvPV_nolen(key)), &m);
            }
        }
    }

    {
        int u;
        for (u = 0; u < TKN_N_UNITS; u++)
            for (w = 0; w < 3; w++) {
                SV *up, *cnt;
                HV *ch;
                int c;
                tkn_rec m;
                args[1] = sv_2mortal(newSVpv(tkn_units[u], 0));
                args[2] = sv_2mortal(newSVpv(tkn_widths[w], 0));
                up = tkn_call1(aTHX_ TKN_LOC, "unit_patterns", args, 3);
                if (u <= 6) {
                    tkn_rec_init(&m);
                    m.field = (I8)(u == 0 ? 0 : u == 1 ? 2 : u == 2 ? 3 : u == 3 ? 4 : u == 4 ? 5 : u == 5 ? 6 : 7);
                    tkn_add(aTHX_ L, TKN_T_FIELD_NAMES, tkn_hget(aTHX_ up, "display"), &m);
                }
                cnt = tkn_hget(aTHX_ up, "count");
                if (!(ch = tkn_hv_of(cnt)))
                    continue;
                for (c = 0; c < TKN_N_CATS; c++) {
                    SV **pp = hv_fetch(ch, tkn_cats[c], (I32)strlen(tkn_cats[c]), 0);
                    if (!pp || !SvOK(*pp))
                        continue;
                    tkn_rec_init(&m);
                    m.unit = (I8)u;
                    m.category = (I8)c;
                    m.width = (I8)w;
                    if (strstr(SvPV_nolen(*pp), "{0}"))
                        tkn_counted(aTHX_ L, TKN_T_UNIT_COUNTED, *pp, &m);
                    else if (c <= 2) {
                        m.has_count = 1;
                        m.count = (I8)c;
                        m.has_n = 1;
                        m.n = (I8)c;
                        tkn_add(aTHX_ L, TKN_T_UNIT_FIXED, *pp, &m);
                    }
                }
            }
    }

    tkn_number_words(aTHX_ L, TKN_T_NUMBERS, "cardinals");
    L->digital = newSVsv(tkn_call1(aTHX_ TKN_LOC, "duration_patterns", args, 1));
    Safefree(L->mh);
    L->mh = NULL;
    L->mhcap = 0;
}

static void
tkn_lexicon_free(pTHX_ tkn_lexicon *L)
{
    int i;
    if (!L)
        return;
    for (i = 0; i < L->nm; i++)
        SvREFCNT_dec((SV *)L->m[i].hv);
    for (i = 0; i < TKN_T_N; i++)
        Safefree(L->t[i].s);
    Safefree(L->m);
    Safefree(L->mh);
    Safefree(L->nodes);
    Safefree(L->arena);
    Safefree(L->jkind);
    SvREFCNT_dec(L->code);
    SvREFCNT_dec(L->markers[0][0]);
    SvREFCNT_dec(L->markers[0][1]);
    SvREFCNT_dec(L->markers[1][0]);
    SvREFCNT_dec(L->markers[1][1]);
    SvREFCNT_dec((SV *)L->jword);
    SvREFCNT_dec((SV *)L->jraw);
    SvREFCNT_dec(L->digital);
    SvREFCNT_dec(L->lists);
    SvREFCNT_dec((SV *)L->patterns);
    Safefree(L->pmeta);
    SvREFCNT_dec((SV *)L->periods);
    Safefree(L->jword_w);
    SvREFCNT_dec((SV *)L->jwords);
    SvREFCNT_dec((SV *)L->dwords);
    SvREFCNT_dec((SV *)L->dprules);
    SvREFCNT_dec(L->calendar);
    SvREFCNT_dec(L->decimal);
    SvREFCNT_dec(L->group);
    Safefree(L);
}

/* The magic that ties the C lexicon to its Perl hash. */
static int
tkn_lex_mg_free(pTHX_ SV *sv, MAGIC *mg)
{
    PERL_UNUSED_ARG(sv);
    tkn_lexicon_free(aTHX_ (tkn_lexicon *)mg->mg_ptr);
    mg->mg_ptr = NULL;
    return 0;
}

#ifdef USE_ITHREADS
static int
tkn_lex_mg_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param)
{
    PERL_UNUSED_ARG(param);
    mg->mg_ptr = NULL;
    return 0;
}
#else
#define tkn_lex_mg_dup NULL
#endif

static MGVTBL tkn_lex_vtbl = { NULL, NULL, NULL, NULL, tkn_lex_mg_free, NULL, tkn_lex_mg_dup, NULL };

static tkn_lexicon *
tkn_lexicon_new(void)
{
    tkn_lexicon *L;
    int i;
    Newxz(L, 1, tkn_lexicon);
    for (i = 0; i < TKN_T_N; i++)
        L->t[i].s = NULL;
    return L;
}

static tkn_lexicon *
tkn_lex(pTHX_ SV *self)
{
    MAGIC *mg;
    HV *hv;
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Time::Keeper::Natural::Lexicon: not a lexicon");
    hv = (HV *)SvRV(self);
    for (mg = SvMAGIC(hv); mg; mg = mg->mg_moremagic)
        if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &tkn_lex_vtbl)
            break;
    if (!mg)
        croak("Time::Keeper::Natural::Lexicon: not a lexicon");
    if (!mg->mg_ptr) {
        SV **c = hv_fetchs(hv, "code", 0), **cal = hv_fetchs(hv, "calendar", 0);
        tkn_lexicon *L = tkn_lexicon_new();
        mg->mg_ptr = (char *)L;
        tkn_lexicon_calendar(aTHX_ L, cal ? *cal : NULL);
        tkn_lexicon_compile(aTHX_ L, c ? *c : &PL_sv_undef);
    }
    return (tkn_lexicon *)mg->mg_ptr;
}

/* A new lexicon object for a canonical code, blessed into klass, in a
 * calendar (a canonical id other than the Gregorian) or none. */
static SV *
tkn_lexicon_object(pTHX_ SV *klass, SV *code, SV *cal)
{
    HV *hv = newHV();
    SV *rv = newRV_noinc((SV *)hv);
    tkn_lexicon *L = tkn_lexicon_new();
    MAGIC *mg;
    (void)hv_stores(hv, "code", newSVsv(code));
    if (cal)
        (void)hv_stores(hv, "calendar", newSVsv(cal));
    tkn_lexicon_calendar(aTHX_ L, cal);
    sv_bless(rv, gv_stashsv(klass, GV_ADD));
    mg = sv_magicext((SV *)hv, NULL, PERL_MAGIC_ext, &tkn_lex_vtbl, (const char *)L, 0);
#ifdef USE_ITHREADS
    mg->mg_flags |= MGf_DUP;
#else
    PERL_UNUSED_VAR(mg);
#endif
    sv_2mortal(rv);
    tkn_lexicon_compile(aTHX_ L, code);
    return rv;
}

/* Lexicon->for: a locale's lexicon, compiled once an interpreter; in a
 * calendar, one a locale and calendar, cached as "code@calendar". */
static SV *
tkn_lexicon_for_cal(pTHX_ SV *klass, SV *locale, SV *cal)
{
    dMY_CXT;
    SV *arg = SvOK(locale) ? locale : sv_2mortal(newSVpvs(""));
    SV *code, *obj, *key;
    HE *he;
    if (cal && (!SvOK(cal) || strEQ(SvPV_nolen(cal), "gregory")))
        cal = NULL;
    /* A canonical code is its own code, so the cache answers it at once. */
    if (!cal && SvOK(locale) && (he = hv_fetch_ent(MY_CXT.lexicons, locale, 0, 0)))
        return HeVAL(he);
    code = tkn_call1(aTHX_ TKN_LOC, "code", &arg, 1);
    if (!SvOK(code))
        tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("Time::Keeper::Natural::Lexicon->for: there is no locale '%" SVf "'", SVfARG(arg))));
    key = cal ? sv_2mortal(newSVpvf("%" SVf "@%" SVf, SVfARG(code), SVfARG(cal))) : code;
    he = hv_fetch_ent(MY_CXT.lexicons, key, 0, 0);
    if (he)
        return HeVAL(he);
    obj = tkn_lexicon_object(aTHX_ klass, code, cal);
    he = hv_store_ent(MY_CXT.lexicons, key, newSVsv(obj), 0);
    return HeVAL(he);
}

static SV *
tkn_lexicon_for(pTHX_ SV *klass, SV *locale)
{
    return tkn_lexicon_for_cal(aTHX_ klass, locale, NULL);
}

/* A meaning as 0.01 gave it: a hash of the keys it has. */
static HV *
tkn_rec_hv(pTHX_ tkn_lexicon *L, const tkn_rec *r)
{
    HV *hv = newHV();
    if (r->field >= 0)
        (void)hv_stores(hv, "field", newSVpv(tkn_fields[r->field], 0));
    if (r->has_n)
        (void)hv_stores(hv, "n", newSViv(r->n));
    if (r->width >= 0)
        (void)hv_stores(hv, "width", newSVpv(tkn_widths[r->width], 0));
    if (r->direction)
        (void)hv_stores(hv, "direction", newSViv(r->direction));
    if (r->category >= 0)
        (void)hv_stores(hv, "category", newSVpv(tkn_cats[r->category], 0));
    if (r->has_count)
        (void)hv_stores(hv, "count", newSViv(r->count));
    if (r->weekday)
        (void)hv_stores(hv, "weekday", newSViv(r->weekday));
    if (r->month)
        (void)hv_stores(hv, "month", newSViv(r->month));
    if (r->period >= 0)
        (void)hv_stores(hv, "period", newSVsv(*av_fetch(L->periods, r->period, 0)));
    if (r->unit >= 0)
        (void)hv_stores(hv, "unit", newSVpv(tkn_units[r->unit], 0));
    return hv;
}

static SV *
tkn_meaning_rv(pTHX_ tkn_lexicon *L, I32 mi)
{
    if (!L->m[mi].hv)
        L->m[mi].hv = tkn_rec_hv(aTHX_ L, &L->m[mi].r);
    return sv_2mortal(newRV_inc((SV *)L->m[mi].hv));
}

/* 0 + a digit string, as Perl numifies it. */
static SV *
tkn_digits_sv(pTHX_ const char *d, STRLEN n, int sign)
{
    UV v = 0;
    STRLEN i;
    for (i = 0; i < n; i++) {
        if (v > (UV)(IV_MAX - 9) / 10) {
            NV nv = Atof(SvPVX(sv_2mortal(newSVpvn(d, n))));
            return newSVnv(sign * nv);
        }
        v = v * 10 + (UV)(d[i] - '0');
    }
    return newSViv(sign * (IV)v);
}

static void
tkn_push_hits(pTHX_ tkn_lexicon *L, AV *out, I32 head, SV *num, int word)
{
    I32 x;
    for (x = head; x >= 0; x = L->nodes[x].next) {
        const tkn_rec *r = &L->m[L->nodes[x].m].r;
        HV *hv = tkn_rec_hv(aTHX_ L, r);
        (void)hv_stores(hv, "count", newSVsv(num));
        if (r->direction) {
            SV *n = newSVsv(num);
            if (SvIOK(num) && !SvNOK(num))
                sv_setiv(n, r->direction * SvIV(num));
            else
                sv_setnv(n, r->direction * SvNV(num));
            (void)hv_stores(hv, "n", n);
        }
        else
            (void)hv_stores(hv, "n", newSVsv(num));
        if (word)
            (void)hv_stores(hv, "word", newSViv(1));
        av_push(out, newRV_noinc((SV *)hv));
    }
}

/* _read_counted: the counted patterns a key reads as, with the number at a
 * digit run, or else at a span of number words. */
static void
tkn_read_counted(pTHX_ tkn_lexicon *L, int table, const char *k, STRLEN len, AV *out)
{
    tkn_table *t = &L->t[table];
    SV *kb = sv_2mortal(newSV(len + 2));
    STRLEN i = 0;
    I32 before = av_len(out);
    while (i < len) {
        STRLEN from, to;
        I32 si;
        if (k[i] < '0' || k[i] > '9') {
            i++;
            continue;
        }
        from = i;
        while (i < len && k[i] >= '0' && k[i] <= '9')
            i++;
        to = i;
        sv_setpvn(kb, k, from);
        sv_catpvn(kb, "\0", 1);
        sv_catpvn(kb, k + to, len - to);
        si = tkn_tfind(L, t, SvPVX(kb), SvCUR(kb));
        if (si >= 0) {
            SV *num = sv_2mortal(tkn_digits_sv(aTHX_ k + from, to - from, 1));
            tkn_push_hits(aTHX_ L, out, t->s[si].head, num, 0);
        }
    }
    if (av_len(out) > before || !L->num_max)
        return;
    {
        STRLEN *at;
        I32 nat = 0, a, b;
        int any = 0;
        if (L->spaceless) {
            const U8 *p = (const U8 *)k, *e = p + len;
            while (p < e) {
                STRLEN cl = UTF8SKIP(p);
                if (p + cl > e)
                    cl = (STRLEN)(e - p);
                if (tkn_tfind(L, &L->t[TKN_T_NUM_CHAR], (const char *)p, cl) >= 0) {
                    any = 1;
                    break;
                }
                p += cl;
            }
        }
        else {
            STRLEN s0 = 0, q;
            for (q = 0; q <= len; q++)
                if (q == len || k[q] == ' ') {
                    if (q > s0 && tkn_tfind(L, &L->t[TKN_T_NUM_TOK], k + s0, q - s0) >= 0) {
                        any = 1;
                        break;
                    }
                    s0 = q + 1;
                }
        }
        if (!any)
            return;
        Newx(at, len + 2, STRLEN);
        SAVEFREEPV(at);
        if (L->spaceless) {
            STRLEN q = 0;
            while (q < len) {
                STRLEN cl = UTF8SKIP((const U8 *)k + q);
                at[nat++] = q;
                q += cl;
            }
            at[nat++] = len;
        }
        else {
            STRLEN q;
            at[nat++] = 0;
            for (q = 0; q < len; q++)
                if (k[q] == ' ')
                    at[nat++] = q + 1;
            at[nat++] = len + 1;
        }
        for (a = 0; a < nat - 1; a++) {
            I32 last = a + L->num_max < nat - 1 ? a + L->num_max : nat - 1;
            for (b = a + 1; b <= last; b++) {
                STRLEN from = at[a], to = L->spaceless ? at[b] : at[b] - 1;
                I32 ni, si;
                if (to < from)
                    continue;
                ni = tkn_tfind(L, &L->t[TKN_T_NUMBERS], k + from, to - from);
                if (ni < 0)
                    continue;
                sv_setpvn(kb, k, from);
                sv_catpvn(kb, "\0", 1);
                sv_catpvn(kb, k + to, len - to);
                si = tkn_tfind(L, t, SvPVX(kb), SvCUR(kb));
                if (si < 0)
                    continue;
                tkn_push_hits(aTHX_ L, out, t->s[si].head,
                              sv_2mortal(newSViv(L->t[TKN_T_NUMBERS].s[ni].head)), 1);
            }
        }
    }
}

/* The locale's decimal sign and group separator, on first use. */
static void
tkn_number_signs(pTHX_ tkn_lexicon *L)
{
    if (!L->decimal) {
        SV *s = tkn_call1(aTHX_ TKN_LOC, "number_symbols", &L->code, 1), **d = NULL, **g = NULL;
        if (s && SvROK(s) && SvTYPE(SvRV(s)) == SVt_PVHV) {
            d = hv_fetchs((HV *)SvRV(s), "decimal", 0);
            g = hv_fetchs((HV *)SvRV(s), "group", 0);
        }
        L->decimal = d && SvOK(*d) ? newSVsv(*d) : newSVpvs(".");
        L->group = g && SvOK(*g) ? newSVsv(*g) : newSVpvs(",");
    }
}

/* A key with the locale's group separator taken out of a number written in
 * groups of three ("1.500" in German, "1,500" in English), or NULL. */
static SV *
tkn_ungrouped(pTHX_ tkn_lexicon *L, SV *key)
{
    STRLEN kl, gl, i;
    const char *kb, *gb;
    SV *out;
    int changed = 0;
    tkn_number_signs(aTHX_ L);
    kb = SvPV_const(key, kl);
    gb = SvPV_const(L->group, gl);
    if (!gl)
        return NULL;
    out = sv_2mortal(newSVpvs(""));
    if (SvUTF8(key))
        SvUTF8_on(out);
    for (i = 0; i < kl;) {
        if (i > 0 && isDIGIT_A(kb[i - 1]) && i + gl + 3 <= kl && memEQ(kb + i, gb, gl)
            && isDIGIT_A(kb[i + gl]) && isDIGIT_A(kb[i + gl + 1]) && isDIGIT_A(kb[i + gl + 2])
            && (i + gl + 3 == kl || !isDIGIT_A(kb[i + gl + 3]))) {
            STRLEN d = i;
            while (d > 0 && isDIGIT_A(kb[d - 1]))
                d--;
            if (i - d > 3)
                return NULL;
            i += gl;
            changed = 1;
            continue;
        }
        sv_catpvn(out, kb + i, 1);
        i++;
    }
    return changed ? out : NULL;
}

/* _lookup_k: the meanings of a key in a fixed table and a counted one,
 * from its first spelling that has any; then, where none has, with a
 * number's group separators taken out. */
static void tkn_lookup_k1(pTHX_ tkn_lexicon *L, int fixed, int counted, SV *key, AV *out);

static void
tkn_lookup_k(pTHX_ tkn_lexicon *L, int fixed, int counted, SV *key, AV *out)
{
    SV *u;
    tkn_lookup_k1(aTHX_ L, fixed, counted, key, out);
    if (av_len(out) < 0 && (u = tkn_ungrouped(aTHX_ L, key)))
        tkn_lookup_k1(aTHX_ L, fixed, counted, u, out);
}

static void
tkn_lookup_k1(pTHX_ tkn_lexicon *L, int fixed, int counted, SV *key, AV *out)
{
    SV *sp[2];
    int n = tkn_spellings(aTHX_ key, sp), i;
    for (i = 0; i < n; i++) {
        STRLEN len;
        const char *b = tkn_utf8_bytes(aTHX_ sp[i], &len);
        if (fixed >= 0) {
            I32 si = tkn_tfind(L, &L->t[fixed], b, len), x;
            if (si >= 0)
                for (x = L->t[fixed].s[si].head; x >= 0; x = L->nodes[x].next)
                    av_push(out, SvREFCNT_inc(tkn_meaning_rv(aTHX_ L, L->nodes[x].m)));
        }
        if (counted >= 0)
            tkn_read_counted(aTHX_ L, counted, b, len, out);
        if (av_len(out) >= 0)
            return;
    }
}

/* A value table's entry for a key: the number, or NULL. */
static SV *
tkn_value_of(pTHX_ tkn_lexicon *L, int table, SV *key)
{
    STRLEN len;
    const char *b = tkn_utf8_bytes(aTHX_ key, &len);
    I32 si = tkn_tfind(L, &L->t[table], b, len);
    return si >= 0 ? sv_2mortal(newSViv(L->t[table].s[si].head)) : NULL;
}

/* A key from the arena as a Perl string. */
static SV *
tkn_arena_sv(pTHX_ tkn_lexicon *L, const tkn_slot *s)
{
    SV *sv = newSVpvn(L->arena + s->off, s->len);
    STRLEN i;
    for (i = 0; i < s->len; i++)
        if ((U8)L->arena[s->off + i] >= 0x80) {
            SvUTF8_on(sv);
            break;
        }
    return sv;
}

#endif
