# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 5;
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
ok($ret, "Successfully Verified XML with unused prefixes");
ok($sig->signer_cert);

open my $file2, 't/signed/inclusive2.xml' or die "no test inclusive2.xml";
my $xml2;
{
    local undef $/;
    $xml2 = <$file2>;
}
my $sig2 = XML::Sig->new(); #{ x509 => 1 });
my $ret2 = $sig2->verify($xml2);
ok($ret2, "Successfully Verified XML with used prefixes");
ok($sig2->signer_cert);

done_testing;
