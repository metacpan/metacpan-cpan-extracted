#ifndef TKR_SET_H
#define TKR_SET_H

/* A set: rules (RRULEs, then the EXRULEs read from iCalendar), dates added
 * (RDATE) and dates removed (EXDATE), one zone, start, gap and overlap
 * choice for all, packed in one buffer behind a blessed reference: a
 * header, the rules, the dates. Never changed after it is made. Its
 * occurrences are the merge of each rule's, in order, with the added dates
 * in and the removed ones and the EXRULEs' taken out. An added whole day
 * is its midnight in the set's zone, resolved when the set is made; a
 * removed whole day takes every occurrence of that day in the set's zone,
 * so it is kept as the day's wall midnight and compared by day. */

#define TKR_SET_MAGIC     0x53524b54u
#define TKR_SET_MAX_RULES 16
#define TKR_SET_MAX_DATES 10000

typedef struct tkr_date {
    int64_t at;        /* an instant; a removed whole day: its wall midnight, seconds as if UTC */
    uint8_t is_day;
} tkr_date;

typedef struct tkr_set {
    uint32_t magic;
    uint8_t  n_rules, n_exrules, gap, overlap;
    uint32_t n_rdates, n_exdates;
    time_keeper_zone    zone;
    time_keeper_instant start;
    int      locale;
    uint8_t  has_start, start_is_day, pad[6];
} tkr_set;

#define TKR_SET_HDR ((sizeof(tkr_set) + 7) & ~(size_t)7)

static size_t tkr_set_size(unsigned nrules, unsigned ndates) { return TKR_SET_HDR + nrules * sizeof(tkr_rule) + ndates * sizeof(tkr_date); }
static tkr_rule *tkr_set_rules(const tkr_set *s) { return (tkr_rule *)((char *)s + TKR_SET_HDR); }
static tkr_date *tkr_set_rdates(const tkr_set *s) { return (tkr_date *)(tkr_set_rules(s) + s->n_rules + s->n_exrules); }
static tkr_date *tkr_set_exdates(const tkr_set *s) { return tkr_set_rdates(s) + s->n_rdates; }

static int
tkr_date_cmp(const void *a, const void *b)
{
    const tkr_date *x = (const tkr_date *)a, *y = (const tkr_date *)b;
    return x->at < y->at ? -1 : x->at > y->at ? 1 : (int)x->is_day - (int)y->is_day;
}

/* The wall time of an instant in a zone, and the instant of a wall time
 * (forward over a gap, the earlier of an overlap). */
static int64_t
tkr_zone_wall(pTHX_ const time_keeper_zone *z, int64_t inst)
{
    tkr_rule probe;
    tkr_rule_init(&probe);
    probe.zone = *z;
    return tkr_wall_of(aTHX_ &probe, inst, NULL);
}

static int64_t
tkr_zone_instant(pTHX_ const time_keeper_zone *z, int64_t wall, const char *what)
{
    tkr_rule probe;
    int64_t out[2];
    tkr_rule_init(&probe);
    probe.zone = *z;
    probe.gap = TKR_GAP_FORWARD;
    probe.overlap = TKR_OVERLAP_EARLIER;
    if (tkr_resolve(aTHX_ &probe, wall, out) < 1)
        croak("%s: a date outside the years Time::Keeper holds", what);
    return out[0];
}

/* Everything a set is made of, before it is packed. */
typedef struct tkr_set_parts {
    tkr_rule rules[TKR_SET_MAX_RULES];
    unsigned n_rules, n_exrules;
    tkr_date *rdates, *exdates;
    unsigned n_rdates, n_exdates, rcap, xcap;
    time_keeper_zone zone;
    time_keeper_instant start;
    int locale, has_start, start_is_day, gap, overlap;
} tkr_set_parts;

static void
tkr_parts_init(tkr_set_parts *p)
{
    memset(p, 0, sizeof *p);
    p->zone.kind = TIME_KEEPER_ZONE_UTC;
    p->gap = TKR_GAP_FORWARD;
    p->overlap = TKR_OVERLAP_EARLIER;
}

