# -*- perl -*-

use Test::Lib;
use Test::XML::Sig;

my $xmlsec  = get_xmlsec_features;
my $lax_key_search = $xmlsec->{lax_key_search} ? '--lax-key-search' :  '';

my $xml = '<?xml version="1.0"?>'."\n".'<foo ID="XML-SIG_1">'."\n".'    <bar>123</bar>'."\n".'</foo>';
my $sig = XML::Sig->new( { key => 't/rsa.private.key', cert => 't/rsa.cert.pem' } );
my $signed = $sig->sign($xml);
ok($signed, "XML is signed");
my $sig2 = XML::Sig->new( { key => 't/dsa.private.key' } );
my $result = $sig2->verify($signed);
ok($result, "XML verified" );

SKIP: {

    skip "xmlsec1 not installed", 1 unless $xmlsec->{installed};
    test_xmlsec1_ok(
        "Response is OK for xmlsec1", $signed, qw(
            --verify
            --pubkey-cert-pem t/rsa.cert.pem
            --untrusted-pem t/intermediate.pem
            --trusted-pem t/cacert.pem
            --id-attr:ID "foo"
        ), $lax_key_search
    );
}

done_testing;
