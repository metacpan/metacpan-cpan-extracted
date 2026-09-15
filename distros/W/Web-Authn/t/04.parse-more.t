#!perl
##----------------------------------------------------------------------------
## WebAuthn - t/04.parse-more.t
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
    use Digest::SHA qw( sha256 );
    use JSON::PP;
    use Web::Authn::CBOR;
    use Web::Authn::COSE;
    use Web::Authn::Parse;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

# NOTE: generate_user_handle
subtest 'generate_user_handle' => sub
{
    my $h = Web::Authn::Parse::generate_user_handle();
    is( length( $h ), 64, 'user handle is 64 bytes' );
    isnt( $h, Web::Authn::Parse::generate_user_handle(), 'two handles differ' );
};

# NOTE: parse_authenticator_data with AT
subtest 'parse_authenticator_data with AT' => sub
{
    my $rp    = sha256( 'example.com' );
    my $flags = pack( 'C', 0x41 );    # UP + AT
    my $count = pack( 'N', 7 );
    my $aaguid = "\x11" x 16;
    my $cid    = 'cred-id-01';
    my $x = "\x01" x 32;
    my $y = "\x02" x 32;
    my $cose = Web::Authn::CBOR::encode({
        1  => Web::Authn::COSE::KTY_EC2,
        3  => Web::Authn::COSE::ECDSA_SHA_256,
        -1 => Web::Authn::COSE::CRV_P256,
        -2 => \$x,
        -3 => \$y,
    });
    my $ad = $rp . $flags . $count . $aaguid . pack( 'n', length( $cid ) ) . $cid . $cose;
    my $parsed = Web::Authn::Parse::parse_authenticator_data( $ad );
    ok( $parsed->{flags}->{up}, 'UP' );
    ok( $parsed->{flags}->{at}, 'AT' );
    is( $parsed->{sign_count}, 7, 'sign count' );
    my $acd = $parsed->{attested_credential_data};
    ok( $acd, 'attested credential data' );
    is( $acd->{aaguid}, $aaguid, 'aaguid raw' );
    is( $acd->{credential_id}, $cid, 'credential id' );
    my $pk = Web::Authn::Parse::decode_credential_public_key( $acd->{credential_public_key} );
    is( $pk->{kty}, Web::Authn::COSE::KTY_EC2, 'cose kty' );
    is( $pk->{x}, $x, 'cose x' );
};

# NOTE: parse_attestation_object none
subtest 'parse_attestation_object none' => sub
{
    my $rp    = sha256( 'example.com' );
    my $flags = pack( 'C', 0x41 );
    my $count = pack( 'N', 0 );
    my $aaguid = "\x00" x 16;
    my $cid    = 'abc';
    my $x = "\x03" x 32;
    my $y = "\x04" x 32;
    my $cose = Web::Authn::CBOR::encode({
        1  => Web::Authn::COSE::KTY_EC2,
        3  => Web::Authn::COSE::ECDSA_SHA_256,
        -1 => Web::Authn::COSE::CRV_P256,
        -2 => \$x,
        -3 => \$y,
    });
    my $auth = $rp . $flags . $count . $aaguid . pack( 'n', length( $cid ) ) . $cid . $cose;
    my $obj  = Web::Authn::CBOR::encode({
        fmt      => 'none',
        attStmt  => {},
        authData => \$auth,
    });
    my $att = Web::Authn::Parse::parse_attestation_object( $obj );
    is( $att->{fmt}, 'none', 'fmt' );
    is( $att->{auth_data}->{sign_count}, 0, 'count' );
    is( $att->{auth_raw}, $auth, 'auth_raw' );
};

# NOTE: parse_backup_flags
subtest 'parse_backup_flags' => sub
{
    my $ok = Web::Authn::Parse::parse_backup_flags({ be => 1, bs => 1 });
    is( $ok->{credential_device_type}, 'multiDevice', 'BE set => multiDevice' );
    ok( $ok->{credential_backed_up}, 'BS set' );

    $ok = Web::Authn::Parse::parse_backup_flags({ be => 0, bs => 0 });
    is( $ok->{credential_device_type}, 'singleDevice', 'no BE => singleDevice' );

    local $@;
    eval { Web::Authn::Parse::parse_backup_flags({ be => 0, bs => 1 }) };
    ok( $@, 'BS without BE is illegal' );
};

# NOTE: parse_registration_credential_json
subtest 'parse_registration_credential_json' => sub
{
    my $id = Web::Authn::Parse::b64u_encode( 'cred-bytes' );
    my $cd = Web::Authn::Parse::b64u_encode( '{"type":"webauthn.create"}' );
    my $ao = Web::Authn::Parse::b64u_encode( 'att-obj' );
    my $parsed = Web::Authn::Parse::parse_registration_credential_json({
        id       => $id,
        rawId    => $id,
        type     => 'public-key',
        response =>
        {
            clientDataJSON    => $cd,
            attestationObject => $ao,
        },
    });
    is( $parsed->{raw_id}, 'cred-bytes', 'raw_id decoded' );
    is( $parsed->{response}->{client_data_json}, '{"type":"webauthn.create"}', 'clientDataJSON decoded' );
};

# NOTE: parse_authentication_credential_json
subtest 'parse_authentication_credential_json' => sub
{
    my $id  = Web::Authn::Parse::b64u_encode( 'cid' );
    my $ad  = Web::Authn::Parse::b64u_encode( 'A' x 37 );
    my $sig = Web::Authn::Parse::b64u_encode( 'SIG' );
    my $cd  = Web::Authn::Parse::b64u_encode( '{}' );
    my $parsed = Web::Authn::Parse::parse_authentication_credential_json({
        id       => $id,
        rawId    => $id,
        type     => 'public-key',
        response =>
        {
            clientDataJSON    => $cd,
            authenticatorData => $ad,
            signature         => $sig,
        },
    });
    is( $parsed->{response}->{signature}, 'SIG', 'signature decoded' );
    is( $parsed->{response}->{authenticator_data}, 'A' x 37, 'authData decoded' );
};

# NOTE: too-short authenticator data
subtest 'too-short authenticator data' => sub
{
    local $@;
    eval { Web::Authn::Parse::parse_authenticator_data( 'short' ) };
    ok( $@, 'short authData dies' );
};

done_testing;

__END__
