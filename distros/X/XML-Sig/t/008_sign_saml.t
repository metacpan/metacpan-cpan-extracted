# -*- perl -*-

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'XML::Sig' );
}

open my $file, 't/saml_request.xml' or die "no test saml request";
my $xml;
{
    local undef $/;
    $xml = <$file>;
}

my $sig = XML::Sig->new({ x509 => 1, key => 't/rsa.private.key', cert => 't/rsa.cert.pem' });
my $signed_xml = $sig->sign($xml);
ok($signed_xml);

my $sig2 = XML::Sig->new({ x509 => 1 });
my $ret = $sig2->verify($signed_xml);
ok($ret);
ok($sig2->signer_cert);

done_testing;
