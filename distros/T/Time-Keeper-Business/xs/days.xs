# Business-day arithmetic: the next and previous, a roll by convention,
# days on, the count between, the list, the nth of a month.

MODULE = Time::Keeper::Business    PACKAGE = Time::Keeper::Business

SV *
next_business_day(self, value)
        SV *self
        SV *value
    ALIAS:
        previous_business_day = 1
    PREINIT:
        const char *what = ix ? "Time::Keeper::Business->previous_business_day" : "Time::Keeper::Business->next_business_day";
        tkb_schedule *s;
        tkb_val v;
    CODE:
        s = tkb_schedule_of(aTHX_ self, what);
        tkb_in_day(aTHX_ value, &v, what);
        RETVAL = tkb_out(aTHX_ &v, tkb_next(aTHX_ s, v.day, ix ? -1 : 1, what), what);
    OUTPUT:
        RETVAL

SV *
roll(self, value, ...)
        SV *self
        SV *value
    PREINIT:
        const char *what = "Time::Keeper::Business->roll";
        tkb_schedule *s;
        tkb_val v;
        SV *conv;
        int c = TKB_ROLL_FOLLOWING;
    CODE:
        s = tkb_schedule_of(aTHX_ self, what);
        tkb_in_day(aTHX_ value, &v, what);
        conv = tkb_opt(aTHX_ &ST(2), items - 2, "convention", what);
        if (conv)
            c = tkb_roll_of_sv(aTHX_ conv, what);
        RETVAL = tkb_out(aTHX_ &v, tkb_roll(aTHX_ s, v.day, c, what), what);
    OUTPUT:
        RETVAL

SV *
plus_business_days(self, value, n, ...)
        SV *self
        SV *value
        SV *n
    ALIAS:
        minus_business_days = 1
    PREINIT:
        const char *what = ix ? "Time::Keeper::Business->minus_business_days" : "Time::Keeper::Business->plus_business_days";
        tkb_schedule *s;
        tkb_val v;
        int64_t count;
        SV *conv;
        int c = -1;
    CODE:
        s = tkb_schedule_of(aTHX_ self, what);
        tkb_in_day(aTHX_ value, &v, what);
        if (!tkb_sv_to_i64(aTHX_ n, &count))
            croak("%s: the number of days is not a whole number", what);
        if (count > (int64_t)366 * 1000000000 || count < -(int64_t)366 * 1000000000)
            croak("%s: the number of days is out of range", what);
        conv = tkb_opt(aTHX_ &ST(3), items - 3, "roll", what);
        if (conv)
            c = tkb_roll_of_sv(aTHX_ conv, what);
        RETVAL = tkb_out(aTHX_ &v, tkb_plus(aTHX_ s, v.day, ix ? -count : count, c, what), what);
    OUTPUT:
        RETVAL

SV *
business_days_between(self, from, to, ...)
        SV *self
        SV *from
        SV *to
    PREINIT:
        const char *what = "Time::Keeper::Business->business_days_between";
        tkb_schedule *s;
        tkb_val a, b;
        SV *inc;
        int64_t n;
    CODE:
        s = tkb_schedule_of(aTHX_ self, what);
        tkb_in_day(aTHX_ from, &a, what);
        tkb_in_day(aTHX_ to, &b, what);
        inc = tkb_opt(aTHX_ &ST(3), items - 3, "include_end", what);
        n = tkb_between(aTHX_ s, a.day, b.day, what);
        if (inc && SvTRUE(inc) && tkb_is_business(s, b.day))
            n += b.day >= a.day ? 1 : -1;
        RETVAL = tkb_i64_sv(aTHX_ n);
    OUTPUT:
        RETVAL

void
business_days(self, from, to)
        SV *self
        SV *from
        SV *to
    PREINIT:
        const char *what = "Time::Keeper::Business->business_days";
        tkb_schedule *s;
        tkb_val a, b;
        int64_t lo, hi, d, count;
    PPCODE:
        s = tkb_schedule_of(aTHX_ self, what);
        tkb_in_day(aTHX_ from, &a, what);
        tkb_in_day(aTHX_ to, &b, what);
        lo = a.day < b.day ? a.day : b.day;
        hi = a.day < b.day ? b.day : a.day;
        count = tkb_between(aTHX_ s, lo, hi + 1, what);
        if (count > TKB_LIST_LIMIT)
            croak("%s: more than ten million business days; narrow the span", what);
        for (d = lo; d <= hi; d++) {
            SV *out;
            if (!tkb_is_business(s, d))
                continue;
            PUTBACK;
            out = tkb_out(aTHX_ &a, d, what);
            SPAGAIN;
            XPUSHs(sv_2mortal(out));
        }

SV *
nth_business_day(self, value, n)
        SV *self
        SV *value
        SV *n
    PREINIT:
        const char *what = "Time::Keeper::Business->nth_business_day";
        tkb_schedule *s;
        tkb_val v;
        int64_t count;
    CODE:
        s = tkb_schedule_of(aTHX_ self, what);
        tkb_in_or_croak(aTHX_ value, &v, what);
        if (!tkb_sv_to_i64(aTHX_ n, &count))
            croak("%s: n is not a whole number", what);
        RETVAL = tkb_out(aTHX_ &v, tkb_nth_in_month(aTHX_ s, v.day, count, what), what);
    OUTPUT:
        RETVAL

SV *
last_business_day(self, value)
        SV *self
        SV *value
    PREINIT:
        const char *what = "Time::Keeper::Business->last_business_day";
        tkb_schedule *s;
        tkb_val v;
    CODE:
        s = tkb_schedule_of(aTHX_ self, what);
        tkb_in_or_croak(aTHX_ value, &v, what);
        RETVAL = tkb_out(aTHX_ &v, tkb_nth_in_month(aTHX_ s, v.day, -1, what), what);
    OUTPUT:
        RETVAL
