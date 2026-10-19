#ifndef TKR_ABI_SELFTEST_H
#define TKR_ABI_SELFTEST_H

/* Every entry of the table, called as a consumer calls it: through the
 * pointer Time::Keeper::Recurrence::_abi_ptr gives, with only the public
 * header's names. Returns 0, or the number of the first check that failed;
 * *made is an object new_sv made, for Perl to look at. */

#define TKRA_CHECK(cond) do { step++; if (!(cond)) goto fail; } while (0)

static int
tkr_abi_selftest(pTHX_ const time_keeper_recurrence_abi *A, SV **made)
{
    const time_keeper_abi *T = tkr_tk(aTHX);
    time_keeper_recurrence *daily = NULL, *cron = NULL, *bad = NULL, *ical = NULL, *again = NULL;
    time_keeper_zone nyc;
    time_keeper_instant start, t, u;
    char err[256];
    double d;
    int step = 0, i, rc;
    const char *ics = "DTSTART;TZID=America/New_York:19970902T090000\r\nRRULE:FREQ=DAILY;COUNT=3\r\nEXDATE;TZID=America/New_York:19970903T090000\r\n";

    *made = NULL;
    TKRA_CHECK(TIME_KEEPER_RECURRENCE_ABI_OK(A));                                              /* 1 */
    TKRA_CHECK(A->abi_version == TIME_KEEPER_RECURRENCE_ABI_VERSION);
    TKRA_CHECK((T->zone_parse)(aTHX_ "America/New_York", 16, &nyc) == TIME_KEEPER_OK);

    /* RFC 5545's first example: daily for ten, from 2 September 1997 09:00 in New York */
    start.sec = 873205200;
    start.nsec = 0;
    TKRA_CHECK((A->compile)(aTHX_ TIME_KEEPER_RECURRENCE_RRULE, "FREQ=DAILY;COUNT=10", 19, &nyc, &start,
               TIME_KEEPER_RECURRENCE_DEFAULT, TIME_KEEPER_RECURRENCE_DEFAULT, &daily, err, sizeof err) == TIME_KEEPER_RECURRENCE_OK);
    t.sec = start.sec - 1;
    t.nsec = 0;
    TKRA_CHECK((A->next)(aTHX_ daily, &t, &u) == TIME_KEEPER_RECURRENCE_OK && u.sec == 873205200 && u.nsec == 0);   /* 5 */
    for (i = 1; i < 10; i++) {
        t = u;
        if ((A->next)(aTHX_ daily, &t, &u) != TIME_KEEPER_RECURRENCE_OK)
            break;
    }
    TKRA_CHECK(i == 10 && u.sec == 873982800);
    t = u;
    TKRA_CHECK((A->next)(aTHX_ daily, &t, &u) == TIME_KEEPER_RECURRENCE_NONE && u.sec == 873982800);
    t.sec = 873982800 + 1;
    TKRA_CHECK((A->previous)(aTHX_ daily, &t, &u) == TIME_KEEPER_RECURRENCE_OK && u.sec == 873982800);
    t.sec = 873982800;
    TKRA_CHECK((A->previous)(aTHX_ daily, &t, &u) == TIME_KEEPER_RECURRENCE_OK && u.sec == 873896400);
    t.sec = start.sec;
    TKRA_CHECK((A->previous)(aTHX_ daily, &t, &u) == TIME_KEEPER_RECURRENCE_NONE);              /* 10 */

    /* what is refused, with the Perl words */
    rc = (A->compile)(aTHX_ TIME_KEEPER_RECURRENCE_RRULE, "COUNT=3", 7, &nyc, &start, -1, -1, &bad, err, sizeof err);
    TKRA_CHECK(rc == TIME_KEEPER_RECURRENCE_BAD && !bad && strstr(err, "FREQ is wanted") && !strstr(err, " line "));
    TKRA_CHECK((A->compile)(aTHX_ TIME_KEEPER_RECURRENCE_RRULE, "FREQ=DAILY", 10, &nyc, NULL, -1, -1, &bad, err, sizeof err) == TIME_KEEPER_RECURRENCE_BAD
               && strstr(err, "needs a start"));
    TKRA_CHECK((A->compile)(aTHX_ 9, "FREQ=DAILY", 10, &nyc, &start, -1, -1, &bad, err, sizeof err) == TIME_KEEPER_RECURRENCE_BAD);
    TKRA_CHECK((A->compile)(aTHX_ TIME_KEEPER_RECURRENCE_RRULE, "FREQ=DAILY", 10, &nyc, &start, 7, -1, &bad, err, sizeof err) == TIME_KEEPER_RECURRENCE_BAD);
    TKRA_CHECK((A->compile)(aTHX_ TIME_KEEPER_RECURRENCE_CRON, "0 0 30 2 *", 10, &nyc, NULL, -1, -1, &bad, err, sizeof err) == TIME_KEEPER_RECURRENCE_BAD
               && strstr(err, "can never fire"));                                                                     /* 15 */
    TKRA_CHECK((A->compile)(aTHX_ TIME_KEEPER_RECURRENCE_RRULE, "FREQ=DAILY", 10, &nyc, &start, -1, -1, &bad, NULL, 0) == TIME_KEEPER_RECURRENCE_OK);
    (A->release)(bad);
    bad = NULL;
    (A->release)(NULL);
    TKRA_CHECK((A->next)(aTHX_ NULL, &t, &u) == TIME_KEEPER_RECURRENCE_BAD);

    /* a cron in New York across the March change: 03:00 still happens, 02:30 does not */
    TKRA_CHECK((A->compile)(aTHX_ TIME_KEEPER_RECURRENCE_CRON, "0 3 * * *", 9, &nyc, NULL, -1, -1, &cron, err, sizeof err) == TIME_KEEPER_RECURRENCE_OK);
    t.sec = 1772884800;                                     /* 2026-03-07T12:00:00Z */
    TKRA_CHECK((A->next)(aTHX_ cron, &t, &u) == TIME_KEEPER_RECURRENCE_OK && u.sec == 1772953200);
    t = u;
    TKRA_CHECK((A->next)(aTHX_ cron, &t, &u) == TIME_KEEPER_RECURRENCE_OK && u.sec == 1773039600);   /* 20 */
    TKRA_CHECK((A->cron_next)(aTHX_ "0 3 * * *", 9, "America/New_York", 16, 1772884800.0, &d, err, sizeof err) == TIME_KEEPER_RECURRENCE_OK
               && d == 1772953200.0);
    TKRA_CHECK((A->cron_next)(aTHX_ "30 2 * * *", 10, "America/New_York", 16, 1772884800.0, &d, err, sizeof err) == TIME_KEEPER_RECURRENCE_OK
               && d == 1773037800.0);
    TKRA_CHECK((A->cron_next)(aTHX_ "*/15 * * * *", 12, NULL, 0, 1000.0, &d, err, sizeof err) == TIME_KEEPER_RECURRENCE_OK && d == 1800.0);
    TKRA_CHECK((A->cron_next)(aTHX_ "*/15 * * * *", 12, "UTC", 3, 900.0, &d, err, sizeof err) == TIME_KEEPER_RECURRENCE_OK && d == 1800.0);
    TKRA_CHECK((A->cron_next)(aTHX_ "@every 15m", 10, "", 0, 1000.5, &d, err, sizeof err) == TIME_KEEPER_RECURRENCE_OK && d == 1900.5);    /* 25 */
    TKRA_CHECK((A->cron_next)(aTHX_ "0 0 30 2 *", 10, "UTC", 3, 1000.0, &d, err, sizeof err) == TIME_KEEPER_RECURRENCE_NONE);
    TKRA_CHECK((A->cron_next)(aTHX_ "61 * * * *", 10, "UTC", 3, 1000.0, &d, err, sizeof err) == TIME_KEEPER_RECURRENCE_BAD
               && strstr(err, "bad cron minute field"));
    TKRA_CHECK((A->cron_next)(aTHX_ "* * * * *", 9, "Nowhere/Special", 15, 1000.0, &d, err, sizeof err) == TIME_KEEPER_RECURRENCE_BAD
               && strstr(err, "is not a time zone"));
    TKRA_CHECK((A->cron_next)(aTHX_ "* * * * *", 9, "+0530", 5, 1e300, &d, err, sizeof err) == TIME_KEEPER_RECURRENCE_RANGE);
    TKRA_CHECK((A->cron_next)(aTHX_ "0 9 * * *", 9, "+0530", 5, 0.0, &d, err, sizeof err) == TIME_KEEPER_RECURRENCE_OK && d == 12600.0);   /* 30 */

    TKRA_CHECK((A->rrule_next)(aTHX_ "FREQ=DAILY;COUNT=2", 18, "UTC", 3, 1000.25, 1000.25, &d, err, sizeof err) == TIME_KEEPER_RECURRENCE_OK
               && d == 87400.25);
    TKRA_CHECK((A->rrule_next)(aTHX_ "FREQ=DAILY;COUNT=2", 18, "UTC", 3, 1000.0, 87400.0, &d, err, sizeof err) == TIME_KEEPER_RECURRENCE_NONE);
    TKRA_CHECK((A->rrule_next)(aTHX_ "FREQ=DAILY;UNTIL=20300101T000000", 32, "America/New_York", 16, 1000.0, 1000.0, &d, err, sizeof err) == TIME_KEEPER_RECURRENCE_BAD
               && strstr(err, "UNTIL must be in UTC"));
    TKRA_CHECK((A->rrule_next)(aTHX_ "FREQ=DAILY;BYHOUR=2;BYMINUTE=30", 31, "America/New_York", 16, 1772800200.0, 1772884800.0, &d, err, sizeof err) == TIME_KEEPER_RECURRENCE_OK
               && d == 1772955000.0);                                                                            /* 03:30 EDT on the 8th: forward over the gap */

    /* gap => fail: 02:30 on 8 March 2026 did not happen in New York */
    t.sec = 1772868600;                                     /* 2026-03-07T02:30:00-05:00 */
    t.nsec = 0;
    TKRA_CHECK((A->compile)(aTHX_ TIME_KEEPER_RECURRENCE_RRULE, "FREQ=DAILY", 10, &nyc, &t, TIME_KEEPER_RECURRENCE_GAP_FAIL,
               TIME_KEEPER_RECURRENCE_DEFAULT, &bad, err, sizeof err) == TIME_KEEPER_RECURRENCE_OK);
    TKRA_CHECK((A->next)(aTHX_ bad, &t, &u) == TIME_KEEPER_RECURRENCE_GAP);
    (A->release)(bad);
    bad = NULL;

    /* an iCalendar set: the removed day is skipped */
    TKRA_CHECK((A->compile)(aTHX_ TIME_KEEPER_RECURRENCE_ICAL, ics, strlen(ics), NULL, NULL, -1, -1, &ical, err, sizeof err) == TIME_KEEPER_RECURRENCE_OK);  /* 35 */
    t.sec = 873205200;
    TKRA_CHECK((A->next)(aTHX_ ical, &t, &u) == TIME_KEEPER_RECURRENCE_OK && u.sec == 873205200 + 2 * 86400);
    t.sec = 873205200 + 2 * 86400;
    TKRA_CHECK((A->previous)(aTHX_ ical, &t, &u) == TIME_KEEPER_RECURRENCE_OK && u.sec == 873205200);

    /* objects and back */
    *made = (A->new_sv)(aTHX_ daily);
    TKRA_CHECK(*made && sv_isobject(*made) && sv_derived_from(*made, "Time::Keeper::Recurrence"));
    TKRA_CHECK((A->from_sv)(aTHX_ *made, &again) == TIME_KEEPER_RECURRENCE_OK && again);
    t.sec = 873205200;
    TKRA_CHECK((A->next)(aTHX_ again, &t, &u) == TIME_KEEPER_RECURRENCE_OK && u.sec == 873205200 + 86400);   /* 40 */
    TKRA_CHECK((A->from_sv)(aTHX_ sv_2mortal(newSViv(3)), &bad) == TIME_KEEPER_RECURRENCE_BAD);
    TKRA_CHECK((A->new_sv)(aTHX_ NULL) == NULL);
    {
        SV *v = (T->new_sv)(aTHX_ &start, &nyc, 0);           /* a Time::Keeper value is no rule */
        int r2 = v ? (A->from_sv)(aTHX_ v, &bad) : 0;
        if (v) SvREFCNT_dec(v);
        TKRA_CHECK(v && r2 == TIME_KEEPER_RECURRENCE_BAD);
    }
    {
        SV *set = (A->new_sv)(aTHX_ ical);
        int ok = set && sv_derived_from(set, "Time::Keeper::Recurrence::Set");
        if (set) SvREFCNT_dec(set);
        TKRA_CHECK(ok);
    }
    (A->release)(daily);
    daily = NULL;
    t.sec = 873205200;
    TKRA_CHECK((A->next)(aTHX_ again, &t, &u) == TIME_KEEPER_RECURRENCE_OK && u.sec == 873205200 + 86400);  /* outlives the first handle */
    step = 0;
  fail:
    (A->release)(daily);
    (A->release)(cron);
    (A->release)(ical);
    (A->release)(again);
    return step;
}

#endif
