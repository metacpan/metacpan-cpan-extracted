#ifndef TKB_BUILD_H
#define TKB_BUILD_H

/* A schedule from its spec: the keys new takes, kept as given in the spec
 * hash so a copy with one key changed starts from the same place. The
 * struct is filled in place behind a wrapped scalar, so a refusal halfway
 * frees everything through the scalar's magic.
 *
 * A holiday source is sorted here into one of three kinds: a literal date
 * goes straight into the arrays; a yearly date (--MM-DD, a MonthDay, a
 * month-and-day hash) is kept to be expanded for each year asked about;
 * and a code ref or an object with a holidays method is kept to be asked
 * for each year (tkb_sources.h). */

static void tkb_hours_parse(pTHX_ tkb_schedule *s, HV *spec, const char *what);
struct tkb_rule;
static struct tkb_rule *tkb_rule_magic(pTHX_ SV *sv);
static int tkb_rule_sv_has_code(pTHX_ SV *rule);
static SV *tkb_rule_spec_sv(pTHX_ SV *rule, const char *what);
static SV *tkb_rule_from_spec(pTHX_ SV *class, SV *spec, const char *what, int depth);

static const char *const tkb_spec_keys[] = { "weekend", "holidays", "rules", "working", "hours", "zone", "name", "reckon", NULL };

static void
tkb_spec_set(pTHX_ HV *spec, SV **args, I32 n, const char *what)
{
    I32 i;
    if (n % 2)
        croak("%s: needs key/value pairs", what);
    for (i = 0; i < n; i += 2) {
        STRLEN klen;
        const char *key = SvPV(args[i], klen);
        const char *const *k;
        for (k = tkb_spec_keys; *k; k++)
            if (strlen(*k) == klen && memEQ(*k, key, klen))
                break;
        if (!*k)
            croak("%s: unknown argument '%s'", what, key);
        (void)hv_store(spec, key, (I32)klen, newSVsv(args[i + 1]), 0);
    }
}

/* A spec value as a list: an array ref as it is, undef as nothing, and
 * anything else as a list of one. */
static AV *
tkb_list_of(pTHX_ SV *sv)
{
    AV *av;
    if (sv && SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV && !sv_isobject(sv))
        return (AV *)SvRV(sv);
    av = (AV *)sv_2mortal((SV *)newAV());
    if (sv && SvOK(sv))
        av_push(av, newSVsv(sv));
    return av;
}

static unsigned
tkb_days_in_month(int64_t y, unsigned m)
{
    static const unsigned days[] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
    if (m == 2 && (y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)))
        return 29;
    return days[m - 1];
}

static int
tkb_valid_civil(int64_t y, unsigned m, unsigned d)
{
    return m >= 1 && m <= 12 && d >= 1 && d <= tkb_days_in_month(y, m);
}

static int
tkb_two_digits(const char *p, unsigned *out)
{
    if (!isDIGIT(p[0]) || !isDIGIT(p[1]))
        return 0;
    *out = (unsigned)((p[0] - '0') * 10 + (p[1] - '0'));
    return 1;
}

/* "--MM-DD" or "--MMDD": a date in every year. */
static int
tkb_yearly_string(const char *p, STRLEN len, unsigned *m, unsigned *d)
{
    if (len == 7 && p[0] == '-' && p[1] == '-' && p[4] == '-')
        return tkb_two_digits(p + 2, m) && tkb_two_digits(p + 5, d);
    if (len == 6 && p[0] == '-' && p[1] == '-')
        return tkb_two_digits(p + 2, m) && tkb_two_digits(p + 4, d);
    return 0;
}

/* "MMDD" or "MM-DD", as a source asked for one year writes a day of it. */
static int
tkb_month_day_string(const char *p, STRLEN len, unsigned *m, unsigned *d)
{
    if (len == 4)
        return tkb_two_digits(p, m) && tkb_two_digits(p + 2, d);
    if (len == 5 && p[2] == '-')
        return tkb_two_digits(p, m) && tkb_two_digits(p + 3, d);
    return tkb_yearly_string(p, len, m, d);
}

static int
tkb_has_method(pTHX_ SV *sv, const char *method)
{
    return sv && sv_isobject(sv) && gv_fetchmethod_autoload(SvSTASH(SvRV(sv)), method, 0) != NULL;
}

