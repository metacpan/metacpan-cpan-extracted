# The plain classes: Time::Keeper::Date, Time::Keeper::YearMonth and
# Time::Keeper::MonthDay. One XSUB serves the classes that share a method,
# by package-qualified aliases; the kind each alias stands for is in a table
# beside it.

MODULE = Time::Keeper    PACKAGE = Time::Keeper::Date

SV *
new(class, ...)
        SV *class
    ALIAS:
        last_day_of_month = 1
        from_day_of_year = 2
        from_iso_week = 3
        Time::Keeper::YearMonth::new = 4
        Time::Keeper::MonthDay::new = 5
    PREINIT:
        static const char *const whats[] = {
            "Time::Keeper::Date->new", "Time::Keeper::Date->last_day_of_month",
            "Time::Keeper::Date->from_day_of_year", "Time::Keeper::Date->from_iso_week",
            "Time::Keeper::YearMonth->new", "Time::Keeper::MonthDay->new"
        };
        static const uint64_t allowed[] = {
            TK_A(TK_A_YEAR) | TK_A(TK_A_MONTH) | TK_A(TK_A_DAY) | TK_A(TK_A_LOCALE),
            TK_A(TK_A_YEAR) | TK_A(TK_A_MONTH) | TK_A(TK_A_LOCALE),
            TK_A(TK_A_YEAR) | TK_A(TK_A_DAY_OF_YEAR) | TK_A(TK_A_LOCALE),
            TK_A(TK_A_YEAR) | TK_A(TK_A_WEEK) | TK_A(TK_A_DAY) | TK_A(TK_A_LOCALE),
            TK_A(TK_A_YEAR) | TK_A(TK_A_MONTH) | TK_A(TK_A_LOCALE),
            TK_A(TK_A_MONTH) | TK_A(TK_A_DAY) | TK_A(TK_A_LOCALE)
        };
        const char *what = whats[ix];
        int kind = ix <= 3 ? TK_KIND_DATE : ix == 4 ? TK_KIND_YEAR_MONTH : TK_KIND_MONTH_DAY;
        tk_args a;
        int64_t y = TK_MONTH_DAY_YEAR;
        unsigned m = 1, d = 1;
        tk_value v;
    CODE:
        tk_args_parse(aTHX_ &ST(1), items - 1, allowed[ix], &a, what);
        if (kind != TK_KIND_MONTH_DAY) {
            if (!a.v[TK_A_YEAR])
                croak("%s: year is required", what);
            y = tk_args_int(aTHX_ &a, TK_A_YEAR, 0, TK_YEAR_MIN, TK_YEAR_MAX, what);
        }
        if (ix <= 3)
            tk_args_ymd(aTHX_ &a, ix, &y, &m, &d, what);
        else {
            if (!a.v[TK_A_MONTH])
                croak("%s: month is required", what);
            m = (unsigned)tk_args_int(aTHX_ &a, TK_A_MONTH, 1, 1, 12, what);
            if (kind == TK_KIND_MONTH_DAY) {
                if (!a.v[TK_A_DAY])
                    croak("%s: day is required", what);
                d = (unsigned)tk_args_int(aTHX_ &a, TK_A_DAY, 1, 1, 31, what);
            }
        }
        tk_plain_make(aTHX_ &v, kind, y, m, d, tk_args_locale(&a, what), what);
        RETVAL = tk_value_new_sv(aTHX_ tk_plain_stash_for(aTHX_ class, kind), &v);
    OUTPUT:
        RETVAL

SV *
today(class, ...)
        SV *class
    PREINIT:
        const char *what = "Time::Keeper::Date->today";
        tk_args a;
        tk_zone_spec z;
        tk_instant t;
        tk_value v, out;
    CODE:
        tk_args_parse(aTHX_ &ST(1), items - 1, TK_A(TK_A_ZONE) | TK_A(TK_A_LOCALE), &a, what);
        tk_zone_spec_from_sv(aTHX_ a.v[TK_A_ZONE], &z, what);
        tk_now_sv(aTHX_ &t);
        tk_value_init(aTHX_ &v, &t, &z);
        v.locale = tk_args_locale(&a, what);
        tk_plain_project(aTHX_ &out, TK_KIND_DATE, &v, what);
        RETVAL = tk_value_new_sv(aTHX_ tk_plain_stash_for(aTHX_ class, TK_KIND_DATE), &out);
    OUTPUT:
        RETVAL

SV *
from_epoch_days(class, days, ...)
        SV *class
        SV *days
    PREINIT:
        const char *what = "Time::Keeper::Date->from_epoch_days";
        tk_args a;
        int64_t n, y;
        unsigned m, d;
        tk_value v;
    CODE:
        tk_args_parse(aTHX_ &ST(2), items - 2, TK_A(TK_A_LOCALE), &a, what);
        if (!tk_sv_to_i64(aTHX_ days, &n))
            croak("%s: the days are not an integer", what);
        if (n < -((int64_t)366 * 1000000000) || n > (int64_t)366 * 1000000000)
            croak("%s: out of range", what);
        tk_civil_from_days(n, &y, &m, &d);
        tk_plain_make(aTHX_ &v, TK_KIND_DATE, y, m, d, tk_args_locale(&a, what), what);
        RETVAL = tk_value_new_sv(aTHX_ tk_plain_stash_for(aTHX_ class, TK_KIND_DATE), &v);
    OUTPUT:
        RETVAL

IV
year(self, ...)
        SV *self
    ALIAS:
        month = 1
        day = 2
        day_of_week = 3
        day_of_year = 4
        quarter = 5
        day_of_quarter = 6
        week = 7
        week_year = 8
        week_of_month = 9
        is_leap_year = 10
        days_in_month = 11
        days_in_year = 12
        days_in_quarter = 13
        epoch_days = 14
        is_weekend = 15
        is_weekday = 16
        Time::Keeper::YearMonth::year = 20
        Time::Keeper::YearMonth::month = 21
        Time::Keeper::YearMonth::quarter = 25
        Time::Keeper::YearMonth::is_leap_year = 30
        Time::Keeper::YearMonth::days_in_month = 31
        Time::Keeper::YearMonth::days_in_year = 32
        Time::Keeper::YearMonth::days_in_quarter = 33
        Time::Keeper::MonthDay::month = 41
        Time::Keeper::MonthDay::day = 42
    PREINIT:
        int kind = ix < 20 ? TK_KIND_DATE : ix < 40 ? TK_KIND_YEAR_MONTH : TK_KIND_MONTH_DAY;
        int field = ix % 20;
        tk_value *v;
        const tk_civil *c;
        int64_t wy;
        unsigned w;
        int by_locale = 0;
    CODE:
        v = tk_plain_of(aTHX_ self, kind, "accessor");
        if (items > 1) {
            tk_args a;
            if (field != 7 && field != 8)
                croak("%s accessor: this accessor takes no arguments", tk_plain_class[kind]);
            tk_args_parse(aTHX_ &ST(1), items - 1, TK_A(TK_A_LOCALE), &a, field == 7 ? "Time::Keeper::Date->week" : "Time::Keeper::Date->week_year");
            by_locale = a.v[TK_A_LOCALE] && SvTRUE(a.v[TK_A_LOCALE]);
        }
        c = tk_value_civil(v);
        switch (field) {
        case 0:  RETVAL = c->year; break;
        case 1:  RETVAL = c->month; break;
        case 2:  RETVAL = c->day; break;
        case 3:  RETVAL = c->dow; break;
        case 4:  RETVAL = c->doy; break;
        case 5:  RETVAL = tk_quarter(c->month); break;
        case 6:  RETVAL = tk_day_of_quarter(c->year, c->month, c->day); break;
        case 7: case 8:
            if (by_locale) tk_locale_week(tk_locale_of(v), c, &wy, &w);
            else tk_iso_week(c->year, c->month, c->day, &wy, &w);
            RETVAL = field == 7 ? (IV)w : (IV)wy;
            break;
        case 9:  RETVAL = (c->day + 4 - c->dow + 6) / 7; break;
        case 10: RETVAL = tk_is_leap_year(c->year); break;
        case 11: RETVAL = tk_days_in_month(c->year, c->month); break;
        case 12: RETVAL = tk_is_leap_year(c->year) ? 366 : 365; break;
        case 13: {
            unsigned first = (tk_quarter(c->month) - 1) * 3 + 1;
            RETVAL = tk_days_in_month(c->year, first) + tk_days_in_month(c->year, first + 1)
                   + tk_days_in_month(c->year, first + 2);
            break;
        }
        case 14: RETVAL = (IV)tk_days_from_civil(c->year, c->month, c->day); break;
        default: {
            const tk_locale_data *loc = tk_locale_of(v);
            int ws = loc->weekend_start, we = loc->weekend_end, dw = c->dow;
            int weekend = ws <= we ? (dw >= ws && dw <= we) : (dw >= ws || dw <= we);
            RETVAL = field == 15 ? weekend : !weekend;
            break;
        }
        }
    OUTPUT:
        RETVAL

