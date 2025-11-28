#!perl
use strict;
use warnings;
use Test::More;

use Test::Which;

which_ok 'perl', { version => qr/\d+\.\d+/ };

done_testing;

