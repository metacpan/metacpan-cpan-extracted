use strict;
use warnings;
use utf8;

use Test::More;

use WebService::Swapi;

my $swapi = WebService::Swapi->new;

my $response = $swapi->resources();
foreach my $object (keys %$response) {
	my $url = $response->{$object};
	my $expected = $swapi->api_url . qq|$object/|;

	is($url, $expected, qq|expect URL for $object root resource match|);
}

my $response_json = $swapi->resources('json');
is_deeply($response, $response_json, 'expect JSON response');

my $response_wookiee = $swapi->resources('wookiee');
ok(exists $response_wookiee->{akwoooakanwo}, 'expect Wookiee key');
is($response_wookiee->{akwoooakanwo}, qq|acaoaoakc://cohraakah.oaoo/raakah/akwoooakanwo/|, 'expect Wookiee value');

done_testing;