static void
tkr_parts_free(tkr_set_parts *p)
{
    if (p->rdates) Safefree(p->rdates);
    if (p->exdates) Safefree(p->exdates);
    p->rdates = p->exdates = NULL;
}

/* A date as it is stored: an instant, or a removed day's wall midnight. */
static void
tkr_parts_add_raw(pTHX_ tkr_set_parts *p, int ex, int64_t at, int is_day, const char *what)
{
    tkr_date **list = ex ? &p->exdates : &p->rdates;
    unsigned *n = ex ? &p->n_exdates : &p->n_rdates, *cap = ex ? &p->xcap : &p->rcap;
    if (*n >= TKR_SET_MAX_DATES) {
        tkr_parts_free(p);
        croak("%s: more than %d dates %s", what, TKR_SET_MAX_DATES, ex ? "removed" : "added");
    }
    if (*n >= *cap) {
        *cap = *cap ? *cap * 2 : 16;
        Renew(*list, *cap, tkr_date);
    }
    (*list)[*n].at = at;
    (*list)[*n].is_day = (uint8_t)is_day;
    (*n)++;
}

/* A date as it was given: an instant, or a whole day as its wall midnight
 * in the set's zone (an added day becomes the instant of that midnight). */
static void
tkr_parts_add_date(pTHX_ tkr_set_parts *p, int ex, int64_t at, int is_day, const char *what)
{
    if (is_day && !ex)
        at = tkr_zone_instant(aTHX_ &p->zone, at, what);
    tkr_parts_add_raw(aTHX_ p, ex, at, is_day, what);
}

static void
tkr_parts_add_rule(pTHX_ tkr_set_parts *p, const tkr_rule *r, int ex, const char *what)
{
    if (p->n_rules + p->n_exrules >= TKR_SET_MAX_RULES) {
        tkr_parts_free(p);
        croak("%s: more than %d rules in a set", what, TKR_SET_MAX_RULES);
    }
    if (ex) {
        p->rules[p->n_rules + p->n_exrules] = *r;
        p->n_exrules++;
    }
    else {
        memmove(&p->rules[p->n_rules + 1], &p->rules[p->n_rules], p->n_exrules * sizeof(tkr_rule));
        p->rules[p->n_rules] = *r;
        p->n_rules++;
    }
}

static int
tkr_zone_eq(const time_keeper_zone *a, const time_keeper_zone *b)
{
    return a->kind == b->kind && (a->kind == TIME_KEEPER_ZONE_UTC || a->kind == TIME_KEEPER_ZONE_FLOATING || a->value == b->value);
}

/* A rule joining a set from Perl: it must share the set's zone, and an
 * RRULE its start; a cron keeps its own bound. */
static void
tkr_parts_join_rule(pTHX_ tkr_set_parts *p, const tkr_rule *r, const char *what)
{
    if (r->flags & TKR_F_EVERY) {
        tkr_parts_free(p);
        croak("%s: an @every cron has no occurrences of its own, only the next after a moment", what);
    }
    if (!tkr_zone_eq(&p->zone, &r->zone)) {
        tkr_parts_free(p);
        croak("%s: the rules of a set share one zone", what);
    }
    if (!(r->flags & TKR_F_CRON) && p->has_start && (r->start.sec != p->start.sec || r->start.nsec != p->start.nsec)) {
        tkr_parts_free(p);
        croak("%s: the rules of a set share one start", what);
    }
    if (!(r->flags & TKR_F_CRON) && !p->has_start) {
        p->start = r->start;
        p->has_start = 1;
    }
    tkr_parts_add_rule(aTHX_ p, r, 0, what);
}

/* The set, packed and blessed. The dates are sorted and deduplicated; every
 * rule takes the set's zone, locale, gap and overlap, and an RRULE its start. */
