use strict;
use warnings;

my $has_test_tester;
BEGIN { $has_test_tester = eval { require Test::Tester; Test::Tester->VERSION(0.108); 1 } }

use Test::More 0.88;
plan skip_all => 'These tests require Test::Tester 0.108' if not $has_test_tester;

plan tests => 19;     # avoid our done_testing hook

# define our END block first, so it is run last (after TW's END)
END {
    final_tests() if $has_test_tester;
}

use Test::Warnings ':all';
use if "$]" >= '5.008', lib => 't/lib';
use if "$]" >= '5.008', 'SilenceStderr';

# we swap out our $tb for Test::Tester's, so we can also test the results
# of the END block... (although not all methods are supported!)
Test::Warnings::_builder(my $capture = Test::Tester::capture());

allow_warnings;
ok(allowing_warnings, 'warnings are now allowed');
warn 'this warning will not cause a failure';
had_no_warnings;                                        # TEST 1

allow_warnings(0);
ok(!allowing_warnings, 'warnings are not allowed again');
warn 'this warning is not expected to be caught';

allow_warnings(undef);
ok(!allowing_warnings, 'warnings are still not allowed');

had_no_warnings('no warnings, with a custom name');     # TEST 2

# now we "END"...

# this is run in the END block
sub final_tests
{
    my @tests = $capture->details;
    Test::Tester::cmp_results(
        \@tests,
        [
            {   # TEST 1
                actual_ok => 1,
                ok => 1,
                name => 'no (unexpected) warnings',
                type => '',
                diag => '',
                depth => undef, # not testable in END blocks
            },
            {   # TEST 2
                actual_ok => 0,
                ok => 0,
                name => 'no warnings, with a custom name',
                type => '',
                diag => '',
                depth => undef, # not testable in END blocks
            },

            {   # END
                actual_ok => 0,
                ok => 0,
                name => 'no (unexpected) warnings (via END block)',
                type => '',
                diag => '',
                depth => undef, # not testable in END blocks
            },
        ],
        'all functionality ok, checking warnings via END block',
    );
}
