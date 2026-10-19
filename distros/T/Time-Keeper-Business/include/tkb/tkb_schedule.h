#ifndef TKB_SCHEDULE_H
#define TKB_SCHEDULE_H

/* A schedule: which days are closed, and why. A weekend day is closed
 * unless it is listed as worked; a weekday is closed when it is a holiday.
 * The three arrays are sorted day numbers, so every question is a binary
 * search, and `closed` holds only the holidays that fall on working
 * weekdays, so counting business days over a span (Phase 05) is one
 * formula over whole weeks with two corrections.
 *
 * Holidays come from literal dates, known at construction, and from
 * sources asked year by year: yearly dates, code refs, objects with a
 * holidays method, and the two parts of a join. A schedule with any of
 * those is lazy: its arrays cover the years materialised so far, and a
 * question about a day outside them widens the span first.
 *
 * The struct lives behind a blessed scalar as ext magic; the magic's
 * object is the spec hash the schedule was built from, so a copy with one
 * key changed, a freeze and a thread all start from the same place. */

#define TKB_NAMED_LAZY 1    /* came from a yearly date or a generator, not a literal */

typedef struct tkb_named {
    int64_t day;
    SV     *name;       /* NULL for a holiday with no name */
    int     flags;
} tkb_named;

/* Business hours: half-open spans of seconds of the day, a list a weekday,
 * a date's own list overriding its weekday, all read on the wall clock in
 * the schedule's zone (tkb_hours.h). */
typedef struct tkb_span { int32_t start, end; } tkb_span;
typedef struct tkb_day { tkb_span *spans; int n; int32_t total; } tkb_day;
typedef struct tkb_dated { int64_t day; tkb_day hours; } tkb_dated;
typedef struct tkb_hours {
    int        has;                /* hours were given */
    int        has_zone;
    time_keeper_zone zone;
    tkb_day    week[7];            /* Monday first */
    tkb_dated *dated; size_t n_dated;   /* sorted by day */
    int32_t    weekly_total;       /* seconds of business time in a plain week */
} tkb_hours;

typedef struct tkb_yearly {
    unsigned month, day;
    SV      *name;      /* NULL for none */
} tkb_yearly;

typedef struct tkb_schedule {
    uint8_t     weekend;          /* bit (dow - 1) set for a weekend day: Monday is bit 0 */
    uint8_t     per_week;         /* business days a week */
    uint8_t     cum[8];           /* business weekdays among Monday .. Monday + k - 1 */
    int64_t    *closed;  size_t n_closed;   /* holidays on working weekdays */
    int64_t    *open;    size_t n_open;     /* worked days on the weekend */
    tkb_named  *names;   size_t n_names;    /* every holiday, named or not */
    tkb_yearly *yearly;  size_t n_yearly;   /* dates that are holidays every year */
    AV         *gens;                       /* code refs and objects asked per year; NULL for none */
    SV         *join_a, *join_b;            /* the two parts of a join; NULL otherwise */
    int         join_both;                  /* closed only when both parts are */
    int         lazy;                       /* years come on demand */
    tkb_hours   hours;
    int64_t     year_lo, year_hi;           /* the years materialised; lo > hi for none yet */
} tkb_schedule;

#define TKB_WEEKEND_BIT(dow) ((uint8_t)(1u << ((dow) - 1)))

static int
tkb_is_weekend(const tkb_schedule *s, int64_t day)
{
    return (s->weekend & TKB_WEEKEND_BIT(tkb_dow_from_days(day))) != 0;
}

/* The first index whose day is not below the one asked for: n when none. */
static size_t
tkb_lower_bound(const int64_t *a, size_t n, int64_t day)
{
    size_t lo = 0, hi = n;
    while (lo < hi) {
        size_t mid = lo + (hi - lo) / 2;
        if (a[mid] < day) lo = mid + 1; else hi = mid;
    }
    return lo;
}

static int
tkb_has_day(const int64_t *a, size_t n, int64_t day)
{
    size_t i = tkb_lower_bound(a, n, day);
    return i < n && a[i] == day;
}

static size_t
tkb_named_lower_bound(const tkb_named *a, size_t n, int64_t day)
{
    size_t lo = 0, hi = n;
    while (lo < hi) {
        size_t mid = lo + (hi - lo) / 2;
        if (a[mid].day < day) lo = mid + 1; else hi = mid;
    }
    return lo;
}

/* The index of a holiday, or -1. */
static ptrdiff_t
tkb_find_named(const tkb_named *a, size_t n, int64_t day)
{
    size_t i = tkb_named_lower_bound(a, n, day);
    return i < n && a[i].day == day ? (ptrdiff_t)i : -1;
}

static void
tkb_insert_day(int64_t **a, size_t *n, int64_t day)
{
    size_t i = tkb_lower_bound(*a, *n, day);
    if (i < *n && (*a)[i] == day)
        return;
    Renew(*a, *n + 1, int64_t);
    Move(*a + i, *a + i + 1, *n - i, int64_t);
    (*a)[i] = day;
    (*n)++;
}

