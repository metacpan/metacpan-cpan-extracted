#ifndef TKN_ZONES_H
#define TKN_ZONES_H

/* A zone named after a time, "3 pm EST", "15:30 Europe/Paris", "9:00
 * GMT+2", read where the plain reading failed: the last one to four tokens
 * as a zone, the rest read in that zone, the value then brought into the
 * parser's zone unless keep_zone. A zone is an IANA name, UTC or GMT; one of
 * the locale's CLDR names or offsets, as parse_cldr reads them, with the
 * parser's zone to choose between zones an abbreviation shares; or a legacy
 * IANA abbreviation (EST, CET). A standard or daylight name keeps its own
 * offset out of its season: "3 pm EST" in July is 15:00 at -05:00. */

static const char *const tkn_zone_pats[] = {
    "zzzz", "z", "vvvv", "v", "VVVV", "OOOO", "O", "xxx", "XXX", "xx", "X"
};
#define TKN_N_ZONE_PATS 11

static IV tkn_zone_call_iv(pTHX_ const char *method, SV *zone, IV epoch);
static SV *tkn_offset_zone(pTHX_ IV secs);
static int tkn_zone_abbr(pTHX_ SV *anchor, SV *cand, IV *offset);

static int
tkn_zone_valid(pTHX_ SV *cand)
{
    SV *r;
    if (!get_cv("Time::Keeper::Zone::is_valid", 0))
        load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("Time::Keeper::Zone"), NULL);
    r = tkn_class_call(aTHX_ "Time::Keeper::Zone", "is_valid", &cand, 1, 1);
    return r && SvTRUE(r);
}

/* The zone a candidate names: its name, the pattern that read it (NULL for
 * an IANA name), or NULL; *ambiguous where the locale's names left two. */
/* The first words of a locale's zone names (z, zzzz, v, vvvv, VVVV, and
 * VVV, the city, for every zone, in January and July), and its GMT format's word under the key "\1":
 * a span starting with none of them is no name of the locale's, and is not
 * handed to parse_cldr. Made in C once a locale. */
