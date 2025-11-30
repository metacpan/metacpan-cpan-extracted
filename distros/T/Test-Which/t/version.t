#!perl
use strict;
use warnings;
use Test::More;

use Test::Which;

which_ok 'perl', { version => qr/\d+\.\d+/ };

# String in hashref (for consistency)
which_ok 'perl', { version => '>=5.8' };

done_testing();