SV *
locale(self)
        SV *self
    ALIAS:
        Time::Keeper::YearMonth::locale = 1
        Time::Keeper::MonthDay::locale = 2
        Time::Keeper::Time::locale = 3
    PREINIT:
        static const int kinds[] = { TK_KIND_DATE, TK_KIND_YEAR_MONTH, TK_KIND_MONTH_DAY, TK_KIND_TIME };
        tk_value *v;
    CODE:
        v = tk_plain_of(aTHX_ self, kinds[ix], "locale");
        RETVAL = newSVpv(tk_locale_codes[v->locale < TK_LOCALE_COUNT ? v->locale : 0].code, 0);
    OUTPUT:
        RETVAL

SV *
month_name(self)
        SV *self
    ALIAS:
        month_abbr = 1
        day_name = 2
        day_abbr = 3
        era_name = 4
        era_abbr = 5
        quarter_name = 6
        quarter_abbr = 7
        Time::Keeper::YearMonth::month_name = 20
        Time::Keeper::YearMonth::month_abbr = 21
        Time::Keeper::YearMonth::era_name = 24
        Time::Keeper::YearMonth::era_abbr = 25
        Time::Keeper::YearMonth::quarter_name = 26
        Time::Keeper::YearMonth::quarter_abbr = 27
        Time::Keeper::MonthDay::month_name = 40
        Time::Keeper::MonthDay::month_abbr = 41
    PREINIT:
        int kind = ix < 20 ? TK_KIND_DATE : ix < 40 ? TK_KIND_YEAR_MONTH : TK_KIND_MONTH_DAY;
        tk_value *v;
        const tk_locale_data *loc;
        const tk_civil *c;
        const char *s;
    CODE:
        v = tk_plain_of(aTHX_ self, kind, "accessor");
        loc = tk_locale_of(v);
        c = tk_value_civil(v);
        switch (ix % 20) {
        case 0:  s = loc->s.months[TK_CTX_FORMAT][TK_W_WIDE][c->month - 1]; break;
        case 1:  s = loc->s.months[TK_CTX_FORMAT][TK_W_ABBR][c->month - 1]; break;
        case 2:  s = loc->s.days[TK_CTX_FORMAT][TK_W_WIDE][c->dow - 1]; break;
        case 3:  s = loc->s.days[TK_CTX_FORMAT][TK_W_ABBR][c->dow - 1]; break;
        case 4:  s = loc->s.eras[TK_W_WIDE][c->year > 0]; break;
        case 5:  s = loc->s.eras[TK_W_ABBR][c->year > 0]; break;
        case 6:  s = loc->s.quarters[TK_CTX_FORMAT][TK_W_WIDE][tk_quarter(c->month) - 1]; break;
        default: s = loc->s.quarters[TK_CTX_FORMAT][TK_W_ABBR][tk_quarter(c->month) - 1]; break;
        }
        RETVAL = newSVpv(s, 0);
        if (!tk_is_ascii(s))
            SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

SV *
with(self, ...)
        SV *self
    ALIAS:
        Time::Keeper::YearMonth::with = 1
        Time::Keeper::MonthDay::with = 2
    PREINIT:
        static const int kinds[] = { TK_KIND_DATE, TK_KIND_YEAR_MONTH, TK_KIND_MONTH_DAY, TK_KIND_TIME };
        static const char *const whats[] = { "Time::Keeper::Date->with", "Time::Keeper::YearMonth->with", "Time::Keeper::MonthDay->with" };
        static const uint64_t allowed[] = {
            TK_A(TK_A_YEAR) | TK_A(TK_A_MONTH) | TK_A(TK_A_DAY) | TK_A(TK_A_DAY_OF_WEEK) | TK_A(TK_A_DAY_OF_YEAR) | TK_A(TK_A_WEEK),
            TK_A(TK_A_YEAR) | TK_A(TK_A_MONTH),
            TK_A(TK_A_MONTH) | TK_A(TK_A_DAY)
        };
        const char *what = whats[ix];
        tk_args a;
        tk_value *v, nv;
        int64_t y;
        unsigned m, d;
    CODE:
        v = tk_plain_of(aTHX_ self, kinds[ix], what);
        tk_args_parse(aTHX_ &ST(1), items - 1, allowed[ix], &a, what);
        tk_args_with_date(aTHX_ &a, tk_value_civil(v), &y, &m, &d, what);
        tk_plain_make(aTHX_ &nv, kinds[ix], y, m, d, v->locale, what);
        RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(self)), &nv);
    OUTPUT:
        RETVAL

SV *
in_locale(self, locale)
        SV *self
        SV *locale
    ALIAS:
        Time::Keeper::YearMonth::in_locale = 1
        Time::Keeper::MonthDay::in_locale = 2
        Time::Keeper::Time::in_locale = 3
    PREINIT:
        static const int kinds[] = { TK_KIND_DATE, TK_KIND_YEAR_MONTH, TK_KIND_MONTH_DAY, TK_KIND_TIME };
        tk_value *v, nv;
    CODE:
        v = tk_plain_of(aTHX_ self, kinds[ix], "in_locale");
        nv = *v;
        nv.locale = tk_locale_id_from_sv(aTHX_ locale, "in_locale");
        RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(self)), &nv);
    OUTPUT:
        RETVAL

