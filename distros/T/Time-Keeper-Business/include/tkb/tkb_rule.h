#ifndef TKB_RULE_H
#define TKB_RULE_H

/* Holiday rules: a fixed date, the nth weekday of a month, a day counted
 * from Easter, a day counted from another rule, and sets of them, each
 * with what happens when it falls on a weekend. A rule is a blessed scalar
 * carrying this struct as ext magic, and never changes: observed, between
 * and only_if copy it. Its years are computed on day numbers and kept, so
 * a schedule asking a rule for a year it has seen gets the days back with
 * no Date made at all. */

#define TKB_RULE_FIXED    0
#define TKB_RULE_NTH      1
#define TKB_RULE_EASTER   2
#define TKB_RULE_RELATIVE 3
#define TKB_RULE_SET      4

#define TKB_OBS_NONE    0
#define TKB_OBS_NEXT    1
#define TKB_OBS_NEAREST 2
#define TKB_OBS_MONDAY  3
#define TKB_OBS_CODE    4
#define TKB_OBS_UNSET  -1

static const char *const tkb_rule_kinds[] = { "fixed", "nth", "easter", "relative", "set" };

typedef struct tkb_rule_year {
    int64_t  year;
    size_t   n;
    int64_t *days;
    SV     **names;              /* each NULL or a counted SV */
    AV      *pairs;              /* the [Date, name] pairs, made on the first ask */
} tkb_rule_year;

typedef struct tkb_rule {
    int      kind;
    int      month, day, dow, n, offset, orthodox, days;
    SV      *child;              /* relative: the base rule, an RV */
    SV     **members;            /* set: RVs */
    size_t   n_members;
    SV      *name;
    int      observed;           /* TKB_OBS_UNSET when never given */
    SV      *observed_code;
    int      has_weekend;
    uint8_t  weekend;
    int      has_from, has_to;
    int64_t  from, to;
    SV      *only_if;
    tkb_rule_year *memo;
    size_t   n_memo;
} tkb_rule;

static void
tkb_rule_memo_free(pTHX_ tkb_rule *r)
{
    size_t i, j;
    for (i = 0; i < r->n_memo; i++) {
        for (j = 0; j < r->memo[i].n; j++)
            SvREFCNT_dec(r->memo[i].names[j]);
        Safefree(r->memo[i].days);
        Safefree(r->memo[i].names);
        SvREFCNT_dec((SV *)r->memo[i].pairs);
    }
    Safefree(r->memo);
    r->memo = NULL;
    r->n_memo = 0;
}

static void
tkb_rule_free(pTHX_ tkb_rule *r)
{
    size_t i;
    if (!r)
        return;
    tkb_rule_memo_free(aTHX_ r);
    SvREFCNT_dec(r->child);
    for (i = 0; i < r->n_members; i++)
        SvREFCNT_dec(r->members[i]);
    Safefree(r->members);
    SvREFCNT_dec(r->name);
    SvREFCNT_dec(r->observed_code);
    SvREFCNT_dec(r->only_if);
    Safefree(r);
}

/* A copy with its own references and no memo, for observed, between and
 * only_if to change. */
static tkb_rule *
tkb_rule_copy(pTHX_ const tkb_rule *r)
{
    tkb_rule *c;
    size_t i;
    Newx(c, 1, tkb_rule);
    *c = *r;
    c->memo = NULL;
    c->n_memo = 0;
    SvREFCNT_inc_simple_void(c->child);
    SvREFCNT_inc_simple_void(c->name);
    SvREFCNT_inc_simple_void(c->observed_code);
    SvREFCNT_inc_simple_void(c->only_if);
    if (r->n_members) {
        Newx(c->members, r->n_members, SV *);
        for (i = 0; i < r->n_members; i++)
            c->members[i] = SvREFCNT_inc_simple_NN(r->members[i]);
    }
    return c;
}

static int
tkb_rule_mg_free(pTHX_ SV *sv, MAGIC *mg)
{
    PERL_UNUSED_ARG(sv);
    tkb_rule_free(aTHX_ (tkb_rule *)mg->mg_ptr);
    mg->mg_ptr = NULL;
    return 0;
}

