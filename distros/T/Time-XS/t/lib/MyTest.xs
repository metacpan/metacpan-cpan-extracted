#include <xs.h>
#include <panda/time.h>

using namespace xs;
using namespace panda::time;
using panda::string;

#ifdef _WIN32
#  define SYSTIMEGM(x)    _mkgmtime(x)
#  define SYSTIMELOCAL(x) mktime(x)
#else
#  define SYSTIMEGM(x)    timegm(x)
#  define SYSTIMELOCAL(x) timelocal(x)
#endif

MODULE = MyTest                PACKAGE = MyTest
PROTOTYPES: DISABLE

time_t systimegm (int64_t sec, int64_t min, int64_t hour, int64_t mday, int64_t mon, int64_t year, int64_t isdst = -1) : ALIAS(systimelocal=1) {
    struct tm date;
    date.tm_sec   = sec;
    date.tm_min   = min;
    date.tm_hour  = hour;
    date.tm_mday  = mday;
    date.tm_mon   = mon;
    date.tm_year  = year;
    date.tm_isdst = isdst;
    if (ix == 0) RETVAL = SYSTIMEGM(&date);
    else RETVAL = SYSTIMELOCAL(&date);
}

const char* strftime (const char* fmt, time_t epoch) {
    char buf[100];
    datetime date;
    localtime(epoch, &date);
    auto sz = strftime(buf, sizeof(buf), fmt, &date);
    if (!sz) croak("should not happen");
    RETVAL = buf;
}

#ifndef _WIN32

bool test_gmtime (ptime_t step, ptime_t from, ptime_t till) : ALIAS(test_localtime=1) {
    datetime date1;
    struct tm date2;
    
    string tzname = ix == 0 ? string("GMT") : tzlocal()->name;
    char* hstr = getenv("HARNESS_ACTIVE");
    bool test = (hstr != NULL && strlen(hstr) > 0);
    
    static bool sranded = false;
    if (!sranded) { srand(time(NULL)); sranded = true; }

    bool isrand = false;
    ptime_t disperse, epoch;
    if (step == 0) {
        isrand = true; 
        disperse = from;
        step = 1;
        from = 0;
    }
    
    int cnt = 0;
    for (ptime_t i = from; i < till; i += step) {
        cnt++;
        memset(&date1, 0, sizeof(date1));
        memset(&date2, 0, sizeof(date2));
        
        if (isrand) epoch = rand() % (2*disperse) - disperse;
        else epoch = i;
        time_t sys_epoch = (time_t) epoch;
        
        if (ix == 0) {
            gmtime(epoch, &date1);
            gmtime_r(&sys_epoch, &date2);
        } else {
            localtime(epoch, &date1);
            localtime_r(&sys_epoch, &date2);
        }
        
        if (cnt % 100000 == 0 && !test) printf("TESTED #%d, last %04i-%02i-%02i %02i:%02i:%02i (off:%ld, dst=%d, zone=%s)\n", cnt, date2.tm_year+1900, date2.tm_mon+1, date2.tm_mday, date2.tm_hour, date2.tm_min, date2.tm_sec, date2.tm_gmtoff, date2.tm_isdst, date2.tm_zone);

        if (date1.year != (date2.tm_year + 1900) || date1.mon != date2.tm_mon || date1.mday != date2.tm_mday ||
            date1.hour != date2.tm_hour || date1.min != date2.tm_min || date1.sec != date2.tm_sec ||
            date1.isdst != date2.tm_isdst || date1.gmtoff != date2.tm_gmtoff || strcmp(date1.zone, date2.tm_zone) != 0) {
            warn(
                "zone=%.*s, epoch=%lli, got %d-%02lld-%02lld %02lld:%02lld:%02lld %d %d %d %d %s, should be %d-%02d-%02d %02d:%02d:%02d %d %d %d %ld %s",
                (int)tzname.length(), tzname.data(), (long long)epoch,
                date1.year, (long long)date1.mon+1, (long long)date1.mday, (long long)date1.hour, (long long)date1.min, (long long)date1.sec,
                date1.wday, date1.yday, date1.isdst, date1.gmtoff, date1.zone,
                date2.tm_year+1900, date2.tm_mon+1, date2.tm_mday, date2.tm_hour, date2.tm_min, date2.tm_sec,
                date2.tm_wday, date2.tm_yday, date2.tm_isdst, date2.tm_gmtoff, date2.tm_zone
            );
            XSRETURN_UNDEF;
        }
    }
    
    if (!test) printf("TESTED %d TIMES\n", cnt);
    
    RETVAL = true;
}

