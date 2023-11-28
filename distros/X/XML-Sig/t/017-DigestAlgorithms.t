use Test::Lib;
use Test::XML::Sig;

my $xmlsec  = get_xmlsec_features;
my $openssl = get_openssl_features;

my @hash_alg = qw/sha1 sha224 sha256 sha384 sha512 ripemd160/;
foreach my $alg (@hash_alg) {
    my $sig = XML::Sig->new(
        {
            digest_hash => $alg,
            x509        => 1,
            key         => 't/dsa.private.key',
        }
    );
    isa_ok($sig, "XML::Sig", "XML::Sig Digest: $alg");

    my $signed = $sig->sign('<foo ID="123"></foo>');
    ok($signed, "XML Signed Sucessfully using dsa key");

    $sig = XML::Sig->new();
    ok($sig->verify($signed),
        "XML::Sig signed Validated using X509Certificate");

    SKIP: {
        skip "xmlsec1 not installed", 1 unless $xmlsec->{installed};
        skip "OpenSSL does not support ripemd160", 1
            unless $openssl->{ripemd160};

        test_xmlsec1_ok("Verified by XMLsec",
            $signed, qw(--verify --id-attr:ID "foo"));
    }
}

foreach my $alg (@hash_alg) {
    my $sig = XML::Sig->new(
        {
            digest_hash => $alg,
            key         => 't/rsa.private.key',
        }
    );
    isa_ok($sig, "XML::Sig", "XML::Sig Digest: $alg");

    my $signed = $sig->sign('<foo ID="123"></foo>');
    ok($signed, "XML Signed Sucessfully using rsa key - no X509");

    $sig = XML::Sig->new();
    ok($sig->verify($signed), "XML::Sig signed Validated - no X509");

    SKIP: {
        skip "xmlsec1 not installed", 1 unless $xmlsec->{installed};
        skip "OpenSSL does not support ripemd160", 1
            unless $openssl->{ripemd160};

        test_xmlsec1_ok(
            "RSA is verified using xmlsec1 - no X509", $signed, qw(
                --verify --pubkey-cert-pem t/rsa.cert.pem
                --untrusted-pem t/intermediate.pem --trusted-pem t/cacert.pem
                --id-attr:ID "foo"
            )
        );
    }
}

foreach my $alg (@hash_alg) {
    my $sig = XML::Sig->new(
        {
            digest_hash => $alg,
            x509        => 1,
            key         => 't/rsa.private.key',
            cert        => 't/rsa.cert.pem'
        }
    );
    isa_ok($sig, "XML::Sig", "XML::Sig Digest: $alg");

    my $signed = $sig->sign('<foo ID="123"></foo>');
    ok($signed, "XML Signed Sucessfully using rsa key");

    $sig = XML::Sig->new();
    my $is_valid = $sig->verify($signed);
    ok($is_valid == 1, "XML::Sig signed Validated");

    SKIP: {
        skip "xmlsec1 not installed", 1 unless $xmlsec->{installed};
        skip "OpenSSL does not support ripemd160", 1
            unless $openssl->{ripemd160};

        test_xmlsec1_ok(
            "RSA is verified using xmlsec1",
            $signed, qw(
                --verify --pubkey-cert-pem t/rsa.cert.pem
                --untrusted-pem t/intermediate.pem
                --trusted-pem t/cacert.pem
                --id-attr:ID "foo")
        );

    }
}

# Signatures for ECDSA based keys
foreach my $alg (@hash_alg) {
    my $sig = XML::Sig->new(
        {
            x509        => 1,
            digest_hash => $alg,
            key         => 't/ecdsa.private.pem',
            cert        => 't/ecdsa.public.pem'
        }
    );
    isa_ok($sig, "XML::Sig", "XML::Sig Digest: $alg");

    my $signed = $sig->sign('<foo ID="123"></foo>');
    ok($signed, "XML Signed Sucessfully using ecdsa key");

    $sig = XML::Sig->new();
    my $is_valid = $sig->verify($signed);
    ok($is_valid == 1, "XML::Sig signed Validated using X509Certificate");

    SKIP: {

        skip "xmlsec1 not installed", 1 unless $xmlsec->{installed};
        skip "OpenSSL does not support ripemd160", 1
            unless $openssl->{ripemd160};

        test_xmlsec1_ok("ECDSA Response is verified using xmlsec1",
            $signed,
            qw(--verify --trusted-pem t/ecdsa.public.pem --id-attr:ID "foo"));
    }

    $sig = XML::Sig->new({ key => 't/ecdsa.private.pem' });
    isa_ok($sig, "XML::Sig", "XML::Sig Digest: $alg");

    $signed = $sig->sign('<foo ID="123"></foo>');
    ok($signed, "XML Signed Sucessfully using ecdsa key");

    $sig = XML::Sig->new();
    ok($sig->verify($signed), "XML::Sig signed Validated using ECDSAKey");
}

done_testing;
