# Doors for the tests only.

MODULE = Time::Keeper    PACKAGE = Time::Keeper

# The version of Zone's table this needs.
IV
_zone_abi_built()
    CODE:
        RETVAL = TK_ZONE_ABI_NEEDS;
    OUTPUT:
        RETVAL

# The version of the Zone header this was compiled against.
IV
_zone_abi_header()
    CODE:
        RETVAL = TKZ_ABI_VERSION;
    OUTPUT:
        RETVAL

# The table's version through the version 2 gate: dies as the new methods
# do when the table is older.
IV
_zone_abi_v2_version()
    CODE:
        RETVAL = tk_zone_abi_v2(aTHX_ "Time::Keeper->_zone_abi_v2_version")->abi_version;
    OUTPUT:
        RETVAL

# Lets go of the table, so the next named zone looks for it again.
void
_zone_abi_forget()
    CODE:
        tk_zone_table = NULL;

# Whether the table has been looked for yet, without looking.
IV
_zone_abi_resolved()
    CODE:
        RETVAL = tk_zone_table ? 1 : 0;
    OUTPUT:
        RETVAL

# Finds the table, loading Zone if it has to, and gives its version.
IV
_zone_abi_version()
    CODE:
        RETVAL = tk_zone_abi(aTHX)->abi_version;
    OUTPUT:
        RETVAL

# 2**62 + 1 worked out in int64_t and written out by hand, so the answer does
# not depend on the perl's IV or NV holding it.
SV *
_int64_probe()
    PREINIT:
        int64_t v;
        char buf[24];
        char *p;
    CODE:
        v = ((int64_t)1 << 62) + 1;
        p = buf + sizeof buf;
        *--p = '\0';
        do { *--p = (char)('0' + (int)(v % 10)); v /= 10; } while (v);
        RETVAL = newSVpv(p, 0);
    OUTPUT:
        RETVAL

# A value's flags: 1 when its date fields have been worked out, 2 when on
# daylight saving time.
IV
_flags(self)
        SV *self
    CODE:
        RETVAL = tk_value_of(aTHX_ self, "_flags")->flags;
    OUTPUT:
        RETVAL

# The size of a value's bytes, for the tests that forge one.
IV
_value_size()
    CODE:
        RETVAL = sizeof(tk_value);
    OUTPUT:
        RETVAL

# today, as it would be at a given instant in a value's zone: the same
# code today runs, given the instant instead of the clock.
SV *
_today_at(self)
        SV *self
    PREINIT:
        tk_value *v;
        tk_value nv;
    CODE:
        v = tk_value_rw(self, "_today_at");
        tk_value_start_of_day(aTHX_ &nv, v, "_today_at");
        RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(self)), &nv);
    OUTPUT:
        RETVAL

# Where a value's fields lie in its bytes: (nsec, utoff, zone). A 32-bit
# perl packs the instant into 12 bytes, a 64-bit one into 16.
void
_value_layout()
    PPCODE:
        EXTEND(SP, 6);
        mPUSHi(STRUCT_OFFSET(tk_value, inst) + STRUCT_OFFSET(tk_instant, nsec));
        mPUSHi(STRUCT_OFFSET(tk_value, utoff));
        mPUSHi(STRUCT_OFFSET(tk_value, zone));
        mPUSHi(STRUCT_OFFSET(tk_value, kind));
        mPUSHi(STRUCT_OFFSET(tk_value, cal));
        mPUSHi(sizeof(tk_value));

# About how many values range would give, before it gives any.
NV
_range_estimate(self, end, ...)
        SV *self
        SV *end
    PREINIT:
        tk_iter it;
    CODE:
        tk_range_init(aTHX_ &it, self, end, &ST(2), items - 2, "Time::Keeper->range");
        RETVAL = tk_range_estimate(&it);
    OUTPUT:
        RETVAL

# The fields of a day in a calendar, by the engine alone: year, month, day,
# day of the year, era index, year of the era, months in the year, days in
# the month and year, leap year, month number and leap month.
void
_cal_fields(id, days)
        SV *id
        IV days
    PREINIT:
        int k;
        tk_calfields f;
    PPCODE:
        k = tk_cal_id_from_sv(aTHX_ id, "_cal_fields");
        tk_cal_check_built(aTHX_ k, "_cal_fields");
        tk_cal_fields(&tk_calendars[k], (int64_t)days, &f);
        EXTEND(SP, 12);
        mPUSHs(tk_newSVi64(aTHX_ f.year));
        mPUSHi(f.month);
        mPUSHi(f.day);
        mPUSHi(f.doy);
        mPUSHi(f.era);
        mPUSHs(tk_newSVi64(aTHX_ f.era_year));
        mPUSHi(f.months_in_year);
        mPUSHi(f.days_in_month);
        mPUSHi(f.days_in_year);
        mPUSHi(f.leap_year);
        mPUSHi(f.month_number);
        mPUSHi(f.leap_month);

IV
_cal_to_days(id, y, m, d)
        SV *id
        IV y
        IV m
        IV d
    PREINIT:
        int k;
    CODE:
        k = tk_cal_id_from_sv(aTHX_ id, "_cal_to_days");
        tk_cal_check_built(aTHX_ k, "_cal_to_days");
        RETVAL = (IV)tk_calendars[k].to_days((int64_t)y, (unsigned)m, (unsigned)d);
    OUTPUT:
        RETVAL

# Every day from one to another: from_days then to_days gives the day back,
# the fields step as they should (the next day is day + 1 of the month, or
# the first of the next month, or the first of the next year), the month
# lengths and year lengths add up. Returns the count of days that fail.
IV
_cal_sweep(id, from, to)
        SV *id
        IV from
        IV to
    PREINIT:
        int k;
        const tk_calendar *cal;
        int64_t days, py = 0;
        unsigned pm = 0, pd = 0;
        IV bad = 0;
    CODE:
        k = tk_cal_id_from_sv(aTHX_ id, "_cal_sweep");
        tk_cal_check_built(aTHX_ k, "_cal_sweep");
        cal = &tk_calendars[k];
        for (days = (int64_t)from; days <= (int64_t)to; days++) {
            int64_t y;
            unsigned m, d;
            cal->from_days(days, &y, &m, &d);
            if (cal->to_days(y, m, d) != days || m < 1 || m > cal->months_in_year(y) || d < 1 || d > cal->days_in_month(y, m))
                bad++;
            else if (days > (int64_t)from) {
                int ok;
                if (y == py && m == pm) ok = d == pd + 1;
                else if (y == py) ok = m == pm + 1 && d == 1 && pd == cal->days_in_month(py, pm);
                else ok = y == py + 1 && m == 1 && d == 1 && pm == cal->months_in_year(py) && pd == cal->days_in_month(py, pm);
                if (!ok) bad++;
            }
            if (d == 1 && m == 1) {
                unsigned sum = 0, i;
                for (i = 1; i <= cal->months_in_year(y); i++)
                    sum += cal->days_in_month(y, i);
                if (sum != tk_cal_days_in_year(cal, y))
                    bad++;
            }
            py = y; pm = m; pd = d;
        }
        RETVAL = bad;
    OUTPUT:
        RETVAL

# The absolute index of a month in a calendar: months before the year plus the month.
IV
_cal_months_index(id, y, m)
        SV *id
        IV y
        IV m
    PREINIT:
        int k;
    CODE:
        k = tk_cal_id_from_sv(aTHX_ id, "_cal_months_index");
        RETVAL = (IV)(tk_cal_months_before(&tk_calendars[k], (int64_t)y) + m);
    OUTPUT:
        RETVAL