#ifdef USE_ITHREADS
/* A thread's copy: its own references; the memo is a cache and is not
 * carried. */
static int
tkb_rule_mg_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param)
{
    const tkb_rule *r = (const tkb_rule *)mg->mg_ptr;
    tkb_rule *c;
    size_t i;
    Newx(c, 1, tkb_rule);
    *c = *r;
    c->memo = NULL;
    c->n_memo = 0;
    c->child = r->child ? sv_dup_inc(r->child, param) : NULL;
    c->name = r->name ? sv_dup_inc(r->name, param) : NULL;
    c->observed_code = r->observed_code ? sv_dup_inc(r->observed_code, param) : NULL;
    c->only_if = r->only_if ? sv_dup_inc(r->only_if, param) : NULL;
    c->members = NULL;
    if (r->n_members) {
        Newx(c->members, r->n_members, SV *);
        for (i = 0; i < r->n_members; i++)
            c->members[i] = sv_dup_inc(r->members[i], param);
    }
    mg->mg_ptr = (char *)c;
    return 0;
}
#endif

static MGVTBL tkb_rule_vtbl;

static void
tkb_rule_vtbl_init(void)
{
    tkb_rule_vtbl.svt_free = tkb_rule_mg_free;
#ifdef USE_ITHREADS
    tkb_rule_vtbl.svt_dup = tkb_rule_mg_dup;
#endif
}

static SV *
tkb_rule_wrap(pTHX_ tkb_rule *r, HV *stash)
{
    SV *inner = newSV(0);
    SV *rv = newRV_noinc(inner);
    MAGIC *mg;
    sv_bless(rv, stash);
    mg = sv_magicext(inner, NULL, PERL_MAGIC_ext, &tkb_rule_vtbl, (const char *)r, 0);
#ifdef USE_ITHREADS
    mg->mg_flags |= MGf_DUP;
#else
    PERL_UNUSED_VAR(mg);
#endif
    return rv;
}

static tkb_rule *
tkb_rule_magic(pTHX_ SV *sv)
{
    MAGIC *mg;
    if (!sv || !SvROK(sv) || !SvOBJECT(SvRV(sv)) || SvTYPE(SvRV(sv)) > SVt_PVMG)
        return NULL;
    for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic)
        if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &tkb_rule_vtbl)
            return (tkb_rule *)mg->mg_ptr;
    return NULL;
}

static tkb_rule *
tkb_rule_of(pTHX_ SV *sv, const char *what)
{
    tkb_rule *r = tkb_rule_magic(aTHX_ sv);
    if (!r)
        croak("%s: not a Time::Keeper::Business::Rule", what);
    return r;
}

/* ---- arguments ---------------------------------------------------------- */

/* A whole number in a range, with the messages the rules have always
 * given: needed, a whole number, the range. */
static int64_t
tkb_rule_int(pTHX_ const char *what, const char *key, SV *sv, int64_t lo, int64_t hi)
{
    STRLEN len, i = 0;
    const char *p;
    int64_t n = 0;
    int neg = 0;
    if (!sv || !SvOK(sv))
        croak("%s: %s is needed", what, key);
    if (SvROK(sv))
        croak("%s: %s must be a whole number", what, key);
    p = SvPV(sv, len);
    if (len && p[0] == '-') { neg = 1; i = 1; }
    if (i >= len)
        croak("%s: %s must be a whole number", what, key);
    for (; i < len; i++) {
        if (!isDIGIT(p[i]))
            croak("%s: %s must be a whole number", what, key);
        if (n < INT64_C(100000000000))
            n = n * 10 + (p[i] - '0');
    }
    if (neg)
        n = -n;
    if (n < lo || n > hi)
        croak("%s: %s must be %" IVdf " to %" IVdf, what, key, (IV)lo, (IV)hi);
    return n;
}

static uint8_t
tkb_rule_weekend_of(pTHX_ SV *sv, const char *what)
{
    AV *av;
    SSize_t i, n;
    uint8_t mask = 0;
    if (!sv || !SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVAV || sv_isobject(sv))
        croak("%s: weekend is a list of days, 1 to 7", what);
    av = (AV *)SvRV(sv);
    n = av_len(av) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(av, i, 0);
        mask |= TKB_WEEKEND_BIT(tkb_rule_int(aTHX_ what, "a weekend day", e ? *e : NULL, 1, 7));
    }
    return mask;
}

