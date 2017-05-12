# -*- perl -*-

# t/01_load.t - check module loading

use strict;
use Test::More tests => 1;

BEGIN { use_ok('Tie::FTP'); }

# Not a lot doing yet
