#ifndef TKR_WALK_H
#define TKR_WALK_H

/* The walk: RFC 5545's recurrence as a two-step machine. A period is a
 * second, minute, hour, day, week, month or year, INTERVAL of them apart,
 * counted from the start's period; inside a period the BY parts expand
 * (a list of hours gives every one) or limit (a list of months keeps only
 * days in them), in the RFC's table, and BYSETPOS keeps the nth of what is
 * left. A day that does not exist (31 April, 30 February) is dropped, never
 * moved. The start counts as the first occurrence whether or not it fits
 * the rule, as the RFC says of COUNT.
 *
 * The expansion is an AND of filters over the days of the period (month,
 * week number, day of year, day of month, weekday with its ordinal), with
 * the start's own month, day or weekday standing in where a rule gives
 * none, and a product of the hour, minute and second lists over each day
 * kept. A cron reads its two day fields as either (TKR_F_VIXIE). Wall
 * times are then made instants by tkr_resolve. */

#define TKR_MAX_CAND     100000   /* candidates in one period */
#define TKR_EMPTY_DAYS_CRON  1830   /* days with nothing in them before "can never fire": a cron's five years, Punk::Queue's contract */
#define TKR_EMPTY_DAYS_RULE 18263   /* a rule's fifty years: a daily rule on a Wednesday the 14th of May waits six */
#define TKR_BETWEEN_MAX 10000000

#define TKR_FILL_SKIP 2       /* tkr_fill: nothing until the period in *skip_to, the same day or the next */

#define TKR_DD_NONE   0
#define TKR_DD_MONTHDAY 1    /* the start's day of the month (and its month, when no BYMONTH) */
#define TKR_DD_WEEKDAY  2    /* the start's weekday */

typedef struct tkr_pending {
    int64_t inst, wall, first;   /* the later reading, its wall time, the earlier reading */
} tkr_pending;

typedef struct tkr_walk {
    tkr_rule  rule;              /* the walk's own copy: an iterator outlives the object it came from */
    const tkr_rule *r;
    int       cron, has_start;
    int64_t   s_inst;            /* the start's instant and its wall fields in the rule's zone */
    int32_t   s_nsec;
    int64_t   s_wall, s_days, s_year, s_week0, s_unit;
    unsigned  s_month, s_dom;
    int       s_h, s_m, s_s, s_wday;
    uint64_t  by_second, by_minute;
    uint32_t  by_hour;
    int       day_default, month_default;
    int64_t   k;                 /* the period being read */
    int64_t  *cand;              /* the period's candidate wall times */
    int       ncand, ccap, ci;
    int64_t  *inst, *instw;      /* the period's occurrences as instants, in order, and their wall times */
    int       ninst, icap, ii, ended;
    tkr_pending *pend;           /* second readings of doubled wall times, by instant */
    int       npend, pcap;
    int64_t   last_wall;         /* the wall time of the last occurrence given out */
    int64_t   fail_wall;         /* the skipped wall time, on TKR_W_FAIL */
    int64_t   cur_day;           /* for a rule stepping hours, minutes or seconds: the day being read, and whether it gave anything */
    int       cur_day_had;
    int64_t   last;              /* the last instant given out, so the start is not given twice */
    int64_t   emitted;           /* occurrences given out, for COUNT */
    int64_t   empty;
    int       started;           /* the start has been given out (or passed) */
    int       done;
    int       no_skip;           /* walking back: read every period, take no jump forward */
    /* a rule in another calendar (RFC 7529): the start read in it, the
     * last month period found, the last two months and the last year read */
    int64_t   c_year;
    int       c_ord, c_mnum, c_leap, c_dom;
    int       mc_ok, mc_ord;
    int64_t   mc_step, mc_year;
    struct tkr_calmonth_s { int64_t first, year; int dim, ord, mnum, leap, miy, diy, yday1; } cm[2];
    int       cm_ok[2], cm_next;
    int       cy_ok, cy_miy;
    int64_t   cy_year;
    uint16_t  cy_leaps;
} tkr_walk;

static int64_t tkr_floor_div(int64_t a, int64_t b) { int64_t q = a / b; return (a % b != 0 && ((a < 0) != (b < 0))) ? q - 1 : q; }

/* How many days an empty period of the rule stands for, toward the cap. */
static int64_t tkr_period_days(const tkr_rule *r) { return r->freq == TKR_YEARLY ? 366 : r->freq == TKR_MONTHLY ? 31 : r->freq == TKR_WEEKLY ? 7 : 1; }
static int64_t tkr_empty_cap(const tkr_rule *r) { return (r->flags & TKR_F_CRON) ? TKR_EMPTY_DAYS_CRON : TKR_EMPTY_DAYS_RULE; }


/* ---- the days of a period ------------------------------------------------- */

typedef struct tkr_dayinfo {
    int64_t  year;
    unsigned month, dom, dim, yday, diy;
    int      wday;               /* 0 Monday .. 6 Sunday */
} tkr_dayinfo;

