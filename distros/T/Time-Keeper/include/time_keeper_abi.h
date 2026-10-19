#ifndef TIME_KEEPER_ABI_H
#define TIME_KEEPER_ABI_H

/* Public C ABI for Time::Keeper: dates and times, their zones and locales,
 * formatting and parsing, callable from another extension's C.
 *
 * It is resolved at RUN TIME through Time::Keeper::_abi_ptr, a versioned
 * table of function pointers, so nothing links against Time::Keeper and
 * each dist builds and upgrades by itself. A consumer reaches this header
 * through ExtUtils::Depends, or vendors a copy pinned at
 * TIME_KEEPER_ABI_VERSION, and checks abi_version once.
 *
 * The table only ever grows at the end. TIME_KEEPER_ABI_VERSION bumps on any
 * append, and a consumer requires abi_version >= the version it was written
 * against (TIME_KEEPER_ABI_OK below), never ==.
 *
 * ---- THIS HEADER NEEDS PERL -------------------------------------------
 *
 * Entries that may load Time::Keeper::Zone, or that make or read a Perl
 * value, take pTHX_. Include perl's headers first. now, http_date,
 * locale_find and tai_minus_utc are plain C and safe from any thread.
 *
 * ---- resolving the table ----------------------------------------------
 *
 * The first time it is needed, or at BOOT once Time::Keeper is loaded (a
 * BOOT that runs before it must require it first):
 *
 *     static const time_keeper_abi *TK = NULL;
 *
 *     SV *sv = eval_pv("require Time::Keeper; Time::Keeper::_abi_ptr()", 0);
 *     SV *err = get_sv("@", 0);
 *     if (sv && SvOK(sv) && (!err || !SvTRUE(err))) {
 *         const time_keeper_abi *t = INT2PTR(const time_keeper_abi *, SvUV(sv));
 *         if (TIME_KEEPER_ABI_OK(t)) TK = t;
 *     }
 *
 * The VALUE eval_pv returns, not the top of the stack. A NULL table means
 * Time::Keeper is absent or older than this header.
 *
 * Calls are written (TK->now)(&t). The parentheses keep a member's name from
 * being read as a function-like macro, which XSUB.h defines for a number of
 * ordinary names on a perl built with PERL_IMPLICIT_SYS.
 *
 * ---- instants --------------------------------------------------------
 *
 * An instant is seconds since 1970-01-01T00:00:00 UTC with leap seconds
 * not counted, and nanoseconds. During a leap second (23:59:60) sec is that
 * of 23:59:59 and nsec runs from 1000000000 to 1999999999. Years run from
 * -999999999 to 999999999.
 *
 * ---- zones -------------------------------------------------------------
 *
 * A zone is a kind and a value: UTC; floating time (a wall clock with no
 * zone: the instant holds the wall-clock time read as UTC); a fixed offset
 * (value: seconds east of UTC, less than a day either way); or a named zone
 * (value: Time::Keeper::Zone's id for the name, from its own ABI or from
 * zone_parse). An id is valid for the life of the process and for one
 * tzdata release: store a zone's NAME, not its id, anywhere that outlives
 * the process.
 *
 * ---- locales -------------------------------------------------------------
 *
 * A locale is an id from locale_find, 0 for English. Ids are those of this
 * build: store a locale's CODE, not its id.
 *
 * ---- results and failure ----------------------------------------------
 *
 * An entry that returns int returns TIME_KEEPER_OK or one of the codes
 * below, and leaves its outputs alone on failure. One that writes a string
 * returns the length the whole string needs, not counting the NUL, as
 * snprintf does: it wrote all of it, NUL-terminated, if that is less than
 * len. A named zone needs Time::Keeper::Zone, loaded the first time one is
 * used; if it cannot be loaded, the entry croaks, as the Perl methods do.
 * Running out of memory croaks, as perl's own allocator does. Nothing else
 * croaks.
 *
 * ---- calendars (version 2) ---------------------------------------------
 *
 * A calendar is an id from calendar_find, 0 for the Gregorian; ids are those
 * of this build, so store a calendar's ID STRING (calendar_id gives it), not
 * its number. cal_fields reads an instant's wall clock in a calendar: the
 * calendar's continuous year, its era and the year within it, the ordinal
 * month and the number in its month code, the day, and the shape of the
 * month and year; cal_from_fields goes back from the calendar, year, month,
 * day and clock. A calendar read from a table (chinese, dangi, islamic,
 * islamic-rgsa) answers TIME_KEEPER_RANGE outside its years. format_cal and
 * strftime_cal write a pattern in a calendar as the methods do on a value
 * read in one. Version 1's civil, from_civil, strftime and format stay
 * Gregorian, and time_keeper_civil never widens. */

