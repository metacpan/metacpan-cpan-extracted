# The calendar of a value, its reading of the date, and the
# Time::Keeper::Calendar class.

MODULE = Time::Keeper    PACKAGE = Time::Keeper

SV *
calendar(self)
        SV *self
    PREINIT:
        const tk_value *v;
    CODE:
        v = tk_value_of(aTHX_ self, "Time::Keeper->calendar");
        RETVAL = newSVpv(tk_cal_of(v)->id, 0);
    OUTPUT:
        RETVAL

SV *
in_calendar(self, calendar)
        SV *self
        SV *calendar
    PREINIT:
        const char *what = "Time::Keeper->in_calendar";
        tk_value *v, nv;
        int id;
    CODE:
        v = tk_value_rw(self, what);
        id = tk_cal_id_from_sv(aTHX_ calendar, what);
        tk_cal_check_built(aTHX_ id, what);
        nv = *v;
        tk_value_set_calendar(&nv, id);
        RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(self)), &nv);
    OUTPUT:
        RETVAL

IV
era_year(self)
        SV *self
    ALIAS:
        months_in_year = 1
        is_leap_month = 2
        related_year = 3
    PREINIT:
        static const char *const whats[] = {
            "Time::Keeper->era_year", "Time::Keeper->months_in_year", "Time::Keeper->is_leap_month", "Time::Keeper->related_year"
        };
        const tk_value *v;
        tk_calfields f;
    CODE:
        v = tk_value_of(aTHX_ self, whats[ix]);
        tk_value_calfields(aTHX_ v, &f, whats[ix]);
        switch (ix) {
        case 0:  RETVAL = (IV)f.era_year; break;
        case 1:  RETVAL = f.months_in_year; break;
        case 2:  RETVAL = f.leap_month; break;
        default: RETVAL = (IV)tk_cal_related_year(tk_cal_of(v), f.year); break;
        }
    OUTPUT:
        RETVAL

SV *
era(self)
        SV *self
    ALIAS:
        month_code = 1
        cyclic_year = 2
    PREINIT:
        static const char *const whats[] = { "Time::Keeper->era", "Time::Keeper->month_code", "Time::Keeper->cyclic_year" };
        const tk_value *v;
        tk_calfields f;
    CODE:
        v = tk_value_of(aTHX_ self, whats[ix]);
        if (ix == 2) {
            if (v->calendar == TK_CAL_CHINESE || v->calendar == TK_CAL_DANGI) {
                tk_value_calfields(aTHX_ v, &f, whats[ix]);
                RETVAL = newSViv(tk_lunisolar_cyclic_year(f.year));
            }
            else
                RETVAL = &PL_sv_undef;
        }
        else {
            tk_value_calfields(aTHX_ v, &f, whats[ix]);
            RETVAL = ix == 0 ? newSVpv(tk_cal_of(v)->eras[f.era].code, 0) : tk_cal_month_code_sv(aTHX_ &f);
        }
    OUTPUT:
        RETVAL

MODULE = Time::Keeper    PACKAGE = Time::Keeper::Calendar

void
ids(class)
        SV *class
    PREINIT:
        int k;
    PPCODE:
        PERL_UNUSED_VAR(class);
        EXTEND(SP, TK_CAL_COUNT);
        for (k = 0; k < TK_CAL_COUNT; k++)
            mPUSHs(newSVpv(tk_calendars[k].id, 0));

SV *
name(class, id)
        SV *class
        SV *id
    ALIAS:
        kind = 1
        canonical = 2
    PREINIT:
        static const char *const whats[] = { "Time::Keeper::Calendar->name", "Time::Keeper::Calendar->kind", "Time::Keeper::Calendar->canonical" };
        static const char *const kinds[] = { "arithmetic", "tabular", "astronomical" };
        int k;
    CODE:
        PERL_UNUSED_VAR(class);
        k = tk_cal_id_from_sv(aTHX_ id, whats[ix]);
        RETVAL = newSVpv(ix == 0 ? tk_calendars[k].name : ix == 1 ? kinds[tk_calendars[k].kind] : tk_calendars[k].id, 0);
    OUTPUT:
        RETVAL

void
eras(class, id)
        SV *class
        SV *id
    PREINIT:
        int k;
        unsigned i;
    PPCODE:
        PERL_UNUSED_VAR(class);
        k = tk_cal_id_from_sv(aTHX_ id, "Time::Keeper::Calendar->eras");
        EXTEND(SP, (IV)tk_calendars[k].n_eras);
        for (i = 0; i < tk_calendars[k].n_eras; i++)
            mPUSHs(newSVpv(tk_calendars[k].eras[i].code, 0));

IV
months_in_year(class, id, year)
        SV *class
        SV *id
        SV *year
    ALIAS:
        days_in_year = 1
        is_leap_year = 2
    PREINIT:
        static const char *const whats[] = {
            "Time::Keeper::Calendar->months_in_year", "Time::Keeper::Calendar->days_in_year", "Time::Keeper::Calendar->is_leap_year"
        };
        int k;
        int64_t y;
    CODE:
        PERL_UNUSED_VAR(class);
        k = tk_cal_id_from_sv(aTHX_ id, whats[ix]);
        tk_cal_check_built(aTHX_ k, whats[ix]);
        y = tk_opt_int(aTHX_ year, whats[ix], "year", -TK_CAL_YEAR_LIMIT, TK_CAL_YEAR_LIMIT);
        RETVAL = ix == 0 ? tk_calendars[k].months_in_year(y) : ix == 1 ? tk_cal_days_in_year(&tk_calendars[k], y) : tk_calendars[k].is_leap_year(y);
    OUTPUT:
        RETVAL

