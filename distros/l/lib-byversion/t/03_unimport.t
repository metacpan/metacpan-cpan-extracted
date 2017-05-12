
use strict;
use warnings;

use Test::More tests => 1;

# ABSTRACT: Test Import

use lib::byversion q[test/%v/lib];
no lib::byversion q[test/%v/lib];

cmp_ok( $INC[0], 'ne', qq{test/$]/lib}, 'Library path removed' );
