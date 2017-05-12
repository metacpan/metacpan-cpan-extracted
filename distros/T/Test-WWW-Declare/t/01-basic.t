#!perl
use Test::WWW::Declare::Tester tests => 4;
use warnings;
use strict;

my @results = run_tests(
    sub {
        session "check logins" => run {
            flow "basic connectivity" => check {
                get "http://localhost:$PORT/";
                content should match qr{This is an index};
                click href qr{good};
                content should match qr{This is a good page}i;
                uri should contain 'good';
            };
        };
    }
);

shift @results; # Test::Tester gives 1-based arrays
is(@results, 1, "had one test");
ok($results[0]{ok}, "1st test passed");
is($results[0]{name}, "basic connectivity", "test name was correct");
is($results[0]{diag}, '', 'no warnings/errors');