static SV *
tkr_set_new_sv(pTHX_ HV *stash, tkr_set_parts *p, const char *what)
{
    unsigned i, nr = p->n_rules + p->n_exrules, w;
    size_t size;
    SV *body;
    tkr_set *s;
    tkr_rule *rules;
    tkr_date *d;
    if (!nr && !p->n_rdates) {
        tkr_parts_free(p);
        croak("%s: nothing recurs: no rule and no date added", what);
    }
    size = tkr_set_size(nr, p->n_rdates + p->n_exdates);
    body = newSV(size + 1);
    SvPOK_on(body);
    s = (tkr_set *)SvPVX(body);
    memset(s, 0, size);
    s->magic = TKR_SET_MAGIC;
    s->n_rules = (uint8_t)p->n_rules;
    s->n_exrules = (uint8_t)p->n_exrules;
    s->gap = (uint8_t)p->gap;
    s->overlap = (uint8_t)p->overlap;
    s->zone = p->zone;
    s->start = p->start;
    s->locale = p->locale;
    s->has_start = (uint8_t)(p->has_start != 0);
    s->start_is_day = (uint8_t)(p->start_is_day != 0);
    rules = tkr_set_rules(s);
    for (i = 0; i < nr; i++) {
        rules[i] = p->rules[i];
        rules[i].zone = p->zone;
        rules[i].locale = p->locale;
        rules[i].gap = (uint8_t)p->gap;
        rules[i].overlap = (uint8_t)p->overlap;
        if (p->has_start && !(rules[i].flags & TKR_F_CRON)) {
            rules[i].start = p->start;
            rules[i].flags |= TKR_F_HAS_START;
        }
    }
    if (p->n_rdates)
        qsort(p->rdates, p->n_rdates, sizeof(tkr_date), tkr_date_cmp);
    if (p->n_exdates)
        qsort(p->exdates, p->n_exdates, sizeof(tkr_date), tkr_date_cmp);
    d = tkr_set_rdates(s);
    for (i = w = 0; i < p->n_rdates; i++)
        if (!w || tkr_date_cmp(&p->rdates[i], &d[w - 1]) != 0)
            d[w++] = p->rdates[i];
    s->n_rdates = w;
    d = tkr_set_rdates(s) + w;
    for (i = w = 0; i < p->n_exdates; i++)
        if (!w || tkr_date_cmp(&p->exdates[i], &d[w - 1]) != 0)
            d[w++] = p->exdates[i];
    s->n_exdates = w;
    SvCUR_set(body, tkr_set_size(nr, s->n_rdates + s->n_exdates));
    tkr_parts_free(p);
    return sv_bless(newRV_noinc(body), stash);
}

static tkr_set *
tkr_set_of(pTHX_ SV *sv, const char *what)
{
    tkr_set *s;
    if (!sv || !SvROK(sv) || !sv_derived_from(sv, "Time::Keeper::Recurrence::Set") || !SvPOK(SvRV(sv))
        || SvCUR(SvRV(sv)) < TKR_SET_HDR)
        croak("%s: not a Time::Keeper::Recurrence::Set", what);
    s = (tkr_set *)SvPVX(SvRV(sv));
    if (s->magic != TKR_SET_MAGIC || SvCUR(SvRV(sv)) != tkr_set_size(s->n_rules + s->n_exrules, s->n_rdates + s->n_exdates))
        croak("%s: a damaged Time::Keeper::Recurrence::Set", what);
    return s;
}

/* The parts of a set, back out of it, so with() can add to them. */
static void
tkr_parts_from_set(pTHX_ tkr_set_parts *p, const tkr_set *s, const char *what)
{
    unsigned i;
    tkr_parts_init(p);
    p->zone = s->zone;
    p->start = s->start;
    p->locale = s->locale;
    p->has_start = s->has_start;
    p->start_is_day = s->start_is_day;
    p->gap = s->gap;
    p->overlap = s->overlap;
    for (i = 0; i < (unsigned)s->n_rules; i++) tkr_parts_add_rule(aTHX_ p, &tkr_set_rules(s)[i], 0, what);
    for (i = 0; i < (unsigned)s->n_exrules; i++) tkr_parts_add_rule(aTHX_ p, &tkr_set_rules(s)[s->n_rules + i], 1, what);
    for (i = 0; i < s->n_rdates; i++) tkr_parts_add_raw(aTHX_ p, 0, tkr_set_rdates(s)[i].at, tkr_set_rdates(s)[i].is_day, what);
    for (i = 0; i < s->n_exdates; i++) tkr_parts_add_raw(aTHX_ p, 1, tkr_set_exdates(s)[i].at, tkr_set_exdates(s)[i].is_day, what);
}

