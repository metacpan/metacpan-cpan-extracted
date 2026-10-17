#ifndef TK_PARSE_SV_H
#define TK_PARSE_SV_H

/* From what was read to a value, the same way for every form. Fields not
 * given take Time::Piece's defaults: 1970-01-01T00:00:00 (Phase 09,
 * measured against Time::Piece 1.36's strptime). */

static int64_t
tk_two_digit_year(int y2)
{
    return y2 < 69 ? 2000 + y2 : 1900 + y2;    /* as POSIX and Time::Piece read %y */
}

static void
tk_fields_to_value(pTHX_ tk_value *out, tk_fields *f, SV *zone_opt, int gap, int overlap,
                   const char *what, const char *text)
{
    int64_t y = 1970, z;
    unsigned m = 1, d = 1;
    int hour = 0, minute = 0, second = 0;
    int32_t nsec = f->nsec;
    tk_zone_spec zs;

    if (f->has_epoch) {
        tk_instant t = f->epoch;
        if (!tk_instant_valid(&t))
            croak("%s: '%s' is out of range", what, text);
        tk_zone_spec_from_sv(aTHX_ zone_opt, &zs, what);
        tk_value_init(aTHX_ out, &t, &zs);
        return;
    }

    /* the year */
    if (f->has_year)
        y = f->year;
    else if (f->has_century && f->has_y2)
        y = f->century * 100 + f->y2;
    else if (f->has_y2)
        y = tk_two_digit_year(f->y2);
    else if (f->has_century)
        y = f->century * 100;
    if (f->era_bc)
        y = 1 - y;                              /* 1 BC is the year 0 */

    /* the date */
    if (f->has_isoweek && f->week) {
        int64_t wy = f->week_year ? f->week_year : y, mon, yy;
        unsigned last, wd = f->has_wday ? f->wday : 1;
        if (wy < TK_YEAR_MIN || wy > TK_YEAR_MAX)
            croak("%s: '%s': the year is out of range", what, text);
        tk_iso_week(wy, 12, 28, &yy, &last);
        if (f->week < 1 || f->week > last)
            croak("%s: '%s': %" IVdf " has no ISO week %u", what, text, (IV)wy, f->week);
        if (wd < 1 || wd > 7)
            croak("%s: '%s': there is no day %u of a week", what, text, wd);
        mon = tk_days_from_civil(wy, 1, 4);
        mon -= tk_dow_from_days(mon) - 1;
        tk_civil_from_days(mon + ((int64_t)f->week - 1) * 7 + wd - 1, &yy, &m, &d);
        y = yy;
    }
    else if (f->has_doy && !f->has_month && !f->has_day) {
        int64_t yy;
        if (y < TK_YEAR_MIN || y > TK_YEAR_MAX)
            croak("%s: '%s': the year is out of range", what, text);
        if (f->doy < 1 || f->doy > (tk_is_leap_year(y) ? 366u : 365u))
            croak("%s: '%s': %" IVdf " has no day %u", what, text, (IV)y, f->doy);
        tk_civil_from_days(tk_days_from_civil(y, 1, 1) + f->doy - 1, &yy, &m, &d);
    }
    else if ((f->has_week_sun || f->has_week_mon) && f->has_wday && !f->has_month && !f->has_day) {
        int64_t jan1 = tk_days_from_civil(y, 1, 1), first, day, yy;
        unsigned jd = tk_dow_from_days(jan1);
        /* the first Sunday (or Monday) of the year starts week 1; days before it are week 0 */
        if (f->has_week_sun)
            first = jan1 + (7 - jd % 7) % 7;
        else
            first = jan1 + (8 - jd) % 7;
        day = first + ((int64_t)f->week - 1) * 7
            + (f->has_week_sun ? f->wday % 7 : f->wday - 1);
        tk_civil_from_days(day, &yy, &m, &d);
        if (yy != y)
            croak("%s: '%s': that week and day are not in %" IVdf, what, text, (IV)y);
    }
    else {
        if (f->has_month) m = f->month;
        if (f->has_day) d = f->day;
    }
    if (y < TK_YEAR_MIN || y > TK_YEAR_MAX)
        croak("%s: '%s': the year is out of range", what, text);
    if (m < 1 || m > 12)
        croak("%s: '%s': there is no month %u", what, text, m);
    if (d < 1 || d > tk_days_in_month(y, m))
        croak("%s: '%s': %04" IVdf "-%02u has no day %u", what, text, (IV)y, m, d);
    z = tk_days_from_civil(y, m, d);
    if (f->has_wday && !(f->has_isoweek && f->week) && !((f->has_week_sun || f->has_week_mon) && !f->has_month)) {
        if (f->wday < 1 || f->wday > 7)
            croak("%s: '%s': there is no day %u of a week", what, text, f->wday);
        if (tk_dow_from_days(z) != f->wday)
            croak("%s: '%s': %04" IVdf "-%02u-%02u was a %s", what, text, (IV)y, m, d,
                  tk_locale_get(aTHX_ 0)->s.days[TK_CTX_FORMAT][TK_W_WIDE][tk_dow_from_days(z) - 1]);
    }

    /* the time */
    if (f->has_hour) hour = f->hour;
    if (f->has_minute) minute = f->minute;
    if (f->has_second) second = f->second;
    if (f->has_hour12 || f->has_ampm) {
        if (f->has_hour12 && (hour < 1 || hour > 12))
            croak("%s: '%s': a 12-hour clock has no hour %d", what, text, hour);
        if (f->has_ampm)
            hour = hour % 12 + (f->pm ? 12 : 0);
        else if (f->has_hour12)
            hour = hour % 12;
    }
    if (hour > 23 || minute > 59 || second > 60)
        croak("%s: '%s': there is no time %02d:%02d:%02d", what, text, hour, minute, second);
    if (f->hour24) {
        int64_t yy;
        tk_civil_from_days(z + 1, &yy, &m, &d);
        y = yy;
    }

    /* the zone */
    if (f->zone) {
        SV *name = sv_2mortal(newSVpvn(f->zone, f->zone_len));
        tk_zone_spec_from_sv(aTHX_ name, &zs, what);
    }
    else if (f->has_offset)
        zs.zone = f->utc || f->offset == 0 ? TK_ZONE_UTC : TK_ZONE_FIXED, zs.fixed = f->offset;
    else if (f->abbr) {
        if ((f->abbr_len == 3 && (strnEQ(f->abbr, "UTC", 3) || strnEQ(f->abbr, "GMT", 3)))
            || (f->abbr_len == 2 && strnEQ(f->abbr, "UT", 2)) || (f->abbr_len == 1 && *f->abbr == 'Z')) {
            zs.zone = TK_ZONE_UTC;
            zs.fixed = 0;
            f->abbr = NULL;
        }
        else if (!zone_opt || !SvOK(zone_opt))
            croak("%s: '%s': the abbreviation '%.*s' could mean more than one zone: say which with zone =>",
                  what, text, (int)f->abbr_len, f->abbr);
        else
            tk_zone_spec_from_sv(aTHX_ zone_opt, &zs, what);
    }
    else
        tk_zone_spec_from_sv(aTHX_ zone_opt, &zs, what);

    if (f->has_offset) {
        /* an offset fixes the instant; a zone in brackets then only names the zone */
        tk_instant t;
        int leap = second == 60;
        int32_t utoff;
        int isdst;
        tk_instant_from_civil(y, m, d, hour, minute, leap ? 59 : second, nsec, &t);
        t.sec -= f->offset;
        if (leap)
            t.nsec += TK_NSECS_PER_SEC;
        if (!tk_instant_valid(&t))
            croak("%s: '%s': %s", what, text, leap ? "there was no leap second then" : "out of range");
        tk_value_init(aTHX_ out, &t, &zs);
        if (f->zone && f->zone_critical) {
            tk_zone_offset(aTHX_ &zs, &t, &utoff, &isdst);
            if (utoff != f->offset)
                croak("%s: '%s': the offset is not the zone's at that time, and the zone is marked critical",
                      what, text);
        }
    }
    else
        tk_value_from_local(aTHX_ out, &zs, y, m, d, hour, minute, second, nsec, gap, overlap, what);

    if (f->dst_hint && !f->has_offset && zs.zone >= TK_ZONE_NAMED
        && ((out->flags & TK_F_DST) ? 2 : 1) != f->dst_hint) {
        /* in an overlap a zone's specific name says which reading */
        tk_value other;
        if (tk_value_from_local_rc(aTHX_ &other, &zs, y, m, d, hour, minute, second, nsec, gap,
                                   overlap == TKZ_OVERLAP_EARLIER ? TKZ_OVERLAP_LATER : TKZ_OVERLAP_EARLIER)
            == TK_LOCAL_OK && ((other.flags & TK_F_DST) ? 2 : 1) == f->dst_hint)
            *out = other;
    }

    if (f->abbr) {
        SV *have = sv_2mortal(tk_zone_abbr_sv(aTHX_ out));
        if ((SvCUR(have) != f->abbr_len || memNE(SvPVX(have), f->abbr, f->abbr_len))
            && !f->has_offset && zs.zone >= TK_ZONE_NAMED) {
            /* in an overlap the abbreviation says which reading: try the other */
            tk_value other;
            if (tk_value_from_local_rc(aTHX_ &other, &zs, y, m, d, hour, minute, second, nsec, gap,
                                       overlap == TKZ_OVERLAP_EARLIER ? TKZ_OVERLAP_LATER : TKZ_OVERLAP_EARLIER)
                == TK_LOCAL_OK) {
                SV *alt = sv_2mortal(tk_zone_abbr_sv(aTHX_ &other));
                if (SvCUR(alt) == f->abbr_len && memEQ(SvPVX(alt), f->abbr, f->abbr_len)) {
                    *out = other;
                    have = alt;
                }
            }
        }
        if (SvCUR(have) != f->abbr_len || memNE(SvPVX(have), f->abbr, f->abbr_len))
            croak("%s: '%s': the zone's abbreviation then was %s, not %.*s", what, text,
                  SvPVX(have), (int)f->abbr_len, f->abbr);
    }
}

