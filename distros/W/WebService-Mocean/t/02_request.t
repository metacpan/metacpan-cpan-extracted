use strict;
use warnings;
use utf8;

use Test::More;
use Test::Exception;

use WebService::Mocean;

my ($response, $expect) = ('', '');

my $mocean_api = WebService::Mocean->new(api_key => 'foo', api_secret => 'bar');

dies_ok {
    $response = $mocean_api->_request();
} 'expect die on missing command';

dies_ok {
    $mocean_api->_request(undef, undef, 'gets')
} 'expect die on invalid HTTP verb';

done_testing;
