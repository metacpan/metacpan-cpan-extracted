use strict;
use warnings;
use Test::More;

use Test::Which qw(which_ok);

ok which_ok('perl'), 'perl present';

done_testing;