SV *
plus(self, ...)
        SV *self
    ALIAS:
        minus = 1
        Time::Keeper::YearMonth::plus = 2
        Time::Keeper::YearMonth::minus = 3
    PREINIT:
        static const char *const whats[] = {
            "Time::Keeper::Date->plus", "Time::Keeper::Date->minus", "Time::Keeper::YearMonth->plus", "Time::Keeper::YearMonth->minus"
        };
        const char *what = whats[ix];
        int kind = ix < 2 ? TK_KIND_DATE : TK_KIND_YEAR_MONTH;
        int sub = ix & 1;
        tk_value *v, out;
        tk_duration d;
    CODE:
        v = tk_plain_of(aTHX_ self, kind, what);
        if (sub && items == 2 && tk_plain_kind_of(aTHX_ ST(1)) == kind) {
            tk_value_difference(aTHX_ &d, v, tk_plain_of(aTHX_ ST(1), kind, what), 1);
            RETVAL = tk_dur_new_sv(aTHX_ tk_dur_stash(aTHX), &d);
        }
        else {
            int eom_given = tk_plain_plus_args(aTHX_ &ST(1), items - 1, kind, &d, what);
            if (sub)
                tk_dur_negate(&d, eom_given);
            tk_plain_add(aTHX_ &out, kind, v, &d, what);
            RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(self)), &out);
        }
    OUTPUT:
        RETVAL

SV *
_add_overload(self, other, swapped)
        SV *self
        SV *other
        SV *swapped
    ALIAS:
        _sub_overload = 1
        Time::Keeper::YearMonth::_add_overload = 2
        Time::Keeper::YearMonth::_sub_overload = 3
    PREINIT:
        int kind = ix < 2 ? TK_KIND_DATE : TK_KIND_YEAR_MONTH;
        int sub = ix & 1;
        const char *what = tk_plain_class[kind];
        tk_value *v, out;
        tk_duration d;
    CODE:
        v = tk_plain_of(aTHX_ self, kind, what);
        if (sub && tk_plain_kind_of(aTHX_ other) == kind) {
            tk_value *o = tk_plain_of(aTHX_ other, kind, what);
            if (SvTRUE(swapped))
                tk_value_difference(aTHX_ &d, o, v, 1);
            else
                tk_value_difference(aTHX_ &d, v, o, 1);
            RETVAL = tk_dur_new_sv(aTHX_ tk_dur_stash(aTHX), &d);
        }
        else {
            if (!tk_is_dur(aTHX_ other))
                croak("%s: a %s takes a Time::Keeper::Duration in + and -, or another %s in -", what, tk_plain_noun[kind], tk_plain_noun[kind]);
            if (sub && SvTRUE(swapped))
                croak("%s: a duration minus a %s means nothing", what, tk_plain_noun[kind]);
            d = *tk_dur_of(aTHX_ other, what);
            if (d.minutes || d.seconds || d.nsec || (kind == TK_KIND_YEAR_MONTH && d.days))
                croak("%s: a %s takes only the units it has", what, tk_plain_noun[kind]);
            if (sub)
                tk_dur_negate(&d, 1);
            tk_plain_add(aTHX_ &out, kind, v, &d, what);
            RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(self)), &out);
        }
    OUTPUT:
        RETVAL

SV *
delta_days(self, other)
        SV *self
        SV *other
    ALIAS:
        delta_md = 1
    PREINIT:
        const char *what = ix ? "Time::Keeper::Date->delta_md" : "Time::Keeper::Date->delta_days";
        tk_value *a, *b, *big, *small;
        tk_duration d;
    CODE:
        b = tk_plain_of(aTHX_ self, TK_KIND_DATE, what);
        a = tk_plain_of(aTHX_ other, TK_KIND_DATE, what);
        if (tk_value_cmp(a, b) <= 0) { small = a; big = b; } else { small = b; big = a; }
        tk_value_difference(aTHX_ &d, big, small, ix ? 1 : 2);
        RETVAL = tk_dur_new_sv(aTHX_ tk_dur_stash(aTHX), &d);
    OUTPUT:
        RETVAL

SV *
truncate(self, ...)
        SV *self
    ALIAS:
        round = 1
        end_of = 2
        Time::Keeper::YearMonth::truncate = 3
        Time::Keeper::YearMonth::round = 4
        Time::Keeper::YearMonth::end_of = 5
    PREINIT:
        static const char *const whats[] = {
            "Time::Keeper::Date->truncate", "Time::Keeper::Date->round", "Time::Keeper::Date->end_of",
            "Time::Keeper::YearMonth->truncate", "Time::Keeper::YearMonth->round", "Time::Keeper::YearMonth->end_of"
        };
        const char *what = whats[ix];
        int kind = ix < 3 ? TK_KIND_DATE : TK_KIND_YEAR_MONTH;
        int op = ix % 3;
        tk_args a;
        tk_value *v, out;
        int unit, mode = TK_RM_HALF_CEIL, ws = 1;
    CODE:
        v = tk_plain_of(aTHX_ self, kind, what);
        tk_args_parse(aTHX_ &ST(1), items - 1,
                      TK_A(TK_A_TO) | (kind == TK_KIND_DATE ? TK_A(TK_A_WEEK_START) : 0) | (op == 1 ? TK_A(TK_A_MODE) : 0), &a, what);
        if (!a.v[TK_A_TO])
            croak("%s: say to => %s", what, kind == TK_KIND_DATE ? "year, quarter, month or week" : "year or quarter");
        unit = tk_opt_unit(aTHX_ a.v[TK_A_TO], what);
        if (unit > TK_U_WEEK || (kind == TK_KIND_YEAR_MONTH && unit > TK_U_QUARTER))
            croak("%s: a %s is truncated to %s, not to %s", what, tk_plain_noun[kind],
                  kind == TK_KIND_DATE ? "a year, quarter, month or week" : "a year or quarter", tk_unit_names[unit]);
        if (a.v[TK_A_WEEK_START]) {
            SV *w = a.v[TK_A_WEEK_START];
            if (SvPOK(w) && strEQ(SvPV_nolen(w), "locale"))
                ws = tk_locale_of(v)->first_day;
            else
                ws = (int)tk_opt_int(aTHX_ w, what, "week_start", 1, 7);
        }
        if (a.v[TK_A_MODE])
            mode = tk_opt_mode(aTHX_ a.v[TK_A_MODE], what);
        switch (op) {
        case 0:  tk_value_truncate_ws(aTHX_ &out, v, unit, ws, what); break;
        case 1:  tk_value_round(aTHX_ &out, v, unit, 1, mode, ws, what); break;
        default: tk_value_end_of(aTHX_ &out, v, unit, ws, what); break;
        }
        tk_plain_project(aTHX_ &out, kind, &out, what);
        RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(self)), &out);
    OUTPUT:
        RETVAL

SV *
next(self, ...)
        SV *self
    ALIAS:
        previous = 1
    PREINIT:
        const char *what = ix ? "Time::Keeper::Date->previous" : "Time::Keeper::Date->next";
        tk_args a;
        tk_value *v, out;
        int64_t dow;
    CODE:
        v = tk_plain_of(aTHX_ self, TK_KIND_DATE, what);
        tk_args_parse(aTHX_ &ST(1), items - 1, TK_A(TK_A_DAY_OF_WEEK) | TK_A(TK_A_OR_SAME), &a, what);
        if (!a.v[TK_A_DAY_OF_WEEK])
            croak("%s: day_of_week is required", what);
        dow = tk_args_int(aTHX_ &a, TK_A_DAY_OF_WEEK, 1, 1, 7, what);
        tk_value_adjust_dow(aTHX_ &out, v, (int)dow, ix ? -1 : 1, a.v[TK_A_OR_SAME] ? SvTRUE(a.v[TK_A_OR_SAME]) : 0,
                            TK_GAP_DEFAULT, TK_OVERLAP_DEFAULT, what);
        tk_plain_project(aTHX_ &out, TK_KIND_DATE, &out, what);
        RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(self)), &out);
    OUTPUT:
        RETVAL

