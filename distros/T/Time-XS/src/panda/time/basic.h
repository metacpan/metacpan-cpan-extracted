#pragma once
#include <limits>
#include <time.h>
#include <cstring>
#include <stdint.h>
#include <stddef.h>

namespace panda { namespace time {

using ptime_t = int64_t;

const size_t ZONE_ABBR_MAX = 7; /* max length of local type abbrev name (MSK, EST, EDT, ...) */
const size_t ZONE_ABBR_MIN = 3;

/*
 epoch max is calculated for gmtime(s=59,m=59,h=23,mday=31,y=2**31-1) - 24 hours for possible tz offsets
 epoch min is calculated for gmtime(s=00,m=00,h=00,mday=01,y=-2**31)  + 24 hours for possible tz offsets
*/
static const constexpr ptime_t EPOCH_MAX =  67767976233446399l;
static const constexpr ptime_t EPOCH_MIN = -67768100567884800l;

struct datetime {
    ptime_t sec;
    ptime_t min;
    ptime_t hour;
    ptime_t mday;
    ptime_t mon;
    int32_t yday;
    int32_t wday;
    int32_t year;
    int32_t isdst;
    int32_t gmtoff;
    union {
        char    zone[ZONE_ABBR_MAX+1];
        int64_t n_zone;
    };
};
using dt = datetime;

const int DAYS_IN_MONTH [][12] = {
    {31,28,31,30,31,30,31,31,30,31,30,31},
    {31,29,31,30,31,30,31,31,30,31,30,31},
};

inline int is_leap_year (int32_t year) {
    return (year % 4) == 0 && ((year % 25) != 0 || (year % 16) == 0);
}

inline int days_in_month (int32_t year, uint8_t month) {
    return DAYS_IN_MONTH[is_leap_year(year)][month];
}

// DAYS PASSED SINCE 1 Jan 0001 00:00:00 TILL 1 Jan <year> 00:00:00
inline ptime_t christ_days (int32_t year) {
    ptime_t yearpos = (ptime_t)year + 2147483999U;
    ptime_t ret = yearpos*365;
    yearpos >>= 2;
    ret += yearpos;
    yearpos /= 25;
    ret -= yearpos - (yearpos >> 2) + (ptime_t)146097*5368710;
    return ret;
}

inline void dt2tm (tm& to, const datetime& from) {
    to.tm_sec    = from.sec;
    to.tm_min    = from.min;
    to.tm_hour   = from.hour;
    to.tm_mday   = from.mday;
    to.tm_mon    = from.mon;
    to.tm_year   = from.year-1900;
    to.tm_isdst  = from.isdst;
    to.tm_wday   = from.wday;
    to.tm_yday   = from.yday;
#ifndef _WIN32
    to.tm_gmtoff = from.gmtoff;
    to.tm_zone   = const_cast<char*>(from.zone);
#endif
}

inline void tm2dt (datetime& to, const tm& from) {
    to.sec    = from.tm_sec;
    to.min    = from.tm_min;
    to.hour   = from.tm_hour;
    to.mday   = from.tm_mday;
    to.mon    = from.tm_mon;
    to.year   = from.tm_year+1900;
    to.isdst  = from.tm_isdst;
    to.wday   = from.tm_wday;
    to.yday   = from.tm_yday;
#ifdef _WIN32
    to.gmtoff = 0;
    to.n_zone = 0;
#else
    to.gmtoff = from.tm_gmtoff;
    std::strncpy(to.zone, from.tm_zone, sizeof(to.zone));
    to.zone[sizeof(to.zone)-1] = 0;
#endif
}

}}
