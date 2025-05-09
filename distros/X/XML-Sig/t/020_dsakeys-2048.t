# -*- perl -*-
use Test::Lib;
use Test::XML::Sig;

my $xmlsec = get_xmlsec_features;

my $sig = XML::Sig->new({ key => 't/dsa.private-2048.key', });
isa_ok($sig, 'XML::Sig');
isa_ok($sig->{key_obj}, 'Crypt::OpenSSL::DSA', 'Key object is valid');

my $signed = $sig->sign('<foo ID="123"></foo>');
ok($signed, "XML Signed Sucessfully using DSA key");

SKIP: {
    skip "xmlsec1 not installed", 1 unless $xmlsec->{installed};
    skip "xmlsec1 too old",       1 unless $xmlsec->{version} gt '1.2.23';

    skip "xmlsec1 does not support DSAKeyValue", 1 if (! $xmlsec->{dsakeyvalue});

    test_xmlsec1_ok(
        "verified using xmlsec1 and X509Certificate", $signed, qw(
            --verify
            --pubkey-cert-pem t/dsa.public-2048.pem
            --trusted-pem t/dsa.public-2048.pem
            --id-attr:ID "foo"
        )
    );
}

$sig = XML::Sig->new();
ok($sig->verify($signed),
    "XML::Sig signed Validated using DSA X509Certificate");

done_testing;
