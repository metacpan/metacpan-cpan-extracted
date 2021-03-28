# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 7;
use File::Which;

BEGIN {
    use_ok( 'XML::Sig' );
}

open my $file, 't/unsigned/saml_request.xml' or die "no test saml request";
my $xml;
{
    local undef $/;
    $xml = <$file>;
}

# First test signing with an RSA key
my $sig = XML::Sig->new({
                    no_xml_declaration => 0,
                    x509 => 1,
                    key => 't/rsa.private.key',
                    cert => 't/rsa.cert.pem'
                });

my $signed_xml = $sig->sign($xml);
ok($signed_xml =~ 'xml version', "XML Declaration Found");
ok($signed_xml, "Signed Successfully");
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
ok($signed_xml !~ 'xml version', "XML Declaration not Found");
ok($signed_xml, "Signed Successfully");
$ret = $sig->verify($signed_xml);
ok($ret, "XML:Sig RSA: Verifed Successfully");

done_testing;