static HV *
tkn_zone_words(pTHX_ tkn_lexicon *L, SV *anchor)
{
    dMY_CXT;
    HE *he = hv_fetch_ent(MY_CXT.zone_words, L->code, 0, 0);
    static const char *const pats[6] = { "zzzz", "z", "vvvv", "v", "VVVV", "VVV" };
    HV *set;
    AV *names;
    I32 i;
    time_keeper_civil ac;
    int lid = tkn_locale_id(aTHX_ L);
    char buf[512];
    if (he)
        return (HV *)SvRV(HeVAL(he));
    set = newHV();
    (void)hv_store_ent(MY_CXT.zone_words, L->code, newRV_noinc((SV *)set), 0);
    tkn_civil_of(aTHX_ anchor, &ac);
    if (!get_cv("Time::Keeper::Zone::names", 0))
        load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("Time::Keeper::Zone"), NULL);
    names = tkn_try_call(aTHX_ sv_2mortal(newSVpvs("Time::Keeper::Zone")), "names", NULL, 0, G_ARRAY);
    for (i = 0; names && i <= av_len(names); i++) {
        STRLEN nl;
        const char *nb = SvPV_const(*av_fetch(names, i, 0), nl);
        time_keeper_zone z;
        int m, k;
        if ((TKN_TK->zone_parse)(aTHX_ nb, nl, &z) != TIME_KEEPER_OK)
            continue;
        for (m = 1; m <= 7; m += 6) {
            time_keeper_civil c;
            time_keeper_instant in;
            Zero(&c, 1, time_keeper_civil);
            c.year = ac.year;
            c.month = m;
            c.day = 15;
            c.hour = 12;
            if ((TKN_TK->from_civil)(aTHX_ &c, &z, TIME_KEEPER_GAP_FORWARD, TIME_KEEPER_OVERLAP_EARLIER, &in) != TIME_KEEPER_OK)
                continue;
            for (k = 0; k < 6; k++) {
                size_t w = (TKN_TK->format)(aTHX_ buf, sizeof buf, pats[k], strlen(pats[k]), &in, &z, lid);
                SV *key, *first;
                const char *kb, *sp;
                STRLEN kl;
                if (!w || w >= sizeof buf)
                    continue;
                key = sv_2mortal(newSVpvn(buf, w));
                SvUTF8_on(key);
                key = tkn_key_sv(aTHX_ L, key);
                kb = SvPV_const(key, kl);
                sp = (const char *)memchr(kb, ' ', kl);
                first = sv_2mortal(newSVpvn(kb, sp ? (STRLEN)(sp - kb) : kl));
                if (SvUTF8(key))
                    SvUTF8_on(first);
                (void)hv_store_ent(set, first, &PL_sv_yes, 0);
                /* and every word of it, marked "\2", for the words after the first */
                {
                    STRLEN a = 0, q;
                    for (q = 0; q <= kl; q++)
                        if (q == kl || kb[q] == ' ') {
                            if (q > a) {
                                SV *wd = sv_2mortal(newSVpvs("\2"));
                                sv_catpvn(wd, kb + a, q - a);
                                if (SvUTF8(key))
                                    SvUTF8_on(wd);
                                (void)hv_store_ent(set, wd, &PL_sv_yes, 0);
                            }
                            a = q + 1;
                        }
                }
            }
        }
    }
    {
        time_keeper_zone z;
        time_keeper_instant in;
        if ((TKN_TK->zone_parse)(aTHX_ "+02:00", 6, &z) == TIME_KEEPER_OK && (TKN_TK->now)(&in) == TIME_KEEPER_OK) {
            size_t w = (TKN_TK->format)(aTHX_ buf, sizeof buf, "O", 1, &in, &z, lid);
            if (w && w < sizeof buf) {
                SV *key = sv_2mortal(newSVpvn(buf, w));
                const char *kb;
                STRLEN kl, j = 0;
                SvUTF8_on(key);
                key = tkn_key_sv(aTHX_ L, key);
                kb = SvPV_const(key, kl);
                while (j < kl && kb[j] != '+' && kb[j] != '-' && !isDIGIT_A(kb[j]))
                    j++;
                if (j)
                    (void)hv_stores(set, "\1", newSVpvn_flags(kb, j, SvUTF8(key) ? SVf_UTF8 : 0));
            }
        }
    }
    return set;
}

/* Whether a span may be a zone: its first word begins one of the locale's
 * zone names or its GMT format, or it is spelled as an IANA name, an offset
 * or an abbreviation. */
static int
tkn_zone_may_be(pTHX_ tkn_lexicon *L, SV *anchor, SV *cand)
{
    STRLEN cl, kl, i;
    const char *cb = SvPV_const(cand, cl), *kb, *sp;
    HV *set;
    SV *key, *first, **gmt;
    int caps = cl >= 2 && cl <= 6;
    if (memchr(cb, '/', cl) || cb[0] == '+' || cb[0] == '-')
        return 1;
    for (i = 0; caps && i < cl; i++)
        if (!(cb[i] >= 'A' && cb[i] <= 'Z'))
            caps = 0;
    if (caps)
        return 1;
    set = tkn_zone_words(aTHX_ L, anchor);
    key = tkn_key_sv(aTHX_ L, cand);
    kb = SvPV_const(key, kl);
    sp = (const char *)memchr(kb, ' ', kl);
    first = sv_2mortal(newSVpvn(kb, sp ? (STRLEN)(sp - kb) : kl));
    if (SvUTF8(key))
        SvUTF8_on(first);
    if (hv_exists_ent(set, first, 0)) {
        /* each word after the first is in some zone's name too ("at 3 pm"
           is not, though "AT" is Atlantic Time) */
        STRLEN a = sp ? (STRLEN)(sp - kb) + 1 : kl, q;
        for (q = a; q <= kl; q++)
            if (q == kl || kb[q] == ' ') {
                if (q > a) {
                    SV *wd = sv_2mortal(newSVpvs("\2"));
                    sv_catpvn(wd, kb + a, q - a);
                    if (SvUTF8(key))
                        SvUTF8_on(wd);
                    if (!hv_exists_ent(set, wd, 0))
                        return 0;
                }
                a = q + 1;
            }
        return 1;
    }
    gmt = hv_fetchs(set, "\1", 0);
    if (gmt) {
        STRLEN gl;
        const char *gb = SvPV_const(*gmt, gl);
        if (kl >= gl && memEQ(kb, gb, gl))
            return 1;
    }
    return (cl == 3 && (memEQ(cb, "UTC", 3) || memEQ(cb, "GMT", 3)));
}

