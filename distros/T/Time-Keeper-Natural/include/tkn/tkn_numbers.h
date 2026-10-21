#ifndef TKN_NUMBERS_H
#define TKN_NUMBERS_H

/* Time::Keeper::Natural::Numbers: a locale's number words 0 to 99 and
 * ordinals, one file a locale under share/numbers, read through the
 * locale's chain (its own code, then each shorter one). The object is a
 * blessed hash: code (the file's), c, o and d (a word to its value; d the
 * day ordinals in digits, "15th"). Also the
 * data directory and file reading Words shares. */

/* $INC{...} as a string, or NULL. */
static SV *
tkn_inc(pTHX_ const char *key)
{
    SV **e = hv_fetch(GvHVn(PL_incgv), key, (I32)strlen(key), 0);
    return e && SvTRUE(*e) ? *e : NULL;
}

static int
tkn_is_dir(pTHX_ SV *path)
{
    Stat_t st;
    return PerlLIO_stat(SvPV_nolen(path), &st) == 0 && S_ISDIR(st.st_mode);
}

static int
tkn_is_file(pTHX_ SV *path)
{
    Stat_t st;
    return PerlLIO_stat(SvPV_nolen(path), &st) == 0 && S_ISREG(st.st_mode);
}

static int
tkn_ends_with(SV *sv, const char *tail)
{
    STRLEN n = SvCUR(sv), t = strlen(tail);
    return n >= t && memEQ(SvPVX(sv) + n - t, tail, t);
}

/* The directory of a kind of data (numbers or words) beside the loaded
 * module, else the tree's share/ directory; NULL when nothing is loaded. */
static SV *
tkn_data_dir(pTHX_ int words)
{
    const char *sub = words ? "words" : "numbers";
    SV *pm = words ? tkn_inc(aTHX_ "Time/Keeper/Natural.pm") : tkn_inc(aTHX_ "Time/Keeper/Natural/Numbers.pm");
    SV *d, *p, *tree;
    if (!pm)
        pm = words ? tkn_inc(aTHX_ "Time/Keeper/Natural/Words.pm") : tkn_inc(aTHX_ "Time/Keeper/Natural.pm");
    if (!pm)
        return NULL;
    d = sv_2mortal(newSVsv(pm));
    if (words && tkn_ends_with(d, "/Words.pm")) {
        SvCUR_set(d, SvCUR(d) - 9);
        sv_catpvs(d, ".pm");
    }
    if (!words && tkn_ends_with(d, "/Numbers.pm"))
        SvCUR_set(d, SvCUR(d) - 11);
    if (tkn_ends_with(d, ".pm"))
        SvCUR_set(d, SvCUR(d) - 3);
    *SvEND(d) = '\0';
    p = sv_2mortal(newSVpvf("%" SVf "/%s", SVfARG(d), sub));
    if (tkn_is_dir(aTHX_ p))
        return p;
    if (tkn_ends_with(d, "/lib/Time/Keeper/Natural")) {
        tree = sv_2mortal(newSVpvn(SvPVX(d), SvCUR(d) - 24));
        sv_catpvf(tree, "/share/%s", sub);
        if (tkn_is_dir(aTHX_ tree))
            return tree;
    }
    return p;
}

/* A code and each shorter one: de-CH-1996, de-CH, de. */
static AV *
tkn_chain(pTHX_ SV *code)
{
    AV *av = (AV *)sv_2mortal((SV *)newAV());
    STRLEN len;
    const char *s = SvPV_const(code, len);
    av_push(av, newSVsv(code));
    while (len) {
        STRLEN i = len;
        while (i > 0 && s[i - 1] != '-')
            i--;
        if (!i || i == len)
            break;
        len = i - 1;
        {
            SV *c = newSVpvn(s, len);
            if (SvUTF8(code))
                SvUTF8_on(c);
            av_push(av, c);
        }
    }
    return av;
}

