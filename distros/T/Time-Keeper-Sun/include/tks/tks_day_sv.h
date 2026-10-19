#ifndef TKS_DAY_SV_H
#define TKS_DAY_SV_H

/* Between the engine and Perl: a value from a rounded second in the place's
 * zone and locale, a Date from days and days from a Date, a Duration from
 * seconds, and the civil window of a date in the place's zone. */

static SV *
tks_value_sv(pTHX_ const tks_place *p, int64_t sec)
{
    time_keeper_instant t;
    SV *sv;
    t.sec = sec;
    t.nsec = 0;
    sv = (tks_tk(aTHX)->new_sv)(aTHX_ &t, &p->zone, p->locale);
    if (!sv)
        croak("Time::Keeper refused an instant outside its years");
    return sv;
}

/* A class method of Time::Keeper's with one integer argument, in scalar
 * context; the result with a reference count the caller owns. */
static SV *
tks_call_class(pTHX_ const char *class, const char *method, SV *arg1, SV *arg2)
{
    dSP;
    SV *ret;
    int count;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(class, 0)));
    XPUSHs(sv_2mortal(arg1));
    if (arg2)
        XPUSHs(sv_2mortal(arg2));
    PUTBACK;
    count = call_method(method, G_SCALAR);
    SPAGAIN;
    if (count != 1)
        croak("%s->%s gave %d values", class, method, count);
    ret = POPs;
    SvREFCNT_inc_simple_void(ret);
    PUTBACK;
    FREETMPS;
    LEAVE;
    return ret;
}

static SV *
tks_date_sv(pTHX_ int64_t days)
{
    return tks_call_class(aTHX_ "Time::Keeper::Date", "from_epoch_days", newSViv((IV)days), NULL);
}

static SV *
tks_duration_sv(pTHX_ int64_t seconds)
{
    return tks_call_class(aTHX_ "Time::Keeper::Duration", "new", newSVpvs("seconds"), newSViv((IV)seconds));
}

/* A Time::Keeper::Date's days since 1970, through its own method. */
static int64_t
tks_days_of_date(pTHX_ SV *date)
{
    dSP;
    int64_t days;
    int count;
    SV *r;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(date);
    PUTBACK;
    count = call_method("epoch_days", G_SCALAR);
    SPAGAIN;
    if (count != 1)
        croak("epoch_days gave %d values", count);
    /* POPs into a variable first: before perl 5.38 SvNV evaluates its
     * argument twice, and would pop twice. */
    r = POPs;
    days = (int64_t)SvNV(r);
    PUTBACK;
    FREETMPS;
    LEAVE;
    return days;
}

/* Local midnight of a date in the place's zone: gap forward (a midnight the
 * clocks skipped is the first moment after it), overlap earlier. */
static int64_t
tks_midnight(pTHX_ const tks_place *p, int64_t days, const char *what)
{
    time_keeper_civil c;
    time_keeper_instant t;
    int64_t y;
    int m, d;
    memset(&c, 0, sizeof c);
    tks_civil_from_days(days, &y, &m, &d);
    c.year = y;
    c.month = m;
    c.day = d;
    if ((tks_tk(aTHX)->from_civil)(aTHX_ &c, &p->zone, TIME_KEEPER_GAP_FORWARD, TIME_KEEPER_OVERLAP_EARLIER, &t) != TIME_KEEPER_OK)
        croak("%s: %" IVdf "-%02d-%02d is outside the years Time::Keeper holds", what, (IV)y, m, d);
    return t.sec;
}

/* The date, as days since 1970, of an instant in the place's zone. */
static int64_t
tks_days_in_zone(pTHX_ const tks_place *p, const time_keeper_instant *t, const char *what)
{
    time_keeper_civil c;
    if ((tks_tk(aTHX)->civil)(aTHX_ t, &p->zone, &c) != TIME_KEEPER_OK)
        croak("%s: the instant is outside the years Time::Keeper holds", what);
    return tks_days_from_civil(c.year, c.month, c.day);
}

#endif
