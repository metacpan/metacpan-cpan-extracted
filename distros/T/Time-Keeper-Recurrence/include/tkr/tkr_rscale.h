#ifndef TKR_RSCALE_H
#define TKR_RSCALE_H

/* RFC 7529: a rule walked in another calendar. A period is the calendar's
 * year or month, or a week or day as anywhere; a day is read in the
 * calendar for its month (the number in its month code and whether it is
 * the leap month), its day of the month and of the year, and the size of
 * both. BYMONTH holds month-code numbers, with a second mask for the leap
 * months ("5L"). SKIP moves a month the year does not have (a leap month
 * in a common year) back to the month it follows or on to the next, then a
 * day its month does not have back to the month's last day or on to the
 * first of the next month; OMIT, the default, drops them. A day moved on
 * to the next month belongs to the period of the month it came from.
 *
 * Days are Gregorian day numbers throughout, read in the calendar at noon
 * UTC, so the calendar's day is the civil day the walk already counts. */


/* A month of the calendar, as the walk keeps it. */
typedef struct tkr_calmonth_s tkr_calmonth;

/* A day read in a calendar. */
static int
tkr_cal_fields_of_day(pTHX_ int cal, int64_t day, time_keeper_calfields *f)
{
    time_keeper_instant t;
    time_keeper_zone utc;
    t.sec = day * 86400 + 43200;
    t.nsec = 0;
    utc.kind = TIME_KEEPER_ZONE_UTC;
    utc.value = 0;
    return (tkr_tk(aTHX)->cal_fields)(aTHX_ &t, &utc, cal, f) == TIME_KEEPER_OK;
}

/* The day a calendar's year, ordinal month and day fall on. */
static int
tkr_cal_day_of(pTHX_ int cal, int64_t year, int ord, int dom, int64_t *day)
{
    time_keeper_calfields f;
    time_keeper_instant t;
    time_keeper_zone utc;
    memset(&f, 0, sizeof f);
    f.calendar = cal;
    f.year = year;
    f.month = ord;
    f.day = dom;
    f.hour = 12;
    utc.kind = TIME_KEEPER_ZONE_UTC;
    utc.value = 0;
    if ((tkr_tk(aTHX)->cal_from_fields)(aTHX_ &f, &utc, TIME_KEEPER_GAP_FORWARD, TIME_KEEPER_OVERLAP_EARLIER, &t) != TIME_KEEPER_OK)
        return 0;
    *day = tkr_floor_div(t.sec, 86400);
    return 1;
}

/* The month holding a day, through the walk's two-month cache. */
static int
tkr_cal_month(pTHX_ tkr_walk *w, int64_t day, tkr_calmonth *out)
{
    time_keeper_calfields f;
    tkr_calmonth *m;
    int i;
    for (i = 0; i < 2; i++)
        if (w->cm_ok[i] && day >= w->cm[i].first && day < w->cm[i].first + w->cm[i].dim) {
            *out = w->cm[i];
            return 1;
        }
    if (!tkr_cal_fields_of_day(aTHX_ w->rule.calendar, day, &f))
        return 0;
    i = w->cm_next;
    w->cm_next = !w->cm_next;
    m = &w->cm[i];
    m->first = day - (f.day - 1);
    m->year = f.year;
    m->dim = f.days_in_month;
    m->ord = f.month;
    m->mnum = f.month_number;
    m->leap = f.leap_month != 0;
    m->miy = f.months_in_year;
    m->diy = f.days_in_year;
    m->yday1 = f.day_of_year - (f.day - 1);
    w->cm_ok[i] = 1;
    *out = *m;
    return 1;
}

/* The months of a calendar year, cached for the last year asked. */
static int
tkr_cal_year(pTHX_ tkr_walk *w, int64_t year, int *miy, uint16_t *leaps)
{
    int64_t day;
    int i;
    if (w->cy_ok && w->cy_year == year) {
        if (miy) *miy = w->cy_miy;
        if (leaps) *leaps = w->cy_leaps;
        return 1;
    }
    if (!tkr_cal_day_of(aTHX_ w->rule.calendar, year, 1, 1, &day))
        return 0;
    w->cy_leaps = 0;
    w->cy_miy = 0;
    for (i = 0; i < 16; i++) {
        time_keeper_calfields f;
        if (!tkr_cal_fields_of_day(aTHX_ w->rule.calendar, day, &f) || f.year != year)
            break;
        w->cy_miy = f.months_in_year;
        if (f.leap_month && f.month_number >= 0 && f.month_number < 16)
            w->cy_leaps |= (uint16_t)(1u << f.month_number);
        day += f.days_in_month;
    }
    w->cy_year = year;
    w->cy_ok = 1;
    if (miy) *miy = w->cy_miy;
    if (leaps) *leaps = w->cy_leaps;
    return w->cy_miy > 0;
}

