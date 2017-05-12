#!perl -w

use strict;
use Test::More tests => 1;

BEGIN { use_ok 'UNIVERSAL::DOES' }

diag "Testing UNIVERSAL::DOES/$UNIVERSAL::DOES::VERSION";
