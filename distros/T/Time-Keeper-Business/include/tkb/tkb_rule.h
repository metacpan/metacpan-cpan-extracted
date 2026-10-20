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
#define TKB_RULE_ON_AFTER  5
#define TKB_RULE_ON_BEFORE 6
#define TKB_RULE_SANDWICH  7

#define TKB_OBS_NONE    0
#define TKB_OBS_NEXT    1
#define TKB_OBS_NEAREST 2
#define TKB_OBS_MONDAY  3
#define TKB_OBS_CODE    4
#define TKB_OBS_PREVIOUS 5
#define TKB_OBS_IF_SUNDAY 6
#define TKB_OBS_UNSET  -1

static const char *const tkb_rule_kinds[] = { "fixed", "nth", "easter", "relative", "set", "weekday_on_or_after", "weekday_on_or_before", "sandwiched" };

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
    int      calendar;           /* the core's id; 0 the Gregorian */
    int      month_number;       /* in another calendar: the number in the month code */
    int      month_leap;         /* the code ends in L */
    int      leap_common;        /* a leap month a year lacks falls back to its common month */
    SV      *child;              /* relative: the base rule, an RV */
    SV     **members;            /* set: RVs */
    size_t   n_members;
    SV      *name;
    int      observed;           /* TKB_OBS_UNSET when never given */
    int      observed_keep;      /* the date stays a holiday and the moved day is added */
    SV      *observed_code;
    int      has_weekend;
    uint8_t  weekend;
    int      has_from, has_to;
    int64_t  from, to;
    SV      *only_if;
    int64_t *except;             /* years the rule does not hold */
    size_t   n_except;
    int64_t *also;               /* days it adds, whatever its years say */
    size_t   n_also;
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
    Safefree(r->except);
    Safefree(r->also);
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
    if (r->n_except) { Newx(c->except, r->n_except, int64_t); Copy(r->except, c->except, r->n_except, int64_t); } else c->except = NULL;
    if (r->n_also) { Newx(c->also, r->n_also, int64_t); Copy(r->also, c->also, r->n_also, int64_t); } else c->also = NULL;
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
    if (r->n_except) { Newx(c->except, r->n_except, int64_t); Copy(r->except, c->except, r->n_except, int64_t); } else c->except = NULL;
    if (r->n_also) { Newx(c->also, r->n_also, int64_t); Copy(r->also, c->also, r->n_also, int64_t); } else c->also = NULL;
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

static struct tkb_rule *
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
    static const char *const msg = "%s: the form is none, next_business_day, nearest_business_day, next_monday, previous_business_day, next_business_day_if_sunday or a code ref";
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
        else if (strEQ(p, "previous_business_day")) r->observed = TKB_OBS_PREVIOUS;
        else if (strEQ(p, "next_business_day_if_sunday")) r->observed = TKB_OBS_IF_SUNDAY;
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


/* ---- other calendars ---------------------------------------------------- */

static int64_t
tkb_floor_div64(int64_t a, int64_t b)
{
    int64_t q = a / b;
    if ((a % b) && ((a < 0) != (b < 0)))
        q--;
    return q;
}

/* An instant at noon UTC on a day, and back. */
static void
tkb_noon_of(int64_t day, time_keeper_instant *t)
{
    t->sec = day * 86400 + 43200;
    t->nsec = 0;
}

static int64_t
tkb_day_of_instant(const time_keeper_instant *t)
{
    return tkb_floor_div64(t->sec, 86400);
}

static int
tkb_cal_read(pTHX_ int calendar, int64_t day, time_keeper_calfields *f)
{
    time_keeper_instant t;
    time_keeper_zone utc;
    utc.kind = TIME_KEEPER_ZONE_UTC;
    utc.value = 0;
    tkb_noon_of(day, &t);
    return TKB(cal_fields)(aTHX_ &t, &utc, calendar, f) == TIME_KEEPER_OK;
}

