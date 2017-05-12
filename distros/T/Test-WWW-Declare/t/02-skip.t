#!perl
use Test::WWW::Declare::Tester tests => 9;
use warnings;
use strict;

my @results = run_tests(
    sub {
        session "check logins" => run {
            flow "this will skip" => check {
                get "http://localhost:$PORT/";
                SKIP "Just testing skip";
            };

            flow "make sure we don't skip the rest of the flows" => check {
                title should equal 'INDEX';
            };
        };
    }
);

shift @results; # Test::Tester gives 1-based arrays
is(@results, 2, "had two tests");
ok($results[0]{ok}, "1st test passed");
ok($results[1]{ok}, "1st test passed");

is($results[0]{type}, "skip", "type was skip");
like($results[0]{reason}, qr/^Just testing skip at/, "skip reason was right");
is($results[0]{name}, "", "skipped test name doesn't appear");
is($results[0]{diag}, '', 'no warnings/errors');

is($results[1]{name}, "make sure we don't skip the rest of the flows", "correct name for flow");
is($results[1]{diag}, "", "no warnings/errrors");

