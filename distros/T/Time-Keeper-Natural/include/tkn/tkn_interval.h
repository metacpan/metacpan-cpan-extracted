#ifndef TKN_INTERVAL_H
#define TKN_INTERVAL_H

/* Intervals: two moments as one text. Three readers, in turn: the ISO 8601
 * "a/b" form through Time::Keeper's parse_interval; what format_interval
 * writes, read against each of the locale's interval patterns split at the
 * dash its fallback pattern uses ("Oct 15 - 17, 2026", the year written once
 * and lent to the half without it); and two phrases round a word table's
 * range ("from {0} to {1}") or the fallback's dash, the second read with the
 * first as its anchor. An end that names a day or a longer period runs to
 * that period's last nanosecond; a time is an instant. */

#define TKN_IF_Y     0x001
#define TKN_IF_M     0x002
#define TKN_IF_D     0x004
#define TKN_IF_E     0x008
#define TKN_IF_A     0x010
#define TKN_IF_H12   0x020
#define TKN_IF_H24   0x040
#define TKN_IF_MIN   0x080
#define TKN_IF_SEC   0x100
#define TKN_IF_OTHER 0x200
#define TKN_IF_DATE  (TKN_IF_Y | TKN_IF_M | TKN_IF_D)
#define TKN_IF_TIME  (TKN_IF_H12 | TKN_IF_H24 | TKN_IF_MIN | TKN_IF_SEC)

/* The kinds of field a pattern has, its quoted literals skipped. */
static unsigned
tkn_ifields(const char *p, STRLEN n)
{
    unsigned f = 0;
    STRLEN i;
    int q = 0;
    for (i = 0; i < n; i++) {
        char c = p[i];
        if (c == '\'') {
            q = !q;
            continue;
        }
        if (q || !tkn_ascii_letter(c))
            continue;
        switch (c) {
        case 'y': case 'u': f |= TKN_IF_Y; break;
        case 'M': case 'L': f |= TKN_IF_M; break;
        case 'd': f |= TKN_IF_D; break;
        case 'E': case 'c': case 'e': f |= TKN_IF_E; break;
        case 'a': case 'b': case 'B': f |= TKN_IF_A; break;
        case 'h': case 'K': f |= TKN_IF_H12; break;
        case 'H': case 'k': f |= TKN_IF_H24; break;
        case 'm': f |= TKN_IF_MIN; break;
        case 's': f |= TKN_IF_SEC; break;
        default: f |= TKN_IF_OTHER;
        }
    }
    return f;
}

/* A pattern's year is "y" (any count of digits) and not "yy"; such a year
 * must be written with three digits or more, so "Oct 15 - Nov 18" is not
 * read as the years 15 and 18. */
static int
tkn_long_year(const char *p, STRLEN n)
{
    STRLEN i;
    int q = 0;
    for (i = 0; i < n; i++) {
        if (p[i] == '\'') {
            q = !q;
            continue;
        }
        if (!q && p[i] == 'y') {
            STRLEN r = 1;
            while (i + r < n && p[i + r] == 'y')
                r++;
            if (r != 2)
                return 1;
            i += r - 1;
        }
    }
    return 0;
}

static int
tkn_digit_run(const char *t, STRLEN n, STRLEN want)
{
    STRLEN i, run = 0;
    for (i = 0; i < n; i++) {
        run = isDIGIT_A(t[i]) ? run + 1 : 0;
        if (run >= want)
            return 1;
    }
    return 0;
}

/* The fields a pattern writes in digits, and in *names its month names,
 * which may hold a run of digits too ("10月", "M10"). A half whose text has
 * fewer runs of digits than the one or more than both is not read, so
 * "cim 2026" is not day 20 of the year 26. */
static int
tkn_num_fields(const char *p, STRLEN n, int *names)
{
    STRLEN i;
    int q = 0, c = 0;
    *names = 0;
    for (i = 0; i < n; i++) {
        char ch = p[i];
        STRLEN r = 1;
        if (ch == '\'') {
            q = !q;
            continue;
        }
        if (q || !tkn_ascii_letter(ch))
            continue;
        while (i + r < n && p[i + r] == ch)
            r++;
        if (strchr("yudhHkKms", ch) || ((ch == 'M' || ch == 'L') && r <= 2))
            c++;
        else if (ch == 'M' || ch == 'L' || strchr("abBEcG", ch))
            (*names)++;
        i += r - 1;
    }
    return c;
}

