# Formatting: strftime, CLDR patterns, names, and the fixed forms.

MODULE = Time::Keeper    PACKAGE = Time::Keeper

void
strftime(self, ...)
        SV *self
    ALIAS:
        format = 1
    PREINIT:
        tk_value *v;
        I32 i;
        const char *what = ix ? "Time::Keeper->format" : "Time::Keeper->strftime";
    PPCODE:
        v = tk_value_rw(self, what);
        if (items < 2)
            croak("%s: which pattern?", what);
        for (i = 1; i < items; i++) {
            tk_out o;
            STRLEN len;
            const char *p;
            SV *pat = ST(i);
            if (!SvUTF8(pat)) {
                STRLEN k;
                p = SvPV(pat, len);
                for (k = 0; k < len; k++)
                    if ((unsigned char)p[k] >= 0x80) {
                        pat = sv_mortalcopy(pat);
                        sv_utf8_upgrade(pat);
                        break;
                    }
            }
            p = SvPV(pat, len);
            o.sv = sv_2mortal(newSV(len * 2 + 40));
            sv_setpvs(o.sv, "");
            o.utf8 = 0;
            o.digits = NULL; o.nums = NULL; o.nums_len = 0;
            if (ix)
                tk_format_cldr(aTHX_ &o, self, v, tk_locale_of(v), p, len, NULL, NULL);
            else
                tk_strftime(aTHX_ &o, self, v, tk_locale_of(v), p, len);
            if (o.utf8)
                SvUTF8_on(o.sv);
            if (GIMME_V != G_ARRAY) {
                ST(0) = o.sv;
                XSRETURN(1);
            }
            XPUSHs(o.sv);
        }

SV *
format_date(self, ...)
        SV *self
    ALIAS:
        format_time = 1
        format_datetime = 2
    PREINIT:
        tk_value *v;
        const tk_locale_data *loc;
        int len = TK_LEN_MEDIUM;
        tk_out o;
        const char *what = ix == 0 ? "Time::Keeper->format_date"
                         : ix == 1 ? "Time::Keeper->format_time" : "Time::Keeper->format_datetime";
    CODE:
        v = tk_value_rw(self, what);
        loc = tk_locale_of(v);
        if (items > 1) {
            const char *l = SvPV_nolen(ST(1));
            if (strEQ(l, "full")) len = TK_LEN_FULL;
            else if (strEQ(l, "long")) len = TK_LEN_LONG;
            else if (strEQ(l, "medium")) len = TK_LEN_MEDIUM;
            else if (strEQ(l, "short")) len = TK_LEN_SHORT;
            else croak("%s: the length is 'full', 'long', 'medium' or 'short', not '%s'", what, l);
        }
        o.sv = newSVpvs("");
        o.utf8 = 0;
        o.digits = NULL; o.nums = NULL; o.nums_len = 0;
        {
            const tk_cal_names *cn = v->calendar != TK_CAL_GREGORY ? tk_cal_names_get(aTHX_ loc, v->calendar) : NULL;
            const char *df = cn ? tk_cal_date_format(cn, loc, len, 0) : loc->s.date_formats[len];
            const char *dtf = cn ? tk_cal_date_format(cn, loc, len, 1) : loc->s.datetime_formats[len];
            if (ix == 0)
                tk_format_cldr(aTHX_ &o, self, v, loc, df, strlen(df), NULL, NULL);
            else if (ix == 1)
                tk_format_cldr(aTHX_ &o, self, v, loc, loc->s.time_formats[len], strlen(loc->s.time_formats[len]), NULL, NULL);
            else
                tk_format_cldr(aTHX_ &o, self, v, loc, dtf, strlen(dtf), df, loc->s.time_formats[len]);
        }
        if (o.utf8)
            SvUTF8_on(o.sv);
        RETVAL = o.sv;
    OUTPUT:
        RETVAL

