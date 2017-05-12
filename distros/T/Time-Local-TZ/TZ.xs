#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <time.h>
#include <string.h>


#define BACKUP_TZ()                                           \
    char* old_tz_p = getenv("TZ");                            \
    int envsize = old_tz_p == NULL ? 1 : strlen(old_tz_p)+1;  \
    char old_tz[envsize];                                     \
    if (old_tz_p != NULL)                                     \
        memcpy(old_tz, old_tz_p, envsize);                    \

#define RESTORE_TZ()                                          \
    if (old_tz_p == NULL) {                                   \
        unsetenv("TZ");                                       \
    } else {                                                  \
        setenv("TZ", old_tz, 1);                              \
    }                                                         \


MODULE = Time::Local::TZ		PACKAGE = Time::Local::TZ
PROTOTYPES: DISABLE


void
tz_localtime(tz, time)
    char* tz
    time_t time
    PREINIT:
        char time_string[26];
        struct tm tm;
    PPCODE:
        BACKUP_TZ();
            setenv("TZ", tz, 1);
            tzset();
            localtime_r(&time, &tm);
        RESTORE_TZ();

        if (GIMME_V == G_ARRAY) {
            EXTEND(SP, 9);
            ST(0) = sv_2mortal(newSViv(tm.tm_sec));
            ST(1) = sv_2mortal(newSViv(tm.tm_min));
            ST(2) = sv_2mortal(newSViv(tm.tm_hour));
            ST(3) = sv_2mortal(newSViv(tm.tm_mday));
            ST(4) = sv_2mortal(newSViv(tm.tm_mon));
            ST(5) = sv_2mortal(newSViv(tm.tm_year));
            ST(6) = sv_2mortal(newSViv(tm.tm_wday));
            ST(7) = sv_2mortal(newSViv(tm.tm_yday));
            ST(8) = sv_2mortal(newSViv(tm.tm_isdst));
            XSRETURN(9); 
        } else {
            asctime_r(&tm, time_string);
            ST(0) = sv_2mortal(newSVpv(time_string, 24));
            XSRETURN(1);
        }


void
tz_timelocal(...)
    PREINIT:
        char* tz;
        struct tm tm;
        time_t time;
    PPCODE:
        if (items < 7 || items > 10)
            croak("Usage: tz_timelocal(tz, sec, min, hour, mday, mon, year, [ wday, yday, is_dst ])");

        tz = SvPV_nolen(ST(0));
        tm.tm_sec   = SvIV(ST(1));
        tm.tm_min   = SvIV(ST(2));
        tm.tm_hour  = SvIV(ST(3));
        tm.tm_mday  = SvIV(ST(4));
        tm.tm_mon   = SvIV(ST(5));
        tm.tm_year  = SvIV(ST(6));
        tm.tm_wday  = -1;
        tm.tm_yday  = -1;
        tm.tm_isdst = -1;

        BACKUP_TZ();
            setenv("TZ", tz, 1);
            tzset();
            time = mktime(&tm);
        RESTORE_TZ();

        ST(0) = sv_2mortal(newSViv((IV)time));
        XSRETURN(1);


void
tz_truncate(tz, time, unit)
    char* tz
    time_t time
    int unit
    PREINIT:
        struct tm tm;
    PPCODE:
        if (unit < 1 || unit > 5)
            croak("Usage: tz_truncate(tz, time, unit), unit should be 1..5");

        BACKUP_TZ();
            setenv("TZ", tz, 1);
            tzset();
            localtime_r(&time, &tm);
            if (unit == 5) tm.tm_mon  = 0;
            if (unit >= 4) tm.tm_mday = 1;
            if (unit >= 3) tm.tm_hour = 0;
            if (unit >= 2) tm.tm_min  = 0;
            if (unit >= 1) tm.tm_sec  = 0;
            time = mktime(&tm);
        RESTORE_TZ();

        ST(0) = sv_2mortal(newSViv((IV)time));
        XSRETURN(1);


void
tz_offset(tz, time)
    char* tz
    time_t time
    PREINIT:
        struct tm tm;
        time_t time_utc;
    PPCODE:
        BACKUP_TZ()
            setenv("TZ", tz, 1);
            tzset();
            gmtime_r(&time, &tm);
            time_utc = mktime(&tm);
        RESTORE_TZ();

        ST(0) = sv_2mortal(newSViv((int)(time-time_utc)));
        XSRETURN(1);
