#ifndef TKN_ABSOLUTE_H
#define TKN_ABSOLUTE_H

/* Absolute dates and times: what Time::Keeper->parse reads (ISO 8601 and
 * the RFC forms), then the locale's own patterns through Time::Keeper's
 * parse_cldr in C, the year added to a pattern without one; a time of day
 * from the time patterns, a bare hour, a day period ("noon", "3 in the
 * afternoon"); and a day and a time together. The grammar around these
 * (_day, _after, _skip) is still Perl and is called as methods. */

typedef struct {
    IV hour, minute, second, nanosecond;
} tkn_tod;

/* The word grammar's, in tkn_grammar.h. */
static int tkn_after(pTHX_ SV *words, tkn_lexicon *L, SV *text, const char *key, SV **rest, SV **rk, SV **raw);
static void tkn_skip(pTHX_ SV *words, tkn_lexicon *L, SV **text, SV **k);
static SV *tkn_day(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *text, SV *k, HV *info);

/* _trim: no white space at either end, and a run of two or more as one
 * space. */
static SV *
tkn_trim(pTHX_ SV *text)
{
    STRLEN len;
    const char *b = SvPV_const(text, len), *s = b, *e = b + len;
    int utf8 = SvUTF8(text) ? 1 : 0;
    SV *out = sv_2mortal(newSVpvs(""));
    if (utf8)
        SvUTF8_on(out);
#define TKN_WS(p, cl) (utf8 ? tkn_is_space_cp(tkn_utf8_cp((const U8 *)(p), (const U8 *)e, &(cl))) \
                            : ((cl) = 1, isSPACE_A(*(p))))
    for (;;) {
        STRLEN cl;
        if (s < e && TKN_WS(s, cl)) {
            s += cl;
            continue;
        }
        break;
    }
    while (e > s) {
        const char *q = e - 1;
        STRLEN cl;
        if (utf8)
            while (q > s && ((U8)*q & 0xC0) == 0x80)
                q--;
        if (!TKN_WS(q, cl))
            break;
        e = q;
    }
    while (s < e) {
        STRLEN cl;
        if (TKN_WS(s, cl)) {
            const char *q = s + cl;
            int n = 1;
            for (;;) {
                STRLEN c2;
                if (q < e && TKN_WS(q, c2)) {
                    q += c2;
                    n++;
                    continue;
                }
                break;
            }
            if (n >= 2)
                sv_catpvs(out, " ");
            else
                sv_catpvn(out, s, cl);
            s = q;
            continue;
        }
        sv_catpvn(out, s, cl);
        s += cl;
    }
#undef TKN_WS
    return out;
}

static int
tkn_locale_id(pTHX_ tkn_lexicon *L)
{
    if (!L->locale_id) {
        STRLEN n;
        const char *c = SvPV_const(L->code, n);
        L->locale_id = (TKN_TK->locale_find)(c, n) + 1;
    }
    return L->locale_id - 1;
}

static int
tkn_h24(pTHX_ tkn_lexicon *L)
{
    if (!L->h24) {
        SV *r = tkn_call1(aTHX_ TKN_LOC, "prefers_24_hour_time", &L->code, 1);
        L->h24 = SvTRUE(r) ? 2 : 1;
    }
    return L->h24 == 2;
}

static AV *
tkn_dprules(pTHX_ tkn_lexicon *L)
{
    if (!L->dprules) {
        AV *r = tkn_call(aTHX_ TKN_LOC, "day_period_rules", &L->code, 1);
        L->dprules = (AV *)SvREFCNT_inc((SV *)r);
    }
    return L->dprules;
}

/* The rule of a day period, or NULL. */
static HV *
tkn_dprule(pTHX_ tkn_lexicon *L, SV *period)
{
    AV *rules = tkn_dprules(aTHX_ L);
    I32 i;
    HV *found = NULL;
    for (i = 0; i <= av_len(rules); i++) {
        SV **e = av_fetch(rules, i, 0);
        HV *r;
        SV *p;
        if (!e || !SvROK(*e) || SvTYPE(SvRV(*e)) != SVt_PVHV)
            continue;
        r = (HV *)SvRV(*e);
        p = tkn_hsv(aTHX_ r, "period");
        if (p && sv_eq(p, period))
            found = r;
    }
    return found;
}

static void
tkn_civil_of(pTHX_ SV *v, time_keeper_civil *c)
{
    time_keeper_point p;
    tkn_pt(aTHX_ v, &p);
    if ((TKN_TK->civil)(aTHX_ &p.inst, &p.zone, c) != TIME_KEEPER_OK)
        croak("Time::Keeper::Natural: a value Time::Keeper cannot read");
}

/* _at_time: the day with the time of day, gap forward. */
static SV *
tkn_at_time(pTHX_ SV *day, const tkn_tod *t)
{
    time_keeper_point in, out;
    tkn_pt(aTHX_ day, &in);
    if (t->hour >= 0 && t->hour <= 24 && t->minute >= 0 && t->minute < 60 && t->second >= 0 && t->second <= 60
        && t->nanosecond >= 0 && t->nanosecond < 1000000000
        && (TKN_TK->with_time)(aTHX_ &in, (int)t->hour, (int)t->minute, (int)t->second, (int32_t)t->nanosecond,
                               TIME_KEEPER_GAP_FORWARD, TIME_KEEPER_OVERLAP_EARLIER, &out, NULL, 0) == TIME_KEEPER_OK)
        return tkn_pt_sv(aTHX_ &out);
    {
        SV *args[10];
        args[0] = sv_2mortal(newSVpvs("hour"));
        args[1] = sv_2mortal(newSViv(t->hour));
        args[2] = sv_2mortal(newSVpvs("minute"));
        args[3] = sv_2mortal(newSViv(t->minute));
        args[4] = sv_2mortal(newSVpvs("second"));
        args[5] = sv_2mortal(newSViv(t->second));
        args[6] = sv_2mortal(newSVpvs("nanosecond"));
        args[7] = sv_2mortal(newSViv(t->nanosecond));
        args[8] = sv_2mortal(newSVpvs("gap"));
        args[9] = sv_2mortal(newSVpvs("forward"));
        return tkn_method(aTHX_ day, "with", args, 10);
    }
}

