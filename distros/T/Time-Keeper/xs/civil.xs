# Doors onto the civil core, for the tests only. The Perl surface arrives
# in Phase 06.

MODULE = Time::Keeper    PACKAGE = Time::Keeper

SV *
_days_from_civil(y, m, d)
        SV *y
        SV *m
        SV *d
    PREINIT:
        int64_t yy, mm, dd;
    CODE:
        yy = tk_arg_i64(aTHX_ y, "year");
        mm = tk_arg_i64(aTHX_ m, "month");
        dd = tk_arg_i64(aTHX_ d, "day");
        if (!tk_civil_date_valid(yy, mm, dd))
            croak("no such date");
        RETVAL = tk_newSVi64(aTHX_ tk_days_from_civil(yy, (unsigned)mm, (unsigned)dd));
    OUTPUT:
        RETVAL

void
_civil_from_days(z)
        SV *z
    PREINIT:
        int64_t zz, y;
        unsigned m, d;
    PPCODE:
        zz = tk_arg_i64(aTHX_ z, "day number");
        if (zz < tk_days_from_civil(TK_YEAR_MIN, 1, 1) || zz > tk_days_from_civil(TK_YEAR_MAX, 12, 31))
            croak("day number out of range");
        tk_civil_from_days(zz, &y, &m, &d);
        EXTEND(SP, 5);
        mPUSHs(tk_newSVi64(aTHX_ y));
        mPUSHu(m);
        mPUSHu(d);
        mPUSHu(tk_dow_from_days(zz));
        mPUSHu(tk_doy_from_civil(y, m, d));

IV
_is_leap_year(y)
        SV *y
    CODE:
        RETVAL = tk_is_leap_year(tk_arg_i64(aTHX_ y, "year"));
    OUTPUT:
        RETVAL

UV
_days_in_month(y, m)
        SV *y
        SV *m
    PREINIT:
        int64_t yy, mm;
    CODE:
        yy = tk_arg_i64(aTHX_ y, "year");
        mm = tk_arg_i64(aTHX_ m, "month");
        if (mm < 1 || mm > 12)
            croak("no such month");
        RETVAL = tk_days_in_month(yy, (unsigned)mm);
    OUTPUT:
        RETVAL

# Walks every day from 1 January of y0 to 31 December of y1, stepping a
# calendar of its own (day, then month, then year, by the days in each
# month), and checks both conversions and the weekday against it.
# Returns (days walked, days wrong).
void
_civil_sweep(y0, y1)
        IV y0
        IV y1
    PREINIT:
        int64_t y, z, ry;
        unsigned m, d, rm, rd, dow;
        UV checked = 0, bad = 0;
    PPCODE:
        y = y0; m = 1; d = 1;
        z = tk_days_from_civil(y, 1, 1);
        dow = tk_dow_from_days(z);
        while (y <= y1) {
            checked++;
            tk_civil_from_days(z, &ry, &rm, &rd);
            if (ry != y || rm != m || rd != d
                || tk_days_from_civil(y, m, d) != z
                || tk_dow_from_days(z) != dow)
                bad++;
            z++;
            dow = dow % 7 + 1;
            if (++d > tk_days_in_month(y, m)) {
                d = 1;
                if (++m > 12) { m = 1; y++; }
            }
        }
        EXTEND(SP, 2);
        mPUSHu(checked);
        mPUSHu(bad);

void
_civil_from_instant(sec, nsec)
        SV *sec
        IV nsec
    PREINIT:
        tk_instant t;
        tk_civil c;
    PPCODE:
        t.sec = tk_arg_i64(aTHX_ sec, "seconds");
        if (nsec < -2147483647 || nsec > 2147483647)
            croak("instant out of range");
        t.nsec = (int32_t)nsec;
        if (!tk_instant_valid(&t))
            croak("instant out of range");
        tk_civil_from_instant(&t, &c);
        EXTEND(SP, 9);
        mPUSHi(c.year);
        mPUSHu(c.month);
        mPUSHu(c.day);
        mPUSHu(c.hour);
        mPUSHu(c.minute);
        mPUSHu(c.second);
        mPUSHi(c.nsec);
        mPUSHu(c.dow);
        mPUSHu(c.doy);

