#!perl
use Test::WWW::Declare::Tester tests => 7;
use warnings;
use strict;

my @results = run_tests(
    sub {
        session "check logins" => run {
            flow "visit index good and formy" => check {
                flow "visit index" => check {
                    get "http://localhost:$PORT/";
                    title should equal 'INDEX';
                };

                flow "visit good" => check {
                    click href qr/AAHHH!!!/; # this needs to be line 16 (see last test)
                    title should equal 'GOOD';
                };

                flow "visit formy" => check {
                    get "http://localhost:$PORT/formy";
                    title should equal 'FORMY';
                };
            };
        };
    }
);

shift @results; # Test::Tester gives 1-based arrays
is(@results, 2, "had four tests");
ok($results[0]{ok}, "1st test passed");
ok(!$results[1]{ok}, "2nd test failed");

is($results[0]{name}, "visit index");
is($results[1]{name}, "visit index good and formy");

is($results[0]{diag}, '', 'no errors/warnings');

is($results[1]{diag}, "Flow 'visit good' failed: No link matching (?-xism:AAHHH!!!) found at t/11-nested-flow-error.t line 16\n", 'nested flow failing only reports once, and gives the right line number');

