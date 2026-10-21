#ifndef TKN_RELATIVE_H
#define TKN_RELATIVE_H

/* Relative points and chains: a whole CLDR phrase ("tomorrow", "in 3 days",
 * "next Tuesday"), the direction a phrase's marker gives, a chain of counted
 * parts ("in 2 weeks and 3 days"), and the arithmetic on the anchor through
 * Time::Keeper's C (plus, truncate, the day of the week). Where Time::Keeper's
 * C refuses (a gap, a year out of range, a count past its integers), the
 * method of that name is called instead, so its death reads as 0.01's did.
 * The meanings, groups and info are the Perl hashes 0.01 passed, since the
 * grammar around them is still Perl until Phase 09. */

/* The parser object's, in tkn_surface.h. */
static SV *tkn_now(pTHX_ SV *self);
static SV *tkn_locale_of(pTHX_ SV *self);
static void tkn_lex_words(pTHX_ SV *self, SV **lexsv, SV **words);
static SV *tkn_new(pTHX_ SV *klass, SV **args, I32 n);
static SV *tkn_invocant(pTHX_ const char *method, SV *self, SV **opts, I32 n);

static const char *const tkn_order[] = {
    "year", "quarter", "month", "week", "day", "hour", "minute", "second", "millisecond", "microsecond", "nanosecond"
};
#define TKN_N_ORDER 11

static int
tkn_rank(const char *f)
{
    int i;
    if (f)
        for (i = 0; i < TKN_N_ORDER; i++)
            if (strEQ(f, tkn_order[i]))
                return i;
    return -1;
}

static int
tkn_weekday_of(const char *f)
{
    static const char *const d[7] = { "mon", "tue", "wed", "thu", "fri", "sat", "sun" };
    int i;
    if (f)
        for (i = 0; i < 7; i++)
            if (strEQ(f, d[i]))
                return i + 1;
    return 0;
}

static SV *
tkn_hsv(pTHX_ HV *hv, const char *key)
{
    SV **e = hv_fetch(hv, key, (I32)strlen(key), 0);
    return e && SvOK(*e) ? *e : NULL;
}

static const char *
tkn_hstr(pTHX_ HV *hv, const char *key)
{
    SV *v = tkn_hsv(aTHX_ hv, key);
    return v ? SvPV_nolen(v) : NULL;
}

static HV *
tkn_rv_hv(pTHX_ SV *rv, const char *what)
{
    if (!rv || !SvROK(rv) || SvTYPE(SvRV(rv)) != SVt_PVHV)
        croak("Time::Keeper::Natural: %s is not a hash", what);
    return (HV *)SvRV(rv);
}

static AV *
tkn_rv_av(pTHX_ SV *rv, const char *what)
{
    if (!rv || !SvROK(rv) || SvTYPE(SvRV(rv)) != SVt_PVAV)
        croak("Time::Keeper::Natural: %s is not an array", what);
    return (AV *)SvRV(rv);
}

static void
tkn_info_assume(pTHX_ HV *info, const char *what)
{
    SV **a = hv_fetchs(info, "assumed", 0);
    AV *av;
    if (a && SvROK(*a) && SvTYPE(SvRV(*a)) == SVt_PVAV)
        av = (AV *)SvRV(*a);
    else {
        av = newAV();
        (void)hv_stores(info, "assumed", newRV_noinc((SV *)av));
    }
    av_push(av, newSVpv(what, 0));
}

/* A Time::Keeper value as a point, and back. */
static void
tkn_pt(pTHX_ SV *v, time_keeper_point *p)
{
    if ((TKN_TK->from_sv_cal)(aTHX_ v, &p->inst, &p->zone, &p->locale, &p->calendar) != TIME_KEEPER_OK)
        croak("Time::Keeper::Natural: the anchor is not a Time::Keeper value");
}

static SV *
tkn_pt_sv(pTHX_ const time_keeper_point *p)
{
    SV *sv = (TKN_TK->new_sv_cal)(aTHX_ &p->inst, &p->zone, p->locale, p->calendar);
    if (!sv)
        croak("Time::Keeper::Natural: a value out of range");
    return sv_2mortal(sv);
}

/* $obj->method(args) in scalar context, for when the C refuses. */
static SV *
tkn_method(pTHX_ SV *obj, const char *method, SV **args, int n)
{
    dSP;
    int i, c;
    SV *r;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(obj);
    for (i = 0; i < n; i++)
        XPUSHs(args[i]);
    PUTBACK;
    c = call_method(method, G_SCALAR);
    SPAGAIN;
    r = c ? newSVsv(POPs) : newSV(0);
    PUTBACK;
    FREETMPS;
    LEAVE;
    return sv_2mortal(r);
}

/* A count as an int64 Time::Keeper's C can take, or 0. */
static int
tkn_small(pTHX_ SV *v, int64_t *out)
{
    if (!v || !SvOK(v))
        return 0;
    if (SvIOK(v) && !SvNOK(v)) {
        IV i = SvIV(v);
        if (i > (IV)4000000000000000LL || i < -(IV)4000000000000000LL)
            return 0;
        *out = (int64_t)i;
        return 1;
    }
    {
        NV n = SvNV(v);
        if (n != n || n > 4.0e15 || n < -4.0e15 || n != (NV)(int64_t)n)
            return 0;
        *out = (int64_t)n;
        return 1;
    }
}

/* $v->plus(name => value, ..., gap => 'forward'). */
static SV *
tkn_plus(pTHX_ SV *v, const char *const *names, SV **vals, int n)
{
    time_keeper_point in, out;
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
        tkn_pt(aTHX_ v, &in);
        if ((TKN_TK->plus)(aTHX_ &in, &parts, TIME_KEEPER_GAP_FORWARD, TIME_KEEPER_OVERLAP_EARLIER, &out, NULL, 0) == TIME_KEEPER_OK)
            return tkn_pt_sv(aTHX_ &out);
    }
    {
        SV **args;
        int k = 0;
        Newx(args, 2 * n + 2, SV *);
        SAVEFREEPV(args);
        for (i = 0; i < n; i++) {
            args[k++] = sv_2mortal(newSVpv(names[i], 0));
            args[k++] = vals[i];
        }
        args[k++] = sv_2mortal(newSVpvs("gap"));
        args[k++] = sv_2mortal(newSVpvs("forward"));
        return tkn_method(aTHX_ v, "plus", args, k);
    }
}

static SV *
tkn_plus1(pTHX_ SV *v, const char *name, SV *val)
{
    return tkn_plus(aTHX_ v, &name, &val, 1);
}

