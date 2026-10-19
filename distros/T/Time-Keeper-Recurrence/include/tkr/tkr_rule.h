#ifndef TKR_RULE_H
#define TKR_RULE_H

/* One compiled rule, whatever spelling it came from: an RFC 5545 RRULE, a
 * cron expression or named arguments. The walk (tkr_walk.h) reads only
 * this. Masks are bit sets; the lists that can hold any of hundreds of
 * values are short arrays with a count. Weekdays are 0 Monday .. 6 Sunday
 * inside the struct, 1 .. 7 at the surface, as Time::Keeper has them. */

#define TKR_SECONDLY 0
#define TKR_MINUTELY 1
#define TKR_HOURLY   2
#define TKR_DAILY    3
#define TKR_WEEKLY   4
#define TKR_MONTHLY  5
#define TKR_YEARLY   6

#define TKR_F_VIXIE     0x01   /* cron: a day matching EITHER restricted day field fires */
#define TKR_F_EVERY     0x02   /* cron @every: an interval from the last occurrence */
#define TKR_F_HAS_START 0x04   /* start holds the rule's start */
#define TKR_F_CRON      0x08   /* came through the cron door: from is exclusive, the start is no occurrence */
#define TKR_F_EXRULE    0x10   /* an exclusion: the start is an occurrence only when it fits */
#define TKR_F_RSCALE    0x20   /* RFC 7529: walked in calendar (0 the Gregorian, with SKIP) */

#define TKR_UNTIL_NONE     0
#define TKR_UNTIL_UTC      1   /* an instant */
#define TKR_UNTIL_FLOATING 2   /* a wall time, seconds as if UTC */
#define TKR_UNTIL_DATE     3   /* a day, the end of it in the rule's zone */

#define TKR_GAP_FORWARD  0
#define TKR_GAP_BACKWARD 1
#define TKR_GAP_SKIP     2
#define TKR_GAP_FAIL     3

#define TKR_OVERLAP_EARLIER 0
#define TKR_OVERLAP_LATER   1
#define TKR_OVERLAP_BOTH    2

#define TKR_SKIP_OMIT     0
#define TKR_SKIP_BACKWARD 1
#define TKR_SKIP_FORWARD  2

static const char *const tkr_skip_names[3] = { "omit", "backward", "forward" };
static const char *const tkr_skip_upper[3] = { "OMIT", "BACKWARD", "FORWARD" };

#define TKR_MAX_LIST 64

typedef struct tkr_rule {
    uint8_t  freq;
    uint8_t  wkst;                 /* 0 Monday .. 6 Sunday */
    uint8_t  flags;
    uint8_t  until_kind;
    uint8_t  gap, overlap;
    uint8_t  calendar;             /* with RSCALE: Time::Keeper's calendar id, 0 the Gregorian */
    uint8_t  skip;                 /* with RSCALE: TKR_SKIP_OMIT, BACKWARD or FORWARD */
    uint32_t interval;
    int64_t  count;                /* 0: none */
    int64_t  until_sec;
    uint64_t by_second;            /* bits 0 .. 60 */
    uint64_t by_minute;            /* bits 0 .. 59 */
    uint32_t by_hour;              /* bits 0 .. 23 */
    uint64_t by_monthday;          /* bits 1 .. 31 for 1 .. 31, bits 33 .. 63 for -1 .. -31 */
    uint16_t by_month;             /* bits 1 .. 12; with RSCALE, month-code numbers 1 .. 13 */
    uint16_t by_month_leap;        /* with RSCALE: the leap months, "5L" as bit 5 */
    uint8_t  by_day_any;           /* bits 0 .. 6: the weekday with no ordinal */
    uint64_t by_day_pos[7];        /* bits 1 .. 53: the nth such weekday */
    uint64_t by_day_neg[7];        /* bits 1 .. 53: the nth from the end */
    int16_t  by_yearday[TKR_MAX_LIST];
    int8_t   by_weekno[TKR_MAX_LIST];
    int16_t  by_setpos[TKR_MAX_LIST];
    uint8_t  n_yearday, n_weekno, n_setpos;
    int64_t  every_sec;
    time_keeper_instant start;
    time_keeper_zone    zone;
    int                 locale;
} tkr_rule;

static const char *const tkr_freq_names[7] = { "SECONDLY", "MINUTELY", "HOURLY", "DAILY", "WEEKLY", "MONTHLY", "YEARLY" };
static const char *const tkr_freq_lower[7] = { "secondly", "minutely", "hourly", "daily", "weekly", "monthly", "yearly" };
static const char *const tkr_day_names[7]  = { "MO", "TU", "WE", "TH", "FR", "SA", "SU" };
static const char *const tkr_gap_names[4]  = { "forward", "backward", "skip", "fail" };
static const char *const tkr_overlap_names[3] = { "earlier", "later", "both" };

static void
tkr_rule_init(tkr_rule *r)
{
    memset(r, 0, sizeof *r);
    r->interval = 1;
    r->zone.kind = TIME_KEEPER_ZONE_UTC;
}

/* True when a BY part is set, for the RFC's rules about which may meet. */
static int tkr_has_by_day(const tkr_rule *r)
{
    int i;
    if (r->by_day_any)
        return 1;
    for (i = 0; i < 7; i++)
        if (r->by_day_pos[i] || r->by_day_neg[i])
            return 1;
    return 0;
}

static int tkr_has_by_day_ordinal(const tkr_rule *r)
{
    int i;
    for (i = 0; i < 7; i++)
        if (r->by_day_pos[i] || r->by_day_neg[i])
            return 1;
    return 0;
}

static int tkr_has_any_by(const tkr_rule *r)
{
    return r->by_second || r->by_minute || r->by_hour || r->by_monthday || r->by_month
        || tkr_has_by_day(r) || r->n_yearday || r->n_weekno;
}

static int tkr_is_finite(const tkr_rule *r)
{
    return r->count > 0 || r->until_kind != TKR_UNTIL_NONE;
}

/* A sorted, deduplicated short list. */
static int
tkr_list_add(int16_t *list, uint8_t *n, int v)
{
    int i, j;
    for (i = 0; i < *n; i++) {
        if (list[i] == v)
            return 1;
        if (list[i] > v)
            break;
    }
    if (*n >= TKR_MAX_LIST)
        return 0;
    for (j = *n; j > i; j--)
        list[j] = list[j - 1];
    list[i] = (int16_t)v;
    (*n)++;
    return 1;
}

static int
tkr_list8_add(int8_t *list, uint8_t *n, int v)
{
    int i, j;
    for (i = 0; i < *n; i++) {
        if (list[i] == v)
            return 1;
        if (list[i] > v)
            break;
    }
    if (*n >= TKR_MAX_LIST)
        return 0;
    for (j = *n; j > i; j--)
        list[j] = list[j - 1];
    list[i] = (int8_t)v;
    (*n)++;
    return 1;
}

#endif
