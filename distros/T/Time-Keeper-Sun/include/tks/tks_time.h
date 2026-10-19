#ifndef TKS_TIME_H
#define TKS_TIME_H

#include <math.h>

/* The time scales under every formula in the book: the Julian Day in UT
 * from an instant and back, Delta T, Terrestrial Time, Julian centuries
 * from J2000.0, sidereal time, the nutation and the obliquity. Everything
 * here is double arithmetic; an instant is the source of truth and a JD is
 * derived from it, never the reverse except at the end of a computation.
 *
 * Angles are reduced modulo 360 in degrees before they become radians: a
 * term like 36000.77 T carries millions of degrees, and the reduction done
 * in radians would lose four digits in it. */

#define TKS_YEAR_MIN (-1999)
#define TKS_YEAR_MAX 3000

#define TKS_JD_EPOCH 2440587.5          /* 1970-01-01T00:00:00 UTC */
#define TKS_J2000    2451545.0          /* 2000 January 1.5 TT */
#define TKS_PI       3.14159265358979323846

static double
tks_deg_norm(double d)
{
    d = fmod(d, 360.0);
    if (d < 0.0)
        d += 360.0;
    else if (d == 0.0)
        d = 0.0;                /* fmod of a negative multiple of 360 is -0: perls before 5.14 print it so */
    return d;
}

static double tks_rad(double d) { return d * (TKS_PI / 180.0); }
static double tks_deg(double r) { return r * (180.0 / TKS_PI); }

/* ---- the Julian Day -------------------------------------------------- */

/* The Julian Day of an instant, read as UT. The nanoseconds go in at double
 * precision (a JD near 2.46e6 holds about fifty microseconds), which is as
 * much as the astronomy can use; a leap second (nsec of 1e9 or more) lands
 * one second after 23:59:59, as it should in a scale with no leap seconds. */
static double
tks_jd_ut(const time_keeper_instant *t)
{
    return TKS_JD_EPOCH + (double)t->sec / 86400.0 + (double)t->nsec / 86400.0e9;
}

/* The instant of a JD in UT, with the nanoseconds the double holds. */
static void
tks_instant_from_jd(double jd, time_keeper_instant *out)
{
    double s = (jd - TKS_JD_EPOCH) * 86400.0;
    double f = floor(s);
    out->sec = (int64_t)f;
    out->nsec = (int32_t)((s - f) * 1e9 + 0.5);
    if (out->nsec >= 1000000000) {
        out->sec++;
        out->nsec -= 1000000000;
    }
}

/* The instant nearest a JD in UT, to the whole second, half up: the form
 * every result takes. */
static void
tks_instant_from_jd_second(double jd, time_keeper_instant *out)
{
    out->sec = (int64_t)floor((jd - TKS_JD_EPOCH) * 86400.0 + 0.5);
    out->nsec = 0;
}

/* Julian centuries from J2000.0, of a JD in whichever scale the formula
 * takes (TT for nearly all of them, UT for sidereal time). */
static double tks_T(double jd) { return (jd - TKS_J2000) / 36525.0; }

/* The decimal year of a JD, for the Delta T expressions, which are smooth
 * enough that a fraction of a year is nothing to them. */
static double tks_decimal_year(double jd) { return 2000.0 + (jd - TKS_J2000) / 365.2425; }

/* ---- Delta T ----------------------------------------------------------- */

/* Espenak and Meeus's polynomial expressions (sources/delta-t-polynomials.txt),
 * by the decimal year. Used before 1972 only; see tks_delta_t. */
static double
tks_delta_t_poly(double y)
{
    double u, t;
    if (y < -500.0) {
        u = (y - 1820.0) / 100.0;
        return -20.0 + 32.0 * u * u;
    }
    if (y < 500.0) {
        u = y / 100.0;
        return 10583.6 + u * (-1014.41 + u * (33.78311 + u * (-5.952053 + u * (-0.1798452
               + u * (0.022174192 + u * 0.0090316521)))));
    }
    if (y < 1600.0) {
        u = (y - 1000.0) / 100.0;
        return 1574.2 + u * (-556.01 + u * (71.23472 + u * (0.319781 + u * (-0.8503463
               + u * (-0.005050998 + u * 0.0083572073)))));
    }
    if (y < 1700.0) {
        t = y - 1600.0;
        return 120.0 + t * (-0.9808 + t * (-0.01532 + t / 7129.0));
    }
    if (y < 1800.0) {
        t = y - 1700.0;
        return 8.83 + t * (0.1603 + t * (-0.0059285 + t * (0.00013336 - t / 1174000.0)));
    }
    if (y < 1860.0) {
        t = y - 1800.0;
        return 13.72 + t * (-0.332447 + t * (0.0068612 + t * (0.0041116 + t * (-0.00037436
               + t * (0.0000121272 + t * (-0.0000001699 + t * 0.000000000875))))));
    }
    if (y < 1900.0) {
        t = y - 1860.0;
        return 7.62 + t * (0.5737 + t * (-0.251754 + t * (0.01680668 + t * (-0.0004473624
               + t / 233174.0))));
    }
    if (y < 1920.0) {
        t = y - 1900.0;
        return -2.79 + t * (1.494119 + t * (-0.0598939 + t * (0.0061966 - t * 0.000197)));
    }
    if (y < 1941.0) {
        t = y - 1920.0;
        return 21.20 + t * (0.84493 + t * (-0.076100 + t * 0.0020936));
    }
    if (y < 1961.0) {
        t = y - 1950.0;
        return 29.07 + t * (0.407 + t * (-1.0 / 233.0 + t / 2547.0));
    }
    if (y < 1986.0) {
        t = y - 1975.0;
        return 45.45 + t * (1.067 + t * (-1.0 / 260.0 - t / 718.0));
    }
    if (y < 2005.0) {
        t = y - 2000.0;
        return 63.86 + t * (0.3345 + t * (-0.060374 + t * (0.0017275 + t * (0.000651814
               + t * 0.00002373599))));
    }
    if (y < 2050.0) {
        t = y - 2000.0;
        return 62.92 + t * (0.32217 + t * 0.005589);
    }
    u = (y - 1820.0) / 100.0;
    if (y < 2150.0)
        return -20.0 + 32.0 * u * u - 0.5628 * (2150.0 - y);
    return -20.0 + 32.0 * u * u;
}