/* $v->truncate(to => unit), with week_start => 'locale' for a week. */
static SV *
tkn_truncate(pTHX_ SV *v, int unit)
{
    time_keeper_point in, out;
    tkn_pt(aTHX_ v, &in);
    if ((TKN_TK->truncate)(aTHX_ &in, unit, TIME_KEEPER_WEEK_LOCALE, &out, NULL, 0) == TIME_KEEPER_OK)
        return tkn_pt_sv(aTHX_ &out);
    {
        SV *args[4];
        args[0] = sv_2mortal(newSVpvs("to"));
        args[1] = sv_2mortal(newSVpv(tkn_order[unit], 0));
        args[2] = sv_2mortal(newSVpvs("week_start"));
        args[3] = sv_2mortal(newSVpvs("locale"));
        return tkn_method(aTHX_ v, "truncate", args, unit == TIME_KEEPER_UNIT_WEEK ? 4 : 2);
    }
}

/* $v->next(day_of_week => d) (dir 1) or ->previous (-1). */
static SV *
tkn_adjust_dow_or(pTHX_ SV *v, int d, int dir, int or_same)
{
    time_keeper_point in, out;
    tkn_pt(aTHX_ v, &in);
    if ((TKN_TK->adjust_dow)(aTHX_ &in, d, dir, or_same, TIME_KEEPER_GAP_FAIL, TIME_KEEPER_OVERLAP_EARLIER, &out, NULL, 0) == TIME_KEEPER_OK)
        return tkn_pt_sv(aTHX_ &out);
    {
        SV *args[4];
        args[0] = sv_2mortal(newSVpvs("day_of_week"));
        args[1] = sv_2mortal(newSViv(d));
        args[2] = sv_2mortal(newSVpvs("or_same"));
        args[3] = sv_2mortal(newSViv(1));
        return tkn_method(aTHX_ v, dir > 0 ? "next" : "previous", args, or_same ? 4 : 2);
    }
}

static SV *
tkn_adjust_dow(pTHX_ SV *v, int d, int dir)
{
    return tkn_adjust_dow_or(aTHX_ v, d, dir, 0);
}

static int
tkn_day_of_week(pTHX_ SV *v)
{
    time_keeper_point p;
    time_keeper_civil c;
    tkn_pt(aTHX_ v, &p);
    if ((TKN_TK->civil)(aTHX_ &p.inst, &p.zone, &c) != TIME_KEEPER_OK) {
        SV *r = tkn_method(aTHX_ v, "day_of_week", NULL, 0);
        return (int)SvIV(r);
    }
    return c.day_of_week;
}

/* n * m as Perl's * writes it: an integer while it is one. */
static SV *
tkn_mul(pTHX_ SV *a, IV m)
{
    if (SvIOK(a) && !SvNOK(a)) {
        IV x = SvIV(a);
        if (x == 0 || (x < IV_MAX / 1000000000 && x > -(IV_MAX / 1000000000)))
            return sv_2mortal(newSViv(x * m));
    }
    return sv_2mortal(newSVnv(SvNV(a) * (NV)m));
}

static SV *
tkn_add_sv(pTHX_ SV *a, SV *b)
{
    if (!a)
        return b;
    if (SvIOK(a) && !SvNOK(a) && SvIOK(b) && !SvNOK(b)) {
        IV x = SvIV(a), y = SvIV(b);
        if ((y > 0 && x < IV_MAX - y) || (y <= 0 && x > IV_MIN - y))
            return sv_2mortal(newSViv(x + y));
    }
    return sv_2mortal(newSVnv(SvNV(a) + SvNV(b)));
}

/* _weekday: the day d (1 Monday) n weeks away; 0 is this week's. */
static SV *
tkn_weekday(pTHX_ SV *anchor, int d, SV *nsv, HV *info)
{
    SV *day;
    NV n = SvNV(nsv);
    (void)hv_stores(info, "precision", newSVpvs("day"));
    tkn_info_assume(aTHX_ info, "time");
    if (n > 0) {
        day = tkn_adjust_dow(aTHX_ anchor, d, 1);
        if (n > 1)
            day = tkn_plus1(aTHX_ day, "weeks", tkn_add_sv(aTHX_ nsv, sv_2mortal(newSViv(-1))));
    }
    else if (n < 0) {
        day = tkn_adjust_dow(aTHX_ anchor, d, -1);
        if (n < -1)
            day = tkn_plus1(aTHX_ day, "weeks", tkn_add_sv(aTHX_ nsv, sv_2mortal(newSViv(1))));
    }
    else {
        SV *w = tkn_truncate(aTHX_ anchor, TIME_KEEPER_UNIT_WEEK);
        int diff = ((d - tkn_day_of_week(aTHX_ w)) % 7 + 7) % 7;
        day = tkn_plus1(aTHX_ w, "days", sv_2mortal(newSViv(diff)));
    }
    return tkn_truncate(aTHX_ day, TIME_KEEPER_UNIT_DAY);
}

static const char *
tkn_units_of(const char *f, int *quarter)
{
    *quarter = 0;
    if (strEQ(f, "year")) return "years";
    if (strEQ(f, "quarter")) { *quarter = 1; return "months"; }
    if (strEQ(f, "month")) return "months";
    if (strEQ(f, "week")) return "weeks";
    if (strEQ(f, "day")) return "days";
    if (strEQ(f, "hour")) return "hours";
    if (strEQ(f, "minute")) return "minutes";
    if (strEQ(f, "second")) return "seconds";
    return NULL;
}

static IV
tkn_nanos_of(const char *f)
{
    if (strEQ(f, "millisecond")) return 1000000;
    if (strEQ(f, "microsecond")) return 1000;
    if (strEQ(f, "nanosecond")) return 1;
    return 0;
}