/* Whether a word is spelled as an IANA name may be: ASCII letters, digits,
 * '/', '_', '-', '+'; worth asking Time::Keeper::Zone about. */
static int
tkn_iana_shaped(const char *b, STRLEN n)
{
    STRLEN i;
    if (!n || n > 40)
        return 0;
    for (i = 0; i < n; i++)
        if (!(isALPHA_A(b[i]) || isDIGIT_A(b[i]) || b[i] == '/' || b[i] == '_' || b[i] == '-' || b[i] == '+'))
            return 0;
    return 1;
}

static SV *
tkn_zone_name_of(pTHX_ tkn_lexicon *L, SV *anchor, const time_keeper_point *ap, SV *cand, const char **pat, int *ambiguous)
{
    STRLEN cl;
    const char *cb = SvPV_const(cand, cl);
    int i;
    SV *days[2];
    {
        time_keeper_civil ac;
        tkn_civil_of(aTHX_ anchor, &ac);
        days[0] = sv_2mortal(newSVpvf("%04d-01-15", (int)ac.year));
        days[1] = sv_2mortal(newSVpvf("%04d-07-15", (int)ac.year));
    }
    *pat = NULL;
    if ((memchr(cb, '/', cl) || (cl == 3 && (memEQ(cb, "UTC", 3) || memEQ(cb, "GMT", 3)))) && tkn_iana_shaped(cb, cl) && tkn_zone_valid(aTHX_ cand))
        return cand;
    if (!tkn_zone_may_be(aTHX_ L, anchor, cand))
        return NULL;
    /* a span that cannot be a zone: no letter and no sign, or digits with
       no sign ("15:30", "2026") */
    {
        STRLEN j;
        int letter = 0, digit = 0, sign = 0;
        for (j = 0; j < cl; j++) {
            U8 ch = (U8)cb[j];
            if (ch >= 0x80 || isALPHA_A(ch))
                letter = 1;
            else if (isDIGIT_A(ch))
                digit = 1;
            else if (ch == '+' || ch == '-')
                sign = 1;
        }
        if ((!letter && !sign) || (digit && !sign && !letter))
            return NULL;
    }
    {
        int lid = tkn_locale_id(aTHX_ L);
        for (i = 0; i < TKN_N_ZONE_PATS; i++) {
            int with_zone;
            /* an abbreviation two zones share is settled by the parser's zone
               where that zone uses it, in winter or in summer */
            for (with_zone = 0; with_zone < 3; with_zone++) {
                time_keeper_point out;
                time_keeper_civil clock;
                SV *t = sv_2mortal(newSVsv(days[with_zone == 2 ? 1 : 0])), *p;
                STRLEN tl, pl;
                const char *tb, *pb;
                char *err;
                int code;
                sv_catpvs(t, " 12:00 ");
                sv_catsv(t, cand);
                p = sv_2mortal(newSVpvf("y-MM-dd HH:mm %s", tkn_zone_pats[i]));
                tb = tkn_utf8_bytes(aTHX_ t, &tl);
                pb = tkn_utf8_bytes(aTHX_ p, &pl);
                Newx(err, tl + 256, char);
                SAVEFREEPV(err);
                err[0] = '\0';
                code = (TKN_TK->parse_cldr)(aTHX_ tb, tl, pb, pl, TIME_KEEPER_KIND_VALUE, with_zone ? &ap->zone : NULL, lid, 0,
                                            TIME_KEEPER_GAP_FORWARD, TIME_KEEPER_OVERLAP_EARLIER, &out, &clock, err, tl + 256);
                if (code == TIME_KEEPER_OK) {
                    *pat = tkn_zone_pats[i];
                    return tkn_method(aTHX_ tkn_pt_sv(aTHX_ &out), "zone_name", NULL, 0);
                }
                if (!with_zone) {
                    IV off;
                    if (!strstr(err, "could mean more than one zone"))
                        break;
                    /* parse_cldr says this of any word it cannot place */
                    if (!tkn_zone_abbr(aTHX_ anchor, cand, &off))
                        return NULL;
                }
                *ambiguous = 1;
            }
        }
    }
    if (*ambiguous) {
        IV off = 0;
        int r = tkn_zone_abbr(aTHX_ anchor, cand, &off);
        if (r > 0) {
            *ambiguous = 0;
            return tkn_offset_zone(aTHX_ off);
        }
        if (r == 0)
            *ambiguous = 0;
        else
            return NULL;
    }
    if (tkn_iana_shaped(cb, cl) && tkn_zone_valid(aTHX_ cand))
        return cand;
    return NULL;
}

