use strict;
use warnings;
use Test2::V0;
use File::Temp qw/tempfile/;

use Test2::Plugin::MemUsage;

subtest happy_path => sub {
    no warnings 'redefine';
    local *Test2::Plugin::MemUsage::proc_file = sub { 't/procfile' };
    my %mem = Test2::Plugin::MemUsage::_collect_proc();
    is($mem{peak}, ['25176', 'kB'], "peak");
    is($mem{size}, ['25176', 'kB'], "size");
    is($mem{rss},  ['16604', 'kB'], "rss");
};

subtest missing_procfile => sub {
    no warnings 'redefine';
    local *Test2::Plugin::MemUsage::proc_file = sub { '/this/path/should/not/exist/please' };
    my @out = Test2::Plugin::MemUsage::_collect_proc();
    is(\@out, [], "missing procfile -> empty");
};

subtest empty_procfile => sub {
    my ($fh, $path) = tempfile(UNLINK => 1);
    close $fh;
    no warnings 'redefine';
    local *Test2::Plugin::MemUsage::proc_file = sub { $path };
    my @out = Test2::Plugin::MemUsage::_collect_proc();
    is(\@out, [], "empty file -> empty");
};

subtest no_vm_lines => sub {
    my ($fh, $path) = tempfile(UNLINK => 1);
    print $fh "Pid:    123\nName:   foo\nState:  R (running)\n";
    close $fh;
    no warnings 'redefine';
    local *Test2::Plugin::MemUsage::proc_file = sub { $path };
    my %mem = Test2::Plugin::MemUsage::_collect_proc();
    is($mem{peak}, ['NA', ''], "peak NA");
    is($mem{size}, ['NA', ''], "size NA");
    is($mem{rss},  ['NA', ''], "rss NA");
};

subtest tab_separator => sub {
    my ($fh, $path) = tempfile(UNLINK => 1);
    print $fh "VmPeak:\t  111 kB\nVmSize:\t  222 kB\nVmRSS:\t   333 kB\n";
    close $fh;
    no warnings 'redefine';
    local *Test2::Plugin::MemUsage::proc_file = sub { $path };
    my %mem = Test2::Plugin::MemUsage::_collect_proc();
    is($mem{peak}, ['111', 'kB'], "peak parsed with tab separator");
    is($mem{size}, ['222', 'kB'], "size parsed with tab separator");
    is($mem{rss},  ['333', 'kB'], "rss parsed with tab separator");
};

subtest partial_vm_lines => sub {
    my ($fh, $path) = tempfile(UNLINK => 1);
    print $fh "VmRSS:    1234 kB\n";  # only rss
    close $fh;
    no warnings 'redefine';
    local *Test2::Plugin::MemUsage::proc_file = sub { $path };
    my %mem = Test2::Plugin::MemUsage::_collect_proc();
    is($mem{rss},  ['1234', 'kB'], "rss parsed");
    is($mem{peak}, ['NA', ''],     "peak NA when missing");
    is($mem{size}, ['NA', ''],     "size NA when missing");
};

# Real-system compatibility: verify the host's /proc/PID/status actually
# matches the shape our mocks assume. Skip cleanly if there is no
# procfile; fail loudly if the procfile exists but the format has
# drifted away from what our regex expects.
subtest real_procfile_matches_mock_shape => sub {
    # /proc/PID/status is Linux-format text only on Linux/Cygwin/gnukfreebsd.
    # On Solaris it is a binary pstatus_t struct; on *BSD /proc may not be
    # mounted at all. Mirror the dispatcher in _collector_for_os.
    skip_all "procfile parser is linux-only (\$^O = $^O)"
        unless $^O eq 'linux' || $^O eq 'cygwin' || $^O eq 'gnukfreebsd';

    my $f = Test2::Plugin::MemUsage::proc_file();
    skip_all "no procfile at $f" unless -e $f;

    open my $fh, '<', $f or skip_all "cannot open $f: $!";
    local $/;
    my $stats = <$fh>;
    close $fh;

    ok(defined $stats && length $stats, "procfile is non-empty");
    like($stats, qr/VmPeak:\s+\d+\s+\S+/, "VmPeak matches our regex");
    like($stats, qr/VmSize:\s+\d+\s+\S+/, "VmSize matches our regex");
    like($stats, qr/VmRSS:\s+\d+\s+\S+/,  "VmRSS matches our regex");
};

# Real-system integration: actually run the collector against the
# host kernel. Skip if /proc is absent; fail if the values come back
# non-numeric, missing units, or wildly out of range.
subtest real_collect_proc_meaningful => sub {
    skip_all "procfile parser is linux-only (\$^O = $^O)"
        unless $^O eq 'linux' || $^O eq 'cygwin' || $^O eq 'gnukfreebsd';

    my $f = Test2::Plugin::MemUsage::proc_file();
    skip_all "no procfile at $f" unless -e $f;

    my %mem = Test2::Plugin::MemUsage::_collect_proc();
    ok(%mem, "got mem hash");

    for my $k (qw/rss size peak/) {
        my ($v, $u) = @{$mem{$k}};
        like($v, qr/^\d+$/,    "$k value is numeric");
        ok($v + 0 > 0,         "$k value is positive");
        ok($v + 0 < 100_000_000, "$k value < 100 GB sanity");
        ok(length $u,          "$k has a unit");
    }
};

done_testing;