/* A time of day as 0.01 handed it round, and back. */
static SV *
tkn_tod_hv(pTHX_ const tkn_tod *t, int only_hour, int with_minute)
{
    HV *hv = newHV();
    (void)hv_stores(hv, "hour", newSViv(t->hour));
    if (!only_hour) {
        (void)hv_stores(hv, "minute", newSViv(t->minute));
        if (!with_minute) {
            (void)hv_stores(hv, "second", newSViv(t->second));
            (void)hv_stores(hv, "nanosecond", newSViv(t->nanosecond));
        }
    }
    return sv_2mortal(newRV_noinc((SV *)hv));
}

static void
tkn_tod_of(pTHX_ SV *rv, tkn_tod *t)
{
    HV *hv = tkn_rv_hv(aTHX_ rv, "a time of day");
    SV *v;
    t->hour = (v = tkn_hsv(aTHX_ hv, "hour")) ? SvIV(v) : 0;
    t->minute = (v = tkn_hsv(aTHX_ hv, "minute")) && SvTRUE(v) ? SvIV(v) : 0;
    t->second = (v = tkn_hsv(aTHX_ hv, "second")) && SvTRUE(v) ? SvIV(v) : 0;
    t->nanosecond = (v = tkn_hsv(aTHX_ hv, "nanosecond")) && SvTRUE(v) ? SvIV(v) : 0;
}

static I32
tkn_digit_runs(const char *s, STRLEN n)
{
    STRLEN i;
    I32 runs = 0;
    for (i = 0; i < n; i++)
        if (s[i] >= '0' && s[i] <= '9' && (i == 0 || s[i - 1] < '0' || s[i - 1] > '9'))
            runs++;
    return runs;
}

static int
tkn_has_all_punct(pTHX_ HV *p, const char *raw, STRLEN rl)
{
    SV **pu = hv_fetchs(p, "punct", 0);
    AV *av;
    I32 i;
    if (!pu || !SvROK(*pu))
        return 1;
    av = (AV *)SvRV(*pu);
    for (i = 0; i <= av_len(av); i++) {
        STRLEN cl;
        const char *c = SvPV_const(*av_fetch(av, i, 0), cl);
        if (!cl)
            continue;
        if (cl > rl || !ninstr(raw, raw + rl, c, c + cl))
            return 0;
    }
    return 1;
}

static IV tkn_piv(pTHX_ HV *p, const char *key);

/* The lexicon's patterns, and beside them in C what the ladders test
 * first, so a pattern that cannot fit costs no hash lookup. */
static void
tkn_patterns_of(pTHX_ tkn_lexicon *L)
{
    I32 i, n;
    if (L->patterns)
        return;
    L->patterns = tkn_patterns_build(aTHX_ L);
    n = av_len(L->patterns) + 1;
    Newxz(L->pmeta, n ? n : 1, tkn_pmeta);
    for (i = 0; i < n; i++) {
        HV *p = (HV *)SvRV(*av_fetch(L->patterns, i, 0));
        const char *kind = tkn_hstr(aTHX_ p, "kind");
        L->pmeta[i].kind = kind && strEQ(kind, "date") ? 'd' : kind && strEQ(kind, "time") ? 't' : 'o';
        L->pmeta[i].numeric = (I8)tkn_piv(aTHX_ p, "numeric");
        L->pmeta[i].alpha = (I8)tkn_piv(aTHX_ p, "alpha");
        L->pmeta[i].month_name = (I8)(tkn_piv(aTHX_ p, "month_name") ? 1 : 0);
    }
}

static IV
tkn_piv(pTHX_ HV *p, const char *key)
{
    SV *v = tkn_hsv(aTHX_ p, key);
    return v ? SvIV(v) : 0;
}

/* What 0.01's regex took from a death: "2026-10-15 was a Thursday". */
static SV *
tkn_weekday_reason(pTHX_ const char *err)
{
    const char *colon = NULL, *q, *was, *e = err + strlen(err);
    for (q = err; (q = strstr(q, ": ")); q += 2)
        colon = q;
    if (!colon)
        return NULL;
    q = colon + 2;
    while (e > q && (e[-1] == '\n' || e[-1] == '.'))
        e--;
    was = strstr(q, " was a");
    if (!was || was == q)
        return NULL;
    {
        const char *s;
        for (s = q; s < was; s++)
            if (isSPACE_A(*s))
                return NULL;
        s = was + 6;
        if (s < e && *s == 'n')
            s++;
        if (s >= e || *s != ' ')
            return NULL;
        s++;
        if (s >= e)
            return NULL;
        for (; s < e; s++)
            if (isSPACE_A(*s))
                return NULL;
    }
    return sv_2mortal(newSVpvn(q, (STRLEN)(e - q)));
}

