#!perl
use strict;
use warnings;
use Test::More;

use Test::Which;

# This program shouldn't exist
which_ok 'definitely-not-a-real-command-xyz', { exit => 0 };

done_testing();
