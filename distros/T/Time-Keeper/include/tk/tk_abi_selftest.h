#ifndef TK_ABI_SELFTEST_H
#define TK_ABI_SELFTEST_H

/* Every entry of the table, called as a consumer calls it: through the
 * pointer Time::Keeper::_abi_ptr gives, with only time_keeper_abi.h's names.
 * Returns 0, or the number of the first check that failed; *made is a value
 * new_sv made, for Perl to look at. */

#define TKA_CHECK(cond) do { step++; if (!(cond)) return step; } while (0)

static int
tk_abi_selftest(pTHX_ const time_keeper_abi *T, SV **made)
{
    int step = 0, k;
    time_keeper_instant t, u;
    time_keeper_zone tokyo, z, nyc;
    time_keeper_civil c;
    char buf[128];
    size_t n;
    SV *sv;

    *made = NULL;
    TKA_CHECK(TIME_KEEPER_ABI_OK(T));                                           /* 1 */
    TKA_CHECK(T->abi_version == TIME_KEEPER_ABI_VERSION);

    TKA_CHECK((T->now)(&t) == TIME_KEEPER_OK && t.sec > 1760000000 && t.nsec >= 0 && t.nsec < 1000000000);
    TKA_CHECK((T->now)(NULL) == TIME_KEEPER_BAD);

    TKA_CHECK((T->zone_parse)(aTHX_ "Asia/Tokyo", 10, &tokyo) == TIME_KEEPER_OK
              && tokyo.kind == TIME_KEEPER_ZONE_NAMED && tokyo.value >= 0);          /* 5 */
    TKA_CHECK((T->zone_parse)(aTHX_ "America/New_York", 16, &nyc) == TIME_KEEPER_OK);
    TKA_CHECK((T->zone_parse)(aTHX_ "+05:30", 6, &z) == TIME_KEEPER_OK
              && z.kind == TIME_KEEPER_ZONE_FIXED && z.value == 19800);
    TKA_CHECK((T->zone_parse)(aTHX_ "utc", 3, &z) == TIME_KEEPER_OK && z.kind == TIME_KEEPER_ZONE_UTC);
    TKA_CHECK((T->zone_parse)(aTHX_ "floating", 8, &z) == TIME_KEEPER_OK && z.kind == TIME_KEEPER_ZONE_FLOATING);
    TKA_CHECK((T->zone_parse)(aTHX_ "Nowhere/Special", 15, &z) == TIME_KEEPER_BAD);   /* 10 */
    TKA_CHECK((T->zone_parse)(aTHX_ "+25:00", 6, &z) == TIME_KEEPER_BAD);

    t.sec = 1760000000;
    t.nsec = 250000000;
    TKA_CHECK((T->civil)(aTHX_ &t, &tokyo, &c) == TIME_KEEPER_OK);
    TKA_CHECK(c.year == 2025 && c.month == 10 && c.day == 9 && c.hour == 17 && c.minute == 53
              && c.second == 20 && c.nanosecond == 250000000 && c.day_of_week == 4
              && c.day_of_year == 282 && c.offset == 32400 && c.is_dst == 0);
    TKA_CHECK((T->civil)(aTHX_ &t, NULL, &c) == TIME_KEEPER_OK && c.hour == 8 && c.offset == 0);
    z.kind = 9;
    TKA_CHECK((T->civil)(aTHX_ &t, &z, &c) == TIME_KEEPER_BAD);                      /* 15 */
    z.kind = TIME_KEEPER_ZONE_NAMED;
    z.value = 1000000;
    TKA_CHECK((T->civil)(aTHX_ &t, &z, &c) == TIME_KEEPER_BAD);

    (T->civil)(aTHX_ &t, &tokyo, &c);
    TKA_CHECK((T->from_civil)(aTHX_ &c, &tokyo, TIME_KEEPER_GAP_FAIL, TIME_KEEPER_OVERLAP_EARLIER, &u) == TIME_KEEPER_OK
              && u.sec == 1760000000 && u.nsec == 250000000);
    c.year = 2026; c.month = 3; c.day = 8; c.hour = 2; c.minute = 30; c.second = 0; c.nanosecond = 0;
    TKA_CHECK((T->from_civil)(aTHX_ &c, &nyc, TIME_KEEPER_GAP_FAIL, TIME_KEEPER_OVERLAP_EARLIER, &u) == TIME_KEEPER_GAP);
    TKA_CHECK((T->from_civil)(aTHX_ &c, &nyc, TIME_KEEPER_GAP_FORWARD, TIME_KEEPER_OVERLAP_EARLIER, &u) == TIME_KEEPER_OK
              && u.sec == 1772955000);
    c.month = 11; c.day = 1; c.hour = 1;                                              /* an overlap */
    TKA_CHECK((T->from_civil)(aTHX_ &c, &nyc, TIME_KEEPER_GAP_FAIL, TIME_KEEPER_OVERLAP_EARLIER, &u) == TIME_KEEPER_OK
              && u.sec == 1793511000);                                                /* 20 */
    TKA_CHECK((T->from_civil)(aTHX_ &c, &nyc, TIME_KEEPER_GAP_FAIL, TIME_KEEPER_OVERLAP_LATER, &u) == TIME_KEEPER_OK
              && u.sec == 1793514600);
    c.month = 13;
    TKA_CHECK((T->from_civil)(aTHX_ &c, &nyc, TIME_KEEPER_GAP_FAIL, TIME_KEEPER_OVERLAP_EARLIER, &u) == TIME_KEEPER_BAD);
    c.month = 2; c.day = 29;
    TKA_CHECK((T->from_civil)(aTHX_ &c, &nyc, TIME_KEEPER_GAP_FAIL, TIME_KEEPER_OVERLAP_EARLIER, &u) == TIME_KEEPER_BAD);
    c.year = 2016; c.month = 12; c.day = 31; c.hour = 23; c.minute = 59; c.second = 60;
    TKA_CHECK((T->from_civil)(aTHX_ &c, NULL, TIME_KEEPER_GAP_FAIL, TIME_KEEPER_OVERLAP_EARLIER, &u) == TIME_KEEPER_OK
              && u.sec == 1483228799 && u.nsec == 1000000000);
    c.year = 2026;
    TKA_CHECK((T->from_civil)(aTHX_ &c, NULL, TIME_KEEPER_GAP_FAIL, TIME_KEEPER_OVERLAP_EARLIER, &u) == TIME_KEEPER_NOLEAP);   /* 25 */
    c.year = 2000000000; c.second = 0;
    TKA_CHECK((T->from_civil)(aTHX_ &c, NULL, TIME_KEEPER_GAP_FAIL, TIME_KEEPER_OVERLAP_EARLIER, &u) == TIME_KEEPER_RANGE);
    c.year = 2026;
    TKA_CHECK((T->from_civil)(aTHX_ &c, NULL, 7, TIME_KEEPER_OVERLAP_EARLIER, &u) == TIME_KEEPER_BAD);

    n = (T->strftime)(aTHX_ buf, sizeof buf, "%Y-%m-%d %H:%M %Z", 17, &t, &tokyo, 0);
    TKA_CHECK(n == 20 && strEQ(buf, "2025-10-09 17:53 JST"));
    n = (T->strftime)(aTHX_ buf, 5, "%Y-%m-%d %H:%M %Z", 17, &t, &tokyo, 0);
    TKA_CHECK(n == 20 && strEQ(buf, "2025"));
    n = (T->strftime)(aTHX_ NULL, 0, "%Y", 2, &t, &tokyo, 0);
    TKA_CHECK(n == 4);                                                                /* 30 */
    k = (T->locale_find)("fr_ca", 5);
    TKA_CHECK(k > 0 && (T->locale_find)("fr", 2) > 0 && (T->locale_find)("en", 2) == 0);
    TKA_CHECK((T->locale_find)("xx-YY", 5) == -1 && (T->locale_find)(NULL, 0) == -1);
    k = (T->locale_find)("fr", 2);
    n = (T->format)(aTHX_ buf, sizeof buf, "EEEE d MMMM y", 13, &t, &tokyo, k);
    TKA_CHECK(strEQ(buf, "jeudi 9 octobre 2025") && n == 20);
    n = (T->format)(aTHX_ buf, sizeof buf, "d MMMM", 6, &t, &tokyo, 99999);
    TKA_CHECK(n == 0 && buf[0] == '\0');
    n = (T->strftime)(aTHX_ buf, sizeof buf, "%Od", 3, &t, &tokyo, (T->locale_find)("ar-EG", 5));
    TKA_CHECK(n == 4 && (unsigned char)buf[0] == 0xD9 && (unsigned char)buf[1] == 0xA0);   /* 35: Arabic-Indic 0 */

    n = (T->iso8601)(aTHX_ buf, sizeof buf, &t, &tokyo);
    TKA_CHECK(n == 29 && strEQ(buf, "2025-10-09T17:53:20.250+09:00"));
    n = (T->iso8601)(aTHX_ buf, sizeof buf, &t, NULL);
    TKA_CHECK(strEQ(buf, "2025-10-09T08:53:20.250Z"));
    n = (T->http_date)(buf, sizeof buf, &t);
    TKA_CHECK(n == 29 && strEQ(buf, "Thu, 09 Oct 2025 08:53:20 GMT"));
    n = (T->http_date)(buf, 10, &t);
    TKA_CHECK(n == 29 && strlen(buf) == 9);
    u.sec = INT64_MAX;
    u.nsec = 0;
    TKA_CHECK((T->http_date)(buf, sizeof buf, &u) == 0);                              /* 40 */

    TKA_CHECK((T->parse)(aTHX_ "2026-10-15T09:00:00.5+09:00[Asia/Tokyo]", 39, &u, &z) == TIME_KEEPER_OK
              && u.sec == 1792022400 && u.nsec == 500000000 && z.kind == TIME_KEEPER_ZONE_NAMED
              && z.value == tokyo.value);
    TKA_CHECK((T->parse)(aTHX_ "Thu, 15 Oct 2026 00:00:00 GMT", 29, &u, &z) == TIME_KEEPER_OK
              && u.sec == 1792022400 && z.kind == TIME_KEEPER_ZONE_UTC);
    TKA_CHECK((T->parse)(aTHX_ "yesterday", 9, &u, &z) == TIME_KEEPER_PARSE);
    TKA_CHECK((T->parse)(aTHX_ "2026-02-30", 10, &u, &z) == TIME_KEEPER_PARSE);
    TKA_CHECK((T->parse)(aTHX_ "2026-10-15[Nowhere/Special]", 27, &u, NULL) == TIME_KEEPER_PARSE);   /* 45 */
    TKA_CHECK(!SvTRUE(ERRSV));

    sv = (T->new_sv)(aTHX_ &t, &tokyo, k);
    TKA_CHECK(sv && SvREFCNT(sv) == 1 && sv_isa(sv, "Time::Keeper"));
    {
        time_keeper_instant w;
        time_keeper_zone wz;
        int wl = -1;
        TKA_CHECK((T->from_sv)(aTHX_ sv, &w, &wz, &wl) == TIME_KEEPER_OK && w.sec == t.sec && w.nsec == t.nsec
                  && wz.kind == TIME_KEEPER_ZONE_NAMED && wz.value == tokyo.value && wl == k);
        TKA_CHECK((T->from_sv)(aTHX_ sv, NULL, NULL, NULL) == TIME_KEEPER_OK);
        TKA_CHECK((T->from_sv)(aTHX_ &PL_sv_undef, &w, &wz, &wl) == TIME_KEEPER_BAD);   /* 50 */
        TKA_CHECK((T->from_sv)(aTHX_ NULL, &w, &wz, &wl) == TIME_KEEPER_BAD);
    }
    *made = sv;
    z.kind = TIME_KEEPER_ZONE_FIXED;
    z.value = 90000;
    TKA_CHECK((T->new_sv)(aTHX_ &t, &z, 0) == NULL);
    TKA_CHECK((T->new_sv)(aTHX_ &t, NULL, -1) == NULL);

    TKA_CHECK((T->tai_minus_utc)(&t, &k) == TIME_KEEPER_OK && k == 37);
    u.sec = -315619200;                                                               /* 1960 */
    u.nsec = 0;
    TKA_CHECK((T->tai_minus_utc)(&u, &k) == TIME_KEEPER_RANGE);                       /* 55 */
    TKA_CHECK((T->tai_minus_utc)(NULL, &k) == TIME_KEEPER_BAD);
    {                                                                             /* version 2: the calendars */
        time_keeper_calfields cf, cg;
        const char *id = NULL;
        int heb = (T->calendar_find)("hebrew", 6), chi = (T->calendar_find)("chinese", 7), wc = -1;
        SV *hv;
        TKA_CHECK(heb > 0 && chi > 0 && (T->calendar_find)("gregorian", 9) == 0 && (T->calendar_find)("ISO8601", 7) == 0);
        TKA_CHECK((T->calendar_find)("klingon", 7) == -1 && (T->calendar_find)(NULL, 0) == -1);
        TKA_CHECK((T->calendar_id)(heb, &id) == TIME_KEEPER_OK && strEQ(id, "hebrew"));
        TKA_CHECK((T->calendar_id)(0, &id) == TIME_KEEPER_OK && strEQ(id, "gregory"));                 /* 60 */
        TKA_CHECK((T->calendar_id)(999, &id) == TIME_KEEPER_BAD && (T->calendar_id)(-1, &id) == TIME_KEEPER_BAD
                  && (T->calendar_id)(heb, NULL) == TIME_KEEPER_BAD);
        TKA_CHECK((T->cal_fields)(aTHX_ &t, &tokyo, heb, &cf) == TIME_KEEPER_OK);
        TKA_CHECK(cf.calendar == heb && cf.year == 5786 && cf.era_year == 5786 && cf.era == 0 && cf.month == 1 && cf.day == 17
                  && cf.month_number == 1 && !cf.leap_month && !cf.leap_year && cf.months_in_year == 12 && cf.days_in_month == 30
                  && cf.days_in_year == 354 && cf.day_of_year == 17 && cf.hour == 17 && cf.minute == 53 && cf.second == 20
                  && cf.nanosecond == 250000000 && cf.offset == 32400 && cf.is_dst == 0);
        TKA_CHECK((T->cal_fields)(aTHX_ &t, &tokyo, chi, &cf) == TIME_KEEPER_OK && cf.year == 2025 && cf.month == 9 && cf.day == 18
                  && cf.era_year == 4662 && cf.month_number == 8 && cf.leap_year && cf.months_in_year == 13);
        TKA_CHECK((T->cal_fields)(aTHX_ &t, &tokyo, 999, &cf) == TIME_KEEPER_BAD && (T->cal_fields)(aTHX_ &t, &tokyo, heb, NULL) == TIME_KEEPER_BAD);   /* 65 */
        u.sec = INT64_C(-40000000000);                                                /* the year 702 */
        u.nsec = 0;
        TKA_CHECK((T->cal_fields)(aTHX_ &u, NULL, chi, &cf) == TIME_KEEPER_RANGE);
        TKA_CHECK((T->cal_fields)(aTHX_ &u, NULL, heb, &cf) == TIME_KEEPER_OK && cf.year == 4462);
        (T->cal_fields)(aTHX_ &t, &tokyo, heb, &cf);
        TKA_CHECK((T->cal_from_fields)(aTHX_ &cf, &tokyo, TIME_KEEPER_GAP_FAIL, TIME_KEEPER_OVERLAP_EARLIER, &u) == TIME_KEEPER_OK
                  && u.sec == t.sec && u.nsec == t.nsec);
        cg = cf; cg.month = 13;                                                       /* 5786 is a common year */
        TKA_CHECK((T->cal_from_fields)(aTHX_ &cg, &tokyo, TIME_KEEPER_GAP_FAIL, TIME_KEEPER_OVERLAP_EARLIER, &u) == TIME_KEEPER_BAD);
        cg = cf; cg.day = 31;
        TKA_CHECK((T->cal_from_fields)(aTHX_ &cg, &tokyo, TIME_KEEPER_GAP_FAIL, TIME_KEEPER_OVERLAP_EARLIER, &u) == TIME_KEEPER_BAD);   /* 70 */
        cg = cf; cg.calendar = 999;
        TKA_CHECK((T->cal_from_fields)(aTHX_ &cg, &tokyo, TIME_KEEPER_GAP_FAIL, TIME_KEEPER_OVERLAP_EARLIER, &u) == TIME_KEEPER_BAD);
        cg = cf; cg.calendar = chi; cg.year = 900; cg.month = 1; cg.day = 1;
        TKA_CHECK((T->cal_from_fields)(aTHX_ &cg, &tokyo, TIME_KEEPER_GAP_FAIL, TIME_KEEPER_OVERLAP_EARLIER, &u) == TIME_KEEPER_RANGE);
        cg = cf; cg.year = INT64_C(2000000000);
        TKA_CHECK((T->cal_from_fields)(aTHX_ &cg, &tokyo, TIME_KEEPER_GAP_FAIL, TIME_KEEPER_OVERLAP_EARLIER, &u) == TIME_KEEPER_RANGE);
        cg = cf; cg.calendar = 0; cg.year = 2025; cg.month = 10; cg.day = 9;         /* the Gregorian through the calendar entry */
        TKA_CHECK((T->cal_from_fields)(aTHX_ &cg, &tokyo, TIME_KEEPER_GAP_FAIL, TIME_KEEPER_OVERLAP_EARLIER, &u) == TIME_KEEPER_OK
                  && u.sec == t.sec);
        TKA_CHECK((T->cal_from_fields)(aTHX_ NULL, &tokyo, TIME_KEEPER_GAP_FAIL, TIME_KEEPER_OVERLAP_EARLIER, &u) == TIME_KEEPER_BAD);   /* 75 */
        n = (T->format_cal)(aTHX_ buf, sizeof buf, "d MMMM y", 8, &t, &tokyo, 0, heb);
        TKA_CHECK(n == 14 && strEQ(buf, "17 Tishri 5786"));
        n = (T->strftime_cal)(aTHX_ buf, sizeof buf, "%Y-%m-%d", 8, &t, &tokyo, 0, heb);
        TKA_CHECK(n == 10 && strEQ(buf, "5786-01-17"));
        n = (T->format_cal)(aTHX_ buf, sizeof buf, "d MMMM y", 8, &t, &tokyo, 0, 999);
        TKA_CHECK(n == 0 && buf[0] == '\0');
        n = (T->format_cal)(aTHX_ buf, sizeof buf, "d MMMM y", 8, &t, &tokyo, 0, 0);
        TKA_CHECK(n == 14 && strEQ(buf, "9 October 2025"));
        hv = (T->new_sv_cal)(aTHX_ &t, &tokyo, k, heb);
        TKA_CHECK(hv && SvREFCNT(hv) == 1 && sv_isa(hv, "Time::Keeper"));                         /* 80 */
        TKA_CHECK((T->from_sv_cal)(aTHX_ hv, NULL, NULL, NULL, &wc) == TIME_KEEPER_OK && wc == heb);
        TKA_CHECK((T->from_sv_cal)(aTHX_ sv, NULL, NULL, NULL, &wc) == TIME_KEEPER_OK && wc == 0);
        TKA_CHECK((T->from_sv_cal)(aTHX_ hv, NULL, NULL, NULL, NULL) == TIME_KEEPER_OK
                  && (T->from_sv_cal)(aTHX_ &PL_sv_undef, NULL, NULL, NULL, &wc) == TIME_KEEPER_BAD);
        SvREFCNT_dec(hv);
        TKA_CHECK((T->new_sv_cal)(aTHX_ &t, &tokyo, k, 999) == NULL);
    }
    {
        /* version 3, from Thursday 9 October 2025, 17:53:20.25 in Tokyo, in French */
        time_keeper_point p, q;
        time_keeper_parts parts;
        time_keeper_civil cc;
        char err[160];
        SV *dv;
        const char *lc = NULL;
        int fr = (T->locale_find)("fr", 2);
        p.inst.sec = 1760000000;
        p.inst.nsec = 250000000;
        p.zone = tokyo;
        p.locale = fr;
        p.calendar = 0;
        Zero(&parts, 1, time_keeper_parts);
        parts.days = 1;
        TKA_CHECK((T->plus)(aTHX_ &p, &parts, TIME_KEEPER_GAP_FORWARD, TIME_KEEPER_OVERLAP_EARLIER, &q, err, sizeof err) == TIME_KEEPER_OK
                  && q.inst.sec == p.inst.sec + 86400 && q.inst.nsec == p.inst.nsec && q.locale == fr);
        TKA_CHECK((T->truncate)(aTHX_ &p, TIME_KEEPER_UNIT_DAY, 1, &q, err, sizeof err) == TIME_KEEPER_OK
                  && (q.inst.sec + 9 * 3600) % 86400 == 0 && q.inst.nsec == 0);
        TKA_CHECK((T->end_of)(aTHX_ &p, TIME_KEEPER_UNIT_MONTH, TIME_KEEPER_WEEK_LOCALE, &q, err, sizeof err) == TIME_KEEPER_OK
                  && q.inst.nsec == 999999999 && (q.inst.sec + 9 * 3600 + 1) % 86400 == 0);
        TKA_CHECK((T->adjust_dow)(aTHX_ &p, 1, 1, 0, TIME_KEEPER_GAP_FORWARD, TIME_KEEPER_OVERLAP_EARLIER, &q, err, sizeof err) == TIME_KEEPER_OK
                  && q.inst.sec == p.inst.sec + 4 * 86400);                               /* to Monday */
        TKA_CHECK((T->nth_in_month)(aTHX_ &p, 7, 5, TIME_KEEPER_GAP_FORWARD, TIME_KEEPER_OVERLAP_EARLIER, &q, err, sizeof err) == TIME_KEEPER_RANGE
                  && strstr(err, "has no fifth") != NULL);                                /* four Sundays */
        TKA_CHECK((T->with_time)(aTHX_ &p, 9, 0, 0, 0, TIME_KEEPER_GAP_FORWARD, TIME_KEEPER_OVERLAP_EARLIER, &q, err, sizeof err) == TIME_KEEPER_OK
                  && q.inst.sec == p.inst.sec - (8 * 3600 + 53 * 60 + 20) && q.inst.nsec == 0);
        TKA_CHECK((T->parse_cldr)(aTHX_ "9 octobre 2025", 14, "d MMMM y", 8, TIME_KEEPER_KIND_VALUE, &tokyo, fr, 0,
                                   TIME_KEEPER_GAP_FORWARD, TIME_KEEPER_OVERLAP_EARLIER, &q, &cc, err, sizeof err) == TIME_KEEPER_OK
                  && cc.year == 2025 && cc.month == 10 && cc.day == 9 && cc.hour == 0);
        TKA_CHECK((T->parse_cldr)(aTHX_ "neuf", 4, "d MMMM y", 8, TIME_KEEPER_KIND_VALUE, &tokyo, fr, 0,
                                   TIME_KEEPER_GAP_FORWARD, TIME_KEEPER_OVERLAP_EARLIER, &q, &cc, err, sizeof err) == TIME_KEEPER_PARSE
                  && strstr(err, "cannot parse") != NULL);
        TKA_CHECK((T->parse_cldr)(aTHX_ "15:30", 5, "HH:mm", 5, TIME_KEEPER_KIND_TIME, NULL, fr, 0,
                                   TIME_KEEPER_GAP_FORWARD, TIME_KEEPER_OVERLAP_EARLIER, &q, &cc, err, sizeof err) == TIME_KEEPER_OK
                  && cc.hour == 15 && cc.minute == 30);
        parts.days = 0;
        parts.hours = 1;
        parts.minutes = 30;
        dv = (T->new_duration_sv)(aTHX_ &parts);
        TKA_CHECK(dv && SvREFCNT(dv) == 1 && sv_isa(dv, "Time::Keeper::Duration"));
        TKA_CHECK((T->duration_from_sv)(aTHX_ dv, &parts) == TIME_KEEPER_OK && parts.minutes == 90 && parts.hours == 0);
        SvREFCNT_dec(dv);
        TKA_CHECK((T->locale_code)(fr, &lc) == TIME_KEEPER_OK && strEQ(lc, "fr"));
        {
            /* Monday 19 October 2026 is day 20745; New York leaves DST at
             * 06:00 UTC on 2 November 2025 */
            time_keeper_zone ny;
            time_keeper_instant at;
            int32_t before = 0, after = 0;
            int kd = -1, dl = -1, ws = 0, we = 0;
            int64_t days = 0;
            SV *dd = (T->new_date_sv)(aTHX_ TIME_KEEPER_KIND_DATE, 20745, fr, NULL);
            TKA_CHECK(dd && SvREFCNT(dd) == 1 && sv_isa(dd, "Time::Keeper::Date"));
            TKA_CHECK((T->date_from_sv)(aTHX_ dd, &kd, &days, &dl) == TIME_KEEPER_OK
                      && kd == TIME_KEEPER_KIND_DATE && days == 20745 && dl == fr);
            SvREFCNT_dec(dd);
            dd = (T->new_date_sv)(aTHX_ TIME_KEEPER_KIND_YEAR_MONTH, 20745, 0, NULL);
            TKA_CHECK(dd && sv_isa(dd, "Time::Keeper::YearMonth")
                      && (T->date_from_sv)(aTHX_ dd, &kd, &days, NULL) == TIME_KEEPER_OK
                      && kd == TIME_KEEPER_KIND_YEAR_MONTH && days == 20745 - 18);
            SvREFCNT_dec(dd);
            TKA_CHECK((T->date_from_sv)(aTHX_ sv, &kd, &days, &dl) == TIME_KEEPER_BAD
                      && (T->date_from_sv)(aTHX_ &PL_sv_undef, NULL, NULL, NULL) == TIME_KEEPER_BAD);
            TKA_CHECK((T->new_date_sv)(aTHX_ TIME_KEEPER_KIND_TIME, 20745, 0, NULL) == NULL
                      && (T->new_date_sv)(aTHX_ TIME_KEEPER_KIND_DATE, 20745, -1, NULL) == NULL
                      && (T->new_date_sv)(aTHX_ TIME_KEEPER_KIND_DATE, INT64_C(1) << 60, 0, NULL) == NULL);
            TKA_CHECK((T->locale_weekend)(aTHX_ (T->locale_find)("ar-EG", 5), &ws, &we, err, sizeof err) == TIME_KEEPER_OK
                      && ws == 5 && we == 6);
            TKA_CHECK((T->locale_weekend)(aTHX_ fr, &ws, &we, NULL, 0) == TIME_KEEPER_OK && ws == 6 && we == 7
                      && (T->locale_weekend)(aTHX_ -1, &ws, &we, err, sizeof err) == TIME_KEEPER_BAD);
            TKA_CHECK((T->zone_parse)(aTHX_ "America/New_York", 16, &ny) == TIME_KEEPER_OK
                      && (T->next_change)(aTHX_ &p.inst, &ny, &at, &before, &after) == TIME_KEEPER_OK
                      && at.sec == 1762063200 && at.nsec == 0 && before == -14400 && after == -18000);
            TKA_CHECK((T->next_change)(aTHX_ &p.inst, &tokyo, &at, NULL, NULL) == TIME_KEEPER_RANGE
                      && (T->next_change)(aTHX_ &p.inst, NULL, &at, NULL, NULL) == TIME_KEEPER_RANGE
                      && (T->next_change)(aTHX_ NULL, &ny, &at, NULL, NULL) == TIME_KEEPER_BAD);
        }
        TKA_CHECK((T->plus)(aTHX_ NULL, &parts, TIME_KEEPER_GAP_FORWARD, TIME_KEEPER_OVERLAP_EARLIER, &q, NULL, 0) == TIME_KEEPER_BAD);
    }
    {
        time_keeper_abi other = *T;
        other.abi_version = TIME_KEEPER_ABI_VERSION - 1;
        TKA_CHECK(!TIME_KEEPER_ABI_OK(&other));                                     /* an older table is refused */
        other.abi_version = TIME_KEEPER_ABI_VERSION + 1;
        TKA_CHECK(TIME_KEEPER_ABI_OK(&other));                                      /* a newer one is a superset */
        TKA_CHECK(!TIME_KEEPER_ABI_OK((const time_keeper_abi *)NULL));
    }
    return 0;
}

#undef TKA_CHECK

#endif