static SV *
tkn_sub_trim(pTHX_ const char *s, const char *e)
{
    SV *out;
    tkn_trim_ws(&s, &e, 1, 1);
    out = sv_2mortal(newSVpvn(s, (STRLEN)(e - s)));
    SvUTF8_on(out);
    return out;
}

/* The fallback's dash, without its spaces: "–" for "{0} – {1}"; *swap set
 * where the fallback writes the end first ("{1} - {0}" in bal). */
static SV *
tkn_fallback_dash(pTHX_ tkn_lexicon *L, int *swap)
{
    SV *fb = tkn_call1(aTHX_ TKN_LOC, "interval_fallback", &L->code, 1);
    STRLEN n;
    const char *b, *o, *c;
    if (!SvOK(fb))
        return NULL;
    b = tkn_utf8_bytes(aTHX_ fb, &n);
    o = strstr(b, "{0}");
    c = strstr(b, "{1}");
    if (!o || !c)
        return NULL;
    *swap = c < o;
    {
        SV *d = *swap ? tkn_sub_trim(aTHX_ c + 3, o) : tkn_sub_trim(aTHX_ o + 3, c);
        return SvCUR(d) ? d : NULL;
    }
}

/* parse_cldr through Time::Keeper's C, the wall clock read into c. */
static int
tkn_cldr_clock(pTHX_ tkn_lexicon *L, SV *anchor, SV *txt, SV *pat, time_keeper_civil *c)
{
    time_keeper_point a, out;
    STRLEN tl, pl;
    const char *tb = tkn_utf8_bytes(aTHX_ txt, &tl), *pb = tkn_utf8_bytes(aTHX_ pat, &pl);
    char *err;
    Newx(err, tl + 256, char);
    SAVEFREEPV(err);
    tkn_pt(aTHX_ anchor, &a);
    return (TKN_TK->parse_cldr)(aTHX_ tb, tl, pb, pl, TIME_KEEPER_KIND_VALUE, &a.zone, tkn_locale_id(aTHX_ L), 0,
                                TIME_KEEPER_GAP_FORWARD, TIME_KEEPER_OVERLAP_EARLIER, &out, c, err, tl + 256) == TIME_KEEPER_OK;
}

/* A half read with the date fields it lacks written after it (" y" and the
 * year, and so on), so a weekday in it can be checked. */
static int
tkn_half(pTHX_ tkn_lexicon *L, SV *anchor, SV *txt, SV *pat, unsigned f, unsigned all,
         const int64_t *ymd, time_keeper_civil *c)
{
    SV *t = sv_2mortal(newSVsv(txt)), *p = sv_2mortal(newSVsv(pat));
    if ((f & TKN_IF_Y) && tkn_long_year(SvPVX(pat), SvCUR(pat)) && !tkn_digit_run(SvPVX(txt), SvCUR(txt), 3))
        return 0;
    {
        int names, nf = tkn_num_fields(SvPVX(pat), SvCUR(pat), &names), runs = (int)tkn_digit_runs(SvPVX(txt), SvCUR(txt));
        if (runs < nf || runs > nf + names)
            return 0;
    }
    if (all & (TKN_IF_DATE | TKN_IF_E)) {
        if (!(f & TKN_IF_Y)) {
            sv_catpvf(t, " %" IVdf, (IV)ymd[0]);
            sv_catpvs(p, " y");
        }
        if (!(f & TKN_IF_M)) {
            sv_catpvf(t, " %" IVdf, (IV)ymd[1]);
            sv_catpvs(p, " M");
        }
        if (!(f & TKN_IF_D)) {
            sv_catpvf(t, " %" IVdf, (IV)ymd[2]);
            sv_catpvs(p, " d");
        }
    }
    return tkn_cldr_clock(aTHX_ L, anchor, t, p, c);
}

/* Time::Keeper->new from a wall clock, in the anchor's zone and the
 * lexicon's locale; NULL when there is no such moment. */
static SV *
tkn_value_at(pTHX_ tkn_lexicon *L, SV *anchor, const time_keeper_civil *c)
{
    SV *args[20];
    int n = 0;
#define TKN_ARG(k, v) (args[n++] = sv_2mortal(newSVpvs(k)), args[n++] = (v))
    TKN_ARG("year", sv_2mortal(newSViv((IV)c->year)));
    TKN_ARG("month", sv_2mortal(newSViv(c->month)));
    TKN_ARG("day", sv_2mortal(newSViv(c->day)));
    TKN_ARG("hour", sv_2mortal(newSViv(c->hour)));
    TKN_ARG("minute", sv_2mortal(newSViv(c->minute)));
    TKN_ARG("second", sv_2mortal(newSViv(c->second)));
    TKN_ARG("nanosecond", sv_2mortal(newSViv(c->nanosecond)));
    TKN_ARG("zone", tkn_method(aTHX_ anchor, "zone_name", NULL, 0));
    TKN_ARG("locale", L->code);
    TKN_ARG("gap", sv_2mortal(newSVpvs("forward")));
#undef TKN_ARG
    return tkn_class_call(aTHX_ "Time::Keeper", "new", args, n, 1);
}

