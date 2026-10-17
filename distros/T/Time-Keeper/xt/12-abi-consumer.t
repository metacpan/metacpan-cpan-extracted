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
    is(TKConsumer::http_date(1760000000), 'Thu, 09 Oct 2025 08:53:20 GMT', 'http_date from another extension');
    my $v = TKConsumer::local_value(1760000000, 'Europe/Paris', 'de');
    isa_ok($v, 'Time::Keeper', 'a value it made');
    is($v->rfc9557, '2025-10-09T10:53:20+02:00[Europe/Paris]', 'in the zone it named');
    my $mine = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 21, zone => 'Asia/Tokyo', locale => 'ja');
    is(TKConsumer::stamp($mine, 'y年M月d日 EEEE'), $mine->format('y年M月d日 EEEE'), 'and it formats a value Perl made');
    is(TKConsumer::stamp($v, 'EEEE, d. MMMM y'), 'Donnerstag, 9. Oktober 2025', 'in its locale');
}

done_testing;
