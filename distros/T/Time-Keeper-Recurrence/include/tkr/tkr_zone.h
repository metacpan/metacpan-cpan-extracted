#ifndef TKR_ZONE_H
#define TKR_ZONE_H

/* A wall time of the rule's zone as instants: one, two when the clocks
 * went back over it, none when they went forward over it and the rule
 * skips, by the rule's gap and overlap choices. UTC, a fixed offset and
 * floating time need no zone data; a named zone asks Time::Keeper::Zone's
 * resolve_local_all, which gives both readings of a doubled wall time and
 * the offsets either side of a skipped one. Returns the count, or -1 when
 * the wall time was skipped and the rule says fail. */
static int
tkr_resolve(pTHX_ const tkr_rule *r, int64_t wall, int64_t out[2])
{
    int64_t utc[2];
    int32_t utoff[2];
    int rc;
    switch (r->zone.kind) {
    case TIME_KEEPER_ZONE_UTC:
    case TIME_KEEPER_ZONE_FLOATING:
        out[0] = wall;
        return 1;
    case TIME_KEEPER_ZONE_FIXED:
        out[0] = wall - r->zone.value;
        return 1;
    default:
        break;
    }
    rc = (tkr_tkz(aTHX)->resolve_local_all)(r->zone.value, wall, utc, utoff);
    if (rc == 1) {
        out[0] = utc[0];
        return 1;
    }
    if (rc == 2) {                                 /* the clocks went back: two readings, earlier first */
        switch (r->overlap) {
        case TKR_OVERLAP_LATER: out[0] = utc[1]; return 1;
        case TKR_OVERLAP_BOTH:  out[0] = utc[0]; out[1] = utc[1]; return 2;
        default:                out[0] = utc[0]; return 1;
        }
    }
    if (rc == 0) {                                 /* the clocks went forward over it */
        switch (r->gap) {
        case TKR_GAP_FORWARD:  out[0] = wall - utoff[0]; return 1;   /* read with the offset before: the moment after the gap */
        case TKR_GAP_BACKWARD: out[0] = wall - utoff[1]; return 1;   /* read with the offset after: the moment before it */
        case TKR_GAP_SKIP:     return 0;
        default:               return -1;
        }
    }
    return -1;
}

/* How far back of a moment's wall time a walk must begin, or on past it
 * walking back: an occurrence's instant is its wall time less the offset
 * of its own moment, so a wall time up to a clock change away can fall on
 * the other side. Three hours covers every change tzdata has; with no
 * change within three hours, and in UTC, a fixed offset or floating time,
 * nothing. */
static int64_t
tkr_lookback(pTHX_ const tkr_rule *r, int64_t from)
{
    int64_t c;
    if (r->zone.kind != TIME_KEEPER_ZONE_NAMED)
        return 0;
    c = (tkr_tkz(aTHX)->next_change)(r->zone.value, from - 3 * 3600);
    return (c != TKZ_NO_CHANGE && c <= from + 3 * 3600) ? 3 * 3600 : 0;
}

/* The wall time of an instant in the rule's zone, as seconds counted as
 * if UTC, and its fields. */
static int64_t
tkr_wall_of(pTHX_ const tkr_rule *r, int64_t inst, time_keeper_civil *c)
{
    const time_keeper_abi *T = tkr_tk(aTHX);
    time_keeper_instant t;
    time_keeper_civil tmp;
    t.sec = inst;
    t.nsec = 0;
    if (!c)
        c = &tmp;
    if ((T->civil)(aTHX_ &t, &r->zone, c) != TIME_KEEPER_OK)
        croak("Time::Keeper::Recurrence: an instant outside the years Time::Keeper holds");
    return tkr_days_from_civil(c->year, (unsigned)c->month, (unsigned)c->day) * 86400
         + c->hour * 3600 + c->minute * 60 + c->second;
}

#endif
