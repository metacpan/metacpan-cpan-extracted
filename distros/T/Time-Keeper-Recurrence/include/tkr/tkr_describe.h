#ifndef TKR_DESCRIBE_H
#define TKR_DESCRIBE_H

/* A rule in English words, from the compiled rule, so a cron, an RRULE and
 * the named arguments read the same: "At 09:00, Monday to Friday", "Every
 * 15 minutes from 09:00 to 17:45", "On the first Monday of every month",
 * "On the last day of every month, 12 times". The rule's own spelling is
 * not consulted. A part the words do not cover reads as its numbers, never
 * as nothing. */

static const char *const tkr_d_day[7] = { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" };
static const char *const tkr_d_month[13] = { "", "January", "February", "March", "April", "May", "June", "July",
                                             "August", "September", "October", "November", "December" };
static const char *const tkr_d_nth[6] = { "", "first", "second", "third", "fourth", "fifth" };

#define TKR_D_ITEMS 64
#define TKR_D_ITEM  48

typedef struct tkr_d_list {
    char item[TKR_D_ITEMS][TKR_D_ITEM];
    int n;
} tkr_d_list;

static void
tkr_d_add(tkr_d_list *l, const char *fmt, ...)
{
    va_list ap;
    if (l->n >= TKR_D_ITEMS)
        return;
    va_start(ap, fmt);
    vsnprintf(l->item[l->n], TKR_D_ITEM, fmt, ap);
    va_end(ap);
    l->n++;
}

/* "a", "a and b", "a, b and c" */
static void
tkr_d_join(pTHX_ SV *out, const tkr_d_list *l, const char *last)
{
    int i;
    for (i = 0; i < l->n; i++) {
        if (i)
            sv_catpv(out, i == l->n - 1 ? last : ", ");
        sv_catpv(out, l->item[i]);
    }
}

static int
tkr_d_bits(uint64_t m)
{
    int n = 0;
    for (; m; m &= m - 1)
        n++;
    return n;
}

static int
tkr_d_lowest(uint64_t m, int lo, int hi)
{
    int v;
    for (v = lo; v <= hi; v++)
        if (m & (UINT64_C(1) << v))
            return v;
    return -1;
}

static int
tkr_d_highest(uint64_t m, int lo, int hi)
{
    int v;
    for (v = hi; v >= lo; v--)
        if (m & (UINT64_C(1) << v))
            return v;
    return -1;
}

/* The mask is every value from lo to hi. */
static int
tkr_d_full(uint64_t m, int lo, int hi)
{
    int v;
    for (v = lo; v <= hi; v++)
        if (!(m & (UINT64_C(1) << v)))
            return 0;
    return 1;
}

/* One run a..b with nothing else: 1 with *a and *b. */
static int
tkr_d_run(uint64_t m, int lo, int hi, int *a, int *b)
{
    int f = tkr_d_lowest(m, lo, hi), l = tkr_d_highest(m, lo, hi), v;
    if (f < 0)
        return 0;
    for (v = f; v <= l; v++)
        if (!(m & (UINT64_C(1) << v)))
            return 0;
    *a = f;
    *b = l;
    return 1;
}

/* Every step-th value from the first to the end of lo..hi: 1 with the step
 * and the first. A single value is no step. The minutes' caller asks for a
 * first of 0 ("every 15 minutes" is :00, :15, :30, :45). */
static int
tkr_d_step(uint64_t m, int lo, int hi, int *step, int *first)
{
    int f = tkr_d_lowest(m, lo, hi), s = -1, v, n = tkr_d_bits(m);
    if (n < 2)
        return 0;
    for (v = f + 1; v <= hi; v++)
        if (m & (UINT64_C(1) << v)) { s = v - f; break; }
    if (s < 2)
        return 0;
    for (v = lo; v <= hi; v++) {
        int want = v >= f && (v - f) % s == 0;
        if (want != !!(m & (UINT64_C(1) << v)))
            return 0;
    }
    *step = s;
    *first = f;
    return 1;
}

static void
tkr_d_ordinal(char *buf, size_t n, int v)
{
    const char *suf = "th";
    int t = v % 100;
    if (t < 11 || t > 13) {
        if (v % 10 == 1) suf = "st";
        else if (v % 10 == 2) suf = "nd";
        else if (v % 10 == 3) suf = "rd";
    }
    snprintf(buf, n, "%d%s", v, suf);
}

/* "first" .. "fifth", "53rd"; from the end "last", "second to last". */
static void
tkr_d_nth_word(char *buf, size_t n, int v)
{
    char o[16];
    if (v > 0 && v <= 5) { snprintf(buf, n, "%s", tkr_d_nth[v]); return; }
    if (v == -1) { snprintf(buf, n, "last"); return; }
    if (v < 0 && v >= -5) { snprintf(buf, n, "%s to last", tkr_d_nth[-v]); return; }
    tkr_d_ordinal(o, sizeof o, v < 0 ? -v : v);
    snprintf(buf, n, v < 0 ? "%s to last" : "%s", o);
}

/* ---- the time of day ------------------------------------------------------ */

static void
tkr_d_every(pTHX_ SV *out, unsigned n, const char *one, const char *many)
{
    if (n == 1) sv_catpvf(out, "every %s", one);
    else sv_catpvf(out, "every %u %s", n, many);
}

/* The minutes within an hour: "every minute", "every 15 minutes", "on the
 * hour", "at 15 minutes past the hour", "at 0, 15 and 45 minutes past". */
static void
tkr_d_minutes(pTHX_ SV *out, const tkr_rule *r)
{
    uint64_t m = r->by_minute;
    int step, first, v;
    if (!m || tkr_d_full(m, 0, 59)) {
        if (r->freq == TKR_MINUTELY && !m) tkr_d_every(aTHX_ out, r->interval, "minute", "minutes");
        else sv_catpvs(out, "every minute");
        return;
    }
    if (tkr_d_step(m, 0, 59, &step, &first) && first == 0 && 60 % step == 0) {
        sv_catpvf(out, "every %d minutes", step);
        return;
    }
    if (tkr_d_bits(m) == 1) {
        v = tkr_d_lowest(m, 0, 59);
        if (v == 0) sv_catpvs(out, "on the hour");
        else sv_catpvf(out, "at %d minute%s past the hour", v, v == 1 ? "" : "s");
        return;
    }
    {
        tkr_d_list l;
        l.n = 0;
        for (v = 0; v <= 59; v++)
            if (m & (UINT64_C(1) << v))
                tkr_d_add(&l, "%d", v);
        sv_catpvs(out, "at ");
        tkr_d_join(aTHX_ out, &l, " and ");
        sv_catpvs(out, " minutes past the hour");
    }
}

static void
tkr_d_seconds(pTHX_ SV *out, const tkr_rule *r)
{
    uint64_t s = r->by_second;
    int v;
    tkr_d_list l;
    if (!s || (tkr_d_bits(s) == 1 && (s & 1)))
        return;
    l.n = 0;
    for (v = 0; v <= 60; v++)
        if (s & (UINT64_C(1) << v))
            tkr_d_add(&l, "%d", v);
    sv_catpvf(out, ", at second%s ", l.n == 1 ? "" : "s");
    tkr_d_join(aTHX_ out, &l, " and ");
}

/* The time of day, or nothing when the rule takes it from its start. 1 when
 * something was written. */
static int
tkr_d_time(pTHX_ SV *out, const tkr_rule *r)
{
    uint64_t h = r->by_hour, m = r->by_minute;
    int nh = tkr_d_bits(h), nm = tkr_d_bits(m), a, b, step, first;
    STRLEN at = SvCUR(out);

    if (r->freq == TKR_SECONDLY && !r->by_second && !m && !h) {
        tkr_d_every(aTHX_ out, r->interval, "second", "seconds");
        return 1;
    }
    if (r->freq == TKR_HOURLY && !h) {
        tkr_d_every(aTHX_ out, r->interval, "hour", "hours");
        if (m) { sv_catpvs(out, ", "); tkr_d_minutes(aTHX_ out, r); }
        tkr_d_seconds(aTHX_ out, r);
        return 1;
    }
    if (!h && !m && r->freq >= TKR_DAILY)
        return 0;                                       /* the start's time */

    /* a few times of day: "at 09:00 and 17:30" */
    if (nh && nm && nh * nm <= 6) {
        tkr_d_list l;
        int hh, mm;
        l.n = 0;
        for (hh = 0; hh <= 23; hh++)
            if (h & (1u << hh))
                for (mm = 0; mm <= 59; mm++)
                    if (m & (UINT64_C(1) << mm))
                        tkr_d_add(&l, "%02d:%02d", hh, mm);
        sv_catpvs(out, "at ");
        tkr_d_join(aTHX_ out, &l, " and ");
        tkr_d_seconds(aTHX_ out, r);
        return 1;
    }
    if (!h || tkr_d_full(h, 0, 23)) {                   /* every hour of the day */
        if (nm == 1)
            sv_catpvs(out, "every hour, ");
        tkr_d_minutes(aTHX_ out, r);
        tkr_d_seconds(aTHX_ out, r);
        return 1;
    }
    if (tkr_d_step(h, 0, 23, &step, &first)) {          /* every 2 hours */
        sv_catpvf(out, "every %d hours", step);
        if (first) sv_catpvf(out, " from %02d:00", first);
        if (nm == 1) {
            int v = tkr_d_lowest(m, 0, 59);
            if (v == 0) sv_catpvs(out, ", on the hour");
            else sv_catpvf(out, ", at %d minute%s past", v, v == 1 ? "" : "s");
        }
        else { sv_catpvs(out, ", "); tkr_d_minutes(aTHX_ out, r); }
        tkr_d_seconds(aTHX_ out, r);
        return 1;
    }
    if (tkr_d_run(h, 0, 23, &a, &b)) {                  /* from 09:00 to 17:45 */
        int mlo = m ? tkr_d_lowest(m, 0, 59) : 0, mhi = m ? tkr_d_highest(m, 0, 59) : 59;
        if (!m && r->freq == TKR_MINUTELY && r->interval > 1 && 60 % r->interval == 0)
            mhi = 60 - (int)r->interval;                /* every 20 minutes: the last at :40 */
        if (nm == 1) sv_catpvs(out, "every hour");
        else tkr_d_minutes(aTHX_ out, r);
        sv_catpvf(out, " from %02d:%02d to %02d:%02d", a, mlo, b, mhi);
        tkr_d_seconds(aTHX_ out, r);
        return 1;
    }
    {                                                   /* in the hours 9, 12 and 18 */
        tkr_d_list l;
        int v;
        l.n = 0;
        for (v = 0; v <= 23; v++)
            if (h & (1u << v))
                tkr_d_add(&l, "%02d", v);
        tkr_d_minutes(aTHX_ out, r);
        sv_catpvs(out, " in the hours ");
        tkr_d_join(aTHX_ out, &l, " and ");
        tkr_d_seconds(aTHX_ out, r);
    }
    return SvCUR(out) > at;
}

/* ---- the days --------------------------------------------------------------- */

/* The weekdays with no ordinal: "Monday to Friday", "Saturday and Sunday",
 * "Monday, Wednesday and Friday". */
static void
tkr_d_weekdays(pTHX_ SV *out, unsigned w)
{
    int a, b, v;
    tkr_d_list l;
    if (tkr_d_run(w, 0, 6, &a, &b) && b - a >= 2) {
        sv_catpvf(out, "%s to %s", tkr_d_day[a], tkr_d_day[b]);
        return;
    }
    l.n = 0;
    for (v = 0; v < 7; v++)
        if (w & (1u << v))
            tkr_d_add(&l, "%s", tkr_d_day[v]);
    tkr_d_join(aTHX_ out, &l, " and ");
}

/* The ordinal weekdays: "the first Monday", "the second and fourth Tuesday",
 * "the last Friday". 1 when there were any. */
static int
tkr_d_ordinals(pTHX_ SV *out, const tkr_rule *r)
{
    tkr_d_list l;
    int w, i;
    l.n = 0;
    for (w = 0; w < 7; w++) {
        tkr_d_list nths;
        char buf[TKR_D_ITEM];
        SV *tmp;
        nths.n = 0;
        for (i = 1; i <= 53; i++)
            if (r->by_day_pos[w] & (UINT64_C(1) << i)) { tkr_d_nth_word(buf, sizeof buf, i); tkr_d_add(&nths, "%s", buf); }
        for (i = 53; i >= 1; i--)
            if (r->by_day_neg[w] & (UINT64_C(1) << i)) { tkr_d_nth_word(buf, sizeof buf, -i); tkr_d_add(&nths, "%s", buf); }
        if (!nths.n)
            continue;
        tmp = sv_2mortal(newSVpvs(""));
        tkr_d_join(aTHX_ tmp, &nths, " and ");
        tkr_d_add(&l, "%s %s", SvPV_nolen(tmp), tkr_d_day[w]);
    }
    if (!l.n)
        return 0;
    sv_catpvs(out, "the ");
    tkr_d_join(aTHX_ out, &l, " and the ");
    return 1;
}

/* The days of the month: "the 1st and 15th", "the last day". */
static void
tkr_d_monthdays(pTHX_ SV *out, uint64_t md)
{
    tkr_d_list l;
    char buf[TKR_D_ITEM];
    int i;
    l.n = 0;
    for (i = 1; i <= 31; i++) {
        int e = i;
        if (!(md & (UINT64_C(1) << i)))
            continue;
        while (e < 31 && (md & (UINT64_C(1) << (e + 1))))
            e++;
        tkr_d_ordinal(buf, sizeof buf, i);
        if (e - i >= 2) {                               /* a run: "the 10th to the 15th" */
            char end[TKR_D_ITEM];
            tkr_d_ordinal(end, sizeof end, e);
            tkr_d_add(&l, "%s to the %s", buf, end);
            i = e;
        }
        else tkr_d_add(&l, "%s", buf);
    }
    for (i = 31; i >= 1; i--)
        if (md & (UINT64_C(1) << (32 + i))) { tkr_d_nth_word(buf, sizeof buf, -i); tkr_d_add(&l, "%s day", buf); }
    sv_catpvs(out, "the ");
    tkr_d_join(aTHX_ out, &l, " and the ");
}

/* The months; with prep, "in June and July" or "from March to October". */
static void
tkr_d_months(pTHX_ SV *out, const tkr_rule *r, int prep)
{
    int a, b, v;
    tkr_d_list l;
    if (prep)
        sv_catpv(out, !(r->flags & TKR_F_RSCALE) && tkr_d_run(r->by_month, 1, 12, &a, &b) && b - a >= 2 ? "from " : "in ");
    if (r->flags & TKR_F_RSCALE) {
        l.n = 0;
        for (v = 1; v <= 13; v++) {
            if (r->by_month & (1u << v)) tkr_d_add(&l, "%d", v);
            if (r->by_month_leap & (1u << v)) tkr_d_add(&l, "%dL", v);
        }
        sv_catpvf(out, "month%s ", l.n == 1 ? "" : "s");
        tkr_d_join(aTHX_ out, &l, " and ");
        return;
    }
    if (tkr_d_run(r->by_month, 1, 12, &a, &b) && b - a >= 2) {
        sv_catpvf(out, "%s to %s", tkr_d_month[a], tkr_d_month[b]);
        return;
    }
    l.n = 0;
    for (v = 1; v <= 12; v++)
        if (r->by_month & (1u << v))
            tkr_d_add(&l, "%s", tkr_d_month[v]);
    tkr_d_join(aTHX_ out, &l, " and ");
}

/* The days a rule keeps, without its cycle: "on Monday to Friday", "on the
 * first Monday", "on the 1st and 15th", "on the 1st or on Monday" (cron's
 * either), "on Friday the 13th". 1 when there was a restriction. */
static int
tkr_d_days(pTHX_ SV *out, const tkr_rule *r, int *monthly)
{
    unsigned w = r->by_day_any;
    int ord = tkr_has_by_day_ordinal(r), i;
    STRLEN at = SvCUR(out);
    *monthly = 0;
    if (w == 0x7f && !ord && !r->by_monthday && !r->n_setpos) {
        if (r->freq > TKR_WEEKLY) { sv_catpvs(out, "every day"); return 1; }
        w = 0;                                          /* every day of the week is no restriction */
    }
    if (r->n_setpos && (w || ord) && !r->by_monthday) {
        tkr_d_list l;
        char buf[TKR_D_ITEM];
        l.n = 0;
        for (i = 0; i < r->n_setpos; i++) { tkr_d_nth_word(buf, sizeof buf, r->by_setpos[i]); tkr_d_add(&l, "%s", buf); }
        sv_catpvs(out, "on the ");
        tkr_d_join(aTHX_ out, &l, " and ");
        if (w == 0x1f && !ord) sv_catpvf(out, " weekday%s", l.n == 1 ? "" : "s");
        else if (w == 0x60 && !ord) sv_catpvf(out, " weekend day%s", l.n == 1 ? "" : "s");
        else {
            sv_catpvs(out, " of ");
            if (ord) tkr_d_ordinals(aTHX_ out, r);
            else tkr_d_weekdays(aTHX_ out, w);
        }
        *monthly = r->freq == TKR_MONTHLY || r->freq == TKR_YEARLY;
        return 1;
    }
    if (r->by_monthday && (w || ord)) {
        if (r->flags & TKR_F_VIXIE) {                   /* cron: either field */
            sv_catpvs(out, "on ");
            tkr_d_monthdays(aTHX_ out, r->by_monthday);
            sv_catpvs(out, " of the month, or on ");
            tkr_d_weekdays(aTHX_ out, w);
        }
        else if (!ord && tkr_d_bits(w) == 1 && tkr_d_bits(r->by_monthday) == 1 && (r->by_monthday & TKR_CRON_ALL(1, 31))) {
            char buf[TKR_D_ITEM];                       /* both, one of each: "on Friday the 13th" */
            tkr_d_ordinal(buf, sizeof buf, tkr_d_lowest(r->by_monthday, 1, 31));
            sv_catpvf(out, "on %s the %s", tkr_d_day[tkr_d_lowest(w, 0, 6)], buf);
        }
        else {                                          /* both: "on a Monday that is the 1st or the 2nd" */
            sv_catpvs(out, "on ");
            if (ord) tkr_d_ordinals(aTHX_ out, r);
            else { sv_catpvs(out, "a "); tkr_d_weekdays(aTHX_ out, w); }
            sv_catpvs(out, " that is ");
            tkr_d_monthdays(aTHX_ out, r->by_monthday);
        }
        return 1;
    }
    if (ord) {
        sv_catpvs(out, "on ");
        tkr_d_ordinals(aTHX_ out, r);
        *monthly = 1;
    }
    else if (r->by_monthday) {
        sv_catpvs(out, "on ");
        tkr_d_monthdays(aTHX_ out, r->by_monthday);
        *monthly = 1;
    }
    else if (w) {
        if (r->freq == TKR_WEEKLY || r->freq == TKR_DAILY || r->freq < TKR_DAILY) {
            if (!(w == 0x1f || tkr_d_run(w, 0, 6, &i, &i)) || tkr_d_bits(w) < 3) sv_catpvs(out, "on ");
        }
        else sv_catpvs(out, "on ");
        tkr_d_weekdays(aTHX_ out, w);
    }
    if (r->n_yearday) {
        tkr_d_list l;
        char buf[TKR_D_ITEM];
        if (SvCUR(out) > at) sv_catpvs(out, ", ");
        l.n = 0;
        for (i = 0; i < r->n_yearday; i++) {
            int v = r->by_yearday[i];
            if (v > 0) tkr_d_add(&l, "%d", v);
            else { tkr_d_nth_word(buf, sizeof buf, v); tkr_d_add(&l, "the %s", buf); }
        }
        sv_catpvf(out, "on day%s ", l.n == 1 ? "" : "s");
        tkr_d_join(aTHX_ out, &l, " and ");
        sv_catpvs(out, " of the year");
    }
    if (r->n_weekno) {
        tkr_d_list l;
        if (SvCUR(out) > at) sv_catpvs(out, ", ");
        l.n = 0;
        for (i = 0; i < r->n_weekno; i++)
            tkr_d_add(&l, "%d", (int)r->by_weekno[i]);
        sv_catpvf(out, "in week%s ", l.n == 1 ? "" : "s");
        tkr_d_join(aTHX_ out, &l, " and ");
        sv_catpvs(out, " of the year");
    }
    if (r->n_setpos && r->by_monthday) {
        tkr_d_list l;
        char buf[TKR_D_ITEM];
        l.n = 0;
        for (i = 0; i < r->n_setpos; i++) { tkr_d_nth_word(buf, sizeof buf, r->by_setpos[i]); tkr_d_add(&l, "%s", buf); }
        sv_catpvs(out, ", only the ");
        tkr_d_join(aTHX_ out, &l, " and ");
        sv_catpvs(out, " of these");
    }
    return SvCUR(out) > at;
}

/* ---- the whole --------------------------------------------------------------- */

static void
tkr_d_end(pTHX_ SV *out, const tkr_rule *r)
{
    if (r->count) {
        sv_catpvf(out, r->count == 1 ? ", once" : ", %" IVdf " times", (IV)r->count);
        return;
    }
    if (r->until_kind != TKR_UNTIL_NONE) {
        int64_t days = r->until_sec >= 0 ? r->until_sec / 86400 : -((-r->until_sec + 86399) / 86400);
        int64_t rem = r->until_sec - days * 86400, y;
        unsigned mo, d;
        tkr_civil_from_days(days, &y, &mo, &d);
        sv_catpvf(out, ", until %04" IVdf "-%02u-%02u", (IV)y, mo, d);
        if (r->until_kind != TKR_UNTIL_DATE)
            sv_catpvf(out, " %02d:%02d%s", (int)(rem / 3600), (int)(rem % 3600 / 60), r->until_kind == TKR_UNTIL_UTC ? " UTC" : "");
    }
}

static void
tkr_d_calendar(pTHX_ SV *out, const tkr_rule *r)
{
    const char *id = NULL;
    if (!(r->flags & TKR_F_RSCALE))
        return;
    if (r->calendar == 0 || (tkr_tk(aTHX)->calendar_id)(r->calendar, &id) != TIME_KEEPER_OK || !id)
        id = "gregorian";
    sv_catpvf(out, ", in the %c%s calendar", toUPPER(*id), id + 1);
}

static void
tkr_describe(pTHX_ const tkr_rule *r, SV *out)
{
    SV *days = sv_2mortal(newSVpvs(""));
    SV *time = sv_2mortal(newSVpvs(""));
    int has_days, has_time, monthly = 0;
    unsigned n = r->interval;

    sv_setpvs(out, "");
    if (r->flags & TKR_F_EVERY) {
        int64_t s = r->every_sec;
        if (s % 86400 == 0) sv_catpvf(out, "every %" IVdf " day%s", (IV)(s / 86400), s == 86400 ? "" : "s");
        else if (s % 3600 == 0) sv_catpvf(out, "every %" IVdf " hour%s", (IV)(s / 3600), s == 3600 ? "" : "s");
        else if (s % 60 == 0) sv_catpvf(out, "every %" IVdf " minute%s", (IV)(s / 60), s == 60 ? "" : "s");
        else sv_catpvf(out, "every %" IVdf " second%s", (IV)s, s == 1 ? "" : "s");
        sv_catpvs(out, ", counted from the last run");
        goto done;
    }
    has_time = tkr_d_time(aTHX_ time, r);
    has_days = tkr_d_days(aTHX_ days, r, &monthly);

    switch (r->freq) {
    case TKR_YEARLY:
        if (has_days && monthly && !r->by_month && tkr_has_by_day_ordinal(r) && !r->by_monthday) {
            sv_catsv(out, days);                        /* "on the 20th Monday of every year" */
            sv_catpvs(out, " of ");
            tkr_d_every(aTHX_ out, n, "year", "years");
            break;
        }
        if (has_days) {
            sv_catsv(out, days);
            if (r->by_month) {
                if (monthly) { sv_catpvs(out, " of "); tkr_d_months(aTHX_ out, r, 0); }
                else { sv_catpv(out, strEQ(SvPVX(days), "every day") ? " " : ", "); tkr_d_months(aTHX_ out, r, 1); }
            }
        }
        else if (r->by_month) tkr_d_months(aTHX_ out, r, 1);
        if (SvCUR(out)) sv_catpvs(out, ", ");
        tkr_d_every(aTHX_ out, n, "year", "years");
        break;
    case TKR_MONTHLY:
        if (has_days) { sv_catsv(out, days); sv_catpv(out, monthly ? " of " : ", "); }
        tkr_d_every(aTHX_ out, n, "month", "months");
        if (r->by_month) { sv_catpvs(out, ", "); tkr_d_months(aTHX_ out, r, 1); }
        break;
    case TKR_WEEKLY:
        if (n == 1 && r->by_day_any && !monthly && !r->n_setpos && !tkr_has_by_day_ordinal(r)) {
            sv_catpvs(out, "every ");
            tkr_d_weekdays(aTHX_ out, r->by_day_any);
        }
        else {
            tkr_d_every(aTHX_ out, n, "week", "weeks");
            if (has_days) { sv_catpvs(out, " "); sv_catsv(out, days); }
        }
        if (r->by_month) { sv_catpvs(out, ", "); tkr_d_months(aTHX_ out, r, 1); }
        break;
    case TKR_DAILY:
        if (n != 1 || !has_days) tkr_d_every(aTHX_ out, n, "day", "days");
        if (has_days) { if (SvCUR(out)) sv_catpvs(out, ", "); sv_catsv(out, days); }
        if (monthly && r->by_month) { sv_catpvs(out, " of "); tkr_d_months(aTHX_ out, r, 0); }
        else {
            if (monthly) sv_catpvs(out, " of the month");
            if (r->by_month) { sv_catpv(out, has_days ? ", " : " "); tkr_d_months(aTHX_ out, r, 1); }
        }
        break;
    default:                                            /* hourly and finer: the time says the cycle */
        if (has_days) sv_catsv(out, days);
        if (monthly && r->by_month) { sv_catpvs(out, " of "); tkr_d_months(aTHX_ out, r, 0); }
        else {
            if (monthly) sv_catpvs(out, " of the month");
            if (r->by_month) { if (SvCUR(out)) sv_catpvs(out, ", "); tkr_d_months(aTHX_ out, r, 1); }
        }
        break;
    }
    if (has_time) {                                     /* the time first: "At 09:00, Monday to Friday" */
        if (SvCUR(out)) {
            SV *rest = sv_2mortal(newSVsv(out));
            sv_setsv(out, time);
            /* "At 09:30 every day", "At 09:00 every Monday to Friday"; else a comma */
            sv_catpv(out, strnEQ(SvPVX(rest), "every ", 6) ? " " : ", ");
            sv_catsv(out, rest);
        }
        else {
            sv_setsv(out, time);
            if (r->freq < TKR_DAILY && r->by_hour && r->by_minute && tkr_d_bits(r->by_hour) * tkr_d_bits(r->by_minute) <= 6)
                sv_catpvs(out, " every day");
        }
    }
done:
    tkr_d_end(aTHX_ out, r);
    tkr_d_calendar(aTHX_ out, r);
    if (SvCUR(out))
        SvPVX(out)[0] = toUPPER(SvPVX(out)[0]);
}

#endif
