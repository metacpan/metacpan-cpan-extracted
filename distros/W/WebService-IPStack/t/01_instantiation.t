use strict;
use utf8;
use warnings;

use Test::More;
use Test::Exception;

use WebService::IPStack;

my ($ipstack, $api_key) = ('', '1xxxxxxxxxxxxxxxxxxxxxxxxxxxxx32');

$ipstack = WebService::IPStack->new(api_key => $api_key);
is($ipstack->api_url, 'http://api.ipstack.com/', 'expect API URL match');
is($ipstack->api_key, $api_key, 'expect api key match');

foreach my $plan (qw(basic pro pro_plus)) {
    $ipstack = WebService::IPStack->new(api_key => $api_key, api_plan => $plan);
    is($ipstack->api_url, 'https://api.ipstack.com/', qq|expect API URL match for $plan plan|);
}

dies_ok {
    $ipstack = WebService::IPStack->new(api_key => 'foobar');
} 'expect exception invalid API key length';

dies_ok {
    $ipstack = WebService::IPStack->new();
} 'expect exception on missing argument: api_key';

done_testing;