/* A word as some zone's tzdata abbreviation, in January or July of the
 * anchor's year: 1 with its offset where every zone that uses it gives it
 * one, -1 where they disagree (IST), 0 where none uses it. parse_cldr calls
 * any word it cannot place a name more than one zone could have. */
static int
tkn_zone_abbr(pTHX_ SV *anchor, SV *cand, IV *offset)
{
    dMY_CXT;
    if (!MY_CXT.zone_abbrs) {
        AV *names;
        I32 i;
        time_keeper_civil ac;
        SV *f = sv_2mortal(newSVpvs("%Z"));
        HV *set = newHV();
        tkn_civil_of(aTHX_ anchor, &ac);
        MY_CXT.zone_abbrs = set;
        names = tkn_try_call(aTHX_ sv_2mortal(newSVpvs("Time::Keeper::Zone")), "names", NULL, 0, G_ARRAY);
        for (i = 0; names && i <= av_len(names); i++) {
            int m;
            for (m = 1; m <= 7; m += 6) {
                SV *args[8], *v;
                args[0] = sv_2mortal(newSVpvs("year"));
                args[1] = sv_2mortal(newSViv((IV)ac.year));
                args[2] = sv_2mortal(newSVpvs("month"));
                args[3] = sv_2mortal(newSViv(m));
                args[4] = sv_2mortal(newSVpvs("day"));
                args[5] = sv_2mortal(newSViv(15));
                args[6] = sv_2mortal(newSVpvs("zone"));
                args[7] = *av_fetch(names, i, 0);
                v = tkn_class_call(aTHX_ "Time::Keeper", "new", args, 8, 1);
                if (v && SvOK(v)) {
                    SV *a = tkn_method(aTHX_ v, "strftime", &f, 1);
                    if (SvCUR(a) && isALPHA_A(SvPVX(a)[0])) {
                        IV off = tkn_zone_call_iv(aTHX_ "offset_at", *av_fetch(names, i, 0),
                                                  SvIV(tkn_method(aTHX_ v, "epoch", NULL, 0)));
                        HE *he = hv_fetch_ent(set, a, 0, 0);
                        if (!he)
                            (void)hv_store_ent(set, a, newSViv(off), 0);
                        else if (SvOK(HeVAL(he)) && SvIV(HeVAL(he)) != off)
                            sv_setsv(HeVAL(he), &PL_sv_undef);
                    }
                }
            }
        }
    }
    {
        HE *he = hv_fetch_ent(MY_CXT.zone_abbrs, cand, 0, 0);
        if (!he)
            return 0;
        if (!SvOK(HeVAL(he)))
            return -1;
        *offset = SvIV(HeVAL(he));
        return 1;
    }
}

static SV *
tkn_offset_zone(pTHX_ IV secs)
{
    IV a = secs < 0 ? -secs : secs;
    return sv_2mortal(newSVpvf("%c%02d:%02d", secs < 0 ? '-' : '+', (int)(a / 3600), (int)(a % 3600 / 60)));
}

static IV
tkn_zone_call_iv(pTHX_ const char *method, SV *zone, IV epoch)
{
    SV *args[2], *r;
    args[0] = zone;
    args[1] = sv_2mortal(newSViv(epoch));
    r = tkn_class_call(aTHX_ "Time::Keeper::Zone", method, args, 2, 1);
    return r && SvOK(r) ? SvIV(r) : 0;
}

/* Whether a value's zone is written as the candidate then: its CLDR name
 * (z or zzzz) or its tzdata abbreviation. */