IV
days_in_month(class, id, year, month)
        SV *class
        SV *id
        SV *year
        SV *month
    PREINIT:
        const char *what = "Time::Keeper::Calendar->days_in_month";
        int k;
        int64_t y;
        unsigned m;
    CODE:
        PERL_UNUSED_VAR(class);
        k = tk_cal_id_from_sv(aTHX_ id, what);
        tk_cal_check_built(aTHX_ k, what);
        y = tk_opt_int(aTHX_ year, what, "year", -TK_CAL_YEAR_LIMIT, TK_CAL_YEAR_LIMIT);
        if (SvPOK(month) && SvPVX(month)[0] == 'M') {
            if (!tk_cal_month_from_code_sv(aTHX_ &tk_calendars[k], y, month, &m, what))
                croak("%s: the %s year %" IVdf " has no month %s", what, tk_calendars[k].id, (IV)y, SvPV_nolen(month));
        }
        else
            m = (unsigned)tk_opt_int(aTHX_ month, what, "month", 1, tk_calendars[k].max_months);
        if (m > tk_calendars[k].months_in_year(y))
            croak("%s: the %s year %" IVdf " has %u months, not %u", what, tk_calendars[k].id, (IV)y, tk_calendars[k].months_in_year(y), m);
        RETVAL = tk_calendars[k].days_in_month(y, m);
    OUTPUT:
        RETVAL

SV *
month_code(class, id, year, month)
        SV *class
        SV *id
        SV *year
        SV *month
    PREINIT:
        const char *what = "Time::Keeper::Calendar->month_code";
        int k;
        int64_t y;
        unsigned m;
        tk_calfields f;
    CODE:
        PERL_UNUSED_VAR(class);
        k = tk_cal_id_from_sv(aTHX_ id, what);
        tk_cal_check_built(aTHX_ k, what);
        y = tk_opt_int(aTHX_ year, what, "year", -TK_CAL_YEAR_LIMIT, TK_CAL_YEAR_LIMIT);
        m = (unsigned)tk_opt_int(aTHX_ month, what, "month", 1, tk_calendars[k].max_months);
        if (m > tk_calendars[k].months_in_year(y))
            croak("%s: the %s year %" IVdf " has %u months, not %u", what, tk_calendars[k].id, (IV)y, tk_calendars[k].months_in_year(y), m);
        if (tk_calendars[k].month_code)
            tk_calendars[k].month_code(y, m, &f.month_number, &f.leap_month);
        else {
            f.month_number = m;
            f.leap_month = 0;
        }
        RETVAL = tk_cal_month_code_sv(aTHX_ &f);
    OUTPUT:
        RETVAL

void
names(class, id, locale, what, ...)
        SV *class
        SV *id
        SV *locale
        const char *what
    PREINIT:
        const char *me = "Time::Keeper::Calendar->names";
        int k, n;
    PPCODE:
        PERL_UNUSED_VAR(class);
        k = tk_cal_id_from_sv(aTHX_ id, me);
        tk_cal_check_built(aTHX_ k, me);
        {
            SV *w = items > 4 ? ST(4) : sv_2mortal(newSVpvs("wide"));
            SV *ctx = items > 5 ? ST(5) : sv_2mortal(newSVpvs("format"));
            PUSHMARK(SP);
            EXTEND(SP, 6);
            PUSHs(sv_2mortal(newSVpvs("Time::Keeper::Locale")));
            PUSHs(locale);
            PUSHs(sv_2mortal(newSVpv(what, 0)));
            PUSHs(w);
            PUSHs(ctx);
            PUSHs(sv_2mortal(newSVpv(tk_calendars[k].id, 0)));
            PUTBACK;
            n = call_method("names", G_ARRAY);
            SPAGAIN;
        }
        XSRETURN(n);

void
preferred(class, where)
        SV *class
        SV *where
    PREINIT:
        const char *ids, *p;
    PPCODE:
        PERL_UNUSED_VAR(class);
        ids = tk_cal_preferred_ids(aTHX_ where, "Time::Keeper::Calendar->preferred");
        for (p = ids; *p; ) {
            const char *e = p;
            while (*e && *e != ' ')
                e++;
            XPUSHs(sv_2mortal(newSVpvn(p, (STRLEN)(e - p))));
            p = *e ? e + 1 : e;
        }

SV *
era_start(class, id, code)
        SV *class
        SV *id
        SV *code
    PREINIT:
        const char *what = "Time::Keeper::Calendar->era_start";
        int k;
        unsigned i;
        STRLEN len;
        const char *s;
        tk_value v;
        int64_t y;
        unsigned m, d;
    CODE:
        PERL_UNUSED_VAR(class);
        k = tk_cal_id_from_sv(aTHX_ id, what);
        s = SvPV(code, len);
        for (i = 0; i < tk_calendars[k].n_eras; i++)
            if (tk_ieq(s, len, tk_calendars[k].eras[i].code))
                break;
        if (i == tk_calendars[k].n_eras)
            croak("%s: the %s calendar has no era '%" SVf "'", what, tk_calendars[k].id, SVfARG(code));
        if (tk_calendars[k].eras[i].start == TK_ERA_FROM_THE_START)
            XSRETURN_UNDEF;
        tk_civil_from_days(tk_calendars[k].eras[i].start, &y, &m, &d);
        tk_plain_make(aTHX_ &v, TK_KIND_DATE, y, m, d, 0, what);
        RETVAL = tk_value_new_sv(aTHX_ tk_plain_stash(aTHX_ TK_KIND_DATE), &v);
    OUTPUT:
        RETVAL
