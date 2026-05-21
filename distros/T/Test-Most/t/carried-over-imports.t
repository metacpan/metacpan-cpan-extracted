use strict;
use warnings;

use lib 't/lib';
use UsesTestMost;

use Test::Most qw(!any); # exclude an import that has already been imported in UsesTestMost

warning_is {
    require List::Util;
    List::Util->import('any');
} undef, 'List::Util::any imports without warnings after exclusion';

ok any( sub { $_ == 1 }, 1 ), 'List::Util::any is imported into the caller';

UsesTestMost::is_it_one(1);

done_testing;
