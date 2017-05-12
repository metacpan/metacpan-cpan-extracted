#!perl
use Test::WWW::Declare::Tester tests => 7;
use warnings;
use strict;

my @results = run_tests(
    sub {
        session "check logins" => run {
            flow "search1" => check {
                get "http://localhost:$PORT/formy";

                fill form 'one' => {
                    clever => 'Modestly',
                };

                click button 'sub-mits';

                content should match qr{MODESTLY};
            };

            flow "search2" => check {
                get "http://localhost:$PORT/formy";

                fill form 'two' => {
                    clever => 'Verily',
                };

                click button 'sub-mits 2';

                content should match qr{verily};
            };
        };
    }
);

shift @results; # Test::Tester gives 1-based arrays
is(@results, 2, "two tests");
ok($results[0]{ok}, "1st test passed");
ok($results[1]{ok}, "2nd test passed");

is($results[0]{name}, "search1", "1st test was flow");
is($results[1]{name}, "search2", "2nd test was flow");

is($results[0]{diag}, '', 'no errors/warnings');
is($results[1]{diag}, '', 'no errors/warnings');

