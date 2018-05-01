use strict;
use warnings;

use Test::More;

use Webservice::Swapi;

my $swapi = Webservice::Swapi->new;

my $response = $swapi->search('people', 'solo');
is($response->{results}->[0]->{name}, 'Han Solo', 'expect people found through search');

my $response_json = $swapi->search('people', 'solo', 'json');
is_deeply($response, $response_json, 'expect JSON format');

SKIP: {
	skip "wookiee format returns malformed JSON string.";

	my $response_wookiee = $swapi->search('people', 'solo', 'wookiee');
	is($response_wookiee->{oaoohuwhao}, 1, 'expect Wookiee format');
}

done_testing;