SV *
nth_in_month(self, ...)
        SV *self
    ALIAS:
        last_in_month = 1
    PREINIT:
        const char *what = ix ? "Time::Keeper::Date->last_in_month" : "Time::Keeper::Date->nth_in_month";
        tk_args a;
        tk_value *v, out;
        int64_t dow, n = -1;
    CODE:
        v = tk_plain_of(aTHX_ self, TK_KIND_DATE, what);
        tk_args_parse(aTHX_ &ST(1), items - 1, TK_A(TK_A_DAY_OF_WEEK) | (ix ? 0 : TK_A(TK_A_N)), &a, what);
        if (!a.v[TK_A_DAY_OF_WEEK])
            croak("%s: day_of_week is required", what);
        dow = tk_args_int(aTHX_ &a, TK_A_DAY_OF_WEEK, 1, 1, 7, what);
        if (!ix) {
            if (!a.v[TK_A_N])
                croak("%s: n is required: 1 to 5, or -1 for the last", what);
            n = tk_args_int(aTHX_ &a, TK_A_N, 1, -1, 5, what);
            if (n == 0)
                croak("%s: n is 1 to 5, or -1 for the last, not 0", what);
        }
        tk_value_nth_in_month(aTHX_ &out, v, (int)dow, (int)n, TK_GAP_DEFAULT, TK_OVERLAP_DEFAULT, what);
        tk_plain_project(aTHX_ &out, TK_KIND_DATE, &out, what);
        RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(self)), &out);
    OUTPUT:
        RETVAL

IV
_compare(a, b, swapped)
        SV *a
        SV *b
        SV *swapped
    ALIAS:
        Time::Keeper::YearMonth::_compare = 1
        Time::Keeper::MonthDay::_compare = 2
        Time::Keeper::Time::_compare = 3
    PREINIT:
        static const int kinds[] = { TK_KIND_DATE, TK_KIND_YEAR_MONTH, TK_KIND_MONTH_DAY, TK_KIND_TIME };
        const tk_value *x, *y;
    CODE:
        if (tk_plain_kind_of(aTHX_ b) != kinds[ix])
            croak("%s: a %s compares only with another %s", tk_plain_class[kinds[ix]], tk_plain_noun[kinds[ix]], tk_plain_noun[kinds[ix]]);
        x = tk_plain_of(aTHX_ a, kinds[ix], "comparison");
        y = tk_plain_of(aTHX_ b, kinds[ix], "comparison");
        RETVAL = tk_value_cmp(x, y);
        if (SvTRUE(swapped))
            RETVAL = -RETVAL;
    OUTPUT:
        RETVAL

IV
compare(class, a, b)
        SV *class
        SV *a
        SV *b
    ALIAS:
        Time::Keeper::YearMonth::compare = 1
        Time::Keeper::MonthDay::compare = 2
        Time::Keeper::Time::compare = 3
    PREINIT:
        static const int kinds[] = { TK_KIND_DATE, TK_KIND_YEAR_MONTH, TK_KIND_MONTH_DAY, TK_KIND_TIME };
        const tk_value *x, *y;
    CODE:
        PERL_UNUSED_VAR(class);
        x = tk_plain_of(aTHX_ a, kinds[ix], "compare");
        y = tk_plain_of(aTHX_ b, kinds[ix], "compare");
        RETVAL = tk_value_cmp(x, y);
    OUTPUT:
        RETVAL

SV *
iso8601(self, ...)
        SV *self
    ALIAS:
        TO_JSON = 1
        Time::Keeper::YearMonth::iso8601 = 2
        Time::Keeper::YearMonth::TO_JSON = 3
        Time::Keeper::MonthDay::iso8601 = 4
        Time::Keeper::MonthDay::TO_JSON = 5
        Time::Keeper::Time::TO_JSON = 6
    PREINIT:
        static const int kinds[] = { TK_KIND_DATE, TK_KIND_YEAR_MONTH, TK_KIND_MONTH_DAY, TK_KIND_TIME };
    CODE:
        RETVAL = tk_plain_iso8601_sv(aTHX_ tk_plain_of(aTHX_ self, kinds[ix / 2], "iso8601"));
    OUTPUT:
        RETVAL

SV *
ymd(self, ...)
        SV *self
    ALIAS:
        mdy = 1
        dmy = 2
        date = 3
    PREINIT:
        tk_value *v;
        const tk_civil *c;
        const char *sep;
        STRLEN sl;
        char y[24];
        SV *out;
    CODE:
        v = tk_plain_of(aTHX_ self, TK_KIND_DATE, "accessor");
        c = tk_value_civil(v);
        if (items > 1 && ix != 3)
            sep = SvPV(ST(1), sl);
        else {
            sep = "-";
            sl = 1;
        }
        if (c->year < 0)
            sprintf(y, "-%04ld", (long)-(long)c->year);
        else
            sprintf(y, "%04ld", (long)c->year);
        switch (ix) {
        case 1:  out = newSVpvf("%02u%.*s%02u%.*s%s", (unsigned)c->month, (int)sl, sep, (unsigned)c->day, (int)sl, sep, y); break;
        case 2:  out = newSVpvf("%02u%.*s%02u%.*s%s", (unsigned)c->day, (int)sl, sep, (unsigned)c->month, (int)sl, sep, y); break;
        default: out = newSVpvf("%s%.*s%02u%.*s%02u", y, (int)sl, sep, (unsigned)c->month, (int)sl, sep, (unsigned)c->day); break;
        }
        if (items > 1 && SvUTF8(ST(1)))
            SvUTF8_on(out);
        RETVAL = out;
    OUTPUT:
        RETVAL

void
strftime(self, ...)
        SV *self
    ALIAS:
        format = 1
        Time::Keeper::YearMonth::strftime = 2
        Time::Keeper::YearMonth::format = 3
        Time::Keeper::MonthDay::strftime = 4
        Time::Keeper::MonthDay::format = 5
        Time::Keeper::Time::strftime = 6
        Time::Keeper::Time::format = 7
    PREINIT:
        static const int kinds[] = { TK_KIND_DATE, TK_KIND_YEAR_MONTH, TK_KIND_MONTH_DAY, TK_KIND_TIME };
        static const char *const whats[] = {
            "Time::Keeper::Date->strftime", "Time::Keeper::Date->format",
            "Time::Keeper::YearMonth->strftime", "Time::Keeper::YearMonth->format",
            "Time::Keeper::MonthDay->strftime", "Time::Keeper::MonthDay->format",
            "Time::Keeper::Time->strftime", "Time::Keeper::Time->format"
        };
        const char *what = whats[ix];
        tk_value *v;
        I32 i;
    PPCODE:
        v = tk_plain_of(aTHX_ self, kinds[ix / 2], what);
        if (items < 2)
            croak("%s: which pattern?", what);
        for (i = 1; i < items; i++) {
            SV *pat = tk_utf8_text(aTHX_ ST(i)), *out;
            STRLEN len;
            const char *p = SvPV(pat, len);
            out = sv_2mortal(tk_plain_format_sv(aTHX_ self, v, ix & 1, 1, p, len, what));
            if (GIMME_V != G_ARRAY) {
                ST(0) = out;
                XSRETURN(1);
            }
            XPUSHs(out);
        }

