# Doors for the tests only.

MODULE = Time::Keeper::Business    PACKAGE = Time::Keeper::Business

# The core's table, found if it has not been; its version.
IV
_abi_version()
    CODE:
        RETVAL = tkb_abi(aTHX)->abi_version;
    OUTPUT:
        RETVAL

# The version of the core's table this needs.
IV
_abi_built()
    CODE:
        RETVAL = TKB_ABI_NEEDS;
    OUTPUT:
        RETVAL

# The version of the core's header this was compiled against.
IV
_abi_header()
    CODE:
        RETVAL = TIME_KEEPER_ABI_VERSION;
    OUTPUT:
        RETVAL

# Whether the table has been looked for yet, without looking.
IV
_abi_resolved()
    CODE:
        RETVAL = tkb_table ? 1 : 0;
    OUTPUT:
        RETVAL

# Lets go of the table, so the next use looks for it again.
void
_abi_forget()
    CODE:
        tkb_table = NULL;

# The current time through the table, as the epoch second: the one entry
# called in this phase, so the resolve is seen to work end to end.
IV
_abi_now()
    PREINIT:
        time_keeper_instant t;
    CODE:
        if (TKB(now)(&t) != TIME_KEEPER_OK)
            croak("Time::Keeper::Business: the clock could not be read");
        RETVAL = (IV)t.sec;
    OUTPUT:
        RETVAL

# 2**62 + 1 worked out in C and written digit by digit, so the test does
# not depend on the IV: int64_t must be 64 bits on every perl.
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

IV
_days_from_civil(y, m, d)
        IV y
        IV m
        IV d
    CODE:
        RETVAL = (IV)tkb_days_from_civil(y, (unsigned)m, (unsigned)d);
    OUTPUT:
        RETVAL

void
_civil_from_days(day)
        IV day
    PREINIT:
        int64_t y;
        unsigned m, d;
    PPCODE:
        tkb_civil_from_days(day, &y, &m, &d);
        EXTEND(SP, 4);
        mPUSHi((IV)y);
        mPUSHi(m);
        mPUSHi(d);
        mPUSHi(tkb_dow_from_days(day));

# The schedule's arrays: how many closed weekdays, worked weekend days and
# holidays it holds, and the business days a week.
void
_counts(self)
        SV *self
    PREINIT:
        tkb_schedule *s;
    PPCODE:
        s = tkb_schedule_of(aTHX_ self, "_counts");
        EXTEND(SP, 4);
        mPUSHi((IV)s->n_closed);
        mPUSHi((IV)s->n_open);
        mPUSHi((IV)s->n_names);
        mPUSHi(s->per_week);

void
_closed_days(self)
        SV *self
    ALIAS:
        _open_days = 1
    PREINIT:
        tkb_schedule *s;
        size_t i, n;
        const int64_t *a;
    PPCODE:
        s = tkb_schedule_of(aTHX_ self, "_closed_days");
        a = ix ? s->open : s->closed;
        n = ix ? s->n_open : s->n_closed;
        EXTEND(SP, (SSize_t)n);
        for (i = 0; i < n; i++)
            mPUSHs(tkb_day_string(aTHX_ a[i]));

# A value moved to a day: what the business-day arithmetic will hand back.
SV *
_on_day(value, day)
        SV *value
        IV day
    PREINIT:
        tkb_val v;
    CODE:
        tkb_in_or_croak(aTHX_ value, &v, "_on_day");
        RETVAL = tkb_out(aTHX_ &v, (int64_t)day, "_on_day");
    OUTPUT:
        RETVAL

# The years a lazy schedule has materialised: nothing for a literal
# schedule, 'none' before the first question, else the first and last year.
void
_materialised_span(self)
        SV *self
    PREINIT:
        tkb_schedule *s;
    PPCODE:
        s = tkb_schedule_of(aTHX_ self, "_materialised_span");
        if (!s->lazy)
            XSRETURN_EMPTY;
        if (s->year_lo > s->year_hi)
            XSRETURN_PV("none");
        EXTEND(SP, 2);
        mPUSHs(tkb_i64_sv(aTHX_ s->year_lo));
        mPUSHs(tkb_i64_sv(aTHX_ s->year_hi));

# The business days in [from, to), a day at a time: the control for the
# formula.
IV
_between_slow(self, from, to)
        SV *self
        IV from
        IV to
    PREINIT:
        tkb_schedule *s;
        IV d, n = 0;
    CODE:
        s = tkb_schedule_of(aTHX_ self, "_between_slow");
        tkb_ensure_span(aTHX_ s, from, to, "_between_slow");
        for (d = from; d < to; d++)
            n += tkb_is_business(s, d);
        RETVAL = n;
    OUTPUT:
        RETVAL

# A value split on the schedule's wall clock: the day, the seconds of it
# and the nanoseconds.
void
_split(self, value)
        SV *self
        SV *value
    PREINIT:
        tkb_schedule *s;
        tkb_val v;
        int64_t day;
        int32_t secs, nsec;
    PPCODE:
        s = tkb_schedule_of(aTHX_ self, "_split");
        tkb_need_hours(aTHX_ s, "_split");
        tkb_in_or_croak(aTHX_ value, &v, "_split");
        tkb_split(aTHX_ s, &v, &day, &secs, &nsec, "_split");
        EXTEND(SP, 3);
        mPUSHs(tkb_i64_sv(aTHX_ day));
        mPUSHi(secs);
        mPUSHi(nsec);

# The hours table as parsed: for each weekday and each dated override, the
# spans as "start-end" in seconds, and the weekly total.
void
_hours_table(self)
        SV *self
    PREINIT:
        tkb_schedule *s;
        int i, j;
        size_t k;
    PPCODE:
        s = tkb_schedule_of(aTHX_ self, "_hours_table");
        for (i = 0; i < 7; i++) {
            SV *line = newSVpvf("%s:", tkb_dow_names[i]);
            for (j = 0; j < s->hours.week[i].n; j++)
                sv_catpvf(line, " %d-%d", (int)s->hours.week[i].spans[j].start, (int)s->hours.week[i].spans[j].end);
            mXPUSHs(line);
        }
        for (k = 0; k < s->hours.n_dated; k++) {
            SV *line = tkb_day_string(aTHX_ s->hours.dated[k].day);
            sv_catpvs(line, ":");
            for (j = 0; j < s->hours.dated[k].hours.n; j++)
                sv_catpvf(line, " %d-%d", (int)s->hours.dated[k].hours.spans[j].start, (int)s->hours.dated[k].hours.spans[j].end);
            mXPUSHs(line);
        }
        mXPUSHi(s->hours.weekly_total);
