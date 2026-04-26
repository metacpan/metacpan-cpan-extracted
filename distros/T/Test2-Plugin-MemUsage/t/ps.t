use strict;
use warnings;
use Test2::V0;

BEGIN {
    if ($^O eq 'MSWin32') {
        plan skip_all => "ps test requires a unix shell";
    }

    my $probe = qx{echo hello 2>/dev/null};
    unless (defined $probe && $probe =~ /hello/) {
        plan skip_all => "shell echo unavailable";
    }
}

use Test2::Plugin::MemUsage;

subtest happy_path => sub {
    no warnings 'redefine';
    local *Test2::Plugin::MemUsage::ps_command = sub { q{echo '  1234  5678'} };
    my %mem = Test2::Plugin::MemUsage::_collect_ps();
    is($mem{rss},  ['1234', 'kB'], "rss");
    is($mem{size}, ['5678', 'kB'], "size");
    is($mem{peak}, ['NA', ''],     "peak NA (ps does not surface)");
};

subtest empty_output => sub {
    no warnings 'redefine';
    local *Test2::Plugin::MemUsage::ps_command = sub { 'true' };
    my @out = Test2::Plugin::MemUsage::_collect_ps();
    is(\@out, [], "empty output -> empty");
};

subtest unparseable_output => sub {
    no warnings 'redefine';
    local *Test2::Plugin::MemUsage::ps_command = sub { q{echo 'definitely not numbers'} };
    my @out = Test2::Plugin::MemUsage::_collect_ps();
    is(\@out, [], "unparseable -> empty");
};

# Real-system compatibility: invoke the actual ps_command and verify
# its output shape matches what our mocks/parser assume. Skip cleanly
# when ps is missing (exit 127 / $? == -1); fail loudly when ps is
# present but exits non-zero or returns output we cannot parse.
subtest real_ps_matches_mock_shape => sub {
    my $cmd = Test2::Plugin::MemUsage::ps_command();
    my $out = qx{$cmd 2>/dev/null};
    my $raw = $?;

    skip_all "ps not executable: $!"   if $raw == -1;
    skip_all "ps not in PATH (exit 127)" if ($raw >> 8) == 127;

    is($raw >> 8, 0, "ps exits 0");
    like($out, qr/^\s*\d+\s+\d+\s*$/m,
        "ps output matches our parser regex");
};

# Real-system integration: drive _collect_ps end to end against the
# host's ps and assert the returned values are numeric, positive,
# correctly unitted, and within a sane range. Same skip rules as
# above; if ps is present and the data is wrong, fail.
subtest real_collect_ps_meaningful => sub {
    my $cmd   = Test2::Plugin::MemUsage::ps_command();
    my $probe = qx{$cmd 2>/dev/null};
    my $raw   = $?;

    skip_all "ps not executable: $!"   if $raw == -1;
    skip_all "ps not in PATH (exit 127)" if ($raw >> 8) == 127;
    skip_all "ps output not parseable" unless $probe =~ /^\s*\d+\s+\d+\s*$/m;

    my %mem = Test2::Plugin::MemUsage::_collect_ps();
    ok(%mem, "got mem hash");
    for my $k (qw/rss size/) {
        my ($v, $u) = @{$mem{$k}};
        like($v, qr/^\d+$/,         "$k numeric");
        ok($v + 0 > 0,              "$k > 0");
        ok($v + 0 < 100_000_000,    "$k < 100 GB sanity");
        is($u, 'kB',                "$k units kB");
    }
    is($mem{peak}, ['NA', ''], "peak NA (ps does not surface peak RSS)");
};

done_testing;