bool test_timegm (ptime_t step, ptime_t from, ptime_t till) : ALIAS(test_timelocal=1) {
    datetime date1;
    struct tm date2;
    
    char* hstr = getenv("HARNESS_ACTIVE");
    bool test = (hstr != NULL && strlen(hstr) > 0);
    
    static bool sranded = false;
    if (!sranded) { srand(time(NULL)); sranded = true; }

    bool isrand = false;
    ptime_t disperce_years;
    if (step == 0) {
        isrand = true; 
        step = 1;
        disperce_years = from;
        if (disperce_years > 200) disperce_years = 200;
        from = 0;
    }
    
    int cnt = 0;
    for (ptime_t i = from; step > 0 ? (i < till) : (i > till); i += step) {
        cnt++;
        bzero(&date1, sizeof(date1));
        bzero(&date2, sizeof(date2));
        
        if (isrand) {
            if (ix == 0) {
                int rnum = rand();
                date1.sec = rnum % 10000 - 5000;
                rnum /= 1000;
                date1.min = rnum % 10000 - 5000;
                rnum /= 1000;
                date1.hour = rnum % 100 - 50;
                rnum = rand();
                date1.mday = rnum % 100 - 50;
                rnum /= 100;
                date1.mon = rnum % 100 - 50;
                rnum /= 100;
                date1.year = rnum % 200 + 1910;
            } else { // dont test denormalized values (LINUX has bugs with them + when using leap seconds zone, our normalization may differ with OS)
                int rnum = rand();
                date1.sec = rnum % 60;
                rnum /= 1000;
                date1.min = rnum % 60;
                rnum /= 1000;
                date1.hour = rnum % 24;
                rnum = rand();
                date1.mday = rnum % 31 + 1;
                rnum /= 100;
                date1.mon = rnum % 11;
                rnum /= 100;
                date1.year = rnum % disperce_years + 1910;
            }
        }
        else {
            if (ix == 0) gmtime(i, &date1);
            else localtime(i, &date1);
        }

        if (ix == 1) date1.isdst = -1;
        dt2tm(date2, date1);
        
        datetime copy1 = date1;
        struct tm copy2 = date2;
        
        ptime_t mytime;
        time_t truetime;
        if (ix == 0) {
            truetime = timegm(&date2);
            if (isrand) mytime = timegm(&date1); // need normalization
            else mytime = timegml(&date1);
        } else {
            mytime = timelocal(&date1);
            truetime = timelocal(&date2);
        }
        
        if (cnt % 100000 == 0 && !test) printf("TESTED #%d, last %04d-%02d-%02d %02d:%02d:%02d\n", cnt, date2.tm_year+1900, date2.tm_mon+1, date2.tm_mday, date2.tm_hour, date2.tm_min, date2.tm_sec);
        
        bool same_ymdhms = (date1.year != (date2.tm_year + 1900) || date1.mon != date2.tm_mon || date1.mday != date2.tm_mday || date1.hour != date2.tm_hour || date1.min != date2.tm_min || date1.sec != date2.tm_sec) ? false : true;
        bool same_zone = (date1.isdst != date2.tm_isdst || date1.gmtoff != date2.tm_gmtoff || strcmp(date1.zone, date2.tm_zone) != 0) ? false : true;
        bool same_date = same_ymdhms && same_zone;

        if (mytime != truetime || !same_date) {
            if (truetime == -1) continue; // OS cannot handle such dates
            
            if (same_ymdhms && ix == 1) { // if ambiguity, OS may return unpredicted results. Lets handle that.
                datetime tmpdate = date1;
                tmpdate.isdst = 1;
                mytime = timelocal(&tmpdate);
                if (mytime == truetime) continue;
            }

            warn(
                "MY: epoch=%lli (%04d/%02lld/%02lld %02lld:%02lld:%02lld %4s %d) from %04d/%02lld/%02lld %02lld:%02lld:%02lld DST=%d (%.*s)",
                (long long)mytime,
                date1.year, (long long)date1.mon+1, (long long)date1.mday, (long long)date1.hour, (long long)date1.min, (long long)date1.sec,
                date1.zone, date1.gmtoff,
                copy1.year, (long long)copy1.mon+1, (long long)copy1.mday, (long long)copy1.hour, (long long)copy1.min, (long long)copy1.sec,
                copy1.isdst, (int)tzlocal()->name.length(), tzlocal()->name.data()
            );
            warn(
                "OS: epoch=%li (%04d/%02d/%02d %02d:%02d:%02d %4s %ld) from %04d/%02d/%02d %02d:%02d:%02d DST=%d (%.*s)",
                truetime, date2.tm_year+1900, date2.tm_mon+1, date2.tm_mday, date2.tm_hour, date2.tm_min, date2.tm_sec, date2.tm_zone, date2.tm_gmtoff,
                copy2.tm_year+1900, copy2.tm_mon+1, copy2.tm_mday, copy2.tm_hour, copy2.tm_min, copy2.tm_sec, copy2.tm_isdst, (int)tzlocal()->name.length(), tzlocal()->name.data()
            );
            warn("diff is %lli", (long long)(mytime - truetime));
            XSRETURN_UNDEF;
        }
    }
    
    if (!test) printf("TESTED %d TIMES\n", cnt);
    
    RETVAL = true;
}

