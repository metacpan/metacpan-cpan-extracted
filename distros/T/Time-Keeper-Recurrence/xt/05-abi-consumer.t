#!perl
use 5.010;
use strict;
use warnings;
use Config;
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

# Author test: a separate extension that knows only perl's headers and the
# two installed headers, time_keeper_recurrence_abi.h and the
# time_keeper_abi.h it includes, built here and loaded beside the module. It
# resolves the table as the header says and calls cron_next, rrule_next and
# compile, next, previous and release from XS. Then 100,000 compile and
# release pairs, and as many cron_next calls, must leave the process the
# size it was.

BEGIN {
    eval { require ExtUtils::CBuilder; require ExtUtils::ParseXS; 1 }
        or plan skip_all => 'ExtUtils::CBuilder and ExtUtils::ParseXS are needed';
    ExtUtils::CBuilder->new(quiet => 1)->have_compiler or plan skip_all => 'no C compiler';
}
use Time::Keeper;
use Time::Keeper::Recurrence;

sub installed {
    my ($file, @dir) = @_;
    my ($d) = grep { -f "$_/$file" } map { File::Spec->catdir($_, @dir, 'Install') } grep { !ref } @INC;
    return $d;
}
my $inc = installed('time_keeper_recurrence_abi.h', qw(Time Keeper Recurrence));
my $tk_inc = installed('time_keeper_abi.h', qw(Time Keeper));
ok($inc, 'the header is installed where ExtUtils::Depends looks') or BAIL_OUT('no header');
ok($tk_inc, 'and the Time::Keeper header it includes') or BAIL_OUT('no core header');

my $dir = tempdir(CLEANUP => 1);
my $xs = File::Spec->catfile($dir, 'TKRConsumer.xs');
open my $fh, '>', $xs or die "$xs: $!";
print $fh <<'XS';
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "time_keeper_recurrence_abi.h"

static const time_keeper_recurrence_abi *TKR = NULL;

static const time_keeper_recurrence_abi *
tkr(pTHX)
{
    if (!TKR) {
        SV *sv = eval_pv("require Time::Keeper::Recurrence; Time::Keeper::Recurrence::_abi_ptr()", 0);
        SV *err = get_sv("@", 0);
        if (sv && SvOK(sv) && (!err || !SvTRUE(err))) {
            const time_keeper_recurrence_abi *t = INT2PTR(const time_keeper_recurrence_abi *, SvUV(sv));
            if (TIME_KEEPER_RECURRENCE_ABI_OK(t))
                TKR = t;
        }
        if (!TKR)
            croak("TKRConsumer: no Time::Keeper::Recurrence table");
    }
    return TKR;
}

MODULE = TKRConsumer    PACKAGE = TKRConsumer

PROTOTYPES: DISABLE

int
version()
    CODE:
        RETVAL = tkr(aTHX)->abi_version;
    OUTPUT:
        RETVAL

void
cron_next(expr, zone, from)
        SV *expr
        SV *zone
        NV from
    PREINIT:
        STRLEN el, zl;
        const char *e, *z;
        double out = 0;
        char err[200];
        int rc;
    PPCODE:
        e = SvPV(expr, el);
        z = SvPV(zone, zl);
        rc = (tkr(aTHX)->cron_next)(aTHX_ e, el, z, zl, from, &out, err, sizeof err);
        EXTEND(SP, 2);
        mPUSHi(rc);
        if (rc == 0) mPUSHn(out); else mPUSHp(err, strlen(err));

void
rrule_next(rule, zone, start, from)
        SV *rule
        SV *zone
        NV start
        NV from
    PREINIT:
        STRLEN rl, zl;
        const char *r, *z;
        double out = 0;
        char err[200];
        int rc;
    PPCODE:
        r = SvPV(rule, rl);
        z = SvPV(zone, zl);
        rc = (tkr(aTHX)->rrule_next)(aTHX_ r, rl, z, zl, start, from, &out, err, sizeof err);
        EXTEND(SP, 2);
        mPUSHi(rc);
        if (rc == 0) mPUSHn(out); else mPUSHp(err, strlen(err));

void
walk(kind, spec, from, n)
        int kind
        SV *spec
        IV from
        int n
    PREINIT:
        STRLEN sl;
        const char *s;
        time_keeper_recurrence *h = NULL;
        time_keeper_instant t, u;
        char err[200];
        int i, rc;
    PPCODE:
        s = SvPV(spec, sl);
        rc = (tkr(aTHX)->compile)(aTHX_ kind, s, sl, NULL, NULL, -1, -1, &h, err, sizeof err);
        if (rc != 0)
            croak("compile: %d %s", rc, err);
        t.sec = from;
        t.nsec = 0;
        for (i = 0; i < n; i++) {
            if ((tkr(aTHX)->next)(aTHX_ h, &t, &u) != 0)
                break;
            mXPUSHi((IV)u.sec);
            t = u;
        }
        if ((tkr(aTHX)->previous)(aTHX_ h, &t, &u) == 0)
            mXPUSHi((IV)u.sec);
        (tkr(aTHX)->release)(h);