SV *
format_skeleton(self, skeleton)
        SV *self
        const char *skeleton
    PREINIT:
        tk_value *v;
        const tk_locale_data *loc;
        int lo, hi, found = -1;
        tk_out o;
    CODE:
        v = tk_value_rw(self, "Time::Keeper->format_skeleton");
        loc = tk_locale_of(v);
        PERL_UNUSED_VAR(lo);
        PERL_UNUSED_VAR(hi);
        PERL_UNUSED_VAR(found);
        {
            const char *p = v->calendar != TK_CAL_GREGORY
                ? tk_cal_skeleton_pattern(tk_cal_names_get(aTHX_ loc, v->calendar), loc, skeleton)
                : tk_skeleton_pattern(loc, skeleton);
            if (!p)
                croak("Time::Keeper->format_skeleton: the locale %s has no format for the skeleton '%s'", loc->id, skeleton);
            o.sv = newSVpvs("");
            o.utf8 = 0;
            o.digits = NULL; o.nums = NULL; o.nums_len = 0;
            tk_format_cldr(aTHX_ &o, self, v, loc, p, strlen(p), NULL, NULL);
        }
        if (o.utf8)
            SvUTF8_on(o.sv);
        RETVAL = o.sv;
    OUTPUT:
        RETVAL

SV *
month_name(self)
        SV *self
    ALIAS:
        month_abbr = 1
        day_name = 2
        day_abbr = 3
        am_pm = 4
        era_name = 5
        era_abbr = 6
        quarter_name = 7
        quarter_abbr = 8
        cyclic_year_name = 9
    PREINIT:
        tk_value *v;
        const tk_locale_data *loc;
        const tk_civil *c;
        const char *s;
    CODE:
        v = tk_value_rw(self, "Time::Keeper accessor");
        loc = tk_locale_of(v);
        c = tk_value_civil(v);
        if (ix == 9 && v->calendar != TK_CAL_CHINESE && v->calendar != TK_CAL_DANGI)
            XSRETURN_UNDEF;
        if (v->calendar != TK_CAL_GREGORY && (ix <= 1 || ix >= 5)) {
            /* the calendar's names: its months and eras, the Gregorian quarters over its ordinal months */
            tk_calfields cf;
            const tk_cal_names *cn = tk_cal_names_get(aTHX_ loc, v->calendar);
            unsigned q;
            tk_value_calfields(aTHX_ v, &cf, "Time::Keeper accessor");
            q = (cf.month - 1) / 3 + 1;
            switch (ix) {
            case 0:  s = tk_cal_month_name(cn, loc, tk_cal_of(v), &cf, TK_CTX_FORMAT, TK_W_WIDE); break;
            case 1:  s = tk_cal_month_name(cn, loc, tk_cal_of(v), &cf, TK_CTX_FORMAT, TK_W_ABBR); break;
            case 5:  s = tk_cal_era_name(cn, tk_cal_of(v), cf.era, TK_W_WIDE); break;
            case 6:  s = tk_cal_era_name(cn, tk_cal_of(v), cf.era, TK_W_ABBR); break;
            case 9:  s = tk_cal_cyclic_name(cn, tk_lunisolar_cyclic_year(cf.year), TK_W_ABBR); break;
            case 7:  s = q <= 4 ? loc->s.quarters[TK_CTX_FORMAT][TK_W_WIDE][q - 1] : ""; break;
            default: s = q <= 4 ? loc->s.quarters[TK_CTX_FORMAT][TK_W_ABBR][q - 1] : ""; break;
            }
            if (cf.leap_month && ix <= 1) {
                tk_out o;
                o.sv = newSVpvs("");
                o.utf8 = 0;
                o.digits = NULL; o.nums = NULL; o.nums_len = 0;
                tk_out_leap_wrap(aTHX_ &o, tk_cal_leap_pattern(cn, TK_CTX_FORMAT, ix ? TK_W_ABBR : TK_W_WIDE, 0), s, strlen(s));
                if (!tk_is_ascii(SvPVX(o.sv)))
                    SvUTF8_on(o.sv);
                RETVAL = o.sv;
                goto named;
            }
            RETVAL = newSVpv(s, 0);
            if (!tk_is_ascii(s))
                SvUTF8_on(RETVAL);
            goto named;
        }
        switch (ix) {
        case 0:  s = loc->s.months[TK_CTX_FORMAT][TK_W_WIDE][c->month - 1]; break;
        case 1:  s = loc->s.months[TK_CTX_FORMAT][TK_W_ABBR][c->month - 1]; break;
        case 2:  s = loc->s.days[TK_CTX_FORMAT][TK_W_WIDE][c->dow - 1]; break;
        case 3:  s = loc->s.days[TK_CTX_FORMAT][TK_W_ABBR][c->dow - 1]; break;
        case 4:  s = loc->s.periods[TK_W_ABBR][c->hour >= 12]; break;
        case 5:  s = loc->s.eras[TK_W_WIDE][c->year > 0]; break;
        case 6:  s = loc->s.eras[TK_W_ABBR][c->year > 0]; break;
        case 7:  s = loc->s.quarters[TK_CTX_FORMAT][TK_W_WIDE][tk_quarter(c->month) - 1]; break;
        default: s = loc->s.quarters[TK_CTX_FORMAT][TK_W_ABBR][tk_quarter(c->month) - 1]; break;
        }
        RETVAL = newSVpv(s, 0);
        if (!tk_is_ascii(s))
            SvUTF8_on(RETVAL);
      named:
        ;
    OUTPUT:
        RETVAL