/* parse_cldr through Time::Keeper's C: a value (kind VALUE) in the anchor's
 * zone, or a time of day (kind TIME) into tod. */
static int
tkn_cldr(pTHX_ tkn_lexicon *L, SV *anchor, SV *txt, SV *pat, int kind, SV **value, tkn_tod *tod, char *err, size_t errlen)
{
    time_keeper_point a, out;
    time_keeper_civil clock;
    STRLEN tl, pl;
    const char *tb = tkn_utf8_bytes(aTHX_ txt, &tl), *pb = tkn_utf8_bytes(aTHX_ pat, &pl);
    int code;
    err[0] = '\0';
    if (kind == TIME_KEEPER_KIND_VALUE)
        tkn_pt(aTHX_ anchor, &a);
    code = (TKN_TK->parse_cldr)(aTHX_ tb, tl, pb, pl, kind, kind == TIME_KEEPER_KIND_VALUE ? &a.zone : NULL,
                                tkn_locale_id(aTHX_ L), L->cal_id, TIME_KEEPER_GAP_FAIL, TIME_KEEPER_OVERLAP_EARLIER,
                                &out, &clock, err, errlen);
    if (code != TIME_KEEPER_OK)
        return code;
    if (kind == TIME_KEEPER_KIND_VALUE)
        *value = tkn_pt_sv(aTHX_ &out);
    else {
        tod->hour = clock.hour;
        tod->minute = clock.minute;
        tod->second = clock.second;
        tod->nanosecond = clock.nanosecond;
    }
    return TIME_KEEPER_OK;
}

static SV *
tkn_self_opt(pTHX_ SV *self, const char *key)
{
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        return NULL;
    return tkn_hsv(aTHX_ (HV *)SvRV(self), key);
}

/* _prefer_year: a date with no year moved to the side prefer names. */
static SV *
tkn_prefer_year(pTHX_ SV *self, SV *anchor, SV *v)
{
    SV *prefer = tkn_self_opt(aTHX_ self, "prefer");
    time_keeper_civil d, t;
    int cmp;
    const char *pf;
    if (!prefer || !SvTRUE(prefer))
        return v;
    pf = SvPV_nolen(prefer);
    tkn_civil_of(aTHX_ v, &d);
    tkn_civil_of(aTHX_ anchor, &t);
    cmp = d.year != t.year ? (d.year < t.year ? -1 : 1) : d.month != t.month ? (d.month < t.month ? -1 : 1)
        : d.day != t.day ? (d.day < t.day ? -1 : 1) : 0;
    if ((strEQ(pf, "future") && cmp < 0) || (strEQ(pf, "past") && cmp > 0)) {
        SV *args[4];
        args[0] = sv_2mortal(newSVpvs("years"));
        args[1] = sv_2mortal(newSViv(strEQ(pf, "future") ? 1 : -1));
        args[2] = sv_2mortal(newSVpvs("end_of_month"));
        args[3] = sv_2mortal(newSVpvs("limit"));
        return tkn_method(aTHX_ v, "plus", args, 4);
    }
    return v;
}

static AV *tkn_try_call(pTHX_ SV *inv, const char *method, SV **args, int n, I32 ctx);

