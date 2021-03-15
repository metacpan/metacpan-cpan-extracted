use strict;
use warnings;

use Test::More tests => 115;
use XML::Sig;
use File::Which;

my @hash_alg = qw/sha1 sha224 sha256 sha384 sha512/;
foreach my $alg (@hash_alg) {
    my $sig = XML::Sig->new( {
        digest_hash    => $alg,
        x509        => 1,
        key         => 't/dsa.private.key',
    } );
    isa_ok( $sig, 'XML::Sig' );

    my $signed = $sig->sign('<foo ID="123"></foo>');
    ok($signed, "XML Signed Sucessfully using dsa key");

    $sig = XML::Sig->new( );
    my $is_valid = $sig->verify( $signed );
    ok( $is_valid == 1, "XML::Sig signed Validated using X509Certificate");

SKIP: {
    skip "xmlsec1 not installed", 2 unless which('xmlsec1');

    ok( (open XML, '>', "t/tmp.xml"), "File t/tmp.xml opened for write");
    print XML $signed;
    close XML;

    my $verify_response = `xmlsec1 --verify --id-attr:ID "foo" t/tmp.xml 2>&1`;
    ok( $verify_response =~ m/^OK/, "t/tmp.xml is verified using xmlsec1" )
        or warn "calling xmlsec1 failed: '$verify_response'\n";
    unlink "t/tmp.xml";
    }
}

foreach my $alg (@hash_alg) {
    my $sig = XML::Sig->new( {
        digest_hash    => $alg,
        key         => 't/rsa.private.key',
    } );
    isa_ok( $sig, 'XML::Sig' );

    my $signed = $sig->sign('<foo ID="123"></foo>');
    ok($signed, "XML Signed Sucessfully using rsa key - no X509");

    $sig = XML::Sig->new( );
    my $is_valid = $sig->verify( $signed );
    ok( $is_valid == 1, "XML::Sig signed Validated - no X509");

SKIP: {
    skip "xmlsec1 not installed", 2 unless which('xmlsec1');

    ok( (open XML, '>', "t/tmp.xml"), "File opened for write");
    print XML $signed;
    close XML;

    my $verify_response = `xmlsec1 --verify --pubkey-cert-pem t/rsa.cert.pem --untrusted-pem t/intermediate.pem --trusted-pem t/cacert.pem --id-attr:ID "foo" t/tmp.xml 2>&1`;
    ok( $verify_response =~ m/^OK/, "t/tmp.xml RSA is verified using xmlsec1 - no X509" )
        or warn "calling xmlsec1 failed: '$verify_response'\n";
    unlink "t/tmp.xml";

    }
}

foreach my $alg (@hash_alg) {
    my $sig = XML::Sig->new( {
        digest_hash    => $alg,
        x509        => 1,
        key         => 't/rsa.private.key',
        cert        => 't/rsa.cert.pem'
    } );
    isa_ok( $sig, 'XML::Sig' );

    my $signed = $sig->sign('<foo ID="123"></foo>');
    ok($signed, "XML Signed Sucessfully using rsa key");

    $sig = XML::Sig->new( );
    my $is_valid = $sig->verify( $signed );
    ok( $is_valid == 1, "XML::Sig signed Validated");

SKIP: {
    skip "xmlsec1 not installed", 2 unless which('xmlsec1');

    ok( (open XML, '>', "t/tmp.xml"), "File opened for write");
    print XML $signed;
    close XML;

    my $verify_response = `xmlsec1 --verify --pubkey-cert-pem t/rsa.cert.pem --untrusted-pem t/intermediate.pem --trusted-pem t/cacert.pem --id-attr:ID "foo" t/tmp.xml 2>&1`;
    ok( $verify_response =~ m/^OK/, "t/tmp.xml RSA is verified using xmlsec1" )
        or warn "calling xmlsec1 failed: '$verify_response'\n";
    unlink "t/tmp.xml";

    }
}

# Signatures for ECDSA based keys
foreach my $alg (@hash_alg) {
    my $sig = XML::Sig->new( { x509 => 1 , digest_hash => $alg, key => 't/ecdsa.private.pem', cert => 't/ecdsa.public.pem' } );
    isa_ok( $sig, 'XML::Sig' );

    my $signed = $sig->sign('<foo ID="123"></foo>');
    ok($signed, "XML Signed Sucessfully using ecdsa key");

    $sig = XML::Sig->new( );
    my $is_valid = $sig->verify( $signed );
    ok( $is_valid == 1, "XML::Sig signed Validated using X509Certificate");

    SKIP: {
        skip "xmlsec1 not installed", 2 unless which('xmlsec1');

        ok( (open XML, '>', "t/tmp.xml"), "File opened for write");
        print XML $signed;
        close XML;

        my $verify_response = `xmlsec1 --verify --trusted-pem t/ecdsa.public.pem --id-attr:ID "foo" t/tmp.xml 2>&1`;
        ok( $verify_response =~ m/^OK/, "ECDSA Response is verified using xmlsec1" )
            or warn "calling xmlsec1 failed: '$verify_response'\n";
        if ($verify_response =~ m/^OK/) {
         #   unlink 't/tmp.xml';
        } else{
            print $signed;
            die;
        }
    }

    $sig = XML::Sig->new( { key => 't/ecdsa.private.pem' } );
    isa_ok( $sig, 'XML::Sig' );

    $signed = $sig->sign('<foo ID="123"></foo>');
    ok($signed, "XML Signed Sucessfully using ecdsa key");

    $sig = XML::Sig->new( );
    $is_valid = $sig->verify( $signed );
    ok( $is_valid == 1, "XML::Sig signed Validated using ECDSAKey");
}

done_testing;
