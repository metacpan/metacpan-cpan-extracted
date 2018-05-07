use strict;
use warnings;
use utf8;

use Test::More;

use WebService::Swapi;

my $swapi = WebService::Swapi->new;

my $response = $swapi->schema('people');
is($response->{title}, 'People', 'expect schema found');

done_testing;