/* "YYYY-MM-DD", with a sign and more digits allowed in the year, read in C;
 * 0 for any other string, which Time::Keeper::Date->parse then reads. */
static int
tkb_iso_date(const char *p, STRLEN len, int64_t *day)
{
    int64_t y = 0;
    int neg = 0;
    unsigned m, d, digits = 0;
    if (len < 10)
        return 0;
    if (*p == '-' || *p == '+') { neg = *p == '-'; p++; len--; }
    while (len > 6 && isDIGIT(*p)) { y = y * 10 + (*p - '0'); p++; len--; digits++; }
    if (digits < 4 || digits > 10 || len != 6 || p[0] != '-' || p[3] != '-')
        return 0;
    if (!tkb_two_digits(p + 1, &m) || !tkb_two_digits(p + 4, &d))
        return 0;
    if (neg) y = -y;
    if (!tkb_valid_civil(y, m, d))
        return 0;
    *day = tkb_days_from_civil(y, m, d);
    return 1;
}

/* A day from a date string, a Time::Keeper::Date or a Time::Keeper (its
 * own zone's date). */
static int64_t
tkb_day_from_sv(pTHX_ SV *sv, const char *what)
{
    tkb_val v;
    const char *why;
    if (sv && sv_isobject(sv) && sv_derived_from(sv, "Time::Keeper::Date")) {
        int64_t day;
        int lid;
        if (!tkb_date_day(aTHX_ sv, &day, &lid))
            croak("%s: the date's day count could not be read", what);
        return day;
    }
    if (sv && SvROK(sv) && tkb_in(aTHX_ sv, &v, &why)) {
        if (v.kind == TKB_KIND_YEAR_MONTH)
            croak("%s: a month is not a day", what);
        return v.day;
    }
    if (sv && SvOK(sv) && !SvROK(sv)) {
        STRLEN len;
        const char *p = SvPV(sv, len);
        int64_t day;
        SV *cls;
        if (tkb_iso_date(p, len, &day))
            return day;
        cls = sv_2mortal(newSVpvs("Time::Keeper::Date"));
        if (!tkb_sv_to_i64(aTHX_ tkb_call(aTHX_ tkb_call(aTHX_ cls, "parse", &sv, 1), "epoch_days", NULL, 0), &day))
            croak("%s: the date's day count could not be read", what);
        return day;
    }
    croak("%s: a date is a string or a Time::Keeper::Date, not %s", what,
          sv && SvOK(sv) ? (SvROK(sv) ? "a reference" : "that") : "undef");
    return 0;
}

static void
tkb_add_yearly(pTHX_ tkb_schedule *s, unsigned m, unsigned d, SV *name, const char *what)
{
    if (!tkb_valid_civil(2000, m, d))
        croak("%s: --%02u-%02u is not a date", what, m, d);
    Renew(s->yearly, s->n_yearly + 1, tkb_yearly);
    s->yearly[s->n_yearly].month = m;
    s->yearly[s->n_yearly].day = d;
    s->yearly[s->n_yearly].name = name && SvOK(name) ? newSVsv(name) : NULL;
    s->n_yearly++;
}

static void
tkb_add_generator(pTHX_ tkb_schedule *s, SV *src, AV *args)
{
    if (!s->gens) {
        s->gens = newAV();
        s->gen_args = newAV();
    }
    av_push(s->gens, newSVsv(src));
    av_push(s->gen_args, args ? newRV_noinc((SV *)args) : newSV(0));
}

/* A copy of an argument: an unblessed array or hash one level deep, so a
 * caller who changes theirs later changes nothing here. */
static SV *
tkb_arg_copy(pTHX_ SV *v)
{
    if (v && SvROK(v) && !sv_isobject(v) && SvTYPE(SvRV(v)) == SVt_PVAV) {
        AV *from = (AV *)SvRV(v), *to = newAV();
        SSize_t i, n = av_len(from) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(from, i, 0);
            av_push(to, e ? newSVsv(*e) : newSV(0));
        }
        return newRV_noinc((SV *)to);
    }
    if (v && SvROK(v) && !sv_isobject(v) && SvTYPE(SvRV(v)) == SVt_PVHV) {
        HV *from = (HV *)SvRV(v), *to = newHV();
        HE *he;
        hv_iterinit(from);
        while ((he = hv_iternext(from)))
            (void)hv_store_ent(to, hv_iterkeysv(he), newSVsv(hv_iterval(from, he)), 0);
        return newRV_noinc((SV *)to);
    }
    return newSVsv(v);
}

