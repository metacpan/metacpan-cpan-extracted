#ifndef TKN_DURATION_H
#define TKN_DURATION_H

/* Durations: the ISO form through Time::Keeper::Duration->parse, the
 * digital clock from the locale's hms, hm and ms patterns, and a chain of
 * unit phrases ("1 hour, 30 minutes"), split where digits start or through
 * the relative grammar's joiners. The parts go to Time::Keeper's C to make
 * the Duration, or to Duration->new where its C refuses, so a death reads
 * as 0.01's did. */

static void tkn_cannot(pTHX_ SV *method, SV *text, SV *token, SV *reason);
static void tkn_carp(pTHX_ const char *fn, SV *msg);

static int
tkn_is_dsep(UV cp)
{
    return tkn_is_space_cp(cp) || cp == ',' || cp == ';' || cp == 0x060C || cp == 0x3001 || cp == 0x1363;
}

/* Whether a text has a letter: /\p{L}/ through Perl's engine past ASCII. */
static int
tkn_has_letter(pTHX_ SV *sv)
{
    dMY_CXT;
    STRLEN len, i;
    const char *b = tkn_utf8_bytes(aTHX_ sv, &len);
    int high = 0;
    SV *s;
    for (i = 0; i < len; i++) {
        if (tkn_ascii_letter(b[i]))
            return 1;
        if ((U8)b[i] >= 0x80)
            high = 1;
    }
    if (!high)
        return 0;
    if (!MY_CXT.re_letter)
        MY_CXT.re_letter = newSVsv(eval_pv("qr/\\p{L}/", TRUE));
    s = sv_2mortal(newSVpvn(b, len));
    SvUTF8_on(s);
    return pregexec(SvRX(MY_CXT.re_letter), SvPVX(s), SvEND(s), SvPVX(s), 0, s, 1) ? 1 : 0;
}

/* $s with white space trimmed from both ends. */
static SV *
tkn_trim_sv(pTHX_ SV *sv)
{
    STRLEN len;
    const char *b = tkn_utf8_bytes(aTHX_ sv, &len), *s = b, *e = b + len;
    SV *out;
    tkn_trim_ws(&s, &e, 1, 1);
    out = sv_2mortal(newSVpvn(s, (STRLEN)(e - s)));
    SvUTF8_on(out);
    return out;
}

/* uc, as Perl writes it. */
static SV *
tkn_uc(pTHX_ SV *sv)
{
    STRLEN len;
    const U8 *p = (const U8 *)tkn_utf8_bytes(aTHX_ sv, &len), *e = p + len;
    SV *out = sv_2mortal(newSVpvs(""));
    SvUTF8_on(out);
    while (p < e) {
        STRLEN cl = UTF8SKIP(p);
        if (p + cl > e)
            cl = (STRLEN)(e - p);
        if (*p < 0x80) {
            char c = (char)toUPPER(*p);
            sv_catpvn(out, &c, 1);
        }
        else {
            U8 buf[UTF8_MAXBYTES_CASE + 1];
            STRLEN bl = 0;
#if PERL_VERSION_GE(5, 26, 0)
            toUPPER_utf8_safe(p, e, buf, &bl);
#else
            to_utf8_upper(p, buf, &bl);
#endif
            sv_catpvn(out, (const char *)buf, bl);
        }
        p += cl;
    }
    return out;
}

/* Class->method(args) in scalar context; NULL when it dies under eval, which
 * leaves $@ set as 0.01's eval did. */
static SV *
tkn_class_call(pTHX_ const char *klass, const char *method, SV **args, int n, int trap)
{
    dSP;
    int i, c;
    SV *r = NULL;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(klass, 0)));
    for (i = 0; i < n; i++)
        XPUSHs(args[i]);
    PUTBACK;
    c = call_method(method, G_SCALAR | (trap ? G_EVAL : 0));
    SPAGAIN;
    if (c) {
        SV *top = POPs;
        if (!(trap && SvTRUE(ERRSV)))
            r = newSVsv(top);
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return r ? sv_2mortal(r) : NULL;
}

