# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

BEGIN {
    use_ok( 'XML::Sig' );
}

my $modulus = 'rkqxhCTOB2XxFxCNWJt0bLWRQva6qOAPKiqlLfgJjG+YY2JaPtpO7WNV5oVqv9F21V/wgOkcQTZZQQQl/L/eXlnFpJeSpF31dupLnzrBU29qWjedNCkj+y01sprJG+c++2d2jV8Qccp55SklALtXYZ3K5OfILy4dFEqUyW0/Bk7Y/PdrAacAazumdNW2nw/ajbiXbUfm55QebQd/61emGettQBT9EUPOxMQrrtxHHxwyvrtsa9KyRPCamYEamOA0Al2Eya5dPWzEbndbVpRx1jz8Ec6ANk8wJHTkggJOUXWem7HL4x8v9hEQeaHEy5CwxKzodDpV2bA/Adr+NCYhsQ==';
my $exponent = 'AQAB';

my $sig = XML::Sig->new( { key => 't/rsa.private.key' } );
isa_ok( $sig, 'XML::Sig' );

isa_ok( $sig->{ key_obj }, 'Crypt::OpenSSL::RSA', 'Key object is valid' );
is( index( $sig->{KeyInfo}, $modulus ), 166, 'Modulus is correct' );
is( index( $sig->{KeyInfo}, $exponent), 576, 'Exponent is correct' );

