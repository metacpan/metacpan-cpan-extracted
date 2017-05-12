use Test::More 'tests' => '6';

BEGIN {
	use_ok('XML::XSPF');
};

my $xspf = XML::XSPF->parse('data/v0.xspf');

ok($xspf->isa('XML::XSPF'), '$xspf->isa(XML::XSPF)');

ok($xspf->version == 0, 'version is 0');

ok($xspf->date eq '2004-03-21', 'date is ISO 8601');

ok($xspf->trackList == 5, 'trackList ok');

my $firstTrack = ($xspf->trackList)[0];

ok($firstTrack->title eq 'Space Dog', 'first track title ok');
