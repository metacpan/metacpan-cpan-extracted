use strict;
use warnings;
use lib 't/lib/';
use Test::More 0.88;
use SubtestCompat;
use TestUtils;
use TestBridge;

use YAML::As::Parsed ();

#--------------------------------------------------------------------------#
# Generally, write_string can be tested with .tml files in t/tml-local/*
#
# This file is for error tests or conditions that can't be easily tested
# via .tml
#--------------------------------------------------------------------------#

subtest 'write_string as class method' => sub {
    my $got = eval { YAML::As::Parsed->write_string };
    is( $@, '', "write_string lives" );
    is( $got, '', "returns empty string" );
};

done_testing;
