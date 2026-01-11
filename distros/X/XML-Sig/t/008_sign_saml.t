# -*- perl -*-

use strict;
use warnings;
use Test::Lib;
use Test::XML::Sig;
use File::Which;
use File::Spec::Functions qw(catfile);

my $xmlsec = get_xmlsec_features;
my $openssl = get_openssl_features;

my $xml = slurp_file('t/unsigned/saml_request.xml');

# First test signing with an RSA key
my $sig = XML::Sig->new({ x509 => 1, key => 't/rsa.private.key', cert => 't/rsa.cert.pem' });
my $signed_xml = $sig->sign($xml);
ok($signed_xml, "Signed Successfully");
my $ret = $sig->verify($signed_xml);
ok($ret, "RSA: Verifed Successfully");
ok($sig->signer_cert);

# Test signing with a DSA key
SKIP: {
    eval {
        require Crypt::OpenSSL::DSA;
    };
    skip "Crypt::OpenSSL::DSA not installed", 1 if ($@);
foreach my $key ('t/dsa.private-2048.key', 't/dsa.private-3072.key', 't/dsa.private.key') {

    my $dsasig = XML::Sig->new({ key => $key });
    my $dsa_signed_xml = $dsasig->sign($xml);

    my $dsaret = $dsasig->verify($dsa_signed_xml);
    ok($dsaret, "XML:Sig DSA: Verifed Successfully");

    SKIP: {
        skip "xmlsec1 not installed", 1 unless $xmlsec->{installed};

        skip "xmlsec1 no sha1 support", 1
            if ($dsasig->{ sig_hash } eq 'sha1' and $xmlsec->{sha1_support} ne 1);

        # Try whether xmlsec is correctly installed which
        # doesn't seem to be the case on every cpan testing machine

        my $output = `xmlsec1 --version`;
        skip "xmlsec1 not correctly installed", 1 if $?;

        skip "xmlsec1 does not support DSAKeyValue", 1 if (! $xmlsec->{dsakeyvalue});

        test_xmlsec1_ok("DSA verify XML:Sig signed with $key: xmlsec1 Response is OK",
            $dsa_signed_xml,
            qw(--verify --id-attr:ID "ArtifactResolve")
        );

    }
}
# Ensure xmlsec still verifies properly
{
    # Test that XML::Sig can verify a xmlsec1 DSA signed xml
    $xml = slurp_file('t/signed/saml_request-xmlsec1-dsa-signed.xml');
    my $xmlsec1_dsasig = XML::Sig->new();
    my $xmlsec_ret = $xmlsec1_dsasig->verify($xml);
    ok($xmlsec_ret, "xmlsec1: DSA Verifed Successfully");

    my $key = 't/dsa.public.pem';
    SKIP: {
        skip "xmlsec1 not installed", 1 unless $xmlsec->{installed};

        skip "xmlsec1 no sha1 support", 1
            if ($xmlsec1_dsasig->{ sig_hash } eq 'sha1' and $xmlsec->{sha1_support} ne 1);

        skip "xmlsec1 does not support DSAKeyValue", 1 if (! $xmlsec->{dsakeyvalue});

        test_xmlsec1_ok(
            "DSA verify XML:Sig signed with $key: xmlsec1 Response is OK",
            $xml, qw(--verify --id-attr:ID "ArtifactResolve"));
    }
}

}
# Test that XML::Sig can verify a xmlsec1 RSA signed xml
$xml = slurp_file('t/signed/saml_request-xmlsec1-rsa-signed.xml');
my $xmlsec1_rsasig = XML::Sig->new({ x509 => 1, cert => 't/rsa.cert.pem' });
ok($xmlsec1_rsasig->verify($xml), "RSA Verifed Successfully");

# SAML metadata
my $md = slurp_file(catfile(qw(t unsigned saml_metadata.xml)));

$sig = XML::Sig->new(
    {
        x509 => 1,
        key  => 't/rsa.private.key',
        cert => 't/rsa.cert.pem',
        # The syntax is similar to xmlsec: --id-attr:ID urn:...:EntityDescriptor
        ns   => { md => 'urn:oasis:names:tc:SAML:2.0:metadata' },
        id_attr => '/md:EntityDescriptor[@ID]',
    });

my $signed = $sig->sign($md);

$ret = $sig->verify($signed);

ok($ret, "Verified SAML metadata signature");

my $xp = XML::LibXML::XPathContext->new(
    XML::LibXML->load_xml(string => $signed)
);

my %ns = (
    md => 'urn:oasis:names:tc:SAML:2.0:metadata',
    ds => 'http://www.w3.org/2000/09/xmldsig#'
);
$xp->registerNs($_, $ns{$_}) foreach keys %ns;

my $nodes = $xp->findnodes('//ds:Signature');
is($nodes->size, 1, "Found only one signature node");
my $node = $nodes->get_node(1);
is($node->nodePath, '/md:EntityDescriptor/dsig:Signature', ".. and on the correct node path");

done_testing;
