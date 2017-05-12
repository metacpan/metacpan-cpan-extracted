#!perl
use Test::WWW::Declare::Tester tests => 7;
use warnings;
use strict;

my @results = run_tests(
    sub {
        session "check logins" => run {
            flow "basic connectivity" => check {
                get "http://localhost:$PORT/";
                mech()->title_is("INDEX", "drop down to mech for checking title");
            };
        };
    }
);

shift @results; # Test::Tester gives 1-based arrays
is(@results, 2, "had three tests");
ok($results[0]{ok}, "1st test passed");
ok($results[1]{ok}, "2nd test passed");

is($results[0]{name}, "drop down to mech for checking title", "1st test was by mech");
is($results[1]{name}, "basic connectivity", "2nd test was flow");

is($results[0]{diag}, "", "no warnings/errors");
is($results[1]{diag}, "", "no warnings/errors");

