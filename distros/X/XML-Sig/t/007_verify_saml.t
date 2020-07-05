# -*- perl -*-

use strict;
use warnings;

use Test::More;
use Test::Exception;
use MIME::Base64;

BEGIN {
    use_ok( 'XML::Sig' );
}

open my $file, 't/saml_response.xml' or die "no test saml response";
my $xml;
{
    local undef $/;
    $xml = <$file>;
}
my $sig = XML::Sig->new({ x509 => 1 });
my $ret = $sig->verify($xml);
ok($ret);
ok($sig->signer_cert);

done_testing;