static void
tkr_dayinfo_of(int64_t day, tkr_dayinfo *d)
{
    tkr_civil_from_days(day, &d->year, &d->month, &d->dom);
    d->dim = tkr_days_in_month(d->year, d->month);
    d->yday = (unsigned)(day - tkr_days_from_civil(d->year, 1, 1) + 1);
    d->diy = tkr_is_leap(d->year) ? 366 : 365;
    d->wday = (int)tkr_weekday(day) - 1;
}

/* The first day of week 1 of a year, weeks starting on wkst: the week that
 * holds 4 January. */
static int64_t
tkr_week1(int64_t year, int wkst)
{
    int64_t jan4 = tkr_days_from_civil(year, 1, 4);
    int w = (int)tkr_weekday(jan4) - 1;
    return jan4 - ((w - wkst + 7) % 7);
}

/* The week number of a day, 1 to 53, and the year the week belongs to. */
static int
tkr_weekno(int64_t day, int wkst, int64_t *wyear, int *weeks_in_year)
{
    tkr_dayinfo d;
    int64_t w1;
    tkr_dayinfo_of(day, &d);
    w1 = tkr_week1(d.year, wkst);
    if (day < w1) {
        *wyear = d.year - 1;
        w1 = tkr_week1(d.year - 1, wkst);
    }
    else if (day >= tkr_week1(d.year + 1, wkst)) {
        *wyear = d.year + 1;
        w1 = tkr_week1(d.year + 1, wkst);
    }
    else
        *wyear = d.year;
    *weeks_in_year = (int)((tkr_week1(*wyear + 1, wkst) - w1) / 7);
    return (int)((day - w1) / 7) + 1;
}

static int
tkr_in_list16(const int16_t *list, unsigned n, int v)
{
    unsigned i;
    for (i = 0; i < n; i++)
        if (list[i] == v)
            return 1;
    return 0;
}

/* Does the day pass the rule's day filters, in a period whose year is
 * pyear (for the ordinal of a weekday within the year). */
static int
tkr_day_ok(const tkr_walk *w, int64_t day, int64_t pyear)
{
    const tkr_rule *r = w->r;
    tkr_dayinfo d;
    int md_ok = 1, wd_ok = 1, has_md = 0, has_wd = 0;
    tkr_dayinfo_of(day, &d);
    if (r->by_month) {
        if (!(r->by_month & (1u << d.month)))
            return 0;
    }
    else if (w->month_default && d.month != w->s_month)
        return 0;
    if (r->n_weekno) {
        int64_t wy;
        int wiy, i, ok = 0;
        int no = tkr_weekno(day, r->wkst, &wy, &wiy);
        if (wy != pyear)
            return 0;
        for (i = 0; i < r->n_weekno; i++)
            if (r->by_weekno[i] == no || (r->by_weekno[i] < 0 && wiy + 1 + r->by_weekno[i] == no)) { ok = 1; break; }
        if (!ok)
            return 0;
    }
    if (r->n_yearday) {
        if (!tkr_in_list16(r->by_yearday, r->n_yearday, (int)d.yday) && !tkr_in_list16(r->by_yearday, r->n_yearday, (int)d.yday - (int)d.diy - 1))
            return 0;
    }
    if (r->by_monthday) {
        has_md = 1;
        md_ok = (r->by_monthday & (UINT64_C(1) << d.dom)) || (r->by_monthday & (UINT64_C(1) << (32 + (d.dim - d.dom + 1))));
    }
    if (tkr_has_by_day(r)) {
        has_wd = 1;
        wd_ok = (r->by_day_any & (1u << d.wday)) != 0;
        if (!wd_ok && (r->by_day_pos[d.wday] || r->by_day_neg[d.wday])) {
            int in_year = r->freq == TKR_YEARLY && !r->by_month;
            unsigned pos = in_year ? (d.yday - 1) / 7 + 1 : (d.dom - 1) / 7 + 1;
            unsigned neg = in_year ? (d.diy - d.yday) / 7 + 1 : (d.dim - d.dom) / 7 + 1;
            wd_ok = (pos <= 53 && (r->by_day_pos[d.wday] & (UINT64_C(1) << pos))) || (neg <= 53 && (r->by_day_neg[d.wday] & (UINT64_C(1) << neg)));
        }
    }
    if (has_md && has_wd)
        return (r->flags & TKR_F_VIXIE) ? (md_ok || wd_ok) : (md_ok && wd_ok);
    if (has_md)
        return md_ok;
    if (has_wd)
        return wd_ok;
    switch (w->day_default) {
    case TKR_DD_MONTHDAY: return d.dom == w->s_dom;
    case TKR_DD_WEEKDAY:  return d.wday == w->s_wday;
    default:              return 1;
    }
}

#include "tkr_rscale.h"

/* ---- periods ------------------------------------------------------------- */

/* The period k: its first and last+1 day for a day-level frequency, or
 * the absolute unit (hour, minute or second since 1970) for a sub-day one. */
