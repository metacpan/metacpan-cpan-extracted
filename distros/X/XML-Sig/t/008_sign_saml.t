# -*- perl -*-

use strict;
use warnings;
use Test::More;
use File::Which;

BEGIN {
    use_ok( 'XML::Sig' );
}

open my $file, 't/saml_request.xml' or die "no test saml request";
my $xml;
{
    local undef $/;
    $xml = <$file>;
}

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
open $file, 't/saml_request-xmlsec1-dsa-signed.xml' or die "no test saml_request-xmlsec1-dsa-signed.xml";
my $xmlsec;
{
    local undef $/;
    $xmlsec = <$file>;
}

my $xmlsec1_dsasig = XML::Sig->new();
my $xmlsec_ret = $xmlsec1_dsasig->verify($xmlsec);
ok($xmlsec_ret, "xmlsec1: DSA Verifed Successfully");

# Test that XML::Sig can verify a xmlsec1 RSA signed xml
open $file, 't/saml_request-xmlsec1-rsa-signed.xml' or die "no test saml_request-xmlsec1-rsa-signed.xml";
{
    local undef $/;
    $xmlsec = <$file>;
}

my $xmlsec1_rsasig = XML::Sig->new( {x509 => 1, cert => 't/rsa.cert.pem'} );
$xmlsec_ret = $xmlsec1_rsasig->verify($xmlsec);
ok($xmlsec_ret, "xmlsec1: RSA Verifed Successfully");

done_testing;
