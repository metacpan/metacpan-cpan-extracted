#!perl
use Test::WWW::Declare::Tester;
use warnings;
use strict;

my @testnames = ('a', 'b', 'c', 'argy mech', 'd', 'f', 'e');
plan tests => 1 + 3 * @testnames;

my @results = run_tests(
    sub {
        session "visit GOOD" => run {
            flow "a" => check {
                get "http://localhost:$PORT/";
                click href qr{good};
                title should equal 'GOOD';
            };

            session "visit FORMY" => run {
                flow "b" => check {
                    get "http://localhost:$PORT/formy";
                    title should equal 'FORMY';
                };
            };

            flow "c" => check {
                title should equal 'GOOD';
            };

            is(mech("visit FORMY")->title, "FORMY", "argy mech");
        };

        session "visit FORMY" => run {
            flow "d" => check {
                title should equal 'FORMY';
            };

            session "visit GOOD" => run {
                flow "e" => check {
                    title should equal 'GOOD';

                    session "visit FORMY" => run {
                        flow "f" => check {
                            title should equal 'FORMY';
                        };
                    };
                };
            };
        };
    }
);

shift @results; # Test::Tester gives 1-based arrays
is(@results, @testnames, "had ".@testnames." tests");
for (1..@testnames) { ok($results[$_-1]{ok}, "test $_ passed") }

for (1..@testnames)
{
    is($results[$_-1]{name}, $testnames[$_-1], "correct test name for test $_");
}

for (1..@testnames) { is($results[$_-1]{diag}, '', "no errors/warnings") }

