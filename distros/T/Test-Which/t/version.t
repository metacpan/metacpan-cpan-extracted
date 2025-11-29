#!perl
use strict;
use warnings;
use Test::More;

use Test::Which;

which_ok 'perl', { version => qr/\d+\.\d+/ };

# Regex constraints
which_ok 'perl', { version => qr/5\.\d+/ };

# String in hashref (for consistency)
which_ok 'perl', { version => '>=5.8' };

done_testing();
