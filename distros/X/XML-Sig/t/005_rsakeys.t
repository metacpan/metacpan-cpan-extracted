# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

BEGIN {
    use_ok( 'XML::Sig' );
}

my $modulus = '1b+m37u3Xyawh2ArV8txLei251p03CXbkVuWaJu9C8eHy1pu87bcthi+T5WdlCPKD7KGtkKn9vqi4BJBZcG/Y10e8KWVlXDLg9gibN5hb0Agae3i1cCJTqqnQ0Ka8w1XABtbxTimS1B0aO1zYW6d+UYl0xIeAOPsGMfWeu1NgLChZQton1/NrJsKwzMaQy1VI8m4gUleit9Z8mbz9bNMshdgYEZ9oC4bHn/SnA4FvQl1fjWyTpzL/aWF/bEzS6Qd8IBk7yhcWRJAGdXTWtwiX4mXb4h/2sdrSNvyOsd/shCfOSMsf0TX+OdlbH079AsxOwoUjlzjuKdCiFPdU6yAJw==';
my $exponent = 'Iw==';

my $sig = XML::Sig->new( { key => 't/rsa.private.key' } );
isa_ok( $sig, 'XML::Sig' );

isa_ok( $sig->{ key_obj }, 'Crypt::OpenSSL::RSA', 'Key object is valid' );
is( index( $sig->{KeyInfo}, $modulus ), 41, 'Modulus is correct' );
is( index( $sig->{KeyInfo}, $exponent), 405, 'Exponent is correct' );