/* _add: the parts (field, count) in the direction dir, at once. */
static SV *
tkn_add_parts(pTHX_ SV *anchor, AV *parts, SV *dir, HV *info)
{
    static const char *const keys[8] = { "years", "months", "weeks", "days", "hours", "minutes", "seconds", "nanoseconds" };
    SV *sum[8] = { NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL }, *vals[8];
    const char *names[8], *smallest = NULL;
    I32 i, n = av_len(parts) + 1;
    int k, m = 0;
    for (i = 0; i < n; i++) {
        AV *p = tkn_rv_av(aTHX_ *av_fetch(parts, i, 0), "a part");
        SV **fe = av_fetch(p, 0, 0), **ce = av_fetch(p, 1, 0);
        const char *f = fe && SvOK(*fe) ? SvPV_nolen(*fe) : "";
        SV *c = ce ? *ce : &PL_sv_undef;
        IV ns = tkn_nanos_of(f);
        int q, slot = 7;
        if (ns)
            sum[7] = tkn_add_sv(aTHX_ sum[7], tkn_mul(aTHX_ c, ns));
        else {
            const char *u = tkn_units_of(f, &q);
            if (!u)
                croak("Time::Keeper::Natural: '%s' is not a unit", f);
            for (slot = 0; slot < 8 && strNE(keys[slot], u); slot++)
                ;
            sum[slot] = tkn_add_sv(aTHX_ sum[slot], q ? tkn_mul(aTHX_ c, 3) : c);
        }
        if (!smallest || tkn_rank(f) > tkn_rank(smallest))
            smallest = f;
    }
    for (k = 0; k < 8; k++)
        if (sum[k]) {
            SV *v = sum[k];
            NV d = SvNV(dir);
            names[m] = keys[k];
            if (SvIOK(v) && !SvNOK(v) && (d == 1 || d == -1))
                vals[m++] = sv_2mortal(newSViv(SvIV(v) * (IV)d));
            else
                vals[m++] = sv_2mortal(newSVnv(SvNV(v) * d));
        }
    if (smallest)
        (void)hv_stores(info, "precision", newSVpv(smallest, 0));
    return tkn_plus(aTHX_ anchor, names, vals, m);
}

/* _one: what one whole phrase means at the anchor. */
static SV *
tkn_one(pTHX_ SV *anchor, HV *m, HV *info)
{
    const char *f = tkn_hstr(aTHX_ m, "field");
    SV *dir = tkn_hsv(aTHX_ m, "direction"), *n;
    int wd = tkn_weekday_of(f), q, unit;
    const char *u;
    if (!f)
        croak("Time::Keeper::Natural: a meaning without a field");
    if (dir) {
        SV *count = tkn_hsv(aTHX_ m, "count");
        if (!count)
            count = sv_2mortal(newSViv(0));
        if (wd) {
            SV *nn = SvIV(dir) < 0 ? tkn_mul(aTHX_ count, -1) : count;
            return tkn_weekday(aTHX_ anchor, wd, nn, info);
        }
        {
            AV *parts = (AV *)sv_2mortal((SV *)newAV()), *p = newAV();
            av_push(p, newSVpv(f, 0));
            av_push(p, newSVsv(count));
            av_push(parts, newRV_noinc((SV *)p));
            return tkn_add_parts(aTHX_ anchor, parts, dir, info);
        }
    }
    n = tkn_hsv(aTHX_ m, "n");
    if (!n)
        n = sv_2mortal(newSViv(0));
    if (wd)
        return tkn_weekday(aTHX_ anchor, wd, n, info);
    (void)hv_stores(info, "precision", newSVpv(f, 0));
    if (strEQ(f, "second") && !SvTRUE(n))
        return anchor;
    tkn_info_assume(aTHX_ info, strEQ(f, "day") ? "time" : "period start");
    unit = tkn_rank(f);
    {
        SV *start = tkn_truncate(aTHX_ anchor, unit);
        if (!SvTRUE(n))
            return start;
        u = tkn_units_of(f, &q);
        return tkn_plus1(aTHX_ start, u, q ? tkn_mul(aTHX_ n, 3) : n);
    }
}

/* The joiner facts _groups needs, once a lexicon. */
static void
tkn_joiner_info(pTHX_ tkn_lexicon *L)
{
    I32 i, n = av_len(L->jword) + 1;
    SV *wre, *scratch;
    HV *seen;
    if (L->jinfo)
        return;
    wre = sv_2mortal(newSVsv(eval_pv("qr/\\w/", TRUE)));
    scratch = sv_2mortal(newSVpvs(""));
    seen = (HV *)sv_2mortal((SV *)newHV());
    Newxz(L->jword_w, n ? n : 1, char);
    L->jwords = newAV();
    L->jmost = 1;
    for (i = 0; i < n; i++) {
        SV *w = *av_fetch(L->jword, i, 0);
        STRLEN len;
        const char *b = SvPV_const(w, len), *s = b, *e = b + len;
        sv_setsv(scratch, w);
        L->jword_w[i] = pregexec(SvRX(wre), SvPVX(scratch), SvEND(scratch), SvPVX(scratch), 0, scratch, 1) ? 1 : 0;
        while (s < e) {
            STRLEN cl;
            UV cp = tkn_utf8_cp((const U8 *)s, (const U8 *)e, &cl);
            if (!(tkn_is_space_cp(cp) || cp == ',' || cp == ';' || cp == 0x060C || cp == 0x3001 || cp == 0x1363))
                break;
            s += cl;
        }
        while (e > s) {
            const char *q = e - 1;
            STRLEN cl;
            UV cp;
            while (q > s && ((U8)*q & 0xC0) == 0x80)
                q--;
            cp = tkn_utf8_cp((const U8 *)q, (const U8 *)e, &cl);
            if (!(tkn_is_space_cp(cp) || cp == ',' || cp == ';' || cp == 0x060C || cp == 0x3001 || cp == 0x1363))
                break;
            e = q;
        }
        if (e > s && !hv_exists(seen, s, -(I32)(e - s))) {
            STRLEN j;
            int t = 1;
            SV *word = newSVpvn(s, (STRLEN)(e - s));
            SvUTF8_on(word);
            (void)hv_store(seen, s, -(I32)(e - s), &PL_sv_yes, 0);
            av_push(L->jwords, word);
            for (j = 0; j < (STRLEN)(e - s); j++)
                if (s[j] == ' ')
                    t++;
            if (t > L->jmost)
                L->jmost = t;
        }
    }
    L->jinfo = 1;
}

static int
tkn_is_jword(pTHX_ tkn_lexicon *L, const char *s, STRLEN n)
{
    I32 i;
    for (i = 0; i <= av_len(L->jwords); i++) {
        STRLEN wl;
        const char *w = SvPV_const(*av_fetch(L->jwords, i, 0), wl);
        if (wl == n && memEQ(w, s, n))
            return 1;
    }
    return 0;
}

static void tkn_unit_read(pTHX_ tkn_lexicon *L, SV *piece, AV *out);

/* _group: the chain parts a piece can be: a whole counted phrase with a
 * direction (full), one without its marker (bare), or a unit (unit). */