static void
tkr_period(pTHX_ const tkr_walk *w, int64_t k, int64_t *d0, int64_t *d1, int64_t *pyear, int64_t *unit)
{
    const tkr_rule *r = w->r;
    int64_t step = (int64_t)r->interval * k;
    if ((r->flags & TKR_F_RSCALE) && (r->freq == TKR_YEARLY || r->freq == TKR_MONTHLY)) {
        *pyear = 0;
        *unit = 0;
        if (!tkr_cal_period(aTHX_ (tkr_walk *)w, k, d0, d1))
            *d0 = *d1 = 0;
        return;
    }
    switch (r->freq) {
    case TKR_YEARLY:
        *pyear = w->s_year + step;
        *d0 = tkr_days_from_civil(*pyear, 1, 1);
        *d1 = tkr_days_from_civil(*pyear + 1, 1, 1);
        break;
    case TKR_MONTHLY: {
        int64_t mi = w->s_year * 12 + (w->s_month - 1) + step, y = tkr_floor_div(mi, 12);
        unsigned m = (unsigned)(mi - y * 12) + 1;
        *pyear = y;
        *d0 = tkr_days_from_civil(y, m, 1);
        *d1 = m == 12 ? tkr_days_from_civil(y + 1, 1, 1) : tkr_days_from_civil(y, m + 1, 1);
        break;
    }
    case TKR_WEEKLY:
        *d0 = w->s_week0 + 7 * step;
        *d1 = *d0 + 7;
        *pyear = 0;
        break;
    case TKR_DAILY:
        *d0 = w->s_days + step;
        *d1 = *d0 + 1;
        *pyear = 0;
        break;
    default:
        *unit = w->s_unit + step;
        *d0 = *d1 = 0;
        *pyear = 0;
        break;
    }
}

/* The period a wall time falls in, never before the start's. */
static int64_t
tkr_k_of(pTHX_ const tkr_walk *w, int64_t wall)
{
    const tkr_rule *r = w->r;
    int64_t day = tkr_floor_div(wall, 86400), k = 0, y;
    unsigned m, d;
    if ((r->flags & TKR_F_RSCALE) && (r->freq == TKR_YEARLY || r->freq == TKR_MONTHLY))
        return tkr_cal_k_of(aTHX_ (tkr_walk *)w, day);
    switch (r->freq) {
    case TKR_YEARLY:
        tkr_civil_from_days(day, &y, &m, &d);
        k = tkr_floor_div(y - w->s_year, r->interval);
        break;
    case TKR_MONTHLY:
        tkr_civil_from_days(day, &y, &m, &d);
        k = tkr_floor_div(y * 12 + (m - 1) - (w->s_year * 12 + (w->s_month - 1)), r->interval);
        break;
    case TKR_WEEKLY: {
        int wd = (int)tkr_weekday(day) - 1;
        int64_t w0 = day - ((wd - r->wkst + 7) % 7);
        k = tkr_floor_div((w0 - w->s_week0) / 7, r->interval);
        break;
    }
    case TKR_DAILY:    k = tkr_floor_div(day - w->s_days, r->interval); break;
    case TKR_HOURLY:   k = tkr_floor_div(tkr_floor_div(wall, 3600) - w->s_unit, r->interval); break;
    case TKR_MINUTELY: k = tkr_floor_div(tkr_floor_div(wall, 60) - w->s_unit, r->interval); break;
    default:           k = tkr_floor_div(wall - w->s_unit, r->interval); break;
    }
    return k < 0 ? 0 : k;
}

/* ---- candidates --------------------------------------------------------- */

static void
tkr_cand_push(pTHX_ tkr_walk *w, int64_t wall)
{
    if (w->ncand >= w->ccap) {
        if (w->ccap >= TKR_MAX_CAND)
            croak("Time::Keeper::Recurrence: more than %d occurrences in one period of the rule", TKR_MAX_CAND);
        w->ccap = w->ccap ? w->ccap * 4 : 64;
        if (w->ccap > TKR_MAX_CAND)
            w->ccap = TKR_MAX_CAND;
        Renew(w->cand, w->ccap, int64_t);
    }
    w->cand[w->ncand++] = wall;
}

/* Every time of a day the rule's hour, minute and second lists give. */
static void
tkr_push_times(pTHX_ tkr_walk *w, int64_t day, uint32_t hours, uint64_t minutes, uint64_t seconds)
{
    int h, m, s;
    for (h = 0; h < 24; h++) {
        if (!(hours & (1u << h)))
            continue;
        for (m = 0; m < 60; m++) {
            if (!(minutes & (UINT64_C(1) << m)))
                continue;
            for (s = 0; s <= 60; s++)
                if (seconds & (UINT64_C(1) << s))
                    tkr_cand_push(aTHX_ w, day * 86400 + h * 3600 + m * 60 + s);
        }
    }
}

/* Fills the period's candidates, sorted. Returns 0 for a sub-day period
 * whose day the rule does not want, with *skip_to the first period of the
 * next day. */
