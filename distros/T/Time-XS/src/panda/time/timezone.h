#pragma once
#include <panda/refcnt.h>
#include <panda/string.h>
#include <panda/time/basic.h>
#include <panda/string_view.h>

namespace panda { namespace time {

struct Timezone : panda::Refcnt {
    struct Transition {
        ptime_t start;        // time of transition
        ptime_t local_start;  // local time of transition (epoch+offset).
        ptime_t local_end;    // local time of transition's end (next transition epoch + MY offset).
        ptime_t local_lower;  // local_start or prev transition's local_end
        ptime_t local_upper;  // local_start or prev transition's local_end
        int32_t offset;       // offset from non-leap GMT
        int32_t gmt_offset;   // offset from leap GMT
        int32_t delta;        // offset minus previous transition's offset
        int32_t isdst;        // is DST in effect after this transition
        int32_t leap_corr;    // summary leap seconds correction at the moment
        int32_t leap_delta;   // delta leap seconds correction (0 if it's just a transition, != 0 if it's a leap correction)
        ptime_t leap_end;     // end of leap period (not including last second) = start + leap_delta
        ptime_t leap_lend;    // local_start + 2*leap_delta
        union {
            char    abbrev[ZONE_ABBR_MAX+1]; // transition (zone) abbreviation
            int64_t n_abbrev;                // abbrev as int64_t
        };
    };

    struct Rule {
        // rule for future (beyond transition list) dates and for abstract timezones
        // http://www.gnu.org/software/libc/manual/html_node/TZ-Variable.html
        // --------------------------------------------------------------------------------------------
        // 1 Jan   OUTER ZONE   OUTER END        INNER ZONE        INNER END     OUTER ZONE      31 Dec
        // --------------------------------------------------------------------------------------------
        struct Zone {
            enum class Switch { DATE, JDAY, DAY };
            union {
                char    abbrev[ZONE_ABBR_MAX+1]; // zone abbreviation
                int64_t n_abbrev;                // abbrev as int64_t
            };
            int32_t  offset;                     // offset from non-leap GMT
            int32_t  gmt_offset;                 // offset from leap GMT
            int32_t  isdst;                      // true if zone represents DST time
            Switch   type;                       // type of 'end' field
            datetime end;                        // dynamic date when this zone ends (only if hasdst=1)
        };

        uint32_t hasdst;       // does this rule have DST switching
        Zone     outer;        // always present
        Zone     inner;        // only present if hasdst=1
        int32_t  max_offset;   // max(outer.offset, inner.offset)
        int32_t  delta;        // inner.offset - outer.offset
    };

    struct Leap {
        ptime_t  time;
        uint32_t correction;
    };

    string      name;
    Transition* trans;
    uint32_t    trans_cnt;
    Transition  ltrans;              // trans[trans_cnt-1]
    Leap*       leaps;
    uint32_t    leaps_cnt;
    Rule        future;
    mutable bool is_local; // if timezone is set as local at the moment

    Timezone () {}

    void clear () {
        delete[] this->trans;
        if (this->leaps_cnt > 0) delete[] this->leaps;
    }

    ~Timezone () { clear(); }
};
using TimezoneSP = panda::iptr<const Timezone>;

void tzset (const string_view& zonename);
void tzset (const TimezoneSP& = TimezoneSP());

TimezoneSP tzget   (const string_view& zonename);
TimezoneSP tzlocal ();

const string& tzdir    ();
bool          tzdir    (const string&);
const string& tzsysdir ();

}}
