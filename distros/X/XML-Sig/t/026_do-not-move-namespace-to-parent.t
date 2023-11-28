use strict;
use warnings;
use Test::More;

use XML::Sig;
use XML::LibXML;

my $xml = <<'THIRDPARTY';
<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" Destination="http://localhost:8080/sales-post-sig/" ID="id-icPMMO3R5rLNKh3wK1PfEC24c-QPBDczJZuxVRU3" InResponseTo="ID_8dc4d086-f2eb-4413-aed9-db4512e1ea1c" IssueInstant="2014-10-05T10:32:20Z" Version="2.0">
<saml:Issuer Format="urn:oasis:names:tc:SAML:2.0:nameid-format:entity">http://oam.convenios.gov.br:14100/oam/fed</saml:Issuer>
<samlp:Status>
<samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
</samlp:Status>
<saml:Assertion ID="id-ogGh-dw-nasEHVC2YIU2-9jQf-bYHE-4c-ip4Ad6" IssueInstant="2014-10-05T10:32:20Z" Version="2.0">
<saml:Issuer Format="urn:oasis:names:tc:SAML:2.0:nameid-format:entity">http://oam.convenios.gov.br:14100/oam/fed</saml:Issuer>
<saml:Subject>
<saml:NameID Format="urn:oasis:names:tc:SAML:2.0:nameid-format:transient" NameQualifier="http://oam.convenios.gov.br:14100/oam/fed" SPNameQualifier="http://localhost:8080/sales-post-sig/">id-KWKgL-WLpVBKBuqBOSa3fJ4Jq-xZLQzbL-t0Y7il</saml:NameID>
<saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
<saml:SubjectConfirmationData InResponseTo="ID_8dc4d086-f2eb-4413-aed9-db4512e1ea1c" NotOnOrAfter="2014-10-05T10:37:20Z" Recipient="http://localhost:8080/sales-post-sig/"/>
</saml:SubjectConfirmation>
</saml:Subject>
<saml:Conditions NotBefore="2014-10-05T10:32:20Z" NotOnOrAfter="2014-10-05T10:37:20Z">
<saml:AudienceRestriction>
<saml:Audience>http://localhost:8080/sales-post-sig/</saml:Audience>
</saml:AudienceRestriction>
</saml:Conditions>
<saml:AuthnStatement AuthnInstant="2014-10-05T10:32:20Z" SessionIndex="id-tGmYdxzyikqZVhZZp6uMTEdlampkB7TstvGh1bw2" SessionNotOnOrAfter="2014-10-05T11:32:20Z">
<saml:AuthnContext>
<saml:AuthnContextClassRef>ConveniosScheme</saml:AuthnContextClassRef>
</saml:AuthnContext>
</saml:AuthnStatement>
</saml:Assertion>
</samlp:Response>
THIRDPARTY

local $XML::LibXML::skipXMLDeclaration = 1;
my $orig = XML::LibXML->load_xml( string => $xml );
my $oxc = XML::LibXML::XPathContext->new($orig);
$oxc->registerNs('dsig', 'http://www.w3.org/2000/09/xmldsig#');
$oxc->registerNs('saml', 'urn:oasis:names:tc:SAML:2.0:assertion');
$oxc->registerNs('samlp', 'urn:oasis:names:tc:SAML:2.0:protocol');

my $uri = qr{http://www.w3.org/2000/09/xmldsig#};

my $attributes = get_attributes($oxc, '/samlp:Response/saml:Assertion');
my ($names, $uris) = get_namespaces($attributes);

ok(!grep ( /dsig/ , @{$names}), 'Did not find dsig in Original Assertion');
ok(!grep ( /$uri/ , @{$uris}), 'Did not find http://www.w3.org/2000/09/xmldsig# in Original Assertion');

$attributes = get_attributes($oxc, '/samlp:Response');
($names, $uris) = get_namespaces($attributes);

ok(!grep ( /dsig/ , @{$names}), 'Did not find dsig in Original Response');
ok(!grep ( /$uri/ , @{$uris}), 'Did not find http://www.w3.org/2000/09/xmldsig# in Original Response');

my $sig = XML::Sig->new(
                    {
                        key  => 't/rsa.private.key',
                        cert => 't/rsa.cert.pem',
                        id_attr => '//saml:Assertion'
                    });

my $signed = $sig->sign($xml);
my $dom = XML::LibXML->load_xml( string => $signed );
my $xc = XML::LibXML::XPathContext->new($dom);
$xc->registerNs('dsig', 'http://www.w3.org/2000/09/xmldsig#');
$xc->registerNs('saml', 'urn:oasis:names:tc:SAML:2.0:assertion');
$xc->registerNs('samlp', 'urn:oasis:names:tc:SAML:2.0:protocol');

$attributes = get_attributes($xc, '/samlp:Response/saml:Assertion');
($names, $uris) = get_namespaces($attributes);

ok(!grep ( /dsig/ , @{$names}), 'Did not find dsig in Assertion');
ok(!grep ( /$uri/ , @{$uris}), 'Did not find http://www.w3.org/2000/09/xmldsig# in Assertion');

$attributes = get_attributes($xc, '/samlp:Response');
($names, $uris) = get_namespaces($attributes);

ok(!grep ( /dsig/ , @{$names}), 'Did not find dsig in Response');
ok(!grep ( /$uri/ , @{$uris}), 'Did not find http://www.w3.org/2000/09/xmldsig# in Response');

sub get_attributes {
    my $xpc   = shift;
    my $xpath = shift;

    my $nodes = $xpc->findnodes($xpath);
    if ($nodes->size == 0) {
        die "Unable to find a samlp:Response";
    }

    my $node = $nodes->get_node(1);

    my @attributes = $node->attributes();
    return \@attributes;
}

sub get_namespaces {
    my $nslist = shift;
    my @localnames;
    my @uri;
    foreach my $ns (@{$nslist}){
        next if (ref $ns ne 'XML::LibXML::Namespace');
        push @localnames, $ns->getLocalName;
        push @uri, $ns->getData();
    }
    return \@localnames, \@uri;
}

done_testing;