/* _by_pattern: the text read with one of the locale's patterns. */
static SV *
tkn_by_pattern(pTHX_ SV *self, tkn_lexicon *L, SV *anchor, SV *raw, HV *p, HV *info)
{
    STRLEN rl;
    const char *rb = tkn_utf8_bytes(aTHX_ raw, &rl);
    SV *txt, *pat, *value = NULL;
    const char *kind = tkn_hstr(aTHX_ p, "kind");
    int is_time = kind && strEQ(kind, "time"), has_year = (int)tkn_piv(aTHX_ p, "year");
    int cyclic = L->calendar && (strEQ(SvPV_nolen(L->calendar), "chinese") || strEQ(SvPV_nolen(L->calendar), "dangi"))
                 && tkn_piv(aTHX_ p, "y_run") > 0;
    /* the Japanese years are an era's, short with or without the era
       written; the Minguo's are three digits now, and BE 69 is not 2569 */
    int era_years = L->calendar && strEQ(SvPV_nolen(L->calendar), "japanese");
    IV y_run = tkn_piv(aTHX_ p, "y_run");
    tkn_tod tod;
    char *err;
    STRLEN errlen = rl + 256;
    time_keeper_civil ac;
    Newx(err, errlen, char);
    SAVEFREEPV(err);
    if (!tkn_has_all_punct(aTHX_ p, rb, rl))
        return NULL;
    /* a year written in full has three digits or more; a Japanese era's
       ("令和8年"), or the Chinese and Korean calendars' place in the cycle
       of sixty, need not */
    if (has_year && y_run != 2 && !cyclic && !era_years
        && !(L->calendar && (IV)tkn_digit_runs(rb, rl) < tkn_piv(aTHX_ p, "numeric"))) {
        STRLEN i;
        int three = 0;
        for (i = 0; i + 2 < rl && !three; i++)
            if (isDIGIT_A(rb[i]) && isDIGIT_A(rb[i + 1]) && isDIGIT_A(rb[i + 2]))
                three = 1;
        if (!three)
            return NULL;
    }
    txt = sv_2mortal(newSVpvn(rb, rl));
    SvUTF8_on(txt);
    pat = sv_2mortal(newSVsv(tkn_hsv(aTHX_ p, "pattern")));
    tkn_civil_of(aTHX_ anchor, &ac);
    if (cyclic) {
        /* Time::Keeper reads the place in the cycle as y and takes the
           nearest year in that place; it refuses yy */
        STRLEN j;
        SV *p2 = sv_2mortal(newSVpvs(""));
        const char *pb = SvPVX(pat);
        for (j = 0; j < SvCUR(pat); j++)
            if (!(pb[j] == 'y' && j + 1 < SvCUR(pat) && pb[j + 1] == 'y'))
                sv_catpvn(p2, pb + j, 1);
        if (SvUTF8(pat))
            SvUTF8_on(p2);
        pat = p2;
    }
    if (!is_time && !has_year && L->calendar) {
        /* the anchor's year in the calendar, as its continuous year; a year
           of the cycle by its name ("ding-wei") Time::Keeper places nearest */
        if (!tkn_piv(aTHX_ p, "cyclic_name")) {
            SV *u = sv_2mortal(newSVpvs("u")), *en = sv_2mortal(newSVpvs("en"));
            sv_catpvs(txt, " ");
            sv_catsv(txt, tkn_method(aTHX_ tkn_method(aTHX_ anchor, "in_locale", &en, 1), "format", &u, 1));
            sv_catpvs(pat, " u");
        }
    }
    else if (!is_time && !has_year) {
        sv_catpvf(txt, " %" IVdf, (IV)ac.year);
        sv_catpvs(pat, " y");
    }
    if (tkn_cldr(aTHX_ L, anchor, txt, pat, is_time ? TIME_KEEPER_KIND_TIME : TIME_KEEPER_KIND_VALUE, &value, &tod,
                 err, errlen) != TIME_KEEPER_OK) {
        SV *reason;
        if (tkn_piv(aTHX_ p, "weekday") && (reason = tkn_weekday_reason(aTHX_ err))) {
            (void)hv_stores(info, "reason", newSVsv(reason));
            (void)hv_stores(info, "token", newSVsv(tkn_first_token(aTHX_ raw)));
        }
        return NULL;
    }
    (void)hv_stores(info, "precision", newSVsv(tkn_hsv(aTHX_ p, "precision")));
    if (is_time) {
        tkn_info_assume(aTHX_ info, "date");
        return tkn_at_time(aTHX_ anchor, &tod);
    }
    if (kind && strEQ(kind, "date"))
        tkn_info_assume(aTHX_ info, "time");
    if (cyclic)
        tkn_info_assume(aTHX_ info, "century");
    else if (y_run == 2 && L->calendar) {
        /* a two-digit year of a calendar: Time::Keeper widened it by the
           Gregorian century; the anchor's century in the calendar instead */
        IV yy = SvIV(tkn_method(aTHX_ value, "year", NULL, 0)) % 100, ay = SvIV(tkn_method(aTHX_ anchor, "year", NULL, 0));
        if (yy < 0)
            yy += 100;
        {
            IV year = (ay / 100) * 100 + yy;
            SV *args[2];
            AV *r;
            if (year > ay + 20)
                year -= 100;
            args[0] = sv_2mortal(newSVpvs("year"));
            args[1] = sv_2mortal(newSViv(year));
            r = tkn_try_call(aTHX_ value, "with", args, 2, G_SCALAR);
            if (!r || av_len(r) < 0)
                return NULL;
            value = *av_fetch(r, 0, 0);
        }
        tkn_info_assume(aTHX_ info, "century");
    }
    else if (y_run == 2) {
        time_keeper_civil vc;
        tkn_civil_of(aTHX_ value, &vc);
        if (vc.year < 100) {
            IV year = (IV)(ac.year / 100) * 100 + (IV)vc.year;
            SV *args[4];
            if (year > (IV)ac.year + 20)
                year -= 100;
            args[0] = sv_2mortal(newSVpvs("year"));
            args[1] = sv_2mortal(newSViv(year));
            args[2] = sv_2mortal(newSVpvs("end_of_month"));
            args[3] = sv_2mortal(newSVpvs("limit"));
            value = tkn_method(aTHX_ value, "with", args, 4);
        }
        tkn_info_assume(aTHX_ info, "century");
    }
    if (!has_year) {
        tkn_info_assume(aTHX_ info, "year");
        value = tkn_prefer_year(aTHX_ self, anchor, value);
    }
    return value;
}

/* _bare_hour: an hour with nothing else, where the locale's clock allows
 * it or bare_hour says which half; -1 for none. */
static IV
tkn_bare_hour(pTHX_ SV *self, tkn_lexicon *L, SV *anchor, SV *k, HV *info)
{
    IV h = SvIV(k), c;
    SV *opt;
    const char *o;
    if (h > 23)
        return -1;
    (void)hv_stores(info, "precision", newSVpvs("hour"));
    if (h == 0 || h > 12 || tkn_h24(aTHX_ L))
        return h;
    opt = tkn_self_opt(aTHX_ self, "bare_hour");
    if (!opt || !SvTRUE(opt)) {
        (void)hv_stores(info, "reason", newSVpvs("a bare hour; say am, pm or pass bare_hour"));
        (void)hv_stores(info, "token", newSVsv(k));
        return -1;
    }
    o = SvPV_nolen(opt);
    tkn_info_assume(aTHX_ info, SvPV_nolen(sv_2mortal(newSVpvf("bare_hour %s", o))));
    if (strEQ(o, "am"))
        return h % 12;
    if (strEQ(o, "pm"))
        return h % 12 + 12;
    {
        time_keeper_civil ac;
        IV now;
        tkn_civil_of(aTHX_ anchor, &ac);
        now = ac.hour * 3600 + ac.minute * 60 + ac.second;
        for (c = h % 12; c <= h % 12 + 12; c += 12)
            if (c * 3600 > now)
                return c;
        return h % 12 + 12;
    }
}

