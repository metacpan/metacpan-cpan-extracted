#!perl
use 5.010;
use strict;
use warnings;
use Config;
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

# Author test: a separate extension that knows only perl's headers and
# time_keeper_abi.h, as installed, built here and loaded beside
# Time::Keeper. It resolves the table as the header says, the first time it
# is called, and uses it from XS.

BEGIN {
    eval { require ExtUtils::CBuilder; require ExtUtils::ParseXS; 1 }
        or plan skip_all => 'ExtUtils::CBuilder and ExtUtils::ParseXS are needed';
    ExtUtils::CBuilder->new(quiet => 1)->have_compiler or plan skip_all => 'no C compiler';
}
use Time::Keeper;

my ($inc) = grep { -f "$_/time_keeper_abi.h" }
            map { File::Spec->catdir($_, 'Time', 'Keeper', 'Install') } grep { !ref } @INC;
ok($inc, 'the header is installed where ExtUtils::Depends looks') or BAIL_OUT('no header');

my $dir = tempdir(CLEANUP => 1);
my $xs = File::Spec->catfile($dir, 'TKConsumer.xs');
open my $fh, '>', $xs or die "$xs: $!";
print $fh <<'XS';
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "time_keeper_abi.h"

static const time_keeper_abi *TK = NULL;

static const time_keeper_abi *
tk(pTHX)
{
    if (!TK) {
        SV *sv = eval_pv("require Time::Keeper; Time::Keeper::_abi_ptr()", 0);
        SV *err = get_sv("@", 0);
        if (sv && SvOK(sv) && (!err || !SvTRUE(err))) {
            const time_keeper_abi *t = INT2PTR(const time_keeper_abi *, SvUV(sv));
            if (TIME_KEEPER_ABI_OK(t))
                TK = t;
        }
        if (!TK)
            croak("TKConsumer: no Time::Keeper table");
    }
    return TK;
}

MODULE = TKConsumer    PACKAGE = TKConsumer

PROTOTYPES: DISABLE

SV *
http_date(epoch)
        IV epoch
    PREINIT:
        time_keeper_instant t;
        char buf[32];
        size_t n;
    CODE:
        t.sec = epoch;
        t.nsec = 0;
        n = (tk(aTHX)->http_date)(buf, sizeof buf, &t);
        RETVAL = newSVpvn(buf, n);
    OUTPUT:
        RETVAL

SV *
local_value(epoch, zone, locale)
        IV epoch
        const char *zone
        const char *locale
    PREINIT:
        time_keeper_instant t;
        time_keeper_zone z;
        int l;
    CODE:
        t.sec = epoch;
        t.nsec = 0;
        if ((tk(aTHX)->zone_parse)(aTHX_ zone, strlen(zone), &z) != TIME_KEEPER_OK)
            croak("no zone %s", zone);
        l = (tk(aTHX)->locale_find)(locale, strlen(locale));
        RETVAL = (tk(aTHX)->new_sv)(aTHX_ &t, &z, l < 0 ? 0 : l);
        if (!RETVAL)
            croak("new_sv refused");
    OUTPUT:
        RETVAL

SV *
stamp(value, pattern)
        SV *value
        SV *pattern
    PREINIT:
        time_keeper_instant t;
        time_keeper_zone z;
        int l;
        char buf[256];
        STRLEN plen;
        const char *p;
        size_t n;
    CODE:
        if ((tk(aTHX)->from_sv)(aTHX_ value, &t, &z, &l) != TIME_KEEPER_OK)
            croak("not a Time::Keeper value");
        p = SvPVutf8(pattern, plen);
        n = (tk(aTHX)->format)(aTHX_ buf, sizeof buf, p, plen, &t, &z, l);
        RETVAL = newSVpvn(buf, n < sizeof buf ? n : sizeof buf - 1);
        SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

int
version()
    CODE:
        RETVAL = tk(aTHX)->abi_version;
    OUTPUT:
        RETVAL

SV *
cal_stamp(value, pattern, calendar)
        SV *value
        SV *pattern
        const char *calendar
    PREINIT:
        time_keeper_instant t;
        time_keeper_zone z;
        int l, c;
        char buf[256];
        STRLEN plen;
        const char *p;
        size_t n;
    CODE:
        if ((tk(aTHX)->from_sv_cal)(aTHX_ value, &t, &z, &l, &c) != TIME_KEEPER_OK)
            croak("not a Time::Keeper value");
        c = (tk(aTHX)->calendar_find)(calendar, strlen(calendar));
        if (c < 0)
            croak("no calendar %s", calendar);
        p = SvPVutf8(pattern, plen);
        n = (tk(aTHX)->format_cal)(aTHX_ buf, sizeof buf, p, plen, &t, &z, l, c);
        RETVAL = newSVpvn(buf, n < sizeof buf ? n : sizeof buf - 1);
        SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

