# -*- perl -*-

use Test::Lib;
use Test::XML::Sig;

my $xml = slurp_file('t/unsigned/saml_request.xml');

# First test signing with an RSA key
my $sig = XML::Sig->new(
    {
        no_xml_declaration => 0,
        x509               => 1,
        key                => 't/rsa.private.key',
        cert               => 't/rsa.cert.pem'
    }
);

my $signed_xml = $sig->sign($xml);
like($signed_xml, qr#<?xml version#, "XML Declaration Found");
ok($signed_xml,                  "Signed Successfully");
my $ret = $sig->verify($signed_xml);
ok($ret, "XML:Sig RSA: Verifed Successfully");

# Test no_xml_declaration = true
$sig = XML::Sig->new({
                    no_xml_declaration => 1,
                    x509 => 1,
                    key => 't/rsa.private.key',
                    cert => 't/rsa.cert.pem'
                });

$signed_xml = $sig->sign($xml);
unlike($signed_xml, qr#<?xml version#, "XML Declaration not Found");
ok($signed_xml, "Signed Successfully");
$ret = $sig->verify($signed_xml);
ok($ret, "XML:Sig RSA: Verifed Successfully");

done_testing;