/* The period of the first fixed meaning that has one. */
static SV *
tkn_period_in(pTHX_ tkn_lexicon *L, SV *s)
{
    AV *r = (AV *)sv_2mortal((SV *)newAV());
    I32 i;
    tkn_lookup_k(aTHX_ L, TKN_T_FIXED, -1, tkn_key_sv(aTHX_ L, s), r);
    for (i = 0; i <= av_len(r); i++) {
        SV *p = tkn_hsv(aTHX_ (HV *)SvRV(*av_fetch(r, i, 0)), "period");
        if (p)
            return p;
    }
    return NULL;
}

/* _time_of_day: 1 and the time, or 0 (with the reason, when a bare hour). */
static int
tkn_time_of_day(pTHX_ SV *self, tkn_lexicon *L, SV *anchor, SV *raw, HV *info, tkn_tod *tod, int *shape)
{
    STRLEN rl, kl;
    const char *rb = tkn_utf8_bytes(aTHX_ raw, &rl), *kb;
    I32 runs = tkn_digit_runs(rb, rl), i;
    int alpha = tkn_has_letter(aTHX_ raw);
    SV *k, *period;
    char *err;
    STRLEN errlen = rl + 256;
    Newx(err, errlen, char);
    SAVEFREEPV(err);
    *shape = 0;
    tkn_patterns_of(aTHX_ L);
    for (i = 0; i <= av_len(L->patterns); i++) {
        HV *p;
        if (L->pmeta[i].kind != 't' || L->pmeta[i].numeric != runs || L->pmeta[i].alpha != alpha)
            continue;
        p = (HV *)SvRV(*av_fetch(L->patterns, i, 0));
        if (!tkn_has_all_punct(aTHX_ p, rb, rl))
            continue;
        if (tkn_cldr(aTHX_ L, anchor, raw, tkn_hsv(aTHX_ p, "pattern"), TIME_KEEPER_KIND_TIME, NULL, tod, err, errlen)
            != TIME_KEEPER_OK)
            continue;
        (void)hv_stores(info, "precision", newSVsv(tkn_hsv(aTHX_ p, "precision")));
        return 1;
    }
    k = tkn_key_sv(aTHX_ L, raw);
    kb = SvPV_const(k, kl);
    if ((kl == 1 || kl == 2) && isDIGIT_A(kb[0]) && isDIGIT_A(kb[kl - 1])) {
        IV h = tkn_bare_hour(aTHX_ self, L, anchor, k, info);
        (void)hv_stores(info, "bare", newSViv(1));
        if (h < 0)
            return 0;
        tod->hour = h;
        tod->minute = tod->second = tod->nanosecond = 0;
        *shape = 1;
        return 1;
    }
    period = tkn_period_in(aTHX_ L, raw);
    if (period) {
        HV *rule = tkn_dprule(aTHX_ L, period);
        SV *at = rule ? tkn_hsv(aTHX_ rule, "at") : NULL;
        if (at) {
            IV m = SvIV(at);
            (void)hv_stores(info, "precision", newSVpvs("minute"));
            tod->hour = m / 60;
            tod->minute = m % 60;
            tod->second = tod->nanosecond = 0;
            *shape = 2;
            return 1;
        }
    }
    if (kl >= 2 && isDIGIT_A(kb[0])) {
        STRLEN d = isDIGIT_A(kb[1]) ? 2 : 1, j = d;
        while (j < kl && isSPACE_A(kb[j]))
            j++;
        if (j < kl) {
            IV h = SvIV(sv_2mortal(newSVpvn(kb, d)));
            SV *rest = sv_2mortal(newSVpvn(kb + j, kl - j)), *per;
            SvUTF8_on(rest);
            per = tkn_period_in(aTHX_ L, rest);
            if (per && h >= 0 && h <= 12) {
                const char *ps = SvPV_nolen(per);
                (void)hv_stores(info, "precision", newSVpvs("hour"));
                tod->minute = tod->second = tod->nanosecond = 0;
                *shape = 1;
                if (strEQ(ps, "am")) {
                    tod->hour = h % 12;
                    return 1;
                }
                if (strEQ(ps, "pm")) {
                    tod->hour = h % 12 + 12;
                    return 1;
                }
                {
                    HV *r = tkn_dprule(aTHX_ L, per);
                    SV *from = r ? tkn_hsv(aTHX_ r, "from") : NULL, *before = r ? tkn_hsv(aTHX_ r, "before") : NULL;
                    if (from) {
                        IV f = SvIV(from), b = before ? SvIV(before) : 0, c;
                        for (c = h % 12; c <= h % 12 + 12; c += 12) {
                            IV m = c * 60;
                            int in = f <= b ? (m >= f && m < b) : (m >= f || m < b);
                            if (in) {
                                tod->hour = c;
                                return 1;
                            }
                        }
                    }
                }
            }
        }
    }
    return 0;
}

/* _absolute: the text as a date and time (or a date only). */
/* A text Time::Keeper->parse might read: every form it takes has four
 * digits in a row (a year, a basic form, an epoch), a clock time
 * ("15 Oct 26 09:00 GMT") or an @. */