#include <stdint.h>
#include <stddef.h>

#define TIME_KEEPER_ABI_VERSION 2

#define TIME_KEEPER_ABI_OK(t) ((t) && (t)->abi_version >= TIME_KEEPER_ABI_VERSION)

#define TIME_KEEPER_OK      0
#define TIME_KEEPER_BAD    -1   /* an argument out of range, or a field that is not one */
#define TIME_KEEPER_GAP    -2   /* the local time did not happen: the clocks went forward over it */
#define TIME_KEEPER_RANGE  -3   /* the result is outside the years Time::Keeper holds */
#define TIME_KEEPER_PARSE  -4   /* text that is not a date and time */
#define TIME_KEEPER_NOLEAP -5   /* second 60 where there was no leap second */

#define TIME_KEEPER_ZONE_UTC      0
#define TIME_KEEPER_ZONE_FLOATING 1
#define TIME_KEEPER_ZONE_FIXED    2
#define TIME_KEEPER_ZONE_NAMED    3

/* from_civil's gap and overlap, as Time::Keeper::Zone's ABI numbers them. */
#define TIME_KEEPER_GAP_FAIL      0   /* return TIME_KEEPER_GAP */
#define TIME_KEEPER_GAP_FORWARD   1
#define TIME_KEEPER_GAP_BACKWARD  2
#define TIME_KEEPER_OVERLAP_LATER   0
#define TIME_KEEPER_OVERLAP_EARLIER 1   /* Time::Keeper's default */

typedef struct time_keeper_instant {
    int64_t sec;
    int32_t nsec;
} time_keeper_instant;

typedef struct time_keeper_zone {
    int     kind;                       /* TIME_KEEPER_ZONE_ */
    int32_t value;                      /* the offset, or the zone's id */
} time_keeper_zone;

typedef struct time_keeper_civil {
    int64_t year;
    int     month, day;                 /* 1 .. 12, 1 .. 31 */
    int     hour, minute, second;       /* second 60 only in a leap second */
    int32_t nanosecond;
    /* filled by civil, read by nothing: */
    int     day_of_week;                /* 1 Monday .. 7 Sunday */
    int     day_of_year;                /* 1 .. 366 */
    int32_t offset;                     /* seconds east of UTC */
    int     is_dst;
} time_keeper_civil;

typedef struct time_keeper_calfields {
    int     calendar;                   /* from calendar_find; 0 the Gregorian */
    int64_t year;                       /* the calendar's continuous year */
    int64_t era_year;                   /* the year within the era */
    int     era;                        /* an index into the calendar's eras, in Time::Keeper::Calendar->eras' order */
    int     month, day;                 /* the ordinal month, 1 .. months_in_year; the day */
    int     month_number;               /* the number in the month code: M05 and M05L are both 5 */
    int     leap_month, leap_year;
    int     months_in_year, days_in_month, days_in_year, day_of_year;
    int     hour, minute, second;       /* second 60 only in a leap second */
    int32_t nanosecond;
    /* filled by cal_fields, read by nothing: */
    int32_t offset;                     /* seconds east of UTC */
    int     is_dst;
} time_keeper_calfields;

