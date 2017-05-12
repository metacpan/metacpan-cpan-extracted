#!perl
use Test::WWW::Declare::Tester tests => 7;
use warnings;
use strict;

my @results = run_tests(
    sub {
        session "check logins" => run {
            flow "click href expects a regex" => check {
                get "http://localhost:$PORT/";
                click href 3;
            };
            flow "no form foo" => check {
                fill form foo => {
                    true  => 'false',
                    false => 'true',
                };
            };
        };
    }
);

shift @results; # Test::Tester gives 1-based arrays
is(@results, 2, "had two tests");
ok(!$results[0]{ok}, "1st test passed");
ok(!$results[1]{ok}, "2nd test passed");

is($results[0]{name}, "click href expects a regex");
is($results[1]{name}, "no form foo");

like($results[0]{diag}, qr/click doesn\'t know what to do with a link type of  at/, 'reasonable error message for "click href 3"');
like($results[1]{diag}, qr/Flow 'no form foo' failed: There is no form named 'foo'/, 'reasonable error message for "fill form nonexistent"');