SV *
format_date(self, ...)
        SV *self
    ALIAS:
        Time::Keeper::YearMonth::format_date = 1
        Time::Keeper::MonthDay::format_date = 2
    PREINIT:
        static const int kinds[] = { TK_KIND_DATE, TK_KIND_YEAR_MONTH, TK_KIND_MONTH_DAY, TK_KIND_TIME };
        static const char *const whats[] = { "Time::Keeper::Date->format_date", "Time::Keeper::YearMonth->format_date", "Time::Keeper::MonthDay->format_date" };
        static const char *const ym_skel[] = { "yMMMM", "yMMMM", "yMMM", "yM" };
        static const char *const md_skel[] = { "MMMMd", "MMMMd", "MMMd", "Md" };
        const char *what = whats[ix];
        tk_value *v;
        const tk_locale_data *loc;
        const char *p;
        int len = TK_LEN_MEDIUM;
    CODE:
        v = tk_plain_of(aTHX_ self, kinds[ix], what);
        loc = tk_locale_of(v);
        if (items > 1) {
            const char *l = SvPV_nolen(ST(1));
            if (strEQ(l, "full")) len = TK_LEN_FULL;
            else if (strEQ(l, "long")) len = TK_LEN_LONG;
            else if (strEQ(l, "medium")) len = TK_LEN_MEDIUM;
            else if (strEQ(l, "short")) len = TK_LEN_SHORT;
            else croak("%s: the length is 'full', 'long', 'medium' or 'short', not '%s'", what, l);
        }
        if (ix == 0)
            p = loc->s.date_formats[len];
        else {
            const char *skel = (ix == 1 ? ym_skel : md_skel)[len];
            p = tk_skeleton_pattern(loc, skel);
            if (!p)
                croak("%s: the locale %s has no format for the skeleton '%s'", what, loc->id, skel);
        }
        RETVAL = tk_plain_format_sv(aTHX_ self, v, 1, 0, p, strlen(p), what);
    OUTPUT:
        RETVAL

SV *
format_skeleton(self, skeleton)
        SV *self
        const char *skeleton
    ALIAS:
        Time::Keeper::YearMonth::format_skeleton = 1
        Time::Keeper::MonthDay::format_skeleton = 2
        Time::Keeper::Time::format_skeleton = 3
    PREINIT:
        static const int kinds[] = { TK_KIND_DATE, TK_KIND_YEAR_MONTH, TK_KIND_MONTH_DAY, TK_KIND_TIME };
        static const char *const whats[] = { "Time::Keeper::Date->format_skeleton", "Time::Keeper::YearMonth->format_skeleton", "Time::Keeper::MonthDay->format_skeleton", "Time::Keeper::Time->format_skeleton" };
        const char *what = whats[ix];
        tk_value *v;
        const tk_locale_data *loc;
        const char *p;
    CODE:
        v = tk_plain_of(aTHX_ self, kinds[ix], what);
        loc = tk_locale_of(v);
        p = tk_skeleton_pattern(loc, skeleton);
        if (!p)
            croak("%s: the locale %s has no format for the skeleton '%s'", what, loc->id, skeleton);
        RETVAL = tk_plain_format_sv(aTHX_ self, v, 1, 1, p, strlen(p), what);
    OUTPUT:
        RETVAL

SV *
parse(class, text, ...)
        SV *class
        SV *text
    ALIAS:
        strptime = 1
        parse_cldr = 2
        Time::Keeper::YearMonth::parse = 3
        Time::Keeper::YearMonth::strptime = 4
        Time::Keeper::YearMonth::parse_cldr = 5
        Time::Keeper::MonthDay::parse = 6
        Time::Keeper::MonthDay::strptime = 7
        Time::Keeper::MonthDay::parse_cldr = 8
        Time::Keeper::Time::parse = 9
        Time::Keeper::Time::strptime = 10
        Time::Keeper::Time::parse_cldr = 11
    PREINIT:
        static const int kinds[] = { TK_KIND_DATE, TK_KIND_YEAR_MONTH, TK_KIND_MONTH_DAY, TK_KIND_TIME };
        static const char *const whats[] = {
            "Time::Keeper::Date->parse", "Time::Keeper::Date->strptime", "Time::Keeper::Date->parse_cldr",
            "Time::Keeper::YearMonth->parse", "Time::Keeper::YearMonth->strptime", "Time::Keeper::YearMonth->parse_cldr",
            "Time::Keeper::MonthDay->parse", "Time::Keeper::MonthDay->strptime", "Time::Keeper::MonthDay->parse_cldr",
            "Time::Keeper::Time->parse", "Time::Keeper::Time->strptime", "Time::Keeper::Time->parse_cldr"
        };
        const char *what = whats[ix];
        int kind = kinds[ix / 3], mode = ix % 3, first = mode ? 3 : 2;
        tk_args a;
        tk_value v;
    CODE:
        if (mode && items < 3)
            croak("%s: a pattern was wanted after the text", what);
        tk_args_parse(aTHX_ &ST(first), items - first, TK_A(TK_A_LOCALE), &a, what);
        tk_plain_parse(aTHX_ &v, kind, mode, text, mode ? ST(2) : NULL, tk_args_locale(&a, what), what);
        RETVAL = tk_value_new_sv(aTHX_ tk_plain_stash_for(aTHX_ class, kind), &v);
    OUTPUT:
        RETVAL

SV *
try_new(class, ...)
        SV *class
    ALIAS:
        try_parse = 1
        try_strptime = 2
        try_parse_cldr = 3
        Time::Keeper::YearMonth::try_new = 4
        Time::Keeper::YearMonth::try_parse = 5
        Time::Keeper::YearMonth::try_strptime = 6
        Time::Keeper::YearMonth::try_parse_cldr = 7
        Time::Keeper::MonthDay::try_new = 8
        Time::Keeper::MonthDay::try_parse = 9
        Time::Keeper::MonthDay::try_strptime = 10
        Time::Keeper::MonthDay::try_parse_cldr = 11
        Time::Keeper::Time::try_new = 12
        Time::Keeper::Time::try_parse = 13
        Time::Keeper::Time::try_strptime = 14
        Time::Keeper::Time::try_parse_cldr = 15
    PREINIT:
        static const char *const methods[] = { "new", "parse", "strptime", "parse_cldr" };
        int count;
        I32 i;
    CODE:
        PERL_UNUSED_VAR(class);
        {
            dSP;
            ENTER;
            SAVETMPS;
            save_scalar(PL_errgv);
            PUSHMARK(SP);
            for (i = 0; i < items; i++)
                XPUSHs(ST(i));
            PUTBACK;
            count = call_method(methods[ix % 4], G_SCALAR | G_EVAL);
            SPAGAIN;
            if (count == 1 && !SvTRUE(ERRSV))
                RETVAL = newSVsv(POPs);
            else {
                if (count) (void)POPs;
                RETVAL = &PL_sv_undef;
            }
            PUTBACK;
            FREETMPS;
            LEAVE;
        }
    OUTPUT:
        RETVAL

