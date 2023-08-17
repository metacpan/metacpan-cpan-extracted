use strict;
use warnings;
use Test::More;
use XML::Enc;
use XML::LibXML;
use XML::LibXML::XPathContext;

# Test for https://github.com/perl-net-saml2/perl-XML-Enc/issues/10
my $xml;
{
    open my $fh, '<', 't/asserted-encryption.xml';
    local $/ = undef;
    $xml = <$fh>;
}

my $enc = XML::Enc->new(
    {
        key                 => 't/encrypted-sign-private.pem',
        no_xml_declaration  => 1
    }
);

$xml = XML::LibXML->load_xml(string => $xml);
my $xpc = XML::LibXML::XPathContext->new($xml);
$xpc->registerNs('saml', 'urn:oasis:names:tc:SAML:2.0:assertion');
$xpc->registerNs('samlp', 'urn:oasis:names:tc:SAML:2.0:protocol');
$xpc->registerNs('dsig', 'http://www.w3.org/2000/09/xmldsig#');
$xpc->registerNs('xenc', 'http://www.w3.org/2001/04/xmlenc#');

my $decrypted = $enc->decrypt($xml);
ok($decrypted, "Got a decrypted message");


$xml = XML::LibXML->load_xml(string => $decrypted);
$xpc->setContextNode($xml);

my $assertion = $xpc->findnodes('//saml:Assertion');
is($assertion->size, 1, "Found one assertion node");

my $a = $assertion->get_node(1);
my $attr = $a->getAttribute('xmlns:saml');

ok($attr, "Have a saml namespace attribute");

done_testing;