/* The day a calendar's year, ordinal month and day fall on. */
static int
tkb_cal_day(pTHX_ int calendar, int64_t year, int month, int day, int64_t *out)
{
    time_keeper_calfields f;
    time_keeper_instant t;
    time_keeper_zone utc;
    Zero(&f, 1, time_keeper_calfields);
    f.calendar = calendar;
    f.year = year;
    f.month = month;
    f.day = day;
    f.hour = 12;
    utc.kind = TIME_KEEPER_ZONE_UTC;
    utc.value = 0;
    if (TKB(cal_from_fields)(aTHX_ &f, &utc, TIME_KEEPER_GAP_FORWARD, TIME_KEEPER_OVERLAP_EARLIER, &t) != TIME_KEEPER_OK)
        return 0;
    *out = tkb_day_of_instant(&t);
    return 1;
}

/* Where a month code falls in a calendar year: the first day of the month
 * and its length; 0 when the year has no such month or is past the
 * calendar's table. */
static int
tkb_cal_month(pTHX_ int calendar, int64_t year, int number, int leap, int64_t *first, int *dim)
{
    time_keeper_calfields f;
    int64_t d;
    int m, miy;
    if (!tkb_cal_day(aTHX_ calendar, year, 1, 1, &d) || !tkb_cal_read(aTHX_ calendar, d, &f))
        return 0;
    miy = f.months_in_year;
    for (m = 1; m <= miy; m++) {
        if (!tkb_cal_day(aTHX_ calendar, year, m, 1, &d) || !tkb_cal_read(aTHX_ calendar, d, &f))
            return 0;
        if (f.month_number == number && (f.leap_month ? 1 : 0) == leap) {
            *first = d;
            *dim = f.days_in_month;
            return 1;
        }
    }
    return 0;
}

static int
tkb_cal_is(pTHX_ int calendar, const char *id)
{
    const char *name;
    return TKB(calendar_id)(calendar, &name) == TIME_KEEPER_OK && strEQ(name, id);
}

/* The days in a Gregorian year a calendar rule falls on: every calendar
 * year that touches it is tried, so a lunar holiday can come twice. */
static void
tkb_cal_bases(pTHX_ const tkb_rule *r, int64_t year, SV *out)
{
    time_keeper_calfields f;
    int64_t jan1 = tkb_days_from_civil(year, 1, 1), dec31 = tkb_days_from_civil(year, 12, 31);
    int64_t lo, hi, cy;
    int have_lo = tkb_cal_read(aTHX_ r->calendar, jan1, &f);
    lo = f.year;
    if (!tkb_cal_read(aTHX_ r->calendar, dec31, &f)) {
        if (!have_lo)
            return;
        hi = lo;
    }
    else {
        hi = f.year;
        if (!have_lo)
            lo = hi;
    }
    for (cy = lo; cy <= hi; cy++) {
        int64_t first, d;
        int dim;
        if (!tkb_cal_month(aTHX_ r->calendar, cy, r->month_number, r->month_leap, &first, &dim)) {
            int twin = tkb_cal_is(aTHX_ r->calendar, "hebrew") ? 6 : r->month_number;
            if (!(r->month_leap && r->leap_common && tkb_cal_month(aTHX_ r->calendar, cy, twin, 0, &first, &dim)))
                continue;
        }
        if (r->kind == TKB_RULE_FIXED) {
            if (r->day > dim)
                continue;
            d = first + r->day - 1;
        }
        else if (r->n == -1) {
            int ldow = (int)tkb_dow_from_days(first + dim - 1);
            d = first + dim - 1 - ((ldow - r->dow + 7) % 7);
        }
        else {
            int fdow = (int)tkb_dow_from_days(first);
            int64_t off = (r->dow - fdow + 7) % 7 + 7 * (int64_t)(r->n - 1);
            if (off >= dim)
                continue;
            d = first + off;
        }
        if (d >= jan1 && d <= dec31)
            sv_catpvn(out, (const char *)&d, sizeof d);
    }
}