void
STORABLE_freeze(self, cloning)
        SV *self
        SV *cloning
    ALIAS:
        FREEZE = 1
        Time::Keeper::YearMonth::STORABLE_freeze = 2
        Time::Keeper::YearMonth::FREEZE = 3
        Time::Keeper::MonthDay::STORABLE_freeze = 4
        Time::Keeper::MonthDay::FREEZE = 5
        Time::Keeper::Time::STORABLE_freeze = 6
        Time::Keeper::Time::FREEZE = 7
    PREINIT:
        static const int kinds[] = { TK_KIND_DATE, TK_KIND_YEAR_MONTH, TK_KIND_MONTH_DAY, TK_KIND_TIME };
    PPCODE:
        PERL_UNUSED_VAR(cloning);
        XPUSHs(sv_2mortal(tk_plain_freeze_sv(aTHX_ tk_plain_of(aTHX_ self, kinds[ix / 2], "freeze"))));

void
STORABLE_thaw(self, cloning, frozen)
        SV *self
        SV *cloning
        SV *frozen
    ALIAS:
        Time::Keeper::YearMonth::STORABLE_thaw = 1
        Time::Keeper::MonthDay::STORABLE_thaw = 2
        Time::Keeper::Time::STORABLE_thaw = 3
    PREINIT:
        static const int kinds[] = { TK_KIND_DATE, TK_KIND_YEAR_MONTH, TK_KIND_MONTH_DAY, TK_KIND_TIME };
        tk_value v;
    PPCODE:
        PERL_UNUSED_VAR(cloning);
        tk_plain_thaw(aTHX_ frozen, kinds[ix], &v, "STORABLE_thaw");
        if (!SvROK(self))
            croak("STORABLE_thaw: not a reference");
        sv_setpvn(SvRV(self), (const char *)&v, sizeof v);
        XSRETURN_EMPTY;

SV *
THAW(class, serialiser, frozen)
        SV *class
        SV *serialiser
        SV *frozen
    ALIAS:
        Time::Keeper::YearMonth::THAW = 1
        Time::Keeper::MonthDay::THAW = 2
        Time::Keeper::Time::THAW = 3
    PREINIT:
        static const int kinds[] = { TK_KIND_DATE, TK_KIND_YEAR_MONTH, TK_KIND_MONTH_DAY, TK_KIND_TIME };
        tk_value v;
    CODE:
        PERL_UNUSED_VAR(serialiser);
        tk_plain_thaw(aTHX_ frozen, kinds[ix], &v, "THAW");
        RETVAL = tk_value_new_sv(aTHX_ tk_plain_stash_for(aTHX_ class, kinds[ix]), &v);
    OUTPUT:
        RETVAL

SV *
at(self, ...)
        SV *self
    PREINIT:
        const char *what = "Time::Keeper::Date->at";
        tk_args a;
        tk_value *v, out;
        const tk_civil *c;
        tk_zone_spec z;
        int gap, overlap;
        int64_t h, mi, s;
        int32_t ns;
        dMY_CXT;
    CODE:
        v = tk_plain_of(aTHX_ self, TK_KIND_DATE, what);
        c = tk_value_civil(v);
        if (items > 1 && tk_plain_kind_of(aTHX_ ST(1)) == TK_KIND_TIME) {
            const tk_civil *tc = tk_value_civil(tk_plain_of(aTHX_ ST(1), TK_KIND_TIME, what));
            tk_args_parse(aTHX_ &ST(2), items - 2, TK_A_RESOLVE, &a, what);
            h = tc->hour;
            mi = tc->minute;
            s = tc->second;
            ns = tc->nsec;
            tk_args_resolve(aTHX_ &a, &z, &gap, &overlap, what);
        }
        else {
            tk_args_parse(aTHX_ &ST(1), items - 1, TK_A_TIME | TK_A_RESOLVE, &a, what);
            tk_args_time(aTHX_ &a, &h, &mi, &s, &ns, what);
            tk_args_resolve(aTHX_ &a, &z, &gap, &overlap, what);
            if (!(a.v[TK_A_HOUR] || a.v[TK_A_MINUTE] || a.v[TK_A_SECOND] || a.v[TK_A_NANOSECOND]) && !a.v[TK_A_GAP])
                gap = TKZ_GAP_FORWARD;
        }
        tk_value_from_local(aTHX_ &out, &z, c->year, c->month, c->day, h, mi, s, ns, gap, overlap, what);
        out.locale = v->locale;
        RETVAL = tk_value_new_sv(aTHX_ MY_CXT.stash, &out);
    OUTPUT:
        RETVAL

SV *
to_year_month(self)
        SV *self
    ALIAS:
        to_month_day = 1
    PREINIT:
        const char *what = ix ? "Time::Keeper::Date->to_month_day" : "Time::Keeper::Date->to_year_month";
        int kind = ix ? TK_KIND_MONTH_DAY : TK_KIND_YEAR_MONTH;
        tk_value *v, out;
    CODE:
        v = tk_plain_of(aTHX_ self, TK_KIND_DATE, what);
        tk_plain_project(aTHX_ &out, kind, v, what);
        RETVAL = tk_value_new_sv(aTHX_ tk_plain_stash(aTHX_ kind), &out);
    OUTPUT:
        RETVAL

void
utc_rd_values(self)
        SV *self
    PREINIT:
        tk_value *v;
        const tk_civil *c;
    PPCODE:
        v = tk_plain_of(aTHX_ self, TK_KIND_DATE, "Time::Keeper::Date->utc_rd_values");
        c = tk_value_civil(v);
        EXTEND(SP, 3);
        mPUSHs(tk_newSVi64(aTHX_ tk_days_from_civil(c->year, c->month, c->day) + 719163));
        mPUSHi(0);
        mPUSHi(0);

MODULE = Time::Keeper    PACKAGE = Time::Keeper::YearMonth

SV *
on(self, day)
        SV *self
        SV *day
    PREINIT:
        const char *what = "Time::Keeper::YearMonth->on";
        tk_value *v, out;
        const tk_civil *c;
        int64_t d;
    CODE:
        v = tk_plain_of(aTHX_ self, TK_KIND_YEAR_MONTH, what);
        c = tk_value_civil(v);
        if (SvPOK(day) && strEQ(SvPV_nolen(day), "last"))
            d = tk_days_in_month(c->year, c->month);
        else
            d = tk_opt_int(aTHX_ day, what, "day", 1, 31);
        tk_plain_make(aTHX_ &out, TK_KIND_DATE, c->year, c->month, (unsigned)d, v->locale, what);
        RETVAL = tk_value_new_sv(aTHX_ tk_plain_stash(aTHX_ TK_KIND_DATE), &out);
    OUTPUT:
        RETVAL

