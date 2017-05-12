use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

use random fixed=>5;
is ( rand, 5,  "fixed rand");