SV *
iso8601(self, ...)
        SV *self
    ALIAS:
        rfc3339 = 1
        rfc9557 = 2
    PREINIT:
        tk_value *v;
        tk_out o;
        int digits = -1, form = 0;
        I32 i;
        const tk_civil *c;
        static const char *const whats[] = { "Time::Keeper->iso8601", "Time::Keeper->rfc3339", "Time::Keeper->rfc9557" };
        const char *what = whats[ix];
    CODE:
        v = tk_value_rw(self, what);
        if ((items - 1) % 2)
            croak("%s: the options are precision => 0 to 9%s", what, ix ? "" : " and form => extended, basic, week or ordinal");
        for (i = 1; i + 1 < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            if (strEQ(k, "precision"))
                digits = (int)tk_opt_int(aTHX_ ST(i + 1), what, "precision", 0, 9);
            else if (strEQ(k, "form") && !ix) {
                const char *fm = SvPV_nolen(ST(i + 1));
                form = strEQ(fm, "extended") ? 0 : strEQ(fm, "basic") ? 1 : strEQ(fm, "week") ? 2 : strEQ(fm, "ordinal") ? 3 : -1;
                if (form < 0)
                    croak("%s: form is extended, basic, week or ordinal, not '%s'", what, fm);
            }
            else
                croak("%s: the options are precision => 0 to 9%s, not '%s'", what,
                      ix ? "" : " and form => extended, basic, week or ordinal", k);
        }
        c = tk_value_civil(v);
        if (ix == 1 && (v->zone == TK_ZONE_FLOATING))
            croak("%s: floating time has no offset, and RFC 3339 needs one", what);
        if (ix == 1 && (c->year < 0 || c->year > 9999))
            croak("%s: RFC 3339 has only the years 0000 to 9999", what);
        o.sv = newSVpvs("");
        o.utf8 = 0;
        o.digits = NULL; o.nums = NULL; o.nums_len = 0;
        tk_out_datetime_form(aTHX_ &o, v, digits, form);
        if (ix == 2 && v->zone != TK_ZONE_FLOATING) {
            SV *name = sv_2mortal(tk_zone_name_sv(aTHX_ v));
            tk_out_offset(aTHX_ &o, v->utoff, 1, 1);
            tk_out_cat(aTHX_ &o, "[", 1);
            tk_out_cat(aTHX_ &o, SvPVX(name), SvCUR(name));
            tk_out_cat(aTHX_ &o, "]", 1);
            if (v->calendar != TK_CAL_GREGORY) {
                tk_out_cat(aTHX_ &o, "[u-ca=", 6);
                tk_out_str(aTHX_ &o, tk_cal_of(v)->id);
                tk_out_cat(aTHX_ &o, "]", 1);
            }
        }
        else if (v->zone == TK_ZONE_UTC)
            tk_out_cat(aTHX_ &o, "Z", 1);
        else if (v->zone != TK_ZONE_FLOATING)
            tk_out_offset(aTHX_ &o, v->utoff, form != 1, 1);
        RETVAL = o.sv;
    OUTPUT:
        RETVAL

