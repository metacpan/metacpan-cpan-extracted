# -*- perl -*-

use strict;
use warnings;
use Test::More;
use File::Which;

BEGIN {
    use_ok( 'XML::Sig' );
}

# Get the XML file that has multiple ID attribute nodes to sign
open my $file, 't/unsigned/sign_multiple_sections.xml' or die "Unable to open t/unsigned/sign_multiple_sections.xml";
my $xml;
{
    local undef $/;
    $xml = <$file>;
}

# First test signing with an RSA key
my $sig = XML::Sig->new({ x509 => 1, key => 't/rsa.private.key', cert => 't/rsa.cert.pem' });
my $signed_xml = $sig->sign($xml);
ok($signed_xml, "Signed Successfully");

# Write the signed XML to a temporary file
ok( open XML, '>', 't/rsa.xml' );
print XML $signed_xml;
ok( close XML, "RSA: Signed t/rsa.xml written Sucessfully");

# Verify the XML::Sig signed xml
my $ret = $sig->verify($signed_xml);
ok($ret, "RSA: Verifed Successfully");
ok($sig->signer_cert);

# Use xmlsec1 to verify the XML::Sig signed file
SKIP: {
    skip "xmlsec1 not installed", 4 unless which('xmlsec1');

    # Try whether xmlsec is correctly installed which
    # doesn't seem to be the case on every cpan testing machine

    my $output = `xmlsec1 --version`;
    skip "xmlsec1 not correctly installed", 6 if $?;

    # Verify with xmlsec1
    open my $rsafile, 't/rsa.xml' or die "no rsa signed xml";
    my $rsaxml;
    {
        local undef $/;
        $rsaxml = <$rsafile>;
    }

    my $verify_response = `xmlsec1 --verify --pubkey-cert-pem t/rsa.cert.pem --untrusted-pem t/intermediate.pem --trusted-pem t/cacert.pem --id-attr:ID "Response" --id-attr:ID "Assertion" t/rsa.xml 2>&1`;
    ok( $verify_response =~ m/^OK/, "RSA verify XML:Sig signed: xmlsec1 Response is OK" )
        or warn "calling xmlsec1 failed: '$verify_response'\n";
}

unlink 't/rsa.xml';

# Test signing with a DSA key
my $dsasig = XML::Sig->new({ key => 't/dsa.private.key' });
my $dsa_signed_xml = $dsasig->sign($xml);

# Write a temporary XML file XML::Sig signed with DSA
ok( open XML, '>', 't/dsa.xml' );
print XML $dsa_signed_xml;
ok( close XML, "DSA: Signed t/dsa.xml written Sucessfully");

# Verify XML file with XML::Sig signed with DSA
my $dsaret = $dsasig->verify($dsa_signed_xml);
ok($dsaret, "XML:Sig DSA: Verifed Successfully");

# Use xmlsec1 to verify the XML::Sig signed file
SKIP: {
    skip "xmlsec1 not installed", 4 unless which('xmlsec1');

    # Try whether xmlsec is correctly installed which
    # doesn't seem to be the case on every cpan testing machine

    my $output = `xmlsec1 --version`;
    skip "xmlsec1 not correctly installed", 6 if $?;

    # Verify with xmlsec1
    open my $dsafile, 't/dsa.xml' or die "no rsa signed xml";
    my $dsaxml;
    {
        local undef $/;
        $dsaxml = <$dsafile>;
    }

    my $verify_response = `xmlsec1 --verify --id-attr:ID "Response" --id-attr:ID "Assertion" t/dsa.xml 2>&1`;
    ok( $verify_response =~ m/^OK/, "DSA verify XML:Sig signed: xmlsec1 Response is OK" )
        or warn "calling xmlsec1 failed: '$verify_response'\n";
}

unlink 't/dsa.xml';

# Test that XML::Sig can verify an xmlsec1 RSA signed xml
open $file, 't/signed/xmlsec1-signed-rsa-multiple.xml' or die "no test t/signed/xmlsec1-signed-rsa-multiple.xml";
my $xmlsec;
{
    local undef $/;
    $xmlsec = <$file>;
}

my $xmlsec1_rsasig = XML::Sig->new( {x509 => 1, cert => 't/rsa.cert.pem'} );
my $xmlsec_ret = $xmlsec1_rsasig->verify($xmlsec);
ok($xmlsec_ret, "xmlsec1: RSA Verifed Successfully");

## Test that XML::Sig can verify a xmlsec1 RSA multiple signed xml
#open $file, 't/signed/xmlsec1-signed-dsa-multiple.xml' or die "no test t/signed/xmlsec1-signed-dsa-multiple.xml";
#{
#    local undef $/;
#    $xmlsec = <$file>;
#}

#my $xmlsec1_dsasig = XML::Sig->new();
#$xmlsec_ret = $xmlsec1_dsasig->verify($xmlsec);
#ok($xmlsec_ret, "xmlsec1: DSA Verifed Successfully");

done_testing;
