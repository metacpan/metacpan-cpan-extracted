#!perl
##----------------------------------------------------------------------------
## WebAuthn - t/03.cbor.t
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
    use Web::Authn::CBOR;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

# NOTE: integers and text
subtest 'integers and text' => sub
{
    my $bin = Web::Authn::CBOR::encode( 24 );
    my $v   = Web::Authn::CBOR::decode( $bin );
    is( $v, 24, 'uint 24' );

    $bin = Web::Authn::CBOR::encode( -7 );
    $v   = Web::Authn::CBOR::decode( $bin );
    is( $v, -7, 'negative alg' );

    $bin = Web::Authn::CBOR::encode( 'none' );
    $v   = Web::Authn::CBOR::decode( $bin );
    is( $v, 'none', 'tstr' );
};

# NOTE: bstr via scalar ref
subtest 'bstr via scalar ref' => sub
{
    my $raw = pack( 'C*', 0x00, 0xff, 0x7f );
    my $bin = Web::Authn::CBOR::encode_bstr( $raw );
    is( Web::Authn::CBOR::decode( $bin ), $raw, 'encode_bstr roundtrip' );

    $bin = Web::Authn::CBOR::encode( \$raw );
    is( Web::Authn::CBOR::decode( $bin ), $raw, 'scalar-ref bstr roundtrip' );
};

# NOTE: maps with integer keys
subtest 'maps with integer keys' => sub
{
    my $bin = Web::Authn::CBOR::encode({
        1  => 2,
        3  => -7,
        -1 => 1,
        -2 => \pack( 'H*', 'aabbcc' ),
    });
    my( $dec, $n ) = Web::Authn::CBOR::decode( $bin );
    is( $n, length( $bin ), 'consumed whole buffer' );
    is( $dec->{1},  2, 'kty-like' );
    is( $dec->{3}, -7, 'alg' );
    is( $dec->{-1}, 1, 'crv' );
    is( unpack( 'H*', $dec->{-2} ), 'aabbcc', 'x bytes' );
};

# NOTE: attestationObject shape
subtest 'attestationObject shape' => sub
{
    my $auth = 'A' x 37;
    my $bin  = Web::Authn::CBOR::encode({
        fmt      => 'none',
        attStmt  => {},
        authData => \$auth,
    });
    my $obj = Web::Authn::CBOR::decode( $bin );
    is( $obj->{fmt}, 'none', 'fmt' );
    is( ref( $obj->{attStmt} ), 'HASH', 'attStmt map' );
    is( $obj->{authData}, $auth, 'authData bstr' );
};

# NOTE: duplicate map key rejected
subtest 'duplicate map key rejected' => sub
{
    # A2 01 01 01 02  => map(2) { 1: 1, 1: 2 }
    my $dup = pack( 'C*', 0xA2, 0x01, 0x01, 0x01, 0x02 );
    local $@;
    eval { Web::Authn::CBOR::decode( $dup ) };
    ok( $@, 'duplicate key dies' );
    like( "$@", qr/duplicate/i, 'error mentions duplicate' );
};

# NOTE: truncated input
subtest 'truncated input' => sub
{
    local $@;
    eval { Web::Authn::CBOR::decode( pack( 'C', 0x58 ) ) }; # bstr, missing length
    ok( $@, 'truncated bstr dies' );
};

done_testing;

__END__
