use strict; use warnings;
use Test::More;
use Test::Exception;

use WebService::OpenStates;

plan skip_all => 'Set $ENV{OPENSTATES_API_KEY} to run live tests' unless $ENV{OPENSTATES_API_KEY};

my $client = new_ok('WebService::OpenStates', [], 'obj instantiated with api key from env');

dies_ok(sub {$client->legislators_for_location()}, 'method dies with no params');

dies_ok(sub {$client->legislators_for_location(lat => 91, lon => 181)}, 'method dies with invalid params');

my $res = $client->legislators_for_location(lat => 37.302268, lon => -78.39263);

is(ref($res), 'HASH', 'method response is a hashref');

is((grep {$_->{title} eq 'Virginia Senator'} @{$res->{legislators}}), 1, 'method response contains one VA senator');

done_testing;
