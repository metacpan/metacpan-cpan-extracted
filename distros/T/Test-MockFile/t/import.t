#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin;
use lib map { "$FindBin::Bin/$_" } qw{ ./lib ../lib };

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Test::TMF qw ( tmf_test_code );

my $test_code;

note "Happy Imports";

$test_code = <<'EOS';
use Test::MockFile ();
is $Test::MockFile::STRICT_MODE_STATUS, Test::MockFile::STRICT_MODE_DEFAULT, 'STRICT_MODE_DEFAULT';
EOS

tmf_test_code(
    name => q[default mode is STRICT_MODE_DEFAULT],

    #args => [],
    exit => 0,

    # test => sub {
    #      my ($out) = @_;
    #      note explain $out;
    # },
    test_code => $test_code,
    debug     => 0,
);

$test_code = <<'EOS';
use Test::MockFile;
is $Test::MockFile::STRICT_MODE_STATUS, Test::MockFile::STRICT_MODE_ENABLED, 'STRICT_MODE_ENABLED';
EOS

tmf_test_code(
    name      => q[import enable STRICT_MODE_ENABLED],
    exit      => 0,
    test_code => $test_code,
    debug     => 0,
);

$test_code = <<'EOS';
use Test::MockFile qw< strict >;
is $Test::MockFile::STRICT_MODE_STATUS, Test::MockFile::STRICT_MODE_ENABLED, 'STRICT_MODE_ENABLED';
EOS

tmf_test_code(
    name      => q[use Test::MockFile qw< strict >],
    exit      => 0,
    test_code => $test_code,
    debug     => 0,
);

$test_code = <<'EOS';
use Test::MockFile qw< nostrict >;
is $Test::MockFile::STRICT_MODE_STATUS, Test::MockFile::STRICT_MODE_DISABLED, 'STRICT_MODE_DISABLED';
EOS

tmf_test_code(
    name      => q[use Test::MockFile qw< nostrict >],
    exit      => 0,
    test_code => $test_code,
    debug     => 0,
);

$test_code = <<'EOS';
use Test::MockFile qw< strict >;
use Test::MockFile qw< strict >;
is $Test::MockFile::STRICT_MODE_STATUS, Test::MockFile::STRICT_MODE_ENABLED, 'STRICT_MODE_ENABLED';
EOS

tmf_test_code(
    name      => q[multiple - use Test::MockFile qw< strict >],
    exit      => 0,
    test_code => $test_code,
    debug     => 0,
);

note "Failed Imports";

$test_code = <<'EOS';
use Test::MockFile qw< strict >;
use Test::MockFile qw< nostrict >;
EOS

tmf_test_code(
    name      => q[use Test::MockFile qw< strict > + qw< nostrict >],
    exit      => 65280,
    test_code => $test_code,
    debug     => 0,
);

$test_code = <<'EOS';
use Test::MockFile;
use Test::MockFile qw< nostrict >;
EOS

tmf_test_code(
    name      => q[use Test::MockFile + qw< nostrict >],
    exit      => 65280,
    test_code => $test_code,
    debug     => 0,
);

done_testing();