void
cal_ymd(value, calendar)
        SV *value
        const char *calendar
    PREINIT:
        time_keeper_instant t;
        time_keeper_zone z;
        time_keeper_calfields f;
        int c;
        const char *id;
    PPCODE:
        if ((tk(aTHX)->from_sv)(aTHX_ value, &t, &z, NULL) != TIME_KEEPER_OK)
            croak("not a Time::Keeper value");
        c = (tk(aTHX)->calendar_find)(calendar, strlen(calendar));
        if (c < 0 || (tk(aTHX)->cal_fields)(aTHX_ &t, &z, c, &f) != TIME_KEEPER_OK)
            croak("cal_fields refused");
        (tk(aTHX)->calendar_id)(f.calendar, &id);
        EXTEND(SP, 5);
        mPUSHs(newSVpv(id, 0));
        mPUSHi(f.year);
        mPUSHi(f.month);
        mPUSHi(f.day);
        mPUSHi(f.months_in_year);

SV *
cal_value(calendar, year, month, day, zone)
        const char *calendar
        IV year
        IV month
        IV day
        const char *zone
    PREINIT:
        time_keeper_calfields f;
        time_keeper_zone z;
        time_keeper_instant t;
    CODE:
        memset(&f, 0, sizeof f);
        f.calendar = (tk(aTHX)->calendar_find)(calendar, strlen(calendar));
        f.year = year;
        f.month = (int)month;
        f.day = (int)day;
        f.hour = 12;
        if ((tk(aTHX)->zone_parse)(aTHX_ zone, strlen(zone), &z) != TIME_KEEPER_OK)
            croak("no zone %s", zone);
        if ((tk(aTHX)->cal_from_fields)(aTHX_ &f, &z, TIME_KEEPER_GAP_FAIL, TIME_KEEPER_OVERLAP_EARLIER, &t) != TIME_KEEPER_OK)
            croak("cal_from_fields refused");
        RETVAL = (tk(aTHX)->new_sv_cal)(aTHX_ &t, &z, 0, f.calendar);
        if (!RETVAL)
            croak("new_sv_cal refused");
    OUTPUT:
        RETVAL

SV *
tomorrow_at(value, hour)
        SV *value
        int hour
    PREINIT:
        time_keeper_point p, q;
        time_keeper_parts parts;
        char err[160];
    CODE:
        if ((tk(aTHX)->from_sv_cal)(aTHX_ value, &p.inst, &p.zone, &p.locale, &p.calendar) != TIME_KEEPER_OK)
            croak("not a Time::Keeper value");
        Zero(&parts, 1, time_keeper_parts);
        parts.days = 1;
        if ((tk(aTHX)->plus)(aTHX_ &p, &parts, TIME_KEEPER_GAP_FORWARD, TIME_KEEPER_OVERLAP_EARLIER, &q, err, sizeof err)
            || (tk(aTHX)->truncate)(aTHX_ &q, TIME_KEEPER_UNIT_DAY, TIME_KEEPER_WEEK_LOCALE, &p, err, sizeof err)
            || (tk(aTHX)->with_time)(aTHX_ &p, hour, 0, 0, 0, TIME_KEEPER_GAP_FORWARD, TIME_KEEPER_OVERLAP_EARLIER, &q, err, sizeof err))
            croak("%s", err);
        RETVAL = (tk(aTHX)->new_sv_cal)(aTHX_ &q.inst, &q.zone, q.locale, q.calendar);
    OUTPUT:
        RETVAL

SV *
read_cldr(text, pattern, locale)
        SV *text
        SV *pattern
        const char *locale
    PREINIT:
        time_keeper_point q;
        char err[160];
        STRLEN tl, pl;
        const char *tx, *pt;
        int l;
    CODE:
        tx = SvPVutf8(text, tl);
        pt = SvPVutf8(pattern, pl);
        l = (tk(aTHX)->locale_find)(locale, strlen(locale));
        if ((tk(aTHX)->parse_cldr)(aTHX_ tx, tl, pt, pl, TIME_KEEPER_KIND_VALUE, NULL, l, 0, TIME_KEEPER_GAP_FORWARD,
                                   TIME_KEEPER_OVERLAP_EARLIER, &q, NULL, err, sizeof err) != TIME_KEEPER_OK) {
            RETVAL = newSVpv(err, 0);
            SvUTF8_on(RETVAL);
        }
        else
            RETVAL = (tk(aTHX)->new_sv_cal)(aTHX_ &q.inst, &q.zone, q.locale, q.calendar);
    OUTPUT:
        RETVAL

