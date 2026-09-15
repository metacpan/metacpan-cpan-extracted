##----------------------------------------------------------------------------
## WebAuthn - ~/lib/Web/Authn/Crypto.pm
## Version v0.2.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/09/09
## Modified 2026/09/11
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Web::Authn::Crypto;
BEGIN
{
    use v5.16.0;
    use strict;
    use warnings;
    warnings::register_categories( 'Web::Authn' );
    use vars qw( $VERSION );
    use Digest::SHA qw( sha1 sha256 sha384 sha512 );
    use MIME::Base64 qw( encode_base64 decode_base64 );
    use Scalar::Util ();
    use Web::Authn::COSE;
    use Web::Authn::Exception;
    use Web::Authn::Parse;
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

my $_HAS_CRYPTX;

# Convert decoded COSE key hashref to a CryptX public key object.
sub cose_to_public_key
{
    my $decoded = shift( @_ );
    require_cryptx();
    my $kty = $decoded->{kty};
    if( $kty == Web::Authn::COSE::KTY_EC2 )
    {
        my $curve = Web::Authn::COSE::curve_name( $decoded->{crv} ) or 
            Web::Authn::Exception::UnsupportedAlgorithm->throw( 'unsupported EC curve' );
        # key2hash form: pub_x / pub_y are hex. Do not use the JWK form
        # (kty/crv/x/y): CryptX would treat x/y as base64url and decode them again.
        my $pk = Crypt::PK::ECC->new;
        $pk->import_key({
            curve_name => $curve,
            pub_x      => unpack( 'H*', $decoded->{'x'} ),
            pub_y      => unpack( 'H*', $decoded->{'y'} ),
        });
        return( $pk );
    }
    if( $kty == Web::Authn::COSE::KTY_RSA )
    {
        my $pk = Crypt::PK::RSA->new;
        $pk->import_key({
            kty => 'RSA',
            n   => unpack( 'H*', $decoded->{n} ),
            e   => unpack( 'H*', $decoded->{e} ),
        });
        return( $pk );
    }
    if( $kty == Web::Authn::COSE::KTY_OKP )
    {
        if( $decoded->{alg} != Web::Authn::COSE::EDDSA ||
            $decoded->{crv} != Web::Authn::COSE::CRV_ED25519 )
        {
            Web::Authn::Exception::UnsupportedAlgorithm->throw( 'only Ed25519 OKP keys are supported' );
        }
        return( Crypt::PK::Ed25519->new->import_key_raw($decoded->{'x'}, 'public' ) );
    }
    Web::Authn::Exception::UnsupportedAlgorithm->throw( "unsupported COSE kty $kty" );
}

sub export_spki_der
{
    my $pk = shift( @_ );
    return( $pk->export_key_der( 'public' ) );
}

sub extract_extension_octet
{
    my( $cert_der, $oid ) = @_;
    my $exts = _extensions( $cert_der ) or return;
    return( $exts->{$oid} );
}

# Minimal X.509 walk: Certificate ::= SEQUENCE { tbsCertificate, signatureAlgorithm, signature }
# tbsCertificate ::= SEQUENCE { version?, serial, sig, issuer, validity, subject, subjectPublicKeyInfo, ... }
sub extract_spki_from_cert
{
    my $der = Web::Authn::Parse::maybe_bytes( shift( @_ ) );
    my( $cert, $off ) = _asn1_read( $der, 0 );
    $cert->{tag} == 16 or
        Web::Authn::Exception::InvalidCertificateChain->throw( 'cert is not a SEQUENCE' );
    my $tbs = _first_seq( $cert->{value} );
    my @els = @{$tbs->{value}};
    # We skip optional [0] version
    my $i = 0;
    $i++ if( $els[0]->{cls} == 2 && $els[0]->{tag} == 0 );
    # serial, signature, issuer, validity, subject, spki
    $i += 5;
    my $spki = $els[$i] or
        Web::Authn::Exception::InvalidCertificateChain->throw( 'missing subjectPublicKeyInfo' );
    return( substr( $der, $spki->{start}, $spki->{len} ) );
}

sub public_key_from_cert_der
{
    my $cert_der = Web::Authn::Parse::maybe_bytes( shift( @_ ) );
    my $spki = extract_spki_from_cert( $cert_der );
    return( public_key_from_der_spki( $spki ) );
}

sub public_key_from_der_spki
{
    my $spki = Web::Authn::Parse::maybe_bytes( shift( @_ ) );
    require_cryptx();
    my $pem = _der_to_pem( $spki, 'PUBLIC KEY' );
    local $@;
    foreach my $class ( qw( Crypt::PK::ECC Crypt::PK::RSA Crypt::PK::Ed25519 ) )
    {
        my $pk = eval{ $class->new( \$pem ) };
        return( $pk ) if( $pk );
    }
    Web::Authn::Exception->throw( 'unable to load SubjectPublicKeyInfo' );
}

sub require_cryptx
{
    _cryptx() or Web::Authn::Exception->throw( 'Web::Authn requires CryptX (Crypt::PK::ECC/RSA/Ed25519) for signature verification' );
}

# In-process analogue of py_webauthn's OpenSSL.crypto.X509StoreContext.
# No openssl(1) subprocess. CryptX verifies each certificate signature;
# we parse issuer/subject/validity from DER ourselves.
sub validate_certificate_chain
{
    my( %arg ) = @_;
    my $x5c  = $arg{x5c} || [];
    my $pem_roots = $arg{pem_root_certs} || [];
    unless( @$x5c )
    {
        Web::Authn::Exception::InvalidCertificateChain->throw( 'empty x5c' );
    }

    local $@;
    my @chain;
    foreach my $c ( @$x5c )
    {
        my $parsed = eval{ _parse_certificate($c) };
        unless( $parsed )
        {
            Web::Authn::Exception::InvalidCertificateChain->throw( 'malformed certificate in x5c' );
        }
        push( @chain, $parsed );
    }

    # Same short-circuit as py_webauthn: no roots means "do not pin".
    return(1) unless( @$pem_roots );

    my @roots;
    foreach my $blob ( @$pem_roots )
    {
        $blob = $$blob if( ( Scalar::Util::reftype( $blob ) || '' ) eq 'SCALAR' );
        $blob = Web::Authn::Parse::_plain( $blob );
        foreach my $der ( _certs_from_blob( $blob ) )
        {
            my $parsed = eval{ _parse_certificate( $der ) };
            unless( $parsed )
            {
                Web::Authn::Exception::InvalidCertificateChain->throw( 'malformed root certificate' );
            }
            push( @roots, $parsed );
        }
    }
    unless( @roots )
    {
        Web::Authn::Exception::InvalidCertificateChain->throw( 'no usable root certificates' );
    }

    foreach my $i ( 0 .. $#chain - 1 )
    {
        unless( _verify_issued_by( $chain[ $i ], $chain[ $i + 1 ] ) )
        {
            Web::Authn::Exception::InvalidCertificateChain->throw( 'intermediate certificate chain signature failed' );
        }
    }

    my $end = $chain[-1];
    foreach my $root ( @roots )
    {
        return(1) if( _same_cert( $end, $root ) );
        return(1) if( _verify_issued_by( $end, $root ) );
    }
    Web::Authn::Exception::InvalidCertificateChain->throw( 'Certificate chain could not be validated against supplied roots' );
}

sub verify_signature
{
    my( %arg ) = @_;
    my $pk     = $arg{public_key};
    my $alg    = $arg{alg};
    my $sig    = Web::Authn::Parse::maybe_bytes( $arg{signature} );
    my $data   = Web::Authn::Parse::maybe_bytes( $arg{data} );
    unless( defined( $pk ) && defined( $sig ) && defined( $data ) )
    {
        Web::Authn::Exception->throw( 'verify_signature missing arguments' );
    }

    if( Web::Authn::COSE::is_ecdsa( $alg ) )
    {
        my $hash = Web::Authn::COSE::alg_hash_name( $alg );
        # CryptX expects DER ECDSA signatures, which WebAuthn uses.
        $pk->verify_message( $sig, $data, $hash ) or
            Web::Authn::Exception->throw( 'ECDSA signature verification failed' );
        return(1);
    }
    if( $alg == Web::Authn::COSE::EDDSA )
    {
        $pk->verify_message( $sig, $data ) or
            Web::Authn::Exception->throw( 'EdDSA signature verification failed' );
        return(1);
    }
    if( Web::Authn::COSE::is_rsa_pkcs( $alg ) )
    {
        my $hash = Web::Authn::COSE::alg_hash_name( $alg );
        $pk->verify_message( $sig, $data, $hash, 'v1.5' ) or
            Web::Authn::Exception->throw( 'RSA PKCS1 signature verification failed' );
        return(1);
    }
    if( Web::Authn::COSE::is_rsa_pss( $alg ) )
    {
        my $hash = Web::Authn::COSE::alg_hash_name( $alg );
        $pk->verify_message( $sig, $data, $hash, 'pss' ) or
            Web::Authn::Exception->throw( 'RSA-PSS signature verification failed' );
        return(1);
    }
    Web::Authn::Exception::UnsupportedAlgorithm->throw( "unsupported signature alg $alg" );
}

sub _alg_oid
{
    my( $alg_node ) = @_;
    return('') unless( $alg_node && $alg_node->{cons} );
    my $oid_node = $alg_node->{value}->[0];
    return( _decode_oid( $oid_node->{value} ) );
}

# NOTE: tiny DER reader
sub _asn1_read
{
    my( $buf, $off ) = @_;
    unless( $off < length( $buf ) )
    {
        Web::Authn::Exception::InvalidStructure->throw( 'truncated DER' );
    }
    my $start = $off;
    my $ib    = unpack( 'C', substr( $buf, $off, 1 ) );
    $off++;
    my $cls   = ( $ib >> 6 ) & 3;
    my $cons  = ( $ib >> 5 ) & 1;
    my $tag   = $ib & 31;
    if( $tag == 31 )
    {
        $tag = 0;
        while(1)
        {
            unless( $off < length( $buf ) )
            {
                Web::Authn::Exception::InvalidStructure->throw( 'truncated DER tag' );
            }
            my $b = unpack( 'C', substr( $buf, $off, 1 ) );
            $off++;
            $tag = ( $tag << 7 ) | ( $b & 0x7f );
            last unless( $b & 0x80 );
        }
    }

    unless( $off < length( $buf ) )
    {
        Web::Authn::Exception::InvalidStructure->throw( 'truncated DER len' );
    }

    my $lb = unpack( 'C', substr( $buf, $off, 1 ) );
    $off++;
    my $len;
    if( $lb < 128 )
    {
        $len = $lb;
    }
    else
    {
        my $n = $lb & 0x7f;
        unless( $off + $n <= length( $buf ) )
        {
            Web::Authn::Exception::InvalidStructure->throw( 'truncated DER len' );
        }
        $len = 0;
        for( 1 .. $n )
        {
            $len = ( $len << 8 ) + unpack( 'C', substr( $buf, $off, 1 ) );
            $off++
        }
    }

    unless( $off + $len <= length( $buf ) )
    {
        Web::Authn::Exception::InvalidStructure->throw( 'truncated DER value' );
    }

    my $val = substr( $buf, $off, $len );
    my $end = $off + $len;
    my $node =
    {
        cls   => $cls,
        tag   => $tag,
        cons  => $cons,
        value => $val,
        start => $start,
        len   => $end - $start
    };
    if( $cons )
    {
        my @kids;
        my $p = 0;
        while( $p < length( $val ) )
        {
            my( $kid, $no ) = _asn1_read( $val, $p );
            # Rewrite start relative to original buffer
            $kid->{start} = $off + $kid->{start};
            push( @kids, $kid );
            $p = $no;
        }
        $node->{value} = \@kids;
    }
    return( $node, $end );
}

sub _asn1_time
{
    my $node = shift( @_ );
    unless( $node )
    {
        Web::Authn::Exception::InvalidCertificateChain->throw( 'missing certificate time field' );
    }
    my $s = defined( $node->{value} ) ? $node->{value} : '';
    $s =~ s/Z\z//;
    if( $node->{tag} == 23 && $s =~ /^(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/ )
    {
        my $year = $1 < 50 ? 2000 + $1 : 1900 + $1;  # RFC 5280 UTCTime
        return( _timegm( $year, $2, $3, $4, $5, $6 ) );
    }
    if( $node->{tag} == 24 && $s =~ /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/ )
    {
        return( _timegm( $1, $2, $3, $4, $5, $6 ) );
    }
    my $tag = defined( $node->{tag} ) ? $node->{tag} : '?';
    Web::Authn::Exception::InvalidCertificateChain->throw(
        sprintf( 'unparseable certificate time (tag %s, value %s)', $tag, unpack( 'H*', $s ) )
    );
}

sub _certs_from_blob
{
    my $blob = shift( @_ );
    return unless( defined( $blob ) && length( $blob ) );
    if( $blob =~ /-----BEGIN [A-Z0-9 ]*CERTIFICATE-----/ )
    {
        my @out;
        while( $blob =~ /-----BEGIN [A-Z0-9 ]*CERTIFICATE-----\s*([A-Za-z0-9\/+=\r\n]+)-----END [A-Z0-9 ]*CERTIFICATE-----/g )
        {
            my $b64 = $1;
            $b64 =~ s/\s+//g;
            push( @out, decode_base64( $b64 ) );
        }
        return( @out );
    }
    return( $blob );
}

sub _check_validity
{
    my $cert = shift( @_ );
    my $now = time;
    return(0) if( defined( $cert->{not_before} ) && $now < $cert->{not_before} );
    return(0) if( defined( $cert->{not_after} ) && $now > $cert->{not_after} );
    return(1);
}

sub _cryptx
{
    return( $_HAS_CRYPTX ) if( defined( $_HAS_CRYPTX ) );
    local $@;
    $_HAS_CRYPTX = eval
    {
        require Crypt::PK::ECC;
        require Crypt::PK::RSA;
        require Crypt::PK::Ed25519;
        1;
    } ? 1 : 0;
    return( $_HAS_CRYPTX );
}

sub _decode_oid
{
    my $raw = shift( @_ );
    return( '' ) unless( defined( $raw ) && length( $raw ) );
    my $first = unpack( 'C', substr( $raw, 0, 1 ) );
    my @ids = ( int( $first / 40 ), $first % 40 );
    my $acc = 0;
    foreach my $i ( 1 .. length( $raw ) - 1 )
    {
        my $b = unpack( 'C', substr( $raw, $i, 1 ) );
        $acc = ( $acc << 7 ) | ( $b & 0x7f );
        if( !( $b & 0x80 ) )
        {
            push( @ids, $acc );
            $acc = 0;
        }
    }
    return( join( '.', @ids ) );
}

sub _der_to_pem
{
    my( $der, $type ) = @_;
    my $b64 = encode_base64( $der, '' );
    $b64 =~ s/(.{64})/$1\n/g;
    $b64 .= "\n" unless( $b64 =~ /\n\z/ );
    return( "-----BEGIN $type-----\n$b64-----END $type-----\n" );
}

sub _extensions
{
    my $der = shift( @_ );
    my( $cert ) = _asn1_read( $der, 0 );
    my $tbs = _first_seq( $cert->{value} );
    my %oid_to_val;
    foreach my $el ( @{$tbs->{value}} )
    {
        next unless( $el->{cls} == 2 && $el->{tag} == 3 );  # [3] extensions
        my( $exts_seq ) = _asn1_read( $el->{value}, 0 );
        foreach my $ext ( @{$exts_seq->{value}} )
        {
            my @f   = @{$ext->{value}};
            my $oid = _decode_oid( $f[0]->{value} );
            my $val = $f[-1]->{value};  # extnValue OCTET STRING
            $oid_to_val{ $oid } = $val;
        }
    }
    return( \%oid_to_val );
}

sub _first_seq
{
    my $kids = shift( @_ );
    foreach my $k ( @$kids )
    {
        return( $k ) if( $k->{tag} == 16 );
    }
    return( $kids->[0] );
}

# Certificate ::= SEQUENCE { tbsCertificate, signatureAlgorithm, signatureValue }
sub _parse_certificate
{
    my $der = shift( @_ );
    my( $top ) = _asn1_read( $der, 0 );
    $top->{tag} == 16 or
        Web::Authn::Exception::InvalidCertificateChain->throw( 'cert is not a SEQUENCE' );
    my @el = @{ $top->{value} };
    unless( @el >= 3 )
    {
        Web::Authn::Exception::InvalidCertificateChain->throw( 'truncated certificate' );
    }

    my $tbs_node = $el[0];
    my $alg_node = $el[1];
    my $sig_node = $el[2];
    my $tbs_der  = substr( $der, $tbs_node->{start}, $tbs_node->{len} );

    my $oid = _alg_oid($alg_node);
    my $sig_alg = _sigalg_from_oid( $oid ) or
        Web::Authn::Exception::InvalidCertificateChain->throw( "unsupported certificate signature OID $oid" );

    my $sig = $sig_node->{value};
    # BIT STRING: first octet is unused-bit count
    if( !$sig_node->{cons} && length( $sig ) )
    {
        $sig = substr( $sig, 1 );
    }

    my @tbs = @{$tbs_node->{value}};
    my $ti  = 0;
    $ti++ if( $tbs[0]->{cls} == 2 && $tbs[0]->{tag} == 0 );  # version
    $ti++;  # serial
    $ti++;  # inner signature alg
    my $issuer_node   = $tbs[ $ti++ ];
    my $validity_node = $tbs[ $ti++ ];
    my $subject_node  = $tbs[ $ti++ ];

    my( $nb, $na ) = _validity_times( $validity_node );

    return({
        der        => $der,
        tbs        => $tbs_der,
        sig        => $sig,
        sig_alg    => $sig_alg,
        issuer     => substr( $der, $issuer_node->{start}, $issuer_node->{len} ),
        subject    => substr( $der, $subject_node->{start}, $subject_node->{len} ),
        not_before => $nb,
        not_after  => $na,
    });
}

sub _same_cert
{
    my( $a, $b ) = @_;
    return(0) unless( $a && $b );
    return(1) if( $a->{der} eq $b->{der} );
    return(1) if( $a->{tbs} eq $b->{tbs} );
    return(0);
}

sub _sigalg_from_oid
{
    my $oid = shift( @_ );
    return( ['rsa',     'SHA1'] )   if( $oid eq '1.2.840.113549.1.1.5' );
    return( ['rsa',     'SHA224'] ) if( $oid eq '1.2.840.113549.1.1.14' );
    return( ['rsa',     'SHA256'] ) if( $oid eq '1.2.840.113549.1.1.11' );
    return( ['rsa',     'SHA384'] ) if( $oid eq '1.2.840.113549.1.1.12' );
    return( ['rsa',     'SHA512'] ) if( $oid eq '1.2.840.113549.1.1.13' );
    return( ['rsa-pss', 'SHA256'] ) if( $oid eq '1.2.840.113549.1.1.10' );
    return( ['ecdsa',   'SHA1'] )   if( $oid eq '1.2.840.10045.4.1' );
    return( ['ecdsa',   'SHA224'] ) if( $oid eq '1.2.840.10045.4.3.1' );
    return( ['ecdsa',   'SHA256'] ) if( $oid eq '1.2.840.10045.4.3.2' );
    return( ['ecdsa',   'SHA384'] ) if( $oid eq '1.2.840.10045.4.3.3' );
    return( ['ecdsa',   'SHA512'] ) if( $oid eq '1.2.840.10045.4.3.4' );
    return( ['ed25519', undef] )    if( $oid eq '1.3.101.112' );
    return;
}

sub _timegm
{
    my( $Y, $M, $D, $h, $m, $s ) = @_;
    $Y = int( $Y );
    $M = int( $M );
    $D = int( $D );
    $h = int( $h );
    $m = int( $m );
    $s = int( $s );
    unless( $Y >= 1950 && $Y <= 9999 &&
            $M >= 1 && $M <= 12 &&
            $D >= 1 && $D <= 31 &&
            $h >= 0 && $h <= 23 &&
            $m >= 0 && $m <= 59 &&
            $s >= 0 && $s <= 60 )
    {
        Web::Authn::Exception::InvalidCertificateChain->throw(
            sprintf( 'invalid certificate time %04d-%02d-%02dT%02d:%02d:%02dZ', $Y, $M, $D, $h, $m, $s )
        );
    }
    require Time::Local;
    my $epoch;
    local $@;
    if( Time::Local->can( 'timegm_modern' ) )
    {
        $epoch = eval
        {
            Time::Local::timegm_modern( $s, $m, $h, $D, $M - 1, $Y );
        };
    }
    else
    {
        $epoch = eval
        {
            Time::Local::timegm( $s, $m, $h, $D, $M - 1, $Y );
        };
    }
    if( $@ || !defined( $epoch ) )
    {
        my $why = $@ ? "$@" : 'undefined epoch';
        $why =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//;
        Web::Authn::Exception::InvalidCertificateChain->throw(
            sprintf( 'invalid certificate time %04d-%02d-%02dT%02d:%02d:%02dZ: %s', $Y, $M, $D, $h, $m, $s, $why )
        );
    }
    return( $epoch );
}

sub _validity_times
{
    my $node = shift( @_ );
    return unless( $node && $node->{cons} && @{$node->{value}} >= 2 );
    return( _asn1_time( $node->{value}->[0] ), _asn1_time( $node->{value}->[1] ) );
}

# Child must name issuer as parent.subject and carry a valid signature by parent.
sub _verify_issued_by
{
    my( $child, $parent ) = @_;
    return(0) unless( $child && $parent );
    return(0) unless( $child->{issuer} eq $parent->{subject} );
    _check_validity( $child ) or return(0);
    local $@;
    my $pk = eval{ public_key_from_cert_der( $parent->{der} ) } or return(0);
    my( $alg, $hash ) = @{$child->{sig_alg} || []};
    return(0) unless( $alg );
    my $rv = eval
    {
        if( $alg eq 'ed25519' )
        {
            $pk->verify_message( $child->{sig}, $child->{tbs} );
        }
        elsif( $alg eq 'rsa-pss' )
        {
            $pk->verify_message( $child->{sig}, $child->{tbs}, $hash, 'pss' );
        }
        else
        {
            $pk->verify_message( $child->{sig}, $child->{tbs}, $hash );
        }
    };
    return( $rv ? 1 : 0 );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Web::Authn::Crypto - CryptX signatures and in-process X.509 chain checks

=head1 SYNOPSIS

    my $pk = Web::Authn::Crypto::cose_to_public_key($decoded_cose);
    Web::Authn::Crypto::verify_signature(
        public_key => $pk,
        alg        => $decoded_cose->{alg},
        signature  => $sig,
        data       => $auth_data . $client_data_hash,
    );

    Web::Authn::Crypto::validate_certificate_chain(
        x5c            => $att_stmt->{x5c},
        pem_root_certs => \@roots,
    );

=head1 DESCRIPTION

Thin layer over L<Crypt::PK::ECC>, L<Crypt::PK::RSA> and L<Crypt::PK::Ed25519>. Also parses X.509 certificates enough to verify that an C<x5c> chain is signed back to RP-supplied roots B<without> spawning C<openssl(1)>. That matches py_webauthn's use of C<OpenSSL.crypto.X509StoreContext>, implemented with CryptX for the signatures and a small DER walker for names and validity.

If C<pem_root_certs> is empty, chain pinning is skipped (same as py_webauthn).

=head1 FUNCTIONS

=head2 cose_to_public_key

    my $decoded = Web::Authn::Parse::decode_credential_public_key( $cose );
    my $pk = Web::Authn::Crypto::cose_to_public_key( $decoded );

Builds a CryptX public-key object (C<Crypt::PK::ECC>, C<Crypt::PK::RSA> or C<Crypt::PK::Ed25519>) from a decoded COSE key. Pass the hash returned by L<Web::Authn::Parse/decode_credential_public_key> (C<kty>, C<alg>, and the type-specific fields).

=head2 export_spki_der

    my $der = Web::Authn::Crypto::export_spki_der( $pk );

Takes a CryptX public-key object.

Exports a CryptX public key as SubjectPublicKeyInfo DER.

=head2 extract_extension_octet

    my $raw = Web::Authn::Crypto::extract_extension_octet(
        $x5c[0], '1.2.840.113635.100.8.2',
    );

Used for Apple's nonce extension C<1.2.840.113635.100.8.2>.

Returns the OCTET STRING value of an X.509 extension, or C<undef> if the OID is absent. Used for Apple's nonce extension C<1.2.840.113635.100.8.2>.

=over

=item C<$cert_der>

This argument is required. It is the raw DER bytes of the certificate.

=item C<$oid>

This argument is required. It is a string containing a dotted OID, for example C<1.2.840.113635.100.8.2>.

=back

=head2 extract_spki_from_cert

    my $spki = Web::Authn::Crypto::extract_spki_from_cert( $der );

Walks a certificate DER and returns the SubjectPublicKeyInfo bytes. Pass the raw DER bytes of an X.509 certificate, or an object that overloads stringification.

=head2 public_key_from_cert_der

    my $pk = Web::Authn::Crypto::public_key_from_cert_der( $x5c[0] );

Loads the subject public key from a certificate. It extracts SubjectPublicKeyInfo and hands it to L</public_key_from_der_spki>. Pass the raw DER bytes of an X.509 certificate, or an object that overloads stringification.

=head2 public_key_from_der_spki

    my $pk = Web::Authn::Crypto::public_key_from_der_spki( $spki );

Loads a CryptX public key from SubjectPublicKeyInfo DER. It tries ECC, then RSA, then Ed25519. Pass the raw DER bytes, or an object that overloads stringification.

=head2 require_cryptx

    Web::Authn::Crypto::require_cryptx();

Throws unless the CryptX PK modules (C<Crypt::PK::ECC>, C<Crypt::PK::RSA>, C<Crypt::PK::Ed25519>) load. This function takes no arguments.

=head2 validate_certificate_chain

    Web::Authn::Crypto::validate_certificate_chain(
        x5c            => $att_stmt->{x5c},
        pem_root_certs => \@roots,
    );

Parses each certificate, checks issuer/subject chaining, notBefore/notAfter, and the signature of cert I<i> under cert I<i+1>'s key, then the last cert under a supplied root. Roots may be PEM (one or more C<BEGIN CERTIFICATE> blocks) or raw DER.

If C<pem_root_certs> is empty, chain pinning is skipped (the same behaviour as py_webauthn). This is not a full RFC 5280 path builder: there are no name constraints, policy OIDs, or CRLs.

=over

=item C<pem_root_certs>

This argument is optional. It is an array of PEM strings, DER bytes, or scalar references to the same: the trusted roots. It defaults to an empty array.

=item C<x5c>

This argument is required. It is an array of certificate DER blobs from the attestation statement, leaf first.

=back

=head2 verify_signature

    Web::Authn::Crypto::verify_signature(
        public_key => $pk,
        alg        => -7,
        signature  => $sig,
        data       => $auth_data . sha256( $client_data_json ),
    );

Verifies C<signature> over C<data> with C<public_key> using the COSE algorithm C<alg>. When walking certificate chains, the following signature OIDs are understood: RSA PKCS#1 SHA-1/224/256/384/512, RSA-PSS, ECDSA SHA-1/224/256/384/512, and Ed25519.

This is not a full RFC 5280 path builder (no name constraints, policy OIDs, or CRLs).

=over

=item C<alg>

This argument is required. It is an integer: the COSE algorithm identifier (for example C<-7> for ES256).

=item C<data>

This argument is required. It is the raw bytes of the signed payload.

=item C<public_key>

This argument is required. It is a CryptX public-key object from L</cose_to_public_key> or L</public_key_from_cert_der>.

=item C<signature>

This argument is required. It is raw bytes: a DER ECDSA signature, a raw Ed25519 signature, or an RSA signature as produced by the authenticator.

=back

=head1 THREAD & PROCESS SAFETY

This module is designed to be fully thread-safe and process-safe, ensuring data integrity across Perl ithreads and mod_perl’s threaded Multi-Processing Modules (MPMs) such as Worker or Event.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<CryptX>, L<Web::Authn::Attestation>, L<Web::Authn>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
