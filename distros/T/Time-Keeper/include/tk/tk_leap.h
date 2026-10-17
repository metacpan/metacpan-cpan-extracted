#ifndef TK_LEAP_H
#define TK_LEAP_H

/* Leap seconds. An instant stays POSIX seconds, in which 23:59:60 has no
 * second of its own. It is held as the POSIX second of 23:59:59 with the
 * nanoseconds running on past a whole second: 23:59:60.25 is that second
 * and 1,250,000,000 ns. Ordering by (sec, nsec) stays right, and only the
 * last second of a day in tk_leap_ends may carry 1e9 ns or more.
 *
 * Elapsed time in SI seconds since 1970 is a POSIX second plus the leap
 * seconds before it, plus the nanoseconds: continuous through 23:59:60.
 * Before 1972 UTC ran at a varying rate against TAI: no leap seconds are
 * counted there and TAI - UTC is not given. */

/* How many leap seconds have ended at or before POSIX second s. */
static int
tk_leaps_before(int64_t s)
{
    int lo = 0, hi = TK_LEAP_COUNT;
    while (lo < hi) {
        int mid = lo + (hi - lo) / 2;
        if (tk_leap_ends[mid] <= s)
            lo = mid + 1;
        else
            hi = mid;
    }
    return lo;
}

/* Whether POSIX second s is 23:59:59 UTC on a day that ended with a leap
 * second, so that the second after it was 23:59:60. */
static int
tk_is_leap_day_end(int64_t s)
{
    int i = tk_leaps_before(s + 1);
    return i > 0 && tk_leap_ends[i - 1] == s + 1;
}

/* TAI - UTC in seconds at an instant, from 1972 on: 1, or 0 before 1972. */
static int
tk_tai_minus_utc(const tk_instant *t, int *out)
{
    if (t->sec < TK_LEAP_EPOCH)
        return 0;
    *out = TK_LEAP_BASE + tk_leaps_before(t->sec);   /* still the old value during 23:59:60 */
    return 1;
}

/* SI seconds and nanoseconds since 1970-01-01T00:00:00 UTC, leap seconds
 * counted. */
static void
tk_elapsed(const tk_instant *t, int64_t *sec, int32_t *nsec)
{
    *sec = t->sec + tk_leaps_before(t->sec);
    *nsec = t->nsec;
    if (*nsec >= TK_NSECS_PER_SEC) {
        *sec += 1;
        *nsec -= TK_NSECS_PER_SEC;
    }
}

/* b - a in SI seconds, leap seconds counted: whole seconds rounded down and
 * nanoseconds 0 .. 999,999,999, so -0.25 s is (-1, 750000000). */
static void
tk_minus_absolute(const tk_instant *b, const tk_instant *a, int64_t *sec, int32_t *nsec)
{
    int64_t bs, as;
    int32_t bn, an;
    tk_elapsed(b, &bs, &bn);
    tk_elapsed(a, &as, &an);
    *sec = bs - as;
    *nsec = bn - an;
    if (*nsec < 0) {
        *nsec += TK_NSECS_PER_SEC;
        *sec -= 1;
    }
}

#endif
