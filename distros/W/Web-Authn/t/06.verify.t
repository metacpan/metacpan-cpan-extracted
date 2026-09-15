#!perl
##----------------------------------------------------------------------------
## WebAuthn - t/06.verify.t
##
## Synthetic ceremonies. Registration with fmt=none does not need CryptX.
## Packed self-attestation and authentication need CryptX (ES256).
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
    use Digest::SHA qw( sha256 );
    use JSON::PP;
    use Web::Authn;
    use Web::Authn::CBOR;
    use Web::Authn::COSE;
    use Web::Authn::Parse;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

my $RP     = 'example.com';
my $ORIGIN = 'https://example.com';

sub b64u { Web::Authn::Parse::b64u_encode( $_[0] ) }

sub client_data
{
    my( $type, $challenge ) = @_;
    return( JSON::PP->new->utf8->encode({
        type      => $type,
        challenge => b64u( $challenge ),
        origin    => $ORIGIN,
    }) );
}

sub cose_ec2
{
    my( $x, $y ) = @_;
    return( Web::Authn::CBOR::encode({
        1  => Web::Authn::COSE::KTY_EC2,
        3  => Web::Authn::COSE::ECDSA_SHA_256,
        -1 => Web::Authn::COSE::CRV_P256,
        -2 => \$x,
        -3 => \$y,
    }) );
}