static int
tkb_key_cmp(const void *a, const void *b)
{
    return strcmp(*(const char *const *)a, *(const char *const *)b);
}

/* A source with arguments: { source => $obj, %args }, the arguments in key
 * order so a source is asked the same way every time. */
static void
tkb_add_source_with_args(pTHX_ tkb_schedule *s, HV *hv, const char *what)
{
    SV **src = hv_fetchs(hv, "source", 0);
    I32 n = (I32)HvUSEDKEYS(hv) - 1, i = 0, k;
    const char **keys;
    AV *args;
    HE *he;
    SV *buf;
    if (!src || !SvOK(*src))
        croak("%s: a source with arguments needs its source", what);
    if (tkb_rule_magic(aTHX_ *src)) {
        if (n)
            croak("%s: a rule as a source takes no arguments", what);
        tkb_add_generator(aTHX_ s, *src, NULL);
        return;
    }
    if (!(SvROK(*src) && !sv_isobject(*src) && SvTYPE(SvRV(*src)) == SVt_PVCV) && !tkb_has_method(aTHX_ *src, "holidays"))
        croak("%s: a source with arguments is a code ref or an object with a holidays method", what);
    buf = sv_2mortal(newSV((STRLEN)(n + 1) * sizeof(char *)));
    keys = (const char **)SvPVX(buf);
    hv_iterinit(hv);
    while ((he = hv_iternext(hv))) {
        STRLEN klen;
        const char *key = HePV(he, klen);
        unsigned m, d;
        int64_t day;
        if (klen == 6 && memEQ(key, "source", 6))
            continue;
        if (tkb_yearly_string(key, klen, &m, &d) || tkb_iso_date(key, klen, &day))
            croak("%s: a hash with a source holds the source's arguments, not the date '%s'", what, key);
        keys[i++] = key;
    }
    qsort(keys, (size_t)n, sizeof(char *), tkb_key_cmp);
    args = newAV();
    sv_2mortal((SV *)args);
    for (k = 0; k < n; k++) {
        SV **v = hv_fetch(hv, keys[k], (I32)strlen(keys[k]), 0);
        av_push(args, newSVpv(keys[k], 0));
        av_push(args, tkb_arg_copy(aTHX_ v ? *v : NULL));
    }
    tkb_add_generator(aTHX_ s, *src, (AV *)SvREFCNT_inc_simple_NN((SV *)args));
}

/* The month and day of a MonthDay object, through its accessors. */
static void
tkb_month_day_of(pTHX_ SV *obj, unsigned *m, unsigned *d, const char *what)
{
    int64_t mm, dd;
    if (!tkb_sv_to_i64(aTHX_ tkb_call(aTHX_ obj, "month", NULL, 0), &mm)
        || !tkb_sv_to_i64(aTHX_ tkb_call(aTHX_ obj, "day", NULL, 0), &dd))
        croak("%s: the month and day could not be read", what);
    *m = (unsigned)mm;
    *d = (unsigned)dd;
}

/* A hash of exactly month and day, with a name or not. */
static int
tkb_month_day_hash(pTHX_ HV *hv, unsigned *m, unsigned *d, SV **name)
{
    SV **pm = hv_fetchs(hv, "month", 0), **pd = hv_fetchs(hv, "day", 0), **pn = hv_fetchs(hv, "name", 0);
    int64_t mm, dd;
    if (!pm || !pd || HvUSEDKEYS(hv) != (pn ? 3u : 2u))
        return 0;
    if (!tkb_sv_to_i64(aTHX_ *pm, &mm) || !tkb_sv_to_i64(aTHX_ *pd, &dd))
        return 0;
    *m = (unsigned)mm;
    *d = (unsigned)dd;
    *name = pn ? *pn : NULL;
    return 1;
}