static void
tkr_parts_from_rule(pTHX_ tkr_set_parts *p, const tkr_rule *r, const char *what)
{
    tkr_parts_init(p);
    if (r->flags & TKR_F_EVERY)
        croak("%s: an @every cron has no occurrences of its own, only the next after a moment", what);
    p->zone = r->zone;
    p->start = r->start;
    p->locale = r->locale;
    p->has_start = (r->flags & TKR_F_HAS_START) != 0 && !(r->flags & TKR_F_CRON);
    p->gap = r->gap;
    p->overlap = r->overlap;
    tkr_parts_add_rule(aTHX_ p, r, 0, what);
}

/* ---- the merge --------------------------------------------------------------- */

/* Is an instant removed: an EXDATE to the second, an EXDATE of its whole
 * day in the set's zone, or an occurrence of an EXRULE. */
static int
tkr_set_excluded(pTHX_ const tkr_set *s, int64_t inst, int *rc)
{
    const tkr_date *x = tkr_set_exdates(s);
    unsigned i;
    int64_t day = INT64_MIN;
    for (i = 0; i < s->n_exdates; i++) {
        if (x[i].is_day) {
            if (day == INT64_MIN)
                day = tkr_floor_div(tkr_zone_wall(aTHX_ &s->zone, inst), 86400) * 86400;
            if (x[i].at == day)
                return 1;
        }
        else if (x[i].at == inst)
            return 1;
    }
    for (i = 0; i < s->n_exrules; i++) {
        int64_t got;
        int r = tkr_next_after(aTHX_ &tkr_set_rules(s)[s->n_rules + i], inst, 1, &got, NULL);
        if (r == TKR_W_FAIL) {
            *rc = r;
            return 1;
        }
        if (r == TKR_W_GOT && got == inst)
            return 1;
    }
    return 0;
}

typedef struct tkr_setiter {
    SV        *set_sv;              /* held: an iterator outlives the object it came from */
    tkr_walk  *walks[TKR_SET_MAX_RULES];
    int64_t    heads[TKR_SET_MAX_RULES];
    unsigned   rd_i;
    int64_t    from, last, fail_wall;
    int        inclusive, from_start, done;
} tkr_setiter;

/* A rule's next occurrence past the iterator's from, into heads[i]. A
 * cron's start is a bound, never an occurrence. */
static int
tkr_setiter_pull(pTHX_ tkr_setiter *it, unsigned i)
{
    int64_t got;
    int rc;
    const tkr_rule *r = &it->walks[i]->rule;
    while ((rc = tkr_walk_next(aTHX_ it->walks[i], &got)) == TKR_W_GOT) {
        if (got > it->from || (it->inclusive && got == it->from && !((r->flags & TKR_F_CRON) && it->from_start))) {
            it->heads[i] = got;
            return TKR_W_GOT;
        }
    }
    it->heads[i] = INT64_MAX;
    if (rc == TKR_W_FAIL)
        it->fail_wall = it->walks[i]->fail_wall;
    return rc;
}

static void
tkr_setiter_free(pTHX_ tkr_setiter *it)
{
    unsigned i;
    for (i = 0; i < TKR_SET_MAX_RULES; i++)
        if (it->walks[i]) {
            tkr_walk_free(it->walks[i]);
            Safefree(it->walks[i]);
            it->walks[i] = NULL;
        }
    if (it->set_sv)
        SvREFCNT_dec(it->set_sv);
    it->set_sv = NULL;
}

