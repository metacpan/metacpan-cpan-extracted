use strict;
use warnings;

# this test is invoked indirectly, via t/06-warnings.t
use Test::Kwalitee 'kwalitee_ok';
kwalitee_ok('has_changelog');
Test::Builder->new->done_testing;
1;