SV *
last_day(self)
        SV *self
    PREINIT:
        const char *what = "Time::Keeper::YearMonth->last_day";
        tk_value *v, out;
        const tk_civil *c;
    CODE:
        v = tk_plain_of(aTHX_ self, TK_KIND_YEAR_MONTH, what);
        c = tk_value_civil(v);
        tk_plain_make(aTHX_ &out, TK_KIND_DATE, c->year, c->month, tk_days_in_month(c->year, c->month), v->locale, what);
        RETVAL = tk_value_new_sv(aTHX_ tk_plain_stash(aTHX_ TK_KIND_DATE), &out);
    OUTPUT:
        RETVAL

MODULE = Time::Keeper    PACKAGE = Time::Keeper::MonthDay

SV *
in_year(self, year, ...)
        SV *self
        SV *year
    PREINIT:
        const char *what = "Time::Keeper::MonthDay->in_year";
        tk_args a;
        tk_value *v, out;
        const tk_civil *c;
        int64_t y;
        unsigned d;
    CODE:
        v = tk_plain_of(aTHX_ self, TK_KIND_MONTH_DAY, what);
        c = tk_value_civil(v);
        tk_args_parse(aTHX_ &ST(2), items - 2, TK_A(TK_A_END_OF_MONTH), &a, what);
        y = tk_opt_int(aTHX_ year, what, "year", TK_YEAR_MIN, TK_YEAR_MAX);
        d = c->day;
        if (d > tk_days_in_month(y, c->month)) {
            int eom = a.v[TK_A_END_OF_MONTH] ? tk_opt_eom(aTHX_ a.v[TK_A_END_OF_MONTH], what) : -1;
            if (eom == TK_EOM_LIMIT || eom == TK_EOM_PRESERVE)
                d = tk_days_in_month(y, c->month);
            else if (eom == TK_EOM_WRAP) {
                int64_t yy;
                unsigned mm;
                tk_civil_from_days(tk_days_from_civil(y, c->month, 1) + d - 1, &yy, &mm, &d);
                tk_plain_make(aTHX_ &out, TK_KIND_DATE, yy, mm, d, v->locale, what);
                RETVAL = tk_value_new_sv(aTHX_ tk_plain_stash(aTHX_ TK_KIND_DATE), &out);
                goto done;
            }
            else
                croak("%s: %" IVdf " has no --%02u-%02u (end_of_month => 'limit' gives the last day of the month)", what, (IV)y, (unsigned)c->month, d);
        }
        tk_plain_make(aTHX_ &out, TK_KIND_DATE, y, c->month, d, v->locale, what);
        RETVAL = tk_value_new_sv(aTHX_ tk_plain_stash(aTHX_ TK_KIND_DATE), &out);
      done:
        ;
    OUTPUT:
        RETVAL

MODULE = Time::Keeper    PACKAGE = Time::Keeper

SV *
to_date(self)
        SV *self
    ALIAS:
        to_year_month = 1
        to_month_day = 2
        to_time = 3
    PREINIT:
        static const int kinds[] = { TK_KIND_DATE, TK_KIND_YEAR_MONTH, TK_KIND_MONTH_DAY, TK_KIND_TIME };
        static const char *const whats[] = { "Time::Keeper->to_date", "Time::Keeper->to_year_month", "Time::Keeper->to_month_day", "Time::Keeper->to_time" };
        tk_value *v, out;
    CODE:
        v = tk_value_rw(self, whats[ix]);
        tk_value_gregorian_only(aTHX_ v, whats[ix]);
        tk_plain_project(aTHX_ &out, kinds[ix], v, whats[ix]);
        RETVAL = tk_value_new_sv(aTHX_ tk_plain_stash(aTHX_ kinds[ix]), &out);
    OUTPUT:
        RETVAL

MODULE = Time::Keeper    PACKAGE = Time::Keeper::Time

SV *
new(class, ...)
        SV *class
    PREINIT:
        const char *what = "Time::Keeper::Time->new";
        tk_args a;
        int64_t h, mi, s;
        int32_t ns;
        tk_value v;
    CODE:
        tk_args_parse(aTHX_ &ST(1), items - 1, TK_A_TIME | TK_A(TK_A_LOCALE), &a, what);
        tk_args_time(aTHX_ &a, &h, &mi, &s, &ns, what);
        tk_time_make(aTHX_ &v, h, mi, s, ns, tk_args_locale(&a, what), what);
        RETVAL = tk_value_new_sv(aTHX_ tk_plain_stash_for(aTHX_ class, TK_KIND_TIME), &v);
    OUTPUT:
        RETVAL

SV *
now(class, ...)
        SV *class
    PREINIT:
        const char *what = "Time::Keeper::Time->now";
        tk_args a;
        tk_zone_spec z;
        tk_instant t;
        tk_value v, out;
    CODE:
        tk_args_parse(aTHX_ &ST(1), items - 1, TK_A(TK_A_ZONE) | TK_A(TK_A_LOCALE), &a, what);
        tk_zone_spec_from_sv(aTHX_ a.v[TK_A_ZONE], &z, what);
        tk_now_sv(aTHX_ &t);
        tk_value_init(aTHX_ &v, &t, &z);
        v.locale = tk_args_locale(&a, what);
        tk_time_project(aTHX_ &out, &v, what);
        RETVAL = tk_value_new_sv(aTHX_ tk_plain_stash_for(aTHX_ class, TK_KIND_TIME), &out);
    OUTPUT:
        RETVAL

IV
hour(self)
        SV *self
    ALIAS:
        minute = 1
        second = 2
        nanosecond = 3
        millisecond = 4
        microsecond = 5
        hour_12 = 6
    PREINIT:
        tk_value *v;
        const tk_civil *c;
    CODE:
        v = tk_plain_of(aTHX_ self, TK_KIND_TIME, "accessor");
        c = tk_value_civil(v);
        switch (ix) {
        case 0:  RETVAL = c->hour; break;
        case 1:  RETVAL = c->minute; break;
        case 2:  RETVAL = c->second; break;
        case 3:  RETVAL = c->nsec; break;
        case 4:  RETVAL = c->nsec / 1000000; break;
        case 5:  RETVAL = c->nsec / 1000; break;
        default: RETVAL = c->hour % 12 ? c->hour % 12 : 12; break;
        }
    OUTPUT:
        RETVAL

SV *
am_pm(self)
        SV *self
    PREINIT:
        tk_value *v;
        const char *s;
    CODE:
        v = tk_plain_of(aTHX_ self, TK_KIND_TIME, "accessor");
        s = tk_locale_of(v)->s.periods[TK_W_ABBR][tk_value_civil(v)->hour >= 12];
        RETVAL = newSVpv(s, 0);
        if (!tk_is_ascii(s))
            SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

SV *
with(self, ...)
        SV *self
    PREINIT:
        const char *what = "Time::Keeper::Time->with";
        tk_args a;
        tk_value *v, nv;
        const tk_civil *c;
        int64_t h, mi, s;
        int32_t ns;
    CODE:
        v = tk_plain_of(aTHX_ self, TK_KIND_TIME, what);
        tk_args_parse(aTHX_ &ST(1), items - 1, TK_A_TIME, &a, what);
        c = tk_value_civil(v);
        h  = tk_args_int(aTHX_ &a, TK_A_HOUR, c->hour, 0, 23, what);
        mi = tk_args_int(aTHX_ &a, TK_A_MINUTE, c->minute, 0, 59, what);
        s  = tk_args_int(aTHX_ &a, TK_A_SECOND, c->second, 0, 59, what);
        ns = (int32_t)tk_args_int(aTHX_ &a, TK_A_NANOSECOND, c->nsec, 0, TK_NSECS_PER_SEC - 1, what);
        tk_time_make(aTHX_ &nv, h, mi, s, ns, v->locale, what);
        RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(self)), &nv);
    OUTPUT:
        RETVAL