/* Duration->new(name => value, ...): Time::Keeper's C while the parts are
 * integers it holds, else the method. */
static SV *
tkn_new_duration(pTHX_ const char *const *names, SV **vals, int n)
{
    time_keeper_parts parts;
    int i, ok = 1;
    Zero(&parts, 1, time_keeper_parts);
    for (i = 0; i < n && ok; i++) {
        int64_t x;
        if (!tkn_small(aTHX_ vals[i], &x)) {
            ok = 0;
            break;
        }
        if (strEQ(names[i], "years")) parts.years += x;
        else if (strEQ(names[i], "months")) parts.months += x;
        else if (strEQ(names[i], "weeks")) parts.weeks += x;
        else if (strEQ(names[i], "days")) parts.days += x;
        else if (strEQ(names[i], "hours")) parts.hours += x;
        else if (strEQ(names[i], "minutes")) parts.minutes += x;
        else if (strEQ(names[i], "seconds")) parts.seconds += x;
        else if (strEQ(names[i], "nanoseconds")) parts.nanoseconds += x;
        else ok = 0;
    }
    if (ok) {
        SV *d = (TKN_TK->new_duration_sv)(aTHX_ &parts);
        if (d)
            return sv_2mortal(d);
    }
    {
        SV **args;
        int k = 0;
        Newx(args, 2 * n + 1, SV *);
        SAVEFREEPV(args);
        for (i = 0; i < n; i++) {
            args[k++] = sv_2mortal(newSVpv(names[i], 0));
            args[k++] = vals[i];
        }
        return tkn_class_call(aTHX_ "Time::Keeper::Duration", "new", args, k, 0);
    }
}

/* The separators of a digital pattern (h:mm:ss): sep[0], and sep[1] for the
 * seconds; 0 unless it is /^[hm]+([^hms]+)[ms]+(?:([^hms]+)s+)?\z/. */
static int
tkn_digital_seps(const char *p, STRLEN n, const char **s0, STRLEN *l0, const char **s1, STRLEN *l1)
{
    STRLEN i = 0, a;
    *s1 = NULL;
    *l1 = 0;
    while (i < n && (p[i] == 'h' || p[i] == 'm'))
        i++;
    if (!i)
        return 0;
    a = i;
    while (i < n && p[i] != 'h' && p[i] != 'm' && p[i] != 's')
        i++;
    if (i == a)
        return 0;
    *s0 = p + a;
    *l0 = i - a;
    a = i;
    while (i < n && (p[i] == 'm' || p[i] == 's'))
        i++;
    if (i == a)
        return 0;
    if (i == n)
        return 1;
    /* [ms]+ took what it could; the optional group needs its own [ms]+ to
       end before a separator, so give back to the last m or s run's start. */
    {
        STRLEN b = i;
        while (b < n && p[b] != 'h' && p[b] != 'm' && p[b] != 's')
            b++;
        if (b == i || b == n)
            return 0;
        *s1 = p + i;
        *l1 = b - i;
        i = b;
        if (p[i] != 's')
            return 0;
        while (i < n && p[i] == 's')
            i++;
        return i == n;
    }
}

static STRLEN
tkn_digits_at(const char *s, STRLEN i, STRLEN n)
{
    STRLEN j = i;
    while (j < n && s[j] >= '0' && s[j] <= '9')
        j++;
    return j - i;
}

