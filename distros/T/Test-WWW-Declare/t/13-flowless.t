#!perl
use Test::WWW::Declare::Tester tests => 13;
use warnings;
use strict;

my @results = run_tests(
    sub {
        session "check logins" => run {
            get "http://localhost:$PORT/";
            content should match qr{This is an index};
            click href qr{good};
            content should match qr{This is a good page}i;
        };
    }
);

shift @results; # Test::Tester gives 1-based arrays
is(@results, 4, "had four tests");

ok($results[0]{ok}, "1st test passed");
ok($results[1]{ok}, "2st test passed");
ok($results[2]{ok}, "3st test passed");
ok($results[3]{ok}, "4st test passed");

is($results[0]{diag}, '', 'no warnings/errors');
is($results[1]{diag}, '', 'no warnings/errors');
is($results[2]{diag}, '', 'no warnings/errors');
is($results[3]{diag}, '', 'no warnings/errors');

is($results[0]{name}, "navigated to http://localhost:$PORT/", "test name was correct");
is($results[1]{name}, "Content does not match (?-xism:This is an index)", "test name was correct");
is($results[2]{name}, "Clicked link matching (?-xism:good)", "test name was correct");
is($results[3]{name}, "Content does not match (?i-xsm:This is a good page)", "test name was correct");

