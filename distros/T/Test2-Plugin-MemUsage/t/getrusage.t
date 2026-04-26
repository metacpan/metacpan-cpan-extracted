use strict;
use warnings;
use Test2::V0;

# Detect at compile time whether the real BSD::Resource is installed.
# When it is, we use it for the real-system subtests; when it is not,
# we install a fake into %INC so the adapter subtests below can still
# exercise our unit-conversion logic without requiring the real module.
our $HAS_REAL_BR;
BEGIN {
    $HAS_REAL_BR = eval { require BSD::Resource; 1 } ? 1 : 0;
    $INC{'BSD/Resource.pm'} ||= __FILE__;
}

unless ($HAS_REAL_BR) {
    no warnings 'redefine', 'once';
    *BSD::Resource::RUSAGE_SELF = sub () { 0 };
    *BSD::Resource::getrusage   = sub { (0, 0, 8192) };
}

use Test2::Plugin::MemUsage;

# --- Real-system subtests -------------------------------------------------

# Compatibility: call real BSD::Resource::getrusage and verify the
# field at index 2 (ru_maxrss) is numeric. Skip when the module is not
# installed; fail when it is installed but its return shape has
# drifted from what _maxrss_kb assumes.
subtest real_getrusage_matches_mock_shape => sub {
    skip_all "BSD::Resource not installed" unless $HAS_REAL_BR;

    my @ru;
    ok(lives { @ru = BSD::Resource::getrusage(BSD::Resource::RUSAGE_SELF()) },
        "getrusage did not throw")
        or diag $@;

    ok(scalar(@ru) >= 3, "getrusage returns at least 3 fields");
    like($ru[2], qr/^-?\d+(?:\.\d+)?$/, "ru_maxrss is numeric");
    ok($ru[2] >= 0, "ru_maxrss is non-negative");
};

# Integration: drive _maxrss_kb against real BSD::Resource. Skip when
# the module is missing; fail when present but value is wrong.
subtest real_maxrss_kb_meaningful => sub {
    skip_all "BSD::Resource not installed" unless $HAS_REAL_BR;

    my $kb = Test2::Plugin::MemUsage::_maxrss_kb();
    ok(defined $kb,         "got a value");
    like($kb, qr/^\d+$/,    "value is numeric");
    ok($kb > 0,             "value > 0");
    ok($kb < 100_000_000,   "value < 100 GB sanity");
};

# --- Mocked adapter subtests ----------------------------------------------

subtest linux_uses_kb_directly => sub {
    no warnings 'redefine';
    local *BSD::Resource::getrusage = sub { (0, 0, 8192) };
    local $^O = 'linux';
    is(Test2::Plugin::MemUsage::_maxrss_kb(), 8192, "ru_maxrss returned as kB on Linux");
};

subtest darwin_converts_bytes => sub {
    no warnings 'redefine';
    local *BSD::Resource::getrusage = sub { (0, 0, 8192) };
    local $^O = 'darwin';
    is(Test2::Plugin::MemUsage::_maxrss_kb(), 8, "ru_maxrss / 1024 on darwin");
};

subtest zero_maxrss_returns_undef => sub {
    no warnings 'redefine';
    local *BSD::Resource::getrusage = sub { (0, 0, 0) };
    is(Test2::Plugin::MemUsage::_maxrss_kb(), undef, "0 maxrss -> undef");
};

subtest empty_getrusage_returns_undef => sub {
    no warnings 'redefine';
    local *BSD::Resource::getrusage = sub { () };
    is(Test2::Plugin::MemUsage::_maxrss_kb(), undef, "empty list from getrusage -> undef");
};

subtest collect_mem_last_resort => sub {
    no warnings 'redefine';
    local *BSD::Resource::getrusage                   = sub { (0, 0, 8192) };
    local *Test2::Plugin::MemUsage::_collector_for_os = sub { undef };
    local $^O                                         = 'linux';

    my %mem = Test2::Plugin::MemUsage::collect_mem();
    is($mem{peak}, [8192, 'kB'], "fallback fills peak");
    is($mem{rss},  ['NA', ''],   "rss NA");
    is($mem{size}, ['NA', ''],   "size NA");
};

subtest augment_peak_uses_real_helper => sub {
    no warnings 'redefine';
    local *BSD::Resource::getrusage = sub { (0, 0, 8192) };
    local $^O                       = 'linux';

    my %in = (
        rss  => ['100', 'kB'],
        size => ['200', 'kB'],
        peak => ['NA',  ''],
    );
    my %out = Test2::Plugin::MemUsage::_augment_peak(%in);
    is($out{peak}, [8192, 'kB'], "augment_peak filled peak from getrusage chain");
};

done_testing;
