#ifndef TKB_CIVIL_H
#define TKB_CIVIL_H

/* A day is a count of days since 1970-01-01, Time::Keeper::Date's
 * epoch_days. The conversions are Howard Hinnant's era-based algorithms,
 * the same twenty lines Time::Keeper and Time::Keeper::Zone each carry, so
 * no table of the core's is reached for. */

static int64_t
tkb_floor_mod(int64_t a, int64_t b)
{
    int64_t r = a % b;
    return r < 0 ? r + b : r;
}

static int64_t
tkb_days_from_civil(int64_t y, unsigned m, unsigned d)
{
    int64_t era, yoe, doy, doe;
    y -= m <= 2;
    era = (y >= 0 ? y : y - 399) / 400;
    yoe = y - era * 400;
    doy = (153 * (int64_t)(m > 2 ? m - 3 : m + 9) + 2) / 5 + d - 1;
    doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    return era * 146097 + doe - 719468;
}

static void
tkb_civil_from_days(int64_t z, int64_t *yp, unsigned *mp, unsigned *dp)
{
    int64_t era, doe, yoe, y, doy, mm;
    z += 719468;
    era = (z >= 0 ? z : z - 146096) / 146097;
    doe = z - era * 146097;
    yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    y = yoe + era * 400;
    doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    mm = (5 * doy + 2) / 153;
    *dp = (unsigned)(doy - (153 * mm + 2) / 5 + 1);
    *mp = (unsigned)(mm < 10 ? mm + 3 : mm - 9);
    *yp = y + (*mp <= 2);
}

/* 1 = Monday .. 7 = Sunday. Day 0, 1970-01-01, was a Thursday. */
static unsigned
tkb_dow_from_days(int64_t z)
{
    return (unsigned)(tkb_floor_mod(z + 3, 7) + 1);
}

/* "YYYY-MM-DD", the year with a sign and more digits outside 0000..9999. */
static SV *
tkb_day_string(pTHX_ int64_t day)
{
    int64_t y;
    unsigned m, d;
    tkb_civil_from_days(day, &y, &m, &d);
    if (y >= 0 && y <= 9999)
        return newSVpvf("%04" IVdf "-%02u-%02u", (IV)y, m, d);
    return newSVpvf("%+" IVdf "-%02u-%02u", (IV)y, m, d);
}

/* An int64 as an SV: an IV where it fits, else an NV. */
static SV *
tkb_i64_sv(pTHX_ int64_t n)
{
    if (n >= IV_MIN && n <= IV_MAX)
        return newSViv((IV)n);
    return newSVnv((NV)n);
}

#endif