static void
tkb_add_holiday_source(pTHX_ tkb_schedule *s, SV *src, const char *what, int depth)
{
    if (depth > 32)
        croak("%s: holiday sources nest too deeply", what);
    if (!src || !SvOK(src))
        croak("%s: a holiday source is undef", what);
    if (sv_isobject(src)) {
        if (sv_derived_from(src, "Time::Keeper") || sv_derived_from(src, "Time::Keeper::Date")) {
            tkb_add_holiday(aTHX_ s, tkb_day_from_sv(aTHX_ src, what), NULL, 0);
            return;
        }
        if (sv_derived_from(src, "Time::Keeper::YearMonth"))
            croak("%s: a month is not a day", what);
        if (sv_derived_from(src, "Time::Keeper::MonthDay")) {
            unsigned m, d;
            tkb_month_day_of(aTHX_ src, &m, &d, what);
            tkb_add_yearly(aTHX_ s, m, d, NULL, what);
            return;
        }
        if (tkb_has_method(aTHX_ src, "holidays")) {
            tkb_add_generator(aTHX_ s, src, NULL);
            return;
        }
        croak("%s: an object with no holidays method is not a holiday source", what);
    }
    if (SvROK(src)) {
        SV *inner = SvRV(src);
        if (SvTYPE(inner) == SVt_PVAV) {
            AV *av = (AV *)inner;
            SSize_t i, n = av_len(av) + 1;
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(av, i, 0);
                tkb_add_holiday_source(aTHX_ s, e ? *e : NULL, what, depth + 1);
            }
            return;
        }
        if (SvTYPE(inner) == SVt_PVHV) {
            HV *hv = (HV *)inner;
            HE *he;
            unsigned m, d;
            SV *name;
            if (hv_exists(hv, "source", 6)) {
                tkb_add_source_with_args(aTHX_ s, hv, what);
                return;
            }
            if (tkb_month_day_hash(aTHX_ hv, &m, &d, &name)) {
                tkb_add_yearly(aTHX_ s, m, d, name, what);
                return;
            }
            hv_iterinit(hv);
            while ((he = hv_iternext(hv))) {
                SV *key = hv_iterkeysv(he);
                SV *val = hv_iterval(hv, he);
                STRLEN klen;
                const char *k = SvPV(key, klen);
                name = val && SvOK(val) ? val : NULL;
                if (tkb_yearly_string(k, klen, &m, &d))
                    tkb_add_yearly(aTHX_ s, m, d, name, what);
                else
                    tkb_add_holiday(aTHX_ s, tkb_day_from_sv(aTHX_ key, what), name, 0);
            }
            return;
        }
        if (SvTYPE(inner) == SVt_PVCV) {
            tkb_add_generator(aTHX_ s, src, NULL);
            return;
        }
        croak("%s: a holiday source is a date, a name map, a code ref, an object with a holidays method or a list of them, not a reference of that kind", what);
    }
    {
        STRLEN len;
        const char *p = SvPV(src, len);
        unsigned m, d;
        if (tkb_yearly_string(p, len, &m, &d))
            tkb_add_yearly(aTHX_ s, m, d, NULL, what);
        else
            tkb_add_holiday(aTHX_ s, tkb_day_from_sv(aTHX_ src, what), NULL, 0);
    }
}

static int
tkb_weekday_of_sv(pTHX_ SV *sv, const char *what)
{
    int64_t n;
    if (!sv || !SvOK(sv) || SvROK(sv) || !looks_like_number(sv) || !tkb_sv_to_i64(aTHX_ sv, &n) || n < 1 || n > 7)
        croak("%s: a weekend day is 1 (Monday) to 7 (Sunday)", what);
    return (int)n;
}

static void
tkb_weekend_from_spec(pTHX_ tkb_schedule *s, HV *spec, const char *what)
{
    SV **p = hv_fetchs(spec, "weekend", 0);
    SV *sv = p ? *p : NULL;
    s->weekend = 0;
    if (!sv || !SvOK(sv)) {
        s->weekend = TKB_WEEKEND_BIT(6) | TKB_WEEKEND_BIT(7);
        return;
    }
    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) {
        AV *av = (AV *)SvRV(sv);
        SSize_t i, n = av_len(av) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            int dow = tkb_weekday_of_sv(aTHX_ e ? *e : NULL, what);
            if (s->weekend & TKB_WEEKEND_BIT(dow))
                croak("%s: weekend day %d is given twice", what, dow);
            s->weekend |= TKB_WEEKEND_BIT(dow);
        }
        return;
    }
    if (!SvROK(sv)) {
        int ws = 0, we = 0, d;
#if TKB_HAVE_V3
        if (TKB_V3) {
            STRLEN len;
            const char *code = SvPV(sv, len);
            int id = TKB(locale_find)(code, len);
            if (id < 0 || TKB(locale_weekend)(aTHX_ id, &ws, &we, NULL, 0) != TIME_KEEPER_OK)
                ws = 0;
        }
#endif
        if (!ws) {
            SV *cls = sv_2mortal(newSVpvs("Time::Keeper::Locale"));
            ws = tkb_weekday_of_sv(aTHX_ tkb_call(aTHX_ cls, "weekend_start", &sv, 1), what);
            we = tkb_weekday_of_sv(aTHX_ tkb_call(aTHX_ cls, "weekend_end", &sv, 1), what);
        }
        if (ws <= we)
            for (d = ws; d <= we; d++) s->weekend |= TKB_WEEKEND_BIT(d);
        else {
            for (d = ws; d <= 7; d++) s->weekend |= TKB_WEEKEND_BIT(d);
            for (d = 1; d <= we; d++) s->weekend |= TKB_WEEKEND_BIT(d);
        }
        return;
    }
    croak("%s: weekend is a list of days or a locale code", what);
}

