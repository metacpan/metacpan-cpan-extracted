use strict;
use warnings;

my $has_test_tester;
BEGIN { $has_test_tester = eval { require Test::Tester; Test::Tester->VERSION(0.108); 1 } }

use Test::More 0.88;
plan skip_all => 'These tests require Test::Tester 0.108' if not $has_test_tester;
plan tests => 6;

use if "$]" >= '5.008', lib => 't/lib';
use if "$]" >= '5.008', 'SilenceStderr';

use Test::Warnings qw(had_no_warnings :report_warnings :no_end_test);
Test::Warnings::_builder(my $capture = Test::Tester::capture());

warn 'this is a warning 1 2 3'; my $line = __LINE__;

my (undef, @results) = Test::Tester::run_tests(sub { had_no_warnings; });

Test::Tester::cmp_results(
    [ $capture->details ],
    [
        {
            actual_ok => 0,
            ok => 0,
            name => 'no (unexpected) warnings',
            diag => "Got the following unexpected warnings:\n  1: this is a warning 1 2 3 at ".__FILE__." line $line.",
            depth => 1,
        },
    ],
    'with :report_warnings enabled, had_no_warnings() tells about warnings that we may not have seen before',
);
