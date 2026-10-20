#ifndef TKB_VALUE_H
#define TKB_VALUE_H

/* What goes in comes out. A Time::Keeper is read through the core's table:
 * its day is the date its own zone shows, and its clock, zone, locale and
 * calendar are kept for the value written back on another day. A
 * Time::Keeper::Date is read and written through the table's version 3
 * entries, or one method call where the table is older; a YearMonth is
 * read as its first day and always written back as a Date. */

#define TKB_KIND_KEEPER     0
#define TKB_KIND_DATE       1
#define TKB_KIND_YEAR_MONTH 2

typedef struct tkb_val {
    int kind;
    SV *sv;                          /* the value as given */
    time_keeper_instant inst;
    time_keeper_zone zone;
    int locale, calendar;
    time_keeper_civil civil;         /* kind 0: the wall clock in its zone */
    int64_t day;
    SV *locale_sv;                   /* kinds 1 and 2 without has_lid: the locale's code, mortal */
    int has_lid;                     /* kinds 1 and 2: locale is the locale's id */
} tkb_val;

/* One method call on an object or a class, in scalar context; the result
 * is mortal. */
static SV *
tkb_call(pTHX_ SV *invocant, const char *method, SV **args, int nargs)
{
    dSP;
    SV *ret;
    int i, count;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, nargs + 1);
    PUSHs(invocant);
    for (i = 0; i < nargs; i++)
        PUSHs(args[i]);
    PUTBACK;
    count = call_method(method, G_SCALAR);
    SPAGAIN;
    ret = count ? POPs : &PL_sv_undef;
    SvREFCNT_inc_simple_void_NN(ret);
    PUTBACK;
    FREETMPS;
    LEAVE;
    return sv_2mortal(ret);
}

static int
tkb_sv_to_i64(pTHX_ SV *sv, int64_t *out)
{
    if (!sv || !SvOK(sv) || SvROK(sv) || (!SvIOK(sv) && !SvNOK(sv) && !looks_like_number(sv)))
        return 0;
    if (SvIOK(sv) || (SvIOKp(sv) && !SvNOK(sv))) {
        *out = (int64_t)SvIV(sv);
        return 1;
    }
    {
        NV n = SvNV(sv);
        if (n != (NV)(int64_t)n)
            return 0;
        *out = (int64_t)n;
        return 1;
    }
}

/* A Time::Keeper::Date's day and locale id through the table, or its day
 * through epoch_days with *locale -1. 0 when the day cannot be read. */
static int
tkb_date_day(pTHX_ SV *sv, int64_t *day, int *locale)
{
#if TKB_HAVE_V3
    if (TKB_V3) {
        int kind;
        if (TKB(date_from_sv)(aTHX_ sv, &kind, day, locale) == TIME_KEEPER_OK && kind == TIME_KEEPER_KIND_DATE)
            return 1;
    }
#endif
    *locale = -1;
    return tkb_sv_to_i64(aTHX_ tkb_call(aTHX_ sv, "epoch_days", NULL, 0), day);
}

/* A Time::Keeper::Date on a day, mortal: in stash (NULL for the class
 * itself) and the locale by id, or by locale_sv's code where the table is
 * older (en when neither is given). */
static SV *
tkb_date_new(pTHX_ int64_t day, int locale, HV *stash, SV *locale_sv)
{
    SV *args[3];
    int n = 1;
#if TKB_HAVE_V3
    if (TKB_V3 && (locale >= 0 || !locale_sv)) {
        SV *out = TKB(new_date_sv)(aTHX_ TIME_KEEPER_KIND_DATE, day, locale >= 0 ? locale : 0, stash);
        if (!out)
            croak("Time::Keeper::Date->from_epoch_days: out of range");
        return sv_2mortal(out);
    }
#endif
    args[0] = sv_2mortal(tkb_i64_sv(aTHX_ day));
    if (locale_sv) {
        args[1] = sv_2mortal(newSVpvs("locale"));
        args[2] = locale_sv;
        n = 3;
    }
    return tkb_call(aTHX_ sv_2mortal(newSVpv(stash ? HvNAME(stash) : "Time::Keeper::Date", 0)), "from_epoch_days", args, n);
}

/* The locale id a Date was read with: 0 (en) when it cannot be told. */
static int
tkb_val_locale_id(pTHX_ const tkb_val *v)
{
    if (v->has_lid)
        return v->locale;
    if (v->locale_sv && SvOK(v->locale_sv)) {
        STRLEN len;
        const char *code = SvPV(v->locale_sv, len);
        int id = TKB(locale_find)(code, len);
        return id < 0 ? 0 : id;
    }
    return 0;
}

