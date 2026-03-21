#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin;
use lib map { "$FindBin::Bin/$_" } qw{ ./lib ../lib };

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Test::TMF qw( tmf_test_code );

my $test_code;

note "--- :trace import tag ---";

$test_code = <<'EOS';
use Test::MockFile qw< :trace >;
is $Test::MockFile::STRICT_MODE_STATUS, Test::MockFile::STRICT_MODE_ENABLED, 'strict mode still enabled with :trace';
ok Test::MockFile::is_strict_mode(), "is_strict_mode is true";

# Trace should log the access before strict mode dies
my $err;
eval { -e '/no/such/trace/file'; 1 } or $err = $@;
like $err, qr/strict mode/, "strict mode still dies on unmocked access";
EOS

tmf_test_code(
    name      => q[use Test::MockFile qw< :trace > enables trace with strict],
    exit      => 0,
    test_code => $test_code,
    test      => sub {
        my ($out) = @_;
        like $out->{output}, qr/\[trace\]\s+stat\b.*\/no\/such\/trace\/file/, "trace output includes stat access";
    },
    debug => 0,
);

note "--- :trace with :nostrict ---";

$test_code = <<'EOS';
use Test::MockFile qw< :trace :nostrict >;
is $Test::MockFile::STRICT_MODE_STATUS, Test::MockFile::STRICT_MODE_DISABLED, 'strict mode disabled with :nostrict';
ok !Test::MockFile::is_strict_mode(), "is_strict_mode is false";

# Access an unmocked file - should trace but not die
my $result = -e '/no/such/trace/file2';
ok !$result, "-e returns false for non-existent file";
EOS

tmf_test_code(
    name      => q[use Test::MockFile qw< :trace :nostrict >],
    exit      => 0,
    test_code => $test_code,
    test      => sub {
        my ($out) = @_;
        like $out->{output}, qr/\[trace\]\s+stat\b.*\/no\/such\/trace\/file2/, "trace output for unmocked -e access";
    },
    debug => 0,
);

note "--- trace without colon ---";

$test_code = <<'EOS';
use Test::MockFile qw< trace nostrict >;
ok !Test::MockFile::is_strict_mode(), "nostrict works";

-e '/no/such/trace/file3';
EOS

tmf_test_code(
    name      => q[use Test::MockFile qw< trace nostrict > also works],
    exit      => 0,
    test_code => $test_code,
    test      => sub {
        my ($out) = @_;
        like $out->{output}, qr/\[trace\]\s+stat\b.*\/no\/such\/trace\/file3/, "trace output works without colon prefix";
    },
    debug => 0,
);

note "--- :nostrict alias ---";

$test_code = <<'EOS';
use Test::MockFile qw< :nostrict >;
is $Test::MockFile::STRICT_MODE_STATUS, Test::MockFile::STRICT_MODE_DISABLED, ':nostrict disables strict mode';
ok !Test::MockFile::is_strict_mode(), "is_strict_mode is false";
EOS

tmf_test_code(
    name      => q[use Test::MockFile qw< :nostrict > alias works],
    exit      => 0,
    test_code => $test_code,
    debug     => 0,
);

note "--- trace includes caller location ---";

$test_code = <<'EOS';
use Test::MockFile qw< :trace :nostrict >;

-e '/no/such/trace/loc_test';
ok 1, "trace logged to STDERR";
EOS

tmf_test_code(
    name      => q[trace output includes caller location],
    exit      => 0,
    test_code => $test_code,
    test      => sub {
        my ($out) = @_;
        like $out->{output}, qr/\[trace\].*at\s+\S+\s+line\s+\d+/, "trace output includes 'at FILE line N'";
    },
    debug => 0,
);

note "--- trace does not fire for mocked files ---";

$test_code = <<'EOS';
use Test::MockFile qw< :trace >;

my $mock = Test::MockFile->file('/trace/mocked/file', 'content');
ok -e '/trace/mocked/file', "mocked file exists";
EOS

tmf_test_code(
    name      => q[trace does not fire for mocked files],
    exit      => 0,
    test_code => $test_code,
    test      => sub {
        my ($out) = @_;
        unlike $out->{output}, qr/\[trace\].*\/trace\/mocked\/file/, "no trace output for mocked file access";
    },
    debug => 0,
);

note "--- trace fires for open on unmocked files ---";

$test_code = <<'EOS';
use Test::MockFile qw< :trace :nostrict >;

open(my $fh, '<', '/no/such/trace/openfile');
ok 1, "open traced to STDERR";
EOS

tmf_test_code(
    name      => q[trace fires for open on unmocked files],
    exit      => 0,
    test_code => $test_code,
    test      => sub {
        my ($out) = @_;
        like $out->{output}, qr/\[trace\]\s+open\b.*\/no\/such\/trace\/openfile/, "trace output for unmocked open";
    },
    debug => 0,
);

done_testing();
