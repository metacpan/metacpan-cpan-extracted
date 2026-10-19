#ifndef TKB_DAYS_H
#define TKB_DAYS_H

/* Business-day arithmetic over a schedule. Everything rests on one
 * count, the business days in a half-open span [a, b): whole weeks times
 * the business days a week, the remainder from a table of the weekdays,
 * less the holidays on weekdays in the span, plus the worked weekend days
 * in it, each a binary search. The nth business day after a day is then
 * the smallest day the count reaches n at, found by binary search as
 * well, since the count rises by one exactly at a business day. */

static const char *const tkb_month_names[] = {
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
};

#define TKB_ROLL_FOLLOWING          0
#define TKB_ROLL_PRECEDING          1
#define TKB_ROLL_MODIFIED_FOLLOWING 2
#define TKB_ROLL_MODIFIED_PRECEDING 3
#define TKB_ROLL_NEAREST            4
#define TKB_ROLL_NONE               5

static const char *const tkb_roll_names[] = {
    "following", "preceding", "modified_following", "modified_preceding", "nearest", "none", NULL
};

#define TKB_WALK_LIMIT 366
#define TKB_LIST_LIMIT 10000000

static int
tkb_roll_of_sv(pTHX_ SV *sv, const char *what)
{
    STRLEN len;
    const char *p;
    int i;
    if (!sv || !SvOK(sv) || SvROK(sv))
        croak("%s: the convention is following, preceding, modified_following, modified_preceding, nearest or none", what);
    p = SvPV(sv, len);
    for (i = 0; tkb_roll_names[i]; i++)
        if (strlen(tkb_roll_names[i]) == len && memEQ(tkb_roll_names[i], p, len))
            return i;
    croak("%s: the convention is following, preceding, modified_following, modified_preceding, nearest or none, not '%s'", what, p);
    return 0;
}

static int
tkb_is_business(const tkb_schedule *s, int64_t day)
{
    return !tkb_is_closed(s, day);
}

/* The business weekdays in [a, b), a <= b, by the week alone. */
static int64_t
tkb_weekdays_in(const tkb_schedule *s, int64_t a, int64_t b)
{
    int64_t n = b - a, q = n / 7, r = n % 7;
    unsigned w = tkb_dow_from_days(a) - 1;
    int64_t rem = (w + r <= 7) ? (int64_t)s->cum[w + r] - s->cum[w]
                               : (int64_t)(s->cum[7] - s->cum[w]) + s->cum[w + r - 7];
    return q * s->per_week + rem;
}

/* The business days in [a, b), in either order: negative when b is first. */
static int64_t
tkb_between(pTHX_ tkb_schedule *s, int64_t a, int64_t b, const char *what)
{
    int64_t n;
    if (a == b)
        return 0;
    if (a > b)
        return -tkb_between(aTHX_ s, b, a, what);
    tkb_ensure_span(aTHX_ s, a, b - 1, what);
    n = tkb_weekdays_in(s, a, b);
    n -= (int64_t)(tkb_lower_bound(s->closed, s->n_closed, b) - tkb_lower_bound(s->closed, s->n_closed, a));
    n += (int64_t)(tkb_lower_bound(s->open, s->n_open, b) - tkb_lower_bound(s->open, s->n_open, a));
    return n;
}

static void
tkb_no_business_day(pTHX_ int64_t day, const char *what)
{
    SV *str = sv_2mortal(tkb_day_string(aTHX_ day));
    croak("%s: no business day within a year of %" SVf, what, SVfARG(str));
}

/* The first business day strictly after (dir 1) or before (dir -1). */
static int64_t
tkb_next(pTHX_ tkb_schedule *s, int64_t day, int dir, const char *what)
{
    int64_t d = day;
    int i;
    tkb_ensure_span(aTHX_ s, day, day + dir * TKB_WALK_LIMIT, what);
    for (i = 0; i < TKB_WALK_LIMIT; i++) {
        d += dir;
        if (tkb_is_business(s, d))
            return d;
    }
    tkb_no_business_day(aTHX_ day, what);
    return 0;
}

static int
tkb_same_month(int64_t a, int64_t b)
{
    int64_t ya, yb;
    unsigned ma, da, mb, db;
    tkb_civil_from_days(a, &ya, &ma, &da);
    tkb_civil_from_days(b, &yb, &mb, &db);
    return ya == yb && ma == mb;
}

/* The day itself when it is a business day, else the one the convention
 * names. */
