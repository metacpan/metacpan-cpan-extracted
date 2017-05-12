#!perl

use strict;
use warnings;

use Test::More 0.98;
use Version::Monotonic qw(
                             valid_version
                             inc_version
                     );

subtest valid_version => sub {
    ok(!valid_version("0.1"));
    ok(!valid_version("1.0"));
    ok(!valid_version("1.01"));
    ok( valid_version("1.1"));
    ok( valid_version("12.3456"));
    ok( valid_version("12.3456.0"));
    ok(!valid_version("12.3456.1"));
};

subtest inc_version => sub {
    is(inc_version("1.9"), "1.10");
    is(inc_version("1.9", 1), "2.10");
    # XXX test invalid version -> dies
};

DONE_TESTING:
done_testing;