sub auth_data_at
{
    my( %arg ) = @_;
    my $flags = pack( 'C', $arg{flags} // 0x41 );
    my $ad    = sha256( $RP ) . $flags . pack( 'N', $arg{count} // 1 );
    $ad .= $arg{aaguid} // ( "\x00" x 16 );
    $ad .= pack( 'n', length( $arg{cid} ) ) . $arg{cid};
    $ad .= $arg{cose};
    return( $ad );
}

sub auth_data_get
{
    my( %arg ) = @_;
    my $flags = pack( 'C', $arg{flags} // 0x01 );
    return( sha256( $RP ) . $flags . pack( 'N', $arg{count} // 2 ) );
}

sub registration_json
{
    my( %arg ) = @_;
    my $att = Web::Authn::CBOR::encode({
        fmt      => $arg{fmt} // 'none',
        attStmt  => $arg{att_stmt} // {},
        authData => \$arg{auth},
    });
    return({
        id       => b64u( $arg{cid} ),
        rawId    => b64u( $arg{cid} ),
        type     => $arg{type} // 'public-key',
        response =>
        {
            clientDataJSON    => b64u( $arg{cd} ),
            attestationObject => b64u( $att ),
        },
    });
}

sub authentication_json
{
    my( %arg ) = @_;
    return({
        id       => b64u( $arg{cid} ),
        rawId    => b64u( $arg{cid} ),
        type     => 'public-key',
        response =>
        {
            clientDataJSON    => b64u( $arg{cd} ),
            authenticatorData => b64u( $arg{auth} ),
            signature         => b64u( $arg{sig} ),
        },
    });
}

my $authn = Web::Authn->new(
    rp_id           => $RP,
    rp_name         => 'Example',
    expected_origin => $ORIGIN,
);

# ---------------------------------------------------------------------------
# fmt=none registration: no CryptX
# ---------------------------------------------------------------------------
# NOTE: verify_registration_response fmt=none
subtest 'verify_registration_response fmt=none' => sub
{
    my $chal = Web::Authn::Parse::generate_challenge(16);
    my $cid  = 'credential-one';
    my $cose = cose_ec2( "\x11" x 32, "\x22" x 32 );
    my $auth = auth_data_at( cid => $cid, cose => $cose, count => 0 );
    my $cd   = client_data( 'webauthn.create', $chal );
    my $body = registration_json( cid => $cid, auth => $auth, cd => $cd );

    my $reg = $authn->verify_registration_response(
        credential         => $body,
        expected_challenge => $chal,
    );
    ok( $reg, 'none registration accepted' ) or diag( $authn->error );
    is( $reg->{fmt}, 'none', 'fmt' );
    is( $reg->{credential_id}, $cid, 'credential id' );
    is( $reg->{sign_count}, 0, 'sign count' );
    is( $reg->{aaguid}, '00000000-0000-0000-0000-000000000000', 'zero aaguid' );
    ok( $reg->{credential_public_key}, 'public key persisted' );
};

# NOTE: registration negatives
subtest 'registration negatives' => sub
{
    my $chal = Web::Authn::Parse::generate_challenge(16);
    my $cid  = 'credential-two';
    my $cose = cose_ec2( "\x11" x 32, "\x22" x 32 );
    my $auth = auth_data_at( cid => $cid, cose => $cose );
    my $cd   = client_data( 'webauthn.create', $chal );

    {
        no warnings 'Web::Authn';
        my $bad = $authn->verify_registration_response(
            credential         => registration_json( cid => $cid, auth => $auth, cd => $cd ),
            expected_challenge => 'not-the-challenge',
        );
        ok( !defined( $bad ), 'wrong challenge rejected' );
        isa_ok( $authn->error, 'Web::Authn::Exception::InvalidRegistration' );
    }

    {
        no warnings 'Web::Authn';
        my $wrong = client_data( 'webauthn.get', $chal );
        my $bad = $authn->verify_registration_response(
            credential         => registration_json( cid => $cid, auth => $auth, cd => $wrong ),
            expected_challenge => $chal,
        );
        ok( !defined( $bad ), 'wrong clientData.type rejected' );
    }

    {
        no warnings 'Web::Authn';
        my $body = registration_json( cid => $cid, auth => $auth, cd => $cd, type => 'password' );
        my $bad = $authn->verify_registration_response(
            credential         => $body,
            expected_challenge => $chal,
        );
        ok( !defined( $bad ), 'wrong credential.type rejected' );
    }

    {
        no warnings 'Web::Authn';
        my $no_at = sha256( $RP ) . pack( 'C', 0x01 ) . pack( 'N', 0 );
        my $bad = $authn->verify_registration_response(
            credential         => registration_json( cid => $cid, auth => $no_at, cd => $cd ),
            expected_challenge => $chal,
        );
        ok( !defined( $bad ), 'missing attested credential data rejected' );
    }

    {
        no warnings 'Web::Authn';
        my $other_rp = sha256( 'evil.example' ) . substr( $auth, 32 );
        my $bad = $authn->verify_registration_response(
            credential         => registration_json( cid => $cid, auth => $other_rp, cd => $cd ),
            expected_challenge => $chal,
        );
        ok( !defined( $bad ), 'wrong rpIdHash rejected' );
    }
};

# NOTE: missing verify arguments
subtest 'missing verify arguments' => sub
{
    no warnings 'Web::Authn';
    my $bad = $authn->verify_registration_response();
    ok( !defined( $bad ), 'missing args' );
};

# ---------------------------------------------------------------------------
# Packed self + authentication with CryptX
# ---------------------------------------------------------------------------
my $have_cryptx = eval { require Crypt::PK::ECC; 1 };

# NOTE: packed self-attestation and authentication
subtest 'packed self-attestation and authentication' => sub
{
    SKIP:
    {
        unless( $have_cryptx )
        {
            skip( 'CryptX (Crypt::PK::ECC) not installed', 13 );
        }

        my $ecc = Crypt::PK::ECC->new;
        $ecc->generate_key( 'P-256' );
        my $raw_pub = $ecc->export_key_raw( 'public' );
        ok( length( $raw_pub ) == 65 && unpack( 'C', $raw_pub ) == 0x04, 'uncompressed P-256' );
        my $x = substr( $raw_pub, 1, 32 );
        my $y = substr( $raw_pub, 33, 32 );
        my $cose = cose_ec2( $x, $y );

        my $chal = Web::Authn::Parse::generate_challenge(16);
        my $cid  = pack( 'C*', 1 .. 16 );
        my $auth = auth_data_at( cid => $cid, cose => $cose, count => 1, flags => 0x45 ); # UP+UV+AT
        my $cd   = client_data( 'webauthn.create', $chal );
        my $sig  = $ecc->sign_message( $auth . sha256( $cd ), 'SHA256' );
        ok( $sig, 'packed self signature' );

        my $body = registration_json(
            cid      => $cid,
            auth     => $auth,
            cd       => $cd,
            fmt      => 'packed',
            att_stmt => { alg => Web::Authn::COSE::ECDSA_SHA_256, sig => \$sig },
        );

        my $reg = $authn->verify_registration_response(
            credential         => $body,
            expected_challenge => $chal,
        );
        ok( $reg, 'packed self registration' ) or diag( $authn->error );
        is( $reg->{fmt}, 'packed', 'fmt packed' );
        ok( $reg->{user_verified}, 'UV flag' );
        is( $reg->{sign_count}, 1, 'sign count 1' );

        # authentication with incremented count
        my $chal2 = Web::Authn::Parse::generate_challenge(16);
        my $ad2   = auth_data_get( count => 2, flags => 0x05 ); # UP+UV
        my $cd2   = client_data( 'webauthn.get', $chal2 );
        my $sig2  = $ecc->sign_message( $ad2 . sha256( $cd2 ), 'SHA256' );
        my $get   = authentication_json( cid => $cid, auth => $ad2, cd => $cd2, sig => $sig2 );

        my $ok = $authn->verify_authentication_response(
            credential                    => $get,
            expected_challenge            => $chal2,
            credential_public_key         => $reg->{credential_public_key},
            credential_current_sign_count => $reg->{sign_count},
        );
        ok( $ok, 'authentication accepted' ) or diag( $authn->error );
        is( $ok->{new_sign_count}, 2, 'new sign count' );
        ok( $ok->{user_verified}, 'UV' );

        # cloned authenticator: same or lower count
        {
            no warnings 'Web::Authn';
            my $replay = $authn->verify_authentication_response(
                credential                    => $get,
                expected_challenge            => $chal2,
                credential_public_key         => $reg->{credential_public_key},
                credential_current_sign_count => 2,
            );
            ok( !defined( $replay ), 'non-increasing sign count rejected' );
            like( $authn->error->message, qr/sign count/i, 'sign count message' );
        }

        # bad signature
        {
            no warnings 'Web::Authn';
            my $tampered = authentication_json(
                cid  => $cid,
                auth => $ad2,
                cd   => $cd2,
                sig  => ( "\x00" x length( $sig2 ) ),
            );
            my $bad = $authn->verify_authentication_response(
                credential                    => $tampered,
                expected_challenge            => $chal2,
                credential_public_key         => $reg->{credential_public_key},
                credential_current_sign_count => 1,
            );
            ok( !defined( $bad ), 'bad signature rejected' );
        }

        # require UV but flag off
        {
            no warnings 'Web::Authn';
            my $ad_nouv = auth_data_get( count => 3, flags => 0x01 );
            my $cd3     = client_data( 'webauthn.get', $chal2 );
            my $sig3    = $ecc->sign_message( $ad_nouv . sha256( $cd3 ), 'SHA256' );
            my $bad = $authn->verify_authentication_response(
                credential                    => authentication_json( cid => $cid, auth => $ad_nouv, cd => $cd3, sig => $sig3 ),
                expected_challenge            => $chal2,
                credential_public_key         => $reg->{credential_public_key},
                credential_current_sign_count => 1,
                require_user_verification     => 1,
            );
            ok( !defined( $bad ), 'missing UV rejected when required' );
        }
    };
};

# NOTE: class-function wrappers
subtest 'class-function wrappers' => sub
{
    my $chal = Web::Authn::Parse::generate_challenge(16);
    my $cid  = 'fn-cred';
    my $cose = cose_ec2( "\xAA" x 32, "\xBB" x 32 );
    my $auth = auth_data_at( cid => $cid, cose => $cose );
    my $cd   = client_data( 'webauthn.create', $chal );
    my $reg  = Web::Authn::verify_registration_response(
        credential         => registration_json( cid => $cid, auth => $auth, cd => $cd ),
        expected_challenge => $chal,
        expected_rp_id     => $RP,
        expected_origin    => $ORIGIN,
    );
    ok( $reg, 'functional verify_registration_response' ) or diag( Web::Authn->error );
};

done_testing;

__END__