SV *
plus(self, ...)
        SV *self
    ALIAS:
        minus = 1
    PREINIT:
        const char *what = ix ? "Time::Keeper::Time->minus" : "Time::Keeper::Time->plus";
        tk_value *v, out;
        tk_duration d;
    CODE:
        v = tk_plain_of(aTHX_ self, TK_KIND_TIME, what);
        if (ix && items == 2 && tk_plain_kind_of(aTHX_ ST(1)) == TK_KIND_TIME) {
            tk_value_difference(aTHX_ &d, v, tk_plain_of(aTHX_ ST(1), TK_KIND_TIME, what), 0);
            RETVAL = tk_dur_new_sv(aTHX_ tk_dur_stash(aTHX), &d);
        }
        else {
            tk_plain_plus_args(aTHX_ &ST(1), items - 1, TK_KIND_TIME, &d, what);
            if (ix)
                tk_dur_negate(&d, 1);
            tk_plain_add(aTHX_ &out, TK_KIND_TIME, v, &d, what);
            RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(self)), &out);
        }
    OUTPUT:
        RETVAL

SV *
_add_overload(self, other, swapped)
        SV *self
        SV *other
        SV *swapped
    ALIAS:
        _sub_overload = 1
    PREINIT:
        const char *what = "Time::Keeper::Time";
        tk_value *v, out;
        tk_duration d;
    CODE:
        v = tk_plain_of(aTHX_ self, TK_KIND_TIME, what);
        if (ix && tk_plain_kind_of(aTHX_ other) == TK_KIND_TIME) {
            tk_value *o = tk_plain_of(aTHX_ other, TK_KIND_TIME, what);
            if (SvTRUE(swapped))
                tk_value_difference(aTHX_ &d, o, v, 0);
            else
                tk_value_difference(aTHX_ &d, v, o, 0);
            RETVAL = tk_dur_new_sv(aTHX_ tk_dur_stash(aTHX), &d);
        }
        else {
            if (!tk_is_dur(aTHX_ other))
                croak("%s: a time of day takes a Time::Keeper::Duration in + and -, or another time of day in -", what);
            if (ix && SvTRUE(swapped))
                croak("%s: a duration minus a time of day means nothing", what);
            d = *tk_dur_of(aTHX_ other, what);
            if (ix)
                tk_dur_negate(&d, 1);
            tk_plain_add(aTHX_ &out, TK_KIND_TIME, v, &d, what);
            RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(self)), &out);
        }
    OUTPUT:
        RETVAL

SV *
truncate(self, ...)
        SV *self
    ALIAS:
        round = 1
        end_of = 2
    PREINIT:
        static const char *const whats[] = { "Time::Keeper::Time->truncate", "Time::Keeper::Time->round", "Time::Keeper::Time->end_of" };
        const char *what = whats[ix];
        tk_args a;
        tk_value *v, out;
        int unit, mode = TK_RM_HALF_CEIL;
        int64_t inc = 1;
    CODE:
        v = tk_plain_of(aTHX_ self, TK_KIND_TIME, what);
        tk_args_parse(aTHX_ &ST(1), items - 1, TK_A(TK_A_TO) | (ix == 1 ? TK_A(TK_A_INCREMENT) | TK_A(TK_A_MODE) : 0), &a, what);
        if (!a.v[TK_A_TO])
            croak("%s: say to => hour, minute, second, millisecond, microsecond or nanosecond", what);
        unit = tk_opt_unit(aTHX_ a.v[TK_A_TO], what);
        if (unit < TK_U_HOUR)
            croak("%s: a time of day is truncated to an hour or less, not to %s", what, tk_unit_names[unit]);
        if (a.v[TK_A_INCREMENT])
            inc = tk_opt_increment(aTHX_ a.v[TK_A_INCREMENT], unit, what);
        if (a.v[TK_A_MODE])
            mode = tk_opt_mode(aTHX_ a.v[TK_A_MODE], what);
        switch (ix) {
        case 0:  tk_value_truncate_ws(aTHX_ &out, v, unit, 1, what); break;
        case 1:  tk_value_round(aTHX_ &out, v, unit, inc, mode, 1, what); break;
        default: tk_value_end_of(aTHX_ &out, v, unit, 1, what); break;
        }
        tk_plain_project(aTHX_ &out, TK_KIND_TIME, &out, what);
        RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(self)), &out);
    OUTPUT:
        RETVAL

SV *
iso8601(self, ...)
        SV *self
    ALIAS:
        hms = 1
        time = 2
    PREINIT:
        const char *what = "Time::Keeper::Time->iso8601";
        tk_value *v;
        int digits = -1;
        I32 i;
    CODE:
        v = tk_plain_of(aTHX_ self, TK_KIND_TIME, what);
        if (ix) {
            const tk_civil *c = tk_value_civil(v);
            const char *sep = ":";
            STRLEN sl = 1;
            if (items > 1 && ix == 1)
                sep = SvPV(ST(1), sl);
            RETVAL = newSVpvf("%02u%.*s%02u%.*s%02u", (unsigned)c->hour, (int)sl, sep, (unsigned)c->minute, (int)sl, sep, (unsigned)c->second);
            if (items > 1 && ix == 1 && SvUTF8(ST(1)))
                SvUTF8_on(RETVAL);
        }
        else {
            if ((items - 1) % 2)
                croak("%s: the option is precision => 0 to 9", what);
            for (i = 1; i + 1 < items; i += 2) {
                if (!SvOK(ST(i)))
                    continue;
                if (strEQ(SvPV_nolen(ST(i)), "precision"))
                    digits = (int)tk_opt_int(aTHX_ ST(i + 1), what, "precision", 0, 9);
                else
                    croak("%s: the option is precision => 0 to 9, not '%s'", what, SvPV_nolen(ST(i)));
            }
            RETVAL = tk_time_iso8601_sv(aTHX_ v, digits);
        }
    OUTPUT:
        RETVAL

SV *
format_time(self, ...)
        SV *self
    PREINIT:
        const char *what = "Time::Keeper::Time->format_time";
        tk_value *v;
        const tk_locale_data *loc;
        const char *p;
        int len = TK_LEN_MEDIUM;
    CODE:
        v = tk_plain_of(aTHX_ self, TK_KIND_TIME, what);
        loc = tk_locale_of(v);
        if (items > 1) {
            const char *l = SvPV_nolen(ST(1));
            if (strEQ(l, "full")) len = TK_LEN_FULL;
            else if (strEQ(l, "long")) len = TK_LEN_LONG;
            else if (strEQ(l, "medium")) len = TK_LEN_MEDIUM;
            else if (strEQ(l, "short")) len = TK_LEN_SHORT;
            else croak("%s: the length is 'full', 'long', 'medium' or 'short', not '%s'", what, l);
        }
        p = loc->s.time_formats[len];
        RETVAL = tk_plain_format_sv(aTHX_ self, v, 1, 1, p, strlen(p), what);
    OUTPUT:
        RETVAL