Array gmtime_bench (ptime_t epoch) : ALIAS(localtime_bench=1) {
    datetime date;
    ptime_t max_epoch = epoch + 10000;
    if      (ix == 0) while(epoch++ < max_epoch) gmtime(epoch, &date);
    else if (ix == 1) while(epoch++ < max_epoch) localtime(epoch, &date);
    
    RETVAL = Array::create();
    RETVAL.push(Simple(date.sec));
    RETVAL.push(Simple(date.min));
    RETVAL.push(Simple(date.hour));
    RETVAL.push(Simple(date.mday));
    RETVAL.push(Simple(date.mon));
    RETVAL.push(Simple(date.year));
    RETVAL.push(Simple(date.wday));
    RETVAL.push(Simple(date.yday));
    RETVAL.push(Simple(date.isdst));
    RETVAL.push(Simple(date.gmtoff));
    RETVAL.push(Simple(date.zone));
}

Array posix_gmtime_bench (time_t epoch) : ALIAS(posix_localtime_bench=1) {
    struct tm date;
    time_t max_epoch = epoch + 10000;
    if      (ix == 0) while(epoch++ < max_epoch) gmtime_r(&epoch, &date);
    else if (ix == 1) while(epoch++ < max_epoch) localtime_r(&epoch, &date);

    RETVAL = Array::create();
    RETVAL.push(Simple(date.tm_sec));
    RETVAL.push(Simple(date.tm_min));
    RETVAL.push(Simple(date.tm_hour));
    RETVAL.push(Simple(date.tm_mday));
    RETVAL.push(Simple(date.tm_mon));
    RETVAL.push(Simple(date.tm_year));
    RETVAL.push(Simple(date.tm_wday));
    RETVAL.push(Simple(date.tm_yday));
    RETVAL.push(Simple(date.tm_isdst));
    RETVAL.push(Simple(date.tm_gmtoff));
    RETVAL.push(Simple(date.tm_zone));
}

ptime_t timegm_bench (ptime_t sec, ptime_t min, ptime_t hour, ptime_t mday, ptime_t mon, ptime_t year) : ALIAS(timegml_bench=1, timelocal_bench=2, timelocall_bench=3) {
    datetime date;
    date.sec = sec;
    date.min = min;
    date.hour = hour;
    date.mday = mday;
    date.mon = mon;
    date.year = year;
    date.isdst = -1;
    
    int i = 0;
    int cnt = 10000;
    RETVAL = 0;
    
    if      (ix == 0) while (i++ < cnt) RETVAL += timegm(&date);
    else if (ix == 1) while (i++ < cnt) RETVAL += timegml(&date);
    else if (ix == 2) while (i++ < cnt) RETVAL += timelocal(&date);
    else if (ix == 3) while (i++ < cnt) RETVAL += timelocall(&date);
}

time_t posix_timegm_bench (int64_t sec, int64_t min, int64_t hour, int64_t mday, int64_t mon, int64_t year) : ALIAS(posix_timelocal_bench=1) {
    struct tm date;
    date.tm_sec = sec;
    date.tm_min = min;
    date.tm_hour = hour;
    date.tm_mday = mday;
    date.tm_mon = mon;
    date.tm_year = year-1900;
    date.tm_isdst = -1;
    
    int i = 0;
    int cnt = 10000;
    RETVAL = 0;
    
    if      (ix == 0) while (i++ < cnt) RETVAL += timegm(&date);
    else if (ix == 1) while (i++ < cnt) RETVAL += timelocal(&date);
}

#endif