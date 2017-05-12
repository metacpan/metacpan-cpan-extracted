# -*- perl -*-

# t/001_load.t - check module loading

use Test::More tests => 2;

BEGIN {
    use_ok( 'XML::Sig' );
}

my $sig = XML::Sig->new(
    {
        key     => 't/rsa.private.key',
    }
);
isa_ok( $sig, 'XML::Sig' );
