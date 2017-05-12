#!/perl -T

use Test::More qw (no_plan);
use WWW::Search::Scrape::Google;

BEGIN
{
	ok(WWW::Search::Scrape::Google::search('google', 10));

	my $result = WWW::Search::Scrape::Google::search('google', 10);

	ok($result->{num} >= 622000000);

}  
