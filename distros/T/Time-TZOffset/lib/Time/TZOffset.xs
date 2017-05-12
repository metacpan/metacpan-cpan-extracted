#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include "tzo_config.h"
#include <time.h>
#include <XSUB.h>

#ifdef __cplusplus
} /* extern "C" */
#endif

#include "ppport.h"

/*    Based on POSIX::strftime::GNU::XS
 *    Copyright (c) 2012-2014 Piotr Roszatycki <dexter@cpan.org>
 */

#define TM_YEAR_BASE 1900

/* Shift A right by B bits portably, by dividing A by 2**B and
   truncating towards minus infinity.  A and B should be free of side
   effects, and B should be in the range 0 <= B <= INT_BITS - 2, where
   INT_BITS is the number of useful bits in an int.  GNU code can
   assume that INT_BITS is at least 32.

   ISO C99 says that A >> B is implementation-defined if A < 0.  Some
   implementations (e.g., UNICOS 9.0 on a Cray Y-MP EL) don't shift
   right in the usual way when A < 0, so SHR falls back on division if
   ordinary A >> B doesn't seem to be the usual signed shift.  */
#define SHR(a, b)       \
  (-1 >> 1 == -1        \
   ? (a) >> (b)         \
   : (a) / (1 << (b)) - ((a) % (1 << (b)) < 0))


#if ! HAVE_TM_GMTOFF
#ifndef HAVE_GMTIME_R
struct tm *gmtime_r (const time_t *, struct tm *);
struct tm *
gmtime_r (const time_t *t, struct tm *tp)
{
  struct tm *ltp;
  ltp = gmtime(t);
  *(tp) = *ltp;
  return ltp;
}
#endif
#ifndef HAVE_LOCALTIME_R
struct tm *localtime_r (const time_t *, struct tm *);
struct tm *
localtime_r (const time_t *t, struct tm *tp)
{
  struct tm *ltp;
  ltp = localtime(t);
  *(tp) = *ltp;
  return ltp;
}
#endif

static int
gmtoff (const struct tm *tp)
{
  struct tm gtm;
  struct tm ltm;
  time_t lt;

  ltm = *tp;
  lt = mktime (&ltm);

  if (lt == (time_t) -1)
    {
      struct tm tm;

      if (! localtime_r (&lt, &tm)
          || ((ltm.tm_min ^ tm.tm_min)
              | (ltm.tm_hour ^ tm.tm_hour)
              | (ltm.tm_mday ^ tm.tm_mday)
              | (ltm.tm_mon ^ tm.tm_mon)
              | (ltm.tm_year ^ tm.tm_year)))
        return -1;
    }

  if (! gmtime_r (&lt, &gtm))
    return -1;

  {
    int a4 = SHR (ltm.tm_year, 2) + SHR (TM_YEAR_BASE, 2) - ! (ltm.tm_year & 3);
    int b4 = SHR (gtm.tm_year, 2) + SHR (TM_YEAR_BASE, 2) - ! (gtm.tm_year & 3);
    int a100 = a4 / 25 - (a4 % 25 < 0);
    int b100 = b4 / 25 - (b4 % 25 < 0);
    int a400 = SHR (a100, 2);
    int b400 = SHR (b100, 2);
    int intervening_leap_days = (a4 - b4) - (a100 - b100) + (a400 - b400);
    int years = ltm.tm_year - gtm.tm_year;
    int days = (365 * years + intervening_leap_days
                + (ltm.tm_yday - gtm.tm_yday));
    return (60 * (60 * (24 * days + (ltm.tm_hour - gtm.tm_hour))
                  + (ltm.tm_min - gtm.tm_min)));
  }
}
#endif

int
tzoffset (
    int             min,
    int             hour,
    int             mday,
    int             mon,
    int             year
) {
    struct tm mytm;
    dTHX;

    memset(&mytm,0,sizeof(mytm));
    mytm.tm_sec = 0;
    mytm.tm_min = min;
    mytm.tm_hour = hour;
    mytm.tm_mday = mday;
    mytm.tm_mon = mon;
    mytm.tm_year = year;
    mytm.tm_isdst = -1;
    mktime(&mytm);

#if HAVE_TM_GMTOFF
    return mytm.tm_gmtoff;
#else
    return gmtoff(&mytm);
#endif
}

MODULE = Time::TZOffset    PACKAGE = Time::TZOffset PREFIX = xs_

PROTOTYPES: DISABLE

SV *
xs_tzoffset(sec, min, hour, mday, mon, year, wday = -1, yday = -1, isdst = -1)
    double          sec
    int             min
    int             hour
    int             mday
    int             mon
    int             year
    int             wday
    int             yday
    int             isdst
PREINIT:
    int offset;
CODE:
    offset = tzoffset(min, hour, mday, mon, year);
    RETVAL=newSVpvf("%+03d%02u", offset/60/60, offset/60%60);
OUTPUT:
    RETVAL

int
xs_tzoffset_as_seconds(sec, min, hour, mday, mon, year, wday = -1, yday = -1, isdst = -1)
    double          sec
    int             min
    int             hour
    int             mday
    int             mon
    int             year
    int             wday
    int             yday
    int             isdst
CODE:
    RETVAL = tzoffset(min, hour, mday, mon, year);
OUTPUT:
    RETVAL