static int
tkr_fill(pTHX_ tkr_walk *w, int64_t k, int64_t *skip_to)
{
    const tkr_rule *r = w->r;
    int64_t d0, d1, pyear, unit = 0, day;
    w->ncand = 0;
    w->ci = 0;
    tkr_period(aTHX_ w, k, &d0, &d1, &pyear, &unit);
    if (r->freq >= TKR_DAILY && (r->flags & TKR_F_RSCALE)) {
        /* a calendar's year or month also takes the day moved on from its last month */
        int ym = r->freq == TKR_YEARLY || r->freq == TKR_MONTHLY;
        int64_t end = d1 + (ym && d1 > d0 && r->skip == TKR_SKIP_FORWARD);
        for (day = d0; day < end; day++)
            if (tkr_cal_day_ok(aTHX_ w, day, !ym ? 1 : day == d0 ? 0 : day == d1 ? 2 : 1))
                tkr_push_times(aTHX_ w, day, w->by_hour, w->by_minute, w->by_second);
    }
    else if (r->freq >= TKR_DAILY) {
        for (day = d0; day < d1; day++)
            if (tkr_day_ok(w, day, pyear))
                tkr_push_times(aTHX_ w, day, w->by_hour, w->by_minute, w->by_second);
    }
    else {
        int64_t per_day = r->freq == TKR_HOURLY ? 24 : r->freq == TKR_MINUTELY ? 1440 : 86400;
        int h, m, s;
        day = tkr_floor_div(unit, per_day);
        if ((r->flags & TKR_F_RSCALE) ? !tkr_cal_day_ok(aTHX_ w, day, 1) : !tkr_day_ok(w, day, 0)) {
            int64_t next_unit = (day + 1) * per_day;
            *skip_to = k + tkr_floor_div(next_unit - unit + r->interval - 1, r->interval);
            return 0;
        }
        if (r->interval == 1 && !w->no_skip && (r->freq == TKR_HOURLY || r->freq == TKR_MINUTELY)) {
            /* an hour or minute the rule does not want: on to the next it does, as a cron's masks say */
            int64_t target = -1;
            int h2, m2;
            if (r->freq == TKR_HOURLY) {
                h = (int)(unit - day * 24);
                if (r->by_hour && !(r->by_hour & (1u << h))) {
                    for (h2 = h + 1; h2 < 24 && !(r->by_hour & (1u << h2)); h2++) ;
                    target = h2 < 24 ? day * 24 + h2 : (day + 1) * 24;
                }
            }
            else {
                int64_t sod = unit - day * 1440;
                h = (int)(sod / 60);
                m = (int)(sod % 60);
                if (r->by_hour && !(r->by_hour & (1u << h))) {
                    for (h2 = h + 1; h2 < 24 && !(r->by_hour & (1u << h2)); h2++) ;
                    target = h2 < 24 ? day * 1440 + h2 * 60 : (day + 1) * 1440;
                }
                else if (r->by_minute && !(r->by_minute & (UINT64_C(1) << m))) {
                    for (m2 = m + 1; m2 < 60 && !(r->by_minute & (UINT64_C(1) << m2)); m2++) ;
                    if (m2 < 60)
                        target = day * 1440 + h * 60 + m2;
                    else {
                        for (h2 = h + 1; h2 < 24 && r->by_hour && !(r->by_hour & (1u << h2)); h2++) ;
                        target = h2 < 24 ? day * 1440 + h2 * 60 : (day + 1) * 1440;
                    }
                }
            }
            if (target > unit) {
                *skip_to = k + (target - unit);
                return TKR_FILL_SKIP;
            }
        }
        if (r->freq == TKR_HOURLY) {
            h = (int)(unit - day * 24);
            if (!r->by_hour || (r->by_hour & (1u << h)))
                tkr_push_times(aTHX_ w, day, 1u << h, w->by_minute, w->by_second);
        }
        else if (r->freq == TKR_MINUTELY) {
            int64_t sod = unit - day * 1440;
            h = (int)(sod / 60);
            m = (int)(sod % 60);
            if ((!r->by_hour || (r->by_hour & (1u << h))) && (!r->by_minute || (r->by_minute & (UINT64_C(1) << m))))
                tkr_push_times(aTHX_ w, day, 1u << h, UINT64_C(1) << m, w->by_second);
        }
        else {
            int64_t sod = unit - day * 86400;
            h = (int)(sod / 3600);
            m = (int)(sod % 3600 / 60);
            s = (int)(sod % 60);
            if ((!r->by_hour || (r->by_hour & (1u << h))) && (!r->by_minute || (r->by_minute & (UINT64_C(1) << m)))
                && (!r->by_second || (r->by_second & (UINT64_C(1) << s))))
                tkr_cand_push(aTHX_ w, day * 86400 + sod);
        }
    }
    if (r->n_setpos && w->ncand) {
        int i, kept = 0;
        for (i = 0; i < w->ncand; i++) {
            int pos = i + 1, neg = i - w->ncand;
            if (tkr_in_list16(r->by_setpos, r->n_setpos, pos) || tkr_in_list16(r->by_setpos, r->n_setpos, neg))
                w->cand[kept++] = w->cand[i];
        }
        w->ncand = kept;
    }
    return 1;
}

/* ---- the walk --------------------------------------------------------------- */

#define TKR_W_END   0    /* the rule has ended */
#define TKR_W_GOT   1
#define TKR_W_NEVER -1   /* the rule can never fire: nothing within the cap */
#define TKR_W_FAIL  -2   /* a skipped wall time, and the rule says fail */

/* Set up to give occurrences in order from the period holding from_wall
 * (a wall time) or, for a rule with COUNT, from the start, since the count
 * must be taken from there. */
