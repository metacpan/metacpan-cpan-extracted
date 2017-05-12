use strict;
use warnings;

use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

# we are testing ourselves, so we don't want this warning
BEGIN { $ENV{_KWALITEE_NO_WARN} = 1; }


# these tests all pass without building the dist
my @expected; BEGIN { @expected = (qw(
    has_changelog
    has_readme
    has_tests
)) }

use Test::Kwalitee tests => \@expected;

my $count = @expected + ($ENV{AUTHOR_TESTING} ? 1 : 0);
Test::Builder->new->current_test == $count
    or die 'ran ' . Test::Builder->new->current_test . ' tests; expected ' . $count . '!';