SV *
rfc2822(self)
        SV *self
    ALIAS:
        http_date = 1
    PREINIT:
        tk_value *v;
        tk_out o;
        tk_value u;
        const char *what = ix ? "Time::Keeper->http_date" : "Time::Keeper->rfc2822";
    CODE:
        v = tk_value_rw(self, what);
        if (v->zone == TK_ZONE_FLOATING)
            croak("%s: floating time is not an instant", what);
        if (ix) {
            tk_zone_spec z;
            z.zone = TK_ZONE_UTC;
            z.fixed = 0;
            tk_value_init(aTHX_ &u, &v->inst, &z);
            if (tk_value_civil(&u)->year < 0 || tk_value_civil(&u)->year > 9999)
                croak("%s: only the years 0000 to 9999", what);
        }
        else if (tk_value_civil(v)->year < 0 || tk_value_civil(v)->year > 9999)
            croak("%s: only the years 0000 to 9999", what);
        o.sv = newSVpvs("");
        o.utf8 = 0;
        o.digits = NULL; o.nums = NULL; o.nums_len = 0;
        tk_rfc2822(aTHX_ &o, v, ix);
        RETVAL = o.sv;
    OUTPUT:
        RETVAL

SV *
ymd(self, ...)
        SV *self
    ALIAS:
        mdy = 1
        dmy = 2
        hms = 3
        date = 4
        time = 5
    PREINIT:
        tk_value *v;
        const tk_civil *c;
        const char *sep;
        STRLEN sl;
        char y[24];
        SV *out;
        tk_calfields cf;
        int64_t yv;
        unsigned mv, dv;
    CODE:
        v = tk_value_rw(self, "Time::Keeper accessor");
        c = tk_value_civil(v);
        yv = c->year;
        mv = c->month;
        dv = c->day;
        if (v->calendar != TK_CAL_GREGORY && ix != 3 && ix != 5) {
            /* the calendar's year, ordinal month and day */
            tk_value_calfields(aTHX_ v, &cf, "Time::Keeper accessor");
            yv = cf.year;
            mv = cf.month;
            dv = cf.day;
        }
        if (items > 1 && ix != 4 && ix != 5)
            sep = SvPV(ST(1), sl);
        else {
            sep = (ix == 3 || ix == 5) ? ":" : "-";
            sl = 1;
        }
        if (yv < 0)
            sprintf(y, "-%04ld", (long)-(long)yv);
        else
            sprintf(y, "%04ld", (long)yv);
        switch (ix) {
        case 0: case 4: out = newSVpvf("%s%.*s%02u%.*s%02u", y, (int)sl, sep, mv, (int)sl, sep, dv); break;
        case 1: out = newSVpvf("%02u%.*s%02u%.*s%s", mv, (int)sl, sep, dv, (int)sl, sep, y); break;
        case 2: out = newSVpvf("%02u%.*s%02u%.*s%s", dv, (int)sl, sep, mv, (int)sl, sep, y); break;
        default: out = newSVpvf("%02u%.*s%02u%.*s%02u", (unsigned)c->hour, (int)sl, sep, (unsigned)c->minute, (int)sl, sep, (unsigned)c->second); break;
        }
        if (items > 1 && SvUTF8(ST(1)))
            SvUTF8_on(out);
        RETVAL = out;
    OUTPUT:
        RETVAL

