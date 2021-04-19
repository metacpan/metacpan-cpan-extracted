use strict;
use warnings;

use Test::More tests => 1224;
use XML::Sig;
use File::Which;

my @hash = qw/sha1 sha224 sha256 sha384 sha512 ripemd160/;
foreach my $sigalg (@hash) {
    # DSA Keys with noX509
    foreach my $digalg (@hash) {
        my $sig = XML::Sig->new( {
            digest_hash => $digalg,
            sig_hash    => $sigalg,
            x509        => 0,
            key         => 't/dsa.private.key',
        } );
        isa_ok( $sig, 'XML::Sig' );

        my $signed = $sig->sign('<foo ID="123"></foo>');
        ok($signed, "XML Signed Sucessfully using dsa-$sigalg digest: $digalg");

        $sig = XML::Sig->new( );
        my $is_valid = $sig->verify( $signed );
        ok( $is_valid == 1, "XML::Sig signed Validated using X509Certificate");

        SKIP: {
            skip "xmlsec1 not installed", 2 unless which('xmlsec1');

            ok( (open XML, '>', "t/tmp-dsa-$sigalg-nox509-$digalg.xml"), "File t/tmp-dsa-$sigalg-nox509-$digalg.xml opened for write");
            print XML $signed;
            close XML;

            my $verify_response = `xmlsec1 --verify --id-attr:ID "foo" t/tmp-dsa-$sigalg-nox509-$digalg.xml 2>&1`;
            ok( $verify_response =~ m/^OK/, "t/tmp-dsa-$sigalg-nox509-$digalg.xml is verified using xmlsec1" )
                or warn "calling xmlsec1 failed: '$verify_response'\n";
            unlink "t/tmp-dsa-$sigalg-nox509-$digalg.xml";
        }
    }

    # DSA Keys with noX509
    foreach my $digalg (@hash) {
        my $sig = XML::Sig->new( {
            digest_hash => $digalg,
            sig_hash    => $sigalg,
            x509        => 1,
            cert        => 't/dsa.public.pem',
            key         => 't/dsa.private.key',
        } );
        isa_ok( $sig, 'XML::Sig' );

        my $signed = $sig->sign('<foo ID="123"></foo>');
        ok($signed, "XML Signed Sucessfully using dsa-$sigalg digest: $digalg");

        $sig = XML::Sig->new( );
        my $is_valid = $sig->verify( $signed );
        ok( $is_valid == 1, "XML::Sig signed Validated using X509Certificate");

        SKIP: {
            skip "xmlsec1 not installed", 2 unless which('xmlsec1');

            ok( (open XML, '>', "t/tmp-dsa-$sigalg-x509-$digalg.xml"), "File t/tmp-dsa-$sigalg-x509-$digalg.xml opened for write");
            print XML $signed;
            close XML;

            my $verify_response = `xmlsec1 --verify --id-attr:ID "foo" --pubkey-cert-pem t/dsa.public.pem --trusted-pem t/dsa.public.pem t/tmp-dsa-$sigalg-x509-$digalg.xml 2>&1`;
            ok( $verify_response =~ m/^OK/, "t/tmp-dsa-$sigalg-x509-$digalg.xml is verified using xmlsec1" )
                or warn "calling xmlsec1 failed: '$verify_response'\n";
            if ($verify_response =~ m/^OK/) {
                unlink "t/tmp-dsa-$sigalg-x509-$digalg.xml";
            } else{
                print $signed;
                die;
            }
        }
    }

    # RSA Keys with no X509
    foreach my $digalg (@hash) {
        my $sig = XML::Sig->new( {
            digest_hash    => $digalg,
            sig_hash    => $sigalg,
            key         => 't/rsa.private.key',
        } );
        isa_ok( $sig, 'XML::Sig' );

        my $signed = $sig->sign('<foo ID="123"></foo>');
        ok($signed, "XML Signed Successfully using rsa-$sigalg - no X509 digest: $digalg");

        $sig = XML::Sig->new( );
        my $is_valid = $sig->verify( $signed );
        ok( $is_valid == 1, "XML::Sig signed Validated -no X509");

        SKIP: {
            skip "xmlsec1 not installed", 2 unless which('xmlsec1');

            ok( (open XML, '>', "t/tmp-rsa-$sigalg-nox509-$digalg.xml"), "File opened for write");
            print XML $signed;
            close XML;

            my $verify_response = `xmlsec1 --verify --pubkey-cert-pem t/rsa.cert.pem --untrusted-pem t/intermediate.pem --trusted-pem t/cacert.pem --id-attr:ID "foo" t/tmp-rsa-$sigalg-nox509-$digalg.xml 2>&1`;
            ok( $verify_response =~ m/^OK/, "t/tmp-rsa-$sigalg-nox509-$digalg.xml RSA is verified using xmlsec1 - no X509" )
                or warn "calling xmlsec1 failed: '$verify_response'\n";
            unlink "t/tmp-rsa-$sigalg-nox509-$digalg.xml";

       }
    }

    # RSA Keys with X509
    foreach my $digalg (@hash) {
        my $sig = XML::Sig->new( {
            digest_hash    => $digalg,
            sig_hash    => $sigalg,
            x509        => 1,
            key         => 't/rsa.private.key',
            cert        => 't/rsa.cert.pem'
        } );
        isa_ok( $sig, 'XML::Sig' );

        my $signed = $sig->sign('<foo ID="123"></foo>');
        ok($signed, "XML Signed Successfully using rsa-$sigalg, digest: $digalg");

        $sig = XML::Sig->new( );
        my $is_valid = $sig->verify( $signed );
        ok( $is_valid == 1, "XML::Sig signed Validated");

        SKIP: {
            skip "xmlsec1 not installed", 2 unless which('xmlsec1');

            ok( (open XML, '>', "t/tmp-rsa-$sigalg-x509-$digalg.xml"), "File opened for write");
            print XML $signed;
            close XML;

            my $verify_response = `xmlsec1 --verify --pubkey-cert-pem t/rsa.cert.pem --untrusted-pem t/intermediate.pem --trusted-pem t/cacert.pem --id-attr:ID "foo" t/tmp-rsa-$sigalg-x509-$digalg.xml 2>&1`;
            ok( $verify_response =~ m/^OK/, "t/tmp-rsa-$sigalg-x509-$digalg.xml RSA is verified using xmlsec1" )
                or warn "calling xmlsec1 failed: '$verify_response'\n";
            unlink "t/tmp-rsa-$sigalg-x509-$digalg.xml";

        }
    }

    # ECDSA based keys with X509
    foreach my $digalg (@hash) {
        my $sig = XML::Sig->new( {
                    x509 => 1,
                    digest_hash => $digalg,
                    sig_hash    => $sigalg,
                    key => 't/ecdsa.private.pem',
                    cert => 't/ecdsa.public.pem' } );
        isa_ok( $sig, 'XML::Sig' );

        my $signed = $sig->sign('<foo ID="123"></foo>');
        ok($signed, "XML Signed Successfully using ecdsa-$sigalg, digest: $digalg");

        $sig = XML::Sig->new( );
        my $is_valid = $sig->verify( $signed );
        ok( $is_valid == 1, "XML::Sig signed Validated using X509Certificate");

        SKIP: {
            skip "xmlsec1 not installed", 2 unless which('xmlsec1');
            skip "xmlsec1 does not support ecdsa-ripemd160", 2 if $sigalg eq 'ripemd160';

            ok( (open XML, '>', "t/tmp-ecdsa-$sigalg-x509-$digalg.xml"), "File opened for write");
            print XML $signed;
            close XML;

            my $verify_response = `xmlsec1 --verify --trusted-pem t/ecdsa.public.pem --id-attr:ID "foo" t/tmp-ecdsa-$sigalg-x509-$digalg.xml 2>&1`;
            ok( $verify_response =~ m/^OK/, "ECDSA Response is verified using xmlsec1" )
                or warn "calling xmlsec1 failed: '$verify_response'\n";
            if ($verify_response =~ m/^OK/) {
                unlink "t/tmp-ecdsa-$sigalg-x509-$digalg.xml";
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

    # ECDSA based keys with no X509
    foreach my $digalg (@hash) {
        my $sig = XML::Sig->new( {
                    digest_hash => $digalg,
                    sig_hash    => $sigalg,
                    key => 't/ecdsa.private.pem',
                    x509 => 0,
                    }
                );
        isa_ok( $sig, 'XML::Sig' );

        my $signed = $sig->sign('<foo ID="123"></foo>');
        ok($signed, "XML Signed Sucessfully using ecdsa-$sigalg, digest: $digalg");

        $sig = XML::Sig->new( );
        my $is_valid = $sig->verify( $signed );
        ok( $is_valid == 1, "XML::Sig signed Validated using X509Certificate");

        $sig = XML::Sig->new( { key => 't/ecdsa.private.pem' } );
        isa_ok( $sig, 'XML::Sig' );

        $signed = $sig->sign('<foo ID="123"></foo>');
        ok($signed, "XML Signed Sucessfully using ecdsa key");

        $sig = XML::Sig->new( );
        $is_valid = $sig->verify( $signed );
        ok( $is_valid == 1, "XML::Sig signed Validated using ECDSAKey");
    }
}

done_testing;
