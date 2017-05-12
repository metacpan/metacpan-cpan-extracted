package CleaneeBridgeExplicit;
use strict;
use warnings;

use namespace::clean ();

sub import {
    namespace::clean->import(
        -cleanee => scalar(caller),
        qw( x_foo x_baz ),
    );
}

1;