static void
tkb_rule_set_observed(pTHX_ tkb_rule *r, SV *form, const char *what)
{
    static const char *const msg = "%s: the form is none, next_business_day, nearest_business_day, next_monday or a code ref";
    SvREFCNT_dec(r->observed_code);
    r->observed_code = NULL;
    if (form && SvROK(form) && SvTYPE(SvRV(form)) == SVt_PVCV) {
        r->observed = TKB_OBS_CODE;
        r->observed_code = newSVsv(form);
        return;
    }
    if (!form || !SvOK(form) || SvROK(form))
        croak(msg, what);
    {
        const char *p = SvPV_nolen(form);
        if (strEQ(p, "none")) r->observed = TKB_OBS_NONE;
        else if (strEQ(p, "next_business_day")) r->observed = TKB_OBS_NEXT;
        else if (strEQ(p, "nearest_business_day")) r->observed = TKB_OBS_NEAREST;
        else if (strEQ(p, "next_monday")) r->observed = TKB_OBS_MONDAY;
        else croak(msg, what);
    }
}

static void
tkb_rule_set_years(pTHX_ tkb_rule *r, SV *from, SV *to, const char *what)
{
    r->has_from = from && SvOK(from);
    r->has_to = to && SvOK(to);
    if (r->has_from) r->from = tkb_rule_int(aTHX_ what, "from", from, -999999999, 999999999);
    if (r->has_to)   r->to   = tkb_rule_int(aTHX_ what, "to", to, -999999999, 999999999);
}

static void
tkb_rule_set_only_if(pTHX_ tkb_rule *r, SV *code, const char *what)
{
    if (!code || !SvROK(code) || SvTYPE(SvRV(code)) != SVt_PVCV)
        croak("%s: needs a code ref", what);
    SvREFCNT_dec(r->only_if);
    r->only_if = newSVsv(code);
}

/* The keys every constructor takes beyond its own: the name, and the
 * three changes as if made afterwards. 1 when the key was one of them. */
static int
tkb_rule_common_key(pTHX_ tkb_rule *r, const char *k, SV *v, SV **from, SV **to, const char *what)
{
    if (strEQ(k, "name")) {
        SvREFCNT_dec(r->name);
        r->name = v && SvOK(v) ? newSVsv(v) : NULL;
        return 1;
    }
    if (strEQ(k, "observed")) { tkb_rule_set_observed(aTHX_ r, v, what); return 1; }
    if (strEQ(k, "weekend")) { r->weekend = tkb_rule_weekend_of(aTHX_ v, what); r->has_weekend = 1; return 1; }
    if (strEQ(k, "from")) { *from = v; return 1; }
    if (strEQ(k, "to")) { *to = v; return 1; }
    if (strEQ(k, "only_if")) { tkb_rule_set_only_if(aTHX_ r, v, what); return 1; }
    return 0;
}

static tkb_rule *
tkb_rule_new(pTHX_ int kind)
{
    tkb_rule *r;
    Newxz(r, 1, tkb_rule);
    r->kind = kind;
    r->observed = TKB_OBS_UNSET;
    return r;
}

/* ---- dates ------------------------------------------------------------ */

static int64_t
tkb_trunc_div(int64_t a, int64_t b)
{
    return a / b;
}

static int64_t
tkb_gregorian_easter(int64_t y)
{
    int64_t a = tkb_floor_mod(y, 19), b = tkb_trunc_div(y, 100), c = tkb_floor_mod(y, 100);
    int64_t d = tkb_trunc_div(b, 4), e = tkb_floor_mod(b, 4);
    int64_t f = tkb_trunc_div(b + 8, 25), g = tkb_trunc_div(b - f + 1, 3);
    int64_t h = tkb_floor_mod(19 * a + b - d - g + 15, 30);
    int64_t i = tkb_trunc_div(c, 4), k = tkb_floor_mod(c, 4);
    int64_t l = tkb_floor_mod(32 + 2 * e + 2 * i - h - k, 7);
    int64_t m = tkb_trunc_div(a + 11 * h + 22 * l, 451);
    int64_t month = tkb_trunc_div(h + l - 7 * m + 114, 31);
    int64_t day = tkb_floor_mod(h + l - 7 * m + 114, 31) + 1;
    return tkb_days_from_civil(y, (unsigned)month, (unsigned)day);
}

