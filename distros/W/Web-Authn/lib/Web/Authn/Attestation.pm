##----------------------------------------------------------------------------
## WebAuthn - ~/lib/Web/Authn/Attestation.pm
## Version v0.1.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/09/09
## Modified 2026/09/11
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Web::Authn::Attestation;
BEGIN
{
    use v5.16.0;
    use strict;
    use warnings;
    warnings::register_categories( 'Web::Authn' );
    use vars qw( $VERSION $JSON_CLASS );
    use Digest::SHA qw( sha256 );
    use MIME::Base64 qw( decode_base64 encode_base64 );
    use Web::Authn::CBOR;
    use Web::Authn::COSE;
    use Web::Authn::Crypto;
    use Web::Authn::Exception;
    use Web::Authn::Parse;
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
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub sha384 { Digest::SHA::sha384( $_[0] ) }

sub sha512 { Digest::SHA::sha512( $_[0] ) }

sub verify
{
    my( %arg ) = @_;
    my $fmt = Web::Authn::Parse::_plain( $arg{fmt} );
    return( verify_none( %arg ) )              if( $fmt eq 'none' );
    return( verify_packed( %arg ) )            if( $fmt eq 'packed' );
    return( verify_fido_u2f( %arg ) )          if( $fmt eq 'fido-u2f' );
    return( verify_apple( %arg ) )             if( $fmt eq 'apple' );
    return( verify_tpm( %arg ) )               if( $fmt eq 'tpm' );
    return( verify_android_safetynet( %arg ) ) if( $fmt eq 'android-safetynet' );
    return( verify_android_key( %arg ) )       if( $fmt eq 'android-key' );
    Web::Authn::Exception::InvalidRegistration->throw( qq{Unsupported attestation type "$fmt"} );
}

sub verify_android_key
{
    my( %arg ) = @_;
    my $stmt = $arg{att_stmt};
    unless( $stmt->{sig} && $stmt->{x5c} )
    {
        Web::Authn::Exception::InvalidRegistration->throw( 'android-key attestation missing sig/x5c' );
    }
    Web::Authn::Crypto::validate_certificate_chain(
        x5c            => $stmt->{x5c},
        pem_root_certs => $arg{pem_root_certs} || [],
    );
    my $verification_data = $arg{auth_raw} . sha256( $arg{client_data_json} );
    my $pk = Web::Authn::Crypto::public_key_from_cert_der( $stmt->{x5c}->[0] );
    local $@;
    eval
    {
        Web::Authn::Crypto::verify_signature(
            public_key => $pk,
            alg        => $stmt->{alg} || Web::Authn::COSE::ECDSA_SHA_256,
            signature  => $stmt->{sig},
            data       => $verification_data,
        );
        1;
    } or Web::Authn::Exception::InvalidRegistration->throw( 'Could not verify android-key attestation signature' );
    return(1);
}

sub verify_android_safetynet
{
    my( %arg ) = @_;
    my $stmt = $arg{att_stmt};
    my $jwt  = Web::Authn::Parse::_plain( $stmt->{response} );
    unless( defined( $jwt ) )
    {
        Web::Authn::Exception::InvalidRegistration->throw( 'SafetyNet attestation missing response' );
    }
    my( $h64, $p64, $s64 ) = split( /\./, $jwt, 3 );
    unless( $h64 && $p64 && defined( $s64 ) )
    {
        Web::Authn::Exception::InvalidRegistration->throw( 'SafetyNet response is not a JWT' );
    }
    my $header  = $JSON_CLASS->new->utf8->decode(_b64u( $h64 ) );
    my $payload = $JSON_CLASS->new->utf8->decode(_b64u( $p64 ) );
    my $sig     = _b64u( $s64 );
    my $x5c     = $header->{x5c} || [];
    unless( @$x5c )
    {
        Web::Authn::Exception::InvalidRegistration->throw( 'SafetyNet JWT missing x5c' );
    }
    my $leaf = decode_base64( $x5c->[0] );
    my $pk   = Web::Authn::Crypto::public_key_from_cert_der( $leaf );
    my $signing_input = "$h64.$p64";
    local $@;
    eval
    {
        Web::Authn::Crypto::verify_signature(
            public_key => $pk,
            alg        => Web::Authn::COSE::RSASSA_PKCS1_SHA_256,
            signature  => $sig,
            data       => $signing_input,
        );
        1;
    } or Web::Authn::Exception::InvalidRegistration->throw( 'SafetyNet JWT signature invalid' );

    unless( $payload->{ctsProfileMatch} )
    {
        Web::Authn::Exception::InvalidRegistration->throw( 'SafetyNet ctsProfileMatch was false' );
    }

    my $nonce_expected = encode_base64( sha256( $arg{auth_raw} . sha256( $arg{client_data_json} ) ), '' );
    # SafetyNet nonce is base64 of sha256(attestationObject || clientDataHash) — some impls use authData.
    # Accept either the provided nonce matching hash of attestation object + clientDataHash
    # or authData + clientDataHash.
    my $nonce = $payload->{nonce} || '';
    my $alt = encode_base64( sha256( ( $arg{attestation_object} || $arg{auth_raw} ) . sha256( $arg{client_data_json} ) ), '' );
    unless( $nonce eq $nonce_expected || $nonce eq $alt )
    {
        Web::Authn::Exception::InvalidRegistration->throw( 'SafetyNet nonce mismatch' );
    }
    return(1);
}

sub verify_apple
{
    my( %arg ) = @_;
    my $stmt = $arg{att_stmt};
    $stmt->{x5c} && @{$stmt->{x5c}}
        or Web::Authn::Exception::InvalidRegistration->throw( 'Attestation statement was missing x5c (Apple)' );

    my $roots = [ @{$arg{pem_root_certs} || []} ];
    if( my $built_in = _apple_root() )
    {
        push( @$roots, $built_in );
    }
    Web::Authn::Crypto::validate_certificate_chain( x5c => $stmt->{x5c}, pem_root_certs => $roots );

    my $nonce_to_hash = $arg{auth_raw} . sha256( $arg{client_data_json} );
    my $nonce = sha256( $nonce_to_hash );
    my $ext = Web::Authn::Crypto::extract_extension_octet( $stmt->{x5c}->[0], '1.2.840.113635.100.8.2' );
    unless( defined( $ext ) )
    {
        Web::Authn::Exception::InvalidRegistration->throw( 'Certificate missing extension 1.2.840.113635.100.8.2 (Apple)' );
    }
    # Apple wraps nonce in an ASN.1 structure; take the last 32 bytes if longer.
    my $ext_nonce = length( $ext ) > 32 ? substr( $ext, -32 ) : $ext;
    unless( $ext_nonce eq $nonce )
    {
        Web::Authn::Exception::InvalidRegistration->throw( 'Certificate nonce was not expected value (Apple)' );
    }

    my $cert_pk = Web::Authn::Crypto::public_key_from_cert_der( $stmt->{x5c}->[0] );
    my $cred_pk = Web::Authn::Crypto::cose_to_public_key(
        Web::Authn::Parse::decode_credential_public_key( $arg{credential_public_key} )
    );
    my $a = Web::Authn::Crypto::export_spki_der( $cert_pk );
    my $b = Web::Authn::Crypto::export_spki_der( $cred_pk );
    unless( $a eq $b )
    {
        Web::Authn::Exception::InvalidRegistration->throw( 'Certificate public key did not match credential public key (Apple)' );
    }
    return(1);
}

sub verify_fido_u2f
{
    my( %arg ) = @_;
    my $stmt = $arg{att_stmt};
    unless( $stmt->{sig} )
    {
        Web::Authn::Exception::InvalidRegistration->throw( 'Attestation statement was missing signature (FIDO-U2F)' );
    }
    unless( $stmt->{x5c} && @{$stmt->{x5c}} )
    {
        Web::Authn::Exception::InvalidRegistration->throw('Attestation statement was missing certificate (FIDO-U2F)');
    }
    unless( @{$stmt->{x5c}} == 1 )
    {
        Web::Authn::Exception::InvalidRegistration->throw('Attestation statement contained too many certificates (FIDO-U2F)');
    }

    Web::Authn::Crypto::validate_certificate_chain(
        x5c            => $stmt->{x5c},
        pem_root_certs => $arg{pem_root_certs} || [],
    );

    my $aaguid = Web::Authn::Parse::aaguid_to_string( $arg{aaguid} );
    unless( $aaguid eq '00000000-0000-0000-0000-000000000000' )
    {
        Web::Authn::Exception::InvalidRegistration->throw( "AAGUID $aaguid was not expected 00000000-0000-0000-0000-000000000000 (FIDO-U2F)" );
    }

    my $decoded = Web::Authn::Parse::decode_credential_public_key( $arg{credential_public_key} );
    unless( $decoded->{kty} == Web::Authn::COSE::KTY_EC2 )
    {
        Web::Authn::Exception::InvalidRegistration->throw( 'Credential public key was not EC2 (FIDO-U2F)' );
    }

    my $public_key_u2f = pack( 'C', 0x04 ) . $decoded->{'x'} . $decoded->{'y'};
    my $client_hash = sha256( $arg{client_data_json} );
    my $verification_data = pack( 'C', 0x00 ) . $arg{rp_id_hash} . $client_hash . $arg{credential_id} . $public_key_u2f;

    my $pk = Web::Authn::Crypto::public_key_from_cert_der( $stmt->{x5c}->[0] );
    local $@;
    eval
    {
        Web::Authn::Crypto::verify_signature(
            public_key => $pk,
            alg        => Web::Authn::COSE::ECDSA_SHA_256,
            signature  => $stmt->{sig},
            data       => $verification_data,
        );
        1;
    } or Web::Authn::Exception::InvalidRegistration->throw( 'Could not verify attestation statement signature (FIDO-U2F)' );
    return(1);
}

sub verify_none
{
    my( %arg ) = @_;
    my $stmt = $arg{att_stmt} || {};
    my $any = grep{ defined( $stmt->{ $_ } ) } keys( %$stmt );
    if( $any )
    {
        Web::Authn::Exception::InvalidRegistration->throw( 'None attestation had unexpected attestation statement' );
    }
    return(1);
}

sub verify_packed
{
    my( %arg ) = @_;
    my $stmt = $arg{att_stmt};
    unless( $stmt->{sig} )
    {
        Web::Authn::Exception::InvalidRegistration->throw('Attestation statement was missing signature (Packed)');
    }
    unless( defined( $stmt->{alg} ) )
    {
        Web::Authn::Exception::InvalidRegistration->throw('Attestation statement was missing algorithm (Packed)');
    }

    my $auth_raw    = $arg{auth_raw};
    my $client_hash = sha256( $arg{client_data_json} );
    my $verification_data = $auth_raw . $client_hash;

    if( $stmt->{x5c} && @{$stmt->{x5c}} )
    {
        Web::Authn::Crypto::validate_certificate_chain(
            x5c            => $stmt->{x5c},
            pem_root_certs => $arg{pem_root_certs} || [],
        );
        my $pk = Web::Authn::Crypto::public_key_from_cert_der( $stmt->{x5c}[0] );
        local $@;
        eval
        {
            Web::Authn::Crypto::verify_signature(
                public_key => $pk,
                alg        => $stmt->{alg},
                signature  => $stmt->{sig},
                data       => $verification_data,
            );
            1;
        } or Web::Authn::Exception::InvalidRegistration->throw( 'Could not verify attestation statement signature (Packed)' );
    }
    else
    {
        my $decoded = Web::Authn::Parse::decode_credential_public_key( $arg{credential_public_key} );
        if( $decoded->{alg} != $stmt->{alg} )
        {
            Web::Authn::Exception::InvalidRegistration->throw( "Credential public key alg $decoded->{alg} did not equal attestation statement alg $stmt->{alg}" );
        }
        my $pk = Web::Authn::Crypto::cose_to_public_key( $decoded );
        local $@;
        eval
        {
            Web::Authn::Crypto::verify_signature(
                public_key => $pk,
                alg        => $stmt->{alg},
                signature  => $stmt->{sig},
                data       => $verification_data,
            );
            1;
        } or Web::Authn::Exception::InvalidRegistration->throw( 'Could not verify attestation statement signature (Packed|Self)' );
    }
    return(1);
}

sub verify_tpm
{
    my( %arg ) = @_;
    my $stmt = $arg{att_stmt};
    unless( $stmt->{sig} &&
            $stmt->{x5c} &&
            $stmt->{cert_info} &&
            $stmt->{pub_area} )
    {
        Web::Authn::Exception::InvalidRegistration->throw( 'TPM attestation statement missing fields' );
    }

    Web::Authn::Crypto::validate_certificate_chain(
        x5c            => $stmt->{x5c},
        pem_root_certs => $arg{pem_root_certs} || [],
    );

    my $auth_raw = $arg{auth_raw};
    my $att_to_be_signed = $auth_raw . sha256( $arg{client_data_json} );
    my $pk = Web::Authn::Crypto::public_key_from_cert_der( $stmt->{x5c}->[0] );
    local $@;
    eval
    {
        Web::Authn::Crypto::verify_signature(
            public_key => $pk,
            alg        => $stmt->{alg} || Web::Authn::COSE::RSASSA_PKCS1_SHA_256,
            signature  => $stmt->{sig},
            data       => $stmt->{cert_info},
        );
        1;
    } or Web::Authn::Exception::InvalidRegistration->throw( 'Could not verify TPM certInfo signature' );
    # extraData in TPMS_ATTEST should be a hash of attToBeSigned. We check it appears.
    unless( index( $stmt->{cert_info}, sha256( $att_to_be_signed ) ) >= 0 or
            index( $stmt->{cert_info}, sha384( $att_to_be_signed ) ) >= 0 or
            index( $stmt->{cert_info}, sha512( $att_to_be_signed ) ) >= 0 )
    {
        Web::Authn::Exception::InvalidRegistration->throw( 'TPM certInfo extraData did not contain hash of attToBeSigned' );
    }
    return(1);
}

# Apple WebAuthn Root CA is published by Apple. Callers should pass pem_root_certs
# for production verification. We do not embed the full CA blob here.
sub _apple_root { return }

sub _b64u
{
    my $s = Web::Authn::Parse::_plain( shift( @_ ) );
    $s =~ tr{-_}{+/};
    my $pad = ( 4 - length( $s ) % 4 ) % 4;
    $s .= '=' x $pad;
    return( decode_base64( $s ) );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Web::Authn::Attestation - Attestation statement format verifiers

=head1 SYNOPSIS

    Web::Authn::Attestation::verify(
        fmt                   => $att->{fmt},
        att_stmt              => $att->{att_stmt},
        auth_raw              => $att->{auth_raw},
        client_data_json      => $client_data_bytes,
        credential_public_key => $cose_bytes,
        credential_id         => $cred_id,
        aaguid                => $aaguid,
        rp_id_hash            => $rp_hash,
        pem_root_certs        => \@pem,
        attestation_object    => $raw_att_obj,
    );

=head1 DESCRIPTION

Called from L<Web::Authn/verify_registration_response> after authenticator data and client data have been checked. Each C<fmt> implements the verification procedure from WebAuthn §8.

You do not normally call this module yourself.

=head1 FUNCTIONS

You do not normally call these from application code. L<Web::Authn/verify_registration_response> already does. On failure each routine throws L<Web::Authn::Exception::InvalidRegistration>. On success it returns true.

=head2 sha384

    my $digest = Web::Authn::Attestation::sha384( $bytes );

Returns the SHA-384 digest of the bytes you pass. This is used when checking TPM C<extraData>.

=head2 sha512

    my $digest = Web::Authn::Attestation::sha512( $bytes );

Returns the SHA-512 digest of the bytes you pass. This is used when checking TPM C<extraData>.

=head2 verify

    Web::Authn::Attestation::verify(
        fmt                   => $att->{fmt},
        att_stmt              => $att->{att_stmt},
        auth_raw              => $att->{auth_raw},
        client_data_json      => $client_data_bytes,
        credential_public_key => $cose_bytes,
        credential_id         => $cred_id,
        aaguid                => $aaguid,
        rp_id_hash            => $rp_hash,
        pem_root_certs        => \@pem,
        attestation_object    => $raw_att_obj,
    );

Dispatches on C<fmt> to L</verify_none>, L</verify_packed>, L</verify_fido_u2f>, L</verify_apple>, L</verify_tpm>, L</verify_android_safetynet> or L</verify_android_key>. Throws if C<fmt> is unknown.

The format-specific routines take the same named arguments. Unused keys are ignored.

=over

=item C<aaguid>

This argument is optional for most formats; L</verify_fido_u2f> requires it and it must be 16 zero bytes. It is 16 raw bytes.

=item C<att_stmt>

This argument is required. It is a hash: the decoded attestation statement (C<sig>, C<alg>, C<x5c>, C<response>, C<certInfo>, C<pubArea>, and so on).

=item C<attestation_object>

This argument is optional. It is the raw bytes of the whole C<attestationObject>. L</verify_android_safetynet> uses it as one of the two nonce bases.

=item C<auth_raw>

This argument is required. It is the raw bytes of authenticator data. They are concatenated with C<SHA-256(clientDataJSON)> to form the signed payload.

=item C<client_data_json>

This argument is required. It is the raw bytes of C<clientDataJSON>.

=item C<credential_id>

This argument is optional for most formats; L</verify_fido_u2f> requires it. It is the raw bytes of the credential ID.

=item C<credential_public_key>

This argument is optional for C<none>. Packed self-attestation, Apple, and FIDO U2F require it. It is the raw COSE_Key bytes.

=item C<fmt>

This argument is required by L</verify>. It is a string: the attestation format name, one of C<none>, C<packed>, C<fido-u2f>, C<apple>, C<tpm>, C<android-safetynet>, or C<android-key>.

=item C<pem_root_certs>

This argument is optional. It is an array of PEM strings or DER bytes: roots used to pin C<x5c> chains. An empty array means “do not pin”, which is the same behaviour as py_webauthn.

=item C<rp_id_hash>

This argument is optional for most formats; L</verify_fido_u2f> requires it. It is the raw 32-byte SHA-256 of the RP ID.

=back

=head2 verify_android_key

    Web::Authn::Attestation::verify_android_key( %arg );

WebAuthn §8.4. Requires C<att_stmt.sig> and C<att_stmt.x5c>. Validates the chain when roots are supplied, then verifies C<sig> over C<authData || SHA-256(clientDataJSON)> with the leaf certificate key.

Named arguments: same as L</verify>.

=head2 verify_android_safetynet

    Web::Authn::Attestation::verify_android_safetynet( %arg );

WebAuthn §8.5. C<attStmt.response> is a JWS. Checks the JWT signature (RS256, C<x5c> in the header), C<ctsProfileMatch>, and that C<nonce> matches C<SHA-256(authData || SHA-256(clientDataJSON))> or C<SHA-256(attestationObject || SHA-256(clientDataJSON))>.

This format is deprecated in later WebAuthn drafts; it is still accepted for older authenticators.

Named arguments: same as L</verify>. C<attestation_object> is used as an alternative nonce base.

=head2 verify_apple

    Web::Authn::Attestation::verify_apple( %arg );

WebAuthn §8.8. Requires C<att_stmt.x5c>. Validates the chain, checks Apple extension C<1.2.840.113635.100.8.2> against C<SHA-256(authData || SHA-256(clientDataJSON))>, and that the leaf subject public key equals the credential public key.

This distribution does not embed the Apple WebAuthn Root CA. Pass it in C<pem_root_certs> for a pinned verification.

Named arguments: same as L</verify>.

=head2 verify_fido_u2f

    Web::Authn::Attestation::verify_fido_u2f( %arg );

WebAuthn §8.6. Requires exactly one certificate in C<x5c>, a signature, AAGUID all zeroes, and an EC2 credential key. Verifies ECDSA P-256 over C<0x00 || rpIdHash || clientDataHash || credId || 0x04 || X || Y>.

Named arguments: same as L</verify>. C<aaguid>, C<credential_id>, C<credential_public_key> and C<rp_id_hash> are required here.

=head2 verify_none

    Web::Authn::Attestation::verify_none( %arg );

WebAuthn §8.7. C<attStmt> must be empty. Typical for consumer passkeys when C<attestation> was C<none>.

Named arguments: same as L</verify>. Only C<att_stmt> is inspected.

=head2 verify_packed

    Web::Authn::Attestation::verify_packed( %arg );

WebAuthn §8.2. Requires C<att_stmt.sig> and C<att_stmt.alg>. Signed data is C<authData || SHA-256(clientDataJSON)>.

If C<x5c> is present (basic attestation), the leaf key verifies C<sig> after an optional chain check. If C<x5c> is absent (self-attestation), the credential public key verifies C<sig> and its COSE C<alg> must equal C<attStmt.alg>.

Named arguments: same as L</verify>. C<credential_public_key> is required for self-attestation.

=head2 verify_tpm

    Web::Authn::Attestation::verify_tpm( %arg );

WebAuthn §8.3. Requires C<att_stmt.sig>, C<x5c>, C<certInfo> and C<pubArea>.

Verifies C<sig> over C<certInfo> with the leaf key, then that C<certInfo> contains a SHA-256, SHA-384 or SHA-512 of C<authData || SHA-256(clientDataJSON)> (TPM C<extraData>).

This is not a full TPMS_ATTEST parser. It is enough to reject a statement that was not signed by the attested key and does not bind the WebAuthn data.

Named arguments: same as L</verify>.

=head1 THREAD & PROCESS SAFETY

This module is designed to be fully thread-safe and process-safe, ensuring data integrity across Perl ithreads and mod_perl’s threaded Multi-Processing Modules (MPMs) such as Worker or Event.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<https://www.w3.org/TR/webauthn-3/#sctn-defined-attestation-formats>,
L<Web::Authn>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