static SV *
tkn_end_of(pTHX_ SV *v, int unit)
{
    time_keeper_point in, out;
    tkn_pt(aTHX_ v, &in);
    if ((TKN_TK->end_of)(aTHX_ &in, unit, TIME_KEEPER_WEEK_LOCALE, &out, NULL, 0) == TIME_KEEPER_OK)
        return tkn_pt_sv(aTHX_ &out);
    {
        SV *args[4];
        args[0] = sv_2mortal(newSVpvs("to"));
        args[1] = sv_2mortal(newSVpv(tkn_order[unit], 0));
        args[2] = sv_2mortal(newSVpvs("week_start"));
        args[3] = sv_2mortal(newSVpvs("locale"));
        return tkn_method(aTHX_ v, "end_of", args, unit == TIME_KEEPER_UNIT_WEEK ? 4 : 2);
    }
}

static int
tkn_before(pTHX_ SV *a, SV *b)
{
    time_keeper_point x, y;
    tkn_pt(aTHX_ a, &x);
    tkn_pt(aTHX_ b, &y);
    return x.inst.sec < y.inst.sec || (x.inst.sec == y.inst.sec && x.inst.nsec < y.inst.nsec);
}

/* A pattern split where its first repeated field starts: the half before,
 * the literal between (unquoted, trimmed: "–", "al", "日～") and the half
 * after. 0 when no field repeats. */
static int
tkn_pat_split(pTHX_ const char *p, STRLEN n, SV **p1, SV **sep, SV **p2)
{
    STRLEN i, prev_end = 0;
    unsigned seen = 0;
    int q = 0;
    for (i = 0; i < n; i++) {
        char c = p[i];
        if (c == '\'') {
            q = !q;
            continue;
        }
        if (q || !tkn_ascii_letter(c))
            continue;
        {
            STRLEN r = 1;
            unsigned f;
            while (i + r < n && p[i + r] == c)
                r++;
            f = tkn_ifields(p + i, r);
            if (seen & f & ~TKN_IF_OTHER) {
                SV *lit = sv_2mortal(newSVpvs(""));
                STRLEN j;
                int lq = 0;
                for (j = prev_end; j < i; j++) {
                    if (p[j] == '\'') {
                        if (j + 1 < i && p[j + 1] == '\'') {
                            sv_catpvs(lit, "'");
                            j++;
                        }
                        else
                            lq = !lq;
                        continue;
                    }
                    sv_catpvn(lit, p + j, 1);
                }
                PERL_UNUSED_VAR(lq);
                *sep = tkn_sub_trim(aTHX_ SvPVX(lit), SvPVX(lit) + SvCUR(lit));
                *p1 = tkn_sub_trim(aTHX_ p, p + prev_end);
                *p2 = tkn_sub_trim(aTHX_ p + i, p + n);
                return SvCUR(*sep) > 0;
            }
            seen |= f;
            i += r - 1;
            prev_end = i + 1;
        }
    }
    return 0;
}

/* The two halves read against a split pattern: 1 read, -1 read with its
 * end first, 0 not. */
