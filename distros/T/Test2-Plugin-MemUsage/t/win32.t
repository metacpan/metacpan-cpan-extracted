use strict;
use warnings;
use Test2::V0;

# Detect at compile time whether the real Win32::Process::Memory is
# installed. If it is, we use it for the real-system subtests; if it
# is not, we install a lightweight fake into %INC so the adapter
# tests below can still exercise our byte-to-kB conversion logic
# without requiring a Windows host or the real CPAN module.
our $HAS_REAL_WPM;
BEGIN {
    $HAS_REAL_WPM = eval { require Win32::Process::Memory; 1 } ? 1 : 0;
    $INC{'Win32/Process/Memory.pm'} ||= __FILE__;
}

# Default fake; only installed when the real module is absent.
unless ($HAS_REAL_WPM) {
    no warnings 'redefine', 'once';
    *Win32::Process::Memory::GetProcessMemoryInfo = sub {
        return {
            WorkingSetSize     => 1048576,
            PeakWorkingSetSize => 2097152,
            PagefileUsage      => 3145728,
        };
    };
}

use Test2::Plugin::MemUsage;

# --- Real-system subtests -------------------------------------------------

# Compatibility: verify the real Win32::Process::Memory returns the hash
# shape our mocks assume. Skip when we are not on Windows or the module
# is not installed; fail when both prerequisites are met but the data
# does not match expectations.
subtest real_module_matches_mock_shape => sub {
    skip_all "Win32::Process::Memory not installed" unless $HAS_REAL_WPM;
    skip_all "not on MSWin32 (\$^O = $^O)"          unless $^O eq 'MSWin32';
    skip_all "Win32::Process::Memory loaded but GetProcessMemoryInfo not defined"
        unless defined &Win32::Process::Memory::GetProcessMemoryInfo;

    my $info;
    ok(lives { $info = Win32::Process::Memory::GetProcessMemoryInfo($$) },
        "GetProcessMemoryInfo did not throw")
        or do { diag $@; return };

    is(ref($info), 'HASH', "returns a hashref") or return;
    for my $k (qw/WorkingSetSize PeakWorkingSetSize PagefileUsage/) {
        ok(exists $info->{$k}, "$k key present") or next;
        like($info->{$k}, qr/^\d+$/, "$k value is numeric");
    }
};

# Integration: drive _collect_win32 end to end against the real module.
subtest real_collect_win32_meaningful => sub {
    skip_all "Win32::Process::Memory not installed" unless $HAS_REAL_WPM;
    skip_all "not on MSWin32 (\$^O = $^O)"          unless $^O eq 'MSWin32';
    skip_all "Win32::Process::Memory loaded but GetProcessMemoryInfo not defined"
        unless defined &Win32::Process::Memory::GetProcessMemoryInfo;

    my %mem = Test2::Plugin::MemUsage::_collect_win32();
    ok(%mem, "got mem hash") or return;
    for my $k (qw/rss peak size/) {
        my ($v, $u) = @{$mem{$k}};
        like($v, qr/^\d+$/,         "$k numeric");
        ok($v + 0 > 0,              "$k > 0");
        ok($v + 0 < 100_000_000,    "$k < 100 GB sanity");
        is($u, 'kB',                "$k units kB");
    }
};

# --- Mocked adapter subtests ----------------------------------------------

subtest happy_path => sub {
    no warnings 'redefine';
    local *Win32::Process::Memory::GetProcessMemoryInfo = sub {
        return {
            WorkingSetSize     => 1048576,
            PeakWorkingSetSize => 2097152,
            PagefileUsage      => 3145728,
        };
    };
    my %mem = Test2::Plugin::MemUsage::_collect_win32();
    is($mem{rss},  [1024, 'kB'], "rss converted from bytes");
    is($mem{peak}, [2048, 'kB'], "peak converted from bytes");
    is($mem{size}, [3072, 'kB'], "size converted from bytes");
};

subtest no_info_returned => sub {
    no warnings 'redefine';
    local *Win32::Process::Memory::GetProcessMemoryInfo = sub { undef };
    my @out = Test2::Plugin::MemUsage::_collect_win32();
    is(\@out, [], "GetProcessMemoryInfo undef -> empty");
};

subtest die_in_call => sub {
    no warnings 'redefine';
    local *Win32::Process::Memory::GetProcessMemoryInfo = sub { die "kaboom" };
    my @out = Test2::Plugin::MemUsage::_collect_win32();
    is(\@out, [], "exception inside call -> empty");
};

subtest partial_info => sub {
    no warnings 'redefine';
    local *Win32::Process::Memory::GetProcessMemoryInfo = sub {
        return {WorkingSetSize => 4096};    # only rss
    };
    my %mem = Test2::Plugin::MemUsage::_collect_win32();
    is($mem{rss},  [4, 'kB'],  "rss converted");
    is($mem{peak}, ['NA', ''], "peak NA when missing");
    is($mem{size}, ['NA', ''], "size NA when missing");
};

done_testing;
