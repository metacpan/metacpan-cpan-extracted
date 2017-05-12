#!perl
use Test::WWW::Declare::Tester tests => 4;
use warnings;
use strict;

my @results = run_tests(
    sub {
        session "check logins" => run {
            flow "basic connectivity" => check {
                get "http://localhost:$PORT/";
                title matches qr{in.ex}i;
                click href qr{good};
                title always equals 'GOOD';
                click href qr{index};
                title caselessly equals 'InDeX';
                title contains 'DEX';
                title never contains 'dEX';
                title contains caselessly 'dEX';

                content shouldnt equal 'anything this short';
                content shouldnt match qr/HELLO CPAN/;
            };
        };
    }
);

shift @results; # Test::Tester gives 1-based arrays
is(@results, 1, "had two tests");
ok($results[0]{ok}, "test passed");
is($results[0]{name}, "basic connectivity", "1st test was flow");
is($results[0]{diag}, '', 'no errors/warnings');