static int
tkr_setiter_init(pTHX_ tkr_setiter *it, SV *set_sv, int64_t from, int inclusive, int from_start)
{
    const tkr_set *s = tkr_set_of(aTHX_ set_sv, "Time::Keeper::Recurrence::Set");
    const tkr_date *rd = tkr_set_rdates(s);
    unsigned i;
    memset(it, 0, sizeof *it);
    it->set_sv = SvREFCNT_inc_simple_NN(set_sv);
    it->from = from;
    it->inclusive = inclusive;
    it->from_start = from_start;
    it->last = INT64_MIN;
    for (i = 0; i < s->n_rules; i++) {
        const tkr_rule *r = &tkr_set_rules(s)[i];
        int rc;
        Newxz(it->walks[i], 1, tkr_walk);
        if (r->flags & TKR_F_EVERY) {
            it->heads[i] = INT64_MAX;       /* an @every cron has no occurrences of its own */
            it->walks[i]->rule = *r;
            continue;
        }
        tkr_walk_init(aTHX_ it->walks[i], r, tkr_wall_of(aTHX_ r, from, NULL) - tkr_lookback(aTHX_ r, from), from_start && (r->flags & TKR_F_HAS_START));
        rc = tkr_setiter_pull(aTHX_ it, i);
        if (rc < 0) {
            tkr_setiter_free(aTHX_ it);
            return rc;
        }
    }
    for (it->rd_i = 0; it->rd_i < s->n_rdates; it->rd_i++)
        if (rd[it->rd_i].at > from || (inclusive && rd[it->rd_i].at == from))
            break;
    return TKR_W_GOT;
}

/* The next occurrence of the set, in order: the least of every rule's head
 * and the next added date, unless it was given out already or is removed. */
static int
tkr_setiter_next(pTHX_ tkr_setiter *it, int64_t *inst)
{
    const tkr_set *s = (const tkr_set *)SvPVX(SvRV(it->set_sv));
    const tkr_date *rd = tkr_set_rdates(s);
    for (;;) {
        int64_t best = INT64_MAX;
        int which = -1, rc = TKR_W_GOT, excluded;
        unsigned i;
        if (it->done)
            return TKR_W_END;
        for (i = 0; i < s->n_rules; i++)
            if (it->heads[i] < best) {
                best = it->heads[i];
                which = (int)i;
            }
        if (it->rd_i < s->n_rdates && rd[it->rd_i].at < best) {
            best = rd[it->rd_i].at;
            which = -2;
        }
        if (which == -1) {
            it->done = 1;
            return TKR_W_END;
        }
        if (which == -2)
            it->rd_i++;
        else {
            rc = tkr_setiter_pull(aTHX_ it, (unsigned)which);
            if (rc < 0)
                return rc;
        }
        if (best == it->last)
            continue;
        excluded = tkr_set_excluded(aTHX_ s, best, &rc);
        if (rc < 0)
            return rc;
        if (excluded)
            continue;
        it->last = best;
        *inst = best;
        return TKR_W_GOT;
    }
}

/* The last occurrence of the set strictly before an instant: the greatest
 * of every rule's previous and the last added date before it, stepping
 * back past the removed ones. */
static int
tkr_set_previous(pTHX_ SV *set_sv, int64_t from, int64_t *inst, int64_t *detail)
{
    const tkr_set *s = tkr_set_of(aTHX_ set_sv, "Time::Keeper::Recurrence::Set->previous");
    const tkr_date *rd = tkr_set_rdates(s);
    unsigned guard = 0;
    for (;;) {
        int64_t best = INT64_MIN;
        unsigned i;
        int rc, excluded;
        for (i = 0; i < s->n_rules; i++) {
            int64_t got;
            const tkr_rule *r = &tkr_set_rules(s)[i];
            if (r->flags & TKR_F_EVERY)
                continue;
            rc = tkr_previous_before(aTHX_ r, from, &got, detail);
            if (rc < 0)
                return rc;
            if (rc == TKR_W_GOT && got > best)
                best = got;
        }
        for (i = s->n_rdates; i > 0; i--)
            if (rd[i - 1].at < from) {
                if (rd[i - 1].at > best)
                    best = rd[i - 1].at;
                break;
            }
        if (best == INT64_MIN)
            return TKR_W_END;
        excluded = tkr_set_excluded(aTHX_ s, best, &rc);
        if (rc < 0)
            return rc;
        if (!excluded) {
            *inst = best;
            return TKR_W_GOT;
        }
        from = best;
        if (++guard > TKR_SET_MAX_DATES + 1000)
            return TKR_W_END;
    }
}

#endif
