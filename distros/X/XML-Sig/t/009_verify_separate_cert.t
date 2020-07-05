# -*- perl -*-

use strict;
use warnings;

use Test::More;
use Test::Exception;
use MIME::Base64;

BEGIN {
    use_ok( 'XML::Sig' );
}

open my $file, 't/logout_response.xml' or die "no test saml logout response";
my $xml;
{
    local undef $/;
    $xml = <$file>;
}
close $file;

my $sig = XML::Sig->new({ x509 => 1, cert => 't/sso.cert.pem' });
my $ret = $sig->verify($xml);
ok($ret);
ok($sig->signer_cert);

open $file, 't/sso.cert.pem';
my $text;
{
    local undef $/;
    $text = <$file>;
}
close $file;

$sig = XML::Sig->new({ x509 => 1, cert_text => $text });
$ret = $sig->verify($xml);
ok($ret);
ok($sig->signer_cert);

done_testing;
