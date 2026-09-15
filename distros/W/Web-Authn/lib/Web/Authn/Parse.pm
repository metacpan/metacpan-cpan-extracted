##----------------------------------------------------------------------------
## WebAuthn - ~/lib/Web/Authn/Parse.pm
## Version v0.2.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/09/09
## Modified 2026/09/12
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Web::Authn::Parse;
BEGIN
{
    use v5.16.0;
    use strict;
    use warnings;
    warnings::register_categories( 'Web::Authn' );
    use vars qw( $VERSION $JSON_CLASS );
    use overload ();
    use Bytes::Random::Secure ();
    use Digest::SHA qw( sha256 );
    use MIME::Base64 qw( encode_base64 decode_base64 );
    use Scalar::Util;
    use Web::Authn::CBOR;
    use Web::Authn::COSE;
    use Web::Authn::Exception;
    # JSON backend detection: prefer Cpanel::JSON::XS (fastest, most rigorous), fall back
    # to JSON::XS, then JSON::PP (core since Perl 5.14).
    our $JSON_CLASS;
    local $@;
    if( eval{ require Cpanel::JSON::XS; 1 } )
    {
        $JSON_CLASS = 'Cpanel::JSON::XS';
    }
    elsif( eval{ require JSON::XS; 1 } )
    {
        $JSON_CLASS = 'JSON::XS';
    }
    else
    {
        require JSON::PP;
        $JSON_CLASS = 'JSON::PP';
    }
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub aaguid_to_string
{
    my $b = maybe_bytes( shift( @_ ) );
    unless( length( $b ) == 16 )
    {
        Web::Authn::Exception::InvalidStructure->throw( 'AAGUID must be 16 bytes' );
    }
    my $h = unpack( 'H*', $b );
    return( sprintf( '%s-%s-%s-%s-%s',
                     substr( $h, 0, 8 ), substr( $h, 8, 4 ), substr( $h, 12, 4 ),
                     substr( $h, 16, 4 ), substr( $h, 20, 12 )
    ) );
}

sub b64u_decode
{
    my $s = _plain( shift( @_ ) );
    unless( defined( $s ) )
    {
        Web::Authn::Exception::InvalidStructure->throw('missing base64url value');
    }
    $s =~ s/\s+//g;
    $s =~ tr{-_}{+/};
    my $pad = ( 4 - length( $s ) % 4 ) % 4;
    $s .= '=' x $pad;
    my $bin = decode_base64( $s );
    defined( $bin ) or Web::Authn::Exception::InvalidStructure->throw( 'invalid base64url' );
    return( $bin );
}

sub b64u_encode
{
    my $bin = maybe_bytes( shift( @_ ) );
    my $s = encode_base64( $bin, '' );
    $s =~ tr{+/}{-_};
    $s =~ s/=+\z//;
    return( $s );
}

sub decode_credential_public_key
{
    my $key = shift( @_ );
    $key = maybe_bytes( $key );
    if( length( $key ) &&
        unpack( 'C', substr( $key, 0, 1 ) ) == 0x04 && length( $key ) == 65 )
    {
        return({
            kty => Web::Authn::COSE::KTY_EC2,
            alg => Web::Authn::COSE::ECDSA_SHA_256,
            crv => Web::Authn::COSE::CRV_P256,
            'x' => substr( $key, 1, 32 ),
            'y' => substr( $key, 33, 32 ),
        });
    }
    my $decoded = Web::Authn::CBOR::decode( $key );
    unless( ref( $decoded ) eq 'HASH' )
    {
        Web::Authn::Exception::InvalidStructure->throw( 'COSE key is not a map' );
    }
    my $kty = $decoded->{ Web::Authn::COSE::KEY_KTY() };
    my $alg = $decoded->{ Web::Authn::COSE::KEY_ALG() };
    unless( defined( $kty ) && defined( $alg ) )
    {
        Web::Authn::Exception::InvalidStructure->throw( 'Credential public key missing kty/alg' );
    }
    if( $kty == Web::Authn::COSE::KTY_OKP )
    {
        return({
            kty => $kty, alg => $alg,
            crv => $decoded->{ Web::Authn::COSE::KEY_CRV() },
            x   => $decoded->{ Web::Authn::COSE::KEY_X() },
        });
    }
    if( $kty == Web::Authn::COSE::KTY_EC2 )
    {
        return({
            kty => $kty,
            alg => $alg,
            crv => $decoded->{ Web::Authn::COSE::KEY_CRV() },
            'x' => $decoded->{ Web::Authn::COSE::KEY_X() },
            'y' => $decoded->{ Web::Authn::COSE::KEY_Y() },
        });
    }
    if( $kty == Web::Authn::COSE::KTY_RSA )
    {
        return({
            kty => $kty,
            alg => $alg,
            n   => $decoded->{ Web::Authn::COSE::KEY_N() },
            e   => $decoded->{ Web::Authn::COSE::KEY_E() },
        });
    }
    if( $kty == Web::Authn::COSE::KTY_ML_DSA )
    {
        return({
            kty => $kty,
            alg => $alg,
            pub => $decoded->{ Web::Authn::COSE::KEY_PUB() },
        });
    }
    Web::Authn::Exception::UnsupportedAlgorithm->throw( qq{Unsupported credential public key type "$kty"} );
}

sub generate_challenge
{
    my $len = _plain( shift( @_ ) );
    $len ||= 64;
    return( _random( $len ) );
}

sub generate_user_handle { return( _random(64) ); }

sub maybe_bytes
{
    my $v = shift( @_ );
    return( $v ) unless( defined( $v ) );
    $v = _plain( $v );
    return( $v ) if( !ref( $v ) );
    return( $$v ) if( ( Scalar::Util::reftype( $v ) || '' ) eq 'SCALAR' );
    Web::Authn::Exception::InvalidStructure->throw( 'expected bytes' );
}

sub options_to_json
{
    my $opt = shift( @_ );
    return( $JSON_CLASS->new->utf8->canonical->encode( options_to_json_dict( $opt ) ) );
}

sub options_to_json_dict
{
    my $opt = shift( @_ );
    my %out;
    if( $opt->{user} )
    {
        # registration
        $out{rp} = { name => _plain( $opt->{rp}->{name} ), id => _plain( $opt->{rp}->{id} ) };
        $out{user} =
        {
            id          => b64u_encode( $opt->{user}->{id} ),
            name        => _plain( $opt->{user}->{name} ),
            displayName => _plain( $opt->{user}->{display_name} // $opt->{user}->{displayName} // $opt->{user}->{name} ),
        };
        $out{challenge} = b64u_encode( $opt->{challenge} );
        $out{pubKeyCredParams} = [map{
            { type => $_->{type} || 'public-key', alg => 0 + $_->{alg} }
        } @{$opt->{pub_key_cred_params} || $opt->{pubKeyCredParams} || []}];
        $out{timeout} = 0 + _plain( $opt->{timeout} ) if( defined( $opt->{timeout} ) );
        if( $opt->{exclude_credentials} )
        {
            $out{excludeCredentials} = [map{ _desc($_) } @{$opt->{exclude_credentials} || [] }];
        }
        $out{attestation} = _plain( $opt->{attestation} ) if( defined( $opt->{attestation} ) );
        if( my $sel = $opt->{authenticator_selection} || $opt->{authenticatorSelection} )
        {
            my %s;
            if( $sel->{authenticator_attachment} || $sel->{authenticatorAttachment} )
            {
                $s{authenticatorAttachment} = _plain( $sel->{authenticator_attachment} || $sel->{authenticatorAttachment} );
            }
            if( $sel->{resident_key} || $sel->{residentKey} )
            {
                $s{residentKey} = _plain( $sel->{resident_key} || $sel->{residentKey} );
            }
            if( exists( $sel->{require_resident_key} ) || exists( $sel->{requireResidentKey} ) )
            {
                no strict 'refs';
                $s{requireResidentKey} = $sel->{require_resident_key} ? &{"$JSON_CLASS\::true"} : &{"$JSON_CLASS\::false"};
            }
            if( $sel->{user_verification} || $sel->{userVerification} )
            {
                $s{userVerification} = _plain( $sel->{user_verification} || $sel->{userVerification} );
            }
            $out{authenticatorSelection} = \%s;
        }
        $out{hints} = $opt->{hints} if( $opt->{hints} );
    }
    else
    {
        $out{challenge} = b64u_encode( $opt->{challenge} );
        $out{timeout}   = 0 + _plain( $opt->{timeout} ) if( defined( $opt->{timeout} ) );
        $out{rpId}      = _plain( $opt->{rp_id} || $opt->{rpId} );
        if( $opt->{allow_credentials} )
        {
            $out{allowCredentials} = [map{ _desc($_) } @{ $opt->{allow_credentials} || [] }];
        }
        if( $opt->{user_verification} || $opt->{userVerification} )
        {
            $out{userVerification} = _plain( $opt->{user_verification} || $opt->{userVerification} );
        }
    }
    return( \%out );
}

sub parse_attestation_object
{
    my $bytes = shift( @_ );
    $bytes = maybe_bytes( $bytes );
    my $obj = Web::Authn::CBOR::decode( $bytes );
    unless( ref( $obj ) eq 'HASH' )
    {
        Web::Authn::Exception::InvalidStructure->throw( 'attestationObject is not a map' );
    }
    my $fmt  = $obj->{fmt};
    my $auth = $obj->{authData};
    unless( defined( $fmt ) && defined( $auth ) )
    {
        Web::Authn::Exception::InvalidStructure->throw( 'attestationObject missing fmt/authData' );
    }
    my $auth_parsed = parse_authenticator_data( $auth );
    my $stmt = parse_attestation_statement( $obj->{attStmt} );
    return({
        fmt       => $fmt,
        auth_data => $auth_parsed,
        att_stmt  => $stmt,
        raw       => $bytes,
        auth_raw  => $auth,
    });
}

sub parse_attestation_statement
{
    my $stmt = shift( @_ );
    return({}) unless( defined( $stmt ) && ref( $stmt ) eq 'HASH' );
    my %out;
    $out{sig}       = $stmt->{sig}      if( exists( $stmt->{sig} ) );
    $out{alg}       = $stmt->{alg}      if( exists( $stmt->{alg} ) );
    $out{x5c}       = $stmt->{x5c}      if( exists( $stmt->{x5c} ) );
    $out{ver}       = $stmt->{ver}      if( exists( $stmt->{ver} ) );
    $out{cert_info} = $stmt->{certInfo} if( exists( $stmt->{certInfo} ) );
    $out{pub_area}  = $stmt->{pubArea}  if( exists( $stmt->{pubArea} ) );
    $out{response}  = $stmt->{response} if( exists( $stmt->{response} ) );
    return( \%out );
}

sub parse_authentication_credential_json
{
    my $cred = shift( @_ );
    $cred    = _as_hash( $cred );
    my $id   = $cred->{id};
    my $raw  = exists( $cred->{rawId} ) ? b64u_decode( $cred->{rawId} ) : b64u_decode( $id );
    my $resp = $cred->{response} || {};
    return({
        id       => $id,
        raw_id   => $raw,
        type     => $cred->{type} || 'public-key',
        response =>
        {
            client_data_json   => _field_bytes( $resp, qw(clientDataJSON client_data_json) ),
            authenticator_data => _field_bytes( $resp, qw(authenticatorData authenticator_data) ),
            signature          => _field_bytes( $resp, qw(signature) ),
            user_handle        => ( exists( $resp->{userHandle} ) && defined( $resp->{userHandle} ) && length( _plain( $resp->{userHandle} ) ) ) ? b64u_decode( $resp->{userHandle} ) : undef,
        },
    });
}

sub parse_authenticator_data
{
    my $val = shift( @_ );
    $val = maybe_bytes( $val );
    unless( length( $val ) >= 37 )
    {
        Web::Authn::Exception::InvalidStructure->throw( 'Authenticator data was ' . length($val) . ' bytes, expected at least 37' );
    }
    my $p = 0;
    my $rp_id_hash = substr( $val, $p, 32 );
    $p += 32;
    my $flags_b = unpack( 'C', substr( $val, $p, 1 ) );
    $p += 1;
    my $sign_count = unpack( 'N', substr( $val, $p, 4 ) );
    $p += 4;
    my $flags =
    {
        up => ( $flags_b & ( 1 << 0 ) ) ? 1 : 0,
        uv => ( $flags_b & ( 1 << 2 ) ) ? 1 : 0,
        be => ( $flags_b & ( 1 << 3 ) ) ? 1 : 0,
        bs => ( $flags_b & ( 1 << 4 ) ) ? 1 : 0,
        at => ( $flags_b & ( 1 << 6 ) ) ? 1 : 0,
        ed => ( $flags_b & ( 1 << 7 ) ) ? 1 : 0,
    };
    my $out =
    {
        rp_id_hash => $rp_id_hash,
        flags      => $flags,
        sign_count => $sign_count,
    };
    if( $flags->{at} )
    {
        my $aaguid  = substr( $val, $p, 16 );
        $p += 16;
        my $cid_len = unpack( 'n', substr( $val, $p, 2 ) );
        $p += 2;
        my $cid     = substr( $val, $p, $cid_len );
        $p += $cid_len;
        my $bad     = pack( 'H*', 'a301634f4b500327206745643235353139' );
        if( substr( $val, $p, length( $bad ) ) eq $bad )
        {
            substr( $val, $p, 1 ) = pack( 'C', 0xA4 );
        }
        my( $pk_obj, $consumed ) = Web::Authn::CBOR::decode( substr( $val, $p ) );
        my $pk_bytes = substr( $val, $p, $consumed );
        $p += $consumed;
        $out->{attested_credential_data} =
        {
            aaguid                => $aaguid,
            credential_id         => $cid,
            credential_public_key => $pk_bytes,
        };
    }
    if( $flags->{ed} )
    {
        my( $ext, $consumed ) = Web::Authn::CBOR::decode( substr( $val, $p ) );
        $out->{extensions} = substr( $val, $p, $consumed );
        $p += $consumed;
    }
    if( length( $val) > $p )
    {
        Web::Authn::Exception::InvalidStructure->throw( 'Leftover bytes detected while parsing authenticator data' );
    }
    return( $out );
}

sub parse_backup_flags
{
    my $flags = shift( @_ );
    my $be = $flags->{be};
    my $bs = $flags->{bs};
    if( !$be && $bs )
    {
        Web::Authn::Exception::InvalidStructure->throw( 'Backup state is true but backup eligibility is false' );
    }
    return({
        credential_device_type => $be ? 'multiDevice' : 'singleDevice',
        credential_backed_up   => $bs ? 1 : 0,
    });
}

sub parse_client_data_json
{
    my $bytes = shift( @_ );
    $bytes = maybe_bytes( $bytes );
    local $@;
    my $json = eval{ $JSON_CLASS->new->utf8->decode( $bytes ) };
    unless( $json && ref( $json ) eq 'HASH' )
    {
        Web::Authn::Exception::InvalidStructure->throw( 'Unable to decode clientDataJSON as JSON object' );
    }

    foreach my $k ( qw( type challenge origin ) )
    {
        unless( exists( $json->{ $k } ) )
        {
            Web::Authn::Exception::InvalidStructure->throw( qq{clientDataJSON missing required property "$k"} );
        }
    }
    my $out = {
        type      => $json->{type},
        challenge => b64u_decode($json->{challenge}),
        origin    => $json->{origin},
    };
    $out->{cross_origin} = $json->{crossOrigin} ? 1 : 0 if( exists( $json->{crossOrigin} ) );
    if( exists( $json->{tokenBinding} ) &&
        ref( $json->{tokenBinding} ) eq 'HASH' )
    {
        my $tb = $json->{tokenBinding};
        if( $tb->{status} &&
            ( $tb->{status} eq 'present' || $tb->{status} eq 'supported' ) )
        {
            $out->{token_binding} = { status => $tb->{status}, id => $tb->{id} };
        }
    }
    return( $out );
}

sub parse_registration_credential_json
{
    my $cred = shift( @_ );
    $cred    = _as_hash( $cred );
    my $id   = $cred->{id};
    my $raw  = exists( $cred->{rawId} ) ? b64u_decode( $cred->{rawId} ) : b64u_decode( $id );
    my $type = $cred->{type} || 'public-key';
    my $resp = $cred->{response} || {};
    return({
        id       => $id,
        raw_id   => $raw,
        type     => $type,
        response =>
        {
            client_data_json   => _field_bytes( $resp, qw(clientDataJSON client_data_json) ),
            attestation_object => _field_bytes( $resp, qw(attestationObject attestation_object) ),
        },
        authenticator_attachment => $cred->{authenticatorAttachment},
        client_extension_results => $cred->{clientExtensionResults} || {},
    });
}

sub _as_hash
{
    my $cred = shift( @_ );
    return( $cred ) if( ref( $cred ) eq 'HASH' );
    $cred = _plain( $cred );
    if( !ref( $cred ) )
    {
        my $j = $JSON_CLASS->new->utf8->decode( $cred );
        return( $j ) if( ref( $j ) eq 'HASH' );
    }
    Web::Authn::Exception::InvalidStructure->throw( 'credential must be JSON or a hash' );
}

sub _desc
{
    my $d  = shift( @_ );
    my $raw_id = maybe_bytes( $d->{id} );
    my $id_out = $raw_id;
    if( $id_out =~ /[^\x20-\x7E]/ )
    {
        $id_out = b64u_encode( $id_out );
    }
    elsif( length( $id_out ) && $id_out !~ /^[A-Za-z0-9_-]+\z/ )
    {
        $id_out = b64u_encode( $id_out );
    }
    else
    {
        # We ssume already base64url or raw that happens to be printable; if it looks like raw 16+ binary-ish we keep encoded
        $id_out = b64u_encode( $raw_id ) if( $d->{_raw} );
    }
    # Always treat Perl bytes IDs as raw when they were generated internally
    if( exists( $d->{_bytes} ) || ( defined( $raw_id ) && $raw_id =~ /[\x00-\x1F\x80-\xFF]/ ) )
    {
        $id_out = b64u_encode( $raw_id );
    }
    my $h = { type => _plain( $d->{type} ) || 'public-key', id => $id_out };
    $h->{transports} = $d->{transports} if( $d->{transports} );
    return( $h );
}

sub _field_bytes
{
    my( $resp, @names ) = @_;
    foreach my $n ( @names )
    {
        next unless( defined( $resp->{ $n } ) );
        my $v = _plain( $resp->{ $n } );
        if( !ref( $v ) )
        {
            if( $v =~ /[^\x20-\x7E]/ )
            {
                return( $v );
            }
            return( b64u_decode( $v ) );
        }
        return( maybe_bytes( $v ) );
    }
    Web::Authn::Exception::InvalidStructure->throw( "missing response field @names" );
}

sub _plain
{
    my $v = shift( @_ );
    return( $v ) if( !defined( $v ) || !ref( $v ) );
    my $rt = Scalar::Util::reftype( $v ) || '';
    if( $rt eq 'SCALAR' && !Scalar::Util::blessed( $v ) )
    {
        return( $$v );
    }
    if( Scalar::Util::blessed( $v ) && overload::Method( $v, '""' ) )
    {
        return( $v . '' );
    }
    return( $$v ) if( $rt eq 'SCALAR' );
    return( $v );
}

# NOTE: A fresh Bytes::Random::Secure object per call. The generator holds OS RNG state
# that must not be shared across Perl ithreads (CLONE would leave a stale object from
# the parent interpreter). Challenge generation is rare compared to CryptX, so the cost
# is acceptable.
sub _random
{
    my $n = shift( @_ );
    $n = int( _plain( $n ) || 0 );
    unless( $n > 0 )
    {
        Web::Authn::Exception->throw( 'random length must be a positive integer' );
    }
    my $rng = Bytes::Random::Secure->new(
        Bits        => 256,
        NonBlocking => 1,
    );
    return( $rng->bytes( $n ) );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Web::Authn::Parse - Parsing helpers for WebAuthn structures

=head1 SYNOPSIS

    my $cd = Web::Authn::Parse::parse_client_data_json( $bytes );
    my $ad = Web::Authn::Parse::parse_authenticator_data( $bytes );
    my $ao = Web::Authn::Parse::parse_attestation_object( $bytes );
    my $pk = Web::Authn::Parse::decode_credential_public_key( $cose );

=head1 DESCRIPTION

Turns the binary and JSON blobs defined by WebAuthn into Perl hashes.
L<Web::Authn> calls these for you; they are public if you need to inspect a response yourself.

=head1 FUNCTIONS

=head2 aaguid_to_string

    my $uuid = Web::Authn::Parse::aaguid_to_string( $acd->{aaguid} );
    # "00000000-0000-0000-0000-000000000000"

Formats a 16-byte AAGUID as a UUID string. Pass the raw 16 bytes, or an object that overloads stringification such as L<Module::Generic::Scalar>.

The function throws L<Web::Authn::Exception::InvalidStructure> if the value is not exactly 16 bytes long.

=head2 b64u_decode

    my $raw = Web::Authn::Parse::b64u_decode( $credential->{id} );

Decodes unpadded base64url to raw bytes. Pass the string to decode (characters C<A-Za-z0-9_->), or an object that overloads stringification.

=head2 b64u_encode

    my $id = Web::Authn::Parse::b64u_encode( $acd->{credential_id} );

Encodes raw bytes as unpadded base64url. Pass the byte string to encode, or an object that overloads stringification.

=head2 decode_credential_public_key

    my $pk = Web::Authn::Parse::decode_credential_public_key( $cose );
    # { kty => 2, alg => -7, crv => 1, x => $x, y => $y }

Decodes a COSE_Key CBOR map, or uncompressed U2F C<0x04 || X || Y> (65 bytes), into a Perl hash with C<kty>, C<alg>, and the type-specific fields (C<crv>/C<x>/C<y>, C<n>/C<e>, or C<pub>). Pass the raw key bytes, or an object that overloads stringification.

=head2 generate_challenge

    my $chal = Web::Authn::Parse::generate_challenge;     # 64
    my $chal = Web::Authn::Parse::generate_challenge(16);

Returns raw CSPRNG bytes from L<Bytes::Random::Secure>. You may pass an optional integer length; it defaults to 64.

=head2 generate_user_handle

    my $handle = Web::Authn::Parse::generate_user_handle;

Returns 64 raw random bytes suitable as a WebAuthn C<user.id>. This function takes no arguments.

=head2 maybe_bytes

    my $raw = Web::Authn::Parse::maybe_bytes( $maybe_sv );

Normalises a value to raw bytes. Pass a plain Perl string, an unblessed scalar reference, or a blessed object that overloads stringification (C<< overload::Method( $obj, '""' ) >>), such as L<Module::Generic::Scalar>. In the last case the value is taken as C<< $obj . '' >>.

Anything else throws C<expected bytes>.

=head2 options_to_json

    my $json = Web::Authn::Parse::options_to_json( $opts );

Serialises registration or authentication options to a JSON string. Byte fields become unpadded base64url; keys are camelCase. Pass the hash returned by L<Web::Authn/generate_registration_options> or L<Web::Authn/generate_authentication_options>.

=head2 options_to_json_dict

    my $href = Web::Authn::Parse::options_to_json_dict( $opts );

Same conversion as L</options_to_json>, but returns a hash instead of a JSON string. Pass the same options hash.

=head2 parse_attestation_object

    my $att = Web::Authn::Parse::parse_attestation_object( $att_obj_bytes );
    # { fmt => 'none', auth_data => {...}, att_stmt => {}, auth_raw => $bytes }

Decodes the CBOR map C<fmt> / C<authData> / C<attStmt>. Pass the raw C<attestationObject> bytes, or an object that overloads stringification.

=head2 parse_attestation_statement

    my $stmt = Web::Authn::Parse::parse_attestation_statement( $att->{attStmt} );

Copies known attestation-statement fields (C<sig>, C<alg>, C<x5c>, C<ver>, C<certInfo>, C<pubArea>, C<response>) into a Perl hash. Pass the decoded C<attStmt> CBOR map. If the argument is undefined or is not a hash, the function returns C<{}>.

=head2 parse_authenticator_data

    my $ad = Web::Authn::Parse::parse_authenticator_data( $bytes );

Splits rpIdHash, flags (UP/UV/BE/BS/AT/ED), signCount, optional attested credential data and extensions. It also applies the known EdDSA 0xA3-should-be-0xA4 workaround used by py_webauthn. Pass the raw authenticator data (at least 37 bytes), or an object that overloads stringification.

=head2 parse_backup_flags

    my $info = Web::Authn::Parse::parse_backup_flags( $ad->{flags} );

Maps the BE and BS flags to C<credential_device_type> (C<singleDevice> or C<multiDevice>) and C<credential_backed_up>. Pass the C<flags> hash from L</parse_authenticator_data>. The function throws if BS is set without BE.

Maps BE/BS to C<credential_device_type> and C<credential_backed_up>.

Dies if BS is set without BE.

=head2 parse_client_data_json

    my $cd = Web::Authn::Parse::parse_client_data_json( $bytes );

Decodes C<clientDataJSON>. The JSON object must contain C<type>, C<challenge> and C<origin>; C<crossOrigin> and C<tokenBinding> are optional. The challenge is decoded from base64url to raw bytes. Pass the raw UTF-8 JSON bytes, or an object that overloads stringification.

=head2 parse_authentication_credential_json

    my $cred = Web::Authn::Parse::parse_authentication_credential_json( $browser_json );

Turns browser JSON (SimpleWebAuthn shape) into the internal hash used by L<Web::Authn/verify_authentication_response>. Pass a JSON string, or a hash with C<id>, C<rawId>, C<type>, and C<response> (C<clientDataJSON>, C<authenticatorData>, C<signature>, and optionally C<userHandle> as unpadded base64url).

=head2 parse_registration_credential_json

    my $cred = Web::Authn::Parse::parse_registration_credential_json( $browser_json );

Turns browser JSON into the internal hash used by L<Web::Authn/verify_registration_response>. Pass a JSON string, or a hash with C<id>, C<rawId>, C<type>, and C<response> (C<clientDataJSON> and C<attestationObject> as unpadded base64url). See L<Web::Authn> for the JSON shape used on the wire.

=head1 THREAD & PROCESS SAFETY

This module is designed to be fully thread-safe and process-safe, ensuring data integrity across Perl ithreads and mod_perl’s threaded Multi-Processing Modules (MPMs) such as Worker or Event.

L</_random> builds a new L<Bytes::Random::Secure> object on every call so a generator created in one ithread is never reused in another. See L<Web::Authn/"THREAD & PROCESS SAFETY">.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Web::Authn>, L<Web::Authn::CBOR>, L<Bytes::Random::Secure>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
