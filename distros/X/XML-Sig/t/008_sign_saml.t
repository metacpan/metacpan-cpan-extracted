# -*- perl -*-

use strict;
use warnings;
use Test::More;
use File::Which;
use File::Spec::Functions qw(catfile);

BEGIN {
    use_ok( 'XML::Sig' );
}

sub slurp_file {
    my $name = shift;
    open (my $fh, '<', $name) or die "Unable to open $name";
    local $/ = undef;
    return <$fh>;
}

my $xml = slurp_file('t/unsigned/saml_request.xml');

# First test signing with an RSA key
my $sig = XML::Sig->new({ x509 => 1, key => 't/rsa.private.key', cert => 't/rsa.cert.pem' });
my $signed_xml = $sig->sign($xml);
ok($signed_xml, "Signed Successfully");
my $ret = $sig->verify($signed_xml);
ok($ret, "RSA: Verifed Successfully");
ok($sig->signer_cert);

# Test signing with a DSA key
my $dsasig = XML::Sig->new({ key => 't/dsa.private.key' });
my $dsa_signed_xml = $dsasig->sign($xml);
ok( open XML, '>', 't/dsa.xml' );
print XML $dsa_signed_xml;
ok( close XML, "DSA: Signed t/dsa.xml written Sucessfully");
my $dsaret = $dsasig->verify($dsa_signed_xml);
ok($dsaret, "XML:Sig DSA: Verifed Successfully");

SKIP: {
    skip "xmlsec1 not installed", 4 unless which('xmlsec1');

    # Try whether xmlsec is correctly installed which
    # doesn't seem to be the case on every cpan testing machine

    my $output = `xmlsec1 --version`;
    skip "xmlsec1 not correctly installed", 6 if $?;

    # Verify with xmlsec1
    open my $dsafile, 't/dsa.xml' or die "no dsa signed xml";
    my $dsaxml;
    {
        local undef $/;
        $dsaxml = <$dsafile>;
    }

    my $verify_response = `xmlsec1 --verify --id-attr:ID "ArtifactResolve" t/dsa.xml 2>&1`;
    ok( $verify_response =~ m/^OK/, "DSA verify XML:Sig signed: xmlsec1 Response is OK" )
        or warn "calling xmlsec1 failed: '$verify_response'\n";
    unlink 't/dsa.xml';
}

# Test that XML::Sig can verify a xmlsec1 DSA signed xml
$xml = slurp_file('t/signed/saml_request-xmlsec1-dsa-signed.xml');
my $xmlsec1_dsasig = XML::Sig->new();
my $xmlsec_ret = $xmlsec1_dsasig->verify($xml);
ok($xmlsec_ret, "xmlsec1: DSA Verifed Successfully");

# Test that XML::Sig can verify a xmlsec1 RSA signed xml
$xml = slurp_file('t/signed/saml_request-xmlsec1-rsa-signed.xml');
my $xmlsec1_rsasig = XML::Sig->new( {x509 => 1, cert => 't/rsa.cert.pem'} );
$xmlsec_ret = $xmlsec1_rsasig->verify($xml);
ok($xmlsec_ret, "xmlsec1: RSA Verifed Successfully");

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
