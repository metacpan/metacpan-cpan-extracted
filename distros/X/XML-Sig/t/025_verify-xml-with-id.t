# -*- perl -*-

use Test::Lib;
use Test::XML::Sig;
use MIME::Base64;

my $xml = slurp_file('t/signed/saml_request-xmlsec1-rsa-signed.xml');
my @certs = qw(t/rsa.cert.pem);

my %args = (
    x509               => 1,
    exclusive          => 1,
    no_xml_declaration => 1,
    ns      => { artifact => 'urn:oasis:names:tc:SAML:2.0:protocol' },
    id_attr => '/artifact:ArtifactResolve[@ID]',
);

foreach (@certs) {
    my $txt = slurp_file($_);

    my $sig = XML::Sig->new({%args, cert_text => $txt});
    isa_ok($sig, 'XML::Sig');

    my $ret = $sig->verify($xml);
    if ($ret) {
        ok($ret, "Validated on $_");
        ok($sig->signer_cert, "Got the signer cert correctly: " . $sig->signer_cert);
        last;
    }
    else {
        ok(!$ret, "Validated on $_");
    }
}



done_testing;
