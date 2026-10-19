#ifndef TIME_KEEPER_RECURRENCE_ABI_H
#define TIME_KEEPER_RECURRENCE_ABI_H

/* Public C ABI for Time::Keeper::Recurrence: recurrence rules (RFC 5545
 * RRULEs, cron expressions, iCalendar sets) compiled once and walked from
 * another extension's C, and the next occurrence of a rule given as text in
 * one call.
 *
 * It is resolved at RUN TIME through Time::Keeper::Recurrence::_abi_ptr, a
 * versioned table of function pointers, so nothing links against
 * Time::Keeper::Recurrence and each dist builds and upgrades by itself. A
 * consumer reaches this header through ExtUtils::Depends, or vendors a copy
 * pinned at TIME_KEEPER_RECURRENCE_ABI_VERSION, and checks abi_version once.
 *
 * The table only ever grows at the end. TIME_KEEPER_RECURRENCE_ABI_VERSION
 * bumps on any append, and a consumer requires abi_version >= the version it
 * was written against (TIME_KEEPER_RECURRENCE_ABI_OK below), never ==.
 *
 * ---- THIS HEADER NEEDS PERL AND time_keeper_abi.h --------------------------
 *
 * Instants and zones are Time::Keeper's (time_keeper_abi.h, included below),
 * and every entry but release takes pTHX_: compiling may load
 * Time::Keeper::Zone, and a handle holds a Perl object. Include perl's
 * headers first. Time::Keeper's own Install directory must be on the
 * include path too; ExtUtils::Depends puts it there when the consumer
 * depends on both.
 *
 * ---- resolving the table ----------------------------------------------
 *
 *     static const time_keeper_recurrence_abi *TKR = NULL;
 *
 *     SV *sv = eval_pv("require Time::Keeper::Recurrence; Time::Keeper::Recurrence::_abi_ptr()", 0);
 *     SV *err = get_sv("@", 0);
 *     if (sv && SvOK(sv) && (!err || !SvTRUE(err))) {
 *         const time_keeper_recurrence_abi *t = INT2PTR(const time_keeper_recurrence_abi *, SvUV(sv));
 *         if (TIME_KEEPER_RECURRENCE_ABI_OK(t)) TKR = t;
 *     }
 *
 * The VALUE eval_pv returns, not the top of the stack. A NULL table means
 * the module is absent or older than this header.
 *
 * Calls are written (TKR->next)(aTHX_ r, &from, &out). The parentheses keep
 * a member's name from being read as a function-like macro, which XSUB.h
 * defines for some ordinary names on a perl built with PERL_IMPLICIT_SYS.
 *
 * ---- handles ----------------------------------------------------------
 *
 * compile and from_sv give a handle, a rule or a set, which the caller owns
 * and gives back with release. A handle never changes; any number of calls
 * may walk it. It is not to be shared between interpreters. new_sv makes a
 * Perl object for the same rule, which lives on by itself: releasing the
 * handle afterwards is safe.
 *
 * ---- storing rules ------------------------------------------------------
 *
 * A handle lives for the process. To keep a rule, keep its TEXT and its
 * zone's NAME, as the Perl FREEZE does, and compile again: zone ids are per
 * process and tzdata release.
 *
 * ---- results and failure ----------------------------------------------
 *
 * Every entry returns TIME_KEEPER_RECURRENCE_OK or a code below. On BAD, an
 * err buffer that is given receives a NUL-terminated message (cut to
 * errlen) saying what is wrong, in the words the Perl methods die with.
 * Outputs are left alone on failure. Nothing croaks but loading
 * Time::Keeper::Zone and running out of memory.
 *
 * ---- choices for skipped and doubled clock times ---------------------------
 *
 * gap and overlap are as the Perl options; DEFAULT takes the door's own
 * (an RRULE moves forward over a gap and takes the earlier of a doubled
 * time; a cron skips the gap and fires every real minute of a doubled
 * hour, a pinned minute once). */

#include <stddef.h>
#include "time_keeper_abi.h"

#define TIME_KEEPER_RECURRENCE_ABI_VERSION 1

