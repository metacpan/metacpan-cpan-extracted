use strict;
use warnings;
use utf8;

use Test::More;
use Test::Exception;

use WebService::Mocean;

my ($got, $expect, $params, $required_fields) = ('', '', {}, []);

my $mocean_api = WebService::Mocean->new(api_key => 'foo', api_secret => 'bar');

#
$params = {
    'mocean-from' => 1,
    'mocean-to' => 1,
    'mocean-text' => 1
};

$got = $mocean_api->client->_check_required_params('sms', $params);
is($got, 0, 'expect no error throw');

#
$params = {
    'mocean-from' => 1,
};

dies_ok {
    $got = $mocean_api->_check_required_params('sms', $params);
} 'expect die on missing required params';

done_testing;
