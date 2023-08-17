# -*- perl -*-

use strict;
use warnings;

use Test::More;
use Test::Exception;
use MIME::Base64;

use_ok('XML::Sig');

sub slurpy {
    my $file = shift;
    open my $fh, $file or die "No file to be opened";
    local undef $/;
    my $content = <$fh>;
    return $content;
}

my $xml = slurpy('t/signed/saml_request-xmlsec1-rsa-signed.xml');
my @certs = qw(t/rsa.cert.pem);

my %args = (
    x509               => 1,
    exclusive          => 1,
    no_xml_declaration => 1,
    ns      => { artifact => 'urn:oasis:names:tc:SAML:2.0:protocol' },
    id_attr => '/artifact:ArtifactResolve[@ID]',
);

foreach (@certs) {
    my $txt = slurpy($_);

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