/* A calendar and a month code from a constructor's keys. */
static void
tkb_rule_set_calendar(pTHX_ tkb_rule *r, SV *calendar, SV *code, SV *leap, const char *what)
{
    const char *name = "gregory";
    if (calendar && SvOK(calendar)) {
        STRLEN len;
        const char *c = SvPV(calendar, len);
        int id = SvROK(calendar) ? -1 : TKB(calendar_find)(c, len);
        if (id < 0)
            croak("%s: unknown calendar '%s'", what, c);
        r->calendar = id;
        TKB(calendar_id)(id, &name);
    }
    if (code && SvOK(code)) {
        STRLEN len;
        const char *p = SvPV(code, len);
        unsigned num;
        int is_leap = len == 4 && p[3] == 'L';
        if (SvROK(code) || !(len == 3 || is_leap) || p[0] != 'M' || !tkb_two_digits(p + 1, &num) || num < 1 || num > 13)
            croak("%s: month_code is M01 to M13, with L after it for a leap month: not '%s'", what, p);
        if (num == 13 && !(strEQ(name, "coptic") || strEQ(name, "ethiopic") || strEQ(name, "ethioaa")))
            croak("%s: the %s calendar has no month M13", what, name);
        if (is_leap && !(strEQ(name, "chinese") || strEQ(name, "dangi") || (strEQ(name, "hebrew") && num == 5)))
            croak("%s: the %s calendar has no leap month %s", what, name, p);
        r->month_number = (int)num;
        r->month_leap = is_leap;
    }
    if (leap && SvOK(leap)) {
        const char *l = SvPV_nolen(leap);
        if (strEQ(l, "common")) r->leap_common = 1;
        else if (strEQ(l, "skip")) r->leap_common = 0;
        else croak("%s: leap_month is 'skip' or 'common', not '%s'", what, l);
    }
}

/* A rule's own date in a year, before any observed move; 0 when it has
 * none that year. */
static void tkb_rule_bases(pTHX_ const tkb_rule *r, int64_t year, SV *out);

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
    case TKB_RULE_RELATIVE:
        croak("Time::Keeper::Business::Rule: a relative rule has its days from tkb_rule_bases");
    default:
        croak("Time::Keeper::Business::Rule: a set has no date of its own");
    }
    return 0;
}


/* Every day a rule's own date falls on in a year, before any observed move:
 * one for a Gregorian rule, none or more for one in another calendar. */