void
_instant_from_civil(y, m, d, hour, minute, second, nsec)
        SV *y
        SV *m
        SV *d
        IV hour
        IV minute
        IV second
        IV nsec
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
        if (!tk_instant_valid(&t))
            croak("no such time");
        EXTEND(SP, 2);
        mPUSHs(tk_newSVi64(aTHX_ t.sec));
        mPUSHi(t.nsec);

# (ISO week year, ISO week, %U, %W, quarter, day of quarter)
void
_week_info(y, m, d)
        SV *y
        SV *m
        SV *d
    PREINIT:
        int64_t yy, mm, dd, wy;
        unsigned w;
    PPCODE:
        yy = tk_arg_i64(aTHX_ y, "year");
        mm = tk_arg_i64(aTHX_ m, "month");
        dd = tk_arg_i64(aTHX_ d, "day");
        if (!tk_civil_date_valid(yy, mm, dd))
            croak("no such date");
        tk_iso_week(yy, (unsigned)mm, (unsigned)dd, &wy, &w);
        EXTEND(SP, 6);
        mPUSHs(tk_newSVi64(aTHX_ wy));
        mPUSHu(w);
        mPUSHu(tk_week_number_sunday(yy, (unsigned)mm, (unsigned)dd));
        mPUSHu(tk_week_number_monday(yy, (unsigned)mm, (unsigned)dd));
        mPUSHu(tk_quarter((unsigned)mm));
        mPUSHu(tk_day_of_quarter(yy, (unsigned)mm, (unsigned)dd));

# (Rata Die days, seconds into the day, nanoseconds), (JD whole, JD
# fraction), (MJD whole, MJD fraction)
void
_day_numbers(sec, nsec)
        SV *sec
        IV nsec
    PREINIT:
        tk_instant t;
        int64_t rd_days, rd_secs, jd_int, mjd_int;
        int32_t rd_nsecs;
        double jd_frac, mjd_frac;
    PPCODE:
        t.sec = tk_arg_i64(aTHX_ sec, "seconds");
        if (nsec < -2147483647 || nsec > 2147483647)
            croak("instant out of range");
        t.nsec = (int32_t)nsec;
        if (!tk_instant_valid(&t))
            croak("instant out of range");
        tk_rd_values(&t, &rd_days, &rd_secs, &rd_nsecs);
        tk_julian_day(&t, &jd_int, &jd_frac);
        tk_mjd(&t, &mjd_int, &mjd_frac);
        EXTEND(SP, 7);
        mPUSHs(tk_newSVi64(aTHX_ rd_days));
        mPUSHs(tk_newSVi64(aTHX_ rd_secs));
        mPUSHi(rd_nsecs);
        mPUSHs(tk_newSVi64(aTHX_ jd_int));
        mPUSHn(jd_frac);
        mPUSHs(tk_newSVi64(aTHX_ mjd_int));
        mPUSHn(mjd_frac);

void
_now()
    PREINIT:
        tk_instant t;
    PPCODE:
        tk_now_sv(aTHX_ &t);
        EXTEND(SP, 2);
        mPUSHs(tk_newSVi64(aTHX_ t.sec));
        mPUSHi(t.nsec);

IV
_now_resolution()
    CODE:
        RETVAL = tk_now_resolution_ns();
    OUTPUT:
        RETVAL

# (first year, last year, first second, last second)
void
_range()
    PPCODE:
        EXTEND(SP, 4);
        mPUSHi(TK_YEAR_MIN);
        mPUSHi(TK_YEAR_MAX);
        mPUSHs(tk_newSVi64(aTHX_ tk_sec_min()));
        mPUSHs(tk_newSVi64(aTHX_ tk_sec_max()));

# A 64-bit integer through the scalar conversions both ways.
SV *
_i64_roundtrip(sv)
        SV *sv
    PREINIT:
        int64_t v;
    CODE:
        if (!tk_sv_to_i64(aTHX_ sv, &v))
            XSRETURN_UNDEF;
        RETVAL = tk_newSVi64(aTHX_ v);
    OUTPUT:
        RETVAL