static void
tkr_walk_init(pTHX_ tkr_walk *w, const tkr_rule *rule, int64_t from_wall, int from_start)
{
    const tkr_rule *r;
    time_keeper_civil c;
    memset(w, 0, sizeof *w);
    w->rule = *rule;
    w->r = r = &w->rule;
    w->cron = (r->flags & TKR_F_CRON) != 0;
    w->has_start = (r->flags & TKR_F_HAS_START) != 0;
    if (w->has_start) {
        w->s_inst = r->start.sec;
        w->s_nsec = r->start.nsec;
        w->s_wall = tkr_wall_of(aTHX_ r, r->start.sec, &c);
        w->s_year = c.year; w->s_month = (unsigned)c.month; w->s_dom = (unsigned)c.day;
        w->s_h = c.hour; w->s_m = c.minute; w->s_s = c.second;
    }
    else {
        /* a cron with no start counts its periods from 1970 */
        w->s_wall = 0;
        w->s_year = 1970; w->s_month = 1; w->s_dom = 1;
        w->s_h = w->s_m = w->s_s = 0;
    }
    w->s_days = tkr_floor_div(w->s_wall, 86400);
    w->s_wday = (int)tkr_weekday(w->s_days) - 1;
    w->s_week0 = w->s_days - ((w->s_wday - r->wkst + 7) % 7);
    w->s_unit = r->freq == TKR_HOURLY ? tkr_floor_div(w->s_wall, 3600) : r->freq == TKR_MINUTELY ? tkr_floor_div(w->s_wall, 60) : w->s_wall;
    /* the RFC's defaults: the start's clock where the rule gives none, the
     * start's day or weekday where a day-level rule gives no day part */
    w->by_hour = r->by_hour ? r->by_hour : r->freq > TKR_HOURLY ? (1u << w->s_h) : 0;
    w->by_minute = r->by_minute ? r->by_minute : r->freq > TKR_MINUTELY ? (UINT64_C(1) << w->s_m) : 0;
    w->by_second = r->by_second ? r->by_second : r->freq > TKR_SECONDLY ? (UINT64_C(1) << w->s_s) : 0;
    if (w->cron)
        w->by_second = r->by_second ? r->by_second : 1;   /* a cron fires on the minute */
    w->day_default = TKR_DD_NONE;
    w->month_default = 0;
    if (r->freq >= TKR_WEEKLY && !w->cron) {
        int any_day = r->n_weekno || r->n_yearday || r->by_monthday || tkr_has_by_day(r);
        if (!any_day) {
            if (r->freq == TKR_WEEKLY)
                w->day_default = TKR_DD_WEEKDAY;
            else {
                w->day_default = TKR_DD_MONTHDAY;
                if (r->freq == TKR_YEARLY && !r->by_month && !r->by_month_leap)
                    w->month_default = 1;
            }
        }
    }
    if (r->flags & TKR_F_RSCALE)
        tkr_cal_start(aTHX_ w);
    w->k = from_start || r->count ? 0 : tkr_k_of(aTHX_ w, from_wall);
    if (w->k > 0 && (r->flags & TKR_F_RSCALE) && r->skip == TKR_SKIP_FORWARD && (r->freq == TKR_YEARLY || r->freq == TKR_MONTHLY))
        w->k--;                                     /* a day moved on to the 1st belongs to the period before */
    w->started = !(w->has_start && !w->cron) || (r->flags & TKR_F_EXRULE) != 0;     /* an RRULE gives its start first; an exclusion does not */
    w->last = INT64_MIN;
    w->last_wall = INT64_MIN;
    w->cur_day = INT64_MIN;
}

static void
tkr_walk_free(tkr_walk *w)
{
    if (w->cand)
        Safefree(w->cand);
    if (w->inst)
        Safefree(w->inst);
    if (w->instw)
        Safefree(w->instw);
    if (w->pend)
        Safefree(w->pend);
    w->cand = w->inst = NULL;
    w->pend = NULL;
}

/* Does an instant (with its wall time) fall within UNTIL. */
static int
tkr_within_until(const tkr_rule *r, int64_t inst, int64_t wall)
{
    switch (r->until_kind) {
    case TKR_UNTIL_UTC:      return inst <= r->until_sec;
    case TKR_UNTIL_FLOATING: return wall <= r->until_sec;
    case TKR_UNTIL_DATE:     return wall < r->until_sec + 86400;
    default:                 return 1;
    }
}

/* The second reading of a doubled wall time waits here until its instant
 * comes round, so occurrences come out in order even when a wall time's
 * later reading is after the next wall time's earlier one. */
static void
tkr_pend_push(pTHX_ tkr_walk *w, int64_t inst, int64_t wall, int64_t first)
{
    int i, j;
    if (w->npend >= w->pcap) {
        w->pcap = w->pcap ? w->pcap * 2 : 16;
        Renew(w->pend, w->pcap, tkr_pending);
    }
    for (i = 0; i < w->npend && w->pend[i].inst <= inst; i++) ;
    for (j = w->npend; j > i; j--)
        w->pend[j] = w->pend[j - 1];
    w->pend[i].inst = inst;
    w->pend[i].wall = wall;
    w->pend[i].first = first;
    w->npend++;
}

