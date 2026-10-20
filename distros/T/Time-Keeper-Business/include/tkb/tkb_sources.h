#ifndef TKB_SOURCES_H
#define TKB_SOURCES_H

/* Holidays that come year by year. A lazy schedule's arrays cover the
 * years materialised so far, a contiguous span; a question about a day
 * outside it widens the span to the day's year and one either side, in
 * whole years, asking every yearly date and every generator once for
 * each new year. A source is therefore called once per year per schedule,
 * and a span wider than TKB_YEARS_CAP years is refused rather than
 * walked. A join materialises its two parts and merges their arrays
 * again. */

#define TKB_YEARS_CAP 1000

static int64_t
tkb_year_of_day(int64_t day)
{
    int64_t y;
    unsigned m, d;
    tkb_civil_from_days(day, &y, &m, &d);
    return y;
}

/* A day from what a source gave for one year: "MMDD", "MM-DD" and
 * "--MM-DD" are days of that year, anything else is a date in its own
 * right. 0 when the day does not exist in that year (29 February). */
static int
tkb_answer_day(pTHX_ SV *sv, int64_t year, int64_t *day, const char *what)
{
    if (sv && SvOK(sv) && !SvROK(sv)) {
        STRLEN len;
        const char *p = SvPV(sv, len);
        unsigned m, d;
        if (tkb_month_day_string(p, len, &m, &d)) {
            if (!tkb_valid_civil(year, m, d))
                return 0;
            *day = tkb_days_from_civil(year, m, d);
            return 1;
        }
    }
    if (sv && sv_isobject(sv) && sv_derived_from(sv, "Time::Keeper::MonthDay")) {
        unsigned m, d;
        tkb_month_day_of(aTHX_ sv, &m, &d, what);
        if (!tkb_valid_civil(year, m, d))
            return 0;
        *day = tkb_days_from_civil(year, m, d);
        return 1;
    }
    *day = tkb_day_from_sv(aTHX_ sv, what);
    return 1;
}

static void
tkb_add_answer(pTHX_ tkb_schedule *s, SV *item, int64_t year, const char *what)
{
    int64_t day;
    if (!item || !SvOK(item))
        return;
    if (SvROK(item) && !sv_isobject(item)) {
        SV *inner = SvRV(item);
        if (SvTYPE(inner) == SVt_PVAV) {
            AV *av = (AV *)inner;
            SV **d, **n;
            if (av_len(av) != 1)
                croak("%s: a holiday source gave a list of %ld for %" IVdf ", not a [date, name] pair",
                      what, (long)(av_len(av) + 1), (IV)year);
            d = av_fetch(av, 0, 0);
            n = av_fetch(av, 1, 0);
            if (tkb_answer_day(aTHX_ d ? *d : NULL, year, &day, what))
                tkb_add_holiday(aTHX_ s, day, n && SvOK(*n) ? *n : NULL, TKB_NAMED_LAZY);
            return;
        }
        if (SvTYPE(inner) == SVt_PVHV) {
            HV *hv = (HV *)inner;
            HE *he;
            hv_iterinit(hv);
            while ((he = hv_iternext(hv))) {
                SV *key = hv_iterkeysv(he);
                SV *val = hv_iterval(hv, he);
                if (tkb_answer_day(aTHX_ key, year, &day, what))
                    tkb_add_holiday(aTHX_ s, day, val && SvOK(val) ? val : NULL, TKB_NAMED_LAZY);
            }
            return;
        }
        croak("%s: a holiday source gave a reference for %" IVdf " that is not a date, a [date, name] pair or a name map",
              what, (IV)year);
    }
    if (tkb_answer_day(aTHX_ item, year, &day, what))
        tkb_add_holiday(aTHX_ s, day, NULL, TKB_NAMED_LAZY);
}

/* A generator asked for one year: a code ref called with the year, or an
 * object's holidays(year => $year); the list it gives, copied. */
static void
tkb_ask(pTHX_ SV *gen, SV *args, int64_t year, AV *out, const char *what)
{
    dSP;
    int count, i, is_code;
    SV *err;
    AV *pairs = args && SvROK(args) ? (AV *)SvRV(args) : NULL;
    SSize_t np = pairs ? av_len(pairs) + 1 : 0, j;
    is_code = SvROK(gen) && SvTYPE(SvRV(gen)) == SVt_PVCV && !tkb_has_method(aTHX_ gen, "holidays");
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    if (is_code) {
        EXTEND(SP, 1 + np);
        PUSHs(sv_2mortal(tkb_i64_sv(aTHX_ year)));
        for (j = 0; j < np; j++)
            PUSHs(*av_fetch(pairs, j, 0));
        PUTBACK;
        count = call_sv(gen, G_LIST | G_EVAL);
    }
    else {
        EXTEND(SP, 3 + np);
        PUSHs(gen);
        mPUSHp("year", 4);
        mPUSHs(tkb_i64_sv(aTHX_ year));
        for (j = 0; j < np; j++)
            PUSHs(*av_fetch(pairs, j, 0));
        PUTBACK;
        count = call_method("holidays", G_LIST | G_EVAL);
    }
    SPAGAIN;
    err = ERRSV;
    if (SvTRUE(err)) {
        SV *msg = newSVsv(err);
        SP -= count;
        PUTBACK;
        FREETMPS;
        LEAVE;
        sv_2mortal(msg);
        croak("%s: a holiday source died for %" IVdf ": %" SVf, what, (IV)year, SVfARG(msg));
    }
    for (i = count - 1; i >= 0; i--)
        av_store(out, i, newSVsv(POPs));
    PUTBACK;
    FREETMPS;
    LEAVE;
    if (!is_code && count == 1) {
        SV **one = av_fetch(out, 0, 0);
        if (!one || !SvOK(*one))
            croak("%s: a holiday source gave undef for %" IVdf " (Date::Holidays gives undef for a country it has no module for)",
                  what, (IV)year);
    }
}

