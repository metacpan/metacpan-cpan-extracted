# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

BEGIN {
    use_ok( 'XML::Sig' );
}

my $modulus = '1b+m37u3Xyawh2ArV8txLei251p03CXbkVuWaJu9C8eHy1pu87bcthi+T5WdlCPKD7KGtkKn9vqi4BJBZcG/Y10e8KWVlXDLg9gibN5hb0Agae3i1cCJTqqnQ0Ka8w1XABtbxTimS1B0aO1zYW6d+UYl0xIeAOPsGMfWeu1NgLChZQton1/NrJsKwzMaQy1VI8m4gUleit9Z8mbz9bNMshdgYEZ9oC4bHn/SnA4FvQl1fjWyTpzL/aWF/bEzS6Qd8IBk7yhcWRJAGdXTWtwiX4mXb4h/2sdrSNvyOsd/shCfOSMsf0TX+OdlbH079AsxOwoUjlzjuKdCiFPdU6yAJw==';
my $exponent = 'Iw==';

my $sig = XML::Sig->new( { key => 't/rsa.private.key' } );
isa_ok( $sig, 'XML::Sig' );

dies_ok { $sig = XML::Sig->new( { key => 'foobar' } ) } 'new shoud die when it cannot find the private key';
dies_ok { $sig = XML::Sig->new( { key => 'README' } ) } 'new shoud die when the private key is invalid';