/* The Julian computus, moved onto the Gregorian calendar through the
 * Julian day number. */
static int64_t
tkb_julian_easter(int64_t y)
{
    int64_t a = tkb_floor_mod(y, 4), b = tkb_floor_mod(y, 7), c = tkb_floor_mod(y, 19);
    int64_t d = tkb_floor_mod(19 * c + 15, 30);
    int64_t e = tkb_floor_mod(2 * a + 4 * b - d + 34, 7);
    int64_t month = tkb_trunc_div(d + e + 114, 31);
    int64_t day = tkb_floor_mod(d + e + 114, 31) + 1;
    int64_t shift = tkb_trunc_div(14 - month, 12);
    int64_t yy = y + 4800 - shift;
    int64_t mm = month + 12 * shift - 3;
    int64_t jdn = day + tkb_trunc_div(153 * mm + 2, 5) + 365 * yy + tkb_trunc_div(yy, 4) - 32083;
    return jdn - 2440588;
}

/* A rule's own date in a year, before any observed move; 0 when it has
 * none that year. */
static int
tkb_rule_base(pTHX_ const tkb_rule *r, int64_t year, int64_t *out)
{
    switch (r->kind) {
    case TKB_RULE_FIXED:
        if (!tkb_valid_civil(year, (unsigned)r->month, (unsigned)r->day))
            return 0;
        *out = tkb_days_from_civil(year, (unsigned)r->month, (unsigned)r->day);
        return 1;
    case TKB_RULE_NTH: {
        int64_t first = tkb_days_from_civil(year, (unsigned)r->month, 1);
        unsigned dim = tkb_days_in_month(year, (unsigned)r->month);
        int fdow = (int)tkb_dow_from_days(first);
        if (r->n == -1) {
            int ldow = (int)tkb_dow_from_days(first + dim - 1);
            *out = first + dim - 1 - ((ldow - r->dow + 7) % 7);
            return 1;
        }
        {
            int64_t d = (r->dow - fdow + 7) % 7 + 7 * (int64_t)(r->n - 1);
            if (d >= dim)
                return 0;
            *out = first + d;
            return 1;
        }
    }
    case TKB_RULE_EASTER:
        *out = (r->orthodox ? tkb_julian_easter(year) : tkb_gregorian_easter(year)) + r->offset;
        return 1;
    case TKB_RULE_RELATIVE: {
        int64_t base;
        if (!tkb_rule_base(aTHX_ tkb_rule_of(aTHX_ r->child, "Time::Keeper::Business::Rule"), year, &base))
            return 0;
        *out = base + r->days;
        return 1;
    }
    default:
        croak("Time::Keeper::Business::Rule: a set has no date of its own");
    }
    return 0;
}

static SV *
tkb_rule_call1(pTHX_ SV *code, SV *arg)
{
    dSP;
    SV *ret;
    int count;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(arg);
    PUTBACK;
    count = call_sv(code, G_SCALAR);
    SPAGAIN;
    ret = count ? POPs : &PL_sv_undef;
    SvREFCNT_inc_simple_void_NN(ret);
    PUTBACK;
    FREETMPS;
    LEAVE;
    return sv_2mortal(ret);
}

static int
tkb_rule_applies(pTHX_ const tkb_rule *r, int64_t year)
{
    if (r->has_from && year < r->from)
        return 0;
    if (r->has_to && year > r->to)
        return 0;
    if (r->only_if) {
        SV *y = sv_2mortal(tkb_i64_sv(aTHX_ year));
        if (!SvTRUE(tkb_rule_call1(aTHX_ r->only_if, y)))
            return 0;
    }
    return 1;
}

