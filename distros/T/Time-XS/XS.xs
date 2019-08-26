#include <xs/time.h>

using namespace xs;
using namespace panda::time;

using panda::string;
using panda::string_view;

#ifdef _WIN32
    #define LT_FORMAT "%a %b %d %H:%M:%S %Y"
#else
    #define LT_FORMAT "%a %b %e %H:%M:%S %Y"
#endif

static inline Hash export_transition (const Timezone::Transition& trans, bool is_past) {
    auto hash = Hash::create();
    hash.store("offset", Simple(trans.offset));
    hash.store("abbrev", Simple(trans.abbrev));
    if (!is_past) {
        hash.store("start",      Simple(trans.start));
        hash.store("isdst",      Simple(trans.isdst));
        hash.store("gmt_offset", Simple(trans.gmt_offset));
        hash.store("leap_corr",  Simple(trans.leap_corr));
        hash.store("leap_delta", Simple(trans.leap_delta));
    }
    return hash;
}

MODULE = Time::XS                PACKAGE = Time::XS
PROTOTYPES: DISABLE

TimezoneSP tzget (string_view zonename = string_view()) {
    RETVAL = tzget(zonename);
}

string tzname () {
    RETVAL = tzlocal()->name;
}

void tzset (SV* newzone = NULL) {
    if (!newzone || !SvOK(newzone)) panda::time::tzset(string_view());
    else if (SvROK(newzone)) panda::time::tzset(xs::in<TimezoneSP>(newzone));
    else panda::time::tzset(xs::in<string_view>(newzone));
}

string tzdir (SV* newdirSV = NULL) {
    if (newdirSV) {
        string newdir = xs::in<string>(newdirSV);
        if (tzdir(newdir)) RETVAL = "1";
        else XSRETURN_UNDEF;
    } else
        RETVAL = tzdir();
}

string tzsysdir () {
    RETVAL = tzsysdir();
}

void gmtime (SV* epochSV = NULL) : ALIAS(localtime=1) {
    ptime_t epoch;
    if (epochSV) epoch = xs::in<ptime_t>(epochSV);
    else epoch = (ptime_t) ::time(NULL);

    datetime date;
    bool success = (ix == 0) ? gmtime(epoch, &date) : localtime(epoch, &date);

    if (GIMME_V == G_ARRAY) {
        if (!success) XSRETURN_EMPTY;
        EXTEND(SP, 9);
        EXTEND_MORTAL(9);
        mPUSHu(date.sec);
        mPUSHu(date.min);
        mPUSHu(date.hour);
        mPUSHu(date.mday);
        mPUSHu(date.mon);
        mPUSHi(date.year);
        mPUSHu(date.wday);
        mPUSHu(date.yday);
        mPUSHu(date.isdst);
        XSRETURN(9);
    } else {
        EXTEND(SP, 1);
        if (!success) XSRETURN_UNDEF;
        SV* ret = newSV(1000);
        SvPOK_on(ret);
        char* str = SvPVX(ret);
        size_t strlen = strftime(str, 1000, LT_FORMAT, &date);
        SvCUR_set(ret, strlen);
        mPUSHs(ret);
        XSRETURN(1);
    }
}

ptime_t timegm (SV* sec, SV* min, SV* hour, SV* mday, SV* mon, SV* year, SV* isdst = NULL) : ALIAS(timelocal=1, timegmn=2, timelocaln=3) {
    datetime date;
    date.sec  = xs::in<ptime_t>(sec);
    date.min  = xs::in<ptime_t>(min);
    date.hour = xs::in<ptime_t>(hour);
    date.mday = xs::in<ptime_t>(mday);
    date.mon  = xs::in<ptime_t>(mon);
    date.year = xs::in<ptime_t>(year);

    if (isdst) date.isdst = SvIV(isdst);
    else date.isdst = -1;

    switch (ix) {
        case 0:
            RETVAL = timegml(&date);
            break;
        case 1:
            RETVAL = timelocall(&date);
            break;
        case 2:
            RETVAL = timegm(&date);
            break;
        case 3:
            RETVAL = timelocal(&date);
            break;
        default: croak("not reached");
    }

    if (ix & 2) {
        sv_setiv(sec, date.sec);
        sv_setiv(min, date.min);
        sv_setiv(hour, date.hour);
        sv_setiv(mday, date.mday);
        sv_setiv(mon, date.mon);
        sv_setiv(year, date.year);
        if (isdst) sv_setiv(isdst, date.isdst);
    }
}

INCLUDE: Timezone.xsi