/* The digital clock: raw read against the locale's pattern of a kind. */
static SV *
tkn_digital(pTHX_ tkn_lexicon *L, const char *kind, SV *raw)
{
    SV *p = tkn_hget(aTHX_ L->digital, kind);
    STRLEN pl, n, i = 0, d;
    const char *pb, *s, *s0, *s1;
    STRLEN l0, l1;
    SV *f[4] = { NULL, NULL, NULL, NULL };
    int hms = strEQ(kind, "hms");
    if (!p)
        return NULL;
    pb = tkn_utf8_bytes(aTHX_ p, &pl);
    if (!tkn_digital_seps(pb, pl, &s0, &l0, &s1, &l1))
        return NULL;
    if (hms && !s1)
        s1 = "", l1 = 0;
    s = tkn_utf8_bytes(aTHX_ raw, &n);
    d = tkn_digits_at(s, 0, n);
    if (!d || i + d + l0 > n || memNE(s + d, s0, l0))
        return NULL;
    f[0] = sv_2mortal(newSVpvn(s, d));
    i = d + l0;
    d = tkn_digits_at(s, i, n);
    if (hms && !l1) {
        /* ([0-9]{1,2})([0-9]{1,2}): the first takes two unless the second
           would be left with none. */
        STRLEN a = d >= 3 ? 2 : 1;
        if (d < 2 || d > 4)
            return NULL;
        f[1] = sv_2mortal(newSVpvn(s + i, a));
        i += a;
    }
    else {
        if (d < 1 || d > 2)
            return NULL;
        f[1] = sv_2mortal(newSVpvn(s + i, d));
        i += d;
    }
    if (hms) {
        if (i + l1 > n || (l1 && memNE(s + i, s1, l1)))
            return NULL;
        i += l1;
        d = tkn_digits_at(s, i, n);
        if (d < 1 || d > 2)
            return NULL;
        f[2] = sv_2mortal(newSVpvn(s + i, d));
        i += d;
        if (i < n && (s[i] == '.' || s[i] == ',')) {
            d = tkn_digits_at(s, i + 1, n);
            if (d < 1 || d > 9)
                return NULL;
            f[3] = sv_2mortal(newSVpvn(s + i + 1, d));
            i += 1 + d;
        }
    }
    if (i != n)
        return NULL;
    {
        const char *names[4];
        SV *vals[4];
        int m = 0;
        if (hms) {
            names[m] = "hours"; vals[m++] = f[0];
            names[m] = "minutes"; vals[m++] = f[1];
            names[m] = "seconds"; vals[m++] = f[2];
            if (f[3]) {
                SV *ns = sv_2mortal(newSVsv(f[3]));
                sv_catpvs(ns, "000000000");
                SvCUR_set(ns, 9);
                *SvEND(ns) = '\0';
                names[m] = "nanoseconds"; vals[m++] = ns;
            }
        }
        else if (strEQ(kind, "hm")) {
            names[m] = "hours"; vals[m++] = f[0];
            names[m] = "minutes"; vals[m++] = f[1];
        }
        else {
            names[m] = "minutes"; vals[m++] = f[0];
            names[m] = "seconds"; vals[m++] = f[1];
        }
        return tkn_new_duration(aTHX_ names, vals, m);
    }
}

static int
tkn_is_jword_in(pTHX_ AV *words, const char *s, STRLEN n)
{
    I32 i;
    for (i = 0; i <= av_len(words); i++) {
        STRLEN wl;
        const char *w = SvPV_const(*av_fetch(words, i, 0), wl);
        if (wl == n && memEQ(w, s, n))
            return 1;
    }
    return 0;
}

/* The joiner words a digit split drops: each joiner without its leading
 * punctuation and spaces and its trailing spaces, when one word. */
static void
tkn_dwords(pTHX_ tkn_lexicon *L)
{
    I32 i;
    if (L->dwords)
        return;
    L->dwords = newAV();
    for (i = 0; i <= av_len(L->jword); i++) {
        STRLEN len;
        const char *b = SvPV_const(*av_fetch(L->jword, i, 0), len), *s = b, *e = b + len, *q;
        int has_ws = 0;
        STRLEN cl;
        while (s < e && tkn_is_dsep(tkn_utf8_cp((const U8 *)s, (const U8 *)e, &cl)))
            s += cl;
        tkn_trim_ws(&s, &e, 0, 1);
        for (q = s; q < e; q += cl)
            if (tkn_is_space_cp(tkn_utf8_cp((const U8 *)q, (const U8 *)e, &cl)))
                has_ws = 1;
        if (e > s && !has_ws) {
            SV *w = newSVpvn(s, (STRLEN)(e - s));
            SvUTF8_on(w);
            av_push(L->dwords, w);
        }
    }
}