/* The period k as instants in order, in w->inst: its candidates on or
 * after the start's wall time, resolved by the rule's gap and overlap
 * choices, cut at UNTIL (w->ended says so); a doubled wall time's second
 * reading goes to the pending list. TKR_W_GOT with a filled list (possibly
 * empty), 0 with *skip_to for a sub-day period on a day the rule does not
 * want, TKR_W_FAIL (with w->fail_wall) for a skipped wall time the rule
 * will not have. */
static int
tkr_fill_instants(pTHX_ tkr_walk *w, int64_t k, int64_t *skip_to, int64_t *day)
{
    const tkr_rule *r = w->r;
    int i;
    w->ninst = 0;
    w->ended = 0;
    if (r->freq < TKR_DAILY) {
        int64_t d0, d1, py, unit, per_day = r->freq == TKR_HOURLY ? 24 : r->freq == TKR_MINUTELY ? 1440 : 86400;
        tkr_period(aTHX_ w, k, &d0, &d1, &py, &unit);
        *day = tkr_floor_div(unit, per_day);
    }
    else
        *day = 0;
    {
        int fr = tkr_fill(aTHX_ w, k, skip_to);
        if (fr != 1)
            return fr;
    }
    if (w->icap < w->ccap + 2) {
        w->icap = w->ccap + 2;
        Renew(w->inst, w->icap, int64_t);
        Renew(w->instw, w->icap, int64_t);
    }
    for (i = 0; i < w->ncand; i++) {
        int64_t wall = w->cand[i], out[2];
        int n;
        if (w->has_start && wall < w->s_wall)
            continue;
        n = tkr_resolve(aTHX_ r, wall, out);
        if (n < 0) {
            w->fail_wall = wall;
            return TKR_W_FAIL;
        }
        if (n == 0)
            continue;
        if (w->has_start && w->cron && out[0] <= w->s_inst) {
            if (n < 2 || out[1] <= w->s_inst)
                continue;                           /* a cron's start is a bound, never an occurrence */
            out[0] = out[1];
            n = 1;
        }
        if (!tkr_within_until(r, out[0], wall)) {
            w->ended = 1;
            return TKR_W_GOT;
        }
        w->inst[w->ninst] = out[0];
        w->instw[w->ninst++] = wall;
        if (n == 2 && tkr_within_until(r, out[1], wall))
            tkr_pend_push(aTHX_ w, out[1], wall, out[0]);
    }
    return TKR_W_GOT;
}

/* The next occurrence in order, as an instant. */
static int
tkr_walk_next(pTHX_ tkr_walk *w, int64_t *inst)
{
    const tkr_rule *r = w->r;
    if (w->done)
        return TKR_W_END;
    if (r->count && w->emitted >= r->count) {
        w->done = 1;
        return TKR_W_END;
    }
    if (!w->started) {                              /* the start itself, first */
        w->started = 1;
        if (tkr_within_until(r, w->s_inst, w->s_wall)) {
            w->emitted++;
            w->last = w->s_inst;
            w->last_wall = w->s_wall;
            *inst = w->s_inst;
            return TKR_W_GOT;
        }
        w->done = 1;
        return TKR_W_END;
    }
    for (;;) {
        int64_t got, wall;
        int from_pend = 0;
        if (w->ii >= w->ninst) {
            if (w->ended) {
                if (!w->npend) {
                    w->done = 1;
                    return TKR_W_END;
                }
                from_pend = 1;
            }
            else {
                int64_t skip_to = 0, day;
                int rc;
                if (w->empty >= tkr_empty_cap(r))
                    return TKR_W_NEVER;
                rc = tkr_fill_instants(aTHX_ w, w->k, &skip_to, &day);
                if (rc == TKR_W_FAIL)
                    return rc;
                w->ii = 0;
                if (rc == TKR_FILL_SKIP) {              /* on to the next hour or minute the rule wants */
                    if (day != w->cur_day) {
                        if (w->cur_day != INT64_MIN && !w->cur_day_had)
                            w->empty++;
                        w->cur_day = day;
                        w->cur_day_had = 0;
                    }
                    w->k = skip_to;
                    continue;
                }
                if (rc == 0) {                          /* a whole day the rule does not want */
                    w->empty++;
                    w->k = skip_to;
                    continue;
                }
                if (r->freq < TKR_DAILY) {              /* count days that gave nothing, not periods */
                    if (day != w->cur_day) {
                        if (w->cur_day != INT64_MIN && !w->cur_day_had)
                            w->empty++;
                        w->cur_day = day;
                        w->cur_day_had = 0;
                    }
                    if (w->ninst)
                        w->cur_day_had = 1;
                }
                else if (w->ninst == 0)
                    w->empty += tkr_period_days(r);
                w->k++;
                if (w->ii >= w->ninst && !(w->npend && w->ended))
                    continue;
            }
        }
        if (!from_pend && w->npend && (w->ii >= w->ninst || w->pend[0].inst <= w->inst[w->ii]))
            from_pend = 1;
        if (from_pend) {
            got = w->pend[0].inst;
            wall = w->pend[0].wall;
            w->npend--;
            memmove(w->pend, w->pend + 1, (size_t)w->npend * sizeof *w->pend);
        }
        else {
            got = w->inst[w->ii];
            wall = w->instw[w->ii];
            w->ii++;
        }
        if (w->has_start && !w->cron && got <= w->last)
            continue;                               /* the start, already given, or a candidate before it */
        if (w->cron && from_pend && wall == w->last_wall)
            continue;                               /* a pinned wall minute fires once in a doubled hour; a sweep every real minute */
        w->empty = 0;
        w->emitted++;
        w->last = got;
        w->last_wall = wall;
        *inst = got;
        return TKR_W_GOT;
    }
}

