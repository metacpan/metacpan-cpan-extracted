# Business hours: whether a moment is inside them, the opens and closes
# around it, and a day's spans.

MODULE = Time::Keeper::Business    PACKAGE = Time::Keeper::Business

int
is_business_hours(self, value)
        SV *self
        SV *value
    PREINIT:
        const char *what = "Time::Keeper::Business->is_business_hours";
        tkb_schedule *s;
        tkb_val v;
        int64_t day;
        int32_t secs, nsec;
    CODE:
        s = tkb_schedule_of(aTHX_ self, what);
        tkb_need_hours(aTHX_ s, what);
        tkb_in_or_croak(aTHX_ value, &v, what);
        tkb_split(aTHX_ s, &v, &day, &secs, &nsec, what);
        tkb_canon(aTHX_ s, &day, &secs, what);
        RETVAL = tkb_span_at(tkb_hours_on(aTHX_ s, day, what), secs) >= 0;
    OUTPUT:
        RETVAL

SV *
next_open(self, value)
        SV *self
        SV *value
    ALIAS:
        next_close = 1
        previous_open = 2
        previous_close = 3
    PREINIT:
        static const char *const names[] = {
            "Time::Keeper::Business->next_open", "Time::Keeper::Business->next_close",
            "Time::Keeper::Business->previous_open", "Time::Keeper::Business->previous_close" };
        const char *what = names[ix];
        tkb_schedule *s;
        tkb_val v;
        int64_t day;
        int32_t secs, nsec;
    CODE:
        s = tkb_schedule_of(aTHX_ self, what);
        tkb_need_hours(aTHX_ s, what);
        tkb_in_or_croak(aTHX_ value, &v, what);
        tkb_split(aTHX_ s, &v, &day, &secs, &nsec, what);
        tkb_canon(aTHX_ s, &day, &secs, what);
        if (ix == 0 && tkb_span_at(tkb_hours_on(aTHX_ s, day, what), secs) >= 0)
            RETVAL = newSVsv(value);
        else {
            switch (ix) {
            case 0: tkb_next_open(aTHX_ s, &day, &secs, &nsec, what); break;
            case 1: tkb_next_close(aTHX_ s, &day, &secs, &nsec, what); break;
            case 2: tkb_previous_open(aTHX_ s, &day, &secs, &nsec, what); break;
            default: tkb_previous_close(aTHX_ s, &day, &secs, &nsec, what); break;
            }
            RETVAL = tkb_join(aTHX_ s, day, secs, nsec, &v, what);
        }
    OUTPUT:
        RETVAL

void
business_hours_on(self, value)
        SV *self
        SV *value
    PREINIT:
        const char *what = "Time::Keeper::Business->business_hours_on";
        tkb_schedule *s;
        tkb_val v;
        int64_t day;
        int32_t secs, nsec;
        const tkb_day *d;
        int i;
    PPCODE:
        s = tkb_schedule_of(aTHX_ self, what);
        tkb_need_hours(aTHX_ s, what);
        tkb_in_day(aTHX_ value, &v, what);
        if (v.kind == TKB_KIND_KEEPER)
            tkb_split(aTHX_ s, &v, &day, &secs, &nsec, what);
        else
            day = v.day;
        d = tkb_hours_on(aTHX_ s, day, what);
        for (i = 0; i < d->n; i++) {
            AV *pair = newAV();
            SV *open, *close;
            PUTBACK;
            open = tkb_join(aTHX_ s, day, d->spans[i].start, 0, &v, what);
            close = tkb_join(aTHX_ s, day, d->spans[i].end, 0, &v, what);
            SPAGAIN;
            av_push(pair, open);
            av_push(pair, close);
            XPUSHs(sv_2mortal(newRV_noinc((SV *)pair)));
        }

SV *
plus_business_hours(self, value, ...)
        SV *self
        SV *value
    ALIAS:
        minus_business_hours = 1
    PREINIT:
        const char *what = ix ? "Time::Keeper::Business->minus_business_hours" : "Time::Keeper::Business->plus_business_hours";
        tkb_schedule *s;
        tkb_val v;
        int64_t day, amount, days;
        int32_t secs, nsec;
        int eod;
    CODE:
        s = tkb_schedule_of(aTHX_ self, what);
        tkb_need_hours(aTHX_ s, what);
        tkb_in_or_croak(aTHX_ value, &v, what);
        tkb_split(aTHX_ s, &v, &day, &secs, &nsec, what);
        tkb_canon(aTHX_ s, &day, &secs, what);
        tkb_amount(aTHX_ &ST(2), items - 2, 0, &amount, &days, &eod, what);
        if (s->hours.elapsed) {
            tkb_inst at, out;
            at.sec = v.inst.sec;
            at.nsec = v.inst.nsec;
            tkb_add_time_elapsed(aTHX_ s, day, secs, nsec, &at, ix ? -amount : amount, &out, what);
            RETVAL = tkb_inst_out(aTHX_ &out, &v, what);
        }
        else {
            tkb_add_time(aTHX_ s, &day, &secs, &nsec, ix ? -amount : amount, what);
            RETVAL = tkb_join(aTHX_ s, day, secs, nsec, &v, what);
        }
    OUTPUT:
        RETVAL

