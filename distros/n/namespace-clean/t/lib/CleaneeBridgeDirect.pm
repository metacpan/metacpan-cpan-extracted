package CleaneeBridgeDirect;
use strict;

use namespace::clean ();

sub import {
    namespace::clean->clean_subroutines(scalar(caller), qw( d_foo d_baz ));
}

1;