static void
tkb_materialise_year(pTHX_ tkb_schedule *s, int64_t year, const char *what)
{
    size_t i;
    for (i = 0; i < s->n_yearly; i++)
        if (tkb_valid_civil(year, s->yearly[i].month, s->yearly[i].day))
            tkb_add_holiday(aTHX_ s, tkb_days_from_civil(year, s->yearly[i].month, s->yearly[i].day),
                            s->yearly[i].name, TKB_NAMED_LAZY);
    if (s->gens) {
        SSize_t g, n = av_len(s->gens) + 1;
        for (g = 0; g < n; g++) {
            SV **gen = av_fetch(s->gens, g, 0);
            AV *answers;
            SSize_t j, m;
            tkb_rule *rule;
            if (!gen)
                continue;
            if ((rule = tkb_rule_magic(aTHX_ *gen))) {
                const tkb_rule_year *ry = tkb_rule_holidays_of(aTHX_ rule, year);
                size_t q;
                for (q = 0; q < ry->n; q++)
                    tkb_add_holiday(aTHX_ s, ry->days[q], ry->names[q], TKB_NAMED_LAZY);
                continue;
            }
            answers = (AV *)sv_2mortal((SV *)newAV());
            {
                SV **a = s->gen_args ? av_fetch(s->gen_args, g, 0) : NULL;
                tkb_ask(aTHX_ *gen, a ? *a : NULL, year, answers, what);
            }
            m = av_len(answers) + 1;
            for (j = 0; j < m; j++) {
                SV **item = av_fetch(answers, j, 0);
                tkb_add_answer(aTHX_ s, item ? *item : NULL, year, what);
            }
        }
    }
}

static void tkb_ensure_span(pTHX_ tkb_schedule *s, int64_t from, int64_t to, const char *what);

/* A join's arrays again, from its two parts as they stand. */
static void
tkb_join_refresh(pTHX_ tkb_schedule *s, const char *what)
{
    const tkb_schedule *a = tkb_schedule_of(aTHX_ s->join_a, what), *b = tkb_schedule_of(aTHX_ s->join_b, what);
    tkb_schedule_clear_days(aTHX_ s);
    tkb_join_days(aTHX_ s, a, b, s->join_both);
    s->lazy = a->lazy || b->lazy;
    s->year_lo = a->year_lo > b->year_lo ? a->year_lo : b->year_lo;
    s->year_hi = a->year_hi < b->year_hi ? a->year_hi : b->year_hi;
}

static void
tkb_ensure_span(pTHX_ tkb_schedule *s, int64_t from, int64_t to, const char *what)
{
    int64_t y1, y2, lo, hi, y;
    if (!s->lazy)
        return;
    if (from > to) { int64_t t = from; from = to; to = t; }
    if (s->join_a) {
        tkb_ensure_span(aTHX_ tkb_schedule_of(aTHX_ s->join_a, what), from, to, what);
        tkb_ensure_span(aTHX_ tkb_schedule_of(aTHX_ s->join_b, what), from, to, what);
        tkb_join_refresh(aTHX_ s, what);
        return;
    }
    y1 = tkb_year_of_day(from) - 1;
    y2 = tkb_year_of_day(to) + 1;
    if (s->year_lo <= s->year_hi && y1 >= s->year_lo && y2 <= s->year_hi)
        return;
    lo = s->year_lo > s->year_hi ? y1 : (y1 < s->year_lo ? y1 : s->year_lo);
    hi = s->year_lo > s->year_hi ? y2 : (y2 > s->year_hi ? y2 : s->year_hi);
    if (hi - lo + 1 > TKB_YEARS_CAP)
        croak("%s: the holiday sources were asked for %" IVdf " years (%" IVdf " to %" IVdf "); list the holidays instead",
              what, (IV)(hi - lo + 1), (IV)lo, (IV)hi);
    for (y = lo; y <= hi; y++)
        if (s->year_lo > s->year_hi || y < s->year_lo || y > s->year_hi)
            tkb_materialise_year(aTHX_ s, y, what);
    s->year_lo = lo;
    s->year_hi = hi;
}

static void
tkb_ensure(pTHX_ tkb_schedule *s, int64_t day, const char *what)
{
    tkb_ensure_span(aTHX_ s, day, day, what);
}

/* The holidays from one day to another, both included, as [Date, name]
 * pairs pushed on the stack: the count is returned. */
static int
tkb_push_holidays(pTHX_ SV **sp_in, tkb_schedule *s, int64_t from, int64_t to, const char *what, SV ***sp_out)
{
    SV **sp = sp_in;
    size_t i;
    int n = 0;
    tkb_ensure_span(aTHX_ s, from, to, what);
    for (i = tkb_named_lower_bound(s->names, s->n_names, from); i < s->n_names && s->names[i].day <= to; i++) {
        SV *date;
        AV *pair;
        PL_stack_sp = sp;
        date = tkb_date_new(aTHX_ s->names[i].day, -1, NULL, NULL);
        sp = PL_stack_sp;
        pair = newAV();
        av_push(pair, newSVsv(date));
        av_push(pair, s->names[i].name ? newSVsv(s->names[i].name) : newSV(0));
        EXTEND(sp, 1);
        PUSHs(sv_2mortal(newRV_noinc((SV *)pair)));
        n++;
    }
    *sp_out = sp;
    return n;
}

#endif
