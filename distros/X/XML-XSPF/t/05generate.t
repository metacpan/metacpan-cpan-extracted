use Test::More 'tests' => '10';

BEGIN {
	use_ok('XML::XSPF');
};

my $xspf  = XML::XSPF->new;
my $track = XML::XSPF::Track->new;

ok($xspf->isa('XML::XSPF'), '$xspf->isa(XML::XSPF)');

$track->title('Prime Evil');

ok($track->title eq 'Prime Evil', 'set track title');

$track->location('http://orb.com/PrimeEvil.mp3');

ok($track->location eq 'http://orb.com/PrimeEvil.mp3', 'set track location');

$xspf->title('Bicycles & Tricycles');

ok($xspf->title eq 'Bicycles & Tricycles', 'set playlist title');

$xspf->trackList($track);

ok($xspf->trackList == 1, 'playlist trackList count');

ok($xspf->version == 1, 'default version');

my $xml = eval { $xspf->toString };

ok(defined $xml, 'serialization worked');

ok($xml =~ /xspf\.org/, 'default xmlns');

ok($xml =~ /PrimeEvil\.mp3<\/location>/, 'xml location ok');