static int
tkn_read_halves(pTHX_ tkn_lexicon *L, SV *anchor, const time_keeper_civil *acp, SV *p1, SV *p2, SV *t1, SV *t2,
                HV *info, SV **s_out, SV **e_out)
{
    time_keeper_civil ac = *acp, c[2], cs, ce;
    unsigned f1 = tkn_ifields(SvPVX(p1), SvCUR(p1)), f2 = tkn_ifields(SvPVX(p2), SvCUR(p2)), fa = f1 | f2;
    int first;
    int64_t ymd[3];
    SV *start, *end;
    if (!f1 || !f2 || (fa & TKN_IF_OTHER))
        return 0;
    first = (f1 & TKN_IF_DATE) == TKN_IF_DATE ? 0 : (f2 & TKN_IF_DATE) == TKN_IF_DATE ? 1 : !(f1 & TKN_IF_E) ? 0 : 1;
    ymd[0] = ac.year;
    ymd[1] = (fa & TKN_IF_M) ? ac.month : 1;
    ymd[2] = 1;
    if (!tkn_half(aTHX_ L, anchor, first ? t2 : t1, first ? p2 : p1, first ? f2 : f1, fa, ymd, &c[first]))
        return 0;
    {
        unsigned ff = first ? f2 : f1;
        if (ff & TKN_IF_Y) ymd[0] = c[first].year;
        if (ff & TKN_IF_M) ymd[1] = c[first].month;
        if (ff & TKN_IF_D) ymd[2] = c[first].day;
    }
    if (!tkn_half(aTHX_ L, anchor, first ? t1 : t2, first ? p1 : p2, first ? f1 : f2, fa, ymd, &c[!first]))
        return 0;
    cs = c[0];
    ce = c[1];
    if (!(fa & TKN_IF_DATE)) {
        cs.year = ce.year = ac.year;
        cs.month = ce.month = ac.month;
        cs.day = ce.day = ac.day;
    }
    else {
        if (!(f1 & TKN_IF_Y)) cs.year = (f2 & TKN_IF_Y) ? c[1].year : ac.year;
        if (!(f1 & TKN_IF_M)) cs.month = (f2 & TKN_IF_M) ? c[1].month : 1;
        if (!(f1 & TKN_IF_D)) cs.day = (f2 & TKN_IF_D) ? c[1].day : 1;
        if (!(f2 & TKN_IF_Y)) ce.year = (f1 & TKN_IF_Y) ? c[0].year : ac.year;
        if (!(f2 & TKN_IF_M)) ce.month = (f1 & TKN_IF_M) ? c[0].month : 1;
        if (!(f2 & TKN_IF_D)) ce.day = (f1 & TKN_IF_D) ? c[0].day : 1;
    }
    if (!(fa & TKN_IF_TIME)) {
        cs.hour = cs.minute = cs.second = ce.hour = ce.minute = ce.second = 0;
        cs.nanosecond = ce.nanosecond = 0;
    }
    else {
        if ((f1 & TKN_IF_H12) && !(f1 & TKN_IF_A) && (f2 & TKN_IF_A))
            cs.hour = cs.hour % 12 + (ce.hour >= 12 ? 12 : 0);
        if ((f2 & TKN_IF_H12) && !(f2 & TKN_IF_A) && (f1 & TKN_IF_A))
            ce.hour = ce.hour % 12 + (cs.hour >= 12 ? 12 : 0);
    }
    start = tkn_value_at(aTHX_ L, anchor, &cs);
    end = start ? tkn_value_at(aTHX_ L, anchor, &ce) : NULL;
    if (!start || !end)
        return 0;
    {
        const char *prec = (fa & TKN_IF_SEC) ? "second" : (fa & TKN_IF_MIN) ? "minute" : (fa & (TKN_IF_H12 | TKN_IF_H24)) ? "hour"
                         : (fa & TKN_IF_D) ? "day" : (fa & TKN_IF_M) ? "month" : "year";
        if (tkn_rank(prec) <= tkn_rank("day"))
            end = tkn_end_of(aTHX_ end, tkn_rank(prec));
        if (tkn_before(aTHX_ end, start))
            return -1;
        (void)hv_stores(info, "precision", newSVpv(prec, 0));
    }
    if (!(fa & TKN_IF_TIME))
        tkn_info_assume(aTHX_ info, "time");
    if (!(fa & TKN_IF_DATE))
        tkn_info_assume(aTHX_ info, "date");
    else if (!(fa & TKN_IF_Y))
        tkn_info_assume(aTHX_ info, "year");
    *s_out = start;
    *e_out = end;
    return 1;
}

static int
tkn_is_letter_at(const char *s, STRLEN n)
{
    STRLEN cl;
    UV cp;
    if (!n)
        return 0;
    cp = tkn_utf8_cp((const U8 *)s, (const U8 *)s + n, &cl);
    return cp < 0x80 ? tkn_ascii_letter((char)cp) : cp >= 0xC0 && !tkn_is_space_cp(cp) && cp != 0x2013 && cp != 0xFF5E;
}

