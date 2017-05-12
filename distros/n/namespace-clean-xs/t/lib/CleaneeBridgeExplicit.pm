package CleaneeBridgeExplicit;
use strict;
use warnings;

use namespace::clean::xs ();

sub import {
    namespace::clean::xs->import(
        -cleanee => scalar(caller),
        qw( x_foo x_baz ),
    );
}

1;
