use strict;
use warnings;
use Test2::V0;
use Test2::API qw/intercept context/;

use Test2::Plugin::MemUsage;

subtest collector_for_os => sub {
    my $proc = \&Test2::Plugin::MemUsage::_collect_proc;
    my $ps   = \&Test2::Plugin::MemUsage::_collect_ps;
    my $win  = \&Test2::Plugin::MemUsage::_collect_win32;

    is(Test2::Plugin::MemUsage::_collector_for_os('linux'),       $proc, "linux -> proc");
    is(Test2::Plugin::MemUsage::_collector_for_os('cygwin'),      $proc, "cygwin -> proc");
    is(Test2::Plugin::MemUsage::_collector_for_os('gnukfreebsd'), $proc, "gnukfreebsd -> proc");
    is(Test2::Plugin::MemUsage::_collector_for_os('darwin'),      $ps,   "darwin -> ps");
    is(Test2::Plugin::MemUsage::_collector_for_os('freebsd'),     $ps,   "freebsd -> ps");
    is(Test2::Plugin::MemUsage::_collector_for_os('openbsd'),     $ps,   "openbsd -> ps");
    is(Test2::Plugin::MemUsage::_collector_for_os('netbsd'),      $ps,   "netbsd -> ps");
    is(Test2::Plugin::MemUsage::_collector_for_os('solaris'),     $ps,   "solaris -> ps");
    is(Test2::Plugin::MemUsage::_collector_for_os('aix'),         $ps,   "aix -> ps");
    is(Test2::Plugin::MemUsage::_collector_for_os('hpux'),        $ps,   "hpux -> ps");
    is(Test2::Plugin::MemUsage::_collector_for_os('MSWin32'),     $win,  "MSWin32 -> win32");
    is(Test2::Plugin::MemUsage::_collector_for_os('haiku'),       undef, "unknown OS -> undef");
    is(Test2::Plugin::MemUsage::_collector_for_os('riscos'),      undef, "another unknown OS -> undef");
};

subtest augment_peak_fills_NA => sub {
    no warnings 'redefine';
    local *Test2::Plugin::MemUsage::_maxrss_kb = sub { 9999 };

    my %in = (
        rss  => ['100', 'kB'],
        size => ['200', 'kB'],
        peak => ['NA',  ''],
    );
    my %out = Test2::Plugin::MemUsage::_augment_peak(%in);
    is($out{peak}, [9999, 'kB'],  "peak filled from getrusage");
    is($out{rss},  ['100', 'kB'], "rss preserved");
    is($out{size}, ['200', 'kB'], "size preserved");
};

subtest augment_peak_keeps_existing => sub {
    no warnings 'redefine';
    local *Test2::Plugin::MemUsage::_maxrss_kb = sub { 9999 };

    my %in = (
        rss  => ['100', 'kB'],
        size => ['200', 'kB'],
        peak => ['500', 'kB'],
    );
    my %out = Test2::Plugin::MemUsage::_augment_peak(%in);
    is($out{peak}, ['500', 'kB'], "existing peak preserved when not NA");
};

subtest augment_peak_no_fallback => sub {
    no warnings 'redefine';
    local *Test2::Plugin::MemUsage::_maxrss_kb = sub { undef };

    my %in = (
        rss  => ['100', 'kB'],
        size => ['200', 'kB'],
        peak => ['NA',  ''],
    );
    my %out = Test2::Plugin::MemUsage::_augment_peak(%in);
    is($out{peak}, ['NA', ''], "peak stays NA when fallback returns undef");
};

subtest collect_mem_no_collector_no_fallback => sub {
    no warnings 'redefine';
    local *Test2::Plugin::MemUsage::_collector_for_os = sub { undef };
    local *Test2::Plugin::MemUsage::_maxrss_kb        = sub { undef };
    my @out = Test2::Plugin::MemUsage::collect_mem();
    is(\@out, [], "no collector + no fallback -> empty");
};

subtest send_mem_event_skips_when_empty => sub {
    no warnings 'redefine';
    local *Test2::Plugin::MemUsage::collect_mem = sub { () };

    my $events = intercept {
        my $ctx = context();
        Test2::Plugin::MemUsage::send_mem_event($ctx);
        $ctx->release;
    };
    is(scalar(@$events), 0, "no event when collect_mem returns empty");
};

subtest send_mem_event_skips_when_all_NA => sub {
    no warnings 'redefine';
    local *Test2::Plugin::MemUsage::collect_mem = sub {
        (peak => ['NA', ''], size => ['NA', ''], rss => ['NA', ''])
    };

    my $events = intercept {
        my $ctx = context();
        Test2::Plugin::MemUsage::send_mem_event($ctx);
        $ctx->release;
    };
    is(scalar(@$events), 0, "no event when all values are NA");
};

done_testing;