static const char *
tkn_trim_dsep_end(const char *s, const char *e)
{
    while (e > s) {
        const char *q = e - 1;
        STRLEN cl;
        while (q > s && ((U8)*q & 0xC0) == 0x80)
            q--;
        if (!tkn_is_dsep(tkn_utf8_cp((const U8 *)q, (const U8 *)e, &cl)))
            break;
        e = q;
    }
    return e;
}

/* _digit_split: a chain split where each number starts ("1h 30m"), each
 * piece without a trailing joiner word; NULL unless every piece reads. */
static AV *
tkn_digit_split(pTHX_ tkn_lexicon *L, SV *ksv, tkn_reader *r)
{
    STRLEN klen, a = 0, q;
    const char *k = tkn_utf8_bytes(aTHX_ ksv, &klen);
    AV *pieces = (AV *)sv_2mortal((SV *)newAV()), *res = (AV *)sv_2mortal((SV *)newAV());
    I32 i;
    for (q = 0; q <= klen; q++)
        if (q == klen || (q > 0 && k[q] >= '0' && k[q] <= '9' && !(k[q - 1] >= '0' && k[q - 1] <= '9'))) {
            if (q > a)
                av_push(pieces, newSVpvn(k + a, q - a));
            a = q;
        }
    if (av_len(pieces) < 1)
        return NULL;
    tkn_dwords(aTHX_ L);
    for (i = 0; i <= av_len(pieces); i++) {
        STRLEN pl;
        const char *p = SvPV_const(*av_fetch(pieces, i, 0), pl), *e, *t;
        AV *m;
        if (!pl || p[0] < '0' || p[0] > '9')
            return NULL;
        e = tkn_trim_dsep_end(p, p + pl);
        t = e;
        while (t > p) {
            const char *b = t - 1;
            STRLEN cl;
            while (b > p && ((U8)*b & 0xC0) == 0x80)
                b--;
            if (tkn_is_space_cp(tkn_utf8_cp((const U8 *)b, (const U8 *)e, &cl)))
                break;
            t = b;
        }
        if (t > p && t < e) {
            const char *b = t - 1;
            STRLEN cl;
            while (b > p && ((U8)*b & 0xC0) == 0x80)
                b--;
            if (tkn_is_space_cp(tkn_utf8_cp((const U8 *)b, (const U8 *)e, &cl)) && tkn_is_jword_in(aTHX_ L->dwords, t, (STRLEN)(e - t)))
                e = tkn_trim_dsep_end(p, t);
        }
        m = tkn_read_piece(aTHX_ r, p, (STRLEN)(e - p));
        if (av_len(m) < 0)
            return NULL;
        av_push(res, tkn_group_rv(aTHX_ p, (STRLEN)(e - p), m));
    }
    return res;
}

/* _duration_value: the duration a key reads as, or NULL (with the token and
 * reason where it stopped). */