static int
tkn_iso_shaped(const char *b, STRLEN n)
{
    STRLEN i, run = 0;
    if (n && b[0] == '@')
        return 1;
    for (i = 0; i < n; i++) {
        if (isDIGIT_A(b[i])) {
            if (++run >= 4)
                return 1;
            continue;
        }
        run = 0;
        if (b[i] == ':' && i > 0 && i + 1 < n && isDIGIT_A(b[i - 1]) && isDIGIT_A(b[i + 1]))
            return 1;
    }
    return 0;
}

static SV *
tkn_absolute(pTHX_ SV *self, tkn_lexicon *L, SV *text, HV *info, int dates_only)
{
    SV *anchor = tkn_anchor(aTHX_ self), *raw;
    STRLEN rl;
    const char *rb;
    I32 runs, i;
    int alpha, shape;
    tkn_tod tod;
    raw = tkn_trim(aTHX_ tkn_ascii_digits(aTHX_ text, L->has_digits ? L->digits : NULL));
    rb = tkn_utf8_bytes(aTHX_ raw, &rl);
    if (!rl)
        return NULL;
    /* in a calendar, a date with no time ("2026-09-06", the Chinese short
       date) is the calendar's to read, not ISO 8601's */
    if (!dates_only && !(L->calendar && !memchr(rb, ':', rl) && !memchr(rb, 'T', rl) && rb[0] != '@') && tkn_iso_shaped(rb, rl)) {
        SV *zone = tkn_method(aTHX_ anchor, "zone_name", NULL, 0), *args[3], *iso;
        args[0] = raw;
        args[1] = sv_2mortal(newSVpvs("zone"));
        args[2] = zone;
        iso = tkn_class_call(aTHX_ "Time::Keeper", "try_parse", args, 3, 0);
        if (iso && SvOK(iso)) {
            const char *prec = "day";
            STRLEN j;
            int sec = 0, to_min = 0;
            for (j = 0; j < rl && !sec; j++) {
                if (j + 9 <= rl && rb[j] == 'T' && isDIGIT_A(rb[j + 1]) && isDIGIT_A(rb[j + 2]) && rb[j + 3] == ':'
                    && isDIGIT_A(rb[j + 4]) && isDIGIT_A(rb[j + 5]) && rb[j + 6] == ':' && isDIGIT_A(rb[j + 7]) && isDIGIT_A(rb[j + 8]))
                    sec = 1;
                if (j + 8 <= rl && isDIGIT_A(rb[j]) && isDIGIT_A(rb[j + 1]) && rb[j + 2] == ':' && isDIGIT_A(rb[j + 3])
                    && isDIGIT_A(rb[j + 4]) && rb[j + 5] == ':' && isDIGIT_A(rb[j + 6]) && isDIGIT_A(rb[j + 7]))
                    sec = 1;
                if (j + 6 <= rl && (rb[j] == 'T' || rb[j] == ' ') && isDIGIT_A(rb[j + 1]) && isDIGIT_A(rb[j + 2])
                    && rb[j + 3] == ':' && isDIGIT_A(rb[j + 4]) && isDIGIT_A(rb[j + 5]))
                    to_min = 1;
            }
            if (rl && rb[0] == '@')
                sec = 1;
            if (sec)
                prec = "second";
            else if (to_min)
                prec = "minute";
            else {
                STRLEN s0 = (rl && (rb[0] == '+' || rb[0] == '-')) ? 1 : 0, d = tkn_digits_at(rb, s0, rl);
                if (d >= 4 && s0 + d == rl)
                    prec = "year";
                else if (d >= 4 && s0 + d + 3 == rl && rb[s0 + d] == '-' && isDIGIT_A(rb[s0 + d + 1]) && isDIGIT_A(rb[s0 + d + 2]))
                    prec = "month";
                else {
                    STRLEN w = tkn_digits_at(rb, 0, rl);
                    if (w == 4) {
                        STRLEN q = 4;
                        if (q < rl && rb[q] == '-')
                            q++;
                        if (q + 3 == rl && rb[q] == 'W' && isDIGIT_A(rb[q + 1]) && isDIGIT_A(rb[q + 2]))
                            prec = "week";
                    }
                }
            }
            (void)hv_stores(info, "precision", newSVpv(prec, 0));
            if (tkn_rank(prec) <= tkn_rank("day"))
                tkn_info_assume(aTHX_ info, strEQ(prec, "day") ? "time" : "period start");
            {
                SV *other_zone = sv_2mortal(newSVpv(strEQ(SvPV_nolen(zone), "Asia/Tokyo") ? "America/New_York" : "Asia/Tokyo", 0));
                SV *other;
                int plain_date = rl == 10 && isDIGIT_A(rb[0]) && isDIGIT_A(rb[1]) && isDIGIT_A(rb[2]) && isDIGIT_A(rb[3])
                              && rb[4] == '-' && isDIGIT_A(rb[5]) && isDIGIT_A(rb[6]) && rb[7] == '-' && isDIGIT_A(rb[8]) && isDIGIT_A(rb[9]);
                args[2] = other_zone;
                other = tkn_class_call(aTHX_ "Time::Keeper", "try_parse", args, 3, 0);
                if (other && SvOK(other) && !plain_date) {
                    time_keeper_point a, b;
                    tkn_pt(aTHX_ other, &a);
                    tkn_pt(aTHX_ iso, &b);
                    if (a.inst.sec == b.inst.sec)
                        (void)hv_stores(info, "zone_named", newSViv(1));
                }
            }
            {
                SV *loc = tkn_method(aTHX_ anchor, "locale", NULL, 0);
                SV *v = tkn_method(aTHX_ iso, "in_zone", &zone, 1);
                return tkn_method(aTHX_ v, "in_locale", &loc, 1);
            }
        }
    }
    runs = tkn_digit_runs(rb, rl);
    alpha = tkn_has_letter(aTHX_ raw);
    tkn_patterns_of(aTHX_ L);
    for (i = 0; i <= av_len(L->patterns); i++) {
        HV *p;
        IV numeric = L->pmeta[i].numeric;
        SV *v;
        if (dates_only && L->pmeta[i].kind != 'd')
            continue;
        /* in a calendar, a number may be written in its numerals (ד׳, 初六),
           not digits, so the count of runs of digits says nothing */
        /* nor, there, does a month name always have letters (be writes the
           Chinese months "9") */
        if (!L->calendar && (L->pmeta[i].alpha != alpha || numeric > runs
                             || (!L->pmeta[i].month_name && numeric != runs)))
            continue;
        p = (HV *)SvRV(*av_fetch(L->patterns, i, 0));
        v = tkn_by_pattern(aTHX_ self, L, anchor, raw, p, info);
        if (v)
            return v;
        if (tkn_hsv(aTHX_ info, "reason"))
            return NULL;
    }
    if (dates_only)
        return NULL;
    if (!tkn_time_of_day(aTHX_ self, L, anchor, raw, info, &tod, &shape))
        return NULL;
    tkn_info_assume(aTHX_ info, "date");
    return tkn_at_time(aTHX_ anchor, &tod);
}

