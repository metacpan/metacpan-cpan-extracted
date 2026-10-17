# Doors onto leap seconds, for the tests only.

MODULE = Time::Keeper    PACKAGE = Time::Keeper

# The POSIX second each leap second ended at.
void
_leap_ends()
    PREINIT:
        int i;
    PPCODE:
        EXTEND(SP, TK_LEAP_COUNT);
        for (i = 0; i < TK_LEAP_COUNT; i++)
            mPUSHs(tk_newSVi64(aTHX_ tk_leap_ends[i]));

IV
_leaps_before(sec)
        SV *sec
    CODE:
        RETVAL = tk_leaps_before(tk_arg_i64(aTHX_ sec, "seconds"));
    OUTPUT:
        RETVAL

IV
_is_leap_day_end(sec)
        SV *sec
    CODE:
        RETVAL = tk_is_leap_day_end(tk_arg_i64(aTHX_ sec, "seconds"));
    OUTPUT:
        RETVAL

# (expires, updated): POSIX seconds, from the list.
void
_leap_dates()
    PPCODE:
        EXTEND(SP, 2);
        mPUSHs(tk_newSVi64(aTHX_ TK_LEAP_EXPIRES));
        mPUSHs(tk_newSVi64(aTHX_ TK_LEAP_UPDATED));

# A wall-clock time at a fixed offset to its instant: (sec, nsec).
void
_instant_from_local(y, m, d, hour, minute, second, nsec, utoff)
        SV *y
        SV *m
        SV *d
        IV hour
        IV minute
        IV second
        IV nsec
        IV utoff
    PREINIT:
        int64_t yy, mm, dd;
        tk_instant t;
    PPCODE:
        yy = tk_arg_i64(aTHX_ y, "year");
        mm = tk_arg_i64(aTHX_ m, "month");
        dd = tk_arg_i64(aTHX_ d, "day");
        if (!tk_civil_date_valid(yy, mm, dd))
            croak("no such date");
        if (hour < 0 || hour > 23 || minute < 0 || minute > 59 || second < 0 || second > 60
            || nsec < 0 || nsec >= TK_NSECS_PER_SEC)
            croak("no such time");
        tk_instant_from_civil(yy, (unsigned)mm, (unsigned)dd, hour, minute, second, (int32_t)nsec, &t);
        t.sec -= utoff;
        if (!tk_instant_valid(&t))
            croak("no such time");
        EXTEND(SP, 2);
        mPUSHs(tk_newSVi64(aTHX_ t.sec));
        mPUSHi(t.nsec);

# TAI - UTC at an instant, or undef before 1972.
SV *
_tai_minus_utc(sec, nsec)
        SV *sec
        IV nsec
    PREINIT:
        tk_instant t;
        int out;
    CODE:
        t.sec = tk_arg_i64(aTHX_ sec, "seconds");
        if (nsec < -2147483647 || nsec > 2147483647)
            croak("instant out of range");
        t.nsec = (int32_t)nsec;
        if (!tk_instant_valid(&t))
            croak("instant out of range");
        if (!tk_tai_minus_utc(&t, &out))
            XSRETURN_UNDEF;
        RETVAL = newSViv(out);
    OUTPUT:
        RETVAL

# b - a in SI seconds: (seconds, nanoseconds 0 .. 999,999,999).
void
_minus_absolute(bs, bn, as, an)
        SV *bs
        IV bn
        SV *as
        IV an
    PREINIT:
        tk_instant b, a;
        int64_t s;
        int32_t n;
    PPCODE:
        b.sec = tk_arg_i64(aTHX_ bs, "seconds");
        a.sec = tk_arg_i64(aTHX_ as, "seconds");
        if (bn < -2147483647 || bn > 2147483647 || an < -2147483647 || an > 2147483647)
            croak("instant out of range");
        b.nsec = (int32_t)bn;
        a.nsec = (int32_t)an;
        if (!tk_instant_valid(&b) || !tk_instant_valid(&a))
            croak("instant out of range");
        tk_minus_absolute(&b, &a, &s, &n);
        EXTEND(SP, 2);
        mPUSHs(tk_newSVi64(aTHX_ s));
        mPUSHi(n);