static int
tkn_zone_writes(pTHX_ tkn_lexicon *L, SV *v, SV *cand)
{
    static const char *const how[3] = { "z", "zzzz", "%Z" };
    SV *ck = tkn_key_sv(aTHX_ L, cand), *lv = tkn_method(aTHX_ v, "in_locale", &L->code, 1);
    int i;
    for (i = 0; i < 3; i++) {
        SV *f = sv_2mortal(newSVpv(how[i], 0));
        SV *w = tkn_method(aTHX_ lv, i == 2 ? "strftime" : "format", &f, 1);
        if (sv_eq(tkn_key_sv(aTHX_ L, w), ck))
            return 1;
    }
    return 0;
}

/* A standard or daylight name ("EST", "British Summer Time") read on a day
 * of the other season: the same wall clock at the offset the name has in
 * its own season, on 15 January or 15 July of the value's year. */
static SV *
tkn_zone_season(pTHX_ tkn_lexicon *L, SV *v, SV *zone, SV *cand, const char *pat)
{
    SV *other = NULL;
    IV epoch, here, there;
    int m;
    if (!pat || !(strEQ(pat, "z") || strEQ(pat, "zzzz")) || !tkn_zone_valid(aTHX_ zone))
        return v;
    if (tkn_zone_writes(aTHX_ L, v, cand))
        return v;
    for (m = 1; m <= 7 && !other; m += 6) {
        SV *args[2];
        args[0] = sv_2mortal(newSVpvs("month"));
        args[1] = sv_2mortal(newSViv(m));
        {
            SV *w[4];
            w[0] = args[0];
            w[1] = args[1];
            w[2] = sv_2mortal(newSVpvs("day"));
            w[3] = sv_2mortal(newSViv(15));
            {
                AV *r = tkn_try_call(aTHX_ v, "with", w, 4, G_SCALAR);
                SV *o = r && av_len(r) >= 0 ? *av_fetch(r, 0, 0) : NULL;
                if (o && tkn_zone_writes(aTHX_ L, o, cand))
                    other = o;
            }
        }
    }
    if (!other)
        return v;
    epoch = SvIV(tkn_method(aTHX_ v, "epoch", NULL, 0));
    here = tkn_zone_call_iv(aTHX_ "offset_at", zone, epoch);
    there = tkn_zone_call_iv(aTHX_ "offset_at", zone, SvIV(tkn_method(aTHX_ other, "epoch", NULL, 0)));
    if (here == there)
        return v;
    {
        time_keeper_civil c;
        SV *args[16];
        int n = 0;
        tkn_civil_of(aTHX_ v, &c);
#define TKN_ZARG(k, x) (args[n++] = sv_2mortal(newSVpvs(k)), args[n++] = (x))
        TKN_ZARG("year", sv_2mortal(newSViv((IV)c.year)));
        TKN_ZARG("month", sv_2mortal(newSViv(c.month)));
        TKN_ZARG("day", sv_2mortal(newSViv(c.day)));
        TKN_ZARG("hour", sv_2mortal(newSViv(c.hour)));
        TKN_ZARG("minute", sv_2mortal(newSViv(c.minute)));
        TKN_ZARG("second", sv_2mortal(newSViv(c.second)));
        TKN_ZARG("nanosecond", sv_2mortal(newSViv(c.nanosecond)));
        TKN_ZARG("zone", tkn_offset_zone(aTHX_ there));
#undef TKN_ZARG
        {
            SV *r = tkn_class_call(aTHX_ "Time::Keeper", "new", args, n, 1);
            return r && SvOK(r) ? r : v;
        }
    }
}