static void
tkb_remove_day(int64_t **a, size_t *n, int64_t day)
{
    size_t i = tkb_lower_bound(*a, *n, day);
    if (i >= *n || (*a)[i] != day)
        return;
    Move(*a + i + 1, *a + i, *n - i - 1, int64_t);
    (*n)--;
}

/* A holiday with a name, or without one; the first name given for a day
 * is kept, and a later one fills a day that had none. A literal entry
 * keeps a day literal. */
static void
tkb_insert_named(pTHX_ tkb_named **a, size_t *n, int64_t day, SV *name, int flags)
{
    size_t i = tkb_named_lower_bound(*a, *n, day);
    if (i < *n && (*a)[i].day == day) {
        if (!(*a)[i].name && name)
            (*a)[i].name = newSVsv(name);
        (*a)[i].flags &= flags;
        return;
    }
    Renew(*a, *n + 1, tkb_named);
    Move(*a + i, *a + i + 1, *n - i, tkb_named);
    (*a)[i].day = day;
    (*a)[i].name = name ? newSVsv(name) : NULL;
    (*a)[i].flags = flags;
    (*n)++;
}

static int
tkb_is_closed(const tkb_schedule *s, int64_t day)
{
    if (tkb_is_weekend(s, day))
        return !tkb_has_day(s->open, s->n_open, day);
    return tkb_has_day(s->closed, s->n_closed, day);
}

/* 1 if the day is a holiday, with its name (which may be NULL) in *name. */
static int
tkb_holiday(const tkb_schedule *s, int64_t day, SV **name)
{
    ptrdiff_t i = tkb_find_named(s->names, s->n_names, day);
    if (i < 0)
        return 0;
    *name = s->names[i].name;
    return 1;
}

/* A holiday into the arrays: named, closed when it falls on a weekday,
 * and no longer worked when it falls on a weekend day a list had opened. */
static void
tkb_add_holiday(pTHX_ tkb_schedule *s, int64_t day, SV *name, int flags)
{
    tkb_insert_named(aTHX_ &s->names, &s->n_names, day, name, flags);
    if (tkb_is_weekend(s, day))
        tkb_remove_day(&s->open, &s->n_open, day);
    else
        tkb_insert_day(&s->closed, &s->n_closed, day);
}

static unsigned
tkb_popcount8(uint8_t b)
{
    unsigned n = 0;
    while (b) { n += b & 1; b >>= 1; }
    return n;
}

/* The weekend, the business days a week and the running count of
 * business weekdays from Monday, set together. */
static void
tkb_set_weekend(tkb_schedule *s, uint8_t mask)
{
    int k;
    s->weekend = mask;
    s->per_week = (uint8_t)(7 - tkb_popcount8(mask));
    s->cum[0] = 0;
    for (k = 1; k <= 7; k++)
        s->cum[k] = (uint8_t)(s->cum[k - 1] + ((mask & TKB_WEEKEND_BIT(k)) ? 0 : 1));
}

static tkb_schedule *
tkb_schedule_new(pTHX)
{
    tkb_schedule *s;
    Newxz(s, 1, tkb_schedule);
    s->year_lo = INT64_MIN;
    s->year_hi = INT64_MAX;
    return s;
}

static void
tkb_schedule_clear_days(pTHX_ tkb_schedule *s)
{
    size_t i;
    for (i = 0; i < s->n_names; i++)
        SvREFCNT_dec(s->names[i].name);
    Safefree(s->closed);
    Safefree(s->open);
    Safefree(s->names);
    s->closed = s->open = NULL;
    s->names = NULL;
    s->n_closed = s->n_open = s->n_names = 0;
}

static void
tkb_day_free(tkb_day *d)
{
    Safefree(d->spans);
    d->spans = NULL;
    d->n = 0;
}

static void
tkb_hours_free(tkb_hours *h)
{
    size_t i;
    for (i = 0; i < 7; i++)
        tkb_day_free(&h->week[i]);
    for (i = 0; i < h->n_dated; i++)
        tkb_day_free(&h->dated[i].hours);
    Safefree(h->dated);
    h->dated = NULL;
    h->n_dated = 0;
}

static void
tkb_day_copy(tkb_day *to, const tkb_day *from)
{
    *to = *from;
    to->spans = NULL;
    if (from->n) {
        Newx(to->spans, from->n, tkb_span);
        Copy(from->spans, to->spans, from->n, tkb_span);
    }
}

static void
tkb_hours_copy(tkb_hours *to, const tkb_hours *from)
{
    size_t i;
    *to = *from;
    to->dated = NULL;
    for (i = 0; i < 7; i++)
        tkb_day_copy(&to->week[i], &from->week[i]);
    if (from->n_dated) {
        Newx(to->dated, from->n_dated, tkb_dated);
        for (i = 0; i < from->n_dated; i++) {
            to->dated[i].day = from->dated[i].day;
            tkb_day_copy(&to->dated[i].hours, &from->dated[i].hours);
        }
    }
}