static void
tkn_group(pTHX_ tkn_lexicon *L, SV *piece, AV *out)
{
    AV *r = (AV *)sv_2mortal((SV *)newAV());
    I32 i;
    tkn_lookup_k(aTHX_ L, TKN_T_FIXED, TKN_T_COUNTED, piece, r);
    for (i = 0; i <= av_len(r); i++) {
        HV *m = (HV *)SvRV(*av_fetch(r, i, 0));
        const char *f = tkn_hstr(aTHX_ m, "field");
        if (f && hv_exists(m, "direction", 9) && !tkn_weekday_of(f)) {
            HV *c = newHVhv(m);
            (void)hv_stores(c, "kind", newSVpvs("full"));
            av_push(out, newRV_noinc((SV *)c));
        }
    }
    av_clear(r);
    tkn_lookup_k(aTHX_ L, TKN_T_BARE_FIXED, TKN_T_BARE, piece, r);
    for (i = 0; i <= av_len(r); i++) {
        HV *c = newHVhv((HV *)SvRV(*av_fetch(r, i, 0)));
        (void)hv_stores(c, "kind", newSVpvs("bare"));
        av_push(out, newRV_noinc((SV *)c));
    }
    tkn_unit_read(aTHX_ L, piece, out);
}

/* What a piece reads as a unit of a duration ("3 hours"), as _group's units. */
static void
tkn_unit_read(pTHX_ tkn_lexicon *L, SV *piece, AV *out)
{
    AV *r = (AV *)sv_2mortal((SV *)newAV());
    I32 i;
    tkn_lookup_k(aTHX_ L, TKN_T_UNIT_FIXED, TKN_T_UNIT_COUNTED, piece, r);
    for (i = 0; i <= av_len(r); i++) {
        HV *c = newHVhv((HV *)SvRV(*av_fetch(r, i, 0)));
        SV *u = tkn_hsv(aTHX_ c, "unit");
        (void)hv_stores(c, "kind", newSVpvs("unit"));
        (void)hv_stores(c, "field", u ? newSVsv(u) : newSV(0));
        av_push(out, newRV_noinc((SV *)c));
    }
}

/* What a piece reads as: the C group reader, or a Perl one; memoised. */
typedef struct {
    tkn_lexicon *L;
    SV *code;
    HV *memo;
    int unit;           /* read units only, as a duration's parts */
} tkn_reader;

