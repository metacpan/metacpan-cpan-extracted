# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;
use MIME::Base64;

BEGIN {
    use_ok( 'XML::Sig' );
}

open my $file, 't/signed/inclusive.xml' or die "no test inclusive xml";
my $xml;
{
    local undef $/;
    $xml = <$file>;
}
my $sig = XML::Sig->new(); #{ x509 => 1 });
my $ret = $sig->verify($xml);
ok($ret, "Successfully Verified XML");
ok($sig->signer_cert);

done_testing;
