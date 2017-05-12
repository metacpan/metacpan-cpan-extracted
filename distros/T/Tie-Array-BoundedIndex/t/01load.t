# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok( 'Tie::Array::BoundedIndex'); }

can_ok("Tie::Array::BoundedIndex",
       qw(TIEARRAY STORE FETCH STORESIZE EXTEND PUSH UNSHIFT SPLICE));