static void
tkb_schedule_free(pTHX_ tkb_schedule *s)
{
    size_t i;
    if (!s)
        return;
    tkb_schedule_clear_days(aTHX_ s);
    tkb_hours_free(&s->hours);
    for (i = 0; i < s->n_yearly; i++)
        SvREFCNT_dec(s->yearly[i].name);
    Safefree(s->yearly);
    SvREFCNT_dec((SV *)s->gens);
    SvREFCNT_dec(s->join_a);
    SvREFCNT_dec(s->join_b);
    Safefree(s);
}

#ifdef USE_ITHREADS
/* A thread's copy: its own arrays, its own SVs. */
static tkb_schedule *
tkb_schedule_dup(pTHX_ const tkb_schedule *s, CLONE_PARAMS *param)
{
    tkb_schedule *c = tkb_schedule_new(aTHX);
    size_t i;
    *c = *s;
    c->closed = c->open = NULL;
    c->names = NULL;
    c->yearly = NULL;
    if (s->n_closed) { Newx(c->closed, s->n_closed, int64_t); Copy(s->closed, c->closed, s->n_closed, int64_t); }
    if (s->n_open)   { Newx(c->open,   s->n_open,   int64_t); Copy(s->open,   c->open,   s->n_open,   int64_t); }
    if (s->n_names) {
        Newx(c->names, s->n_names, tkb_named);
        for (i = 0; i < s->n_names; i++) {
            c->names[i] = s->names[i];
            c->names[i].name = s->names[i].name ? sv_dup_inc(s->names[i].name, param) : NULL;
        }
    }
    if (s->n_yearly) {
        Newx(c->yearly, s->n_yearly, tkb_yearly);
        for (i = 0; i < s->n_yearly; i++) {
            c->yearly[i] = s->yearly[i];
            c->yearly[i].name = s->yearly[i].name ? sv_dup_inc(s->yearly[i].name, param) : NULL;
        }
    }
    tkb_hours_copy(&c->hours, &s->hours);
    c->gens = s->gens ? (AV *)sv_dup_inc((SV *)s->gens, param) : NULL;
    c->join_a = s->join_a ? sv_dup_inc(s->join_a, param) : NULL;
    c->join_b = s->join_b ? sv_dup_inc(s->join_b, param) : NULL;
    return c;
}
#endif

static int
tkb_mg_free(pTHX_ SV *sv, MAGIC *mg)
{
    PERL_UNUSED_ARG(sv);
    tkb_schedule_free(aTHX_ (tkb_schedule *)mg->mg_ptr);
    mg->mg_ptr = NULL;
    return 0;
}

#ifdef USE_ITHREADS
static int
tkb_mg_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param)
{
    mg->mg_ptr = (char *)tkb_schedule_dup(aTHX_ (const tkb_schedule *)mg->mg_ptr, param);
    return 0;
}
#endif

/* Filled at BOOT by tkb_vtbl_init rather than by an initialiser, since
 * the members after svt_dup differ between perls from 5.10.0 on. */
static MGVTBL tkb_vtbl;

static void
tkb_vtbl_init(void)
{
    tkb_vtbl.svt_free = tkb_mg_free;
#ifdef USE_ITHREADS
    tkb_vtbl.svt_dup = tkb_mg_dup;
#endif
}

/* The struct onto a scalar, with the spec as the magic's object; the
 * spec's reference is taken by the magic. */
static void
tkb_schedule_attach(pTHX_ SV *inner, tkb_schedule *s, HV *spec)
{
    MAGIC *mg = sv_magicext(inner, (SV *)spec, PERL_MAGIC_ext, &tkb_vtbl, (const char *)s, 0);
#ifdef USE_ITHREADS
    mg->mg_flags |= MGf_DUP;
#else
    PERL_UNUSED_VAR(mg);
#endif
    SvREFCNT_dec((SV *)spec);
}

/* A new blessed scalar carrying the struct. */
static SV *
tkb_schedule_wrap(pTHX_ tkb_schedule *s, HV *spec, HV *stash)
{
    SV *inner = newSV(0);
    SV *rv = newRV_noinc(inner);
    sv_bless(rv, stash);
    tkb_schedule_attach(aTHX_ inner, s, spec);
    return rv;
}

static MAGIC *
tkb_schedule_magic(pTHX_ SV *sv)
{
    MAGIC *mg;
    if (!sv || !SvROK(sv) || !SvOBJECT(SvRV(sv)) || SvTYPE(SvRV(sv)) > SVt_PVMG)
        return NULL;
    for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic)
        if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &tkb_vtbl)
            return mg;
    return NULL;
}

static tkb_schedule *
tkb_schedule_of(pTHX_ SV *sv, const char *what)
{
    MAGIC *mg = tkb_schedule_magic(aTHX_ sv);
    if (!mg || !mg->mg_ptr)
        croak("%s: not a Time::Keeper::Business schedule", what);
    return (tkb_schedule *)mg->mg_ptr;
}

static HV *
tkb_spec_of(pTHX_ SV *sv, const char *what)
{
    MAGIC *mg = tkb_schedule_magic(aTHX_ sv);
    if (!mg || !mg->mg_obj)
        croak("%s: not a Time::Keeper::Business schedule", what);
    return (HV *)mg->mg_obj;
}

#endif