IV
churn(n)
        IV n
    PREINIT:
        time_keeper_recurrence *h;
        time_keeper_instant t, u;
        char err[200];
        double d;
        IV i, ok = 0;
    CODE:
        for (i = 0; i < n; i++) {
            if ((tkr(aTHX)->compile)(aTHX_ 2, "*/5 * * * *", 11, NULL, NULL, -1, -1, &h, err, sizeof err) != 0)
                croak("compile: %s", err);
            t.sec = 1000000000 + i;
            t.nsec = 0;
            if ((tkr(aTHX)->next)(aTHX_ h, &t, &u) == 0)
                ok++;
            (tkr(aTHX)->release)(h);
            if ((tkr(aTHX)->cron_next)(aTHX_ "0 3 * * *", 9, "America/New_York", 16, 1000000000.0 + i, &d, err, sizeof err) == 0)
                ok++;
        }
        RETVAL = ok;
    OUTPUT:
        RETVAL
XS
close $fh;

my $c = File::Spec->catfile($dir, 'TKRConsumer.c');
ExtUtils::ParseXS->new->process_file(filename => $xs, output => $c, prototypes => 0);
ok(-s $c, 'xsubpp made the C');
my $cb = ExtUtils::CBuilder->new(quiet => 1);
my $obj = eval { $cb->compile(source => $c, include_dirs => [$inc, $tk_inc, $Config{archlibexp} . '/CORE']) };
ok($obj, 'it compiles against the installed headers alone') or diag($@);
my $lib = $obj && eval { $cb->link(objects => [$obj], module_name => 'TKRConsumer') };
ok($lib, 'and links, against nothing of the module\'s') or diag($@);

SKIP: {
    skip 'not built', 9 unless $lib;
    require DynaLoader;
    my $libref = DynaLoader::dl_load_file($lib, 0) or die DynaLoader::dl_error();
    my $boot = DynaLoader::dl_find_symbol($libref, 'boot_TKRConsumer') or die DynaLoader::dl_error();
    my $xsub = DynaLoader::dl_install_xsub('TKRConsumer::bootstrap', $boot, $lib);
    &$xsub('TKRConsumer');
    is(TKRConsumer::version(), Time::Keeper::Recurrence::_abi_version(), 'the consumer sees the table\'s version');

    my $from = Time::Keeper->parse('2026-03-07T12:00:00Z')->epoch;
    my $want = Time::Keeper::Recurrence->cron('30 2 * * *', zone => 'America/New_York')->next(Time::Keeper->parse('2026-03-07T12:00:00Z'))->epoch;
    is_deeply([TKRConsumer::cron_next('30 2 * * *', 'America/New_York', $from)], [0, $want], 'cron_next across the March change, as the Perl next');
    is_deeply([TKRConsumer::cron_next('0 9 * * 1-5', 'local', $from)], [0, Time::Keeper::Recurrence->cron('0 9 * * 1-5', zone => 'local')->next(Time::Keeper->from_epoch($from))->epoch],
        'in the zone Punk::Queue calls local');
    my @bad = TKRConsumer::cron_next('0 0 * * * *', 'UTC', $from);
    is($bad[0], -1, 'a bad expression is BAD');
    like($bad[1], qr/cron expression has more than 5 fields - second and year fields are not supported/, 'with Punk::Queue\'s words');
    my $start = Time::Keeper->new(year => 2026, month => 1, day => 31, hour => 9, zone => 'Europe/London');
    is_deeply([TKRConsumer::rrule_next('FREQ=MONTHLY;BYMONTHDAY=-1', 'Europe/London', $start->epoch, $start->epoch)],
        [0, Time::Keeper->new(year => 2026, month => 2, day => 28, hour => 9, zone => 'Europe/London')->epoch], 'rrule_next: the last day of February');
    my @w = TKRConsumer::walk(1 + 2, "DTSTART:20260101T090000Z\r\nRRULE:FREQ=DAILY;COUNT=4\r\nEXDATE:20260102T090000Z\r\n", 0, 10);
    my $day = 86400;
    my $d0 = Time::Keeper->parse('2026-01-01T09:00:00Z')->epoch;
    is_deeply(\@w, [$d0, $d0 + 2 * $day, $d0 + 3 * $day, $d0 + 2 * $day], 'compile, next to the end, previous, release: an iCalendar set from another extension');

    my $rss = sub { my $k = `ps -o rss= -p $$`; $k =~ s/\s+//g; $k };
    TKRConsumer::churn(20_000);
    my $before = $rss->();
    is(TKRConsumer::churn(100_000), 200_000, '100,000 compile and release pairs and 100,000 cron_next calls');
    my $after = $rss->();
    cmp_ok($after - $before, '<', 4096, "and the process stays its size ($before KB to $after KB)");
}

done_testing;