/* Is a month (by its code) one the rule wants in a year, a skipped leap
 * month moved onto it included. */
static int
tkr_cal_month_ok(pTHX_ tkr_walk *w, int64_t year, int mnum, int leap)
{
    const tkr_rule *r = &w->rule;
    uint32_t reg, lp;
    uint16_t has = 0;
    if (r->by_month || r->by_month_leap) {
        reg = r->by_month;
        lp = r->by_month_leap;
    }
    else if (w->month_default) {
        reg = w->c_leap ? 0 : 1u << w->c_mnum;
        lp = w->c_leap ? 1u << w->c_mnum : 0;
    }
    else
        return 1;
    if (leap)
        return (lp & (1u << mnum)) != 0;
    if (reg & (1u << mnum))
        return 1;
    if (r->skip == TKR_SKIP_OMIT || !lp)
        return 0;
    if (r->skip == TKR_SKIP_BACKWARD && (lp & (1u << mnum))) {
        tkr_cal_year(aTHX_ w, year, NULL, &has);
        return !(has & (1u << mnum));
    }
    if (r->skip == TKR_SKIP_FORWARD && mnum > 1 && (lp & (1u << (mnum - 1)))) {
        tkr_cal_year(aTHX_ w, year, NULL, &has);
        return !(has & (1u << (mnum - 1)));
    }
    return 0;
}

/* The greatest day of the month the rule asks for, 0 if it asks none. */
static int
tkr_cal_md_max(const tkr_walk *w)
{
    const tkr_rule *r = &w->rule;
    int i;
    if (r->by_monthday) {
        for (i = 31; i >= 1; i--)
            if (r->by_monthday & (UINT64_C(1) << i))
                return i;
        return 0;
    }
    return w->day_default == TKR_DD_MONTHDAY ? w->c_dom : 0;
}

/* The day filter in the calendar. mode 0: the day itself only; 1: also a
 * day moved on from the month before; 2: only such a moved day. */
static int
tkr_cal_day_ok(pTHX_ tkr_walk *w, int64_t day, int mode)
{
    const tkr_rule *r = &w->rule;
    tkr_calmonth m;
    int dom, yday, wday, mok, fwd = 0, has_md, md_ok = 1, wd_ok = 1, has_wd = 0, mdmax;
    if (!tkr_cal_month(aTHX_ w, day, &m))
        return 0;
    dom = (int)(day - m.first) + 1;
    yday = m.yday1 + dom - 1;
    wday = (int)tkr_weekday(day) - 1;
    has_md = r->by_monthday || w->day_default == TKR_DD_MONTHDAY;
    mdmax = tkr_cal_md_max(w);
    mok = mode != 2 && tkr_cal_month_ok(aTHX_ w, m.year, m.mnum, m.leap);
    if (mode && r->skip == TKR_SKIP_FORWARD && has_md && dom == 1) {
        tkr_calmonth p;
        if (tkr_cal_month(aTHX_ w, day - 1, &p) && mdmax > p.dim && tkr_cal_month_ok(aTHX_ w, p.year, p.mnum, p.leap))
            fwd = 1;
    }
    if (!mok && !fwd)
        return 0;
    if (r->n_yearday && !tkr_in_list16(r->by_yearday, r->n_yearday, yday) && !tkr_in_list16(r->by_yearday, r->n_yearday, yday - m.diy - 1))
        return 0;
    if (has_md) {
        int direct = r->by_monthday
            ? ((r->by_monthday & (UINT64_C(1) << dom)) || (m.dim - dom + 1 <= 31 && (r->by_monthday & (UINT64_C(1) << (32 + (m.dim - dom + 1))))))
            : dom == w->c_dom;
        int back = r->skip == TKR_SKIP_BACKWARD && dom == m.dim && mdmax > m.dim;
        md_ok = (mok && (direct || back)) || fwd;
    }
    if (tkr_has_by_day(r)) {
        has_wd = 1;
        wd_ok = (r->by_day_any & (1u << wday)) != 0;
        if (!wd_ok && (r->by_day_pos[wday] || r->by_day_neg[wday])) {
            int in_year = r->freq == TKR_YEARLY && !r->by_month && !r->by_month_leap;
            unsigned pos = in_year ? (unsigned)(yday - 1) / 7 + 1 : (unsigned)(dom - 1) / 7 + 1;
            unsigned neg = in_year ? (unsigned)(m.diy - yday) / 7 + 1 : (unsigned)(m.dim - dom) / 7 + 1;
            wd_ok = (pos <= 53 && (r->by_day_pos[wday] & (UINT64_C(1) << pos))) || (neg <= 53 && (r->by_day_neg[wday] & (UINT64_C(1) << neg)));
        }
    }
    if (has_md && has_wd)
        return md_ok && wd_ok;
    if (has_md)
        return md_ok;
    if (has_wd)
        return wd_ok;
    if (w->day_default == TKR_DD_WEEKDAY)
        return wday == w->s_wday;
    return 1;
}

