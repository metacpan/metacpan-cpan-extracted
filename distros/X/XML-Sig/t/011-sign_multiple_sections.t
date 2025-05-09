# -*- perl -*-

use File::Which;
use Test::Lib;
use Test::XML::Sig;


my $xmlsec = get_xmlsec_features;
my $openssl = get_openssl_features;

# Get the XML file that has multiple ID attribute nodes to sign
my $xml = slurp_file('t/unsigned/sign_multiple_sections.xml');

# First test signing with an RSA key
my $sig = XML::Sig->new(
    { x509 => 1, key => 't/rsa.private.key', cert => 't/rsa.cert.pem' });
my $signed_xml = $sig->sign($xml);
ok($signed_xml, "Signed Successfully");

# Verify the XML::Sig signed xml
my $ret = $sig->verify($signed_xml);
ok($ret, "RSA: Verifed Successfully");
ok($sig->signer_cert);

SKIP: {
    skip "xmlsec1 not installed", 1 unless $xmlsec->{installed};

    test_xmlsec1_ok(
        "RSA verify XML:Sig signed: xmlsec1 Response is OK",
        $signed_xml,
        qw(
        --verify
        --pubkey-cert-pem
        t/rsa.cert.pem
        --untrusted-pem
        t/intermediate.pem
        --trusted-pem
        t/cacert.pem
        --id-attr:ID
        "Response"
        --id-attr:ID
        "Assertion"
        )
    );
}

# Test signing with a DSA key
my $dsasig = XML::Sig->new({ key => 't/dsa.private.key' });
my $dsa_signed_xml = $dsasig->sign($xml);

# Verify XML file with XML::Sig signed with DSA
my $dsaret = $dsasig->verify($dsa_signed_xml);
ok($dsaret, "XML:Sig DSA: Verifed Successfully");

# Use xmlsec1 to verify the XML::Sig signed file
SKIP: {
    skip "xmlsec1 not installed", 1 unless $xmlsec->{installed};

    skip "xmlsec1 no sha1 support", 1
        if ($dsasig->{ sig_hash } eq 'sha1' and $xmlsec->{sha1_support} ne 1);

    skip "xmlsec1 does not support DSAKeyValue", 1 if (! $xmlsec->{dsakeyvalue});

    test_xmlsec1_ok(
        "DSA verify XML:Sig signed: xmlsec1 Response is OK",
        $dsa_signed_xml,
        qw(
            --verify
            --id-attr:ID "Response"
            --id-attr:ID "Assertion"
        )
    );
}

# Test that XML::Sig can verify an xmlsec1 RSA signed xml
$xml = slurp_file('t/signed/xmlsec1-signed-rsa-multiple.xml');
my $xmlsec1_rsasig = XML::Sig->new({ x509 => 1, cert => 't/rsa.cert.pem' });
my $xmlsec_ret     = $xmlsec1_rsasig->verify($xml);
ok($xmlsec_ret, "xmlsec1: RSA Verifed Successfully");

## Test that XML::Sig can verify a xmlsec1 RSA multiple signed xml
#TODO: {
#    local $TODO = "Test that XML::Sig can verify a xmlsec1 RSA multiple signed xml";
#    my $xml = slurp_file('t/signed/xmlsec1-signed-dsa-multiple.xml');
#    my $sig = XML::Sig->new();
#    ok($sig->verify($xmlsec), "DSA Verifed Successfully");
#}


done_testing;
