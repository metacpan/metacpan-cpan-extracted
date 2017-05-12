package Vending;

use warnings;
use strict;

use UR;

class Vending {
    is => [ 'UR::Namespace' ],
    has_constant => [
        allow_sloppy_primitives => { value => 1 },
    ]
};


1;
