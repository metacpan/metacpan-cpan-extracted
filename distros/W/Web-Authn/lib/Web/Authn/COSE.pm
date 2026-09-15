##----------------------------------------------------------------------------
## WebAuthn - ~/lib/Web/Authn/COSE.pm
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
package Web::Authn::COSE;
BEGIN
{
    use v5.16.0;
    use strict;
    use warnings;
    warnings::register_categories( 'Web::Authn' );
    use vars qw( $VERSION );
    use Exporter 'import';
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

our $VERSION = '0.001';
our @EXPORT_OK = qw(
    ECDSA_SHA_256 EDDSA ECDSA_SHA_384 ECDSA_SHA_512
    RSASSA_PSS_SHA_256 RSASSA_PSS_SHA_384 RSASSA_PSS_SHA_512
    RSASSA_PKCS1_SHA_256 RSASSA_PKCS1_SHA_384 RSASSA_PKCS1_SHA_512 RSASSA_PKCS1_SHA_1
    ML_DSA_44 ML_DSA_65 ML_DSA_87
    KTY_OKP KTY_EC2 KTY_RSA KTY_ML_DSA
    CRV_P256 CRV_P384 CRV_P521 CRV_ED25519
    KEY_KTY KEY_ALG KEY_CRV KEY_X KEY_Y KEY_N KEY_E KEY_PUB
    default_supported_algs alg_hash_name is_rsa_pkcs is_rsa_pss is_ecdsa
);

use constant {
    ECDSA_SHA_256         => -7,
    EDDSA                 => -8,
    ECDSA_SHA_384         => -35,
    ECDSA_SHA_512         => -36,
    RSASSA_PSS_SHA_256    => -37,
    RSASSA_PSS_SHA_384    => -38,
    RSASSA_PSS_SHA_512    => -39,
    RSASSA_PKCS1_SHA_256  => -257,
    RSASSA_PKCS1_SHA_384  => -258,
    RSASSA_PKCS1_SHA_512  => -259,
    RSASSA_PKCS1_SHA_1    => -65535,
    ML_DSA_44             => -48,
    ML_DSA_65             => -49,
    ML_DSA_87             => -50,

    KTY_OKP    => 1,
    KTY_EC2    => 2,
    KTY_RSA    => 3,
    KTY_ML_DSA => 7,

    CRV_P256    => 1,
    CRV_P384    => 2,
    CRV_P521    => 3,
    CRV_ED25519 => 6,

    KEY_KTY => 1,
    KEY_ALG => 3,
    KEY_CRV => -1,
    KEY_X   => -2,
    KEY_Y   => -3,
    KEY_N   => -1,
    KEY_E   => -2,
    KEY_PUB => -1,
};

sub default_supported_algs
{
    return( EDDSA, ECDSA_SHA_256, RSASSA_PKCS1_SHA_256 );
}

sub alg_hash_name
{
    my $alg = shift( @_ );
    return( 'SHA256' ) if( $alg == ECDSA_SHA_256 || $alg == RSASSA_PSS_SHA_256 || $alg == RSASSA_PKCS1_SHA_256 );
    return( 'SHA384' ) if( $alg == ECDSA_SHA_384 || $alg == RSASSA_PSS_SHA_384 || $alg == RSASSA_PKCS1_SHA_384 );
    return( 'SHA512' ) if( $alg == ECDSA_SHA_512 || $alg == RSASSA_PSS_SHA_512 || $alg == RSASSA_PKCS1_SHA_512 );
    return( 'SHA1' )   if( $alg == RSASSA_PKCS1_SHA_1 );
    return;
}

sub is_rsa_pkcs
{
    my $alg = shift( @_ );
    return( $alg == RSASSA_PKCS1_SHA_256 ||
            $alg == RSASSA_PKCS1_SHA_384 ||
            $alg == RSASSA_PKCS1_SHA_512 ||
            $alg == RSASSA_PKCS1_SHA_1 );
}

sub is_rsa_pss
{
    my $alg = shift( @_ );
    return( $alg == RSASSA_PSS_SHA_256 ||
            $alg == RSASSA_PSS_SHA_384 ||
            $alg == RSASSA_PSS_SHA_512 );
}

sub is_ecdsa
{
    my $alg = shift( @_ );
    return( $alg == ECDSA_SHA_256 || $alg == ECDSA_SHA_384 || $alg == ECDSA_SHA_512 );
}

sub curve_name
{
    my $crv = shift( @_ );
    return( 'secp256r1' ) if( $crv == CRV_P256 );
    return( 'secp384r1' ) if( $crv == CRV_P384 );
    return( 'secp521r1' ) if( $crv == CRV_P521 );
    return;
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Web::Authn::COSE - COSE algorithm, key-type and curve constants

=head1 SYNOPSIS

    use Web::Authn::COSE qw(EDDSA ECDSA_SHA_256 RSASSA_PKCS1_SHA_256);

    my $authn = Web::Authn->new( rp_id => 'example.com', rp_name => 'Ex' );
    $authn->generate_registration_options(
        user_name              => 'bob',
        supported_pub_key_algs => [ EDDSA, ECDSA_SHA_256 ],
    );

=head1 DESCRIPTION

IANA COSE / WebAuthn numeric identifiers. Export constants explicitly or call them as C<Web::Authn::COSE::NAME>.

=head1 CONSTANTS

Algorithms: C<ECDSA_SHA_256> (-7), C<EDDSA> (-8), C<ECDSA_SHA_384> (-35), C<ECDSA_SHA_512> (-36), C<RSASSA_PSS_SHA_256> (-37), C<RSASSA_PSS_SHA_384> (-38), C<RSASSA_PSS_SHA_512> (-39), C<RSASSA_PKCS1_SHA_256> (-257), C<RSASSA_PKCS1_SHA_384> (-258), C<RSASSA_PKCS1_SHA_512> (-259), C<RSASSA_PKCS1_SHA_1> (-65535), C<ML_DSA_44> (-48), C<ML_DSA_65> (-49), C<ML_DSA_87> (-50).

Key types: C<KTY_OKP> (1), C<KTY_EC2> (2), C<KTY_RSA> (3), C<KTY_ML_DSA> (7).

Curves: C<CRV_P256> (1), C<CRV_P384> (2), C<CRV_P521> (3), C<CRV_ED25519> (6).

COSE key labels: C<KEY_KTY> (1), C<KEY_ALG> (3), C<KEY_CRV> (-1), C<KEY_X> (-2), C<KEY_Y> (-3). RSA uses C<KEY_N>/C<KEY_E> at the same negative labels; ML-DSA uses C<KEY_PUB> at -1.

=head1 FUNCTIONS

=head2 alg_hash_name

    my $name = Web::Authn::COSE::alg_hash_name( -7 );  # SHA256

Maps a COSE algorithm identifier to the CryptX / Digest hash name used to verify signatures. Pass an integer such as C<-7> (ES256). The function returns C<undef> when the identifier is not a hash-based algorithm known to this module.

=head2 curve_name

    my $nist = Web::Authn::COSE::curve_name( 1 );  # secp256r1

Maps a COSE elliptic-curve identifier to the CryptX curve name. Pass an integer: C<1> is P-256, C<2> is P-384, C<3> is P-521. The function returns C<undef> for unknown curves, including Ed25519, which CryptX loads as C<Crypt::PK::Ed25519> instead.

=head2 default_supported_algs

    my @algs = Web::Authn::COSE::default_supported_algs();
    # (-8, -7, -257)

Returns the default list of COSE algorithm identifiers offered in registration options: EdDSA, ES256, and RS256. This function takes no arguments.

=head2 is_ecdsa

    if( Web::Authn::COSE::is_ecdsa( $alg ) ) { ... }

Returns true when the COSE algorithm identifier you pass is ES256, ES384 or ES512.

=head2 is_rsa_pkcs

    if( Web::Authn::COSE::is_rsa_pkcs( $alg ) ) { ... }

Returns true when the COSE algorithm identifier you pass is RS1, RS256, RS384 or RS512 (PKCS#1 v1.5).

=head2 is_rsa_pss

    if( Web::Authn::COSE::is_rsa_pss( $alg ) ) { ... }

Returns true when the COSE algorithm identifier you pass is PS256, PS384 or PS512.

=head1 THREAD & PROCESS SAFETY

This module is designed to be fully thread-safe and process-safe, ensuring data integrity across Perl ithreads and mod_perl’s threaded Multi-Processing Modules (MPMs) such as Worker or Event.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<https://www.iana.org/assignments/cose/cose.xhtml>, L<Web::Authn>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
