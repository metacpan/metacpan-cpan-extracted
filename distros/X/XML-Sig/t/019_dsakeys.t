# -*- perl -*-

use Test::Lib;
use Test::XML::Sig;

my $xmlsec  = get_xmlsec_features;

SKIP: {
    eval {
        require Crypt::OpenSSL::DSA;
    };
    skip "Crypt::OpenSSL::DSA not installed", 5 if ($@);
my $sig = XML::Sig->new(
    {
        x509 => 1,
        cert => 't/dsa.public.pem',
        key  => 't/dsa.private.key',
    }
);
isa_ok($sig, 'XML::Sig');
isa_ok($sig->{key_obj}, 'Crypt::OpenSSL::DSA', 'Key object is valid');

my $signed = $sig->sign('<foo ID="123"></foo>');
ok($signed, "XML Signed Sucessfully using DSA key");

SKIP: {
    skip "xmlsec1 not installed", 1 unless $xmlsec->{installed};

    skip "xmlsec1 no sha1 support", 1
        if (($sig->{ sig_hash } eq 'sha1') and $xmlsec->{sha1_support} ne 1);

    test_xmlsec1_ok(
        "verified using xmlsec1 and X509Certificate", $signed, qw(
            --verify --pubkey-cert-pem t/dsa.public.pem
            --trusted-pem t/dsa.public.pem
            --id-attr:ID "foo"
        )
    );
}

$sig = XML::Sig->new();
ok($sig->verify($signed),
    "XML::Sig signed Validated using DSA X509Certificate");
}
done_testing;