#define TIME_KEEPER_RECURRENCE_ABI_OK(t) ((t) && (t)->abi_version >= TIME_KEEPER_RECURRENCE_ABI_VERSION)

#define TIME_KEEPER_RECURRENCE_OK     0
#define TIME_KEEPER_RECURRENCE_BAD   -1   /* a spec or an argument that is not one; err says why */
#define TIME_KEEPER_RECURRENCE_NONE  -2   /* no occurrence: the rule has ended, or it cannot fire again */
#define TIME_KEEPER_RECURRENCE_RANGE -3   /* an instant outside the years Time::Keeper holds */
#define TIME_KEEPER_RECURRENCE_GAP   -4   /* the next is a wall time the clocks skipped, and the rule says fail */

/* compile's kinds of spec. */
#define TIME_KEEPER_RECURRENCE_RRULE 1    /* an RRULE; start is required, its zone the rule's */
#define TIME_KEEPER_RECURRENCE_CRON  2    /* a cron expression in Punk::Queue's grammar; zone, or UTC; start a bound, or NULL */
#define TIME_KEEPER_RECURRENCE_ICAL  3    /* iCalendar lines (DTSTART, RRULE, RDATE, EXDATE, EXRULE); zone and start are not read */

#define TIME_KEEPER_RECURRENCE_DEFAULT          -1
#define TIME_KEEPER_RECURRENCE_GAP_FORWARD       0
#define TIME_KEEPER_RECURRENCE_GAP_BACKWARD      1
#define TIME_KEEPER_RECURRENCE_GAP_SKIP          2
#define TIME_KEEPER_RECURRENCE_GAP_FAIL          3
#define TIME_KEEPER_RECURRENCE_OVERLAP_EARLIER   0
#define TIME_KEEPER_RECURRENCE_OVERLAP_LATER     1
#define TIME_KEEPER_RECURRENCE_OVERLAP_BOTH      2

typedef struct time_keeper_recurrence time_keeper_recurrence;

typedef struct time_keeper_recurrence_abi {
    int abi_version;

    /* A handle from a spec of a kind above. zone is a Time::Keeper zone
     * (NULL for UTC); start a Time::Keeper instant, read in that zone. */
    int  (*compile)(pTHX_ int kind, const char *spec, size_t len, const time_keeper_zone *zone,
                    const time_keeper_instant *start, int gap, int overlap,
                    time_keeper_recurrence **out, char *err, size_t errlen);

    /* The first occurrence strictly after from, and the last strictly
     * before it. An occurrence carries the start's nanoseconds. */
    int  (*next)(pTHX_ const time_keeper_recurrence *r, const time_keeper_instant *from, time_keeper_instant *out);
    int  (*previous)(pTHX_ const time_keeper_recurrence *r, const time_keeper_instant *from, time_keeper_instant *out);

    /* Gives a handle back. NULL is allowed. */
    void (*release)(time_keeper_recurrence *r);

    /* One shot, for a scheduler that stores text. The next occurrence of a
     * cron expression in a zone named as Time::Keeper names them (an IANA
     * name, UTC, local, +HHMM or +HH:MM; NULL or empty for UTC), strictly
     * after from, in epoch seconds; NONE when nothing comes within five
     * years. A doubled hour and a skipped one are the cron door's: a pinned
     * minute fires once, a skipped one not at all. */
    int  (*cron_next)(pTHX_ const char *expr, size_t elen, const char *zone, size_t zlen,
                      double from, double *out, char *err, size_t errlen);

    /* The same for an RRULE with its start, both read in the zone. */
    int  (*rrule_next)(pTHX_ const char *rrule, size_t rlen, const char *zone, size_t zlen,
                       double start, double from, double *out, char *err, size_t errlen);

    /* A Time::Keeper::Recurrence (or ::Set) object for a handle's rule, and
     * a new handle for such an object, which the caller releases. */
    SV * (*new_sv)(pTHX_ const time_keeper_recurrence *r);
    int  (*from_sv)(pTHX_ SV *sv, time_keeper_recurrence **out);
} time_keeper_recurrence_abi;

#endif