/* _day_part: a day for a time to go on, never a moment. */
static SV *
tkn_day_part(pTHX_ SV *self, tkn_lexicon *L, SV *lexsv, SV *words, SV *text, HV *info)
{
    SV *v, *prec;
    PERL_UNUSED_ARG(lexsv);
    v = tkn_day(aTHX_ self, L, words, text, tkn_key_sv(aTHX_ L, text), info);
    if (!v || !SvTRUE(v))
        return NULL;
    prec = tkn_hsv(aTHX_ info, "precision");
    if (tkn_rank(prec ? SvPV_nolen(prec) : NULL) > tkn_rank("day")) {
        (void)hv_stores(info, "reason", newSVpvs("a time on a time"));
        (void)hv_stores(info, "token", newSVsv(tkn_first_token(aTHX_ text)));
        return NULL;
    }
    return v;
}

static void
tkn_merge(pTHX_ HV *into, HV *from)
{
    HE *he;
    hv_iterinit(from);
    while ((he = hv_iternext(from)))
        (void)hv_store_ent(into, hv_iterkeysv(he), newSVsv(HeVAL(he)), 0);
}

/* _combined: a day and a time, either way round. */
static SV *
tkn_combined(pTHX_ SV *self, tkn_lexicon *L, SV *lexsv, SV *words, SV *text, HV *info)
{
    SV *anchor = tkn_anchor(aTHX_ self), *raw;
    STRLEN rl;
    const char *rb;
    AV *tok = (AV *)sv_2mortal((SV *)newAV());
    const char *glue;
    I32 i, nt;
    int have_words = words && SvTRUE(words);
    /* in a spaceless locale, the tokens that a space set apart, joined
       again with one ("2026年10月15日 星期四 下午3:05:00") */
    char spaced[256];
    Zero(spaced, sizeof spaced, char);
    raw = tkn_trim(aTHX_ tkn_ascii_digits(aTHX_ text, L->has_digits ? L->digits : NULL));
    rb = tkn_utf8_bytes(aTHX_ raw, &rl);
    if (L->spaceless) {
        STRLEN a = 0, q;
        int space_before = 0;
        glue = "";
        for (q = 1; q <= rl; q++) {
            int cut = 0;
            STRLEN cl = 0;
            if (q < rl && ((U8)rb[q] & 0xC0) == 0x80)
                continue;
            if (q < rl && tkn_is_space_cp(tkn_utf8_cp((const U8 *)rb + q, (const U8 *)rb + rl, &cl))) {
                if (q > a) {
                    SV *t = newSVpvn(rb + a, q - a);
                    SvUTF8_on(t);
                    if (av_len(tok) + 1 < (I32)sizeof spaced)
                        spaced[av_len(tok) + 1] = (char)space_before;
                    av_push(tok, t);
                }
                while (q < rl && tkn_is_space_cp(tkn_utf8_cp((const U8 *)rb + q, (const U8 *)rb + rl, &cl)))
                    q += cl;
                a = q;
                space_before = 1;
                continue;
            }
            if (q < rl && isDIGIT_A(rb[q]) && !isDIGIT_A(rb[q - 1]))
                cut = 1;
            if (isDIGIT_A(rb[q - 1]) && (q == rl || !(isDIGIT_A(rb[q]) || rb[q] == ':' || rb[q] == '.')))
                cut = 1;
            if (cut) {
                if (q > a) {
                    SV *t = newSVpvn(rb + a, q - a);
                    SvUTF8_on(t);
                    if (av_len(tok) + 1 < (I32)sizeof spaced)
                        spaced[av_len(tok) + 1] = (char)space_before;
                    av_push(tok, t);
                    space_before = 0;
                }
                a = q;
            }
        }
        if (rl > a) {
            SV *t = newSVpvn(rb + a, rl - a);
            SvUTF8_on(t);
            if (av_len(tok) + 1 < (I32)sizeof spaced)
                spaced[av_len(tok) + 1] = (char)space_before;
            av_push(tok, t);
        }
    }
    else {
        STRLEN a = 0, q;
        glue = " ";
        for (q = 0; q <= rl; q++)
            if (q == rl || rb[q] == ' ') {
                SV *t = newSVpvn(rb + a, q - a);
                SvUTF8_on(t);
                av_push(tok, t);
                a = q + 1;
            }
        while (av_len(tok) >= 0 && !SvCUR(*av_fetch(tok, av_len(tok), 0)))
            SvREFCNT_dec(av_pop(tok));
    }
    nt = av_len(tok) + 1;
    if (nt < 2)
        return NULL;
    for (i = nt - 1; i >= 1; i--) {
        SV *left = sv_2mortal(newSVpvs("")), *right = sv_2mortal(newSVpvs(""));
        I32 j;
        int o;
        SvUTF8_on(left);
        SvUTF8_on(right);
        for (j = 0; j < i; j++) {
            if (j)
                sv_catpv(left, j < (I32)sizeof spaced && spaced[j] ? " " : glue);
            sv_catsv(left, *av_fetch(tok, j, 0));
        }
        for (j = i; j < nt; j++) {
            if (j > i)
                sv_catpv(right, j < (I32)sizeof spaced && spaced[j] ? " " : glue);
            sv_catsv(right, *av_fetch(tok, j, 0));
        }
        {
            STRLEN ll;
            const char *lb = SvPV_const(left, ll), *q = lb + ll;
            STRLEN cl;
            if (ll) {
                q--;
                while (q > lb && ((U8)*q & 0xC0) == 0x80)
                    q--;
                {
                    UV cp = tkn_utf8_cp((const U8 *)q, (const U8 *)lb + ll, &cl);
                    if (cp == ',' || cp == ';' || cp == 0x060C || cp == 0x3001) {
                        SvCUR_set(left, (STRLEN)(q - lb));
                        *SvEND(left) = '\0';
                    }
                }
            }
        }
        for (o = 0; o < 2; o++) {
            SV *day_text = o ? right : left, *time_text = o ? left : right;
            HV *ti, *di;
            tkn_tod tod;
            int shape;
            SV *day, *ttrim;
            if (have_words) {
                SV *rest, *rk, *raw, *sk;
                if (tkn_after(aTHX_ words, L, time_text, "at", &rest, &rk, &raw))
                    time_text = rest;
                sk = tkn_key_sv(aTHX_ L, time_text);
                tkn_skip(aTHX_ words, L, &time_text, &sk);
            }
            if (!SvOK(time_text) || !SvCUR(time_text))
                continue;
            ti = (HV *)sv_2mortal((SV *)newHV());
            (void)hv_stores(ti, "assumed", newRV_noinc((SV *)newAV()));
            ttrim = time_text;
            if (!tkn_time_of_day(aTHX_ self, L, anchor, ttrim, ti, &tod, &shape)) {
                if (!(tkn_hsv(aTHX_ ti, "bare") && SvTRUE(tkn_hsv(aTHX_ ti, "bare")) && tkn_hsv(aTHX_ ti, "reason")))
                    continue;
                tkn_merge(aTHX_ info, ti);
                return NULL;
            }
            di = (HV *)sv_2mortal((SV *)newHV());
            (void)hv_stores(di, "assumed", newRV_noinc((SV *)newAV()));
            day = tkn_day_part(aTHX_ self, L, lexsv, words, day_text, di);
            if (!day) {
                SV *reason = tkn_hsv(aTHX_ di, "reason");
                if (reason && strNE(SvPV_nolen(reason), "a duration, not a time; parse_duration reads it")) {
                    tkn_merge(aTHX_ info, di);
                    return NULL;
                }
                continue;
            }
            if (tkn_hsv(aTHX_ ti, "bare") && SvTRUE(tkn_hsv(aTHX_ ti, "bare")) && tkn_hsv(aTHX_ di, "absolute")
                && SvTRUE(tkn_hsv(aTHX_ di, "absolute")))
                continue;
            {
                SV *tp = tkn_hsv(aTHX_ ti, "precision");
                AV *assumed = newAV(), *da = tkn_rv_av(aTHX_ *hv_fetchs(di, "assumed", 0), "assumed"),
                   *ta = tkn_rv_av(aTHX_ *hv_fetchs(ti, "assumed", 0), "assumed");
                SV **old = hv_fetchs(info, "assumed", 0);
                I32 x;
                (void)hv_stores(info, "precision", tp ? newSVsv(tp) : newSV(0));
                for (x = 0; x <= av_len(da); x++)
                    if (strNE(SvPV_nolen(*av_fetch(da, x, 0)), "time"))
                        av_push(assumed, newSVsv(*av_fetch(da, x, 0)));
                for (x = 0; x <= av_len(ta); x++)
                    av_push(assumed, newSVsv(*av_fetch(ta, x, 0)));
                if (old && SvROK(*old) && SvTYPE(SvRV(*old)) == SVt_PVAV) {
                    AV *oa = (AV *)SvRV(*old);
                    av_clear(oa);
                    for (x = 0; x <= av_len(assumed); x++)
                        av_push(oa, newSVsv(*av_fetch(assumed, x, 0)));
                    SvREFCNT_dec((SV *)assumed);
                }
                else
                    (void)hv_stores(info, "assumed", newRV_noinc((SV *)assumed));
            }
            return tkn_at_time(aTHX_ day, &tod);
        }
    }
    return NULL;
}

#endif
