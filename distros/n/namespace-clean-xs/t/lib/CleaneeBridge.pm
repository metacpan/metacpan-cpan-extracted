package CleaneeBridge;
use strict;
use warnings;

use namespace::clean::xs ();

sub import {
    namespace::clean::xs->import(
        -cleanee => scalar(caller),
        -except  => 'IGNORED',
    );
}

1;
