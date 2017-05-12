use strict;
use warnings;

use Test::More;
use Test::Exception;
use Data::Dumper;

use WWW::Shorten::ptl ();


ok !exists $::{makeashorterlink};
ok !exists $::{makealongerlink};

can_ok(q{WWW::Shorten::ptl}, 'new');

my $ptl = WWW::Shorten::ptl->new;
ok $ptl;

can_ok($ptl, q/apikey/);
can_ok($ptl, q/shorten/);
can_ok($ptl, q/extract/);


ok !defined $ptl->apikey;
dies_ok sub { $ptl->shorten("http://www.pixiv.net/"); }, "no API-KEY";
$ptl->apikey("API-KEY");
is $ptl->apikey, "API-KEY";
is(WWW::Shorten::ptl->new(apikey => "API-KEY-AGAIN")->apikey, "API-KEY-AGAIN");

ok(!defined $ptl->shorten(""));
ok(!defined $ptl->shorten(undef));
ok(!defined $ptl->shorten());

SKIP: {
	if ( !exists $ENV{PTL_API_KEY} ) {
		skip "set PTL_API_KEY to test shortening functionality", 1;
	}

  my $apikey = $ENV{PTL_API_KEY};
	$ptl->apikey($apikey);

	# short url seems to be persistent 
	my $shorturl = $ptl->shorten("http://www.pixiv.net/");
	diag Dumper $shorturl;

	is $shorturl->{short_url}, "http://p.tl/p/aog_";
}

my $longurl = $ptl->extract("http://p.tl/p/aog_");
is $longurl, "http://www.pixiv.net/";

ok(!defined $ptl->extract("http://bit.ly/hogehoge"));

done_testing();