/* Fills a fresh struct from a literal spec. */
static void
tkb_build_into(pTHX_ tkb_schedule *s, HV *spec, const char *what)
{
    SV **p;

    if (hv_fetchs(spec, "join", 0))
        croak("%s: a joined schedule cannot be changed; change the schedules and join them again", what);

    tkb_weekend_from_spec(aTHX_ s, spec, what);
    tkb_set_weekend(s, s->weekend);

    if ((p = hv_fetchs(spec, "holidays", 0)) && SvOK(*p)) {
        AV *av = tkb_list_of(aTHX_ *p);
        SSize_t j, n = av_len(av) + 1;
        for (j = 0; j < n; j++) {
            SV **e = av_fetch(av, j, 0);
            tkb_add_holiday_source(aTHX_ s, e ? *e : NULL, what, 0);
        }
    }

    if ((p = hv_fetchs(spec, "rules", 0)) && SvOK(*p)) {
        AV *av = tkb_list_of(aTHX_ *p);
        SSize_t j, n = av_len(av) + 1;
        SV *cls = sv_2mortal(newSVpvs("Time::Keeper::Business::Rule"));
        for (j = 0; j < n; j++) {
            SV **e = av_fetch(av, j, 0);
            if (e && tkb_rule_magic(aTHX_ *e))
                tkb_add_generator(aTHX_ s, *e, NULL);
            else if (e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVHV && !sv_isobject(*e))
                tkb_add_generator(aTHX_ s, tkb_rule_from_spec(aTHX_ cls, *e, what, 0), NULL);
            else
                croak("%s: rules is a list of rules, or of rules as data", what);
        }
    }

    if ((p = hv_fetchs(spec, "working", 0)) && SvOK(*p)) {
        AV *av = tkb_list_of(aTHX_ *p);
        SSize_t j, n = av_len(av) + 1;
        for (j = 0; j < n; j++) {
            SV **e = av_fetch(av, j, 0);
            int64_t day = tkb_day_from_sv(aTHX_ e ? *e : NULL, what);
            if (tkb_find_named(s->names, s->n_names, day) >= 0) {
                SV *str = sv_2mortal(tkb_day_string(aTHX_ day));
                croak("%s: %" SVf " is both a holiday and a working day", what, SVfARG(str));
            }
            if (tkb_is_weekend(s, day))
                tkb_insert_day(&s->open, &s->n_open, day);
        }
    }

    tkb_hours_parse(aTHX_ s, spec, what);

    if (s->n_yearly || s->gens) {
        s->lazy = 1;
        s->year_lo = INT64_MAX;
        s->year_hi = INT64_MIN;
    }
}

static HV *
tkb_spec_copy(pTHX_ HV *spec)
{
    HV *out = newHV();
    HE *he;
    hv_iterinit(spec);
    while ((he = hv_iternext(spec))) {
        SV *key = hv_iterkeysv(he);
        (void)hv_store_ent(out, key, newSVsv(hv_iterval(spec, he)), 0);
    }
    return out;
}

/* A new schedule in a class, from a spec the caller hands over. */
static SV *
tkb_schedule_make(pTHX_ HV *spec, HV *stash, const char *what)
{
    tkb_schedule *s = tkb_schedule_new(aTHX);
    SV *rv = sv_2mortal(tkb_schedule_wrap(aTHX_ s, spec, stash));
    tkb_build_into(aTHX_ s, spec, what);
    return SvREFCNT_inc_simple_NN(rv);
}