SV *
next_working_date(date)
        SV *date
    PREINIT:
        int kind, l, s, e, dow;
        int64_t d;
        char err[128];
    CODE:
        if ((tk(aTHX)->date_from_sv)(aTHX_ date, &kind, &d, &l) != TIME_KEEPER_OK || kind != TIME_KEEPER_KIND_DATE)
            croak("not a Time::Keeper::Date");
        if ((tk(aTHX)->locale_weekend)(aTHX_ l, &s, &e, err, sizeof err) != TIME_KEEPER_OK)
            croak("%s", err);
        for (;;) {
            d++;
            dow = (int)(((d % 7) + 7 + 3) % 7) + 1;
            if (s <= e ? (dow < s || dow > e) : (dow < s && dow > e))
                break;
        }
        RETVAL = (tk(aTHX)->new_date_sv)(aTHX_ TIME_KEEPER_KIND_DATE, d, l, NULL);
    OUTPUT:
        RETVAL

void
change_after(value)
        SV *value
    PREINIT:
        time_keeper_instant t, at;
        time_keeper_zone z;
        int32_t before, after;
    PPCODE:
        if ((tk(aTHX)->from_sv)(aTHX_ value, &t, &z, NULL) != TIME_KEEPER_OK)
            croak("not a Time::Keeper value");
        if ((tk(aTHX)->next_change)(aTHX_ &t, &z, &at, &before, &after) != TIME_KEEPER_OK)
            XSRETURN_EMPTY;
        EXTEND(SP, 3);
        mPUSHi(at.sec);
        mPUSHi(before);
        mPUSHi(after);
XS
close $fh;

my $c = File::Spec->catfile($dir, 'TKConsumer.c');
ExtUtils::ParseXS->new->process_file(filename => $xs, output => $c, prototypes => 0);
ok(-s $c, 'xsubpp made the C');
my $cb = ExtUtils::CBuilder->new(quiet => 1);
my $obj = eval { $cb->compile(source => $c, include_dirs => [$inc, $Config{archlibexp} . '/CORE']) };
ok($obj, 'it compiles against the installed header alone') or diag($@);
my $lib = $obj && eval { $cb->link(objects => [$obj], module_name => 'TKConsumer') };
ok($lib, 'and links, against nothing of Time::Keeper\'s') or diag($@);

