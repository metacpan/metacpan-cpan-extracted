use strict;
use warnings;

use Test::More;
use Test::Exception;

use WWW::Shorten::ptl;

ok exists $::{makeashorterlink};
ok exists $::{makealongerlink};

# compile error :)
#dies_ok sub { makeashorterlink("http://www.pixiv.net/") }, "no API-key";

ok !defined makeashorterlink("http://www.pixiv.net/", "");

SKIP: {
	if ( !exists $ENV{PTL_API_KEY} ) {
		skip "set PTL_API_KEY to test shortening functionality", 1;
	}

  my $apikey = $ENV{PTL_API_KEY};

	# short url seems to be persistent 
	my $shorturl = makeashorterlink("http://www.pixiv.net/", $apikey);
	is $shorturl, "http://p.tl/p/aog_";
}

my $longurl = makealongerlink("http://p.tl/p/aog_");
is $longurl, "http://www.pixiv.net/";

done_testing();