static SV *
tkn_duration_value(pTHX_ tkn_lexicon *L, SV *ksv, SV *text, HV *info)
{
    STRLEN klen;
    const char *k = tkn_utf8_bytes(aTHX_ ksv, &klen);
    int letters = tkn_has_letter(aTHX_ ksv), iso = klen && k[0] == 'p';
    SV *raw = sv_2mortal(newSVpvs(""));
    tkn_reader r;
    AV *groups, *lists, *chosen;
    I32 i;
    if (!letters || iso)
        raw = tkn_trim_sv(aTHX_ tkn_ascii_digits(aTHX_ text, L->has_digits ? L->digits : NULL));
    if (iso) {
        SV *arg = tkn_uc(aTHX_ raw);
        SV *d = tkn_class_call(aTHX_ "Time::Keeper::Duration", "parse", &arg, 1, 1);
        if (d && SvTRUE(d))
            return d;
    }
    if (!letters) {
        static const char *const kinds[3] = { "hms", "hm", "ms" };
        int x;
        for (x = 0; x < 3; x++) {
            SV *d = tkn_digital(aTHX_ L, kinds[x], raw);
            if (d)
                return d;
        }
    }
    r.L = L;
    r.code = NULL;
    r.unit = 1;
    r.memo = (HV *)sv_2mortal((SV *)newHV());
    groups = tkn_digit_split(aTHX_ L, ksv, &r);
    if (!groups)
        groups = tkn_groups(aTHX_ L, ksv, info, &r, 1);
    if (!groups)
        return NULL;
    lists = (AV *)sv_2mortal((SV *)newAV());
    for (i = 0; i <= av_len(groups); i++)
        av_push(lists, newSVsv(*av_fetch((AV *)SvRV(*av_fetch(groups, i, 0)), 1, 0)));
    chosen = tkn_choose(aTHX_ lists);
    {
        static const char *const keys[8] = { "years", "months", "weeks", "days", "hours", "minutes", "seconds", "nanoseconds" };
        SV *sum[8] = { NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL }, *vals[8];
        const char *names[8];
        HV *seen = (HV *)sv_2mortal((SV *)newHV());
        int x, m = 0;
        for (i = 0; i <= av_len(chosen); i++) {
            HV *mh = tkn_rv_hv(aTHX_ *av_fetch(chosen, i, 0), "a meaning");
            const char *f = tkn_hstr(aTHX_ mh, "field");
            SV *c = tkn_hsv(aTHX_ mh, "count");
            IV ns;
            if (!f)
                f = "";
            if (hv_exists(seen, f, (I32)strlen(f))) {
                (void)hv_stores(info, "token", newSVsv(*av_fetch((AV *)SvRV(*av_fetch(groups, i, 0)), 0, 0)));
                (void)hv_stores(info, "reason", newSVpvf("%s is given twice", f));
                return NULL;
            }
            (void)hv_store(seen, f, (I32)strlen(f), &PL_sv_yes, 0);
            if (!c)
                c = sv_2mortal(newSViv(0));
            if ((ns = tkn_nanos_of(f)))
                sum[7] = tkn_add_sv(aTHX_ sum[7], tkn_mul(aTHX_ c, ns));
            else {
                int q;
                const char *u = tkn_units_of(f, &q);
                if (!u)
                    croak("Time::Keeper::Natural: '%s' is not a unit", f);
                for (x = 0; x < 8 && strNE(keys[x], u); x++)
                    ;
                sum[x] = tkn_add_sv(aTHX_ sum[x], c);
            }
        }
        for (x = 0; x < 8; x++)
            if (sum[x]) {
                names[m] = keys[x];
                vals[m++] = sum[x];
            }
        return tkn_new_duration(aTHX_ names, vals, m);
    }
}

static SV *tkn_frac_duration(pTHX_ tkn_lexicon *L, SV *text, HV *info);

/* _first_token: the text's first run of non-spaces, or ''. */
static SV *
tkn_first_token(pTHX_ SV *text)
{
    STRLEN len;
    const char *b, *s, *e, *t;
    SV *out;
    if (!SvOK(text))
        return sv_2mortal(newSVpvs(""));
    b = SvPV_const(text, len);
    s = b;
    e = b + len;
    if (SvUTF8(text))
        tkn_trim_ws(&s, &e, 1, 0);
    else
        while (s < e && isSPACE(*s))
            s++;
    for (t = s; t < e;) {
        STRLEN cl = 1;
        UV cp = SvUTF8(text) ? tkn_utf8_cp((const U8 *)t, (const U8 *)e, &cl) : (U8)*t;
        if (SvUTF8(text) ? tkn_is_space_cp(cp) : (cp < 0x80 && isSPACE((U8)cp)))
            break;
        t += cl;
    }
    out = sv_2mortal(newSVpvn(s, (STRLEN)(t - s)));
    if (SvUTF8(text))
        SvUTF8_on(out);
    return out;
}