static HV *
tkb_stash_of(pTHX_ SV *invocant)
{
    if (SvROK(invocant) && SvOBJECT(SvRV(invocant)))
        return SvSTASH(SvRV(invocant));
    return gv_stashsv(invocant, GV_ADD);
}

/* Whether the plain form would rebuild the same schedule: not with a
 * source that is asked year by year, and not a join whose parts have
 * yearly or generated sources. */
static void
tkb_freezable(pTHX_ const tkb_schedule *s, const char *what)
{
    size_t r;
    if (s->join_hours)
        croak("%s: cannot freeze a join with hours; freeze its parts and join them again", what);
    for (r = 0; r < s->hours.n_rules; r++)
        if (tkb_rule_sv_has_code(aTHX_ s->hours.rule_svs[r]))
            croak("%s: cannot freeze a schedule whose hours rules hold a code ref", what);
    if (s->gens) {
        SSize_t g, n = av_len(s->gens) + 1;
        for (g = 0; g < n; g++) {
            SV **gen = av_fetch(s->gens, g, 0);
            SV **a = s->gen_args ? av_fetch(s->gen_args, g, 0) : NULL;
            if (!gen || !tkb_rule_magic(aTHX_ *gen) || (a && SvOK(*a)))
                croak("%s: cannot freeze a schedule with a code ref or an object among its holiday sources; list its holidays", what);
            if (tkb_rule_sv_has_code(aTHX_ *gen))
                croak("%s: cannot freeze a schedule whose rules hold a code ref; list its holidays", what);
        }
    }

    if (s->join_a) {
        const tkb_schedule *a = tkb_schedule_of(aTHX_ s->join_a, what), *b = tkb_schedule_of(aTHX_ s->join_b, what);
        if (a->lazy || b->lazy)
            croak("%s: cannot freeze a join of schedules with yearly or generated sources; join the thawed schedules again", what);
    }
}

/* The plain form: what TO_JSON gives and a freeze carries. Every date is
 * a string, so it rebuilds anywhere; a yearly date is its --MM-DD key and
 * the days it was expanded to are left out. */
static HV *
tkb_plain(pTHX_ const tkb_schedule *s, HV *spec)
{
    HV *out = newHV();
    AV *weekend = newAV();
    HV *holidays = newHV();
    AV *working = newAV();
    SV **p;
    size_t i;
    int d;
    for (d = 1; d <= 7; d++)
        if (s->weekend & TKB_WEEKEND_BIT(d))
            av_push(weekend, newSViv(d));
    for (i = 0; i < s->n_names; i++) {
        SV *key;
        if (s->names[i].flags & TKB_NAMED_LAZY)
            continue;
        key = sv_2mortal(tkb_day_string(aTHX_ s->names[i].day));
        (void)hv_store_ent(holidays, key, s->names[i].name ? newSVsv(s->names[i].name) : newSV(0), 0);
    }
    for (i = 0; i < s->n_yearly; i++) {
        SV *key = sv_2mortal(newSVpvf("--%02u-%02u", s->yearly[i].month, s->yearly[i].day));
        (void)hv_store_ent(holidays, key, s->yearly[i].name ? newSVsv(s->yearly[i].name) : newSV(0), 0);
    }
    for (i = 0; i < s->n_open; i++)
        av_push(working, tkb_day_string(aTHX_ s->open[i]));
    (void)hv_stores(out, "weekend", newRV_noinc((SV *)weekend));
    (void)hv_stores(out, "holidays", newRV_noinc((SV *)holidays));
    (void)hv_stores(out, "working", newRV_noinc((SV *)working));
    if (s->gens) {
        AV *rules = newAV();
        SSize_t g, n = av_len(s->gens) + 1;
        for (g = 0; g < n; g++) {
            SV **gen = av_fetch(s->gens, g, 0);
            if (gen && tkb_rule_magic(aTHX_ *gen))
                av_push(rules, tkb_rule_spec_sv(aTHX_ *gen, "Time::Keeper::Business->TO_JSON"));
        }
        (void)hv_stores(out, "rules", newRV_noinc((SV *)rules));
    }
    if ((p = hv_fetchs(spec, "zone", 0)) && SvOK(*p))
        (void)hv_stores(out, "zone", newSVsv(*p));
    if ((p = hv_fetchs(spec, "name", 0)) && SvOK(*p))
        (void)hv_stores(out, "name", newSVsv(*p));
    if ((p = hv_fetchs(spec, "reckon", 0)) && SvOK(*p))
        (void)hv_stores(out, "reckon", newSVsv(*p));
    if ((p = hv_fetchs(spec, "hours", 0)) && SvOK(*p)) {
        SV *h = *p;
        SV **br;
        if (SvROK(h) && SvTYPE(SvRV(h)) == SVt_PVHV && (br = hv_fetchs((HV *)SvRV(h), "by_rule", 0)) && SvROK(*br) && SvTYPE(SvRV(*br)) == SVt_PVAV) {
            HV *copy = newHV();
            HE *he;
            AV *pairs = newAV(), *from = (AV *)SvRV(*br);
            SSize_t i, n = av_len(from) + 1;
            hv_iterinit((HV *)SvRV(h));
            while ((he = hv_iternext((HV *)SvRV(h))))
                (void)hv_store_ent(copy, hv_iterkeysv(he), newSVsv(hv_iterval((HV *)SvRV(h), he)), 0);
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(from, i, 0);
                AV *pair = newAV();
                SV **rule = e && SvROK(*e) ? av_fetch((AV *)SvRV(*e), 0, 0) : NULL;
                SV **spans = e && SvROK(*e) ? av_fetch((AV *)SvRV(*e), 1, 0) : NULL;
                av_push(pair, rule && tkb_rule_magic(aTHX_ *rule) ? tkb_rule_spec_sv(aTHX_ *rule, "Time::Keeper::Business->TO_JSON") : newSVsv(rule ? *rule : &PL_sv_undef));
                av_push(pair, newSVsv(spans ? *spans : &PL_sv_undef));
                av_push(pairs, newRV_noinc((SV *)pair));
            }
            (void)hv_stores(copy, "by_rule", newRV_noinc((SV *)pairs));
            (void)hv_stores(out, "hours", newRV_noinc((SV *)copy));
        }
        else
            (void)hv_stores(out, "hours", newSVsv(h));
    }
    return out;
}

