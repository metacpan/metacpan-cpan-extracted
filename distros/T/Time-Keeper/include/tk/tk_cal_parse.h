#ifndef TK_CAL_PARSE_H
#define TK_CAL_PARSE_H

/* Fields read in a calendar other than the Gregorian, turned into the
 * Gregorian date of the same day, so that tk_fields_to_value can go on as
 * it does for every parse: the era and its year, or the extended or related
 * year, or the cyclic year; the month by CLDR's slot or by its code's
 * number and leap flag; the day or the day of the year. */
static void
tk_cal_fields_resolve(pTHX_ tk_fields *f, int cal_id, const char *what, const char *text)
{
    const tk_calendar *cal = &tk_calendars[cal_id];
    int lunisolar = cal_id == TK_CAL_CHINESE || cal_id == TK_CAL_DANGI;
    int64_t y, days;
    unsigned m = 1, d = 1;

    if (f->has_isoweek || f->has_week_sun || f->has_week_mon)
        croak("%s: '%s': a week is the ISO week, which the %s calendar does not count", what, text, cal->id);

    /* the year */
    if (f->has_related)
        y = f->related;
    else if (f->has_year && f->year_kind == 2)
        y = lunisolar ? f->year - 2637 : f->year;
    else if (f->has_year || f->has_y2) {
        int64_t ey = f->has_year ? f->year : tk_two_digit_year(f->y2);
        if (lunisolar) {
            /* the year of the cycle: the one in the cycle 1984 began */
            if (ey < 1 || ey > 60)
                croak("%s: '%s': a %s year is 1 to 60 in its cycle; give the related year with r", what, text, cal->id);
            y = 1983 + ey;
        }
        else {
            unsigned era = f->has_era ? f->era_index : cal->n_eras - 1;
            if (!cal->year_from_era(era, ey, &y))
                croak("%s: '%s': the era has no year %" IVdf, what, text, (IV)ey);
        }
    }
    else if (f->has_cyclic && lunisolar)
        y = 1983 + f->cyclic;
    else
        croak("%s: '%s': no year was read, and a %s date needs one", what, text, cal->id);
    if (!tk_cal_year_ok(cal, y))
        croak("%s: '%s': the year %" IVdf " is outside the %s calendar", what, text, (IV)y, cal->id);

    /* the day */
    if (f->has_doy && !f->has_month && !f->has_day) {
        if (f->doy < 1 || f->doy > tk_cal_days_in_year(cal, y))
            croak("%s: '%s': the %s year %" IVdf " has no day %u", what, text, cal->id, (IV)y, f->doy);
        days = cal->to_days(y, 1, 1) + f->doy - 1;
    }
    else {
        if (f->has_month) {
            unsigned slot = f->month;
            if (cal_id == TK_CAL_HEBREW) {
                int leap = cal->is_leap_year(y);
                if (slot < 1 || slot > (f->month_slot ? 13u : cal->months_in_year(y)) || (f->month_slot && slot == 6 && !leap))
                    croak("%s: '%s': the Hebrew year %" IVdf " has no month %u", what, text, (IV)y, slot);
                m = !f->month_slot || leap || slot <= 5 ? slot : slot - 1;
            }
            else if (lunisolar) {
                if (!cal->month_from_code(y, slot, f->leap_month_text, &m))
                    croak("%s: '%s': the %s year %" IVdf " has no month %u%s", what, text, cal->id, (IV)y, slot, f->leap_month_text ? " (leap)" : "");
            }
            else {
                if (slot < 1 || slot > cal->months_in_year(y))
                    croak("%s: '%s': the %s year %" IVdf " has %u months, not %u", what, text, cal->id, (IV)y, cal->months_in_year(y), slot);
                m = slot;
            }
        }
        if (f->has_day)
            d = f->day;
        if (d < 1 || d > cal->days_in_month(y, m))
            croak("%s: '%s': month %u of the %s year %" IVdf " has %u days, not %u", what, text, m, cal->id, (IV)y, cal->days_in_month(y, m), d);
        days = cal->to_days(y, m, d);
    }
    tk_civil_from_days(days, &f->year, &f->month, &f->day);
    f->has_year = f->has_month = f->has_day = 1;
    f->has_doy = f->has_y2 = f->has_century = f->era_bc = 0;
    f->year_kind = 0;
}

#endif
