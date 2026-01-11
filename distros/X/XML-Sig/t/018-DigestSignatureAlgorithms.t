use Test::Lib;
use Test::XML::Sig;

my $xmlsec = get_xmlsec_features;
my $openssl = get_openssl_features;

my @hash = qw/sha224 sha256 sha384 sha512/;
push @hash, 'ripemd160' if $xmlsec->{ripemd160};
push @hash, 'sha1' if $xmlsec->{sha1_support};

SKIP: {
    eval {
        require Crypt::OpenSSL::DSA;
    };
    my $algs = scalar @hash;
    skip "Crypt::OpenSSL::DSA not installed", 3 * $algs * 9 if ($@);
# DSA key size determinst the signature length and therfore the signature hashing algorithm
foreach my $key ('t/dsa.private.key', 't/dsa.private-2048.key', 't/dsa.private-3072.key') {
    # DSA Keys with noX509
    foreach my $digalg (@hash) {
        my $sig = XML::Sig->new( {
            digest_hash => $digalg,
            x509        => 0,
            key         => $key,
        } );
        isa_ok( $sig, 'XML::Sig' );

        my $signed = $sig->sign('<foo ID="123"></foo>');
        ok($signed, "XML Signed Sucessfully using $key dsa-$sig->{sig_hash} digest: $digalg");

        $sig = XML::Sig->new( );
        ok($sig->verify($signed), "XML::Sig signed Validated using X509Certificate");

        SKIP: {
            skip "xmlsec1 not installed", 1 unless $xmlsec->{installed};

            skip "xmlsec1 no sha1 support", 1
                if (($digalg eq 'sha1' or $sig->{ sig_hash } eq 'sha1') and $xmlsec->{sha1_support} ne 1);

            skip "xmlsec1 does not support ecdsa-ripemd160", 1 if (! $xmlsec->{ripemd160} and
                $sig->{sig_hash} eq 'ripemd160');
            skip "OpenSSL version 3.0.0 through 3.0.7 do not support ripemd160", 1
                if ( ! $openssl->{ripemd160} and
                    ($sig->{sig_hash} eq 'ripemd160' or $digalg eq 'ripemd160'));

            skip "xmlsec1 does not support DSAKeyValue", 1 if (! $xmlsec->{dsakeyvalue});

            test_xmlsec1_ok(
                "$sig->{sig_hash} with $digalg verified by xmlsec1", $signed, qw(
                    --verify --id-attr:ID "foo"
                )
            );
        }
    }

    # DSA Keys with noX509
    foreach my $digalg (@hash) {
        my $sig = XML::Sig->new( {
            digest_hash => $digalg,
            x509        => 1,
            key         => $key,
        } );
        isa_ok( $sig, 'XML::Sig' );

        my $signed = $sig->sign('<foo ID="123"></foo>');
        ok($signed, "XML Signed Sucessfully using $key dsa-$sig->{sig_hash} digest: $digalg");

        $sig = XML::Sig->new( );
        my $is_valid = $sig->verify( $signed );
        ok( $is_valid == 1, "XML::Sig signed Validated using X509Certificate");

        SKIP: {

            skip "xmlsec1 not installed", 1 unless $xmlsec->{installed};

            skip "xmlsec1 no sha1 support", 1
                if (($digalg eq 'sha1' or $sig->{ sig_hash } eq 'sha1') and $xmlsec->{sha1_support} ne 1);

            skip "xmlsec1 does not support ecdsa-ripemd160", 1 if (! $xmlsec->{ripemd160} and
                $sig->{sig_hash} eq 'ripemd160');

            skip "OpenSSL version 3.0.0 through 3.0.7 do not support ripemd160", 1
                if ( ! $openssl->{ripemd160} and
                    ($sig->{sig_hash} eq 'ripemd160' or $digalg eq 'ripemd160'));

            skip "xmlsec1 does not support DSAKeyValue", 1 if (! $xmlsec->{dsakeyvalue});

            test_xmlsec1_ok(
                "$sig->{sig_hash} with $digalg verified by xmlsec1", $signed, qw(
                    --verify
                    --id-attr:ID "foo"
                    --pubkey-cert-pem t/dsa.public.pem
                    --trusted-pem t/dsa.public.pem
                )
            );
        }
    }
}
}
foreach my $sigalg (@hash) {
    # RSA Keys with no X509
    foreach my $digalg (@hash) {
        my $sig = XML::Sig->new(
            {
                digest_hash => $digalg,
                sig_hash    => $sigalg,
                key         => 't/rsa.private.key',
            }
        );
        isa_ok($sig, 'XML::Sig');

        my $signed = $sig->sign('<foo ID="123"></foo>');
        ok($signed, "XML Signed Successfully using rsa-$sigalg - no X509 digest: $digalg");

        $sig = XML::Sig->new( );
        my $is_valid = $sig->verify( $signed );
        ok( $is_valid == 1, "XML::Sig signed Validated -no X509");

        SKIP: {
            skip "xmlsec1 not installed", 1 unless $xmlsec->{installed};

            skip "xmlsec1 no sha1 support", 1
                if (($digalg eq 'sha1' or $sigalg eq 'sha1') and
                    $xmlsec->{sha1_support} ne 1);

            skip "xmlsec1 no sha1 support", 1
                if ($sig->{ sig_hash } eq 'sha1' and $xmlsec->{sha1_support} ne 1);

            skip "OpenSSL version 3.0.0 through 3.0.7 do not support ripemd160", 1
                if ( ! $openssl->{ripemd160} and
                    ($sig->{sig_hash} eq 'ripemd160' or $digalg eq 'ripemd160'));

            skip "xmlsec1 does not support DSAKeyValue", 1 if (! $xmlsec->{dsakeyvalue});

            test_xmlsec1_ok(
                "$sigalg with $digalg verified by xmlsec1 - no X509", $signed,
                qw(
                    --verify
                    --pubkey-cert-pem t/rsa.cert.pem
                    --untrusted-pem t/intermediate.pem
                    --trusted-pem t/cacert.pem
                    --id-attr:ID "foo"
                )
            );
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
            skip "xmlsec1 not installed", 1 unless $xmlsec->{installed};

            skip "xmlsec1 no sha1 support", 1
                if (($digalg eq 'sha1' or $sig->{ sig_hash } eq 'sha1') and $xmlsec->{sha1_support} ne 1);

            skip "xmlsec1 does not support ecdsa-ripemd160", 1 if (! $xmlsec->{ripemd160} and
                $sig->{sig_hash} eq 'ripemd160');

            skip "OpenSSL version 3.0.0 through 3.0.7 do not support ripemd160", 1
                if ( ! $openssl->{ripemd160} and
                    ($sig->{sig_hash} eq 'ripemd160' or $digalg eq 'ripemd160'));

            test_xmlsec1_ok(
                "$sigalg with $digalg verified by xmlsec1 - X509", $signed,
                qw(
                    --verify
                    --pubkey-cert-pem t/rsa.cert.pem
                    --untrusted-pem t/intermediate.pem
                    --trusted-pem t/cacert.pem
                    --id-attr:ID "foo"
                )
            );
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
            skip "xmlsec1 not installed", 1 unless $xmlsec->{installed};

            skip "xmlsec1 no sha1 support", 1
                if (($digalg eq 'sha1' or $sig->{ sig_hash } eq 'sha1') and $xmlsec->{sha1_support} ne 1);

            skip "xmlsec1 does not support ecdsa-ripemd160", 1 if (! $xmlsec->{ripemd160} and
                $sig->{sig_hash} eq 'ripemd160');

            skip "OpenSSL version 3.0.0 through 3.0.7 do not support ripemd160", 1
                if ( ! $openssl->{ripemd160} and
                    ($sig->{sig_hash} eq 'ripemd160' or $digalg eq 'ripemd160'));

            test_xmlsec1_ok(
                "ECDSA Response is verified using xmlsec1",
                $signed,
                qw(
                    --verify
                    --trusted-pem t/ecdsa.public.pem --id-attr:ID "foo"
                )
            );
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