/* ---- ISO 8601 durations ------------------------------------------------------ */

/* P1Y2M3W4DT5H6M7.5S, -P1D, and the mixed signs Duration's iso8601 writes
 * (P1M-2D). A fraction may end the hours, minutes or seconds. */
static int
tk_parse_duration_text(tk_cursor *c, tk_duration *d)
{
    int neg = 0, in_time = 0, any = 0, frac_done = 0;
    int64_t months = 0, days = 0, minutes = 0, seconds = 0, nsec = 0, frac_ns = 0, fs;
    Zero(d, 1, tk_duration);
    if (tk_peek(c) == '-' || tk_peek(c) == '+')
        neg = c->s[c->i++] == '-';
    if (!tk_eat_ci(c, 'P'))
        return tk_fail(c, "a duration starts with P");
    while (!tk_at_end(c)) {
        int sign = 1, fd = 0;
        int64_t v;
        int32_t frac = 0;
        char unit;
        if (tk_eat_ci(c, 'T')) {
            if (in_time)
                return tk_fail(c, "a second T");
            in_time = 1;
            continue;
        }
        if (frac_done)
            return tk_fail(c, "only the last unit may have a fraction");
        if (tk_peek(c) == '-')
            sign = -1, c->i++;
        if (!tk_digits_range(c, 1, 18, &v))
            return 0;
        if (tk_peek(c) == '.' || tk_peek(c) == ',') {
            c->i++;
            if (!tk_fraction(c, &frac, &fd))
                return 0;
            frac_done = 1;
        }
        if (v > TK_DUR_LIMIT / 60)
            return tk_fail(c, "out of range");
        if (tk_at_end(c))
            return tk_fail(c, "a unit was wanted");
        unit = (char)toUPPER(c->s[c->i]);
        c->i++;
        v *= sign;
        if (!in_time) {
            if (frac) return tk_fail(c, "years, months, weeks and days are whole");
            switch (unit) {
            case 'Y': months += v * 12; break;
            case 'M': months += v; break;
            case 'W': days += v * 7; break;
            case 'D': days += v; break;
            default: return tk_fail(c, "Y, M, W or D was wanted");
            }
        }
        else {
            switch (unit) {
            case 'H': minutes += v * 60; frac_ns += (int64_t)sign * frac * 3600; break;
            case 'M': minutes += v; frac_ns += (int64_t)sign * frac * 60; break;
            case 'S': seconds += v; nsec += (int64_t)sign * frac; break;
            default: return tk_fail(c, "H, M or S was wanted");
            }
        }
        any = 1;
    }
    if (!any)
        return tk_fail(c, "a duration has at least one unit");
    /* a fraction of an hour or a minute is minutes first, then seconds */
    fs = frac_ns / TK_NSECS_PER_SEC;
    minutes += fs / 60;
    seconds += fs % 60;
    nsec += frac_ns % TK_NSECS_PER_SEC;
    if (neg) {
        months = -months; days = -days; minutes = -minutes; seconds = -seconds; nsec = -nsec;
    }
    d->months = months;
    d->days = days;
    d->minutes = minutes;
    d->seconds = seconds;
    if (!tk_dur_normalize(d, nsec))
        return tk_fail(c, "out of range");
    d->eom = tk_dur_default_eom(d->months);
    return 1;
}

#endif