/* What format_interval writes: 1 read, -1 read with its end first, 0 not. */
static int
tkn_interval_cldr(pTHX_ SV *self, tkn_lexicon *L, SV *text, HV *info, SV **s_out, SV **e_out)
{
    SV *anchor = tkn_anchor(aTHX_ self), *raw, *all;
    STRLEN rl;
    const char *rb;
    HV *seen = (HV *)sv_2mortal((SV *)newHV());
    AV *pats = (AV *)sv_2mortal((SV *)newAV());
    HE *he;
    I32 i, np;
    time_keeper_civil ac;
    int reversed = 0;
    raw = tkn_trim(aTHX_ tkn_ascii_digits(aTHX_ text, L->has_digits ? L->digits : NULL));
    rb = tkn_utf8_bytes(aTHX_ raw, &rl);
    all = tkn_call1(aTHX_ TKN_LOC, "interval_formats", &L->code, 1);
    if (!tkn_hv_of(all))
        return 0;
    hv_iterinit(tkn_hv_of(all));
    while ((he = hv_iternext(tkn_hv_of(all)))) {
        HV *by = tkn_hv_of(HeVAL(he));
        HE *pe;
        if (!by)
            continue;
        hv_iterinit(by);
        while ((pe = hv_iternext(by))) {
            SV *p = HeVAL(pe);
            if (!SvOK(p) || hv_exists_ent(seen, p, 0))
                continue;
            (void)hv_store_ent(seen, p, &PL_sv_yes, 0);
            av_push(pats, newSVsv(p));
        }
    }
    np = av_len(pats) + 1;
    if (np > 1) {
        sortsv(AvARRAY(pats), np, Perl_sv_cmp);
        for (i = 1; i < np; i++) {
            I32 j;
            SV *x = AvARRAY(pats)[i];
            for (j = i - 1; j >= 0 && SvCUR(AvARRAY(pats)[j]) < SvCUR(x); j--)
                AvARRAY(pats)[j + 1] = AvARRAY(pats)[j];
            AvARRAY(pats)[j + 1] = x;
        }
    }
    tkn_civil_of(aTHX_ anchor, &ac);
    for (i = 0; i < np; i++) {
        STRLEN pl, sl, at;
        const char *pb = tkn_utf8_bytes(aTHX_ *av_fetch(pats, i, 0), &pl), *sb;
        SV *p1, *p2, *sep;
        int pass;
        if (!tkn_pat_split(aTHX_ pb, pl, &p1, &sep, &p2))
            continue;
        /* the separator as written, then a hyphen typed for a dash */
        for (pass = 0; pass < 2; pass++) {
            int any = 0;
            if (pass == 0) {
                sb = SvPVX(sep);
                sl = SvCUR(sep);
            }
            else {
                if ((SvCUR(sep) == 1 && *SvPVX(sep) == '-') || tkn_is_letter_at(SvPVX(sep), SvCUR(sep)))
                    break;
                sb = "-";
                sl = 1;
            }
            for (at = 0; at + sl <= rl; at++) {
                SV *t1, *t2, *s, *e;
                int got;
                if (memNE(rb + at, sb, sl))
                    continue;
                if (!L->spaceless && tkn_is_letter_at(sb, sl)) {
                    STRLEN b = at;
                    if (b > 0) {
                        b--;
                        while (b > 0 && ((U8)rb[b] & 0xC0) == 0x80)
                            b--;
                    }
                    if ((at > 0 && tkn_is_letter_at(rb + b, rl - b)) || (at + sl < rl && tkn_is_letter_at(rb + at + sl, rl - at - sl)))
                        continue;
                }
                t1 = tkn_sub_trim(aTHX_ rb, rb + at);
                t2 = tkn_sub_trim(aTHX_ rb + at + sl, rb + rl);
                if (!SvCUR(t1) || !SvCUR(t2))
                    continue;
                any = 1;
                got = tkn_read_halves(aTHX_ L, anchor, &ac, p1, p2, t1, t2, info, &s, &e);
                if (got > 0) {
                    *s_out = s;
                    *e_out = e;
                    return 1;
                }
                if (got < 0)
                    reversed = 1;
            }
            if (any)
                break;
        }
    }
    return reversed ? -1 : 0;
}

/* The phrases a two-sided interval is read round: the table's ranges, and
 * the fallback's dash with or without spaces. Each [before, between, after]. */
static void
tkn_dash_phrase(pTHX_ AV *out, SV *dash, int swap)
{
    AV *r = newAV();
    SV *toks = sv_2mortal(newSVpvs("s"));
    tkn_tok_lit(aTHX_ toks, (const U8 *)SvPVX(dash), (const U8 *)SvPVX(dash) + SvCUR(dash));
    sv_catpvs(toks, "s");
    av_push(r, newSV(0));
    av_push(r, newSVsv(toks));
    av_push(r, newSV(0));
    av_push(r, newSViv(swap));
    av_push(out, newRV_noinc((SV *)r));
}

