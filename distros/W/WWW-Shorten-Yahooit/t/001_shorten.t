use Test::More tests => 8;

BEGIN { use_ok WWW::Shorten::Yahooit };

my $url = 'http://search.cpan.org/~cwimmer/';
my $return = makeashorterlink($url);
is ( makeashorterlink($url), $return, 'make it shorter');
is ( makealongerlink($return), $url, 'make it longer');

$url = 'http://www.wimmer.net/';
$return = makeashorterlink($url);
is ( makeashorterlink($url), $return, 'make it shorter');
is ( makealongerlink($return), $url, 'make it longer');

$url = 'http://wimmer.net/';
eval { &makeashorterlink($url) };
ok($@, 'makeashorterlink files with a 3xx URL');

eval { &makeashorterlink() };
ok($@, 'makeashorterlink fails with no args');
eval { &makealongerlink() };
ok($@, 'makealongerlink fails with no args');
