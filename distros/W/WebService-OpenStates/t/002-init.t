use strict; use warnings;
use Test::More;
use Test::Exception;

use WebService::OpenStates;;

delete local $ENV{OPENSTATES_API_KEY};

dies_ok(
    sub { my $c = WebService::OpenStates->new },
    'Base class throws with no args',
);

dies_ok(
    sub { WebService::OpenStates->new( api_key => {}) },
    'Base class throws with hashref for api key',
);

dies_ok(
    sub { WebService::OpenStates->new( api_key => '') },
    'Base class throws with zero-length api key',
);

my $c = new_ok('WebService::OpenStates', [ api_key => 'foo', _api_url => 'bar', _client => 'baz' ]);

isnt( $c->_api_url, 'bar', 'api_url arg ignored');
isnt( $c->_client,  'baz', 'client arg ignored');

done_testing;