static AV *
tkn_range_phrases(pTHX_ tkn_lexicon *L, SV *words, int hyphen)
{
    AV *out = (AV *)sv_2mortal((SV *)newAV());
    if (tkn_words_ok(words)) {
        AV *list = tkn_phrases_of(aTHX_ words, sv_2mortal(newSVpvs("range")));
        I32 i;
        for (i = 0; list && i <= av_len(list); i++) {
            AV *ph = (AV *)SvRV(*av_fetch(list, i, 0)), *r = newAV();
            av_push(r, newSVsv(*av_fetch(ph, 2, 0)));
            av_push(r, newSVsv(*av_fetch(ph, 5, 0)));
            av_push(r, newSVsv(*av_fetch(ph, 4, 0)));
            av_push(r, newSViv(0));
            av_push(out, newRV_noinc((SV *)r));
        }
    }
    {
        int swap = 0;
        SV *dash = tkn_fallback_dash(aTHX_ L, &swap);
        if (dash)
            tkn_dash_phrase(aTHX_ out, dash, swap);
        if (hyphen && !(dash && SvCUR(dash) == 1 && *SvPVX(dash) == '-'))
            tkn_dash_phrase(aTHX_ out, sv_2mortal(newSVpvs("-")), 0);
    }
    return out;
}

static void
tkn_assume_all(pTHX_ HV *info, HV *from)
{
    AV *a = tkn_assumed(aTHX_ info), *b = tkn_assumed(aTHX_ from);
    I32 i, j;
    for (i = 0; i <= av_len(b); i++) {
        SV *x = *av_fetch(b, i, 0);
        int have = 0;
        for (j = 0; j <= av_len(a) && !have; j++)
            if (sv_eq(*av_fetch(a, j, 0), x))
                have = 1;
        if (!have)
            av_push(a, newSVsv(x));
    }
}

static int
tkn_assumed_has(pTHX_ HV *info, const char *what)
{
    AV *a = tkn_assumed(aTHX_ info);
    I32 i;
    for (i = 0; i <= av_len(a); i++)
        if (strEQ(SvPV_nolen(*av_fetch(a, i, 0)), what))
            return 1;
    return 0;
}

/* Two phrases as an interval: 1 read, -1 read with its end first, 0 not.
 * The second is read against the first, a bare hour in it as the next. */
static int
tkn_read_pair(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *x, SV *y, HV *info, SV **s_out, SV **e_out)
{
    HV *xi = tkn_info_new(aTHX), *yi = tkn_info_new(aTHX);
    SV *xv = NULL, *yv = NULL;
    STRLEN xl;
    const char *xb = SvPV_const(tkn_ascii_digits(aTHX_ x, L->has_digits ? L->digits : NULL), xl);
    int xday = 0;
    if (xl >= 1 && xl <= 2 && isDIGIT_A(xb[0]) && isDIGIT_A(xb[xl - 1]))
        xday = atoi(xb);
    if (xday >= 1 && xday <= 31) {
        SV *pr;
        yv = tkn_phrase(aTHX_ self, L, words, y, tkn_key_sv(aTHX_ L, y), yi);
        pr = yv ? tkn_hsv(aTHX_ yi, "precision") : NULL;
        if (pr && strEQ(SvPV_nolen(pr), "day")) {
            SV *args[2];
            AV *r;
            args[0] = sv_2mortal(newSVpvs("day"));
            args[1] = sv_2mortal(newSViv(xday));
            r = tkn_try_call(aTHX_ yv, "with", args, 2, G_SCALAR);
            if (!r || av_len(r) < 0)
                return 0;
            xv = *av_fetch(r, 0, 0);
            tkn_info_set(aTHX_ xi, yi);
        }
        else
            yv = NULL;
    }
    if (!xv) {
        SV *nargs[4];
        xv = tkn_phrase(aTHX_ self, L, words, x, tkn_key_sv(aTHX_ L, x), xi);
        if (!xv)
            return 0;
        nargs[0] = sv_2mortal(newSVpvs("now"));
        nargs[1] = xv;
        nargs[2] = sv_2mortal(newSVpvs("bare_hour"));
        nargs[3] = sv_2mortal(newSVpvs("next"));
        yi = tkn_info_new(aTHX);
        yv = tkn_phrase(aTHX_ tkn_new(aTHX_ self, nargs, 4), L, words, y, tkn_key_sv(aTHX_ L, y), yi);
        if (!yv)
            return 0;
    }
    if (tkn_before(aTHX_ yv, xv) && tkn_assumed_has(aTHX_ yi, "date")) {
        int bare = tkn_assumed_has(aTHX_ yi, "bare_hour am") || tkn_assumed_has(aTHX_ yi, "bare_hour pm") || tkn_assumed_has(aTHX_ yi, "bare_hour next");
        int i;
        for (i = 0; i < 2 && tkn_before(aTHX_ yv, xv); i++)
            yv = tkn_plus1(aTHX_ yv, bare ? "hours" : "days", sv_2mortal(newSViv(bare ? 12 : 1)));
    }
    if (tkn_assumed_has(aTHX_ yi, "time") || tkn_assumed_has(aTHX_ yi, "period start")) {
        SV *pr = tkn_hsv(aTHX_ yi, "precision");
        int unit = pr ? tkn_rank(SvPV_nolen(pr)) : -1;
        if (unit >= 0 && unit <= TIME_KEEPER_UNIT_DAY)
            yv = tkn_end_of(aTHX_ yv, unit);
    }
    if (tkn_before(aTHX_ yv, xv))
        return -1;
    {
        SV *pr = tkn_hsv(aTHX_ xi, "precision");
        (void)hv_stores(info, "precision", pr ? newSVsv(pr) : newSVpvs("day"));
    }
    tkn_assume_all(aTHX_ info, xi);
    tkn_assume_all(aTHX_ info, yi);
    if (tkn_hsv(aTHX_ xi, "zone_named") || tkn_hsv(aTHX_ yi, "zone_named"))
        (void)hv_stores(info, "zone_named", newSViv(1));
    *s_out = xv;
    *e_out = yv;
    return 1;
}