/* The leaves that hold in a year, in order, into a mortal buffer. */
static void
tkb_rule_leaves(pTHX_ const tkb_rule *r, int64_t year, SV *buf, int depth)
{
    size_t i;
    if (depth > 64)
        croak("Time::Keeper::Business::Rule: sets nest too deeply");
    if (!tkb_rule_applies(aTHX_ r, year))
        return;
    if (r->kind != TKB_RULE_SET) {
        sv_catpvn(buf, (const char *)&r, sizeof r);
        return;
    }
    for (i = 0; i < r->n_members; i++)
        tkb_rule_leaves(aTHX_ tkb_rule_of(aTHX_ r->members[i], "Time::Keeper::Business::Rule"), year, buf, depth + 1);
}

static int
tkb_rule_any_observed(pTHX_ const tkb_rule *r, int64_t year)
{
    SV *buf = sv_2mortal(newSVpvs(""));
    const tkb_rule *const *leaf;
    size_t i, n;
    tkb_rule_leaves(aTHX_ r, year, buf, 0);
    leaf = (const tkb_rule *const *)SvPVX(buf);
    n = SvCUR(buf) / sizeof(tkb_rule *);
    for (i = 0; i < n; i++)
        if (leaf[i]->observed != TKB_OBS_UNSET)
            return 1;
    return 0;
}

static int
tkb_rule_moves(const tkb_rule *leaf, int64_t day, uint8_t weekend)
{
    if (leaf->observed == TKB_OBS_UNSET || leaf->observed == TKB_OBS_NONE)
        return 0;
    if (leaf->observed == TKB_OBS_CODE)
        return 1;
    return (weekend & TKB_WEEKEND_BIT(tkb_dow_from_days(day))) != 0;
}

static int
tkb_rule_taken(const int64_t *taken, size_t n, int64_t day)
{
    size_t i;
    for (i = 0; i < n; i++)
        if (taken[i] == day)
            return 1;
    return 0;
}

static SV *
tkb_rule_date(pTHX_ int64_t day)
{
    SV *cls = sv_2mortal(newSVpvs("Time::Keeper::Date"));
    SV *d = sv_2mortal(tkb_i64_sv(aTHX_ day));
    return tkb_call(aTHX_ cls, "from_epoch_days", &d, 1);
}

/* Where a leaf's date moves to: 0 for nowhere (a code ref's undef). */
static int
tkb_rule_move(pTHX_ const tkb_rule *leaf, int64_t day, const int64_t *taken, size_t n_taken, uint8_t weekend, int64_t *out)
{
    if (weekend == 0x7f && leaf->observed != TKB_OBS_CODE)
        croak("Time::Keeper::Business::Rule: a weekend of every day leaves no day to move a holiday to");
    switch (leaf->observed) {
    case TKB_OBS_CODE: {
        SV *r = tkb_rule_call1(aTHX_ leaf->observed_code, tkb_rule_date(aTHX_ day));
        int64_t d;
        if (!SvOK(r))
            return 0;
        if (!sv_isobject(r) || !sv_derived_from(r, "Time::Keeper::Date"))
            croak("Time::Keeper::Business::Rule: an observed code ref must give a Time::Keeper::Date or undef");
        if (!tkb_sv_to_i64(aTHX_ tkb_call(aTHX_ r, "epoch_days", NULL, 0), &d))
            croak("Time::Keeper::Business::Rule: the date an observed code ref gave could not be read");
        *out = d;
        return 1;
    }
    case TKB_OBS_NEXT: {
        int64_t d = day;
        do { d++; } while ((weekend & TKB_WEEKEND_BIT(tkb_dow_from_days(d))) || tkb_rule_taken(taken, n_taken, d));
        *out = d;
        return 1;
    }
    case TKB_OBS_MONDAY: {
        int dow = (int)tkb_dow_from_days(day);
        *out = day + (dow == 1 ? 7 : 8 - dow);
        return 1;
    }
    default: {
        int64_t back = day, fwd = day;
        int64_t nb = 0, nf = 0;
        do { back--; nb++; } while (weekend & TKB_WEEKEND_BIT(tkb_dow_from_days(back)));
        do { fwd++; nf++; } while (weekend & TKB_WEEKEND_BIT(tkb_dow_from_days(fwd)));
        *out = nf < nb ? fwd : back;
        return 1;
    }
    }
}