/* Where each white-space token of a text starts and ends, in bytes. */
static AV *
tkn_ws_offsets(pTHX_ SV *text)
{
    AV *out = (AV *)sv_2mortal((SV *)newAV());
    STRLEN len;
    const U8 *b = (const U8 *)tkn_utf8_bytes(aTHX_ text, &len), *p = b, *e = b + len, *s = NULL;
    while (p <= e) {
        STRLEN cl = 1;
        int sp = p == e || tkn_is_space_cp(tkn_utf8_cp(p, e, &cl));
        if (sp && s) {
            av_push(out, newSViv((IV)(s - b)));
            av_push(out, newSViv((IV)(p - b)));
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

/* A span of tokens as a zone candidate, its brackets aside ("(hora de
 * verano británica)", "[英國夏令時間]"), and the text without it, cut from
 * the text itself so the spaces inside what is left are the locale's own
 * ("p. m." with its narrow no-break space). */
static SV *
tkn_zone_span(pTHX_ SV *text, AV *off, I32 a, I32 b, SV **rest)
{
    STRLEN len;
    const char *tb = tkn_utf8_bytes(aTHX_ text, &len);
    I32 n = (av_len(off) + 1) / 2;
    STRLEN cs = (STRLEN)SvIV(*av_fetch(off, 2 * a, 0)), ce = (STRLEN)SvIV(*av_fetch(off, 2 * (b - 1) + 1, 0));
    SV *cand = sv_2mortal(newSVpvn(tb + cs, ce - cs)), *r;
    STRLEN cl, k, give = 0;
    int open = 0, shut = 0;
    SvUTF8_on(cand);
    /* a bracket the span closes but does not open is the text's: eu wraps
       the time and then the zone, "(15:05:00 (Londresko udako ordua))" */
    for (k = 0; k < SvCUR(cand); k++) {
        open += SvPVX(cand)[k] == '(';
        shut += SvPVX(cand)[k] == ')';
    }
    while (shut > open && SvCUR(cand) && SvPVX(cand)[SvCUR(cand) - 1] == ')') {
        SvCUR_set(cand, SvCUR(cand) - 1);
        shut--;
        give++;
    }
    *SvEND(cand) = '\0';
    cl = SvCUR(cand);
    if (cl > 2 && ((SvPVX(cand)[0] == '(' && SvPVX(cand)[cl - 1] == ')') || (SvPVX(cand)[0] == '[' && SvPVX(cand)[cl - 1] == ']'))) {
        sv_chop(cand, SvPVX(cand) + 1);
        SvCUR_set(cand, SvCUR(cand) - 1);
        *SvEND(cand) = '\0';
    }
    r = sv_2mortal(newSVpvn(tb, a ? (STRLEN)SvIV(*av_fetch(off, 2 * (a - 1) + 1, 0)) : 0));
    SvUTF8_on(r);
    if (b < n) {
        STRLEN ns = (STRLEN)SvIV(*av_fetch(off, 2 * b, 0));
        if (SvCUR(r))
            sv_catpvs(r, " ");
        sv_catpvn(r, tb + ns, len - ns);
    }
    /* the comma that set the zone off ("15:05:00, Брытанскі летні час") */
    while (SvCUR(r) && (SvPVX(r)[SvCUR(r) - 1] == ',' || SvPVX(r)[SvCUR(r) - 1] == ';'))
        SvCUR_set(r, SvCUR(r) - 1);
    *SvEND(r) = '\0';
    while (give--)
        sv_catpvs(r, ")");
    *rest = r;
    return cand;
}

#define TKN_ZONE_SPAN 10

static SV *
tkn_zone_phrase(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *text, HV *info)
{
    AV *off = tkn_ws_offsets(aTHX_ text);
    I32 n = (av_len(off) + 1) / 2, k, a;
    SV *zone = tkn_zone_of(aTHX_ self), *anchor = tkn_anchor(aTHX_ self);
    SV *amb = NULL;
    time_keeper_point ap;
    int digits = 0;
    /* the zone last, the longest span first; then a zone inside the text, as
       some locales' full formats put it ("2026年10月15日星期四 英国夏令时间 15:05:00") */
    I32 i, spans[2 * TKN_ZONE_SPAN * 16][2], ns = 0;
    for (k = n - 1 < TKN_ZONE_SPAN ? n - 1 : TKN_ZONE_SPAN; k >= 1; k--) {
        spans[ns][0] = n - k;
        spans[ns++][1] = n;
    }
    tkn_pt(aTHX_ tkn_method(aTHX_ anchor, "in_zone", &zone, 1), &ap);
    {
        STRLEN tl, j;
        const char *tb = SvPV_const(text, tl);
        for (j = 0; j < tl && !digits; j++)
            digits = isDIGIT_A(tb[j]) || (U8)tb[j] >= 0x80;
    }
    for (a = 1; digits && a < n - 1; a++)
        for (k = n - 1 - a < TKN_ZONE_SPAN ? n - 1 - a : TKN_ZONE_SPAN; k >= 1 && ns < 2 * TKN_ZONE_SPAN * 16; k--) {
            spans[ns][0] = a;
            spans[ns++][1] = a + k;
        }
    for (i = 0; i < ns; i++) {
        SV *rest, *cand, *z, *sub, *v, *args[2];
        const char *pat;
        int ambiguous = 0;
        HV *ri;
        cand = tkn_zone_span(aTHX_ text, off, spans[i][0], spans[i][1], &rest);
        z = tkn_zone_name_of(aTHX_ L, anchor, &ap, cand, &pat, &ambiguous);
        if (!z) {
            if (ambiguous && !amb)
                amb = cand;
            continue;
        }
        args[0] = sv_2mortal(newSVpvs("zone"));
        args[1] = z;
        sub = tkn_new(aTHX_ self, args, 2);
        ri = tkn_info_new(aTHX);
        v = tkn_phrase_dated(aTHX_ sub, L, words, rest, tkn_key_sv(aTHX_ L, rest), ri);
        if (!v)
            continue;
        v = tkn_zone_season(aTHX_ L, v, z, cand, pat);
        {
            SV *keep = tkn_self_opt(aTHX_ self, "keep_zone");
            if (!keep || !SvTRUE(keep))
                v = tkn_method(aTHX_ v, "in_zone", &zone, 1);
        }
        tkn_info_set(aTHX_ info, ri);
        (void)hv_stores(info, "zone_named", newSViv(1));
        return v;
    }
    if (amb) {
        (void)hv_stores(info, "reason", newSVpvf("'%" SVf "' names more than one zone in %" SVf, SVfARG(amb), SVfARG(L->code)));
        (void)hv_stores(info, "token", newSVsv(amb));
    }
    return NULL;
}

/* An interval whose last tokens name a zone, read whole in that zone: both
 * ends are the zone's. */
static int
tkn_interval_zoned(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *text, HV *info, SV **s_out, SV **e_out)
{
    AV *off = tkn_ws_offsets(aTHX_ text);
    I32 n = (av_len(off) + 1) / 2, k;
    SV *zone = tkn_zone_of(aTHX_ self), *anchor = tkn_anchor(aTHX_ self);
    time_keeper_point ap;
    tkn_pt(aTHX_ tkn_method(aTHX_ anchor, "in_zone", &zone, 1), &ap);
    for (k = n - 1 < TKN_ZONE_SPAN ? n - 1 : TKN_ZONE_SPAN; k >= 1; k--) {
        SV *rest, *cand = tkn_zone_span(aTHX_ text, off, n - k, n, &rest), *z, *sub, *args[2], *s, *e;
        const char *pat;
        int ambiguous = 0, single = -1;
        HV *ri;
        z = tkn_zone_name_of(aTHX_ L, anchor, &ap, cand, &pat, &ambiguous);
        if (!z)
            continue;
        args[0] = sv_2mortal(newSVpvs("zone"));
        args[1] = z;
        sub = tkn_new(aTHX_ self, args, 2);
        ri = tkn_info_new(aTHX);
        if (tkn_interval_try(aTHX_ sub, L, words, rest, tkn_key_sv(aTHX_ L, rest), ri, &s, &e, &single) <= 0)
            continue;
        s = tkn_zone_season(aTHX_ L, s, z, cand, pat);
        e = tkn_zone_season(aTHX_ L, e, z, cand, pat);
        {
            SV *keep = tkn_self_opt(aTHX_ self, "keep_zone");
            if (!keep || !SvTRUE(keep)) {
                s = tkn_method(aTHX_ s, "in_zone", &zone, 1);
                e = tkn_method(aTHX_ e, "in_zone", &zone, 1);
            }
        }
        tkn_info_set(aTHX_ info, ri);
        (void)hv_stores(info, "zone_named", newSViv(1));
        *s_out = s;
        *e_out = e;
        return 1;
    }
    return 0;
}

#endif