/* The codes that have a file in a data directory, sorted. */
static AV *
tkn_locales(pTHX_ int words)
{
    SV *dir = tkn_data_dir(aTHX_ words);
    AV *av;
    DIR *dh;
    Direntry_t *de;
    if (!dir || !tkn_is_dir(aTHX_ dir))
        return NULL;
    if (!(dh = PerlDir_open(SvPV_nolen(dir))))
        return NULL;
    av = (AV *)sv_2mortal((SV *)newAV());
    while ((de = PerlDir_read(dh))) {
        STRLEN n = strlen(de->d_name);
        if (n > 4 && memEQ(de->d_name + n - 4, ".txt", 4))
            av_push(av, newSVpvn(de->d_name, n - 4));
    }
    PerlDir_close(dh);
    if (av_len(av) > 0)
        sortsv(AvARRAY(av), av_len(av) + 1, Perl_sv_cmp);
    return av;
}

/* A file's text, decoded from UTF-8. */
static SV *
tkn_slurp(pTHX_ SV *path, const char *who)
{
    PerlIO *f = PerlIO_open(SvPV_nolen(path), "rb");
    SV *buf;
    char tmp[8192];
    SSize_t n;
    if (!f)
        tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("%s: cannot read %" SVf ": %s", who, SVfARG(path), Strerror(errno))));
    buf = sv_2mortal(newSVpvs(""));
    while ((n = PerlIO_read(f, tmp, sizeof tmp)) > 0)
        sv_catpvn(buf, tmp, (STRLEN)n);
    PerlIO_close(f);
    if (!is_utf8_string((U8 *)SvPVX(buf), SvCUR(buf)))
        tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("%s: cannot read %" SVf ": it is not UTF-8", who, SVfARG(path))));
    SvUTF8_on(buf);
    return buf;
}

/* The canonical code of a locale argument, or a croak naming who asked. */
static SV *
tkn_code_of(pTHX_ SV *locale, const char *who)
{
    SV *arg = SvOK(locale) ? locale : sv_2mortal(newSVpvs(""));
    SV *code = tkn_call1(aTHX_ TKN_LOC, "code", &arg, 1);
    if (!SvOK(code))
        tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("%s->for: there is no locale '%" SVf "'", who, SVfARG(arg))));
    return code;
}

/* Numbers->for: the number words of a locale's first code in its chain
 * that has a file, or undef. */
static SV *
tkn_numbers_for(pTHX_ SV *klass, SV *locale)
{
    dMY_CXT;
    SV *code = tkn_code_of(aTHX_ locale, "Time::Keeper::Natural::Numbers");
    HE *he = hv_fetch_ent(MY_CXT.numbers, code, 0, 0);
    SV *dir, *obj = NULL;
    AV *chain;
    I32 i;
    if (he)
        return HeVAL(he);
    dir = tkn_data_dir(aTHX_ 0);
    chain = tkn_chain(aTHX_ code);
    for (i = 0; dir && i <= av_len(chain); i++) {
        SV *c = *av_fetch(chain, i, 0);
        SV *file = sv_2mortal(newSVpvf("%" SVf "/%" SVf ".txt", SVfARG(dir), SVfARG(c)));
        SV *text;
        HV *self, *ch, *oh, *dh;
        const char *p, *e;
        if (!tkn_is_file(aTHX_ file))
            continue;
        text = tkn_slurp(aTHX_ file, "Time::Keeper::Natural::Numbers");
        self = newHV();
        ch = newHV();
        oh = newHV();
        dh = newHV();
        obj = newRV_noinc((SV *)self);
        sv_bless(obj, gv_stashsv(klass, GV_ADD));
        (void)hv_stores(self, "code", newSVsv(c));
        (void)hv_stores(self, "c", newRV_noinc((SV *)ch));
        (void)hv_stores(self, "o", newRV_noinc((SV *)oh));
        (void)hv_stores(self, "d", newRV_noinc((SV *)dh));
        p = SvPVX(text);
        e = p + SvCUR(text);
        while (p < e) {
            const char *nl = (const char *)memchr(p, '\n', (size_t)(e - p)), *le = nl ? nl : e;
            const char *t1, *t2, *w;
            HV *into;
            IV val;
            if (le > p && le[-1] == '\r')
                le--;
            if (*p == '#' || !(t1 = (const char *)memchr(p, '\t', (size_t)(le - p)))
                || !(t2 = (const char *)memchr(t1 + 1, '\t', (size_t)(le - t1 - 1)))) {
                p = nl ? nl + 1 : e;
                continue;
            }
            if (t1 - p == 1 && (*p == 'c' || *p == 'o' || *p == 'd')) {
                into = *p == 'c' ? ch : *p == 'o' ? oh : dh;
                val = SvIV(sv_2mortal(newSVpvn(t1 + 1, (STRLEN)(t2 - t1 - 1))));
                for (w = t2 + 1; w < le;) {
                    const char *bar = (const char *)memchr(w, '|', (size_t)(le - w)), *we = bar ? bar : le;
                    if (we > w)
                        (void)hv_store(into, w, -(I32)(we - w), newSViv(val), 0);
                    if (!bar)
                        break;
                    w = bar + 1;
                }
            }
            p = nl ? nl + 1 : e;
        }
        break;
    }
    he = hv_store_ent(MY_CXT.numbers, code, obj ? obj : newSV(0), 0);
    return HeVAL(he);
}

