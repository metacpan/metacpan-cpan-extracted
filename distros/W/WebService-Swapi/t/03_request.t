use strict;
use warnings;
use utf8;

use Test::More;

use WebService::Swapi;

my $swapi = WebService::Swapi->new;
my $response;

$response = $swapi->_request();
is(ref $response, 'HASH', 'expect hash found');

$response = $swapi->_request(undef, undef, {format => 'json'});
is($response->{films}, $swapi->api_url . 'films/', 'expect JSON hash');

$response = $swapi->_request(undef, undef, {format => 'wookiee'});
ok(exists $response->{akwoooakanwo}, 'expect Wookiee key');
is($response->{akwoooakanwo}, qq|acaoaoakc://cohraakah.oaoo/raakah/akwoooakanwo/|, 'expect Wookiee value');

done_testing;