/* Two schedules as one: closed when either is (QuantLib's JoinHolidays)
 * or only when both are (JoinBusinessDays). Every day either schedule
 * lists is judged under the joined weekend; a day neither lists is a
 * weekend day in one, the other or both, which the joined mask already
 * says. */
static void
tkb_join_days(pTHX_ tkb_schedule *out, const tkb_schedule *a, const tkb_schedule *b, int both)
{
    int64_t *cand = NULL;
    size_t n_cand = 0, i;
    const tkb_schedule *two[2];
    two[0] = a; two[1] = b;
    tkb_set_weekend(out, both ? (uint8_t)(a->weekend & b->weekend) : (uint8_t)(a->weekend | b->weekend));
    for (i = 0; i < 2; i++) {
        size_t j;
        for (j = 0; j < two[i]->n_closed; j++) tkb_insert_day(&cand, &n_cand, two[i]->closed[j]);
        for (j = 0; j < two[i]->n_open; j++)   tkb_insert_day(&cand, &n_cand, two[i]->open[j]);
        for (j = 0; j < two[i]->n_names; j++)  tkb_insert_day(&cand, &n_cand, two[i]->names[j].day);
    }
    for (i = 0; i < n_cand; i++) {
        int64_t d = cand[i];
        int ca = tkb_is_closed(a, d), cb = tkb_is_closed(b, d);
        int closed = both ? (ca && cb) : (ca || cb);
        int w = tkb_is_weekend(out, d);
        if (closed && !w) tkb_insert_day(&out->closed, &out->n_closed, d);
        if (!closed && w) tkb_insert_day(&out->open, &out->n_open, d);
    }
    Safefree(cand);
    for (i = 0; i < a->n_names; i++) {
        SV *other;
        if (!both || tkb_holiday(b, a->names[i].day, &other))
            tkb_insert_named(aTHX_ &out->names, &out->n_names, a->names[i].day, a->names[i].name, a->names[i].flags);
    }
    for (i = 0; i < b->n_names; i++) {
        SV *other;
        if (!both || tkb_holiday(a, b->names[i].day, &other))
            tkb_insert_named(aTHX_ &out->names, &out->n_names, b->names[i].day, b->names[i].name, b->names[i].flags);
    }
}

#endif
