use strict;
use warnings;

use Test::More;

use_ok('eBay::Client::OpenAPI3');
is($eBay::Client::OpenAPI3::VERSION, '0.01', 'version is set');
can_ok('eBay::Client::OpenAPI3', qw(new oauth2 get_ua browse getItem get_item rate_limit));

done_testing;
