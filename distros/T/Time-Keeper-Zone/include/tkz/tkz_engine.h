#ifndef TKZ_ENGINE_H
#define TKZ_ENGINE_H

/* The zone engine: the local time type at an instant, the next change
 * after it, and the instant a wall-clock time names.
 *
 * A zone id is an index into tkz_lookup, so a link keeps its own name and
 * shares its target's data. Everything here is plain C over const tables:
 * no Perl, no globals, nothing to lock.
 *
 * Before a zone's first transition it is in its initial type. From its
 * last transition on (or always, if it has none) its footer, a POSIX TZ
 * string, decides. A footer's rule times may be negative or past 24 hours
 * (RFC 9636), so a year's transitions can fall in the year before or
 * after it: the footer is worked out over four years around the instant
 * and the results sorted, rather than assumed to lie in their own year. */

static int64_t
tkz_floor_div(int64_t a, int64_t b)
{
    int64_t q = a / b;
    if ((a % b != 0) && ((a < 0) != (b < 0)))
        q--;
    return q;
}

static int
tkz_is_leap(int64_t y)
{
    return (y % 4 == 0) && (y % 100 != 0 || y % 400 == 0);
}

static int64_t
tkz_days_from_civil(int64_t y, unsigned m, unsigned d)
{
    int64_t era, yoe, doy, doe;
    y -= m <= 2;
    era = (y >= 0 ? y : y - 399) / 400;
    yoe = y - era * 400;
    doy = (153 * (int64_t)(m > 2 ? m - 3 : m + 9) + 2) / 5 + d - 1;
    doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    return era * 146097 + doe - 719468;
}

static int64_t
tkz_year_of_day(int64_t z)
{
    int64_t era, doe, yoe, doy, mp;
    z += 719468;
    era = (z >= 0 ? z : z - 146096) / 146097;
    doe = z - era * 146097;
    yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    mp = (5 * doy + 2) / 153;
    return yoe + era * 400 + (mp >= 10);
}

/* Seconds from 1970 to the local midnight the rule names in year y, plus
 * the rule's time: local seconds, not yet UTC. */
static int64_t
tkz_rule_local(const tkz_rule *r, int64_t y)
{
    int64_t day;
    switch (r->kind) {
    case TKZ_RULE_MONTH: {
        static const unsigned char dim[12] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
        int64_t first = tkz_days_from_civil(y, r->month, 1);
        unsigned last = dim[r->month - 1] + (r->month == 2 && tkz_is_leap(y));
        unsigned wd1 = (unsigned)((first % 7 + 7 + 4) % 7);   /* 0 = Sunday; day 0 was a Thursday */
        unsigned d = 1 + (r->wday + 7 - wd1) % 7 + (r->week - 1) * 7;
        while (d > last)
            d -= 7;
        day = first + d - 1;
        break;
    }
    case TKZ_RULE_JULIAN:
        day = tkz_days_from_civil(y, 1, 1) + r->day - 1
            + (tkz_is_leap(y) && r->day >= 60);
        break;
    default:
        day = tkz_days_from_civil(y, 1, 1) + r->day;
        break;
    }
    return day * 86400 + r->time;
}

/* The footer's state at t: the type in force, and the next change after
 * t (TKZ_NO_CHANGE if it has no daylight time). */
static uint16_t
tkz_footer_at(const tkz_footer *f, int64_t t, int64_t *next)
{
    int64_t at[8], y;
    uint16_t ty[8], cur;
    int n = 0, i, j;

    if (f->dst_type == 0xFFFF) {
        *next = TKZ_NO_CHANGE;
        return f->std_type;
    }
    y = tkz_year_of_day(tkz_floor_div(t + f->std_utoff, 86400));
    for (j = -1; j <= 2; j++) {
        at[n] = tkz_rule_local(&f->start, y + j) - f->std_utoff;
        ty[n++] = f->dst_type;
        at[n] = tkz_rule_local(&f->end, y + j) - f->dst_utoff;
        ty[n++] = f->std_type;
    }
    /* Insertion sort, stable: a year's end and the next year's start at
     * the same instant keep that order, so the later one wins. */
    for (i = 1; i < n; i++) {
        int64_t a = at[i];
        uint16_t b = ty[i];
        for (j = i - 1; j >= 0 && at[j] > a; j--) {
            at[j + 1] = at[j];
            ty[j + 1] = ty[j];
        }
        at[j + 1] = a;
        ty[j + 1] = b;
    }
    cur = ty[0] == f->dst_type ? f->std_type : f->dst_type;
    *next = TKZ_NO_CHANGE;
    for (i = 0; i < n; i++) {
        if (at[i] <= t) {
            cur = ty[i];
        }
        else {
            *next = at[i];
            break;
        }
    }
    return cur;
}

static const tkz_zone *
tkz_zone_of(int id)
{
    return &tkz_zones[tkz_lookup[id].zone];
}

/* The type at t, and the instant of the next change after t, or
 * TKZ_NO_CHANGE. A "change" here is a transition in the table or the footer;
 * it may leave the offset, DST flag and abbreviation all as they were. */
static uint16_t
tkz_type_at(int id, int64_t t, int64_t *next)
{
    const tkz_zone *z = tkz_zone_of(id);
    const int64_t *at = tkz_trans_at + z->first_trans;
    uint32_t n = z->n_trans, lo, hi;

    if (n == 0 || t >= at[n - 1]) {
        if (z->footer == TKZ_NO_FOOTER) {
            *next = TKZ_NO_CHANGE;
            return n ? tkz_trans_type[z->first_trans + n - 1] : z->initial_type;
        }
        return tkz_footer_at(&tkz_footers[z->footer], t, next);
    }
    if (t < at[0]) {
        *next = at[0];
        return z->initial_type;
    }
    /* The last transition at or before t: at[lo] <= t < at[hi]. */
    lo = 0;
    hi = n - 1;
    while (hi - lo > 1) {
        uint32_t mid = lo + (hi - lo) / 2;
        if (at[mid] <= t)
            lo = mid;
        else
            hi = mid;
    }
    *next = at[hi];
    return tkz_trans_type[z->first_trans + lo];
}