/* One year computed: the dates every leaf lands on, in leaf order, into
 * two mortal buffers (days, and the leaf each came from). The stayers take
 * their days first, then the movers find a free one in order. */
static void
tkb_rule_compute(pTHX_ const tkb_rule *top, int64_t year, SV *days_out, SV *leaves_out)
{
    uint8_t weekend = top->has_weekend ? top->weekend : (uint8_t)(TKB_WEEKEND_BIT(6) | TKB_WEEKEND_BIT(7));
    SV *lbuf = sv_2mortal(newSVpvs(""));
    SV *rows = sv_2mortal(newSVpvs(""));
    SV *rowleaf = sv_2mortal(newSVpvs(""));
    SV *taken = sv_2mortal(newSVpvs(""));
    const tkb_rule *const *leaf;
    size_t i, n, nr;
    tkb_rule_leaves(aTHX_ top, year, lbuf, 0);
    leaf = (const tkb_rule *const *)SvPVX(lbuf);
    n = SvCUR(lbuf) / sizeof(tkb_rule *);
    for (i = 0; i < n; i++) {
        int64_t d;
        if (!tkb_rule_base(aTHX_ leaf[i], year, &d))
            continue;
        sv_catpvn(rows, (const char *)&d, sizeof d);
        sv_catpvn(rowleaf, (const char *)&leaf[i], sizeof leaf[i]);
    }
    nr = SvCUR(rows) / sizeof(int64_t);
    for (i = 0; i < nr; i++) {
        const int64_t *d = (const int64_t *)SvPVX(rows) + i;
        const tkb_rule *lf = ((const tkb_rule *const *)SvPVX(rowleaf))[i];
        if (!tkb_rule_moves(lf, *d, weekend))
            sv_catpvn(taken, (const char *)d, sizeof *d);
    }
    for (i = 0; i < nr; i++) {
        int64_t d = ((const int64_t *)SvPVX(rows))[i];
        const tkb_rule *lf = ((const tkb_rule *const *)SvPVX(rowleaf))[i];
        if (tkb_rule_moves(lf, d, weekend)) {
            int64_t to;
            if (!tkb_rule_move(aTHX_ lf, d, (const int64_t *)SvPVX(taken), SvCUR(taken) / sizeof(int64_t), weekend, &to))
                continue;
            d = to;
            sv_catpvn(taken, (const char *)&d, sizeof d);
        }
        sv_catpvn(days_out, (const char *)&d, sizeof d);
        sv_catpvn(leaves_out, (const char *)&lf, sizeof lf);
    }
}

/* A year's pairs as an AV the memo keeps, made once. */
static AV *tkb_rule_pairs(pTHX_ tkb_rule *r, int64_t year);

static int64_t
tkb_rule_year_of(int64_t day)
{
    int64_t y;
    unsigned m, d;
    tkb_civil_from_days(day, &y, &m, &d);
    return y;
}

