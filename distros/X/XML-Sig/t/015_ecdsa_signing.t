use strict;
use warnings;

use Test::More tests => 8;
use XML::Sig;
use File::Which;

my $sig = XML::Sig->new( { x509 => 1 , key => 't/ecdsa.private.pem', cert => 't/ecdsa.public.pem' } );
isa_ok( $sig, 'XML::Sig' );

my $signed = $sig->sign('<foo ID="123"></foo>');
ok($signed, "XML Signed Sucessfully using ecdsa key");

$sig = XML::Sig->new( );
my $is_valid = $sig->verify( $signed );
ok( $is_valid == 1, "XML::Sig signed Validated using X509Certificate");

ok( (open XML, '>', 't/tmp.xml'), "File opened for write");
print XML $signed;
close XML;

SKIP: {
    skip "xmlsec1 not installed", 1 unless which('xmlsec1');

    my $verify_response = `xmlsec1 --verify --trusted-pem t/ecdsa.public.pem --id-attr:ID "foo" t/tmp.xml 2>&1`;
    ok( $verify_response =~ m/^OK/, "ECDSA Response is verified using xmlsec1" )
        or warn "calling xmlsec1 failed: '$verify_response'\n";
    if ($verify_response =~ m/^OK/) {
        unlink 't/tmp.xml';
    } else{
        print $signed;
        die;
    }
}

$sig = XML::Sig->new( { key => 't/ecdsa.private.pem' } );
isa_ok( $sig, 'XML::Sig' );

$signed = $sig->sign('<foo ID="123"></foo>');
ok($signed, "XML Signed Sucessfully using ecdsa key");

$sig = XML::Sig->new( );
$is_valid = $sig->verify( $signed );
ok( $is_valid == 1, "XML::Sig signed Validated using ECDSAKey");

done_testing;