typedef struct time_keeper_abi {
    int abi_version;

    /* The current time, to the nanosecond where the system gives it. */
    int    (*now)(time_keeper_instant *out);

    /* A zone by name, as the Perl methods take one: an IANA name or link,
     * "UTC", "floating", "local", or an offset such as "+05:30". */
    int    (*zone_parse)(pTHX_ const char *name, size_t len, time_keeper_zone *out);

    /* An instant's wall clock in a zone. */
    int    (*civil)(pTHX_ const time_keeper_instant *in, const time_keeper_zone *zone,
                    time_keeper_civil *out);

    /* The instant a wall clock in a zone shows. gap and overlap choose, as
     * the Perl methods' arguments do; TIME_KEEPER_GAP if gap is _FAIL and
     * the time fell in one. */
    int    (*from_civil)(pTHX_ const time_keeper_civil *in, const time_keeper_zone *zone,
                         int gap, int overlap, time_keeper_instant *out);

    /* strftime and a CLDR pattern, as the methods of those names write them,
     * in a locale. Patterns are UTF-8, and so is what is written. */
    size_t (*strftime)(pTHX_ char *buf, size_t len, const char *pattern, size_t plen,
                       const time_keeper_instant *in, const time_keeper_zone *zone, int locale);
    size_t (*format)(pTHX_ char *buf, size_t len, const char *pattern, size_t plen,
                     const time_keeper_instant *in, const time_keeper_zone *zone, int locale);

    /* RFC 3339 with the offset, or Z in UTC, and the fewest of 0, 3, 6 or 9
     * fraction digits that are exact: the method iso8601's form. */
    size_t (*iso8601)(pTHX_ char *buf, size_t len, const time_keeper_instant *in,
                      const time_keeper_zone *zone);

    /* RFC 9110's date, "Thu, 15 Oct 2026 09:05:07 GMT": always 29 bytes. */
    size_t (*http_date)(char *buf, size_t len, const time_keeper_instant *in);

    /* What the method parse reads: ISO 8601, RFC 3339 and 9557, the mail
     * and HTTP forms, "@epoch". Text with no zone is read in UTC. */
    int    (*parse)(pTHX_ const char *s, size_t len, time_keeper_instant *out, time_keeper_zone *zone);

    /* A locale's id by its code, any case, _ for -; -1 if none. */
    int    (*locale_find)(const char *code, size_t len);

    /* A Time::Keeper value with a reference count of one, which the caller
     * owns; NULL if an argument is out of range. */
    SV *   (*new_sv)(pTHX_ const time_keeper_instant *in, const time_keeper_zone *zone, int locale);

    /* A Time::Keeper value's instant, zone and locale; any pointer may be
     * NULL. TIME_KEEPER_BAD if sv is not one. */
    int    (*from_sv)(pTHX_ SV *sv, time_keeper_instant *out, time_keeper_zone *zone, int *locale);

    /* TAI minus UTC at an instant, in seconds: 10 in 1972 to 37 since 2017.
     * TIME_KEEPER_RANGE before 1972. */
    int    (*tai_minus_utc)(const time_keeper_instant *in, int *out);

    /* ---- version 2 ---- */

    /* A calendar's id by its id string or an alias ("hebrew", "gregorian",
     * "iso8601", "islamicc"), any case; -1 if none. */
    int    (*calendar_find)(const char *id, size_t len);

    /* The id string of a calendar; TIME_KEEPER_BAD if there is no such id. */
    int    (*calendar_id)(int calendar, const char **out);

    /* An instant's wall clock in a zone, read in a calendar. */
    int    (*cal_fields)(pTHX_ const time_keeper_instant *in, const time_keeper_zone *zone, int calendar,
                         time_keeper_calfields *out);

    /* The instant a calendar's wall clock shows: calendar, year, month, day
     * and the clock are read, the rest ignored; gap and overlap as from_civil. */
    int    (*cal_from_fields)(pTHX_ const time_keeper_calfields *in, const time_keeper_zone *zone,
                              int gap, int overlap, time_keeper_instant *out);

    /* format and strftime with the value read in a calendar. */
    size_t (*format_cal)(pTHX_ char *buf, size_t len, const char *pattern, size_t plen,
                         const time_keeper_instant *in, const time_keeper_zone *zone, int locale, int calendar);
    size_t (*strftime_cal)(pTHX_ char *buf, size_t len, const char *pattern, size_t plen,
                           const time_keeper_instant *in, const time_keeper_zone *zone, int locale, int calendar);

    /* new_sv and from_sv with the calendar: a value read in one, and the
     * calendar a value is read in (0 for one version 1 made). */
    SV *   (*new_sv_cal)(pTHX_ const time_keeper_instant *in, const time_keeper_zone *zone, int locale, int calendar);
    int    (*from_sv_cal)(pTHX_ SV *sv, time_keeper_instant *out, time_keeper_zone *zone, int *locale, int *calendar);
} time_keeper_abi;

#endif