static int64_t
tkb_roll(pTHX_ tkb_schedule *s, int64_t day, int conv, const char *what)
{
    int64_t f, p;
    tkb_ensure(aTHX_ s, day, what);
    if (tkb_is_business(s, day))
        return day;
    switch (conv) {
    case TKB_ROLL_FOLLOWING:
        return tkb_next(aTHX_ s, day, 1, what);
    case TKB_ROLL_PRECEDING:
        return tkb_next(aTHX_ s, day, -1, what);
    case TKB_ROLL_MODIFIED_FOLLOWING:
        f = tkb_next(aTHX_ s, day, 1, what);
        return tkb_same_month(f, day) ? f : tkb_next(aTHX_ s, day, -1, what);
    case TKB_ROLL_MODIFIED_PRECEDING:
        p = tkb_next(aTHX_ s, day, -1, what);
        return tkb_same_month(p, day) ? p : tkb_next(aTHX_ s, day, 1, what);
    case TKB_ROLL_NEAREST:
        f = tkb_next(aTHX_ s, day, 1, what);
        p = tkb_next(aTHX_ s, day, -1, what);
        return (f - day) <= (day - p) ? f : p;
    default: {
        SV *str = sv_2mortal(tkb_day_string(aTHX_ day));
        croak("%s: %" SVf " is not a business day", what, SVfARG(str));
        return 0;
    }
    }
}

static void
tkb_not_enough(pTHX_ int64_t start, int64_t n, const char *what)
{
    SV *str = sv_2mortal(tkb_day_string(aTHX_ start));
    croak("%s: there are not %" IVdf " business days within %" IVdf " years of %" SVf,
          what, (IV)n, (IV)(n + 1), SVfARG(str));
}

/* The nth business day strictly after start, n >= 1: the smallest day
 * the count in (start, day] reaches n at. The upper bound is found by
 * doubling from the week's estimate, since holidays can only push it out. */
static int64_t
tkb_nth_after(pTHX_ tkb_schedule *s, int64_t start, int64_t n, const char *what)
{
    int64_t lo = start + 1, hi, span;
    if (s->per_week == 0 && s->n_open == 0)
        tkb_no_business_day(aTHX_ start, what);
    span = 7 * (n / (s->per_week ? s->per_week : 1) + 2);
    hi = start + span;
    while (tkb_between(aTHX_ s, start + 1, hi + 1, what) < n) {
        if (hi - start > (int64_t)TKB_WALK_LIMIT * (n + 1))
            tkb_not_enough(aTHX_ start, n, what);
        hi += hi - start;
    }
    while (lo < hi) {
        int64_t mid = lo + (hi - lo) / 2;
        if (tkb_between(aTHX_ s, start + 1, mid + 1, what) >= n) hi = mid; else lo = mid + 1;
    }
    return lo;
}

/* The nth business day strictly before start: the largest day the count
 * in [day, start) reaches n at. */
static int64_t
tkb_nth_before(pTHX_ tkb_schedule *s, int64_t start, int64_t n, const char *what)
{
    int64_t hi = start - 1, lo, span;
    if (s->per_week == 0 && s->n_open == 0)
        tkb_no_business_day(aTHX_ start, what);
    span = 7 * (n / (s->per_week ? s->per_week : 1) + 2);
    lo = start - span;
    while (tkb_between(aTHX_ s, lo, start, what) < n) {
        if (start - lo > (int64_t)TKB_WALK_LIMIT * (n + 1))
            tkb_not_enough(aTHX_ start, n, what);
        lo -= start - lo;
    }
    while (lo < hi) {
        int64_t mid = lo + (hi - lo + 1) / 2;
        if (tkb_between(aTHX_ s, mid, start, what) >= n) lo = mid; else hi = mid - 1;
    }
    return lo;
}

/* n business days on from a day: a closed day is rolled first, forward
 * for a positive n and back for a negative one unless a convention is
 * given, and n of zero is that roll. */
static int64_t
tkb_plus(pTHX_ tkb_schedule *s, int64_t day, int64_t n, int conv, const char *what)
{
    int64_t start;
    if (conv < 0)
        conv = n < 0 ? TKB_ROLL_PRECEDING : TKB_ROLL_FOLLOWING;
    start = tkb_roll(aTHX_ s, day, conv, what);
    if (n == 0)
        return start;
    return n > 0 ? tkb_nth_after(aTHX_ s, start, n, what) : tkb_nth_before(aTHX_ s, start, -n, what);
}

/* The first day of a day's month and of the next. */
static void
tkb_month_of(int64_t day, int64_t *first, int64_t *next, int64_t *year, unsigned *month)
{
    unsigned d;
    tkb_civil_from_days(day, year, month, &d);
    *first = tkb_days_from_civil(*year, *month, 1);
    *next = *month == 12 ? tkb_days_from_civil(*year + 1, 1, 1) : tkb_days_from_civil(*year, *month + 1, 1);
}

/* The nth business day of a month, -1 for the last. */
static int64_t
tkb_nth_in_month(pTHX_ tkb_schedule *s, int64_t day, int64_t n, const char *what)
{
    int64_t first, next, year, count;
    unsigned month;
    tkb_month_of(day, &first, &next, &year, &month);
    count = tkb_between(aTHX_ s, first, next, what);
    if (n == 0 || n > count || -n > count)
        croak("%s: %s %" IVdf " has %" IVdf " business days, not %" IVdf,
              what, tkb_month_names[month - 1], (IV)year, (IV)count, (IV)(n < 0 ? -n : n));
    return n > 0 ? tkb_nth_after(aTHX_ s, first - 1, n, what) : tkb_nth_before(aTHX_ s, next, -n, what);
}

#endif
