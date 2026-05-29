#!/usr/bin/env perl

use strict;
use warnings;
use CBOR::Free;

print CBOR::Free::encode( {
    tagged => CBOR::Free::tag( 123, "John" ),
    1 => 5,
} );
