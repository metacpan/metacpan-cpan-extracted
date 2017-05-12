#!perl
use Test::WWW::Declare::Tester tests => 4;
use warnings;
use strict;

my @results = run_tests(
    sub {
        session "check logins" => run {
            flow "basic connectivity" => check {
                get "http://localhost:$PORT/";
                title should match qr{in.ex}i;
                click href qr{good};
                title should equal 'GOOD';
                click href qr{index};
                title should caselessly equal 'InDeX';
                title should contain 'DEX';
                title shouldnt contain 'dEX';
                title should caselessly contain 'dEX';
                title should lack 'foo';
            };
        };
    }
);

shift @results; # Test::Tester gives 1-based arrays
is(@results, 1, "had two tests");
ok($results[0]{ok}, "1st test passed");

is($results[0]{name}, "basic connectivity", "1st test was flow");

is($results[0]{diag}, '', 'no errors/warnings');