SKIP: {
    skip 'not built', 6 unless $lib;
    require DynaLoader;
    my $libref = DynaLoader::dl_load_file($lib, 0) or die DynaLoader::dl_error();
    my $boot = DynaLoader::dl_find_symbol($libref, 'boot_TKConsumer') or die DynaLoader::dl_error();
    my $xsub = DynaLoader::dl_install_xsub('TKConsumer::bootstrap', $boot, $lib);
    &$xsub('TKConsumer');
    is(TKConsumer::version(), Time::Keeper::_abi_version(), 'the consumer sees the table\'s version');
    my $thu = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London', locale => 'en-GB');
    is('' . TKConsumer::tomorrow_at($thu, 15), '2026-10-16T15:00:00+01:00', 'the consumer adds a day, truncates and sets the hour through version 3');
    is('' . TKConsumer::next_working_date(Time::Keeper::Date->new(year => 2026, month => 10, day => 16, locale => 'en-GB')), '2026-10-19',
       'version 3 dates: Friday to Monday in en-GB, through date_from_sv, locale_weekend and new_date_sv');
    is('' . TKConsumer::next_working_date(Time::Keeper::Date->new(year => 2026, month => 10, day => 15, locale => 'ar-EG')), '2026-10-18',
       'and Thursday to Sunday in ar-EG');
    is(join(' ', TKConsumer::change_after($thu)), '1792890000 3600 0', 'next_change: London leaves summer time on 25 October 2026');
    is(scalar(() = TKConsumer::change_after($thu->in_zone('UTC'))), 0, 'and UTC never changes');
    is('' . TKConsumer::read_cldr('15 October 2026', 'd MMMM y', 'en'), '2026-10-15T00:00:00Z', 'and reads a CLDR pattern');
    is(TKConsumer::read_cldr('Tuesday 15 October 2026', 'EEEE d MMMM y', 'en'), "'Tuesday 15 October 2026': 2026-10-15 was a Thursday", 'with the method\'s reason when it cannot');
    is(TKConsumer::http_date(1760000000), 'Thu, 09 Oct 2025 08:53:20 GMT', 'http_date from another extension');
    my $v = TKConsumer::local_value(1760000000, 'Europe/Paris', 'de');
    isa_ok($v, 'Time::Keeper', 'a value it made');
    is($v->rfc9557, '2025-10-09T10:53:20+02:00[Europe/Paris]', 'in the zone it named');
    my $mine = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 21, zone => 'Asia/Tokyo', locale => 'ja');
    is(TKConsumer::stamp($mine, 'y年M月d日 EEEE'), $mine->format('y年M月d日 EEEE'), 'and it formats a value Perl made');
    is(TKConsumer::stamp($v, 'EEEE, d. MMMM y'), 'Donnerstag, 9. Oktober 2025', 'in its locale');
    is(TKConsumer::cal_stamp($mine, 'd MMMM y', 'hebrew'), $mine->in_calendar('hebrew')->format('d MMMM y'), 'version 2: format_cal in a calendar');
    is(join(' ', TKConsumer::cal_ymd($mine, 'hebrew')), 'hebrew 5787 2 4 13', 'cal_fields reads the calendar (5787 is a leap year)');
    my $h = TKConsumer::cal_value('hebrew', 5787, 2, 4, 'Asia/Tokyo');
    isa_ok($h, 'Time::Keeper', 'a value made from calendar fields');
    is($h->calendar . ' ' . $h->iso8601, 'hebrew 2026-10-15T12:00:00+09:00', 'in the calendar, on the right day');
}

# A consumer written against version 1: its header is the installed one cut
# back to the first version (the version 2 entries removed, the version 1),
# compiled in a directory of its own so it sees nothing newer. It must build,
# load and work against the version 2 table.
SKIP: {
    skip 'not built', 4 unless $lib;
    my $old = tempdir(CLEANUP => 1);
    open my $in, '<', "$inc/time_keeper_abi.h" or die;
    my $h = do { local $/; <$in> };
    close $in;
    $h =~ s/#define TIME_KEEPER_ABI_VERSION \d+/#define TIME_KEEPER_ABI_VERSION 1/ or die 'no version line';
    $h =~ s/\n    \/\* ---- version 2 ---- \*\/.*?(\n\} time_keeper_abi;)/$1/s or die 'no version 2 block';
    open my $out, '>', "$old/time_keeper_abi.h" or die;
    print $out $h;
    close $out;
    (my $oldxs = do { open my $f, '<', $xs or die; local $/; <$f> }) =~ s/TKConsumer/TKOld/g;
    $oldxs =~ s/\nSV \*\ncal_stamp.*/\n/s or die 'no cut';
    open my $oxs, '>', "$old/TKOld.xs" or die;
    print $oxs $oldxs;
    close $oxs;
    my $oc = "$old/TKOld.c";
    ExtUtils::ParseXS->new->process_file(filename => "$old/TKOld.xs", output => $oc, prototypes => 0);
    my $oobj = eval { $cb->compile(source => $oc, include_dirs => [$old, $Config{archlibexp} . '/CORE']) };
    ok($oobj, 'a consumer against the version 1 header compiles') or diag($@);
    my $olib = $oobj && eval { $cb->link(objects => [$oobj], module_name => 'TKOld') };
    ok($olib, 'and links') or diag($@);
    skip 'not built', 2 unless $olib;
    my $libref = DynaLoader::dl_load_file($olib, 0) or die DynaLoader::dl_error();
    my $boot = DynaLoader::dl_find_symbol($libref, 'boot_TKOld') or die DynaLoader::dl_error();
    my $xsub = DynaLoader::dl_install_xsub('TKOld::bootstrap', $boot, $olib);
    &$xsub('TKOld');
    is(TKOld::version(), Time::Keeper::_abi_version(), 'it accepts the current table (>= 1)');
    is(TKOld::stamp(Time::Keeper->new(year => 2026, month => 10, day => 15, zone => 'UTC'), 'y-MM-dd'), '2026-10-15', 'and its version 1 entries work');
}

done_testing;
