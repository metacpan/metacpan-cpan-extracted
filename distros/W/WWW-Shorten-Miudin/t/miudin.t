use Test::More tests => 6;

BEGIN { use_ok WWW::Shorten::Miudin };

my $url = 'http://search.cpan.org/dist/WWW-Shorten/';
my $return = makeashorterlink($url);
my ($code) = $return =~ /(\w+)$/;
my $prefix = 'http://miud.in/';
is ( makeashorterlink($url), $prefix.$code, 'make it shorter');
is ( makealongerlink($prefix.$code), $url, 'make it longer');
is ( makealongerlink($code), $url, 'make it longer by Id',);

eval { &makeashorterlink() };
ok($@, 'makeashorterlink fails with no args');
eval { &makealongerlink() };
ok($@, 'makealongerlink fails with no args');