/* 1 when read; 0 when sv is neither kind, with the reason in *why. */
static int
tkb_in(pTHX_ SV *sv, tkb_val *v, const char **why)
{
    Zero(v, 1, tkb_val);
    v->sv = sv;
    if (!sv || !SvROK(sv)) {
        *why = "not a Time::Keeper value or a Time::Keeper::Date";
        return 0;
    }
    if (TKB(from_sv_cal)(aTHX_ sv, &v->inst, &v->zone, &v->locale, &v->calendar) == TIME_KEEPER_OK) {
        v->kind = TKB_KIND_KEEPER;
        if (TKB(civil)(aTHX_ &v->inst, &v->zone, &v->civil) != TIME_KEEPER_OK) {
            *why = "the value's date could not be read";
            return 0;
        }
        v->day = tkb_days_from_civil(v->civil.year, (unsigned)v->civil.month, (unsigned)v->civil.day);
        return 1;
    }
    if (sv_derived_from(sv, "Time::Keeper::Date") || sv_derived_from(sv, "Time::Keeper::YearMonth")) {
        SV *date = sv;
        SV *days;
        v->kind = sv_derived_from(sv, "Time::Keeper::Date") ? TKB_KIND_DATE : TKB_KIND_YEAR_MONTH;
#if TKB_HAVE_V3
        if (TKB_V3) {
            int kind;
            if (TKB(date_from_sv)(aTHX_ sv, &kind, &v->day, &v->locale) == TIME_KEEPER_OK
                && (kind == TIME_KEEPER_KIND_DATE || kind == TIME_KEEPER_KIND_YEAR_MONTH)) {
                v->has_lid = 1;
                return 1;
            }
        }
#endif
        if (v->kind == TKB_KIND_YEAR_MONTH) {
            SV *one = sv_2mortal(newSViv(1));
            date = tkb_call(aTHX_ sv, "on", &one, 1);
        }
        days = tkb_call(aTHX_ date, "epoch_days", NULL, 0);
        if (!tkb_sv_to_i64(aTHX_ days, &v->day)) {
            *why = "the date's day count could not be read";
            return 0;
        }
        v->locale_sv = tkb_call(aTHX_ date, "locale", NULL, 0);
        return 1;
    }
    *why = "not a Time::Keeper value or a Time::Keeper::Date";
    return 0;
}

static void
tkb_in_or_croak(pTHX_ SV *sv, tkb_val *v, const char *what)
{
    const char *why = "";
    if (!tkb_in(aTHX_ sv, v, &why))
        croak("%s: %s", what, why);
}

/* The value on another day: the same class, clock, zone, locale and
 * calendar. A kept clock the new day skipped is carried forward, as
 * plus(days => n, gap => 'forward') would carry it. A Time::Keeper in a
 * subclass stays in it. */
static SV *
tkb_out(pTHX_ const tkb_val *v, int64_t day, const char *what)
{
    if (v->kind == TKB_KIND_KEEPER) {
        time_keeper_civil c = v->civil;
        time_keeper_instant t;
        int64_t y;
        unsigned m, d;
        SV *out;
        int rc;
        tkb_civil_from_days(day, &y, &m, &d);
        c.year = y;
        c.month = (int)m;
        c.day = (int)d;
        if (c.second == 60) {
            c.second = 59;
            c.nanosecond = 999999999;
        }
        rc = TKB(from_civil)(aTHX_ &c, &v->zone, TIME_KEEPER_GAP_FORWARD, TIME_KEEPER_OVERLAP_EARLIER, &t);
        if (rc == TIME_KEEPER_RANGE)
            croak("%s: the result is outside the years Time::Keeper holds", what);
        if (rc != TIME_KEEPER_OK)
            croak("%s: the result could not be made (code %d)", what, rc);
        out = TKB(new_sv_cal)(aTHX_ &t, &v->zone, v->locale, v->calendar);
        if (!out)
            croak("%s: the result could not be made", what);
        if (SvSTASH(SvRV(v->sv)) != SvSTASH(SvRV(out)))
            sv_bless(out, SvSTASH(SvRV(v->sv)));
        return out;
    }
    else {
        HV *stash = v->kind == TKB_KIND_DATE ? SvSTASH(SvRV(v->sv)) : NULL;
        SV *out = tkb_date_new(aTHX_ day, v->has_lid ? v->locale : -1, stash,
                               v->has_lid ? NULL : v->locale_sv ? v->locale_sv : sv_2mortal(newSVpvs("en")));
        return SvREFCNT_inc_simple_NN(out);
    }
}

#endif

/* As tkb_in_or_croak, for a method that wants a day: a month is refused. */
static void
tkb_in_day(pTHX_ SV *sv, tkb_val *v, const char *what)
{
    tkb_in_or_croak(aTHX_ sv, v, what);
    if (v->kind == TKB_KIND_YEAR_MONTH)
        croak("%s: a month is not a day", what);
}

/* One option by key from a key/value list; every other key is refused. */
static SV *
tkb_opt(pTHX_ SV **args, I32 n, const char *key, const char *what)
{
    I32 i;
    SV *found = NULL;
    if (n % 2)
        croak("%s: needs key/value pairs after the value", what);
    for (i = 0; i < n; i += 2) {
        STRLEN klen;
        const char *k = SvPV(args[i], klen);
        if (strlen(key) == klen && memEQ(key, k, klen))
            found = args[i + 1];
        else
            croak("%s: unknown argument '%s'", what, k);
    }
    return found;
}
