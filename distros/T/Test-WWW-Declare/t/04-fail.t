#!perl
use Test::WWW::Declare::Tester tests => 7;
use warnings;
use strict;

my @results = run_tests(
    sub {
        session "check logins" => run {
            flow "basic connectivity" => check {
                get "http://localhost:$PORT/";
                content should match qr{This is an index};
                click href qr{bad};
                content should match qr{NOT!}i;
            };

            flow "should be run" => check {
                get "http://localhost:$PORT/";
                content should match qr{This is an index};
            };
        };
    }
);

shift @results; # Test::Tester gives 1-based arrays
is(@results, 2, "had two tests");
ok(!$results[0]{ok}, "1st test failed");
ok( $results[1]{ok}, "2nd test passed");

is($results[0]{name}, "basic connectivity", "1st test was flow");
is($results[1]{name}, "should be run", "2nd test was flow");

like($results[0]{diag}, qr/404 Not Found/, "reasonable error message for 'content should match' failing");
is($results[1]{diag}, '', "no errors/warnings on the second flow");