/* A cron in UTC, a fixed offset or floating time has no clock change to
 * walk round, so its next occurrence is found from its masks directly: the
 * next day its day fields allow, then the next hour and minute. A cron has
 * no ordinals, year days, week numbers or seconds; its start is a bound. */
static int
tkr_cron_day_ok(const tkr_rule *r, int64_t day)
{
    int64_t y;
    unsigned m, d;
    int md = -1, wd = -1;
    tkr_civil_from_days(day, &y, &m, &d);
    if (r->by_month && !(r->by_month & (1u << m)))
        return 0;
    if (r->by_monthday)
        md = (r->by_monthday & (UINT64_C(1) << d)) != 0;
    if (r->by_day_any)
        wd = (r->by_day_any & (1u << (tkr_weekday(day) - 1))) != 0;
    if (md >= 0 && wd >= 0)
        return (r->flags & TKR_F_VIXIE) ? (md || wd) : (md && wd);
    return md >= 0 ? md : wd >= 0 ? wd : 1;
}

static int
tkr_cron_fast_ok(const tkr_rule *r)
{
    return (r->flags & TKR_F_CRON) && !(r->flags & TKR_F_EVERY) && r->zone.kind != TIME_KEEPER_ZONE_NAMED
        && !r->n_yearday && !r->n_weekno && !r->n_setpos && !tkr_has_by_day_ordinal(r)
        && (!r->by_second || r->by_second == 1) && r->interval == 1 && !r->count && r->until_kind == TKR_UNTIL_NONE;
}

static int
tkr_cron_fast_next(const tkr_rule *r, int64_t from, int inclusive, int64_t *inst)
{
    int64_t off = r->zone.kind == TIME_KEEPER_ZONE_FIXED ? r->zone.value : 0, mins, day, n;
    int mod;
    if ((r->flags & TKR_F_HAS_START) && from <= r->start.sec) {
        from = r->start.sec;                        /* a cron's start is a bound, never an occurrence */
        inclusive = 0;
    }
    mins = tkr_floor_div(from + off, 60);
    if (!inclusive || (from + off) - mins * 60 != 0)
        mins++;                                     /* the first whole minute strictly after */
    day = tkr_floor_div(mins, 1440);
    mod = (int)(mins - day * 1440);
    for (n = 0; n <= TKR_EMPTY_DAYS_CRON; n++, day++, mod = 0) {
        int h, m;
        if (!tkr_cron_day_ok(r, day))
            continue;
        for (h = mod / 60; h < 24; h++) {
            if (r->by_hour && !(r->by_hour & (1u << h)))
                continue;
            for (m = h == mod / 60 ? mod % 60 : 0; m < 60; m++)
                if (!r->by_minute || (r->by_minute & (UINT64_C(1) << m))) {
                    *inst = (day * 1440 + h * 60 + m) * 60 - off;
                    return TKR_W_GOT;
                }
        }
    }
    return TKR_W_NEVER;
}

/* The first occurrence strictly after an instant (or at it, when
 * inclusive). The walk starts as far before it in wall time as a clock
 * change near it needs (tkr_lookback): a wall time's instant can be up to
 * that much later than the wall time says, and a doubled wall time's
 * second reading is later still. */
static int
tkr_next_after(pTHX_ const tkr_rule *r, int64_t from, int inclusive, int64_t *inst, int64_t *detail)
{
    tkr_walk w;
    int64_t got, from_wall;
    int rc;
    if (tkr_cron_fast_ok(r))
        return tkr_cron_fast_next(r, from, inclusive, inst);
    from_wall = tkr_wall_of(aTHX_ r, from, NULL);
    tkr_walk_init(aTHX_ &w, r, from_wall - tkr_lookback(aTHX_ r, from), 0);
    while ((rc = tkr_walk_next(aTHX_ &w, &got)) == TKR_W_GOT) {
        if (got > from || (inclusive && got == from)) {
            *inst = got;
            break;
        }
    }
    if (rc == TKR_W_FAIL && detail)
        *detail = w.fail_wall;
    tkr_walk_free(&w);
    return rc;
}

/* The last occurrence strictly before an instant: the periods walked back
 * from the one holding it, each resolved in order and read from its end;
 * a doubled wall time's second reading counts for a cron only when
 * another occurrence lies between the two readings. A rule with COUNT is
 * walked from its start. */
