# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;
use File::Which;

BEGIN {
    use_ok( 'XML::Sig' );
}

my $sig = XML::Sig->new( {
    x509        => 1,
    cert        => 't/dsa.public.pem',
    key         => 't/dsa.private.key',
} );
isa_ok( $sig, 'XML::Sig' );

isa_ok( $sig->{ key_obj }, 'Crypt::OpenSSL::DSA', 'Key object is valid' );

my $signed = $sig->sign('<foo ID="123"></foo>');
ok($signed, "XML Signed Sucessfully using DSA key");

SKIP: {
    skip "xmlsec1 not installed", 2 unless which('xmlsec1');

    ok( (open XML, '>', "t/tmp.xml"), "File t/tmp.xml opened for write");
    print XML $signed;
    close XML;

    my $verify_response = `xmlsec1 --verify --pubkey-cert-pem t/dsa.public.pem --trusted-pem t/dsa.public.pem  --id-attr:ID "foo" t/tmp.xml 2>&1`;
    ok( $verify_response =~ m/OK/, "t/tmp.xml is verified using xmlsec1 and X509Certificate" )
        or warn "calling xmlsec1 failed: '$verify_response'\n";
    unlink "t/tmp.xml";
}

$sig = XML::Sig->new( );
my $is_valid = $sig->verify( $signed );
ok( $is_valid == 1, "XML::Sig signed Validated using DSA X509Certificate");

done_testing;
