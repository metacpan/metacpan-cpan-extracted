use strict;
use warnings;

use Test::More;

use Webservice::Swapi;

my $swapi = Webservice::Swapi->new;

my $response = $swapi->get_object('films', '1');
is($response->{title}, 'A New Hope', 'expect film found');

my $response_json = $swapi->get_object('films', '1', 'json');
is_deeply($response, $response_json, 'expect JSON response');

SKIP: {
	skip "wookie format returns illegal backslash";

	my $response_wookiee = $swapi->get_object('films', '1', 'wookiee');
	is($response_wookiee->{aoahaoanwo}, "A Nwooh Hooakwo", 'expect Wookiee response');
}

done_testing;