static int
tkn_interval_pairs(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *text, int hyphen, HV *info, SV **s_out, SV **e_out)
{
    AV *phrases = tkn_range_phrases(aTHX_ L, words, hyphen);
    tkn_fold F;
    I32 i;
    int reversed = 0;
    tkn_fold_text(aTHX_ tkn_trim(aTHX_ text), &F);
    for (i = 0; i <= av_len(phrases); i++) {
        AV *r = (AV *)SvRV(*av_fetch(phrases, i, 0));
        SV *pre = *av_fetch(r, 0, 0), *mid = *av_fetch(r, 1, 0), *post = *av_fetch(r, 2, 0);
        int swap = (int)SvIV(*av_fetch(r, 3, 0));
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
        for (c = p + 1; c < yend; c = tkn_fnext(&F, c)) {
            IV m = tkn_match_toks(&F, mid, c);
            STRLEN xa = p, xe, ya, ye;
            int got;
            SV *s, *e;
            if (m < 0 || (STRLEN)m >= yend)
                continue;
            xe = tkn_ftrim_end(&F, xa, c);
            ya = tkn_fskip_ws(&F, (STRLEN)m);
            ye = tkn_ftrim_end(&F, ya, yend);
            if (xe <= xa || ye <= ya)
                continue;
            {
                SV *xt = tkn_fsub(aTHX_ &F, xa, xe), *yt = tkn_fsub(aTHX_ &F, ya, ye);
                got = tkn_read_pair(aTHX_ self, L, words, swap ? yt : xt, swap ? xt : yt, info, &s, &e);
            }
            if (got > 0) {
                *s_out = s;
                *e_out = e;
                return 1;
            }
            if (got < 0)
                reversed = 1;
        }
    }
    return reversed ? -1 : 0;
}

/* $class->method(args) in list context under eval with $@ kept; NULL on a
 * death. */
static AV *
tkn_try_class_list(pTHX_ const char *klass, const char *method, SV **args, int n)
{
    return tkn_try_call(aTHX_ sv_2mortal(newSVpv(klass, 0)), method, args, n, G_ARRAY);
}

/* The three readers in turn: 1 read, -1 read with its end first, 0 not;
 * *single set where the pairs reader had to ask whether it is one time. */
