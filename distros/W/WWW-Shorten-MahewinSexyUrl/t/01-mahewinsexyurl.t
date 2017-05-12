use Test::More;

use LWP::UserAgent;

my $prefix = 'http://msud.pl/';

my $ua = LWP::UserAgent->new();
$ua->timeout(10);
my $r = $ua->get($prefix);
$r->code == 200 ? plan tests => 6
                : plan skip_all => 'http://msud.pl/ not reachable';

use_ok WWW::Shorten::MahewinSexyUrl;

my $url = 'http://search.cpan.org/dist/WWW-Shorten-MahewinSexyUrl/';
my $return = makeashorterlink($url);
my ($code) = $return =~ /(\w+)$/;
like ( $return, qr[^${prefix}\w+$], 'make it shorter');

is ( makealongerlink($prefix.$code), $url, 'make it longer');
is ( makealongerlink($code), $url, 'make it longer by Id',);

eval { &makeashorterlink() };
ok($@, 'makeashorterlink fails with no args');

eval { &makealongerlink() };
ok($@, 'makealongerlink fails with no args');

