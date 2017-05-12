package CleaneeBridge;
use strict;
use warnings;

use namespace::clean ();

sub import {
    namespace::clean->import(
        -cleanee => scalar(caller),
        -except  => 'IGNORED',
    );
}

1;
