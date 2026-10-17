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
