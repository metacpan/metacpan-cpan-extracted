
use strict;
use warnings;

use require::relative 'data/config-sub.pl';

use Test::More tests => 2;
use Test::Warnings qw[ :no_end_test had_no_warnings ];

ok config () eq 'config-sub', 'config sub available';

had_no_warnings;

done_testing;