/* Delta T (TT minus UT) at an instant, in seconds. From 1972 it is 32.184
 * plus TAI minus UTC from Time::Keeper's leap-second table (UT1 minus UTC,
 * under 0.9 s, is ignored), and after the table's last entry that entry
 * holds, which is what the table answers for any later instant. Before
 * 1972 it is the polynomial fit. */
static double
tks_delta_t(pTHX_ const time_keeper_instant *t)
{
    int tmu;
    if ((tks_tk(aTHX)->tai_minus_utc)(t, &tmu) == TIME_KEEPER_OK)
        return 32.184 + (double)tmu;
    return tks_delta_t_poly(tks_decimal_year(tks_jd_ut(t)));
}

/* The Julian Ephemeris Day (TT) of an instant. */
static double
tks_jde(pTHX_ const time_keeper_instant *t)
{
    return tks_jd_ut(t) + tks_delta_t(aTHX_ t) / 86400.0;
}

/* ---- the obliquity and the nutation ------------------------------------ */

/* The mean obliquity of the ecliptic (22.2), degrees, T in TT. */
static double
tks_obliquity_mean(double T)
{
    return 23.0 + (26.0 + 21.448 / 60.0) / 60.0
         + (-46.8150 * T + T * T * (-0.00059 + 0.001813 * T)) / 3600.0;
}

/* The nutation in longitude and in obliquity, arcseconds, by chapter 22's
 * short form: half an arcsecond in the first, a tenth in the second. */
static void
tks_nutation(double T, double *dpsi, double *deps)
{
    double om = tks_rad(tks_deg_norm(125.04452 - 1934.136261 * T));
    double l  = tks_rad(tks_deg_norm(280.4665 + 36000.7698 * T));
    double lp = tks_rad(tks_deg_norm(218.3165 + 481267.8813 * T));
    *dpsi = -17.20 * sin(om) - 1.32 * sin(2.0 * l) - 0.23 * sin(2.0 * lp) + 0.21 * sin(2.0 * om);
    *deps =   9.20 * cos(om) + 0.57 * cos(2.0 * l) + 0.10 * cos(2.0 * lp) - 0.09 * cos(2.0 * om);
}

/* The true obliquity, degrees. */
static double
tks_obliquity_true(double T)
{
    double dpsi, deps;
    tks_nutation(T, &dpsi, &deps);
    return tks_obliquity_mean(T) + deps / 3600.0;
}

/* ---- sidereal time ------------------------------------------------------ */

/* Mean sidereal time at Greenwich (12.4), degrees, of a JD in UT. The whole
 * days are reduced first: 360.98564736629 times a whole day is a whole
 * number of turns plus 0.98564736629 of a degree, so only that part is
 * kept, and the fraction of a day takes the full rate. */
static double
tks_sidereal_mean(double jd_ut)
{
    double d  = jd_ut - TKS_J2000;
    double di = floor(d);
    double df = d - di;
    double T  = d / 36525.0;
    double th = 280.46061837
              + tks_deg_norm(0.98564736629 * di)
              + 360.98564736629 * df
              + T * T * (0.000387933 - T / 38710000.0);
    return tks_deg_norm(th);
}

/* Apparent sidereal time at Greenwich, degrees: the mean plus the nutation
 * in right ascension, with the nutation taken at the TT of the instant. */
static double
tks_sidereal_apparent(double jd_ut, double jde)
{
    double T = tks_T(jde);
    double dpsi, deps;
    tks_nutation(T, &dpsi, &deps);
    return tks_deg_norm(tks_sidereal_mean(jd_ut)
                        + (dpsi / 3600.0) * cos(tks_rad(tks_obliquity_mean(T) + deps / 3600.0)));
}

/* ---- the range ---------------------------------------------------------- */

/* Dies when the instant's year in UTC is outside what this dist computes:
 * the span of the Delta T expressions and of the book's phase formulae. */
static void
tks_year_check(pTHX_ const time_keeper_instant *t, const char *what)
{
    time_keeper_zone z;
    time_keeper_civil c;
    z.kind = TIME_KEEPER_ZONE_UTC;
    z.value = 0;
    if ((tks_tk(aTHX)->civil)(aTHX_ t, &z, &c) != TIME_KEEPER_OK)
        croak("%s: the instant is outside the years Time::Keeper holds", what);
    if (c.year < TKS_YEAR_MIN || c.year > TKS_YEAR_MAX)
        croak("%s: the year %" IVdf " is outside the years Time::Keeper::Sun computes (%d to %d)",
              what, (IV)c.year, TKS_YEAR_MIN, TKS_YEAR_MAX);
}

#endif
