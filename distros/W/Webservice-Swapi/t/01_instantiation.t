use strict;
use warnings;

use Test::More;

use Webservice::Swapi;

my $swapi = Webservice::Swapi->new;

is(ref $swapi, 'Webservice::Swapi', 'object instantiate through new');
is($swapi->api_url, 'https://swapi.co/api/', 'api url match');

done_testing;