/* 0.01's _variants: lower case, white space runs as one space, trimmed;
 * and with hyphens as spaces when that differs. */
static int
tkn_number_variants(pTHX_ SV *w, SV **out)
{
    STRLEN len;
    const U8 *p = (const U8 *)SvPV_const(w, len), *e = p + len;
    int utf8 = SvUTF8(w) ? 1 : 0, space = 0;
    SV *k = sv_2mortal(newSVpvs(""));
    STRLEN i;
    if (utf8)
        SvUTF8_on(k);
    while (p < e) {
        STRLEN cl = 1;
        UV cp = utf8 ? tkn_utf8_cp(p, e, &cl) : *p;
        if (utf8 ? tkn_is_space_cp(cp) : (cp < 0x80 && isSPACE((U8)cp))) {
            if (!space)
                sv_catpvs(k, " ");
            space = 1;
        }
        else {
            if (cp < 0x80) {
                char c = (char)toLOWER((U8)cp);
                sv_catpvn(k, &c, 1);
            }
            else if (utf8)
                tkn_lower_cat(aTHX_ k, p, e);
            else
                sv_catpvn(k, (const char *)p, 1);
            space = 0;
        }
        p += cl;
    }
    if (SvCUR(k) && SvPVX(k)[0] == ' ')
        sv_chop(k, SvPVX(k) + 1);
    if (SvCUR(k) && SvPVX(k)[SvCUR(k) - 1] == ' ')
        SvCUR_set(k, SvCUR(k) - 1);
    *SvEND(k) = '\0';
    out[0] = k;
    if (!memchr(SvPVX(k), '-', SvCUR(k)))
        return 1;
    out[1] = sv_2mortal(newSVsv(k));
    for (i = 0; i < SvCUR(out[1]); i++)
        if (SvPVX(out[1])[i] == '-')
            SvPVX(out[1])[i] = ' ';
    return 2;
}

/* Numbers->read and ->ordinal: a text's value, through every word's
 * variants, built once a kind. */
static SV *
tkn_numbers_read(pTHX_ SV *self, const char *kind, SV *text)
{
    HV *hv = (HV *)SvRV(self), *by;
    char cache[4] = { '_', kind[0], 'v', 0 };
    SV **e = hv_fetch(hv, cache, 3, 0), *v[2];
    int n, i;
    if (!SvOK(text))
        return NULL;
    if (e && SvROK(*e))
        by = (HV *)SvRV(*e);
    else {
        SV **src = hv_fetch(hv, kind, 1, 0);
        HE *he;
        by = newHV();
        (void)hv_store(hv, cache, 3, newRV_noinc((SV *)by), 0);
        if (src && SvROK(*src)) {
            HV *words = (HV *)SvRV(*src);
            hv_iterinit(words);
            while ((he = hv_iternext(words))) {
                SV *w[2];
                int m = tkn_number_variants(aTHX_ hv_iterkeysv(he), w), j;
                for (j = 0; j < m; j++)
                    (void)hv_store_ent(by, w[j], newSVsv(HeVAL(he)), 0);
            }
        }
    }
    n = tkn_number_variants(aTHX_ text, v);
    for (i = 0; i < n; i++) {
        HE *he = hv_fetch_ent(by, v[i], 0, 0);
        if (he)
            return HeVAL(he);
    }
    return NULL;
}

#endif