/* A year's holidays, from the memo or computed into it. */
static const tkb_rule_year *
tkb_rule_holidays_of(pTHX_ tkb_rule *r, int64_t year)
{
    SV *days = sv_2mortal(newSVpvs("")), *leaves = sv_2mortal(newSVpvs(""));
    size_t i, j, n, lo = 0, hi = r->n_memo;
    int64_t k;
    tkb_rule_year *slot;
    const int64_t *dv;
    const tkb_rule *const *lv;
    while (lo < hi) {
        size_t mid = lo + (hi - lo) / 2;
        if (r->memo[mid].year < year) lo = mid + 1; else hi = mid;
    }
    if (lo < r->n_memo && r->memo[lo].year == year)
        return &r->memo[lo];

    tkb_rule_compute(aTHX_ r, year, days, leaves);
    for (k = year - 1; k <= year + 1; k += 2)
        if (tkb_rule_any_observed(aTHX_ r, k))
            tkb_rule_compute(aTHX_ r, k, days, leaves);

    dv = (const int64_t *)SvPVX(days);
    lv = (const tkb_rule *const *)SvPVX(leaves);
    n = SvCUR(days) / sizeof(int64_t);

    lo = 0;
    hi = r->n_memo;
    while (lo < hi) {
        size_t mid = lo + (hi - lo) / 2;
        if (r->memo[mid].year < year) lo = mid + 1; else hi = mid;
    }
    if (lo < r->n_memo && r->memo[lo].year == year)
        return &r->memo[lo];
    Renew(r->memo, r->n_memo + 1, tkb_rule_year);
    Move(r->memo + lo, r->memo + lo + 1, r->n_memo - lo, tkb_rule_year);
    r->n_memo++;
    slot = &r->memo[lo];
    slot->year = year;
    slot->n = 0;
    slot->pairs = NULL;
    Newx(slot->days, n ? n : 1, int64_t);
    Newx(slot->names, n ? n : 1, SV *);
    for (i = 0; i < n; i++) {
        if (tkb_rule_year_of(dv[i]) != year)
            continue;
        j = slot->n;
        while (j > 0 && slot->days[j - 1] > dv[i]) {
            slot->days[j] = slot->days[j - 1];
            slot->names[j] = slot->names[j - 1];
            j--;
        }
        slot->days[j] = dv[i];
        slot->names[j] = lv[i]->name ? SvREFCNT_inc_simple_NN(lv[i]->name) : NULL;
        slot->n++;
    }
    return slot;
}

#endif

#ifndef TKB_RULE_COUNTRY_H
#define TKB_RULE_COUNTRY_H

static SV *
tkb_rule_leaf(pTHX_ HV *stash, int kind, int a, int b, int c, const char *name, int observed, int from)
{
    tkb_rule *r = tkb_rule_new(aTHX_ kind);
    switch (kind) {
    case TKB_RULE_FIXED:  r->month = a; r->day = b; break;
    case TKB_RULE_NTH:    r->month = a; r->dow = b; r->n = c; break;
    case TKB_RULE_EASTER: r->offset = a; break;
    }
    r->name = newSVpv(name, 0);
    r->observed = observed;
    if (from) { r->has_from = 1; r->from = from; }
    return tkb_rule_wrap(aTHX_ r, stash);
}

