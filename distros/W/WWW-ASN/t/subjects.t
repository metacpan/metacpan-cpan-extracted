use strict;
use warnings;
use Test::More;

use WWW::ASN;
use FindBin qw($Bin);
use File::Spec::Functions qw(catfile);

my $xml_file = catfile($Bin, 'subjects.xml');

if ($ENV{ASN_USE_NET}) {
    unlink($xml_file);
    ok(! -e $xml_file, "$xml_file does not exist");
}


my $asn = new_ok 'WWW::ASN' => [ subjects_cache => $xml_file ];

my $subjects = $asn->subjects;
ok(-e $xml_file, "$xml_file exists");

isa_ok($subjects->[0], 'WWW::ASN::Subject');

my @english = grep { $_->id eq 'http://purl.org/ASN/scheme/ASNTopic/english' } @$subjects;

ok(@english, "found english");
like($english[0]->name, qr/English/, 'name');
ok($english[0]->document_count > 1, 'document_count > 1');

done_testing;
