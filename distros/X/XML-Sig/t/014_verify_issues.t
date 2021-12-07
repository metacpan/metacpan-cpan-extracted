# -*- perl -*-

use strict;
use warnings;

use Test::More;
use Test::Exception;
use MIME::Base64;

BEGIN {
    use_ok( 'XML::Sig' );
}

my %issues = (
    "Issue 20 - Digest New Lines" => "20",
    "Issue 31 - InclusiveNameSpaces" => "31",
    "Issue 38 - Wide Characters" => "38",
);

for my $issue (keys %issues) {
    my $filename = "t/issues/issue-$issues{$issue}.xml";
    open my $file, $filename or die "$filename not found!";
    my $xml;
    {
        local undef $/;
        $xml = <$file>;
    }
    my $sig = XML::Sig->new({ x509 => 1 });
    my $ret = $sig->verify($xml);
    ok($ret, "Successfully Verified " . $issue);
    ok($sig->signer_cert);
}

done_testing;
