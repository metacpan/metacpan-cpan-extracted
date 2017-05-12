use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

# we are testing ourselves, so we don't want this warning
BEGIN { $ENV{_KWALITEE_NO_WARN} = 1; }

use Test::Kwalitee 'kwalitee_ok';

# these tests all pass without building the dist
my $result = kwalitee_ok(qw(has_changelog has_readme has_tests));

ok($result, 'kwalitee_ok returned true when tests pass');

ok(!Test::Builder->new->has_plan, 'there has been no plan yet');

done_testing;