static SV *
tkb_rule_country(pTHX_ int which, HV *stash)
{
    tkb_rule *set = tkb_rule_new(aTHX_ TKB_RULE_SET);
    SV *m[11];
    int n = 0, i;
    const int U = TKB_OBS_UNSET, X = TKB_OBS_NEXT, N = TKB_OBS_NEAREST;
    if (which == 0) {
        m[n++] = tkb_rule_leaf(aTHX_ stash, TKB_RULE_FIXED, 1, 1, 0, "New Year's Day", X, 0);
        m[n++] = tkb_rule_leaf(aTHX_ stash, TKB_RULE_EASTER, -2, 0, 0, "Good Friday", U, 0);
        m[n++] = tkb_rule_leaf(aTHX_ stash, TKB_RULE_EASTER, 1, 0, 0, "Easter Monday", U, 0);
        m[n++] = tkb_rule_leaf(aTHX_ stash, TKB_RULE_NTH, 5, 1, 1, "Early May bank holiday", U, 0);
        m[n++] = tkb_rule_leaf(aTHX_ stash, TKB_RULE_NTH, 5, 1, -1, "Spring bank holiday", U, 0);
        m[n++] = tkb_rule_leaf(aTHX_ stash, TKB_RULE_NTH, 8, 1, -1, "Summer bank holiday", U, 0);
        m[n++] = tkb_rule_leaf(aTHX_ stash, TKB_RULE_FIXED, 12, 25, 0, "Christmas Day", X, 0);
        m[n++] = tkb_rule_leaf(aTHX_ stash, TKB_RULE_FIXED, 12, 26, 0, "Boxing Day", X, 0);
        set->name = newSVpvs("England and Wales");
        set->has_from = 1; set->from = 2024;
    }
    else if (which == 1) {
        m[n++] = tkb_rule_leaf(aTHX_ stash, TKB_RULE_FIXED, 1, 1, 0, "New Year's Day", N, 0);
        m[n++] = tkb_rule_leaf(aTHX_ stash, TKB_RULE_NTH, 1, 1, 3, "Birthday of Martin Luther King, Jr.", U, 1986);
        m[n++] = tkb_rule_leaf(aTHX_ stash, TKB_RULE_NTH, 2, 1, 3, "Washington's Birthday", U, 0);
        m[n++] = tkb_rule_leaf(aTHX_ stash, TKB_RULE_NTH, 5, 1, -1, "Memorial Day", U, 0);
        m[n++] = tkb_rule_leaf(aTHX_ stash, TKB_RULE_FIXED, 6, 19, 0, "Juneteenth National Independence Day", N, 2021);
        m[n++] = tkb_rule_leaf(aTHX_ stash, TKB_RULE_FIXED, 7, 4, 0, "Independence Day", N, 0);
        m[n++] = tkb_rule_leaf(aTHX_ stash, TKB_RULE_NTH, 9, 1, 1, "Labor Day", U, 0);
        m[n++] = tkb_rule_leaf(aTHX_ stash, TKB_RULE_NTH, 10, 1, 2, "Columbus Day", U, 0);
        m[n++] = tkb_rule_leaf(aTHX_ stash, TKB_RULE_FIXED, 11, 11, 0, "Veterans Day", N, 0);
        m[n++] = tkb_rule_leaf(aTHX_ stash, TKB_RULE_NTH, 11, 4, 4, "Thanksgiving Day", U, 0);
        m[n++] = tkb_rule_leaf(aTHX_ stash, TKB_RULE_FIXED, 12, 25, 0, "Christmas Day", N, 0);
        set->name = newSVpvs("United States federal");
        set->has_from = 1; set->from = 1971;
    }
    else {
        m[n++] = tkb_rule_leaf(aTHX_ stash, TKB_RULE_FIXED, 1, 1, 0, "New Year's Day", U, 0);
        m[n++] = tkb_rule_leaf(aTHX_ stash, TKB_RULE_EASTER, -2, 0, 0, "Good Friday", U, 0);
        m[n++] = tkb_rule_leaf(aTHX_ stash, TKB_RULE_EASTER, 1, 0, 0, "Easter Monday", U, 0);
        m[n++] = tkb_rule_leaf(aTHX_ stash, TKB_RULE_FIXED, 5, 1, 0, "Labour Day", U, 0);
        m[n++] = tkb_rule_leaf(aTHX_ stash, TKB_RULE_FIXED, 12, 25, 0, "Christmas Day", U, 0);
        m[n++] = tkb_rule_leaf(aTHX_ stash, TKB_RULE_FIXED, 12, 26, 0, "Christmas Holiday", U, 0);
        set->name = newSVpvs("TARGET2");
        set->has_from = 1; set->from = 2002;
    }
    Newx(set->members, n, SV *);
    for (i = 0; i < n; i++)
        set->members[i] = m[i];
    set->n_members = (size_t)n;
    return tkb_rule_wrap(aTHX_ set, stash);
}

#endif

#ifndef TKB_RULE_PAIRS_H
#define TKB_RULE_PAIRS_H

static AV *
tkb_rule_pairs(pTHX_ tkb_rule *r, int64_t year)
{
    tkb_rule_year *slot = (tkb_rule_year *)tkb_rule_holidays_of(aTHX_ r, year);
    AV *pairs;
    size_t i;
    if (slot->pairs)
        return slot->pairs;
    pairs = newAV();
    sv_2mortal((SV *)pairs);
    for (i = 0; i < slot->n; i++) {
        AV *pair = newAV();
        av_push(pair, newSVsv(tkb_rule_date(aTHX_ slot->days[i])));
        av_push(pair, slot->names[i] ? newSVsv(slot->names[i]) : newSV(0));
        av_push(pairs, newRV_noinc((SV *)pair));
    }
    slot = (tkb_rule_year *)tkb_rule_holidays_of(aTHX_ r, year);
    if (!slot->pairs)
        slot->pairs = (AV *)SvREFCNT_inc_simple_NN((SV *)pairs);
    return slot->pairs;
}

#endif
