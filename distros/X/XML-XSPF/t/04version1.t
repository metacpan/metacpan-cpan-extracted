use Test::More 'tests' => '6';

BEGIN {
	use_ok('XML::XSPF');
};

my $xspf = XML::XSPF->parse('data/v1.xspf');

ok($xspf->isa('XML::XSPF'), '$xspf->isa(XML::XSPF)');

ok($xspf->version == 1, 'version is 1');

ok($xspf->date =~ /^2006-04-08T04:47:00/, 'date is xsd:dateTime');

ok($xspf->trackList == 1, 'trackList ok');

my $firstTrack = ($xspf->trackList)[0];

ok($firstTrack->title eq 'Ambient 040428', 'first track title ok');
