#ifndef TIME_KEEPER_ZONE_ABI_H
#define TIME_KEEPER_ZONE_ABI_H

/* Public C ABI for Time::Keeper::Zone, resolved at run time through
 * Time::Keeper::Zone::_abi_ptr, so nothing is linked against this dist.
 *
 * The table only grows at the end. TKZ_ABI_VERSION bumps on any append, and
 * a consumer requires abi_version >= the version it was written against,
 * never ==.
 *
 * Resolving it, once, when it is first needed:
 *
 *     SV *sv = eval_pv("require Time::Keeper::Zone; Time::Keeper::Zone::_abi_ptr()", 0);
 *     const tkz_abi *t = INT2PTR(const tkz_abi *, SvUV(sv));
 *     if (t->abi_version >= TKZ_ABI_VERSION) ...
 *
 * Nothing in the table takes the interpreter or touches Perl: it is plain
 * C over constant data, safe from any thread.
 *
 * A zone id is a small non-negative int from lookup(), valid for the life
 * of the process and for this tzdata release only: store a zone's NAME, not
 * its id, anywhere that outlives the process. A link has an id of its own,
 * so name() gives back what was asked for and canonical_name() the zone
 * whose rules it follows.
 *
 * Times are seconds since 1970-01-01T00:00:00 UTC, leap seconds not
 * counted. A "local" time is the wall-clock reading counted the same way,
 * as if the clock were in UTC. */

#include <stdint.h>
#include <stddef.h>

#define TKZ_ABI_VERSION 2

/* next_change() when nothing ever changes again. */
#define TKZ_NO_CHANGE INT64_MAX

/* resolve_local() results. */
#define TKZ_LOCAL_EXACT   0   /* one instant has this wall-clock time */
#define TKZ_LOCAL_OVERLAP 1   /* two: the clocks went back over it */
#define TKZ_LOCAL_GAP     2   /* none: the clocks jumped over it */

/* resolve_local()'s gap argument. */
#define TKZ_GAP_CROAK    0    /* report the gap; *utc is not set */
#define TKZ_GAP_FORWARD  1    /* the instant the time would be with the offset before the gap */
#define TKZ_GAP_BACKWARD 2    /* the instant it would be with the offset after it */

/* resolve_local()'s overlap argument. */
#define TKZ_OVERLAP_LATER   0 /* the second time round, as DateTime does */
#define TKZ_OVERLAP_EARLIER 1

typedef struct tkz_abi {
    int abi_version;

    /* The id of a zone or link name, matched without regard to case, or -1. */
    int         (*lookup)(const char *name, size_t len);
    const char *(*name)(int id);
    const char *(*canonical_name)(int id);
    int         (*is_link)(int id);

    /* The offset (seconds east of UTC), DST flag and abbreviation at utc.
     * 0 for an id that is not one. Any pointer may be NULL. */
    int         (*offset_at)(int id, int64_t utc, int32_t *utoff, int *isdst, const char **abbr);

    /* The first instant after utc at which the offset, DST flag or
     * abbreviation changes, or TKZ_NO_CHANGE. */
    int64_t     (*next_change)(int id, int64_t utc);

    /* The UTC instant of a local time: a TKZ_LOCAL_ result, or -1 for a bad id. */
    int         (*resolve_local)(int id, int64_t local, int gap, int overlap, int64_t *utc);

    /* This process's zone, given the TZ variable's value (NULL if unset). */
    int         (*local_zone)(const char *tz, size_t len);

    const char *(*tzdata_version)(void);

    /* Ids run from 0 to zone_count() - 1, zones and links together. */
    int         (*zone_count)(void);

    /* Version 2 from here. */

    /* The last instant strictly before utc at which the offset, DST flag or
     * abbreviation changes, or TKZ_NO_CHANGE. */
    int64_t     (*prev_change)(int id, int64_t utc);

    /* Every instant whose wall clock reads local: 0 (a gap), 1, or 2 (an
     * overlap), or -1 for a bad id. Two fill utc[] earlier first and
     * utoff[] with each one's offset; one fills both slots alike; a gap
     * fills utoff[] with the offsets before and after it. In every case
     * utc[i] == local - utoff[i]. */
    int         (*resolve_local_all)(int id, int64_t local, int64_t utc[2], int32_t utoff[2]);

    /* The offset of standard time at utc, as the database's types have it:
     * Europe/Dublin's standard time is +01:00, its winter GMT a negative
     * daylight time. 0 for a bad id. */
    int         (*standard_offset_at)(int id, int64_t utc, int32_t *utoff);

    /* The two-letter ISO 3166 code of the zone's country, or NULL. */
    const char *(*country_of)(int id);

    /* The zone's Windows name, such as "GMT Standard Time", or NULL. */
    const char *(*windows_name)(int id);
} tkz_abi;

#endif
