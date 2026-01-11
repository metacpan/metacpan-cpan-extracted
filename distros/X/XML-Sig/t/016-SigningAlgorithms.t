use Test::Lib;
use Test::XML::Sig;
use File::Which;

my $xmlsec = get_xmlsec_features;

my @hash_alg = qw/sha224 sha256 sha384 sha512/;
push @hash_alg, 'sha1' if $xmlsec->{sha1_support};

SKIP: {
    eval {
        require Crypt::OpenSSL::DSA;
    };
    my $algs = scalar @hash_alg;
    skip "Crypt::OpenSSL::DSA not installed", $algs * 4 if ($@);
foreach my $alg (@hash_alg) {

    my $sig = XML::Sig->new(
        {
            sig_hash => $alg,
            x509     => 1,
            key      => 't/dsa.private.key',
        }
    );
    isa_ok($sig, 'XML::Sig');

    my $signed = $sig->sign('<foo ID="123"></foo>');
    ok($signed, "XML Signed Sucessfully using dsa key");

    $sig = XML::Sig->new( );
    ok($sig->verify($signed), "XML::Sig signed Validated using X509Certificate");

    SKIP: {
        skip "xmlsec1 not installed", 1 unless $xmlsec->{installed};

        skip "xmlsec1 no sha1 support", 1
            if ($sig->{ sig_hash } eq 'sha1' and $xmlsec->{sha1_support} ne 1);

        skip "xmlsec1 does not support DSAKeyValue", 1 if (! $xmlsec->{dsakeyvalue});

        test_xmlsec1_ok("Verified by xmlsec1",
            $signed, qw(--verify --id-attr:ID "foo"));
    }
}
}
foreach my $alg (@hash_alg) {
    my $sig = XML::Sig->new(
        {
            sig_hash => $alg,
            key      => 't/rsa.private.key',
        }
    );
    isa_ok($sig, 'XML::Sig');

    my $signed = $sig->sign('<foo ID="123"></foo>');
    ok($signed, "XML Signed Sucessfully using rsa key - no X509");

    $sig = XML::Sig->new();
    ok($sig->verify($signed), "XML::Sig signed Validated -no X509");

    SKIP: {
        skip "xmlsec1 not installed", 1 unless $xmlsec->{installed};

        skip "xmlsec1 does not support DSAKeyValue", 1 if (! $xmlsec->{dsakeyvalue});

        test_xmlsec1_ok(
            'RSA is verified using xmlsec1 - no',
            $signed,
            qw(
                --verify
                --pubkey-cert-pem
                t/rsa.cert.pem
                --untrusted-pem
                t/intermediate.pem
                --trusted-pem
                t/cacert.pem
                --id-attr:ID
                "foo"
            )
        );
    }
}

foreach my $alg (@hash_alg) {
    my $sig = XML::Sig->new( {
        sig_hash    => $alg,
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
        skip "xmlsec1 not installed", 1 unless $xmlsec->{installed};

        test_xmlsec1_ok(
            'RSA is verified using xmlsec1 - no',
            $signed,
            qw(
                --verify
                --pubkey-cert-pem
                t/rsa.cert.pem
                --untrusted-pem
                t/intermediate.pem
                --trusted-pem
                t/cacert.pem
                --id-attr:ID
                "foo"
            )
        );
    }
}

# Signatures for ECDSA based keys
foreach my $alg (@hash_alg) {
    my $sig = XML::Sig->new( { x509 => 1 , sig_hash => $alg, key => 't/ecdsa.private.pem', cert => 't/ecdsa.public.pem' } );
    isa_ok( $sig, 'XML::Sig' );

    my $signed = $sig->sign('<foo ID="123"></foo>');
    ok($signed, "XML Signed Sucessfully using ecdsa key");

    $sig = XML::Sig->new();
    ok($sig->verify($signed), "XML::Sig signed Validated using X509Certificate");

    SKIP: {
        skip "xmlsec1 not installed", 1 unless $xmlsec->{installed};

        test_xmlsec1_ok(
            'RSA is verified using xmlsec1 - no',
            $signed,
            qw(
                --verify
                --trusted-pem
                t/ecdsa.public.pem
                --id-attr:ID
                "foo"
            )
        );
    }

    $sig = XML::Sig->new( { key => 't/ecdsa.private.pem' } );
    isa_ok( $sig, 'XML::Sig' );

    $signed = $sig->sign('<foo ID="123"></foo>');
    ok($signed, "XML Signed Sucessfully using ecdsa key");

    $sig = XML::Sig->new();
    ok($sig->verify($signed), "XML::Sig signed Validated using ECDSAKey");
}

done_testing;