/* The ordinal month n months on (or back) from a calendar year and month. */
static int
tkr_cal_month_add(pTHX_ tkr_walk *w, int64_t year, int ord, int64_t n, int64_t *oyear, int *oord)
{
    int miy;
    while (n > 0) {
        if (!tkr_cal_year(aTHX_ w, year, &miy, NULL))
            return 0;
        if (ord + n <= miy) {
            ord += (int)n;
            n = 0;
        }
        else {
            n -= miy - ord + 1;
            year++;
            ord = 1;
        }
    }
    while (n < 0) {
        if (ord + n >= 1) {
            ord += (int)n;
            n = 0;
        }
        else {
            n += ord;
            year--;
            if (!tkr_cal_year(aTHX_ w, year, &miy, NULL))
                return 0;
            ord = miy;
        }
    }
    *oyear = year;
    *oord = ord;
    return 1;
}

/* The calendar's period k: its first day and the first day of the next.
 * A month is found from the last one asked, so a walk forward or back
 * steps one month at a time. */
static int
tkr_cal_period(pTHX_ tkr_walk *w, int64_t k, int64_t *d0, int64_t *d1)
{
    const tkr_rule *r = &w->rule;
    int64_t step = (int64_t)r->interval * k;
    if (r->freq == TKR_YEARLY) {
        if (!tkr_cal_day_of(aTHX_ r->calendar, w->c_year + step, 1, 1, d0) || !tkr_cal_day_of(aTHX_ r->calendar, w->c_year + step + 1, 1, 1, d1))
            return 0;
        return 1;
    }
    else {
        int64_t y;
        int ord;
        tkr_calmonth m;
        if (!w->mc_ok) {
            w->mc_step = 0;
            w->mc_year = w->c_year;
            w->mc_ord = w->c_ord;
            w->mc_ok = 1;
        }
        if (!tkr_cal_month_add(aTHX_ w, w->mc_year, w->mc_ord, step - w->mc_step, &y, &ord))
            return 0;
        w->mc_step = step;
        w->mc_year = y;
        w->mc_ord = ord;
        if (!tkr_cal_day_of(aTHX_ r->calendar, y, ord, 1, d0) || !tkr_cal_month(aTHX_ w, *d0, &m))
            return 0;
        *d1 = *d0 + m.dim;
        return 1;
    }
}

/* The calendar period a day falls in, never before the start's. */
static int64_t
tkr_cal_k_of(pTHX_ tkr_walk *w, int64_t day)
{
    const tkr_rule *r = &w->rule;
    tkr_calmonth m;
    int64_t n = 0, y;
    int miy;
    if (!tkr_cal_month(aTHX_ w, day, &m) || m.year < w->c_year)
        return 0;
    if (r->freq == TKR_YEARLY)
        return tkr_floor_div(m.year - w->c_year, r->interval);
    for (y = w->c_year; y < m.year; y++) {
        if (!tkr_cal_year(aTHX_ w, y, &miy, NULL))
            return 0;
        n += miy;
    }
    n += m.ord - w->c_ord;
    return n < 0 ? 0 : tkr_floor_div(n, r->interval);
}

/* The start read in the rule's calendar. */
static void
tkr_cal_start(pTHX_ tkr_walk *w)
{
    time_keeper_calfields f;
    const tkr_rule *r = &w->rule;
    if ((tkr_tk(aTHX)->cal_fields)(aTHX_ &r->start, &r->zone, r->calendar, &f) != TIME_KEEPER_OK)
        croak("Time::Keeper::Recurrence: the start cannot be read in the rule's calendar");
    w->c_year = f.year;
    w->c_ord = f.month;
    w->c_mnum = f.month_number;
    w->c_leap = f.leap_month != 0;
    w->c_dom = f.day;
}

#endif
