# Counts over a month or a year, and an iterator of business days with no
# cap.

MODULE = Time::Keeper::Business    PACKAGE = Time::Keeper::Business

SV *
business_days_in(self, ...)
        SV *self
    ALIAS:
        business_hours_in = 1
    PREINIT:
        const char *what = ix ? "Time::Keeper::Business->business_hours_in" : "Time::Keeper::Business->business_days_in";
        tkb_schedule *s;
        int64_t first, next, y;
        unsigned m, d;
        SV *number = NULL;
        I32 opts;
    CODE:
        s = tkb_schedule_of(aTHX_ self, what);
        if (items >= 3 && !SvROK(ST(1)) && SvOK(ST(1)) && strEQ(SvPV_nolen(ST(1)), "year")) {
            if (!tkb_sv_to_i64(aTHX_ ST(2), &y))
                croak("%s: the year is not a whole number", what);
            first = tkb_days_from_civil(y, 1, 1);
            next = tkb_days_from_civil(y + 1, 1, 1);
            opts = 3;
        }
        else if (items >= 2) {
            tkb_val v;
            tkb_in_or_croak(aTHX_ ST(1), &v, what);
            if (ix && v.kind == TKB_KIND_KEEPER)
                croak("%s: a value gives its day; give a Time::Keeper::Date for a day, a YearMonth for a month, or year => \\$y", what);
            if (ix && v.kind == TKB_KIND_DATE) {
                first = v.day;
                next = v.day + 1;
            }
            else {
                tkb_civil_from_days(v.day, &y, &m, &d);
                first = tkb_days_from_civil(y, m, 1);
                next = m == 12 ? tkb_days_from_civil(y + 1, 1, 1) : tkb_days_from_civil(y, m + 1, 1);
            }
            opts = 2;
        }
        else
            croak("%s: takes a month (a YearMonth, or any value of the month), %syear => $y", what, ix ? "a Time::Keeper::Date for a day, " : "");
        if (!ix) {
            if (items > opts)
                croak("%s: takes no options", what);
            RETVAL = tkb_i64_sv(aTHX_ tkb_between(aTHX_ s, first, next, what));
        }
        else {
            int64_t ns = 0, dd;
            SV *buf = sv_2mortal(newSVpvs(""));
            number = tkb_opt(aTHX_ &ST(opts), items - opts, "number", what);
            tkb_need_hours(aTHX_ s, what);
            if (next - first > 366 * 2)
                croak("%s: a span of more than a year; ask year by year", what);
            for (dd = first; dd < next; dd++) {
                if (s->hours.elapsed) {
                    size_t n = tkb_day_iv(aTHX_ s, dd, buf, what), k;
                    const int64_t *iv = (const int64_t *)SvPVX(buf);
                    for (k = 0; k < n; k++)
                        ns += (iv[2 * k + 1] - iv[2 * k]) * TKB_NS_PER_SEC;
                }
                else
                    ns += (int64_t)tkb_hours_on(aTHX_ s, dd, what)->total * TKB_NS_PER_SEC;
            }
            if (number && SvTRUE(number))
                RETVAL = newSVnv((NV)ns / 3.6e12);
            else
                RETVAL = tkb_duration_hours(aTHX_ ns);
        }
    OUTPUT:
        RETVAL

void
_iterate_business_days_step(...)
    PREINIT:
        const char *what = "Time::Keeper::Business->iterate_business_days";
        MAGIC *mg;
        AV *st = NULL;
        tkb_schedule *s;
        tkb_val v;
        int64_t day, end = 0, d;
        int has_end;
        SV **e;
    PPCODE:
        PERL_UNUSED_VAR(items);
        for (mg = SvMAGIC((SV *)cv); mg; mg = mg->mg_moremagic)
            if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &tkb_iter_vtbl)
                st = (AV *)mg->mg_obj;
        if (!st)
            croak("%s: the iterator is not one", what);
        e = av_fetch(st, 4, 0);
        if (e && SvTRUE(*e))
            XSRETURN_UNDEF;
        s = tkb_schedule_of(aTHX_ *av_fetch(st, 0, 0), what);
        e = av_fetch(st, 5, 0);
        if (e && SvOK(*e)) {
            Zero(&v, 1, tkb_val);
            v.kind = TKB_KIND_DATE;
            v.sv = *av_fetch(st, 1, 0);
            if (SvIOK(*e) && !SvPOK(*e)) {
                v.locale = (int)SvIV(*e);
                v.has_lid = 1;
            }
            else
                v.locale_sv = *e;
        }
        else
            tkb_in_day(aTHX_ *av_fetch(st, 1, 0), &v, what);
        if (!tkb_sv_to_i64(aTHX_ *av_fetch(st, 2, 0), &day))
            croak("%s: the iterator's state is damaged", what);
        e = av_fetch(st, 3, 0);
        has_end = e && SvOK(*e) && tkb_sv_to_i64(aTHX_ *e, &end);
        if (has_end && day > end) {
            av_store(st, 4, newSViv(1));
            XSRETURN_UNDEF;
        }
        PUTBACK;
        tkb_ensure(aTHX_ s, day, what);
        d = tkb_is_business(s, day) ? day : tkb_next(aTHX_ s, day, 1, what);
        SPAGAIN;
        if (has_end && d > end) {
            av_store(st, 4, newSViv(1));
            XSRETURN_UNDEF;
        }
        av_store(st, 2, tkb_i64_sv(aTHX_ d + 1));
        PUTBACK;
        {
            SV *out = tkb_out(aTHX_ &v, d, what);
            SPAGAIN;
            XPUSHs(sv_2mortal(out));
        }

SV *
iterate_business_days(self, from, ...)
        SV *self
        SV *from
    PREINIT:
        const char *what = "Time::Keeper::Business->iterate_business_days";
        tkb_val v, w;
        AV *st;
        CV *it;
    CODE:
        (void)tkb_schedule_of(aTHX_ self, what);
        tkb_in_day(aTHX_ from, &v, what);
        st = newAV();
        av_push(st, newSVsv(self));
        av_push(st, newSVsv(from));
        av_push(st, tkb_i64_sv(aTHX_ v.day));
        if (items > 2 && SvOK(ST(2))) {
            tkb_in_day(aTHX_ ST(2), &w, what);
            av_push(st, tkb_i64_sv(aTHX_ w.day));
        }
        else
            av_push(st, newSV(0));
        if (items > 3)
            croak("%s: takes a start and an end, or a start alone", what);
        av_push(st, newSViv(0));
        av_push(st, v.kind != TKB_KIND_DATE ? newSV(0) : v.has_lid ? newSViv(v.locale) : v.locale_sv ? newSVsv(v.locale_sv) : newSV(0));
        it = newXS(NULL, XS_Time__Keeper__Business__iterate_business_days_step, __FILE__);
        sv_magicext((SV *)it, (SV *)st, PERL_MAGIC_ext, &tkb_iter_vtbl, NULL, 0);
        SvREFCNT_dec((SV *)st);
        RETVAL = newRV_noinc((SV *)it);
    OUTPUT:
        RETVAL