static int
tkz_offset_at(int id, int64_t t, int32_t *utoff, int *isdst, const char **abbr)
{
    int64_t next;
    const tkz_type *ty;
    if (id < 0 || id >= TKZ_LOOKUP_COUNT)
        return 0;
    ty = &tkz_types[tkz_type_at(id, t, &next)];
    if (utoff) *utoff = ty->utoff;
    if (isdst) *isdst = ty->isdst;
    if (abbr)  *abbr = tkz_abbrs + ty->abbr;
    return 1;
}

/* The next instant after t at which the offset, DST flag or abbreviation
 * really changes, or TKZ_NO_CHANGE. */
static int64_t
tkz_next_change(int id, int64_t t)
{
    int64_t next;
    uint16_t now = tkz_type_at(id, t, &next);
    while (next != TKZ_NO_CHANGE) {
        int64_t after;
        uint16_t then = tkz_type_at(id, next, &after);
        if (then != now) {
            const tkz_type *a = &tkz_types[now], *b = &tkz_types[then];
            if (a->utoff != b->utoff || a->isdst != b->isdst
                || strcmp(tkz_abbrs + a->abbr, tkz_abbrs + b->abbr) != 0)
                return next;
        }
        if (after <= next)
            break;
        next = after;
    }
    return TKZ_NO_CHANGE;
}

/* The UTC instant of local time `local` (seconds since 1970, as if the
 * wall clock were UTC). Every stretch of constant offset within a day and
 * a bit either side is tried: an instant t in a stretch with offset o
 * matches when t + o == local. No offset has ever been more than a day. */
static int
tkz_resolve_local(int id, int64_t local, int gap, int overlap, int64_t *utc)
{
    int64_t from = local - 2 * 86400, to = local + 2 * 86400;
    int64_t t = from, first = TKZ_NO_CHANGE, last = TKZ_NO_CHANGE;
    int found = 0;
    int32_t before_off = 0, after_off = 0;
    int have_gap = 0;

    if (id < 0 || id >= TKZ_LOOKUP_COUNT)
        return -1;
    while (t <= to) {
        int64_t next, cand;
        uint16_t ty = tkz_type_at(id, t, &next);
        int32_t off = tkz_types[ty].utoff;
        cand = local - off;
        if (cand >= t && (next == TKZ_NO_CHANGE || cand < next)) {
            if (!found) first = cand;
            last = cand;
            found++;
        }
        else if (!found && !have_gap && next != TKZ_NO_CHANGE && cand >= next) {
            int64_t after;
            int32_t noff = tkz_types[tkz_type_at(id, next, &after)].utoff;
            if (local - noff < next) {
                /* next + off <= local < next + noff: the clocks jumped
                 * from next + off to next + noff, over local */
                have_gap = 1;
                before_off = off;
                after_off = noff;
            }
        }
        if (next == TKZ_NO_CHANGE)
            break;
        t = next;
    }
    if (found == 1) {
        *utc = first;
        return TKZ_LOCAL_EXACT;
    }
    if (found > 1) {
        *utc = overlap == TKZ_OVERLAP_EARLIER ? first : last;
        return TKZ_LOCAL_OVERLAP;
    }
    if (have_gap) {
        if (gap == TKZ_GAP_FORWARD)
            *utc = local - before_off;
        else if (gap == TKZ_GAP_BACKWARD)
            *utc = local - after_off;
    }
    return TKZ_LOCAL_GAP;
}

/* Case-blind binary search of the names. */
static int
tkz_strncasecmp_nul(const char *a, const char *b, size_t blen)
{
    size_t i;
    for (i = 0; i < blen; i++) {
        int ca = (unsigned char)a[i], cb = (unsigned char)b[i];
        if (ca >= 'A' && ca <= 'Z') ca += 32;
        if (cb >= 'A' && cb <= 'Z') cb += 32;
        if (ca == 0) return -1;
        if (ca != cb) return ca - cb;
    }
    return a[blen] == 0 ? 0 : 1;
}

static int
tkz_lookup_name(const char *name, size_t len)
{
    int lo = 0, hi = TKZ_LOOKUP_COUNT - 1;
    if (len == 0 || memchr(name, 0, len))
        return -1;
    while (lo <= hi) {
        int mid = lo + (hi - lo) / 2;
        int c = tkz_strncasecmp_nul(tkz_names + tkz_lookup[mid].name, name, len);
        if (c == 0)
            return mid;
        if (c < 0)
            lo = mid + 1;
        else
            hi = mid - 1;
    }
    return -1;
}

static const char *
tkz_id_name(int id)
{
    return (id < 0 || id >= TKZ_LOOKUP_COUNT) ? NULL : tkz_names + tkz_lookup[id].name;
}

static const char *
tkz_id_canonical(int id)
{
    return (id < 0 || id >= TKZ_LOOKUP_COUNT) ? NULL : tkz_names + tkz_zone_of(id)->name;
}

static int
tkz_id_is_link(int id)
{
    return (id < 0 || id >= TKZ_LOOKUP_COUNT) ? 0 : tkz_lookup[id].is_link;
}

#endif
