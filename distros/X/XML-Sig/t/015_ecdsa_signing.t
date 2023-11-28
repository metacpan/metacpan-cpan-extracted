use File::Which;
use Test::Lib;
use Test::XML::Sig;


my $xmlsec = get_xmlsec_features;

my $sig = XML::Sig->new(
    { x509 => 1, key => 't/ecdsa.private.pem', cert => 't/ecdsa.public.pem' });
isa_ok( $sig, 'XML::Sig' );

my $signed = $sig->sign('<foo ID="123"></foo>');
ok($signed, "XML Signed Sucessfully using ecdsa key");

$sig = XML::Sig->new();
ok($sig->verify($signed), "XML::Sig signed Validated using X509Certificate");

SKIP: {
    skip "xmlsec1 not installed", 1 unless $xmlsec->{installed};
    test_xmlsec1_ok("ECDSA Response is verified using xmlsec1",
        $signed,
        qw(--verify --trusted-pem t/ecdsa.public.pem --id-attr:ID "foo"));

}

$sig = XML::Sig->new( { key => 't/ecdsa.private.pem' } );
isa_ok( $sig, 'XML::Sig' );

$signed = $sig->sign('<foo ID="123"></foo>');
ok($signed, "XML Signed Sucessfully using ecdsa key");

$sig = XML::Sig->new( );
ok($sig->verify($signed), "XML::Sig signed Validated using ECDSAKey");

done_testing;
