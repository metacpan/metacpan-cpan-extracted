use strict;
use warnings;

my $has_test_tester;
BEGIN { $has_test_tester = eval { require Test::Tester; Test::Tester->VERSION(0.108); 1 } }

use Test::More 0.88;
plan skip_all => 'These tests require Test::Tester 0.108' if not $has_test_tester;

plan tests => 6;

# define our END block first, so it is run last (after TW's END)
END {
    final_tests() if $has_test_tester;
}

use Test::Warnings ':fail_on_warning', ':no_end_test';
use if "$]" >= '5.008', lib => 't/lib';
use if "$]" >= '5.008', 'SilenceStderr';

# we swap out our $tb for Test::Tester's, so we can test the expected
# failure (although not all methods are supported!)
Test::Warnings::_builder(my $capture = Test::Tester::capture());

warn 'here is a warning';   # TEST 1

# now we "END"...

# this is run in the END block
sub final_tests
{
    my @tests = $capture->details;
    Test::Tester::cmp_results(
        \@tests,
        [
            {   # TEST 1
                actual_ok => 0,
                ok => 0,
                name => 'unexpected warning',
                type => '',
                diag => '',
                depth => undef, # not testable in END blocks
            },
        ],
        'failed immediately when we had a warning',
    );
}