SV *
format_relative(self, ...)
        SV *self
    PREINIT:
        static const char *const fields[TK_RF_UNIT_COUNT] = { "year", "quarter", "month", "week", "day", "hour", "minute", "second" };
        static const char *const widths[TK_RW_COUNT] = { "long", "short", "narrow" };
        const char *what = "Time::Keeper->format_relative";
        tk_args a;
        tk_value *v, *to, now;
        const tk_locale_data *loc;
        tk_out o;
        int field = -1, width = TK_RW_LONG, numeric_auto = 1;
        int64_t count = 0;
    CODE:
        v = tk_value_rw(self, what);
        tk_value_gregorian_only(aTHX_ v, what);
        tk_args_parse(aTHX_ &ST(1), items - 1, TK_A(TK_A_TO) | TK_A(TK_A_UNIT) | TK_A(TK_A_STYLE) | TK_A(TK_A_NUMERIC), &a, what);
        if (a.v[TK_A_TO])
            to = tk_value_rw(a.v[TK_A_TO], what);
        else {
            tk_zone_spec z;
            tk_instant t;
            tk_now_sv(aTHX_ &t);
            tk_value_zone(v, &z);
            if (z.zone == TK_ZONE_FLOATING) { z.zone = TK_ZONE_UTC; z.fixed = 0; }
            tk_value_init(aTHX_ &now, &t, &z);
            to = &now;
        }
        if (a.v[TK_A_UNIT]) {
            const char *u = SvPV_nolen(a.v[TK_A_UNIT]);
            if (strNE(u, "auto")) {
                for (field = 0; field < TK_RF_UNIT_COUNT && strNE(u, fields[field]); field++) ;
                if (field == TK_RF_UNIT_COUNT)
                    croak("%s: unit is auto, year, quarter, month, week, day, hour, minute or second, not '%s'", what, u);
            }
        }
        if (a.v[TK_A_STYLE]) {
            const char *s = SvPV_nolen(a.v[TK_A_STYLE]);
            for (width = 0; width < TK_RW_COUNT && strNE(s, widths[width]); width++) ;
            if (width == TK_RW_COUNT)
                croak("%s: style is 'long', 'short' or 'narrow', not '%s'", what, s);
        }
        if (a.v[TK_A_NUMERIC]) {
            const char *s = SvPV_nolen(a.v[TK_A_NUMERIC]);
            if (strEQ(s, "always")) numeric_auto = 0;
            else if (strNE(s, "auto")) croak("%s: numeric is 'auto' or 'always', not '%s'", what, s);
        }
        if (field < 0)
            field = tk_relative_auto(aTHX_ to, v, &count, what);
        else
            count = tk_relative_count(aTHX_ to, v, field, what);
        loc = tk_locale_of(v);
        o.sv = newSVpvs("");
        o.utf8 = 0;
        o.digits = loc->ascii_digits ? NULL : loc->s.digits;
        tk_out_relative(aTHX_ &o, loc, field, width, count, numeric_auto);
        if (o.utf8)
            SvUTF8_on(o.sv);
        RETVAL = o.sv;
    OUTPUT:
        RETVAL

SV *
format_interval(self, end, ...)
        SV *self
        SV *end
    PREINIT:
        const char *what = "Time::Keeper->format_interval";
        tk_args a;
        tk_value *v, *e, b;
        SV *bsv;
        const tk_locale_data *loc;
        tk_out o;
    CODE:
        v = tk_value_rw(self, what);
        e = tk_value_rw(end, what);
        tk_value_gregorian_only(aTHX_ v, what);
        tk_args_parse(aTHX_ &ST(2), items - 2, TK_A(TK_A_SKELETON), &a, what);
        if (!a.v[TK_A_SKELETON])
            croak("%s: say skeleton => the fields wanted, such as 'yMMMd'", what);
        if ((v->zone == TK_ZONE_FLOATING) != (e->zone == TK_ZONE_FLOATING))
            croak("%s: one value is in floating time and the other is not", what);
        tk_value_in_zone_of(aTHX_ &b, e, v);
        b.locale = v->locale;
        b.calendar = v->calendar;
        bsv = sv_2mortal(tk_value_new_sv(aTHX_ SvSTASH(SvRV(self)), &b));
        loc = tk_locale_of(v);
        o.sv = newSVpvs("");
        o.utf8 = 0;
        o.digits = NULL; o.nums = NULL; o.nums_len = 0;
        tk_format_interval(aTHX_ &o, self, v, bsv, &b, loc, SvPV_nolen(a.v[TK_A_SKELETON]), what);
        if (o.utf8)
            SvUTF8_on(o.sv);
        RETVAL = o.sv;
    OUTPUT:
        RETVAL