/* _duration: the Duration a text reads as, and its info; else the death,
 * through _cannot. */
static SV *
tkn_duration(pTHX_ SV *self, SV *method, SV *text, HV **info_out)
{
    SV *lexsv, *k, *d;
    tkn_lexicon *L;
    HV *info;
    if (!SvOK(text))
        tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("Time::Keeper::Natural->%" SVf ": the text is undefined", SVfARG(method))));
    {
        SV *words;
        tkn_lex_words(aTHX_ self, &lexsv, &words);
    }
    L = tkn_lex(aTHX_ lexsv);
    k = tkn_key_sv(aTHX_ L, text);
    if (!SvCUR(k)) {
        tkn_cannot(aTHX_ method, text, sv_2mortal(newSVpvs("")), sv_2mortal(newSVpvs("the text is empty")));
    }
    info = (HV *)sv_2mortal((SV *)newHV());
    (void)hv_stores(info, "precision", newSVpvs("none"));
    (void)hv_stores(info, "assumed", newRV_noinc((SV *)newAV()));
    d = tkn_duration_value(aTHX_ L, k, text, info);
    /* 0.01's "return ($d, \%info) if $d": a Duration of nothing is false. */
    if (d && SvTRUE(d)) {
        *info_out = info;
        return d;
    }
    {
        /* a number in groups of three ("1,500 seconds", "1.500 Sekunden") */
        SV *u = tkn_ungrouped(aTHX_ L, k);
        if (u) {
            HV *ui = (HV *)sv_2mortal((SV *)newHV());
            (void)hv_stores(ui, "precision", newSVpvs("none"));
            (void)hv_stores(ui, "assumed", newRV_noinc((SV *)newAV()));
            d = tkn_duration_value(aTHX_ L, u, u, ui);
            if (d && SvTRUE(d)) {
                *info_out = ui;
                return d;
            }
        }
    }
    {
        HV *fi = (HV *)sv_2mortal((SV *)newHV());
        SV *fd = tkn_frac_duration(aTHX_ L, text, fi);
        if (fd) {
            *info_out = info;
            return fd;
        }
        if (tkn_hsv(aTHX_ fi, "reason")) {
            (void)hv_stores(info, "reason", newSVsv(tkn_hsv(aTHX_ fi, "reason")));
            (void)hv_stores(info, "token", newSVsv(tkn_hsv(aTHX_ fi, "token")));
        }
    }
    if (!tkn_hsv(aTHX_ info, "reason")) {
        HV *scratch = (HV *)sv_2mortal((SV *)newHV());
        STRLEN kl;
        const char *kb = tkn_utf8_bytes(aTHX_ k, &kl);
        (void)hv_stores(scratch, "assumed", newRV_noinc((SV *)newAV()));
        if (tkn_relative(aTHX_ self, L, k, scratch, NULL)) {
            (void)hv_stores(info, "reason", newSVpvs("a time, not a duration"));
            (void)hv_stores(info, "token", newSVsv(tkn_first_token(aTHX_ text)));
        }
        else if (kl && (kb[0] == '-' || kb[0] == '+' || (kl >= 3 && memEQ(kb, "\xE2\x88\x92", 3)))) {
            (void)hv_stores(info, "reason", newSVpvs("a sign; a duration is unsigned"));
            (void)hv_stores(info, "token", newSVpvn_flags(kb, kb[0] == '-' || kb[0] == '+' ? 1 : 3, SVf_UTF8));
        }
    }
    {
        SV *tok = tkn_hsv(aTHX_ info, "token"), *reason = tkn_hsv(aTHX_ info, "reason");
        tkn_cannot(aTHX_ method, text, tok ? tok : tkn_first_token(aTHX_ text),
                   reason ? reason : sv_2mortal(newSVpvf("no such word in %" SVf, SVfARG(L->code))));
    }
    croak("Time::Keeper::Natural: _cannot returned");
    return NULL;
}

#endif