static void
tkb_rule_bases(pTHX_ const tkb_rule *r, int64_t year, SV *out)
{
    int64_t d;
    if (r->kind == TKB_RULE_SANDWICH)
        return;
    if (r->kind == TKB_RULE_RELATIVE || r->kind == TKB_RULE_ON_AFTER || r->kind == TKB_RULE_ON_BEFORE) {
        SV *child = sv_2mortal(newSVpvs(""));
        const int64_t *cd;
        size_t i, n;
        tkb_rule_bases(aTHX_ tkb_rule_of(aTHX_ r->child, "Time::Keeper::Business::Rule"), year, child);
        cd = (const int64_t *)SvPVX(child);
        n = SvCUR(child) / sizeof(int64_t);
        for (i = 0; i < n; i++) {
            int64_t start = cd[i] + r->days;
            int w = (int)tkb_dow_from_days(start);
            if (r->kind == TKB_RULE_ON_AFTER)
                d = start + (r->dow - w + 7) % 7 + 7 * (int64_t)(r->n - 1);
            else if (r->kind == TKB_RULE_ON_BEFORE)
                d = start - (w - r->dow + 7) % 7 - 7 * (int64_t)(r->n - 1);
            else
                d = start;
            sv_catpvn(out, (const char *)&d, sizeof d);
        }
        return;
    }
    if (r->calendar && (r->kind == TKB_RULE_FIXED || r->kind == TKB_RULE_NTH)) {
        tkb_cal_bases(aTHX_ r, year, out);
        return;
    }
    if (tkb_rule_base(aTHX_ r, year, &d))
        sv_catpvn(out, (const char *)&d, sizeof d);
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
    size_t i;
    for (i = 0; i < r->n_except; i++)
        if (r->except[i] == year)
            return 0;
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
tkb_rule_walk(pTHX_ const tkb_rule *r, int64_t year, SV *buf, SV **also, int depth)
{
    size_t i;
    if (depth > 64)
        croak("Time::Keeper::Business::Rule: sets nest too deeply");
    if (also && r->n_also) {
        if (!*also)
            *also = sv_2mortal(newSVpvs(""));
        sv_catpvn(*also, (const char *)&r, sizeof r);
    }
    if (!tkb_rule_applies(aTHX_ r, year))
        return;
    if (r->kind != TKB_RULE_SET) {
        sv_catpvn(buf, (const char *)&r, sizeof r);
        return;
    }
    for (i = 0; i < r->n_members; i++)
        tkb_rule_walk(aTHX_ tkb_rule_of(aTHX_ r->members[i], "Time::Keeper::Business::Rule"), year, buf, also, depth + 1);
}

static void
tkb_rule_leaves(pTHX_ const tkb_rule *r, int64_t year, SV *buf, int depth)
{
    tkb_rule_walk(aTHX_ r, year, buf, NULL, depth);
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
    if (leaf->observed == TKB_OBS_IF_SUNDAY)
        return tkb_dow_from_days(day) == 7;
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
    return tkb_date_new(aTHX_ day, -1, NULL, NULL);
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
        int lid;
        if (!SvOK(r))
            return 0;
        if (!sv_isobject(r) || !sv_derived_from(r, "Time::Keeper::Date"))
            croak("Time::Keeper::Business::Rule: an observed code ref must give a Time::Keeper::Date or undef");
        if (!tkb_date_day(aTHX_ r, &d, &lid))
            croak("Time::Keeper::Business::Rule: the date an observed code ref gave could not be read");
        *out = d;
        return 1;
    }
    case TKB_OBS_PREVIOUS: {
        int64_t d = day;
        do { d--; } while ((weekend & TKB_WEEKEND_BIT(tkb_dow_from_days(d))) || tkb_rule_taken(taken, n_taken, d));
        *out = d;
        return 1;
    }
    case TKB_OBS_IF_SUNDAY:
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
static int64_t tkb_rule_year_of(int64_t day);

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
    SV *abuf = NULL;
    size_t nbase;
    tkb_rule_walk(aTHX_ top, year, lbuf, &abuf, 0);
    leaf = (const tkb_rule *const *)SvPVX(lbuf);
    n = SvCUR(lbuf) / sizeof(tkb_rule *);
    SV *b = sv_2mortal(newSVpvs(""));
    for (i = 0; i < n; i++) {
        size_t j, nb;
        SvCUR_set(b, 0);
        tkb_rule_bases(aTHX_ leaf[i], year, b);
        nb = SvCUR(b) / sizeof(int64_t);
        for (j = 0; j < nb; j++) {
            sv_catpvn(rows, SvPVX(b) + j * sizeof(int64_t), sizeof(int64_t));
            sv_catpvn(rowleaf, (const char *)&leaf[i], sizeof leaf[i]);
        }
    }
    nbase = SvCUR(rows) / sizeof(int64_t);
    if (abuf) {
        const tkb_rule *const *an = (const tkb_rule *const *)SvPVX(abuf);
        size_t a, na = SvCUR(abuf) / sizeof(tkb_rule *);
        for (a = 0; a < na; a++) {
            size_t k;
            for (k = 0; k < an[a]->n_also; k++) {
                if (tkb_rule_year_of(an[a]->also[k]) != year)
                    continue;
                sv_catpvn(rows, (const char *)&an[a]->also[k], sizeof(int64_t));
                sv_catpvn(rowleaf, (const char *)&an[a], sizeof an[a]);
            }
        }
    }
    nr = SvCUR(rows) / sizeof(int64_t);
    for (i = 0; i < nr; i++) {
        const int64_t *d = (const int64_t *)SvPVX(rows) + i;
        const tkb_rule *lf = ((const tkb_rule *const *)SvPVX(rowleaf))[i];
        if (i >= nbase || lf->observed_keep || !tkb_rule_moves(lf, *d, weekend))
            sv_catpvn(taken, (const char *)d, sizeof *d);
    }
    for (i = 0; i < nr; i++) {
        int64_t d = ((const int64_t *)SvPVX(rows))[i];
        const tkb_rule *lf = ((const tkb_rule *const *)SvPVX(rowleaf))[i];
        if (i < nbase && tkb_rule_moves(lf, d, weekend)) {
            int64_t to;
            if (lf->observed_keep) {
                sv_catpvn(days_out, (const char *)&d, sizeof d);
                sv_catpvn(leaves_out, (const char *)&lf, sizeof lf);
            }
            if (!tkb_rule_move(aTHX_ lf, d, (const int64_t *)SvPVX(taken), SvCUR(taken) / sizeof(int64_t), weekend, &to))
                continue;
            d = to;
            sv_catpvn(taken, (const char *)&d, sizeof d);
        }
        sv_catpvn(days_out, (const char *)&d, sizeof d);
        sv_catpvn(leaves_out, (const char *)&lf, sizeof lf);
    }
    for (i = 0; i < n; i++) {
        const int64_t *rd = (const int64_t *)SvPVX(rows);
        size_t j;
        if (leaf[i]->kind != TKB_RULE_SANDWICH)
            continue;
        for (j = 0; j < nr; j++) {
            int64_t c = rd[j] + 1;
            if (!tkb_rule_taken(rd, nr, c + 1) || tkb_rule_taken((const int64_t *)SvPVX(taken), SvCUR(taken) / sizeof(int64_t), c))
                continue;
            if (weekend & TKB_WEEKEND_BIT(tkb_dow_from_days(c)))
                continue;
            sv_catpvn(taken, (const char *)&c, sizeof c);
            sv_catpvn(days_out, (const char *)&c, sizeof c);
            sv_catpvn(leaves_out, (const char *)&leaf[i], sizeof leaf[i]);
        }
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

#ifndef TKB_RULE_SPEC_H
#define TKB_RULE_SPEC_H

/* A rule as data: a plain nested hash of what its constructors and
 * changes were given, keys absent when unset, so from_spec can give it to
 * them again and every check runs again. A code ref has no data form. */

static const char *const tkb_obs_names[] = {
    "none", "next_business_day", "nearest_business_day", "next_monday", "", "previous_business_day", "next_business_day_if_sunday"
};

static int
tkb_rule_has_code(pTHX_ const tkb_rule *r, int depth)
{
    size_t i;
    if (depth > 64)
        return 1;
    if (r->observed == TKB_OBS_CODE || r->only_if)
        return 1;
    if (r->child && tkb_rule_has_code(aTHX_ tkb_rule_of(aTHX_ r->child, "Time::Keeper::Business::Rule"), depth + 1))
        return 1;
    for (i = 0; i < r->n_members; i++)
        if (tkb_rule_has_code(aTHX_ tkb_rule_of(aTHX_ r->members[i], "Time::Keeper::Business::Rule"), depth + 1))
            return 1;
    return 0;
}

static int
tkb_rule_sv_has_code(pTHX_ SV *rule)
{
    return tkb_rule_has_code(aTHX_ tkb_rule_of(aTHX_ rule, "Time::Keeper::Business::Rule"), 0);
}

static void
tkb_hv_iv(pTHX_ HV *hv, const char *key, IV v)
{
    (void)hv_store(hv, key, (I32)strlen(key), newSViv(v), 0);
}

static HV *
tkb_rule_spec(pTHX_ const tkb_rule *r, const char *what, int depth)
{
    HV *hv = newHV();
    SV *guard = sv_2mortal(newRV_noinc((SV *)hv));
    size_t i;
    if (depth > 64)
        croak("%s: sets nest too deeply", what);
    if (r->observed == TKB_OBS_CODE || r->only_if)
        croak("%s: a rule with a code ref (observed or only_if) cannot be written as data", what);
    (void)hv_stores(hv, "kind", newSVpv(tkb_rule_kinds[r->kind], 0));
    if (r->calendar) {
        const char *id;
        if (TKB(calendar_id)(r->calendar, &id) == TIME_KEEPER_OK)
            (void)hv_stores(hv, "calendar", newSVpv(id, 0));
        (void)hv_stores(hv, "month_code", newSVpvf("M%02d%s", r->month_number, r->month_leap ? "L" : ""));
        if (r->leap_common)
            (void)hv_stores(hv, "leap_month", newSVpvs("common"));
    }
    switch (r->kind) {
    case TKB_RULE_FIXED:
        if (!r->calendar) tkb_hv_iv(aTHX_ hv, "month", r->month);
        tkb_hv_iv(aTHX_ hv, "day", r->day);
        break;
    case TKB_RULE_NTH:
        if (!r->calendar) tkb_hv_iv(aTHX_ hv, "month", r->month);
        tkb_hv_iv(aTHX_ hv, "day_of_week", r->dow);
        tkb_hv_iv(aTHX_ hv, "n", r->n);
        break;
    case TKB_RULE_EASTER:
        if (r->offset) tkb_hv_iv(aTHX_ hv, "offset", r->offset);
        if (r->orthodox) tkb_hv_iv(aTHX_ hv, "orthodox", 1);
        break;
    case TKB_RULE_ON_AFTER:
    case TKB_RULE_ON_BEFORE:
        tkb_hv_iv(aTHX_ hv, "day_of_week", r->dow);
        if (r->n != 1) tkb_hv_iv(aTHX_ hv, "n", r->n);
        /* fall through */
    case TKB_RULE_RELATIVE:
        if (r->days || r->kind == TKB_RULE_RELATIVE) tkb_hv_iv(aTHX_ hv, "days", r->days);
        (void)hv_stores(hv, "rule", newRV_noinc((SV *)tkb_rule_spec(aTHX_ tkb_rule_of(aTHX_ r->child, what), what, depth + 1)));
        break;
    case TKB_RULE_SET: {
        AV *m = newAV();
        for (i = 0; i < r->n_members; i++)
            av_push(m, newRV_noinc((SV *)tkb_rule_spec(aTHX_ tkb_rule_of(aTHX_ r->members[i], what), what, depth + 1)));
        (void)hv_stores(hv, "members", newRV_noinc((SV *)m));
        break;
    }
    default:
        break;
    }
    if (r->name)
        (void)hv_stores(hv, "name", newSVsv(r->name));
    if (r->observed != TKB_OBS_UNSET)
        (void)hv_stores(hv, "observed", newSVpv(tkb_obs_names[r->observed], 0));
    if (r->observed_keep)
        tkb_hv_iv(aTHX_ hv, "keep", 1);
    if (r->has_weekend) {
        AV *w = newAV();
        int d;
        for (d = 1; d <= 7; d++)
            if (r->weekend & TKB_WEEKEND_BIT(d))
                av_push(w, newSViv(d));
        (void)hv_stores(hv, "weekend", newRV_noinc((SV *)w));
    }
    if (r->has_from) (void)hv_stores(hv, "from", tkb_i64_sv(aTHX_ r->from));
    if (r->has_to)   (void)hv_stores(hv, "to", tkb_i64_sv(aTHX_ r->to));
    if (r->n_except) {
        AV *e = newAV();
        for (i = 0; i < r->n_except; i++)
            av_push(e, tkb_i64_sv(aTHX_ r->except[i]));
        (void)hv_stores(hv, "except", newRV_noinc((SV *)e));
    }
    if (r->n_also) {
        AV *a = newAV();
        for (i = 0; i < r->n_also; i++)
            av_push(a, tkb_day_string(aTHX_ r->also[i]));
        (void)hv_stores(hv, "also", newRV_noinc((SV *)a));
    }
    SvREFCNT_inc_simple_void_NN((SV *)hv);
    PERL_UNUSED_VAR(guard);
    return hv;
}

static SV *
tkb_rule_spec_sv(pTHX_ SV *rule, const char *what)
{
    return newRV_noinc((SV *)tkb_rule_spec(aTHX_ tkb_rule_of(aTHX_ rule, what), what, 0));
}

static SV *
tkb_rule_call_list(pTHX_ SV *invocant, const char *method, AV *args)
{
    dSP;
    SV *ret;
    SSize_t i, n = av_len(args) + 1;
    int count;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, n + 1);
    PUSHs(invocant);
    for (i = 0; i < n; i++)
        PUSHs(*av_fetch(args, i, 0));
    PUTBACK;
    count = call_method(method, G_SCALAR);
    SPAGAIN;
    ret = count ? POPs : &PL_sv_undef;
    SvREFCNT_inc_simple_void_NN(ret);
    PUTBACK;
    FREETMPS;
    LEAVE;
    return sv_2mortal(ret);
}

/* A rule from its data, through its constructors and changes; mortal. */
static SV *
tkb_rule_from_spec(pTHX_ SV *class, SV *spec, const char *what, int depth)
{
    HV *hv;
    SV **p, *rule;
    AV *args = (AV *)sv_2mortal((SV *)newAV());
    HE *he;
    const char *kind;
    int k, known = 0;
    if (depth > 64)
        croak("%s: sets nest too deeply", what);
    if (!spec || !SvROK(spec) || SvTYPE(SvRV(spec)) != SVt_PVHV || sv_isobject(spec))
        croak("%s: a rule's data is a hash", what);
    hv = (HV *)SvRV(spec);
    p = hv_fetchs(hv, "kind", 0);
    if (!p || !SvOK(*p))
        croak("%s: a rule's data needs its kind", what);
    kind = SvPV_nolen(*p);
    for (k = 0; k < (int)(sizeof tkb_rule_kinds / sizeof *tkb_rule_kinds); k++)
        if (strEQ(kind, tkb_rule_kinds[k]))
            known = 1;
    if (!known)
        croak("%s: a rule of kind '%s' needs a later release of Time::Keeper::Business", what, kind);
    if (strEQ(kind, "set")) {
        SV **m = hv_fetchs(hv, "members", 0);
        AV *mav;
        SSize_t i, n;
        if (!m || !SvROK(*m) || SvTYPE(SvRV(*m)) != SVt_PVAV)
            croak("%s: a set's data needs its members", what);
        mav = (AV *)SvRV(*m);
        n = av_len(mav) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(mav, i, 0);
            av_push(args, newSVsv(tkb_rule_from_spec(aTHX_ class, e ? *e : NULL, what, depth + 1)));
        }
    }
    hv_iterinit(hv);
    while ((he = hv_iternext(hv))) {
        STRLEN klen;
        const char *key = HePV(he, klen);
        SV *val = hv_iterval(hv, he);
        if (strEQ(key, "kind") || strEQ(key, "members") || strEQ(key, "observed") || strEQ(key, "keep")
            || strEQ(key, "except") || strEQ(key, "also"))
            continue;
        av_push(args, newSVpvn(key, klen));
        if (strEQ(key, "rule"))
            av_push(args, newSVsv(tkb_rule_from_spec(aTHX_ class, val, what, depth + 1)));
        else
            av_push(args, newSVsv(val));
    }
    rule = tkb_rule_call_list(aTHX_ class, kind, args);
    if ((p = hv_fetchs(hv, "observed", 0)) && SvOK(*p)) {
        AV *o = (AV *)sv_2mortal((SV *)newAV());
        SV **keep = hv_fetchs(hv, "keep", 0);
        av_push(o, newSVsv(*p));
        if (keep && SvTRUE(*keep)) {
            av_push(o, newSVpvs("keep"));
            av_push(o, newSViv(1));
        }
        rule = tkb_rule_call_list(aTHX_ rule, "observed", o);
    }
    if ((p = hv_fetchs(hv, "except", 0)) && SvOK(*p)) {
        AV *o = (AV *)sv_2mortal((SV *)newAV());
        av_push(o, newSVpvs("years"));
        av_push(o, newSVsv(*p));
        rule = tkb_rule_call_list(aTHX_ rule, "except", o);
    }
    if ((p = hv_fetchs(hv, "also", 0)) && SvOK(*p)) {
        AV *o = (AV *)sv_2mortal((SV *)newAV());
        av_push(o, newSVpvs("dates"));
        av_push(o, newSVsv(*p));
        rule = tkb_rule_call_list(aTHX_ rule, "also", o);
    }
    return rule;
}

#endif