static int
tkr_previous_before(pTHX_ const tkr_rule *r, int64_t from, int64_t *inst, int64_t *detail)
{
    tkr_walk w;
    int64_t got, best = INT64_MIN, from_wall = tkr_wall_of(aTHX_ r, from, NULL), k, empty = 0, lb, limit = INT64_MIN;
    int found = 0, rc = TKR_W_END;
    if (r->count) {
        tkr_walk_init(aTHX_ &w, r, from_wall, 1);
        while ((rc = tkr_walk_next(aTHX_ &w, &got)) == TKR_W_GOT && got < from) {
            best = got;
            found = 1;
        }
        if (rc == TKR_W_FAIL && detail)
            *detail = w.fail_wall;
        tkr_walk_free(&w);
        if (rc < 0)
            return rc;
        if (found)
            *inst = best;
        return found ? TKR_W_GOT : TKR_W_END;
    }
    lb = tkr_lookback(aTHX_ r, from);
    tkr_walk_init(aTHX_ &w, r, from_wall + lb, 0);
    w.k = tkr_k_of(aTHX_ &w, from_wall + lb);    /* walking back starts in the period itself */
    for (k = w.k; k >= 0; k--) {
        int64_t skip_to, day;
        int i;
        if (empty >= tkr_empty_cap(r)) {
            tkr_walk_free(&w);
            return TKR_W_NEVER;
        }
        w.npend = 0;
        w.no_skip = 1;
        rc = tkr_fill_instants(aTHX_ &w, k, &skip_to, &day);
        if (rc == TKR_W_FAIL) {
            if (detail)
                *detail = w.fail_wall;
            tkr_walk_free(&w);
            return rc;
        }
        if (rc == 0) {
            /* a sub-day period on a day the rule does not want: back to the last period of the day before */
            int64_t per_day = r->freq == TKR_HOURLY ? 24 : r->freq == TKR_MINUTELY ? 1440 : 86400, d0, d1, py, unit;
            tkr_period(aTHX_ &w, k, &d0, &d1, &py, &unit);
            k -= tkr_floor_div(unit - tkr_floor_div(unit, per_day) * per_day, r->interval);
            empty++;
            continue;
        }
        if (r->freq < TKR_DAILY) {
            if (day != w.cur_day) {
                if (w.cur_day != INT64_MIN && !w.cur_day_had)
                    empty++;
                w.cur_day = day;
                w.cur_day_had = 0;
            }
            if (w.ninst)
                w.cur_day_had = 1;
        }
        else if (w.ninst == 0)
            empty += tkr_period_days(r);
        /* the period's second readings count too, each after its first */
        for (i = w.npend - 1; i >= 0; i--) {
            int64_t second = w.pend[i].inst, first = w.pend[i].first, between;
            if (second >= from || second <= best)
                continue;
            if (w.cron) {
                int rc2 = tkr_next_after(aTHX_ r, first, 0, &between, NULL);
                if (rc2 != TKR_W_GOT || between >= second)
                    continue;                       /* nothing between the two readings: the pinned minute fired once */
            }
            best = second;
            found = 1;
        }
        for (i = w.ninst - 1; i >= 0; i--)
            if (w.inst[i] < from) {
                if (w.inst[i] > best) {
                    best = w.inst[i];
                    found = 1;
                }
                break;
            }
        if (found) {
            /* near a clock change an earlier wall time can be a later instant (the
             * second reading of a doubled hour): walk back until no wall time can */
            int64_t d0, d1, py, unit, pstart;
            if (!lb)
                break;
            if (limit == INT64_MIN)
                limit = tkr_wall_of(aTHX_ r, best, NULL) - lb;
            tkr_period(aTHX_ &w, k, &d0, &d1, &py, &unit);
            pstart = r->freq >= TKR_DAILY ? d0 * 86400
                   : r->freq == TKR_HOURLY ? unit * 3600 : r->freq == TKR_MINUTELY ? unit * 60 : unit;
            if (pstart < limit)
                break;
        }
    }
    if (w.has_start && !w.cron && w.s_inst < from && (!found || w.s_inst > best)
        && tkr_within_until(r, w.s_inst, w.s_wall)) {
        best = w.s_inst;
        found = 1;
    }
    tkr_walk_free(&w);
    if (found)
        *inst = best;
    return found ? TKR_W_GOT : TKR_W_END;
}

/* Can the rule fire at all: an RRULE's start is its first occurrence
 * unless UNTIL is before it; a cron must have an occurrence within five
 * years of now. 1, or 0 with err. */
static int
tkr_can_fire(pTHX_ const tkr_rule *r, int64_t now, char *err)
{
    int64_t got;
    if (r->flags & TKR_F_EVERY)
        return 1;
    if (!(r->flags & TKR_F_CRON)) {
        if (!tkr_within_until(r, r->start.sec, tkr_wall_of(aTHX_ r, r->start.sec, NULL))) {
            tkr_err(err, "the rule can never fire: UNTIL is before the start");
            return 0;
        }
        return 1;
    }
    if (tkr_next_after(aTHX_ r, now, 0, &got, NULL) != TKR_W_GOT) {
        tkr_err(err, "can never fire (no occurrence within five years)");
        return 0;
    }
    return 1;
}

#endif