SV *
business_hours_between(self, from, to, ...)
        SV *self
        SV *from
        SV *to
    PREINIT:
        const char *what = "Time::Keeper::Business->business_hours_between";
        tkb_schedule *s;
        tkb_val a, b;
        int64_t a_day, b_day, ns;
        int32_t a_secs, a_nsec, b_secs, b_nsec;
        SV *number;
    CODE:
        s = tkb_schedule_of(aTHX_ self, what);
        tkb_need_hours(aTHX_ s, what);
        tkb_in_or_croak(aTHX_ from, &a, what);
        tkb_in_or_croak(aTHX_ to, &b, what);
        number = tkb_opt(aTHX_ &ST(3), items - 3, "number", what);
        tkb_split(aTHX_ s, &a, &a_day, &a_secs, &a_nsec, what);
        tkb_split(aTHX_ s, &b, &b_day, &b_secs, &b_nsec, what);
        tkb_canon(aTHX_ s, &a_day, &a_secs, what);
        tkb_canon(aTHX_ s, &b_day, &b_secs, what);
        if (s->hours.elapsed) {
            tkb_inst ai, bi;
            ai.sec = a.inst.sec; ai.nsec = a.inst.nsec;
            bi.sec = b.inst.sec; bi.nsec = b.inst.nsec;
            if (tkb_zone_steady(aTHX_ &s->hours.zone, tkb_inst_cmp(&ai, &bi) <= 0 ? &ai : &bi, tkb_inst_cmp(&ai, &bi) <= 0 ? &bi : &ai) == 1)
                ns = tkb_time_between(aTHX_ s, a_day, (int64_t)a_secs * TKB_NS_PER_SEC + a_nsec, b_day, (int64_t)b_secs * TKB_NS_PER_SEC + b_nsec, what);
            else
                ns = tkb_time_between_elapsed(aTHX_ s, a_day, &ai, b_day, &bi, what);
        }
        else
            ns = tkb_time_between(aTHX_ s, a_day, (int64_t)a_secs * TKB_NS_PER_SEC + a_nsec, b_day, (int64_t)b_secs * TKB_NS_PER_SEC + b_nsec, what);
        if (number && SvTRUE(number))
            RETVAL = newSVnv((NV)ns / 3.6e12);
        else
            RETVAL = tkb_duration_hours(aTHX_ ns);
    OUTPUT:
        RETVAL

SV *
deadline(self, value, ...)
        SV *self
        SV *value
    PREINIT:
        const char *what = "Time::Keeper::Business->deadline";
        tkb_schedule *s;
        tkb_val v;
        int64_t day, amount, days;
        int32_t secs, nsec;
        int eod;
        const tkb_day *d;
        int64_t day0;
        int32_t secs0;
    CODE:
        s = tkb_schedule_of(aTHX_ self, what);
        tkb_need_hours(aTHX_ s, what);
        tkb_in_or_croak(aTHX_ value, &v, what);
        tkb_split(aTHX_ s, &v, &day, &secs, &nsec, what);
        tkb_canon(aTHX_ s, &day, &secs, what);
        tkb_amount(aTHX_ &ST(2), items - 2, 1, &amount, &days, &eod, what);
        if (amount < 0 || days < 0)
            croak("%s: a deadline lies ahead: the amounts must not be negative", what);
        day0 = day;
        secs0 = secs;
        tkb_next_open(aTHX_ s, &day, &secs, &nsec, what);
        if (days) {
            day = tkb_plus(aTHX_ s, day, days, -1, what);
            tkb_next_open(aTHX_ s, &day, &secs, &nsec, what);
        }
        if (eod) {
            d = tkb_hours_on(aTHX_ s, day, what);
            secs = d->spans[d->n - 1].end;
            nsec = 0;
        }
        if (amount && s->hours.elapsed) {
            tkb_inst at, out;
            int same = !days && !eod && tkb_span_at(tkb_hours_on(aTHX_ s, day0, what), secs0) >= 0;
            at.sec = v.inst.sec;
            at.nsec = v.inst.nsec;
            tkb_add_time_elapsed(aTHX_ s, day, secs, nsec, same ? &at : NULL, amount, &out, what);
            RETVAL = tkb_inst_out(aTHX_ &out, &v, what);
        }
        else {
            if (amount)
                tkb_add_time(aTHX_ s, &day, &secs, &nsec, amount, what);
            RETVAL = tkb_join(aTHX_ s, day, secs, nsec, &v, what);
        }
    OUTPUT:
        RETVAL
