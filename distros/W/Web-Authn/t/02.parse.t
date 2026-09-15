#!perl
##----------------------------------------------------------------------------
## WebAuthn - t/02.parse.t
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    use Digest::SHA qw( sha256 );
    use JSON::PP;
    use Web::Authn::CBOR;
    use Web::Authn::Parse;
    use Web::Authn::COSE;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

# CBOR map with integer keys
my $cbor = Web::Authn::CBOR::encode({ 1 => 2, 3 => -7, -2 => \pack( 'H*', 'aabb' ) });
my( $dec, $n ) = Web::Authn::CBOR::decode( $cbor );
is( $dec->{1}, 2, 'cbor int key' );
is( $dec->{3}, -7, 'cbor negative alg' );
is( unpack( 'H*', $dec->{-2} ), 'aabb', 'cbor bstr' );

# Authenticator data without AT
my $rp = sha256( 'example.com' );
my $flags = pack( 'C', 0x01 );  # UP
my $count = pack( 'N', 42 );
my $ad = $rp . $flags . $count;
my $parsed = Web::Authn::Parse::parse_authenticator_data( $ad );
is( $parsed->{sign_count}, 42, 'sign count' );
ok( $parsed->{flags}->{up},    'UP flag' );
ok( !$parsed->{flags}->{at},   'no AT' );

# clientDataJSON
my $chal = Web::Authn::Parse::generate_challenge(16);
my $cd = JSON::PP->new->utf8->encode({
    type      => 'webauthn.create',
    challenge => Web::Authn::Parse::b64u_encode( $chal ),
    origin    => 'https://example.com',
});
my $pcd = Web::Authn::Parse::parse_client_data_json( $cd );
is( $pcd->{type},      'webauthn.create', 'client data type' );
is( $pcd->{challenge}, $chal,             'client data challenge' );

# COSE EC2 key encode/decode
my $x = "\x11" x 32;
my $y = "\x22" x 32;
my $cose = Web::Authn::CBOR::encode({
    1  => Web::Authn::COSE::KTY_EC2,
    3  => Web::Authn::COSE::ECDSA_SHA_256,
    -1 => Web::Authn::COSE::CRV_P256,
    -2 => \$x,
    -3 => \$y,
});
my $pk = Web::Authn::Parse::decode_credential_public_key( $cose );
is( $pk->{kty}, 2,  'ec2 kty' );
is( $pk->{x},   $x, 'ec2 x' );

is( Web::Authn::Parse::aaguid_to_string( "\x00" x 16 ), '00000000-0000-0000-0000-000000000000', 'zero aaguid' );

done_testing;

__END__