static AV *
tkn_read_piece(pTHX_ tkn_reader *r, const char *s, STRLEN n)
{
    SV **e = hv_fetch(r->memo, s, -(I32)n, 0);
    AV *av;
    SV *piece;
    if (e)
        return (AV *)SvRV(*e);
    av = newAV();
    (void)hv_store(r->memo, s, -(I32)n, newRV_noinc((SV *)av), 0);
    piece = sv_2mortal(newSVpvn(s, n));
    SvUTF8_on(piece);
    if (!r->code && r->unit)
        tkn_unit_read(aTHX_ r->L, piece, av);
    else if (!r->code)
        tkn_group(aTHX_ r->L, piece, av);
    else {
        dSP;
        int c, i;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(piece);
        PUTBACK;
        c = call_sv(r->code, G_ARRAY);
        SPAGAIN;
        for (i = 0; i < c; i++)
            av_push(av, newSVsv(*(SP - c + 1 + i)));
        SP -= c;
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    return av;
}

static SV *
tkn_group_rv(pTHX_ const char *s, STRLEN n, AV *m)
{
    AV *g = newAV();
    SV *str = newSVpvn(s, n);
    SvUTF8_on(str);
    av_push(g, str);
    av_push(g, newRV_inc((SV *)m));
    return newRV_noinc((SV *)g);
}

/* A spaceless piece is a digit run's start or a number word's first
 * character (num_char) at q, not at the piece's start. */
static int
tkn_num_cut(tkn_lexicon *L, const char *k, STRLEN a, STRLEN q)
{
    if (q <= a)
        return 0;
    if (k[q] >= '0' && k[q] <= '9')
        return !(k[q - 1] >= '0' && k[q - 1] <= '9');
    return tkn_tfind(L, &L->t[TKN_T_NUM_CHAR], k + q, UTF8SKIP((const U8 *)k + q)) >= 0;
}

/* A spaceless segment [a, e) cut where a number starts, digits or a word
 * ("二週間三日"), the longest piece that reads first, each piece read;
 * 1 when every piece reads. Reads are capped by *budget. */
static int
tkn_num_split(pTHX_ tkn_lexicon *L, tkn_reader *r, const char *k, STRLEN a, STRLEN e, AV *res, int *budget)
{
    STRLEN c = e;
    if (a >= e)
        return 1;
    for (;;) {
        if (c == e || tkn_num_cut(L, k, a, c)) {
            AV *m;
            if (--*budget < 0)
                return 0;
            m = tkn_read_piece(aTHX_ r, k + a, c - a);
            if (av_len(m) >= 0) {
                av_push(res, tkn_group_rv(aTHX_ k + a, c - a, m));
                if (tkn_num_split(aTHX_ L, r, k, c, e, res, budget))
                    return 1;
                SvREFCNT_dec(av_pop(res));
            }
        }
        if (c <= a + 1)
            return 0;
        do
            c--;
        while (c > a && ((U8)k[c] & 0xC0) == 0x80);
        if (c == a)
            return 0;
    }
}

/* 0.01 cut a spaceless chain at digits only: where that fails, a number
 * word starts a piece too, in each segment between joiners. NULL unless
 * every piece reads and there are min_n of them. */
static AV *
tkn_num_groups(pTHX_ tkn_lexicon *L, tkn_reader *r, const char *k, STRLEN (*segs)[2], int nseg, int min_n)
{
    AV *res = (AV *)sv_2mortal((SV *)newAV());
    int s, budget = 256;
    if (nseg >= 64)
        return NULL;
    for (s = 0; s < nseg; s++)
        if (!tkn_num_split(aTHX_ L, r, k, segs[s][0], segs[s][1], res, &budget))
            return NULL;
    return av_len(res) + 1 >= min_n ? res : NULL;
}

/* _groups: the fewest groups the key splits into, each read by the
 * reader, with the locale's joiners between them; NULL (and the token
 * where reading stopped) when there is no such split. */
static AV *
tkn_groups(pTHX_ tkn_lexicon *L, SV *ksv, HV *info, tkn_reader *r, int min_n)
{
    STRLEN klen;
    const char *k = tkn_utf8_bytes(aTHX_ ksv, &klen);
    AV *res = (AV *)sv_2mortal((SV *)newAV());
    I32 nj = av_len(L->jword) + 1, j;
    tkn_joiner_info(aTHX_ L);
    if (L->spaceless) {
        STRLEN p = 0, start = 0;
        AV *pieces = (AV *)sv_2mortal((SV *)newAV());
        STRLEN segs[64][2];
        int nseg = 0;
        I32 i;
        while (p <= klen) {
            I32 hit = -1;
            STRLEN hl = 0;
            if (p < klen && nj)
                for (j = 0; j < nj; j++) {
                    STRLEN wl;
                    const char *w = SvPV_const(*av_fetch(L->jword, j, 0), wl);
                    if (wl && p + wl <= klen && memEQ(k + p, w, wl)) {
                        hit = j;
                        hl = wl;
                        break;
                    }
                }
            if (hit >= 0 || p == klen) {
                STRLEN a = start, q;
                if (nseg < 64) {
                    segs[nseg][0] = start;
                    segs[nseg++][1] = p;
                }
                for (q = start; q <= p; q++) {
                    if (q == p || (q > start && k[q] >= '0' && k[q] <= '9' && !(k[q - 1] >= '0' && k[q - 1] <= '9'))) {
                        if (q > a) {
                            SV *pc = newSVpvn(k + a, q - a);
                            SvUTF8_on(pc);
                            av_push(pieces, pc);
                        }
                        a = q;
                    }
                }
                if (p == klen)
                    break;
                p += hl;
                start = p;
                continue;
            }
            p += UTF8SKIP((const U8 *)k + p);
        }
        if (av_len(pieces) + 1 < min_n)
            return tkn_num_groups(aTHX_ L, r, k, segs, nseg, min_n);
        for (i = 0; i <= av_len(pieces); i++) {
            STRLEN pl;
            const char *pb = SvPV_const(*av_fetch(pieces, i, 0), pl);
            AV *m = tkn_read_piece(aTHX_ r, pb, pl);
            if (av_len(m) < 0) {
                AV *res2 = tkn_num_groups(aTHX_ L, r, k, segs, nseg, min_n);
                if (res2)
                    return res2;
                (void)hv_stores(info, "token", newSVsv(*av_fetch(pieces, i, 0)));
                return NULL;
            }
            av_push(res, tkn_group_rv(aTHX_ pb, pl, m));
        }
        return res;
    }
    {
        SV *c = sv_2mortal(newSVpvn(k, klen));
        STRLEN *ts, *te, cl;
        I32 nt = 0, i, jj;
        AV **best;
        char *cb, *ce;
        for (j = 0; j < nj; j++) {
            STRLEN wl;
            const char *w;
            SV *nc;
            const char *cp, *cend;
            if (L->jword_w[j])
                continue;
            w = SvPV_const(*av_fetch(L->jword, j, 0), wl);
            if (!wl)
                continue;
            nc = sv_2mortal(newSVpvs(""));
            cp = SvPVX(c);
            cend = cp + SvCUR(c);
            while (cp < cend) {
                if (cp + wl <= cend && memEQ(cp, w, wl)) {
                    sv_catpvs(nc, " ");
                    cp += wl;
                }
                else {
                    sv_catpvn(nc, cp, 1);
                    cp++;
                }
            }
            c = nc;
        }
        {
            SV *nc = sv_2mortal(newSVpvs(""));
            const char *cp = SvPVX(c), *cend = cp + SvCUR(c);
            int sp = 0;
            while (cp < cend) {
                UV ch = tkn_utf8_cp((const U8 *)cp, (const U8 *)cend, &cl);
                int is_sep = ch == ' ' || ch == ',' || ch == ';' || ch == 0x060C || ch == 0x3001 || ch == 0x1363;
                if (is_sep) {
                    if (!sp)
                        sv_catpvs(nc, " ");
                    sp = 1;
                }
                else {
                    sv_catpvn(nc, cp, cl);
                    sp = 0;
                }
                cp += cl;
            }
            c = nc;
        }
        cb = SvPVX(c);
        ce = cb + SvCUR(c);
        if (cb < ce && *cb == ' ')
            cb++;
        if (ce > cb && ce[-1] == ' ')
            ce--;
        Newx(ts, (ce - cb) + 2, STRLEN);
        SAVEFREEPV(ts);
        Newx(te, (ce - cb) + 2, STRLEN);
        SAVEFREEPV(te);
        if (ce > cb) {
            const char *p = cb, *s = cb;
            for (;; p++) {
                if (p == ce || *p == ' ') {
                    ts[nt] = (STRLEN)(s - cb);
                    te[nt++] = (STRLEN)(p - cb);
                    s = p + 1;
                    if (p == ce)
                        break;
                }
            }
        }
        if (nt < min_n)
            return NULL;
        Newxz(best, nt + 1, AV *);
        SAVEFREEPV(best);
        best[0] = (AV *)sv_2mortal((SV *)newAV());
#define TOKS(a, b) (cb + ts[a]), (te[(b) - 1] - ts[a])
        for (i = 1; i <= nt; i++) {
            for (jj = 0; jj < i; jj++) {
                I32 from = jj, t;
                AV *m;
                SV *gs;
                if (!best[jj])
                    continue;
                if (jj > 0)
                    for (t = L->jmost; t >= 1; t--) {
                        if (jj + t > nt)
                            continue;
                        if (tkn_is_jword(aTHX_ L, TOKS(jj, jj + t))) {
                            from = jj + t;
                            break;
                        }
                    }
                if (from >= i)
                    continue;
                gs = sv_2mortal(newSVpvn(cb + ts[from], te[i - 1] - ts[from]));
                SvUTF8_on(gs);
                m = tkn_read_piece(aTHX_ r, SvPVX(gs), SvCUR(gs));
                if (av_len(m) < 0 && jj > 0) {
                    I32 x;
                    const char *g0 = cb + ts[from];
                    STRLEN g0l = te[from] - ts[from];
                    for (x = 0; x < nj; x++) {
                        STRLEN ll;
                        const char *l;
                        SV *h;
                        if (L->jkind[x] != 1)
                            continue;
                        l = SvPV_const(*av_fetch(L->jword, x, 0), ll);
                        if (!(g0l > ll && memEQ(g0, l, ll)))
                            continue;
                        h = sv_2mortal(newSVpvn(g0 + ll, SvCUR(gs) - ll));
                        m = tkn_read_piece(aTHX_ r, SvPVX(h), SvCUR(h));
                        if (av_len(m) >= 0)
                            break;
                    }
                }
                if (av_len(m) < 0 && i < nt) {
                    I32 x;
                    const char *gl = cb + ts[i - 1];
                    STRLEN gll = te[i - 1] - ts[i - 1];
                    for (x = 0; x < nj; x++) {
                        STRLEN tl;
                        const char *tw;
                        if (L->jkind[x] != 2)
                            continue;
                        tw = SvPV_const(*av_fetch(L->jword, x, 0), tl);
                        if (!(gll > tl && memEQ(gl + gll - tl, tw, tl)))
                            continue;
                        m = tkn_read_piece(aTHX_ r, SvPVX(gs), SvCUR(gs) - tl);
                        if (av_len(m) >= 0)
                            break;
                    }
                }
                if (av_len(m) < 0)
                    continue;
                if (!best[i] || av_len(best[jj]) + 1 < av_len(best[i])) {
                    AV *cand = (AV *)sv_2mortal((SV *)av_make(av_len(best[jj]) + 1, AvARRAY(best[jj])));
                    av_push(cand, tkn_group_rv(aTHX_ SvPVX(gs), SvCUR(gs), m));
                    best[i] = cand;
                }
            }
        }
        if (!best[nt]) {
            I32 read = 0;
            for (i = nt - 1; i >= 1; i--) {
                const char *hb = cb + ts[0];
                STRLEN hl = te[i - 1] - ts[0];
                int ok = best[i] != NULL;
                if (!ok)
                    ok = av_len(tkn_read_piece(aTHX_ r, hb, hl)) >= 0;
                if (!ok) {
                    AV *rr = (AV *)sv_2mortal((SV *)newAV());
                    SV *head = sv_2mortal(newSVpvn(hb, hl));
                    I32 x;
                    SvUTF8_on(head);
                    tkn_lookup_k(aTHX_ L, TKN_T_FIXED, TKN_T_COUNTED, head, rr);
                    for (x = 0; x <= av_len(rr) && !ok; x++)
                        if (hv_exists((HV *)SvRV(*av_fetch(rr, x, 0)), "field", 5))
                            ok = 1;
                }
                if (ok) {
                    read = i;
                    break;
                }
            }
            {
                SV *tok = newSVpvn(cb + ts[read], te[read] - ts[read]);
                SvUTF8_on(tok);
                (void)hv_stores(info, "token", tok);
            }
            return NULL;
        }
#undef TOKS
        return best[nt];
    }
}

/* _direction: the one direction every group allows, a full phrase having
 * decided it; else the reason. */
static int
tkn_direction(pTHX_ AV *groups, HV *info, int *dir)
{
    int dirs[2] = { 1, 1 }, decided = 0;
    I32 i, j;
    for (i = 0; i <= av_len(groups); i++) {
        AV *g = tkn_rv_av(aTHX_ *av_fetch(groups, i, 0), "a group");
        AV *ms = tkn_rv_av(aTHX_ *av_fetch(g, 1, 0), "a group's meanings");
        int have[2] = { 0, 0 }, full[2] = { 0, 0 }, anyfull = 0;
        for (j = 0; j <= av_len(ms); j++) {
            HV *m = tkn_rv_hv(aTHX_ *av_fetch(ms, j, 0), "a meaning");
            const char *kind = tkn_hstr(aTHX_ m, "kind");
            if (kind && strEQ(kind, "unit"))
                have[0] = have[1] = 1;
            else {
                SV *d = tkn_hsv(aTHX_ m, "direction");
                int x = d && SvIV(d) < 0 ? 1 : 0;
                if (d && (SvIV(d) == 1 || SvIV(d) == -1)) {
                    have[x] = 1;
                    if (kind && strEQ(kind, "full")) {
                        full[x] = 1;
                        anyfull = 1;
                    }
                }
            }
        }
        for (j = 0; j < 2; j++)
            if (!have[j])
                dirs[j] = 0;
        if (anyfull) {
            for (j = 0; j < 2; j++)
                if (!full[j])
                    dirs[j] = 0;
            decided = 1;
        }
    }
    if (!dirs[0] && !dirs[1]) {
        (void)hv_stores(info, "reason", newSVpvs("one direction a phrase"));
        return 0;
    }
    if (!decided || (dirs[0] && dirs[1])) {
        (void)hv_stores(info, "reason", newSVpvs("a duration, not a time; parse_duration reads it"));
        return 0;
    }
    *dir = dirs[0] ? 1 : -1;
    return 1;
}

/* _choose: one meaning a group, preferring units that fall from one group
 * to the next (hours then minutes), by the cheapest path. */
static AV *
tkn_choose(pTHX_ AV *lists)
{
    I32 n = av_len(lists) + 1, i, c, p;
    AV *out = (AV *)sv_2mortal((SV *)newAV());
    int all1 = 1;
    NV **cost;
    I32 **back;
    I32 pick = -1, last;
    for (i = 0; i < n; i++)
        if (av_len(tkn_rv_av(aTHX_ *av_fetch(lists, i, 0), "a list")) != 0)
            all1 = 0;
    if (all1) {
        for (i = 0; i < n; i++)
            av_push(out, newSVsv(*av_fetch(tkn_rv_av(aTHX_ *av_fetch(lists, i, 0), "a list"), 0, 0)));
        return out;
    }
    if (!n)
        return out;
    Newxz(cost, n, NV *);
    SAVEFREEPV(cost);
    Newxz(back, n, I32 *);
    SAVEFREEPV(back);
    for (i = 0; i < n; i++) {
        AV *cands = tkn_rv_av(aTHX_ *av_fetch(lists, i, 0), "a list");
        I32 nc = av_len(cands) + 1;
        Newxz(cost[i], nc ? nc : 1, NV);
        SAVEFREEPV(cost[i]);
        Newxz(back[i], nc ? nc : 1, I32);
        SAVEFREEPV(back[i]);
        for (c = 0; c < nc; c++) {
            int rank = tkn_rank(tkn_hstr(aTHX_ tkn_rv_hv(aTHX_ *av_fetch(cands, c, 0), "a meaning"), "field"));
            AV *prev;
            I32 np;
            int have = 0;
            if (i == 0) {
                cost[0][c] = -rank;
                continue;
            }
            prev = tkn_rv_av(aTHX_ *av_fetch(lists, i - 1, 0), "a list");
            np = av_len(prev) + 1;
            for (p = 0; p < np; p++) {
                int pr = tkn_rank(tkn_hstr(aTHX_ tkn_rv_hv(aTHX_ *av_fetch(prev, p, 0), "a meaning"), "field"));
                NV step = cost[i - 1][p] + (rank > pr ? rank - pr : 1000);
                if (!have || step < cost[i][c]) {
                    cost[i][c] = step;
                    back[i][c] = p;
                    have = 1;
                }
            }
        }
    }
    last = n - 1;
    {
        AV *cands = tkn_rv_av(aTHX_ *av_fetch(lists, last, 0), "a list");
        for (c = 0; c <= av_len(cands); c++)
            if (pick < 0 || cost[last][c] < cost[last][pick] || (cost[last][c] == cost[last][pick] && c > pick))
                pick = c;
    }
    if (pick < 0)
        return out;
    av_extend(out, n - 1);
    for (i = last; i >= 0; i--) {
        AV *cands = tkn_rv_av(aTHX_ *av_fetch(lists, i, 0), "a list");
        av_store(out, i, newSVsv(*av_fetch(cands, pick, 0)));
        if (i)
            pick = back[i][pick];
    }
    return out;
}

/* Whether the key starts with a direction's prefix or ends with its suffix. */
static int
tkn_marked(pTHX_ tkn_lexicon *L, int d, const char *k, STRLEN kl, int strict)
{
    STRLEN pl, sl;
    const char *pre = SvPV_const(L->markers[d][0], pl), *suf = SvPV_const(L->markers[d][1], sl);
    return (pl && kl >= pl && memEQ(k, pre, pl))
        || (sl && (strict ? kl > sl : kl >= sl) && memEQ(k + kl - sl, suf, sl));
}

/* _could_chain: a chain needs a direction's marker at an edge, unless a
 * direction has no marker at all. */
static int
tkn_could_chain(pTHX_ tkn_lexicon *L, SV *ksv)
{
    STRLEN kl;
    const char *k = tkn_utf8_bytes(aTHX_ ksv, &kl);
    int d, edge = 0;
    for (d = 0; d < 2; d++) {
        if (!SvCUR(L->markers[d][0]) && !SvCUR(L->markers[d][1]))
            return 1;
        edge = edge || tkn_marked(aTHX_ L, d, k, kl, 1);
    }
    return edge;
}

static SV *
tkn_anchor(pTHX_ SV *self)
{
    return tkn_now(aTHX_ self);
}

static SV *tkn_self_opt(pTHX_ SV *self, const char *key);

/* A reading named in English, as CLDR's English writes it: "yesterday",
 * "next Saturday", "in 3 months". */
static SV *
tkn_reading_name(pTHX_ const char *field, IV nv)
{
    SV *args[3], *r, *at, *pat;
    args[0] = sv_2mortal(newSVpvs("en"));
    args[1] = sv_2mortal(newSVpv(field, 0));
    args[2] = sv_2mortal(newSVpvs("long"));
    r = tkn_call1(aTHX_ TKN_LOC, "relative_names", args, 3);
    at = tkn_hget(aTHX_ r, "at");
    if (at) {
        SV *s = tkn_hget(aTHX_ at, SvPV_nolen(sv_2mortal(newSViv(nv))));
        if (s)
            return s;
    }
    pat = tkn_hget(aTHX_ tkn_hget(aTHX_ r, nv < 0 ? "past" : "future"), "other");
    if (pat) {
        SV *out = sv_2mortal(newSVsv(pat));
        STRLEN len;
        const char *b = SvPV_const(out, len), *o = strstr(b, "{0}");
        if (o) {
            SV *x = sv_2mortal(newSVpvn(b, (STRLEN)(o - b)));
            sv_catpvf(x, "%" IVdf, nv < 0 ? -nv : nv);
            sv_catpvn(x, o + 3, len - (STRLEN)(o - b) - 3);
            return x;
        }
    }
    return sv_2mortal(newSVpvf("%s %+" IVdf, field, nv));
}

/* A whole phrase CLDR writes for more than one offset of one field (hi
 * "कल", yesterday and tomorrow), which the text's direction marker does not
 * decide: prefer picks, future the later and past the earlier, and the
 * direction is assumed; without it the phrase dies naming the readings.
 * NULL with no reason when it is no such tie. */
static SV *
tkn_tie(pTHX_ SV *self, tkn_lexicon *L, SV *anchor, SV *ksv, AV *whole, int *marked, int bestv, HV *info)
{
    I32 i, n = av_len(whole) + 1, nc = 0, *cand, pick = -1;
    const char *field = NULL;
    int differ = 0;
    IV n0 = 0;
    SV *prefer;
    Newx(cand, n, I32);
    SAVEFREEPV(cand);
    for (i = 0; i < n; i++) {
        HV *m = (HV *)SvRV(*av_fetch(whole, i, 0));
        SV *md = tkn_hsv(aTHX_ m, "direction"), *mn = tkn_hsv(aTHX_ m, "n");
        const char *f = tkn_hstr(aTHX_ m, "field");
        int v = md ? marked[SvIV(md) < 0 ? 1 : 0] : 0;
        if (v != bestv)
            continue;
        if (!f || (field && strNE(f, field)))
            return NULL;
        if (!field) {
            field = f;
            n0 = mn ? SvIV(mn) : 0;
        }
        else if ((mn ? SvIV(mn) : 0) != n0)
            differ = 1;
        cand[nc++] = i;
    }
    if (nc < 2 || !differ)
        return NULL;
    prefer = tkn_self_opt(aTHX_ self, "prefer");
    if (prefer && SvTRUE(prefer)) {
        int future = strEQ(SvPV_nolen(prefer), "future");
        IV best = 0;
        SV *v;
        for (i = 0; i < nc; i++) {
            SV *mn = tkn_hsv(aTHX_ (HV *)SvRV(*av_fetch(whole, cand[i], 0)), "n");
            IV x = mn ? SvIV(mn) : 0;
            if (pick < 0 || (future ? x > best : x < best)) {
                best = x;
                pick = cand[i];
            }
        }
        v = tkn_one(aTHX_ anchor, (HV *)SvRV(*av_fetch(whole, pick, 0)), info);
        tkn_info_assume(aTHX_ info, "direction");
        return v;
    }
    {
        IV *ns;
        I32 nn = 0, a, b;
        SV *names = sv_2mortal(newSVpvs(""));
        Newx(ns, nc, IV);
        SAVEFREEPV(ns);
        for (i = 0; i < nc; i++) {
            SV *mn = tkn_hsv(aTHX_ (HV *)SvRV(*av_fetch(whole, cand[i], 0)), "n");
            IV x = mn ? SvIV(mn) : 0;
            for (a = 0; a < nn && ns[a] != x; a++)
                ;
            if (a == nn)
                ns[nn++] = x;
        }
        for (a = 1; a < nn; a++)
            for (b = a; b > 0 && ns[b - 1] > ns[b]; b--) {
                IV y = ns[b];
                ns[b] = ns[b - 1];
                ns[b - 1] = y;
            }
        SvUTF8_on(names);
        for (a = 0; a < nn; a++) {
            if (a)
                sv_catpv(names, a == nn - 1 ? " and " : ", ");
            sv_catsv(names, tkn_reading_name(aTHX_ field, ns[a]));
        }
        (void)hv_stores(info, "reason", newSVpvf("'%" SVf "' means %" SVf " in %" SVf "; pass prefer",
                                                 SVfARG(ksv), SVfARG(names), SVfARG(L->code)));
        (void)hv_stores(info, "token", newSVsv(ksv));
        (void)hv_stores(info, "tie", newSVsv(ksv));
        return NULL;
    }
}

/* _relative: a whole phrase, else a chain; NULL when it is neither. */
static SV *
tkn_relative(pTHX_ SV *self, tkn_lexicon *L, SV *ksv, HV *info, AV *whole_in)
{
    SV *anchor = tkn_anchor(aTHX_ self);
    AV *whole = (AV *)sv_2mortal((SV *)newAV());
    I32 i, n;
    if (whole_in) {
        for (i = 0; i <= av_len(whole_in); i++)
            av_push(whole, newSVsv(*av_fetch(whole_in, i, 0)));
    }
    else {
        AV *r = (AV *)sv_2mortal((SV *)newAV());
        tkn_lookup_k(aTHX_ L, TKN_T_FIXED, TKN_T_COUNTED, ksv, r);
        for (i = 0; i <= av_len(r); i++)
            if (hv_exists((HV *)SvRV(*av_fetch(r, i, 0)), "field", 5))
                av_push(whole, newSVsv(*av_fetch(r, i, 0)));
    }
    n = av_len(whole) + 1;
    if (n) {
        HV *w = tkn_rv_hv(aTHX_ *av_fetch(whole, 0, 0), "a meaning");
        const char *wf = tkn_hstr(aTHX_ w, "field");
        SV *wn = tkn_hsv(aTHX_ w, "n"), *wd = tkn_hsv(aTHX_ w, "direction");
        NV d = wd ? SvNV(wd) : 0;
        int agree = 1;
        for (i = 0; i < n && agree; i++) {
            HV *m = tkn_rv_hv(aTHX_ *av_fetch(whole, i, 0), "a meaning");
            const char *mf = tkn_hstr(aTHX_ m, "field");
            SV *mn = tkn_hsv(aTHX_ m, "n"), *md = tkn_hsv(aTHX_ m, "direction");
            if (!mf || !wf || strNE(mf, wf) || (mn ? SvNV(mn) : 0) != (wn ? SvNV(wn) : 0) || (md ? SvNV(md) : 0) != d)
                agree = 0;
        }
        if (agree)
            return tkn_one(aTHX_ anchor, w, info);
        {
            STRLEN kl;
            const char *k = tkn_utf8_bytes(aTHX_ ksv, &kl);
            int marked[2], best = -1, bestv = -1;
            marked[0] = tkn_marked(aTHX_ L, 0, k, kl, 0);
            marked[1] = tkn_marked(aTHX_ L, 1, k, kl, 0);
            for (i = 0; i < n; i++) {
                HV *m = tkn_rv_hv(aTHX_ *av_fetch(whole, i, 0), "a meaning");
                SV *md = tkn_hsv(aTHX_ m, "direction");
                int v = md ? marked[SvIV(md) < 0 ? 1 : 0] : 0;
                if (v > bestv) {
                    bestv = v;
                    best = i;
                }
            }
            {
                SV *v = tkn_tie(aTHX_ self, L, anchor, ksv, whole, marked, bestv, info);
                if (v || tkn_hsv(aTHX_ info, "reason"))
                    return v;
            }
            return tkn_one(aTHX_ anchor, tkn_rv_hv(aTHX_ *av_fetch(whole, best, 0), "a meaning"), info);
        }
    }
    if (!tkn_could_chain(aTHX_ L, ksv))
        return NULL;
    {
        tkn_reader r;
        AV *groups, *lists, *chosen, *parts;
        int dir;
        r.L = L;
        r.code = NULL;
        r.unit = 0;
        r.memo = (HV *)sv_2mortal((SV *)newHV());
        groups = tkn_groups(aTHX_ L, ksv, info, &r, 2);
        if (!groups)
            return NULL;
        if (!tkn_direction(aTHX_ groups, info, &dir))
            return NULL;
        lists = (AV *)sv_2mortal((SV *)newAV());
        for (i = 0; i <= av_len(groups); i++) {
            AV *g = (AV *)SvRV(*av_fetch(groups, i, 0));
            AV *ms = (AV *)SvRV(*av_fetch(g, 1, 0)), *keep = newAV();
            I32 j;
            for (j = 0; j <= av_len(ms); j++) {
                HV *m = (HV *)SvRV(*av_fetch(ms, j, 0));
                const char *kind = tkn_hstr(aTHX_ m, "kind");
                SV *md = tkn_hsv(aTHX_ m, "direction");
                if ((kind && strEQ(kind, "unit")) || (md && SvIV(md) == dir))
                    av_push(keep, newSVsv(*av_fetch(ms, j, 0)));
            }
            av_push(lists, newRV_noinc((SV *)keep));
        }
        chosen = tkn_choose(aTHX_ lists);
        parts = (AV *)sv_2mortal((SV *)newAV());
        for (i = 0; i <= av_len(chosen); i++) {
            HV *m = tkn_rv_hv(aTHX_ *av_fetch(chosen, i, 0), "a meaning");
            AV *p = newAV();
            SV *f = tkn_hsv(aTHX_ m, "field"), *c = tkn_hsv(aTHX_ m, "count");
            av_push(p, f ? newSVsv(f) : newSV(0));
            av_push(p, c ? newSVsv(c) : newSV(0));
            av_push(parts, newRV_noinc((SV *)p));
        }
        return tkn_add_parts(aTHX_ anchor, parts, sv_2mortal(newSViv(dir)), info);
    }
}

#endif