static int
tkn_interval_try(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *text, SV *k, HV *info, SV **s_out, SV **e_out, int *single)
{
    int got = 0;
    {
        STRLEN tl;
        const char *tb = SvPV_const(text, tl);
        if (memchr(tb, '/', tl)) {
            SV *anchor = tkn_anchor(aTHX_ self), *zone = tkn_method(aTHX_ anchor, "zone_name", NULL, 0), *args[3];
            SV *raw = tkn_trim(aTHX_ tkn_ascii_digits(aTHX_ text, L->has_digits ? L->digits : NULL));
            AV *r;
            args[0] = raw;
            args[1] = sv_2mortal(newSVpvs("zone"));
            args[2] = zone;
            r = tkn_try_class_list(aTHX_ "Time::Keeper", "parse_interval", args, 3);
            if (r && av_len(r) == 1) {
                SV *loc = tkn_method(aTHX_ anchor, "locale", NULL, 0);
                HV *si = tkn_info_new(aTHX);
                STRLEN rl;
                const char *rb = SvPV_const(raw, rl), *slash = (const char *)memchr(rb, '/', rl);
                SV *first = sv_2mortal(newSVpvn(rb, (STRLEN)(slash - rb)));
                if (SvUTF8(raw))
                    SvUTF8_on(first);
                *s_out = tkn_method(aTHX_ tkn_method(aTHX_ *av_fetch(r, 0, 0), "in_zone", &zone, 1), "in_locale", &loc, 1);
                *e_out = tkn_method(aTHX_ tkn_method(aTHX_ *av_fetch(r, 1, 0), "in_zone", &zone, 1), "in_locale", &loc, 1);
                if (tkn_absolute(aTHX_ self, L, first, si, 0)) {
                    SV *pr = tkn_hsv(aTHX_ si, "precision");
                    (void)hv_stores(info, "precision", pr ? newSVsv(pr) : newSVpvs("second"));
                    if (tkn_hsv(aTHX_ si, "zone_named"))
                        (void)hv_stores(info, "zone_named", newSViv(1));
                    tkn_assume_all(aTHX_ info, si);
                }
                else
                    (void)hv_stores(info, "precision", newSVpvs("second"));
                got = 1;
            }
        }
    }
    if (!got) {
        got = tkn_interval_cldr(aTHX_ self, L, text, info, s_out, e_out);
        if (got <= 0) {
            HV *pi = tkn_info_new(aTHX);
            int g2;
            *single = tkn_phrase(aTHX_ self, L, words, text, k, tkn_info_new(aTHX)) ? 1 : 0;
            g2 = tkn_interval_pairs(aTHX_ self, L, words, text, !*single, pi, s_out, e_out);
            if (g2 > 0) {
                tkn_info_set(aTHX_ info, pi);
                got = 1;
            }
            else if (g2 < 0)
                got = -1;
        }
    }
    return got;
}

static int tkn_interval_zoned(pTHX_ SV *self, tkn_lexicon *L, SV *words, SV *text, HV *info, SV **s_out, SV **e_out);

/* parse_interval: the start and the end, and the info; else the death. */
static void
tkn_interval(pTHX_ SV *self, SV *method, SV *text, SV **s_out, SV **e_out, HV **info_out)
{
    SV *lexsv, *words, *k;
    tkn_lexicon *L;
    HV *info;
    int got, single = -1;
    if (!SvOK(text))
        tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("Time::Keeper::Natural->%" SVf ": the text is undefined", SVfARG(method))));
    tkn_lex_words(aTHX_ self, &lexsv, &words);
    L = tkn_lex(aTHX_ lexsv);
    k = tkn_key_sv(aTHX_ L, text);
    if (!SvCUR(k))
        tkn_cannot(aTHX_ method, text, sv_2mortal(newSVpvs("")), sv_2mortal(newSVpvs("the text is empty")));
    info = tkn_info_new(aTHX);
    got = tkn_interval_try(aTHX_ self, L, words, text, k, info, s_out, e_out, &single);
    /* a zone named at the end is both ends' ("9 am - 5 pm EST") */
    if (got > 0 && tkn_hsv(aTHX_ info, "zone_named")) {
        HV *zi = tkn_info_new(aTHX);
        SV *zs, *ze;
        if (tkn_interval_zoned(aTHX_ self, L, words, text, zi, &zs, &ze) > 0) {
            info = zi;
            *s_out = zs;
            *e_out = ze;
        }
    }
    if (got > 0) {
        SV *zn = tkn_hsv(aTHX_ info, "zone_named");
        if (!zn || !SvTRUE(zn))
            tkn_info_assume(aTHX_ info, "zone");
        *info_out = info;
        *s_out = tkn_in_cal(aTHX_ self, *s_out);
        *e_out = tkn_in_cal(aTHX_ self, *e_out);
        return;
    }
    if (got < 0)
        tkn_cannot(aTHX_ method, text, tkn_first_token(aTHX_ text), sv_2mortal(newSVpvs("the interval ends before it starts")));
    if (single < 0)
        single = tkn_phrase(aTHX_ self, L, words, text, k, tkn_info_new(aTHX)) ? 1 : 0;
    if (single)
        tkn_cannot(aTHX_ method, text, tkn_first_token(aTHX_ text), sv_2mortal(newSVpvs("a single time, not an interval")));
    tkn_cannot(aTHX_ method, text, tkn_first_token(aTHX_ text), sv_2mortal(newSVpvf("no such word in %" SVf, SVfARG(L->code))));
}

#endif
