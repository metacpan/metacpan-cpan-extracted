#include <panda/time.h>
#include <stdio.h>
#include <panda/time/util.h>

namespace panda { namespace time {

static const int64_t ZONE_N_GMT = *((int64_t*)"GMT\0\0\0\0");

#define __PTIME_TRANS_BINFIND(VAR, FIELD) \
    int index = -1; \
    int low = 0; \
    int high = zone->trans_cnt; \
    while (high - low > 1) { \
        int mid = (high+low)/2; \
        if (zone->trans[mid].FIELD > VAR) high = mid; \
        else if (zone->trans[mid].FIELD < VAR) low = mid; \
        else { index = mid; break; } \
    } \
    if (index < 0) index = high - 1;

#define _PTIME_LT_LEAPSEC_CORR(source) \
    if (epoch < source.leap_end) result->sec = 60 + epoch - source.start;


static inline void _gmtime (ptime_t epoch, datetime* result) {
    ptime_t sec_remainder = (epoch + OUTLIM_EPOCH_BY_86400) % 86400;
    ptime_t delta_days = (epoch - sec_remainder)/86400;
    result->wday = (OUTLIM_DAY_BY_7 + EPOCH_WDAY + delta_days) % 7;
    result->hour = sec_remainder/3600;
    sec_remainder %= 3600;
    result->min = sec_remainder/60;
    result->sec = sec_remainder % 60;

    int32_t year;
    int32_t remainder;
    christ_year(EPOCH_CHRIST_DAYS + delta_days, year, remainder);

    int leap = is_leap_year(year);
    result->yday = remainder;
    result->mon  = YDAY2MON[leap][remainder];
    result->mday = YDAY2MDAY[leap][remainder];
    result->gmtoff = 0;
    result->n_zone = ZONE_N_GMT;
    result->isdst = 0;
    result->year = year;
}

static inline bool is_epoch_valid(ptime_t epoch) { return (epoch <= EPOCH_MAX) && (epoch >= EPOCH_MIN); }

static inline ptime_t _timegmll (const datetime* date) {
    int leap = is_leap_year(date->year);
    ptime_t delta_days = christ_days(date->year) + MON2YDAY[leap][date->mon] + date->mday - 1 - EPOCH_CHRIST_DAYS;
    return delta_days * 86400 + date->hour * 3600 + date->min * 60 + date->sec;
}

static inline ptime_t _timegml (datetime* date) {
    ptime_t mon_remainder = (date->mon + OUTLIM_MONTH_BY_12) % 12;
    date->year += (date->mon - mon_remainder) / 12;
    date->mon = mon_remainder;
    return _timegmll(date);
}

static inline ptime_t _timegm (datetime* date) {
    ptime_t result = _timegml(date);
    _gmtime(result, date);
    return result;
}

bool    gmtime  (ptime_t epoch, datetime* result) {
    if (is_epoch_valid(epoch)){
        _gmtime(epoch, result);
        return true;
    };
    return false;
}
ptime_t timegm  (datetime *date)                  { return _timegm(date); }
ptime_t timegml (datetime *date)                  { return _timegml(date); }

static inline ptime_t _calc_rule_epoch (int is_leap, const datetime* curdate, datetime border) {
    border.mday = (border.wday + curdate->yday - MON2YDAY[is_leap][border.mon] - curdate->wday + 378) % 7 + 7*border.yday - 6;
    if (border.mday > DAYS_IN_MONTH[is_leap][border.mon]) border.mday -= 7;
    border.year = curdate->year;
    return _timegmll(&border);
}

bool anytime (ptime_t epoch, datetime* result, const Timezone* zone) {
    bool r = is_epoch_valid(epoch);
    if (r) {
        if (epoch < zone->ltrans.start) {
            __PTIME_TRANS_BINFIND(epoch, start);
            _gmtime(epoch + zone->trans[index].offset, result);
            result->gmtoff = zone->trans[index].gmt_offset;
            result->n_zone = zone->trans[index].n_abbrev;
            result->isdst  = zone->trans[index].isdst;
            _PTIME_LT_LEAPSEC_CORR(zone->trans[index]);
        }
        else if (!zone->future.hasdst) { // future with no DST
            _gmtime(epoch + zone->future.outer.offset, result);
            result->n_zone = zone->future.outer.n_abbrev;
            result->gmtoff = zone->future.outer.gmt_offset;
            result->isdst  = zone->future.outer.isdst; // some zones stay in dst in future (when no POSIX string and last trans is in dst)
            _PTIME_LT_LEAPSEC_CORR(zone->ltrans);
        }
        else {
            _gmtime(epoch + zone->future.outer.offset, result);
            int is_leap = is_leap_year(result->year);

            if ((epoch >= _calc_rule_epoch(is_leap, result, zone->future.outer.end) - zone->future.outer.offset) &&
                (epoch < _calc_rule_epoch(is_leap, result, zone->future.inner.end) - zone->future.inner.offset)) {
                _gmtime(epoch + zone->future.inner.offset, result);
                result->isdst  = zone->future.inner.isdst;
                result->n_zone = zone->future.inner.n_abbrev;
                result->gmtoff = zone->future.inner.gmt_offset;
            } else {
                result->isdst  = zone->future.outer.isdst;
                result->n_zone = zone->future.outer.n_abbrev;
                result->gmtoff = zone->future.outer.gmt_offset;
            }
            _PTIME_LT_LEAPSEC_CORR(zone->ltrans);
        }
    };
    return r;
}

ptime_t timeany (datetime* date, const Timezone* zone) {
#   define PTIME_ANY_NORMALIZE
    if (date->isdst > 0) {
#       undef PTIME_AMBIGUOUS_LATER
#       include <panda/time/timeany_impl.icc>
    } else {
#       define PTIME_AMBIGUOUS_LATER
#       include <panda/time/timeany_impl.icc>
    }
#   undef PTIME_ANY_NORMALIZE
}

ptime_t timeanyl (datetime* date, const Timezone* zone) {
    if (date->isdst > 0) {
#       undef PTIME_AMBIGUOUS_LATER
#       include <panda/time/timeany_impl.icc>
    } else {
#       define PTIME_AMBIGUOUS_LATER
#       include <panda/time/timeany_impl.icc>
    }
}

size_t strftime (char* buf, size_t maxsize, const char* format, const datetime* timeptr) {
    tm systm;
    dt2tm(systm, *timeptr);
    return strftime(buf, maxsize, format, &systm);
}

void printftime (const char* format, const datetime* timeptr) {
    char buf[150];
    strftime(buf, 150, format, timeptr);
    printf("%s", buf);
}

}}
